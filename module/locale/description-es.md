# Lord Hunt

**Autor**: Monsterfish
**Versión**: 1.0.3

Evita que escondas a tu señor de la IA. Cada parte puede desactivarse por separado en los ajustes.

## Señor escondido en un castillo aliado

Normalmente, una IA atacante solo va a por tu propia fortaleza. Si tu señor se refugia en el castillo de un aliado, la IA destruye tu castillo vacío y nunca se acerca a él.

Con este módulo, cuando tu señor está fuera de tus propios muros y dentro de los muros de un aliado a los que los atacantes no pueden entrar a pie:

- **Si aún tienes habitantes y edificios en casa:** el ejército se divide. Por defecto, el asedio completo (campamentos de asedio, ingenieros, escaleras, relleno de fosos) va al castillo donde está tu señor, y la mitad del ejército ataca tu castillo por su cuenta. Puedes intercambiar qué castillo recibe el asedio completo y cambiar el porcentaje.
- **Si tu castillo está vacío:** todo el ejército marcha contra el castillo donde está tu señor.
- **Si tu señor se refugia allí durante un ataque ya en marcha:** los atacantes solo cambian de objetivo si aún conservan la mayor parte de su ejército (80 % por defecto).

Las tropas separadas atacan el edificio alcanzable más cercano y luego el siguiente. Cuando no alcanzan ninguno, golpean los muros. Los arqueros, ballesteros y honderos avanzan con ellas y disparan a las tropas que encuentran en lugar de desperdiciar flechas contra edificios.

## Caza al señor

En cuanto los atacantes tienen un camino abierto hacia tu señor, la mitad del ejército que ataca ese castillo va directamente a por él. Un camino abierto puede ser un muro o una puerta destruidos, una escalera, una torre de asedio, un túnel derrumbado o simplemente que tu señor esté a campo abierto. El resto continúa el asedio.

- **Quién va:** primero las tropas del ejército principal más cercanas a tu señor, y después el resto de tropas de ataque. Las máquinas de asedio, ingenieros, escaladores y zapadores siguen en sus tareas.
- **Si mueren todos los perseguidores:** el resto de ese ejército va a por el señor.
- **Si vuelves a cerrar el paso (reparando el muro):** los perseguidores regresan al asedio.
- **Retirada:** la IA sigue decidiendo cuándo retirarse exactamente igual que antes.

## Conviene saber

- **A quién afecta:** solo a ataques de la IA contra jugadores humanos. Los combates IA contra IA no cambian.
- **Partidas guardadas:** no se guarda nada en la partida. Al cargar, las tropas empiezan con normalidad y recuperan sus tareas en la siguiente comprobación de la IA, unos instantes después.
- **Otros mods:** si otro mod ha sustituido la lógica de ataque de la IA, este módulo permanece inactivo y lo indica en `ucp3.log`.
