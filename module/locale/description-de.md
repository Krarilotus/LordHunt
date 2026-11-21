# Lord Hunt

**Autor**: Monsterfish
**Version**: 1.0.3

Verhindert, dass du deinen Lord vor der KI verstecken kannst. Jeder Teil lässt sich in den Einstellungen einzeln abschalten.

## Lord versteckt sich in einer verbündeten Burg

Normalerweise greift eine KI immer nur deinen eigenen Bergfried an. Sitzt dein Lord in einer verbündeten Burg, zerstört die KI deine leere Heimatburg und kommt nie in seine Nähe.

Mit diesem Modul gilt, sobald dein Lord außerhalb deiner eigenen Mauern und innerhalb der Mauern eines Verbündeten steht, in die die Angreifer nicht einfach hineinmarschieren können:

- **Du hast zu Hause noch Leute und Gebäude:** Die Armee teilt sich auf. Standardmäßig geht die volle Belagerung (Belagerungslager, Baumeister, Leitern, Grabenausheben) gegen die Burg, in der dein Lord sitzt, während die halbe Armee auf eigene Faust deine eigene Burg angreift. Du kannst vertauschen, welche Burg die volle Belagerung abbekommt, und den Anteil anpassen.
- **Deine Burg ist leer:** Die gesamte Armee zieht gegen die Burg, in der sich dein Lord aufhält.
- **Dein Lord flieht während eines bereits laufenden Angriffs dorthin:** Die Angreifer schwenken nur um, wenn noch der Großteil ihrer Armee lebt (standardmäßig 80 %).

Die abgespaltenen Truppen greifen das nächste erreichbare Gebäude an und dann das nächste. Ist keines erreichbar, schlagen sie auf die Mauern ein. Bogenschützen, Armbrustschützen und Steinschleuderer ziehen mit und beschießen feindliche Truppen, statt Pfeile an Gebäuden zu verschwenden.

## Jagd auf den Lord

Sobald die Angreifer einen freien Weg zu deinem Lord haben, stürmt die Hälfte der angreifenden Armee direkt auf ihn los. Ein freier Weg kann eine zerstörte Mauer oder ein zerstörtes Torhaus sein, eine Leiter, ein Belagerungsturm, ein eingestürzter Tunnel oder schlicht, dass dein Lord im Freien steht. Der Rest führt die Belagerung fort.

- **Wer loszieht:** Zuerst die Truppen der Hauptarmee, die deinem Lord am nächsten stehen, dann die übrigen Angriffstruppen. Belagerungsgeräte, Baumeister, Leiterträger und Tunnelgräber bleiben bei ihren Aufgaben.
- **Wenn alle Verfolger fallen:** Der Rest dieser Armee geht auf den Lord los.
- **Wenn du den Weg wieder schließt (Mauer reparierst):** Die Verfolger kehren zur Belagerung zurück.
- **Rückzug:** Die KI entscheidet weiterhin genauso wie zuvor, wann sie sich zurückzieht.

## Gut zu wissen

- **Wen es betrifft:** Nur KI-Angriffe auf menschliche Spieler. KI gegen KI bleibt unverändert.
- **Spielstände:** In deinem Spielstand wird nichts gespeichert. Nach dem Laden verhalten sich die Truppen zunächst normal und erhalten ihre Aufgaben bei der nächsten Prüfung der KI wenige Augenblicke später zurück.
- **Andere Mods:** Hat ein anderes Modul die Angriffslogik der KI ersetzt, bleibt dieses Modul deaktiviert und vermerkt dies in `ucp3.log`.
