# Lord Hunt

A UCP3 module for Stronghold Crusader and Stronghold Crusader Extreme. It stops you hiding your
lord from the AI: an attack follows him into an ally's castle (splitting the army between that
castle and your own), and once the attackers have an open way to him, part of the army goes
straight for him.

What the module does, in plain English, is in `module/locale/description-en.md`.

## What is in here

| Folder | |
|---|---|
| `module/` | the module itself - this is the source of truth, edited in place |
| `tools/publish.py` | copies `module/` into the game's module folder under a new version |

## Working on it

1. Edit under `module/`.
2. `python tools/publish.py --bump` - raises the last version slot and copies the module to
   `ucp/modules/lord-hunt-<version>`. Do this with the game closed.
3. In the UCP GUI press F5, then apply.
4. Commit and tag: `git commit -am "<version> - <what changed>" && git tag v<version>`.

## How it works

* **One hook.** In `updateAIBehaviour` the call right after the AI's attack state update
  (`updateAIPlayerState`) is pointed at a stub that runs the lua check for that AI player and
  then jumps on to what the call pointed at before. If the attack state update itself has been
  replaced by another module, Lord Hunt stays off.
* **Troops are the game's own.** Hunters and split-off troops are moved with the game's own
  `createTribeForPlayer` / `removeUnitFromTribe` / `addUnitToTribe` and given the game's own
  tribe orders (attack unit 4, attack building 9, attack wall 0x17, move). A troop that is not
  in the AI's `aiTribeIDs` list never gets AI orders, so hunters stay on the lord. Going back
  is the AI's own `addUnitToItsTribe`.
* **Where the lord is.** The game's area map (built with every gate shut) tells which walled
  area the lord stands in; the AI's own area-to-area test (`calculateCanPlayerUnitsNavigateTo
  AreaFromArea`, modes 0 and 2, the two it uses to call a castle breached) tells whether the
  army can get there.
* **Hiding.** `attackedPlayerID` is pointed at the ally and the AI state set back to 1, so the
  AI plans its siege on the new castle. It is put back when the attack ends.
* **Saves.** Nothing is saved. After a load, attack units in unregistered troops go back to the
  AI's troops, and the next check picks again.
* **Other modules** can ask `modules["lord-hunt"]:isHunter(unitId)`, `:isSplit(unitId)` and
  `:pause(true/false)`.

## Per-character AIC settings

Add these integer fields under an AI character's existing `Personality` section for AIC
Loader 1.1.1 or later in the 1.x series. Omitted fields use the values in Customizations.
The global hunt and hiding switches still govern their respective features.

| AIC field | Values |
| --- | --- |
| `AttLordHuntShare` | Initial share sent after the lord, 0–100%. Zero disables hunting for the character. |
| `AttRedirectHidingSplit` | Share sent to the castle without the main siege, 0–100%. Zero sends the whole army to the hiding castle. |
| `AttRedirectHidingSwitchAlive` | Minimum surviving share required to switch targets mid-attack, 0–100%. |
| `AttRedirectHidingSiege` | 0 sends the main siege to the original castle, 1 to the hiding castle. Applies when a split is possible. |
