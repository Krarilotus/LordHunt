# Lord Hunt

**Auteur** : Monsterfish
**Version** : 1.0.3

Vous empêche de cacher votre seigneur à l'IA. Chaque partie peut être désactivée séparément dans les paramètres.

## Seigneur caché dans un château allié

Normalement, une IA attaquante ne vise que votre propre donjon. Si votre seigneur est installé dans un château allié, l'IA rase votre château vide sans jamais l'approcher.

Avec ce module, lorsque votre seigneur se trouve hors de vos propres murs et derrière les murs d'un allié où les attaquants ne peuvent pas entrer librement :

- **Vous avez encore des habitants et des bâtiments chez vous :** l'armée se divise. Par défaut, le siège complet (tentes de siège, ingénieurs, échelles, comblement des douves) vise le château où se trouve votre seigneur, tandis que la moitié de l'armée attaque votre propre château de manière autonome. Vous pouvez inverser la cible du siège complet et ajuster la répartition.
- **Votre château est vide :** toute l'armée marche sur le château où se trouve votre seigneur.
- **Votre seigneur s'y réfugie pendant une attaque déjà en cours :** les attaquants ne changent de cible que s'il leur reste la majeure partie de leur armée (80 % par défaut).

Les troupes détachées attaquent le bâtiment accessible le plus proche, puis le suivant. Quand aucun bâtiment n'est accessible, elles frappent les murs. Les archers, arbalétriers et frondeurs les accompagnent et tirent sur les troupes ennemies rencontrées au lieu de gaspiller leurs flèches sur les bâtiments.

## Chasse au seigneur

Dès que les attaquants ont un chemin dégagé jusqu'à votre seigneur, la moitié de l'armée attaquant ce château fonce directement sur lui. Un chemin dégagé peut être un mur ou une porte détruits, une échelle, une tour de siège, un tunnel effondré, ou simplement votre seigneur à découvert. Le reste poursuit le siège.

- **Qui part à la chasse :** d'abord les troupes de l'armée principale les plus proches de votre seigneur, puis les autres troupes d'attaque. Les engins de siège, ingénieurs, écheliers et tunneliers restent à leur poste.
- **Si tous les chasseurs tombent :** le reste de cette armée fonce sur le seigneur.
- **Si vous refermez le passage (en réparant le mur) :** les chasseurs retournent au siège.
- **Retraite :** l'IA décide toujours du repli exactement comme avant.

## Bon à savoir

- **Qui est concerné :** uniquement les attaques de l'IA contre des joueurs humains. Les combats IA contre IA ne sont pas modifiés.
- **Sauvegardes :** rien n'est enregistré dans vos sauvegardes. Après chargement, les troupes démarrent normalement et retrouvent leurs ordres lors de la vérification suivante de l'IA, quelques instants plus tard.
- **Autres mods :** si un autre mod a remplacé la logique d'attaque de l'IA, ce module reste inactif et le signale dans `ucp3.log`.
