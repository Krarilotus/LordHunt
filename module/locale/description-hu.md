# Lord Hunt

**Szerző**: Monsterfish
**Verzió**: 1.0.3

Megakadályozza, hogy elrejtsd a lordodat az MI elől. Minden része külön kikapcsolható a beállításokban.

## Szövetséges várban rejtőző lord

Alapesetben a támadó MI csak a saját vártornyodra megy. Ha a lordod egy szövetséges várában ül, az MI lerombolja az üres otthonodat, de sosem jut a közelébe.

Ezzel a modullal, ha a lordod a saját falaidon kívül, de egy szövetséges falain belül van, ahová a támadók nem tudnak besétálni:

- **Még vannak embereid és épületeid otthon:** a sereg kettéválik. Alapértelmezés szerint a teljes ostrom (ostromsátrak, mérnökök, létrák, árokbetemetés) a lordodat rejtő várat éri, a sereg fele pedig önállóan támadja a saját váradat. Felcserélheted, melyik vár kapja a teljes ostromot, és módosíthatod az arányt.
- **A várad üres:** az egész sereg a lordodat rejtő vár ellen indul.
- **A lordod már folyamatban lévő támadás közben menekül oda:** a támadók csak akkor váltanak célt, ha a seregük nagy része még él (alapértelmezés szerint 80%).

A leváló csapatok a legközelebbi elérhető épületet támadják, majd a következőt. Ha egyet sem érnek el, a falakat verik. Az íjászok, számszeríjászok és parittyások velük tartanak, és a szembejövő katonákra lőnek ahelyett, hogy épületekre pazarolnák a nyilaikat.

## Vadászat a lordra

Amint a támadóknak szabad útjuk van a lordodhoz, az adott várat támadó sereg fele egyenesen rá ront. Szabad út lehet egy áttört fal vagy kapuház, létra, ostromtorony, beomlott alagút, vagy egyszerűen az, hogy a lordod nyílt terepen áll. A többiek folytatják az ostromot.

- **Kik indulnak:** először a lordodhoz legközelebb álló fősereg-egységek, majd a többi támadó csapat. Az ostromgépek, mérnökök, létrahordozók és alagútásók a feladatuknál maradnak.
- **Ha minden vadász meghal:** a sereg többi része is a lordra támad.
- **Ha újra lezárod az utat (megjavítod a falat):** a vadászok visszatérnek az ostromhoz.
- **Visszavonulás:** az MI továbbra is pontosan ugyanúgy dönt a visszavonulásról.

## Jó tudni

- **Kit érint:** csak az emberi játékosok elleni MI-támadásokat. Az MI kontra MI harcok változatlanok.
- **Mentések:** semmi nem kerül a mentésbe. Betöltés után a csapatok normálisan indulnak, és néhány pillanattal később, az MI következő ellenőrzésekor újra megkapják a feladataikat.
- **Más modok:** ha egy másik mod lecserélte az MI támadási logikáját, ez a modul kikapcsolva marad, és ezt jelzi a `ucp3.log` fájlban.
