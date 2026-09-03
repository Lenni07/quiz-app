# Quiz-App – Erweiterte Vision & Roadmap (über das MVP hinaus)

Dieses Dokument ergänzt die bestehende `CLAUDE.md`. Die dortige Phase 1 (MVP) bleibt technisch das Fundament und wird **nicht** rückgebaut – die folgenden Phasen bauen schrittweise darauf auf. Am Ende steht eine Zusammenfassung, welche Punkte der ursprünglichen "Kein X"-Liste aus der MVP-Phase jetzt bewusst aufgehoben werden.

## 1. Gesamtvision

- Mehr Spielformate, inklusive Formate mit echter Drag-and-Drop-Interaktion (Match Up, Word Magnets, Group Sort, Rank Order, ...).
- Nutzerkonten mit gespeichertem Fortschritt und Statistiken.
- **Lokales Mehrspieler-Duell:** Zwei oder mehr Spieler auf demselben Schiff spielen gegeneinander – kostenlos, ohne Internetverbindung nötig (nur Schiffs-WLAN bzw. direkte Geräteverbindung).
- **Schiffsübergreifender monatlicher "Flottenkrieg":** Spieler unterschiedlicher Schiffe sammeln über einen Monat Punkte für ihr jeweiliges Schiff – ähnlich einem Clan-Krieg/Clan-Liga-System wie bei Clash of Clans/Clash Royale, nur mit "Schiff" statt "Clan" und einem monatlichen statt wöchentlichen Zyklus.

## 2. Wichtige Rahmenbedingung: Internet auf Schiffen

Das prägt die technische Architektur entscheidend, deshalb vorab explizit festgehalten:

- Das interne Schiffs-WLAN funktioniert meist **ohne** kostenpflichtige Internetverbindung – Geräte im selben Netzwerk können sich direkt erreichen.
- Echtes Internet (für schiffsübergreifende Funktionen) läuft über Satellit – oft langsam, limitiert oder kostenpflichtig.
- **Konsequenz:** Es braucht zwei getrennte technische Wege, keinen gemeinsamen:
  1. **Lokales Duell** = rein lokale Verbindung (WLAN ohne Internet oder direkte Geräteverbindung), funktioniert immer und kostenlos.
  2. **Flottenkrieg** = braucht echtes Internet, sollte so datensparsam wie möglich sein (nur kleine Datenmengen wie Punktestände synchronisieren, keine dauerhafte Live-Verbindung).

## 3. Phase 2 – Mehr Spielformate

**Ohne Drag-and-Drop (zuerst umsetzen, da einfacher):**
Quiz, True or False, Gameshow Quiz, Image Quiz, Open the Box, Find the Match, Random Wheel, Flip Tiles (wird im "Glücksrad"-Stil überarbeitet, siehe Abschnitt 12).

~~Higher or Lower, Random Cards, Maths Generator, Balloon Pop~~ – nach dem ersten Test aus der App entfernt, siehe Abschnitt 12.

~~Whack-a-Mole~~ – vorerst aus der App entfernt, wird später überarbeitet und dann wieder aufgenommen, siehe Abschnitt 12.

**Mit Drag-and-Drop (Flutter: `Draggable`, `DragTarget`, `ReorderableListView`):**
Match Up, Word Magnets, Group Sort/Categorize, Rank Order.

**Wichtig für das Datenmodell:** Die JSON-Struktur sollte jetzt schon so angelegt werden, dass sie nicht nur "Frage + 4 Antworten" abbildet, sondern auch Paare (Match Up), Kategorien (Group Sort) und Reihenfolgen (Rank Order) – sonst muss die Datenstruktur später erneut umgebaut werden. Empfehlung: ein `type`-Feld pro Frage/Aktivität, das bestimmt, welches Spiel-Widget die Daten rendert.

## 4. Phase 3 – Accounts, Fortschritt & Statistiken

- **Firebase Authentication** für Nutzerkonten (E-Mail oder anonym mit späterer Verknüpfung – auf einem Schiff mit unsicherem Internet ist ein anonymer Start sinnvoll, mit optionaler Anmeldung sobald Internet verfügbar ist).
- **Cloud Firestore** für Fortschritt/Statistiken – Firestore unterstützt **Offline-Persistenz von Haus aus**: Änderungen werden lokal gespeichert und automatisch synchronisiert, sobald wieder Internet verfügbar ist (z. B. im Hafen). Das passt sehr gut zum Schiffs-Szenario.
- Jeder Nutzer bekommt zusätzlich ein Feld für sein **Schiff** (z. B. Schiffsname/ID) – das ist die Grundlage für Phase 4b.

## 5. Phase 4a – Lokales Mehrspieler-Duell (kostenlos, ohne Internet)

Ziel: Zwei Spieler auf demselben Schiff spielen gegeneinander, unabhängig davon, ob gerade Internet verfügbar ist.

**Technischer Ansatz (zwei Optionen, von einfach zu robust):**

1. **`nearby_connections` (Flutter-Plugin):** Geräte verbinden sich direkt per WLAN/Bluetooth, ganz ohne Router oder Internet. Sehr gut geeignet für "zwei Spieler nebeneinander im Aufenthaltsraum" – funktioniert sogar ganz ohne Schiffs-WLAN.
2. **Lokaler Host im selben WLAN:** Ein Gerät startet einen kleinen lokalen Server (z. B. mit dem Dart-Paket `shelf` + WebSocket), andere Geräte im selben Schiffs-WLAN verbinden sich über die lokale IP-Adresse. Etwas mehr Aufwand, aber auch für mehr als 2 Spieler gleichzeitig geeignet (z. B. eine kleine Runde in der Crew-Lounge).

**Empfehlung:** Mit Option 1 (`nearby_connections`) starten – am wenigsten Infrastruktur, funktioniert garantiert kostenlos und überall auf dem Schiff.

## 6. Phase 4b – Monatlicher "Flottenkrieg" (Schiff gegen Schiff, wie bei Clash of Clans)

Ziel: Spieler unterschiedlicher Schiffe treten gegeneinander an, ihre Punkte zählen für ihr Schiff – organisiert als monatliche Season/Liga, nach dem Vorbild eines Clan-Kriegs in Clash of Clans/Clash Royale.

**Grundprinzip (Clan-Krieg-Logik, übertragen auf Schiffe):**
- Ein **Season-Zyklus von einem Monat**: Punkte werden ab dem 1. eines Monats gesammelt und am Monatsende ausgewertet.
- Jedes Schiff ist wie ein "Clan" – alle Spieler an Bord tragen mit ihren individuellen Ergebnissen zum Schiffs-Gesamtpunktestand bei.
- Am Monatsende: Rangliste aller Schiffe ("Flottenrangliste"), danach **Reset auf 0** für die neue Season (Historie/Bestenliste vergangener Monate bleibt einsehbar).
- Optional wie beim Vorbild: Belohnungen/Abzeichen für die Top-Schiffe der Season, evtl. Auf-/Abstiegs-Ligen (z. B. "Liga Bronze/Silber/Gold" wie bei Clash Royale), falls das später gewünscht ist.

**Technische Umsetzung:**
- Braucht echtes Internet (Satellit) – deshalb bewusst **nicht** wie Phase 4a in Echtzeit mit dauerhafter Verbindung, sondern datensparsam:
  - Punktestände werden nur bei Spielende an Firestore übermittelt (kleine Dokumente, keine dauerhafte Streaming-Verbindung).
  - Duelle gegen Spieler anderer Schiffe können asynchron ablaufen (z. B. "Herausforderung stellen, Gegner antwortet, sobald er/sie online ist") statt Echtzeit – spart Bandbreite und funktioniert auch bei instabiler Satellitenverbindung.
- **Datenmodell:** eigene Firestore-Collection `ships`, darin laufender Season-Punktestand pro Schiff sowie ein Unter-Bereich `seasons` mit den Ergebnissen vergangener Monate. Eine Cloud Function aktualisiert bei jedem übermittelten Spielergebnis automatisch das Schiffs-Total der laufenden Season.
- **Season-Reset:** eine zeitgesteuerte Cloud Function (Scheduled Function), die am Monatsanfang die laufende Season abschließt, in die Historie verschiebt und eine neue Season mit Punktestand 0 startet.

## 7. Architektur-Anpassungen gegenüber dem ursprünglichen MVP

- **State Management:** Wechsel von reinem `setState` zu `Provider` oder `Riverpod` – bei parallelem Auth-Status, lokalem Duell-Status und Online-Sync wird reines `setState` schnell unübersichtlich.
- **Datenhaltung:** Nicht mehr nur eine statische JSON-Datei – Fragen/Aktivitäten weiterhin lokal vorhalten (funktioniert offline), aber Nutzer-, Fortschritts- und Schiffsdaten über Firestore.
- **Offline-first als durchgehendes Prinzip:** Die App muss ohne Internet voll nutzbar bleiben (Quiz spielen, lokal duellieren); alles, was Internet braucht (Flottenkrieg, Accountabgleich), synchronisiert im Hintergrund, sobald Verbindung besteht.

## 8. Welche MVP-Einschränkungen fallen jetzt bewusst weg

| Ursprüngliche MVP-Regel | Status jetzt |
|---|---|
| Kein Server/Backend | Aufgehoben ab Phase 3 (Firebase) |
| Kein Multiplayer | Aufgehoben ab Phase 4a/4b |
| Keine Drag-and-Drop-Fragetypen | Aufgehoben ab Phase 2 (zweiter Teil) |
| Keine Nutzerkonten/Login | Aufgehoben ab Phase 3 |
| Kein Admin-Panel | Bleibt vorerst bestehen (nicht Teil dieser Erweiterung) |
| Keine Joker | Bleibt vorerst bestehen (kann bei Bedarf ergänzt werden) |

## 9. Entwicklungsreihenfolge: Platzhalterinhalte zuerst

Bewusste Entscheidung für den Entwicklungsprozess: Zuerst werden alle Module inkl. Backend technisch fertiggestellt – **ohne** auf echte Frage-/Antwortinhalte zu warten. Dafür reichen frei erfundene Platzhalterinhalte (beliebiger Text, Lückensätze, ausgedachte Paare/Kategorien), solange sie dem jeweiligen Datenschema des Aktivitätstyps entsprechen (siehe `type`-Feld in Abschnitt 3).

- Die eigentlichen Fragen/Antworten (z. B. Deutschunterricht-Inhalte) werden parallel bzw. später separat erarbeitet.
- Sobald die echten Inhalte vorliegen, werden nur die Platzhalterdaten ausgetauscht – an der Modul-/Backend-Logik ändert sich dadurch nichts, solange das Schema eingehalten wurde.
- Für Claude Code heißt das konkret: beim Bauen jedes Moduls einfach passende Platzhalterinhalte selbst ausdenken, nicht auf inhaltliche Vorgaben warten.

## 10. Arbeitsweise: eigenständige Umsetzung ohne Rückfrage pro Modul

Die Formate aus Abschnitt 3 (sowohl ohne als auch **mit** Drag-and-Drop – die ursprüngliche Trennung war nur eine Empfehlung zur Reihenfolge, kein Ausschlusskriterium) werden von Claude Code eigenständig der Reihe nach umgesetzt, ohne für jedes einzelne Modul erneut nachfragen zu müssen:

- Pro Modul: implementieren, kurz testbar machen (lokaler Testlink), committen, pushen.
- Danach automatisch mit dem nächsten Format aus der Liste weitermachen.
- Nur bei echten inhaltlichen/technischen Unklarheiten zwischendurch nachfragen, nicht routinemäßig vor jedem Modul.

## 11. Empfohlene Reihenfolge

1. Phase 2 (erste Hälfte): einfache neue Spielformate ohne Drag-and-Drop.
2. Phase 2 (zweite Hälfte): Drag-and-Drop-Formate, inkl. flexiblerem Datenmodell.
3. Phase 3: Firebase-Grundlage (Auth + Firestore) einziehen, auch wenn Mehrspieler noch nicht fertig ist – das ist die Basis für alles Weitere.
4. Phase 4a: lokales Duell (kostenlos, kein Internet nötig) – schneller Erfolg, gutes Nutzererlebnis an Bord.
5. Phase 4b: monatlicher Flottenkrieg (Schiff gegen Schiff) – technisch anspruchsvollster Teil, baut auf allem Vorherigen auf, inkl. Season-Logik mit monatlichem Reset.

## 12. Status nach erstem Test aller 20 Modi

Alle Modi aus Abschnitt 3 wurden gebaut und getestet (Stand: 20 Modi in "Modus wählen", inkl. Gameshow-Quiz und Bild-Quiz aus vorherigen Commits). Ergebnis des ersten Tests:

- **Higher or Lower, Random Cards, Maths Generator ("Rechnen üben") und Balloon Pop werden entfernt** – aus der App-Liste sowie zugehörigem Code/Assets. Sie passen nach erstem Eindruck nicht ins Gesamtbild der App.
- **Whack-a-Mole wird vorerst ebenfalls entfernt** (Code/Assets können archiviert statt komplett gelöscht werden) – im Unterschied zu den anderen vier ist das kein endgültiger Rauswurf, sondern soll später überarbeitet und wieder in die App aufgenommen werden.
- **Flip Tiles wird neu ausgelegt**, im Stil eines "Glücksrad"/Wheel-of-Fortune-Spiels: Ein verstecktes Wort oder ein Satz wird als verdeckte Buchstaben-/Wortkacheln angezeigt, die Spieler raten einzelne Buchstaben, aufgedeckte Treffer bleiben sichtbar, bis das ganze Wort/der ganze Satz erraten ist. Bestehende Flip-Tiles-Logik (Kachel umdrehen) kann als Basis für die Buchstaben-Aufdeckung wiederverwendet werden.
- Die übrigen Modi bleiben als Basis bestehen, auch wenn sie inhaltlich/visuell noch nicht final sind ("noch lange nicht so, wie ich es mir vorstelle, aber ein Start") – Feinschliff erfolgt später, bremst Phase 3 nicht.
- Bei **Word Magnets** und **Rank Order** gab es bewusste Abweichungen von der wörtlichen Roadmap-Beschreibung, um Dopplungen mit anderen Modi zu vermeiden (siehe jeweilige Commit-Nachrichten) – akzeptiert, keine Änderung nötig.
- Nächster Schritt laut Entscheidung: **Phase 3 (Firebase-Grundlage: Accounts + Fortschritt)** wird jetzt begonnen.

## 13. Phase 5 – Visueller Feinschliff & Freelancer-Handoff

Bewusste Trennung: Claude Code baut die App **funktional komplett** (alle Modi, Backend, Mehrspieler) mit einfachem/funktionalem Styling ("Platzhalter-Optik", analog zu Abschnitt 9 bei den Inhalten). Erst wenn die Funktion steht, kommt ein Freelancer für den kompletten visuellen Feinschliff – Ziel: Endergebnis soll wirken wie eine hochwertige, vollständig durchgestaltete App (Layout, Farben, Typografie, **und komplette Animationen**, z. B. Dreh-Animation beim Glücksrad, Übergänge zwischen Screens, Feedback-Animationen bei richtig/falsch).

**Warum diese Reihenfolge:**
- Solange sich Modi/Features noch ändern (siehe Abschnitt 12), wäre Freelancer-Arbeit am Design verschwendetes Geld – die müsste bei jeder Änderung teilweise wiederholt werden.
- Code (Flutter/Dart, auf GitHub) und Inhalte (JSON) sind vollständig portabel – ein Freelancer mit Flutter-Kenntnissen kann direkt darauf aufbauen, unabhängig davon, wer den funktionalen Teil gebaut hat.

**Vorbereitung vor der Freelancer-Suche:**
1. Funktionaler Stand muss stehen (alle Modi + mindestens Phase 3/4-Grundgerüst).
2. Ein kurzes **Design-Briefing** erstellen (Vision, Stilrichtung, Referenzen/Moodboard, Zielgefühl "hochwertig"), damit der Freelancer nicht raten muss, wie "wie ich es mir vorstelle" konkret aussieht.
3. Klären, ob ein Flutter-Entwickler mit Design-Gespür gesucht wird (kann Theming/Animationen direkt im Code umsetzen) oder ein reiner UI/UX-Designer (liefert Mockups, die danach wieder implementiert werden müssen).

**Hinweis zur Abgrenzung:** Rein optische Anpassungen (Farben, Schriften, Icons, Layout) lassen sich später sauber "draufsetzen". Bei Interaktionen, die Optik und Logik eng verzahnen (z. B. Drag-and-Drop-Gefühl, Dreh-Animation), kann der Freelancer auch etwas am bestehenden Code anpassen müssen – das ist normal und kein Zeichen für einen Fehler im bisherigen Aufbau.

## 14. Status Phase 4a – abgeschlossen und auf echten Geräten bestätigt

Phase 4a (lokales Mehrspieler-Duell) ist fertig, technisch: lokaler WLAN-Server (shelf/WebSocket, Option 1 aus Abschnitt 5 der ursprünglichen Optionen), nicht `nearby_connections` (Android-Umgebung war dafür zu instabil, außerdem hätte das iPhones ausgeschlossen).

- Android-Entwicklungsumgebung repariert, echte APK-Builds funktionieren (Verteilung ans Testgerät über WLAN-Download statt USB-Kopie).
- Ein echter Bug gefunden und behoben: Ergebnis-Nachricht des Gegners ging verloren, wenn sie ankam, bevor die eigene Seite fertig gespielt hatte (Race Condition) – jetzt per automatisiertem Test dauerhaft abgesichert.
- Auf zwei echten Geräten bestätigt (Handy hostet, Browser tritt bei): kompletter Ablauf inkl. korrektem Ergebnis-Bildschirm funktioniert.
- Commit `5167449`.

**Nächster Schritt:** Phase 4b (monatlicher Flottenkrieg, siehe Abschnitt 6).

## 15. Navigationsumbau: drei Hauptbereiche statt flacher Modus-Liste

Wichtige Struktur-Entscheidung, die die bisherige einfache "Modus wählen"-Liste ablöst. Die App bekommt drei Hauptbereiche auf oberster Ebene; innerhalb jedes Bereichs wählt man danach ein Spielformat (Quiz, True/False, Match Up, ...) wie bisher:

- **Karrieremodus:** Ranking/Wettkampf. Zeitdruck, Punkte für Siege, direktes Antreten gegen ähnlich gerankte Spieler (Ranking-Liste/Rangsystem).
- **Lernmodus:** Entspanntes Üben, ohne Zeitdruck und ohne Wertungsdruck. Bei falscher Antwort wird sofort die richtige Lösung gezeigt – zum Vokabeln-/Grammatik-Üben statt zum Wettkampf.
- **Flottentreffen** (bisher "Flottenkrieg" – umbenannt, weniger martialisch): der monatliche Schiff-gegen-Schiff-Wettbewerb aus Phase 4b (Abschnitt 6), bleibt inhaltlich gleich, nur der Name ändert sich.

**Wichtig:** Alle drei sind eigenständige, gleichrangige Hauptbereiche – kein verschachteltes Untermenü, kein Modus in einer flachen Liste. Die bisherigen Spielformate (Quiz, True/False, Gameshow Quiz, Match Up, Rank Order, usw.) werden diesen drei Bereichen zugeordnet bzw. innerhalb von Karrieremodus/Lernmodus auswählbar gemacht.

**Korrektur der Navigationstiefe (nach erstem Test):** Die drei Bereiche erscheinen NICHT direkt auf der Startseite als Kacheln, sondern die Startseite behält den bestehenden **"Spiel starten"**-Button. Erst nach dem Tippen darauf werden die drei Hauptbereiche (Karrieremodus, Lernmodus, Flottentreffen) angezeigt, und erst danach – innerhalb des gewählten Bereichs – die einzelnen Spielformate. Also: Startseite → "Spiel starten" → Bereich wählen → Format wählen.

**Offen/zu klären beim Umbau:** Wie genau Ranking im Karrieremodus berechnet wird (z. B. ELO-artig, einfache Punktesumme) und ob Lernmodus alle Formate umfasst oder nur eine Teilmenge – das kann im nächsten Schritt mit Claude Code konkretisiert werden.

## 16. Navigation im Clash-Royale-Stil (unterer Reiter-Leiste)

Vorbild: Clash Royale (Screenshot als Referenz erhalten). Statt "Spiel starten"-Button + Bereichsauswahl (siehe Korrektur in Abschnitt 15) jetzt konkretes Layout mit **unterer Reiter-Leiste (5 Reiter)**, angelehnt an Clash Royale:

- **Lernmodus** – Icon: Buch/Karteikarten
- **Flottentreffen** – Icon: Anker/Schiff (bisher "Flottenkrieg")
- **1 vs 1** (bisher "Karrieremodus", umbenannt) – Icon: gekreuzte Schwerter, **mittig platziert und optisch hervorgehoben**, da Hauptmodus (wie der Kampf-Button bei Clash Royale)
- **Rangliste** – Icon: Pokal (neu, bisher nicht als eigener Reiter geplant – zeigt die ELO-Rangliste aus dem 1-vs-1-Matchmaking)
- **Profil/Optionen** – Icon: Personen-Silhouette oder Zahnrad

**Oberer Bereich (wie Clash Royale):** Level-Badge mit XP-Fortschrittsbalken links, aktuelle Wertung/Rang rechts (statt Gold/Diamanten wie im Vorbild – bei uns keine Ingame-Währung geplant).

## 17. 1-vs-1-Modus: Draft-Phase vor dem Match

Neue Spielmechanik für den "1 vs 1"-Reiter (Abschnitt 16), zusätzlich zum bereits gebauten ELO-Matchmaking (Abschnitt 15/Phase 4b-Bereich):

- Nach dem Matchmaking (Gegner gefunden) folgt eine **Draft-Phase**: Beide Spieler können bestimmte Spielformate aus dem Pool eliminieren ("bannen").
- Danach sucht sich **jeder Spieler ein Format aus** den verbleibenden, nicht eliminierten Formaten aus.
- Format des Matches: **Best of 3** – zwei Formate sind durch die Spieler gewählt (je eins), das **dritte/letzte Format wird per Zufallsgenerator** aus den verbleibenden (nicht eliminierten, nicht bereits gewählten) Formaten bestimmt.
- Sieger ist, wer von den drei Runden mehr gewinnt.

**Ablauf der Draft-Phase (geklärt):**
- Bans laufen **abwechselnd** ab, wie ein echter Draft (Spieler A bannt, dann Spieler B, usw.), nicht gleichzeitig.
- Jeder Draft-Schritt (Ban oder Formatauswahl) hat ein **Zeitlimit von 15-20 Sekunden**. Läuft die Zeit ab, wird automatisch zufällig gebannt bzw. gewählt, damit kein Spieler den anderen ewig warten lässt.

**Noch zu klären beim Umsetzen (kann mit Claude Code konkretisiert werden):**
- Wie viele Formate werden insgesamt abwechselnd gebannt, bevor die Auswahl beginnt (z. B. je 2-3 Bans pro Spieler)?

## 18. Status Abschnitt 16/17 – umgesetzt und im Emulator vollständig getestet

Beide Abschnitte sind fertig gebaut. Wichtigste Entscheidung dabei: Das bisher gebaute **asynchrone** 1-vs-1-Matchmaking (Abschnitt 15/Phase 4b-Bereich, "spielt blind, wird später zugeordnet auch wenn offline") wurde nie live deployt und deshalb durch eine **echte Live-Warteschlange** ersetzt – die Draft-Phase (Abschnitt 17) braucht zwingend einen gerade anwesenden Gegner, das war mit dem alten Async-Design nicht vereinbar.

- **Bans pro Spieler:** 3 (also 6 Bans insgesamt, abwechselnd), danach wählt jeder Spieler ein Format aus den verbleibenden 10. Das dritte Best-of-3-Format wird zufällig aus den übrigen 8 gezogen.
- **Reiter-Icons:** einfache Flutter-Material-Icons als Platzhalter (Buch, Anker, gekreuzte Schwerter, Pokal, Person) – wie gewünscht noch nicht final gestaltet.
- **Kompletter Ablauf im Firebase-Emulator End-to-End getestet** (zwei simulierte Testspieler, echte ID-Tokens, echte Firestore-Regeln statt Admin-Umgehung): Warteschlange → Zuordnung nach ähnlicher Wertung → Draft (abwechselndes Bannen mit Zug-Prüfung, Auswahl, zufälliges drittes Format) → drei Runden mit Teil-Einreichungs-Handling (wartet auf beide Spieler) → Sieger-Ermittlung → ELO-Update (K=32, gegenseitig: Gewinner +15, Verlierer −15 bei etwa gleicher Wertung) → Warteschlange wird zurückgesetzt → Ranglisten-Spiegel aktualisiert.
- **Sicherheitsregeln geprüft:** direkte Schreibversuche auf `matches/{id}` werden abgelehnt (nur die Cloud Functions dürfen schreiben), Schreibversuche auf die Warteschlange eines anderen Nutzers werden abgelehnt, unbeteiligte Nutzer können ein fremdes Match nicht lesen.
- `flutter analyze`, `flutter test` (14 Tests) und `flutter build web` laufen alle sauber durch.

**Lektion für später:** Der allererste Aufruf einer neu geladenen Cloud Function im Emulator kann auf Windows über 30 Sekunden zum Hochfahren brauchen (Node-Modulauflösung) – der Emulator selbst gibt nach 30 Sekunden auf und meldet einen Fehler, obwohl die Funktion kurz danach doch noch bereit wird. Ein einfacher zweiter Versuch reicht dann.
