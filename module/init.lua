--[[
  Lord Hunt

  The AI plans every attack against one player's keep (PlayerData.attackedPlayerID). A human
  lord standing in an ally's castle is not at that keep, and the attackers never go for him.
  This module watches every AI attack on a human player, right after the AI's own attack state
  update (updateAIPlayerState, called once per AI player from updateAIBehaviour):

  1. Lord hiding in an ally's castle. The lord's tile is in the walled-in area (the game's area
     map, built with every gate shut) of an allied keep, the attacking army cannot walk there,
     and he is not at home. The attack is pointed at that castle instead (attackedPlayerID =
     the ally, AI state 1 = plan again) and a share of the army is split off into a troop of
     its own that attacks the player's own castle - if the player still has people and
     buildings there. A setting swaps which castle gets the real siege. Mid-attack this only
     happens while the army still has enough of its troops.
  2. Lord hunt. When the lord can be reached (the game's own area-to-area test, the one it uses
     to call a castle breached), a share of the army attacking the castle he is in is moved
     into a troop of its own and given the game's "attack this unit" order on the lord: main
     army troops first, closest first. If they all die, the rest go. When the way is closed
     again (wall repaired), they rejoin the siege.

  Troops are moved with the game's own functions (createTribeForPlayer, removeUnitFromTribe,
  addUnitToTribe, addUnitToItsTribe). A troop the AI has not registered in its aiTribeIDs list
  is one the AI never gives orders to, which is what keeps hunters on the lord. Nothing is
  written to the save: after loading, units in such troops go back into the AI's own troops
  and are picked again on the next check.

  The code changes are two calls in updateAIBehaviour. The call right after the attack state
  update is pointed at a stub that runs the lua check and then jumps to whatever that call
  pointed at before. The call to the AI's monthly target choice (selectAttackTarget, which runs
  during attacks too and would undo a redirect) is pointed at a stub that runs it and then puts
  back the castle this module pointed the attack at. If another module has replaced either of
  those AI functions, the module stays off and says so in the log.
]]

local MODULE_NAME = "lord-hunt"

local DEFAULTS = {
  hiding = { enabled = true, siege = "hiding", split = 50, switch_alive = 80 },
  hunt = { enabled = true, share = 50 },
  diagnostics = { log = false },
}

---------------------------------------------------------------------------------------
-- What the game's code looks like where this module reads it
---------------------------------------------------------------------------------------

-- updateAIBehaviour, per AI player: updateAIPlayerState / aiUpdateTaxesAndRations /
-- setFoodBuyPlan, then cmp [monthTicks].
local AOB_CALLS = "57 8B CB E8 ? ? ? ? 57 8B CB E8 ? ? ? ? 57 8B CB E8 ? ? ? ? 39 3D ? ? ? ? 74"
local CALL_STATE = 0x03
local CALL_HOOK = 0x0B
local AOB_STATE_UPDATE = "53 56 8B 74 24 0C 57 8B FE 69 FF F4 39 00 00 8B 87 ? ? ? ? 85 C0 8B D9 0F 84"

-- updateAIBehaviour, per AI player once a month: updateAIStrengthState / selectAttackTarget.
-- The target choice runs during attacks too and would undo a redirect.
local AOB_SELECT_CALL = "57 8B CB E8 ? ? ? ? B8 01 00 00 00 39 86 ? ? 00 00 75 08 89 86"
local CALL_SELECT = 0x03
local AOB_SELECT = "83 EC 20 8B 54 24 24 53 8B DA 69 DB F4 39 00 00 8B 83 ? ? ? ? 55 33 ED 3B C5"

-- AICState::addUnitToItsTribe(unit, behaviour)
local AOB_ADD_TO_ITS_TRIBE = "56 57 8B 7C 24 0C 8B C7 69 C0 90 04 00 00 0F BF 90 ? ? ? ? 8B F2 69 F6 F4 39 00 00"
local ITS_UNIT_OWNER = { 0x0E, { 0x0F, 0xBF, 0x90 } }
local ITS_AI_TYPE = { 0x1D, { 0x83, 0xBE } }
local ITS_TRIBES = { 0x3F, { 0xB9 } }
local ITS_ADD_TO_TRIBE = 0x44

local AOB_ADD_TO_TRIBE = "53 8B 5C 24 08 56 57 8B 7C 24 14 8B C7 69 C0 ? ? 00 00 66 83"
local AOB_REMOVE_FROM_TRIBE = "53 55 56 8B 74 24 10 8B D9 8B CE 69 C9 90 04 00 00 66 83 B9 ? ? ? ? 00 57 8B 7C 24 18"
local REMOVE_STRIDE = { 0x5B, { 0x69, 0xC0 } }
local AOB_CREATE_TRIBE = "53 55 8B 6C 24 0C 56 57 BF ? ? 00 00 2B FD 33 DB 3B FB 7E"
local AOB_INSTRUCTION = "83 EC 1C 8B 44 24 20 69 C0 ? ? 00 00 53 8B 5C 24 30 55 8D 2C 08 33 D2 56 0F BF 75 5C"
local AOB_STANCE = "8B 44 24 04 66 8B 54 24 08 69 C0 ? ? 00 00 66 89 94 08 ? ? 00 00 C7 05"
local AOB_MOVE = "83 EC 34 33 C0 55 8B 6C 24 44 57 8B 7C 24 44 3B F8 89 4C 24 08 89 44 24 18"
local AOB_GO_DEFENSIVE = "83 EC 0C 53 8B 5C 24 14 69 DB F4 39 00 00 83 BB ? ? ? ? 00"

-- GameState::canNavigateFromKeepToKeep: the area map, the keep fields and the area test.
local AOB_KEEP_TO_KEEP = "56 8B 74 24 08 8B C6 69 C0 F4 39 00 00 03 C1 83 B8 ? ? ? ? 00 75 09 B8 01 00 00 00"
local K2K_HAS_KEEP = { 0x0F, { 0x83, 0xB8 } }
local K2K_KEEP_TILE = { 0x36, { 0x8B, 0x89 } }
local K2K_AREA = { 0x42, { 0x0F, 0xB7, 0x04, 0x4D } }
local K2K_PATHS = { 0x72, { 0xB9 } }
local K2K_CAN_NAVIGATE = 0x77

-- chooseRandomBuildingIDFromPlayersArrayOfBuildings: the building array.
local AOB_RANDOM_BUILDING = "8B 4C 24 04 69 C9 F4 39 00 00 53 0F B6 1D ? ? ? ? 56 8B B1"
local RANDOM_TARGETABLE = { 0x13, { 0x8B, 0xB1 } }
local RANDOM_BUILDING_TYPE = { 0x47, { 0x0F, 0xBF, 0xBF } }

local AOB_TEAMS = "8B 0C 85 ? ? ? ? 8B 44 24 30 3B 0C 85 ? ? ? ?"
local TEAMS_OPERAND = 0x03
local AOB_TICKS = "8B 87 50 0A 00 00 8B 8F 98 09 00 00 8B 15"
local TICKS_OPERAND = 0x0E
local AOB_TILE_FLAGS = "F7 04 9D ? ? ? ? 00 01 00 00"
local TILE_FLAGS_OPERAND = 0x03

---------------------------------------------------------------------------------------
-- Layouts (the same in both executables unless read from code above)
---------------------------------------------------------------------------------------

local U = {
  STRIDE = 0x490, STATE = 0x8C, TYPE = 0x8E, OWNER = 0x96, UID = 0x98, X = 0xC4, Y = 0xC6,
  TILE = 0xD4, DYING = 0x2A0, TRIBE = 0x2D8, TARGETING = 0x39C, TARGET_UNIT = 0x39E,
  BEHAVIOUR = 0x42A, STATE_OFFSET = 0x614,
}
local P = {
  STRIDE = 0x39F4, HAS_KEEP = 0x94, KEEP_TILE = 0x1E0, LORD = 0x21F8, LORD_UID = 0x21FC,
  AI_TYPE = 0x2300, AI_STATE = 0x2BA4, ATTACKED = 0x2BD8, TRIBE_IDS = 0x310C,
  TRIBE_UIDS = 0x329C, TARGETABLE = 0x35BC, TARGETABLE_COUNT = 0x3684,
}
local T = { OWNER = 0x2C, UID = 0x34, STATE = 0x40, SIZE = 0x5C }
local B = { STRIDE = 0x32C, STATE = 0xD0, OWNER = 0xD6, UID = 0xD8, X = 0xEE, Y = 0xF0, SIZE = 0xF8,
  ENTRY_X = 0xFE, ENTRY_Y = 0x100 }
local MAP = { FLAGS = 0x165160, WALL_OWNER = 0x2C6E50, AREA = 0x363ED0, Y_OF_TILE = 0x742B90,
  ROWS = 0x8A40F8, SIZE = 400 }
-- The AI characters live in the AI state object: (character - 1) * 0x2A4 + field. 0x1F4 is the
-- army size the AI waits for before it attacks (AttForceBase).
local AIC_STRIDE, AIC_ATTACK_FORCE = 0x2A4, 0x1F4

local LORD_TYPE = 55
local WALL_FLAG, NOT_WALL_FLAG = 0x100, 0x2
local STANCE_AGGRESSIVE = 2
local ORDER_ATTACK_UNIT, ORDER_ATTACK_BUILDING, ORDER_ATTACK_WALL = 4, 9, 0x17

-- The attack army, by aiUnitBehaviourType, in the order of the AI's own troop slots (its
-- breach troop table): main army first. 10 engineers, 11 moat diggers, 14 laddermen and 15
-- tunnellers have jobs of their own and are left alone; they still count as attack troops.
local HUNT_RANK = { [20] = 1, [19] = 2, [13] = 3, [12] = 4, [17] = 5, [18] = 6, [16] = 7 }
local ATTACK_FIRST, ATTACK_LAST = 10, 20
-- Siege engines and the units that work them never fight a lord.
local LEFT_ALONE = { [29] = true, [30] = true, [39] = true, [40] = true, [41] = true, [55] = true,
  [58] = true, [59] = true, [60] = true, [61] = true, [77] = true }

-- Archers, crossbowmen, Arab archers, slingers and horse archers: given the game's "attack
-- building" order they stand and shoot at the building's middle, which hurts nothing. In the
-- split troop they walk with the others instead and shoot the troops they meet.
local RANGED = { [22] = true, [23] = true, [70] = true, [72] = true, [74] = true }

local ACTIVE_FIRST, ACTIVE_LAST = 1, 6       -- AI attack states that are an attack under way
local LOAD_GAP = 4000                        -- a jump in the tick counter this big is a load
local CLOSED_TICKS = 200                     -- the way to the lord shut this long ends a hunt
local REORDER_TICKS = 80                     -- hunters off the lord get the order again
local WALL_SEARCH = 30                       -- tiles around the split troop to look for walls

---------------------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------------------

local rd32, rd16, rd8 = core.readInteger, core.readSmallInteger, core.readByte
local wr32 = core.writeInteger

local function scan(pattern, purpose)
  local ok, address = pcall(core.AOBScan, pattern)
  if not ok or address == nil then
    error(MODULE_NAME .. ": could not find " .. purpose)
  end
  return address
end

local function scanOptional(pattern)
  local ok, address = pcall(core.AOBScan, pattern)
  if ok then
    return address
  end
  return nil
end

local function expectBytes(address, bytes, purpose)
  for index, byte in ipairs(bytes) do
    if (rd8(address + index - 1) & 0xFF) ~= byte then
      error(string.format("%s: %s at 0x%X is not the code this module knows", MODULE_NAME, purpose,
        address))
    end
  end
end

local function readOperand(base, site, purpose)
  expectBytes(base + site[1], site[2], purpose)
  return rd32(base + site[1] + #site[2])
end

local function readCallTarget(base, offset, purpose)
  expectBytes(base + offset, { 0xE8 }, purpose)
  return base + offset + 5 + rd32(base + offset + 1)
end

local function setting(config, group, name)
  local section = config[group]
  if type(section) == "table" and section[name] ~= nil then
    return section[name]
  end
  return DEFAULTS[group][name]
end

local function percent(value)
  value = math.tointeger(math.floor(tonumber(value) or 0)) or 0
  if value < 0 then return 0 end
  if value > 100 then return 100 end
  return value
end

---------------------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------------------

local G = {}             -- addresses, filled by enable
local F = {}             -- the game's functions, exposed to lua
local O = {}             -- options
local attackers = {}     -- per AI player: the attack this module is looking after
local swept = {}         -- per AI player: troops checked after a load
local lastTick = nil
local paused = false
local broken = false

local function diag(fmt, ...)
  if O.log then
    log(INFO, MODULE_NAME .. ": " .. string.format(fmt, ...))
  end
end

local function player(p) return G.players + p * P.STRIDE end

local valuesByAI = {}
local AIC_OPTIONS = {
  AttLordHuntShare = { default = function() return O.huntShare end, min = 0, max = 100 },
  AttRedirectHidingSplit = { default = function() return O.split end, min = 0, max = 100 },
  AttRedirectHidingSwitchAlive = { default = function() return O.switchAlive end, min = 0, max = 100 },
  AttRedirectHidingSiege = { default = function() return O.siegeOnHiding and 1 or 0 end, min = 0, max = 1 },
}

local function aicOption(playerID, name)
  local character = rd32(player(playerID) + P.AI_TYPE)
  local values = valuesByAI[character]
  local value = values and values[name]
  if value ~= nil then return value end
  return AIC_OPTIONS[name].default()
end

local function registerAICOptions()
  for name, spec in pairs(AIC_OPTIONS) do
    modules.aicloader:setAdditionalAICValue(name, function(character, value)
      if value == nil then
        local values = valuesByAI[character]
        if values and values[name] ~= nil then return values[name] end
        return spec.default()
      end
      local integer = type(value) == "number" and math.tointeger(value)
      if not integer or integer < spec.min or integer > spec.max then
        log(WARNING, string.format("%s: %s must be an integer from %d to %d",
          MODULE_NAME, name, spec.min, spec.max))
        return
      end
      local values = valuesByAI[character] or {}
      values[name] = integer
      valuesByAI[character] = values
    end, function(character)
      if valuesByAI[character] then valuesByAI[character][name] = nil end
    end)
  end
end

local function unit(id) return G.units + id * U.STRIDE end
local function tribe(id) return G.tribes + id * G.tribeStride end
local function building(id) return G.buildings + id * B.STRIDE end

local function area(tile)
  if tile == nil or tile <= 0 then return 0 end
  return rd16(G.area + tile * 2) & 0xFFFF
end

local function tileAt(x, y)
  if x < 0 or y < 0 or x >= MAP.SIZE or y >= MAP.SIZE then return nil end
  return rd32(G.rows + y * 12) + x
end

local function team(p) return rd32(G.teams + p * 4) end
local function hasKeep(p) return rd32(player(p) + P.HAS_KEEP) ~= 0 end
local function keepTile(p) return rd32(player(p) + P.KEEP_TILE) end

local function tileXY(tile)
  local y = rd16(G.yOfTile + tile * 2)
  return tile - rd32(G.rows + y * 12), y
end

local function distance(ax, ay, bx, by)
  local dx, dy = math.abs(ax - bx), math.abs(ay - by)
  return dx > dy and dx or dy
end

local function tribeAlive(id, uid)
  return id ~= nil and id > 0 and rd16(tribe(id) + T.STATE) == 2 and rd32(tribe(id) + T.UID) == uid
end

local function aliveLord(p)
  local id = rd32(player(p) + P.LORD)
  if id <= 0 then return nil end
  local u = unit(id)
  if rd16(u + U.STATE) ~= 2 or rd16(u + U.TYPE) ~= LORD_TYPE or rd16(u + U.DYING) ~= 0 then
    return nil
  end
  if rd32(u + U.UID) ~= rd32(player(p) + P.LORD_UID) then return nil end
  return { id = id, uid = rd32(u + U.UID), x = rd16(u + U.X), y = rd16(u + U.Y), tile = rd32(u + U.TILE) }
end

local function isHuman(p)
  return p >= 1 and p <= 8 and rd32(player(p) + P.AI_TYPE) == 0 and aliveLord(p) ~= nil
end

-- The game's own "can troops of this player walk from one area to the other", with and
-- without the climbing links (ladders, siege towers) - the two tests the AI itself uses to
-- call a castle breached.
local function reaches(memo, p, from, to)
  if from == 0 or to == 0 then return false end
  if from == to then return true end
  local key = from * 65536 + to
  local known = memo[key]
  if known == nil then
    known = F.canNavigate(G.paths, p, to, from, 0) ~= 0 or F.canNavigate(G.paths, p, to, from, 2) ~= 0
    memo[key] = known
  end
  return known
end

-- Every troop the AI has registered, by tribe id.
local function registeredTribes(a)
  local list = {}
  local base = player(a)
  for slot = 0, 199 do
    local id = rd16(base + P.TRIBE_IDS + slot * 2)
    if id > 0 and rd32(tribe(id) + T.UID) == rd32(base + P.TRIBE_UIDS + slot * 4) then
      list[id] = true
    end
  end
  return list
end

---------------------------------------------------------------------------------------
-- Moving units between troops
---------------------------------------------------------------------------------------

local function newTribe(a, units)
  local id = F.createTribe(G.tribesThis, a)
  if id == nil or id <= 0 then return nil end
  for _, u in ipairs(units) do
    if u.tribe > 0 then
      F.removeFromTribe(G.tribesThis, u.id, u.tribe)
    end
    F.addToTribe(G.tribesThis, u.id, id)
    u.tribe = id
  end
  F.setStance(G.tribesThis, id, STANCE_AGGRESSIVE)
  return id, rd32(tribe(id) + T.UID)
end

-- Back to where it came from: the split troop if it is still there, else the AI's own troop
-- for its behaviour (the AI's own addUnitToItsTribe picks the smallest one).
local function giveBack(u, into)
  if u.tribe > 0 then
    F.removeFromTribe(G.tribesThis, u.id, u.tribe)
  end
  if into ~= nil and tribeAlive(into.id, into.uid) then
    F.addToTribe(G.tribesThis, u.id, into.id)
    u.tribe = into.id
  else
    F.addToItsTribe(G.aiState, u.id, u.behaviour)
    u.tribe = rd16(unit(u.id) + U.TRIBE)
  end
end

local function unitsOfTribe(a, id)
  local list = {}
  local count = rd32(G.unitsThis)
  for index = 1, count - 1 do
    local u = unit(index)
    if rd16(u + U.OWNER) == a and rd16(u + U.TRIBE) == id and rd16(u + U.STATE) == 2 then
      list[#list + 1] = { id = index, tribe = id, behaviour = rd16(u + U.BEHAVIOUR) }
    end
  end
  return list
end

-- After a load the module knows nothing of the troops it made. The AI keeps every attack
-- unit in a troop it registered, so any attack unit in an unregistered troop is one of ours:
-- it goes back to the AI, and the next check picks again.
local function sweep(a)
  local registered = registeredTribes(a)
  local count = rd32(G.unitsThis)
  local moved = 0
  for index = 1, count - 1 do
    local u = unit(index)
    if rd16(u + U.OWNER) == a and rd16(u + U.STATE) == 2 then
      local behaviour = rd16(u + U.BEHAVIOUR)
      local id = rd16(u + U.TRIBE)
      if HUNT_RANK[behaviour] ~= nil and id > 0 and not registered[id] then
        giveBack({ id = index, tribe = id, behaviour = behaviour }, nil)
        moved = moved + 1
      end
    end
  end
  if moved > 0 then
    diag("player %d: %d units back in the AI's own troops after loading", a, moved)
  end
end

---------------------------------------------------------------------------------------
-- The attack army
---------------------------------------------------------------------------------------

local function collect(a, S, h)
  local registered = registeredTribes(a)
  local army = { main = {}, split = {}, shooters = {}, hunt = {}, attack = 0, home = 0 }
  local splitId = S.split and S.split.id or -1
  local shootersId = S.shooters and S.shooters.id or -1
  local huntId = S.hunt and S.hunt.id or -1
  local count = rd32(G.unitsThis)
  for index = 1, count - 1 do
    local u = unit(index)
    local owner = rd16(u + U.OWNER)
    if (owner == a or owner == h) and rd16(u + U.STATE) == 2 and rd16(u + U.DYING) == 0 then
      local kind = rd16(u + U.TYPE)
      if owner == h then
        if kind ~= LORD_TYPE then army.home = army.home + 1 end
      else
        local behaviour = rd16(u + U.BEHAVIOUR)
        if behaviour >= ATTACK_FIRST and behaviour <= ATTACK_LAST then
          army.attack = army.attack + 1
          if HUNT_RANK[behaviour] ~= nil and not LEFT_ALONE[kind] then
            local id = rd16(u + U.TRIBE)
            local entry = { id = index, tribe = id, behaviour = behaviour, kind = kind, x = rd16(u + U.X),
              y = rd16(u + U.Y), tile = rd32(u + U.TILE) }
            if id == huntId then
              army.hunt[#army.hunt + 1] = entry
            elseif id == splitId then
              army.split[#army.split + 1] = entry
            elseif id == shootersId then
              army.shooters[#army.shooters + 1] = entry
            elseif registered[id] then
              army.main[#army.main + 1] = entry
            end
          end
        end
      end
    end
  end
  return army
end

local function anyReaches(memo, a, units, target)
  for _, u in ipairs(units) do
    if reaches(memo, a, area(u.tile), target) then return true end
  end
  return false
end

---------------------------------------------------------------------------------------
-- 1. The lord hiding in an ally's castle
---------------------------------------------------------------------------------------

local function checkHiding(a, S, army, lord, memo, state)
  local h = S.orig
  local lordArea = area(lord.tile)
  if lordArea == 0 then return end
  if hasKeep(h) and area(keepTile(h)) == lordArea then return end
  local host = nil
  for q = 1, 8 do
    if q ~= h and q ~= a and hasKeep(q) and team(q) == team(h) and team(q) ~= team(a)
        and area(keepTile(q)) == lordArea then
      host = q
      break
    end
  end
  if host == nil then return end
  if anyReaches(memo, a, army.main, lordArea) then return end    -- not hidden: the hunt's job
  if state >= 3 and army.attack * 100 < S.peak * aicOption(a, "AttRedirectHidingSwitchAlive") then return end

  local homeHasStuff = army.home > 0 and rd32(player(h) + P.TARGETABLE_COUNT) > 0
  local share = homeHasStuff and aicOption(a, "AttRedirectHidingSplit") or 0
  local splitTo
  if aicOption(a, "AttRedirectHidingSiege") == 1 or share == 0 then
    wr32(player(a) + P.ATTACKED, host)
    wr32(G.override + a * 4, host)          -- the AI's monthly target choice keeps it
    wr32(player(a) + P.AI_STATE, 1)          -- the AI plans its attack again, on the new castle
    S.host = host
    splitTo = h
  else
    splitTo = host
  end
  S.redirected = true
  diag("player %d: the lord of player %d hides in the castle of player %d; siege on player %d, "
    .. "%d percent of %d troops to player %d", a, h, host, S.host or h, share, #army.main, splitTo)

  if share > 0 and #army.main > 0 then
    local tx, ty = tileXY(keepTile(splitTo))
    table.sort(army.main, function(l, r)
      return distance(l.x, l.y, tx, ty) < distance(r.x, r.y, tx, ty)
    end)
    local n = (#army.main * share + 50) // 100
    local chosen = {}
    for index = 1, n do chosen[index] = army.main[index] end
    local melee, ranged = {}, {}
    for _, u in ipairs(chosen) do
      if RANGED[u.kind] then ranged[#ranged + 1] = u else melee[#melee + 1] = u end
    end
    S.splitTo, S.splitTarget = splitTo, nil
    if #melee > 0 then
      local id, uid = newTribe(a, melee)
      if id ~= nil then S.split = { id = id, uid = uid } army.split = melee end
    end
    if #ranged > 0 then
      local id, uid = newTribe(a, ranged)
      if id ~= nil then S.shooters = { id = id, uid = uid } army.shooters = ranged end
    end
    for index = #army.main, 1, -1 do
      local id = army.main[index].tribe
      if (S.split and id == S.split.id) or (S.shooters and id == S.shooters.id) then
        table.remove(army.main, index)
      end
    end
  end
end

-- The split troop has no siege plan: it attacks the nearest building of its castle it can
-- walk to, then the next, else the nearest wall it can stand next to, else it walks to the
-- keep and fights what it meets.
local function nearestBuilding(a, X, fromArea, x, y, memo)
  local base = player(X)
  local count = rd32(base + P.TARGETABLE_COUNT)
  if count > 100 then count = 100 end
  local best, bestDistance, bx, by = nil, nil, nil, nil
  for index = 0, count - 1 do
    local id = rd16(base + P.TARGETABLE + index * 2)
    if id > 0 then
      local b = building(id)
      if rd16(b + B.STATE) ~= 0 and rd16(b + B.OWNER) == X then
        local ex, ey = rd16(b + B.ENTRY_X), rd16(b + B.ENTRY_Y)
        if ex <= 0 and ey <= 0 then                     -- no door: the tile below its corner
          ex, ey = rd16(b + B.X), rd16(b + B.Y) + rd32(b + B.SIZE)
        end
        local tile = tileAt(ex, ey)
        if tile ~= nil and reaches(memo, a, area(tile), fromArea) then
          local d = distance(ex, ey, x, y)
          if bestDistance == nil or d < bestDistance then best, bestDistance, bx, by = id, d, ex, ey end
        end
      end
    end
  end
  return best, bx, by
end

local NEIGHBOURS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

local function nearestWall(a, X, fromArea, x, y, memo)
  local best, bestDistance = nil, nil
  for ty = math.max(y - WALL_SEARCH, 0), math.min(y + WALL_SEARCH, MAP.SIZE - 1) do
    local row = rd32(G.rows + ty * 12)
    for tx = math.max(x - WALL_SEARCH, 0), math.min(x + WALL_SEARCH, MAP.SIZE - 1) do
      local tile = row + tx
      do
        local flags = rd32(G.flags + tile * 4)
        if flags & WALL_FLAG ~= 0 and flags & NOT_WALL_FLAG == 0
            and (rd8(G.wallOwner + tile) & 7) + 1 == X then
          local d = distance(tx, ty, x, y)
          if bestDistance == nil or d < bestDistance then
            for _, n in ipairs(NEIGHBOURS) do
              local side = tileAt(tx + n[1], ty + n[2])
              if side ~= nil and reaches(memo, a, area(side), fromArea) then
                best, bestDistance = tile, d
                break
              end
            end
          end
        end
      end
    end
  end
  return best
end

local function splitTargetHolds(S)
  local target = S.splitTarget
  if target == nil then return false end
  if target.kind == "building" then
    local b = building(target.id)
    return rd16(b + B.STATE) ~= 0 and rd32(b + B.UID) == target.uid and rd16(b + B.OWNER) == S.splitTo
  elseif target.kind == "wall" then
    local flags = rd32(G.flags + target.tile * 4)
    return flags & WALL_FLAG ~= 0 and (rd8(G.wallOwner + target.tile) & 7) + 1 == S.splitTo
  end
  return false
end

local function orderSplit(a, S, army, memo)
  if S.splitTo == nil then return end
  if S.split ~= nil and (not tribeAlive(S.split.id, S.split.uid) or #army.split == 0) then
    S.split = nil
  end
  if S.shooters ~= nil and (not tribeAlive(S.shooters.id, S.shooters.uid) or #army.shooters == 0) then
    S.shooters = nil
  end
  if S.split == nil and S.shooters == nil then
    S.splitTo = nil
    return
  end
  local size = #army.split + #army.shooters
  if S.splitSize ~= nil and size > S.splitSize then
    S.splitTarget = nil                                         -- hunters came back, order again
  end
  S.splitSize = size
  if splitTargetHolds(S) then return end

  local X = S.splitTo
  local lead = army.split[1] or army.shooters[1]
  local fromArea = area(lead.tile)
  local target = nil
  if S.split ~= nil then
    local id, bx, by = nearestBuilding(a, X, fromArea, lead.x, lead.y, memo)
    if id ~= nil then
      local uid = rd32(building(id) + B.UID)
      F.instruction(G.tribesThis, S.split.id, ORDER_ATTACK_BUILDING, id, uid, 0)
      target = { kind = "building", id = id, uid = uid, x = bx, y = by }
      diag("player %d: split troop attacks building %d of player %d", a, id, X)
    else
      local wall = nearestWall(a, X, fromArea, lead.x, lead.y, memo)
      if wall ~= nil then
        F.instruction(G.tribesThis, S.split.id, ORDER_ATTACK_WALL, wall, 0, 0)
        local wx, wy = tileXY(wall)
        target = { kind = "wall", tile = wall, x = wx, y = wy }
        diag("player %d: split troop attacks a wall of player %d", a, X)
      end
    end
  end
  if target == nil then
    -- nothing in reach to attack, or only shooters left: to the keep, fighting on the way
    if S.splitTarget ~= nil and S.splitTarget.kind == "move" then return end
    local kx, ky = tileXY(keepTile(X))
    target = { kind = "move", x = kx, y = ky }
    if S.split ~= nil then F.move(G.tribesThis, S.split.id, kx, ky, 0, 0, 0) end
    diag("player %d: split troop walks to the keep of player %d", a, X)
  end
  S.splitTarget = target
  if S.split ~= nil then F.setStance(G.tribesThis, S.split.id, STANCE_AGGRESSIVE) end
  if S.shooters ~= nil then
    F.move(G.tribesThis, S.shooters.id, target.x, target.y, 0, 0, 0)
    F.setStance(G.tribesThis, S.shooters.id, STANCE_AGGRESSIVE)
  end
end

---------------------------------------------------------------------------------------
-- 2. The lord hunt
---------------------------------------------------------------------------------------

local function releaseHunt(a, S, units, why)
  for _, u in ipairs(units) do
    local into = nil
    if S.hunt.source == "split" then into = RANGED[u.kind] and S.shooters or S.split end
    giveBack(u, into)
  end
  diag("player %d: %d hunters back to the siege (%s)", a, #units, why)
end

local function startHunt(a, S, group, source, lord, lordArea, memo, wave, tick)
  local candidates, reachable = 0, {}
  for _, u in ipairs(group) do
    candidates = candidates + 1
    if reaches(memo, a, area(u.tile), lordArea) then reachable[#reachable + 1] = u end
  end
  if #reachable == 0 then return end
  local n = #reachable
  if wave == 1 then
    n = (candidates * aicOption(a, "AttLordHuntShare") + 99) // 100
    if n > #reachable then n = #reachable end
  end
  table.sort(reachable, function(l, r)
    local lr, rr = HUNT_RANK[l.behaviour], HUNT_RANK[r.behaviour]
    if lr ~= rr then return lr < rr end
    return distance(l.x, l.y, lord.x, lord.y) < distance(r.x, r.y, lord.x, lord.y)
  end)
  local chosen = {}
  for index = 1, n do chosen[index] = reachable[index] end
  local id, uid = newTribe(a, chosen)
  if id == nil then return end
  F.instruction(G.tribesThis, id, ORDER_ATTACK_UNIT, lord.id, lord.uid, 0)
  S.hunt = { id = id, uid = uid, source = source, wave = wave, ordered = tick, closedSince = nil }
  if source == "split" then S.splitTarget = nil end
  diag("player %d: wave %d, %d of %d troops hunt the lord of player %d", a, wave, n, candidates, S.orig)
end

local function splitGroup(army)
  local group = {}
  for _, u in ipairs(army.split) do group[#group + 1] = u end
  for _, u in ipairs(army.shooters) do group[#group + 1] = u end
  return group
end

local function huntLord(a, S, army, lord, memo, tick)
  local lordArea = area(lord.tile)
  local source, group = "main", army.main
  if S.splitTo ~= nil and area(keepTile(S.splitTo)) == lordArea then
    source, group = "split", splitGroup(army)
  end

  if S.hunt ~= nil and tribeAlive(S.hunt.id, S.hunt.uid) and #army.hunt > 0 then
    local stuck, going = {}, 0
    for _, u in ipairs(army.hunt) do
      if reaches(memo, a, area(u.tile), lordArea) then going = going + 1 else stuck[#stuck + 1] = u end
    end
    if going == 0 then
      S.hunt.closedSince = S.hunt.closedSince or tick
      if tick - S.hunt.closedSince >= CLOSED_TICKS then
        releaseHunt(a, S, army.hunt, "the way to the lord is closed")
        S.hunt = nil
      end
      return
    end
    S.hunt.closedSince = nil
    if #stuck > 0 then releaseHunt(a, S, stuck, "cut off") end
    if tick - S.hunt.ordered >= REORDER_TICKS then
      for _, u in ipairs(army.hunt) do
        local base = unit(u.id)
        if rd16(base + U.TARGETING) ~= ORDER_ATTACK_UNIT or rd16(base + U.TARGET_UNIT) ~= lord.id then
          F.instruction(G.tribesThis, S.hunt.id, ORDER_ATTACK_UNIT, lord.id, lord.uid, 0)
          S.hunt.ordered = tick
          break
        end
      end
    end
    return
  end

  if S.hunt ~= nil then
    -- every hunter is gone: the rest of that army goes, once
    local wave = S.hunt.wave
    source = S.hunt.source
    group = source == "split" and splitGroup(army) or army.main
    S.hunt = nil
    if wave >= 2 then
      S.huntOver = true
      diag("player %d: the second wave of hunters is gone too", a)
      return
    end
    startHunt(a, S, group, source, lord, lordArea, memo, 2, tick)
    return
  end

  if not S.huntOver then
    startHunt(a, S, group, source, lord, lordArea, memo, 1, tick)
  end
end

---------------------------------------------------------------------------------------
-- The check, once per AI player per AI update
---------------------------------------------------------------------------------------

local function finish(a, S, state)
  local released = 0
  for _, which in ipairs({ "hunt", "split", "shooters" }) do
    local kept = S[which]
    if kept ~= nil and tribeAlive(kept.id, kept.uid) then
      for _, u in ipairs(unitsOfTribe(a, kept.id)) do
        giveBack(u, nil)
        released = released + 1
      end
    end
  end
  if released > 0 and (state == 0 or state == 9) then
    F.goDefensive(G.aiState, a)            -- the retreat order went out before they were back
  end
  wr32(G.override + a * 4, 0)
  if S.host ~= nil and not S.inferred and rd32(player(a) + P.ATTACKED) == S.host then
    wr32(player(a) + P.ATTACKED, S.orig)
  end
  if released > 0 or S.host ~= nil then
    diag("player %d: attack over (state %d), %d units back to the AI", a, state, released)
  end
end

-- An attack already pointed at an ally's castle when the game was loaded: the lord of a human
-- ally of that castle's owner sitting in it is who it was for.
local function inferOrigin(a, t)
  if t < 1 or t > 8 or not hasKeep(t) then return nil end
  local hostArea = area(keepTile(t))
  for h = 1, 8 do
    if h ~= t and h ~= a and team(h) == team(t) and isHuman(h) then
      local lord = aliveLord(h)
      if lord ~= nil and area(lord.tile) == hostArea then return h end
    end
  end
  return nil
end

local function update(a)
  local tick = rd32(G.ticks)
  if lastTick == nil or tick < lastTick or tick - lastTick > LOAD_GAP then
    attackers, swept = {}, {}
    for p = 0, 8 do wr32(G.override + p * 4, 0) end
  end
  lastTick = tick

  local base = player(a)
  if rd32(base + P.AI_TYPE) == 0 then return end
  if not swept[a] then
    swept[a] = true
    sweep(a)
  end

  local S = attackers[a]
  local state = rd32(base + P.AI_STATE)
  if state < ACTIVE_FIRST or state > ACTIVE_LAST or (state == 1 and S == nil) then
    if S ~= nil then
      finish(a, S, state)
      attackers[a] = nil
    end
    return
  end

  local t = rd32(base + P.ATTACKED)
  if S == nil then
    if isHuman(t) then
      S = { orig = t, peak = 0 }
    else
      local h = inferOrigin(a, t)
      if h == nil then return end                 -- an AI attacking an AI: not ours
      S = { orig = h, host = t, inferred = true, redirected = true, peak = 0 }
      wr32(G.override + a * 4, t)
    end
    attackers[a] = S
  end

  local lord = aliveLord(S.orig)
  if lord == nil then
    finish(a, S, state)
    S.split, S.shooters, S.splitTo, S.hunt, S.huntOver = nil, nil, nil, nil, true
    return
  end

  local army = collect(a, S, S.orig)
  local force = rd32(G.aiState + (rd32(base + P.AI_TYPE) - 1) * AIC_STRIDE + AIC_ATTACK_FORCE)
  if army.attack > S.peak then S.peak = army.attack end
  if force > S.peak then S.peak = force end

  local memo = {}
  if O.hiding and not S.redirected then
    checkHiding(a, S, army, lord, memo, state)
  end
  orderSplit(a, S, army, memo)
  if O.hunt and aicOption(a, "AttLordHuntShare") > 0 then
    huntLord(a, S, army, lord, memo, tick)
  elseif S.hunt ~= nil then
    releaseHunt(a, S, army.hunt, "hunting disabled for this character")
    S.hunt = nil
  end
end

---------------------------------------------------------------------------------------
-- Injected code
---------------------------------------------------------------------------------------

-- Replaces the call right after the AI's attack state update: note the player and the AI
-- state object, run the lua check (a detour on PAD), then go on to what the call did before.
-- Replaces the call to the AI's monthly target choice: run it, then put back a target this
-- module pointed the attack at (OVERRIDE: one dword per player, 0 = leave it).
local SELECT_STUB = [[
push dword [esp+4]
call ORIGINAL_SELECT
mov eax,[esp+4]
mov edx,[OVERRIDE+eax*4]
test edx,edx
jz done
imul eax,eax,PLAYER_STRIDE
mov [eax+ATTACKED],edx
done:
ret 4
]]

local STUB = [[
mov eax,[esp+4]
mov [PLAYER],eax
mov [THIS],ecx
call PAD
jmp ORIGINAL_TARGET
]]

---------------------------------------------------------------------------------------
-- Enable
---------------------------------------------------------------------------------------

local function resolve()
  local calls = scan(AOB_CALLS, "the AI's per player update")
  local stateUpdate = readCallTarget(calls, CALL_STATE, "the AI attack state update")
  local vanilla = scanOptional(AOB_STATE_UPDATE)
  if vanilla ~= nil and vanilla ~= stateUpdate then
    error(MODULE_NAME .. ": another module has replaced the AI's attack logic; Lord Hunt stays off")
  end
  G.site = calls + CALL_HOOK
  G.original = readCallTarget(calls, CALL_HOOK, "the call after the AI attack state update")
  local select = scan(AOB_SELECT_CALL, "the AI's target choice")
  G.selectSite = select + CALL_SELECT
  G.selectOriginal = readCallTarget(select, CALL_SELECT, "the AI's target choice")
  local selectVanilla = scanOptional(AOB_SELECT)
  if selectVanilla ~= nil and selectVanilla ~= G.selectOriginal then
    error(MODULE_NAME .. ": another module has replaced the AI's target choice; Lord Hunt stays off")
  end

  local its = scan(AOB_ADD_TO_ITS_TRIBE, "where the AI puts a unit in its troop")
  G.units = readOperand(its, ITS_UNIT_OWNER, "the unit array") - U.OWNER
  G.unitsThis = G.units - U.STATE_OFFSET
  G.players = readOperand(its, ITS_AI_TYPE, "the player array") - P.AI_TYPE
  G.tribesThis = readOperand(its, ITS_TRIBES, "the troop array")
  local addToTribe = readCallTarget(its, ITS_ADD_TO_TRIBE, "addUnitToTribe")
  if scan(AOB_ADD_TO_TRIBE, "addUnitToTribe") ~= addToTribe then
    error(MODULE_NAME .. ": addUnitToTribe is not where the module expects it")
  end
  local remove = scan(AOB_REMOVE_FROM_TRIBE, "removeUnitFromTribe")
  G.tribeStride = readOperand(remove, REMOVE_STRIDE, "the troop size")
  G.tribes = G.tribesThis

  local k2k = scan(AOB_KEEP_TO_KEEP, "the keep to keep test")
  local hasKeepOffset = readOperand(k2k, K2K_HAS_KEEP, "the keep fields")
  local keepTileOffset = readOperand(k2k, K2K_KEEP_TILE, "the keep fields")
  if keepTileOffset - hasKeepOffset ~= P.KEEP_TILE - P.HAS_KEEP then
    error(MODULE_NAME .. ": the keep fields are not laid out as the module expects")
  end
  G.area = readOperand(k2k, K2K_AREA, "the area map")
  G.paths = readOperand(k2k, K2K_PATHS, "the path finder")
  local canNavigate = readCallTarget(k2k, K2K_CAN_NAVIGATE, "the area test")

  local random = scan(AOB_RANDOM_BUILDING, "the AI's building target list")
  if readOperand(random, RANDOM_TARGETABLE, "the target list") ~= G.players + P.TARGETABLE_COUNT then
    error(MODULE_NAME .. ": the player array is not laid out as the module expects")
  end
  G.buildings = readOperand(random, RANDOM_BUILDING_TYPE, "the building array") - 0xD2

  G.teams = rd32(scan(AOB_TEAMS, "the team table") + TEAMS_OPERAND)
  G.ticks = rd32(scan(AOB_TICKS, "the game tick counter") + TICKS_OPERAND)
  local tileMap = rd32(scan(AOB_TILE_FLAGS, "the tile flags") + TILE_FLAGS_OPERAND) - MAP.FLAGS
  G.flags = tileMap + MAP.FLAGS
  G.wallOwner = tileMap + MAP.WALL_OWNER
  G.rows = tileMap + MAP.ROWS
  G.yOfTile = tileMap + MAP.Y_OF_TILE
  if G.area ~= tileMap + MAP.AREA then
    error(MODULE_NAME .. ": the map layers are not laid out as the module expects")
  end

  F.createTribe = core.exposeCode(scan(AOB_CREATE_TRIBE, "createTribeForPlayer"), 2, 1)
  F.addToTribe = core.exposeCode(addToTribe, 3, 1)
  F.removeFromTribe = core.exposeCode(remove, 3, 1)
  F.addToItsTribe = core.exposeCode(its, 3, 1)
  F.instruction = core.exposeCode(scan(AOB_INSTRUCTION, "giveTribeAnInstruction"), 6, 1)
  F.setStance = core.exposeCode(scan(AOB_STANCE, "setUnitStance"), 3, 1)
  F.move = core.exposeCode(scan(AOB_MOVE, "giveTribeMoveInstruction"), 7, 1)
  F.canNavigate = core.exposeCode(canNavigate, 5, 1)
  F.goDefensive = core.exposeCode(scan(AOB_GO_DEFENSIVE, "the AI's retreat order"), 2, 1)
end

local function enable(self, config)
  config = config or {}
  O.hiding = setting(config, "hiding", "enabled") == true
  O.siegeOnHiding = setting(config, "hiding", "siege") ~= "home"
  O.split = percent(setting(config, "hiding", "split"))
  O.switchAlive = percent(setting(config, "hiding", "switch_alive"))
  O.hunt = setting(config, "hunt", "enabled") == true
  O.huntShare = percent(setting(config, "hunt", "share"))
  O.log = setting(config, "diagnostics", "log") == true
  if not O.hiding and not O.hunt then
    log(INFO, MODULE_NAME .. ": both parts are off")
    return
  end

  local ok, problem = pcall(resolve)
  if not ok then
    log(WARNING, tostring(problem))
    return
  end

  registerAICOptions()

  local slots = core.allocate(8, true)
  local pad = core.allocateCode({ 0x90, 0x90, 0x90, 0x90, 0x90, 0xC3 })
  core.detourCode(function(registers)
    if not paused and not broken then
      G.aiState = rd32(slots + 4)
      local done, problem = pcall(update, rd32(slots))
      if not done then
        broken = true
        log(WARNING, MODULE_NAME .. ": stopped after an error: " .. tostring(problem))
      end
    end
    return registers
  end, pad, 5)
  local stub = core.allocateAssembly(STUB, {
    PLAYER = slots, THIS = slots + 4, PAD = pad, ORIGINAL_TARGET = G.original,
  })
  G.override = core.allocate(9 * 4, true)
  for p = 0, 8 do wr32(G.override + p * 4, 0) end
  local selectStub = core.allocateAssembly(SELECT_STUB, {
    ORIGINAL_SELECT = G.selectOriginal, OVERRIDE = G.override, PLAYER_STRIDE = P.STRIDE,
    ATTACKED = G.players + P.ATTACKED,
  })
  self.saved = {
    { address = G.site, bytes = core.readBytes(G.site, 5) },
    { address = G.selectSite, bytes = core.readBytes(G.selectSite, 5) },
  }
  core.writeCode(G.site, { 0xE8, core.itob(core.getRelativeAddress(G.site, stub, -5)) })
  core.writeCode(G.selectSite, { 0xE8, core.itob(core.getRelativeAddress(G.selectSite, selectStub, -5)) })
  log(INFO, string.format("%s: on (lord hiding %s, lord hunt %s); hooked 0x%X, units 0x%X, players 0x%X, "
    .. "troops 0x%X (size 0x%X), area map 0x%X", MODULE_NAME, O.hiding and "on" or "off",
    O.hunt and "on" or "off", G.site, G.units, G.players, G.tribes, G.tribeStride, G.area))
end

local function disable(self, config)
  if self.saved ~= nil then
    for name in pairs(AIC_OPTIONS) do
      modules.aicloader:setAdditionalAICValue(name, nil)
    end
    valuesByAI = {}
  end
  if self.saved ~= nil then
    for _, saved in ipairs(self.saved) do core.writeCode(saved.address, saved.bytes) end
    self.saved = nil
  end
end

---------------------------------------------------------------------------------------
-- For other modules: modules["lord-hunt"]:isHunter(unitId) and friends
---------------------------------------------------------------------------------------

local function inTroop(unitId, which)
  if G.units == nil or unitId == nil or unitId <= 0 then return false end
  local id = rd16(unit(unitId) + U.TRIBE)
  for _, S in pairs(attackers) do
    local kept = S[which]
    if kept ~= nil and kept.id == id and tribeAlive(kept.id, kept.uid) then return true end
  end
  return false
end

return {
  enable = enable,
  disable = disable,
  -- true while the unit is hunting a lord
  isHunter = function(self, unitId) return inTroop(unitId, "hunt") end,
  -- true while the unit is in a troop split off to attack the other castle
  isSplit = function(self, unitId) return inTroop(unitId, "split") or inTroop(unitId, "shooters") end,
  -- stop or resume the module's checks (troops it already moved stay where they are)
  pause = function(self, on) paused = on and true or false end,
}
