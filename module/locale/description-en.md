# Lord Hunt

**Author**: Monsterfish
**Version**: 1.0.2

Stops you hiding your lord from the AI. Every part can be switched off in the settings.

## Lord hiding in an ally's castle

Normally an attacking AI only goes for your own keep. If your lord is sitting in an ally's
castle, the AI wrecks your empty home and never gets near him.

With this module, when your lord is outside your own walls and inside an ally's walls that the
attackers can't walk into:

- **You still have people and buildings at home:** the army splits. By default the full siege
  (siege camps, engineers, ladders, moat filling) goes to the castle your lord is in, and half
  the army attacks your own castle on its own. You can swap which castle gets the full siege,
  and change the share.
- **Your castle is empty:** the whole army goes for the castle your lord is in.
- **Your lord moves there while an attack is already under way:** the attackers only switch if
  they still have most of their army (80% by default).

The split-off troops attack the nearest building they can reach, then the next one. When they
can't reach any, they hack at the walls. Archers, crossbowmen and slingers walk along with
them and shoot the troops they meet, rather than wasting arrows on buildings.

## Lord hunt

As soon as the attackers have an open way to your lord, half of the army attacking that castle
goes straight for him. An open way can be a broken wall or gate, a ladder, a siege tower or a
collapsed tunnel, or your lord simply being out in the open. The rest carry on with the siege.

- **Who goes:** the main army troops closest to your lord go first, then the other attack
  troops. Siege engines, engineers, laddermen and tunnellers stay on their jobs.
- **If the hunters all die:** the rest of that army goes for the lord.
- **If you close the way again (repair the wall):** the hunters go back to the siege.
- **Retreat:** the AI still decides when to retreat, exactly as before.

## Good to know

- **Who it affects:** only AI attacks on human players. AI against AI is left alone.
- **Saves:** nothing is written to your save. After loading, the troops start out normal and get
  their jobs again on the AI's next check, a few moments later.
- **Other mods:** if another mod has replaced the AI's attack logic, this module stays off and
  says so in `ucp3.log`.
