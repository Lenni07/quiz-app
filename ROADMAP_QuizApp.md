# Quiz-App – Erweiterte Vision & Roadmap (über das MVP hinaus)

## ▶ AKTUELLE ARBEITSREIHENFOLGE (zuerst lesen)

1. **Nachbesserungen am aktuellen Optik-Stand** *(angestoßen)* – Ruder-Icon lesbar machen, kaputten Leerzustand bei "Letzte Matches" beheben, Statistik-Kacheln auf maritime Icons umstellen, Button "Kampf starten" → "Quiz-Duell starten" (inkl. englischer Fassung und aller weiteren "Kampf"-Formulierungen).
2. **Asset-Kits sichten** *(Lance)* – bessere Quellen als itch.io: GameDev Market, Unity Asset Store (Dateien lassen sich ohne Unity nutzen), CraftPix, Envato Elements (Abo ca. 16 €/Monat, bei diesem Bedarf günstiger als Einzelkäufe), ArtStation Marketplace.
3. **Die 17 Spielmodi im Detail durchgehen** – gemeinsam bewerten, welche wirklich Spaß machen und welche verzichtbar sind. Empfehlung: auf 6-8 gute Modi reduzieren, statt 17 mittelmäßige zu pflegen.
4. **Modi überarbeiten – Optik UND Spielgefühl.** Nicht alle gleichzeitig: zuerst 2-3 Modi als Referenz-Qualität ausarbeiten (Vorschlag: Quiz/Multiple Choice, True/False, Hörverständnis), dann die restlichen daran ausrichten. Stellschrauben fürs Spielgefühl: Tempo/Countdown, Combo-Mechanik bei Serien, sofortiges Feedback ohne Wartezeit, befriedigender Rundenabschluss mit hochzählenden Zahlen, Sound-Design.

**Zurückgestellt:** Abschnitt 18d (Download-Seite/Hosting), Abschnitt 18e (Ligen- und EP-System – Ranking-Konzept noch nicht final), Live-Deployment aller bisher nur lokal getesteten Server-Logik.

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

### 13a. Konkrete Analyse: Warum der aktuelle Stand optisch weit von Clash Royale entfernt ist

Bewertung des aktuellen Prototyps (Stand: 1-vs-1-Bildschirm mit Reiter-Leiste) im Vergleich zum Vorbild:

1. **Leere vs. Dichte:** Aktuell schwebt ein einzelnes Icon mit Text und Button in großer leerer Fläche. Clash Royale füllt den Bildschirm mit Inhalt (Karten, Zähler, Abzeichen) – Leerraum wirkt "unfertig".
2. **Flach vs. Tiefe:** Alle Elemente sind flach. Vorbild hat Schatten, Verläufe, Fasen, Glanzlichter – Buttons wirken physisch drückbar. Größter Unterschied im ersten Eindruck.
3. **Standard-Icons vs. eigene Illustrationen:** Aktuell generische Material-Icons (z. B. Karate-Figur für 1 vs 1) ohne Wiedererkennungswert.
4. **Typografie:** Dünne System-Schrift statt fetter, konturierter Display-Schrift mit Schatten.
5. **Farbwelt/Textur:** Einfarbig Blau auf Dunkelblau statt warmer Palette mit echten Texturen (Holz, Papier, Metall).
6. **Kein visuelles Thema:** Größte verpasste Chance – die App hat keine eigene Identität, obwohl sich das **maritime Thema** anbietet (Anker, Taue, Bullaugen, Wellen, Signalflaggen, Schiffsdeck-Holz, Rettungsringe). Das wäre das Gegenstück zu Clash Royales "mittelalterlicher Kampfarena".

### 13b. Was mit Flutter direkt geht – und wofür externe Assets nötig sind

**Ohne Zusatztools/Kosten direkt in Flutter umsetzbar (kann Claude Code jederzeit machen):**
- Verläufe, Schlagschatten, Fasen, abgerundete Ecken, Weichzeichner
- Eigene Schriftarten einbinden (behebt Punkt 4 sofort)
- Animationen: federnde Buttons, Bildschirmübergänge, Partikel-Effekte bei richtigen Antworten, animierte Fortschrittsbalken
- Eigene Formen/Ornamente programmatisch zeichnen (Wellen, Taue, Rahmen)
- Dichteres, durchdachteres Layout und eine stimmige Farbpalette

**Nur mit externen Assets möglich:**
- Illustrationen, Charaktere, Texturen, Hintergrundbilder (Flutter zeigt sie nur an, erstellen muss sie jemand)
- Komplexe animierte Illustrationen (über Rive oder Lottie extern gestaltet, in Flutter abgespielt)

**Empfohlener Abkürzungsweg statt Freelancer-Beauftragung:** Fertige **Game-UI-Asset-Kits** kaufen (itch.io, Envato/GraphicRiver, kostenlos bei kenney.nl) – Sammlungen mit Holz-Panels, klobigen Buttons, Rahmen, Bannern, Icons im Spiele-Look, meist 10-50 €. Ein maritimes Kit würde perfekt zum Thema passen und liefert einen Großteil des gewünschten Looks ohne Designer-Auftrag.

**Empfohlene Reihenfolge für Phase 5:**
1. Zuerst die kostenlosen Flutter-Mittel ausschöpfen (Schrift, Tiefe/Schatten, Animationen, Farbpalette, dichteres Layout) – zeigt, wie weit man allein damit kommt.
2. Danach entscheiden, ob gekaufte Asset-Kits ausreichen.
3. Freelancer nur, falls darüber hinaus ein individueller, durchgestalteter Look gewünscht ist.

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

## 18. Profil-Bereich (Reiter "Profil", Abschnitt 16)

Felder im Nutzerprofil:
- **Nickname** (Anzeigename, frei wählbar)
- **Richtiger Name**
- **Position** (z. B. Jobbezeichnung an Bord)
- **Department** (Abteilung)
- **Profilbild:** über **vordefinierte Avatare** (Auswahl aus einer kleinen Icon-/Avatar-Sammlung), **kein** echter Foto-Upload – dadurch kein Firebase Storage nötig, kein Datenschutz-Thema mit echten Fotos.

**Sichtbarkeit:**
- Das Profilbild ist nur sichtbar, wenn man das eigene oder ein fremdes Profil direkt öffnet – nicht automatisch überall in der App present.
- **Nickname und Position** sind zusätzlich **in der Rangliste** (Abschnitt 16, Reiter "Rangliste") sichtbar, neben der Wertung. Richtiger Name und Department bleiben nur im Profil selbst sichtbar.

**Zusätzliche Felder (Ergänzung):**
- **Crew-ID**
- **Deutsch-Level** (1-6, passend zur Berlitz-Level-Struktur aus dem Unterricht)
- **Zertifikat:** statt manueller Prüfung bei jeder Anmeldung nur das **Ausstellungsdatum** eintragen lassen, Ablauf (Ausstellung + 2 Jahre) wird automatisch berechnet und als "gültig"/"abgelaufen" angezeigt.

**Verifizierung – bewusst KEINE Anbindung an das Bord-System:** Das angegebene Deutsch-Level ist **selbstangegeben**, ohne Abgleich mit einem externen/Bord-System – eine echte Systemanbindung wäre ein eigenes, deutlich größeres Projekt (unbekannte Schnittstelle, Zugriffsrechte, Datenschutz) und bewusst nicht Teil dieser App. Kann bei Bedarf später als eigene, separate Erweiterung angegangen werden.

**Hinweis (überholt):** Die ursprünglich hier vorgesehene Verknüpfung "Deutsch-Level bestimmt die Start-Wertung im 1-vs-1 (Level × 1000)" wurde verworfen – siehe **Abschnitt 18b**. Das Level hat keinen Einfluss mehr auf Wertung oder Matchmaking und dient nur noch als Profil-Information bzw. für die Lernmodus-/Department-Logik.

## 18b. Überarbeitung Ranglisten-System (ersetzt die Level-basierte Start-EP-Logik aus Abschnitt 18)

**Warum die ursprüngliche Lösung nicht funktioniert:** Die Idee "Deutsch-Level bestimmt die Start-Wertung (Level × 1000)" hat zwei Probleme. Erstens verbessern sich Schüler über die Zeit, eine einmalige Start-Einstufung bildet das nicht ab. Zweitens – und gravierender – lässt sich das nicht sinnvoll gegen Manipulation absichern: Eine Regel "Level darf nur steigen, nie sinken" verhindert zwar das Herunterstufen, aber nicht, dass sich jemand **von Anfang an zu niedrig einstuft** und dauerhaft in einer zu leichten Liga dominiert ("Smurfing"). Das Grundproblem bleibt also bestehen.

**Neues Modell: Ranking rein leistungsbasiert, ohne Level-Bezug**

- **Das Deutsch-Level wird vollständig aus dem Ranking herausgelöst.** Es bleibt im Profil erhalten (Abschnitt 18) und wird für Lernmodus/Department-Logik genutzt, hat aber **keinen Einfluss mehr auf Wertung oder Matchmaking**. Damit entfällt auch die serverseitige Level-Sperre komplett – es gibt nichts mehr zu manipulieren.
- **Alle starten bei derselben Grundwertung** (z. B. 1000). Das ELO-System sortiert die Spieler innerhalb weniger Matches automatisch nach tatsächlicher Spielstärke – genau dafür sind ELO-Systeme gebaut. Sich zu niedrig einzustufen bringt keinen Vorteil mehr, weil sich die Wertung ohnehin selbst korrigiert.
- **Ein einziger, gemeinsamer Matchmaking-Pool** statt sechs kleiner Level-Pools. Bei ein paar hundert Crew-Mitgliedern pro Schiff entscheidend, damit die Warteschlange überhaupt zuverlässig Gegner findet (dieselbe Pool-Größen-Logik wie bei der Department-Entscheidung in Abschnitt 18c).

**Zwei Ergänzungen dazu:**
- **Platzierungsmatches:** Die ersten ca. 5 Matches gelten als Kalibrierungsphase mit höherem K-Faktor, in der sich die Wertung schneller anpasst. So landet man zügig auf dem passenden Niveau, statt sich langsam hocharbeiten zu müssen.
- **Weicher Season-Reset statt hartem Reset:** Zum Monatswechsel wird die Wertung nicht auf 0 zurückgesetzt, sondern zur Mitte hin gestaucht (z. B. neue Wertung = (alte Wertung + 1000) / 2). Der Fortschritt fühlt sich dadurch nicht jeden Monat komplett entwertet an, die Saison bleibt aber trotzdem spannend und offen.

**Für Claude Code zu beachten:** Die bereits gebaute "Level × 1000 Start-EP + serverseitige Sperre nach erstem Match"-Logik aus Abschnitt 18 entfällt damit ersatzlos und kann zurückgebaut werden.

## 18c. Weitere Feature-Ideen (aufgenommen, Umsetzung nach den Kernfunktionen)

**Audio/Hörverständnis (höchste didaktische Priorität):** Die App ist bisher rein textbasiert, das eigentliche Ziel ist aber das *Sprechen* mit Gästen. Neues Format, bei dem ein deutscher Satz vorgelesen wird (Text-to-Speech, in Flutter gut umsetzbar – kein aufgenommenes Audiomaterial nötig) und der Spieler die Bedeutung/Antwort erkennen muss. Schließt die Lücke beim Hörverständnis.

**Fragen nach Department filtern:** Das Profil enthält bereits ein Department-Feld (Abschnitt 18). Fragen/Inhalte werden mit Department-Tags versehen (z. B. Restaurant, Housekeeping, Rezeption, Spa, Security), zusätzlich gibt es einen Tag für **allgemeine, abteilungsübergreifende Inhalte** (Begrüßung, Smalltalk, Zahlen, Wegbeschreibungen – was ohnehin alle brauchen). Beim Anlegen der echten Inhalte gleich mitdenken (Tag pro Frage), damit es später nicht nachgerüstet werden muss.

**Wichtig – wo die Department-Tags greifen und wo nicht:**
- **Lernmodus (allein üben):** Department-Tags greifen voll. Nutzer bekommen überwiegend Inhalte ihrer eigenen Abteilung (Housekeeping-Vokabular für Housekeeper, Check-in-Wortschatz für die Rezeption usw.) – hier bringt Relevanz den größten Lerneffekt.
- **1 vs 1 / Wettkampf:** Bewusst **nur allgemeine, abteilungsübergreifende Inhalte**. Grund: Es gibt bewusst **einen einzigen gemeinsamen Matchmaking-Pool** ohne jede Segmentierung (siehe Abschnitt 18b – auch die ursprünglich geplante Level-Segmentierung wurde verworfen). Käme eine Department-Segmentierung dazu, entstünden 5-8 getrennte Pools – bei ein paar hundert Crew-Mitgliedern pro Schiff wären viele davon praktisch leer und die Warteschlange fände keinen Gegner. Außerdem haben so beide Spieler dieselben fairen Voraussetzungen, unabhängig von ihrer Abteilung.
- **Flottentreffen:** ebenfalls nur allgemeine Inhalte, da schiffsübergreifend.
- **Es wird also NICHT nach Department gematcht** – Housekeeper spielen ganz normal gegen alle anderen, nur eben mit allgemeinen Inhalten.

**Umsetzungsumfang (Entscheidung):** Im ersten Durchgang bekommt **nur das `Question`-Datenmodell** ein Department-Feld samt Filterlogik (genutzt u. a. von Allgemeinwissen-Quiz, Gameshow-Quiz, Open the Box, Random Wheel). Die übrigen sechs Datenmodelle (Sentence, TrueFalse, ImageQuiz, GroupSort, FlipTileWord, NumberWord) bleiben vorerst ungetaggt und gelten damit automatisch als "allgemein". Begründung: Echte Inhalte existieren noch nicht, es gibt also aktuell nichts zu taggen; außerdem wurden nach dem ersten Testdurchgang bereits fünf Formate wieder entfernt – Tagging-Infrastruktur für Formate zu bauen, die möglicherweise wegfallen, wäre Arbeit auf Verdacht.

**⚠️ Wichtige Bedingung:** Die restlichen sechs Datenmodelle **müssen das Department-Feld bekommen, bevor die echten Inhalte eingepflegt werden**. Sonst müssten sämtliche Inhalte später nochmal durchgegangen und nachträglich getaggt werden. Dieser Punkt ist Voraussetzung für den Arbeitsblock "echte Inhalte einpflegen".

**Tages-Challenge mit Streak:** Eine tägliche Aufgabe, die Bonuspunkte bringt, plus Streak-Zähler (aufeinanderfolgende Tage). Passt zur monatlichen Season-Logik und zur Clash-Royale-Gamification aus Abschnitt 16; gibt Crew-Mitgliedern mit unregelmäßigen Schichten einen klaren, kleinen täglichen Anreiz.

## 18e. Ligen-System und stärkeres Antwort-Feedback (Motivation/Nutzungshäufigkeit)

Ziel: Die App soll häufig und regelmäßig genutzt werden. Vorbild ist hier bewusst **Duolingo**, nicht Mobile Legends – Duolingo hat genau dieses Problem (Leute zum täglichen Lernen bringen) mit vergleichsweise einfacher Grafik gelöst, während der MLBB-Look aufwendig gezeichnete Assets erfordern würde und thematisch nicht zu einer Vokabel-App für Crew-Mitglieder passt.

> **Status: noch nicht endgültig entschieden.** Die Grundrichtung (Aktivitäts-EP im Wettkampf, Fortschrittsanzeige im Lernmodus) steht, die konkrete Ausgestaltung des Ranking-Systems ist aber offen und kann bei Bedarf verschoben werden.

**Grundlage: Aktivitäts-EP – aber nur im Wettkampfbereich**

Es wird eine **Aktivitäts-Punktzahl (EP)** eingeführt, getrennt von der ELO-Wertung:
- EP gibt es **ausschließlich für 1 vs 1 und die Tages-Challenge**, nicht für den Lernmodus.
- EP messen **Fleiß/Aktivität**, ELO misst weiterhin ausschließlich **Können** und bestimmt nur noch, *gegen wen* man im 1 vs 1 antritt.
- **Warum EP nötig sind:** Eine Liga, die nach ELO rankt, belohnt Untätigkeit – wer oben steht und aufhört zu spielen, bleibt oben ("Rank Camping"), weil ELO nicht mit Aktivität wächst.

**Lernmodus: bewusst keine EP, stattdessen Fortschrittsanzeige**

Der Lernmodus bekommt ausdrücklich **keine Punktebelohnung**. Die Motivation ist dort bereits intrinsisch vorhanden: Die Crew lernt für die Level-Prüfungen, von denen Zertifikat und berufliches Weiterkommen abhängen. Punkte draufzusetzen wäre nicht nur überflüssig, sondern potenziell schädlich – wenn Lernen Punkte bringt, verschiebt sich der Fokus leicht vom Verstehen zum Punktesammeln.

Was stattdessen wirklich hilft, ist **Orientierung für die Prüfungsvorbereitung**:
- Fortschritt pro Level/Einheit ("Du beherrschst 60 % des Level-3-Wortschatzes")
- Erkennung von Schwachstellen ("Deine Schwachstelle sind Dativ-Präpositionen")
- Liste der noch nicht sitzenden Inhalte ("Diese 12 Vokabeln sitzen noch nicht")

Damit sind die beiden Bereiche auch inhaltlich sauber getrennt: **Lernmodus = Prüfungsvorbereitung** (Motivation durch sichtbaren Lernfortschritt), **1 vs 1 = Wettkampf** (Motivation durch Liga und EP). Keine einheitliche Punktewährung über alles.

**Ligen-System (wöchentlich):**
- Ligen ranken nach **in dieser Woche gesammelten Aktivitäts-EP**, nicht nach ELO und ausdrücklich nicht nach dem selbstangegebenen Deutsch-Level (das würde die in Abschnitt 18b bewusst abgeschaffte Segmentierung wieder einführen).
- Spieler werden nach Wertung in Gruppen von ca. **30 Personen** einsortiert (Bronze, Silber, Gold, …). Pro Woche steigen die besten ca. 7 auf, die schlechtesten ca. 5 ab.
- **Warum das wirkt:** In einer Rangliste mit mehreren hundert Leuten hängt der Durchschnittsspieler anonym im Mittelfeld fest. In einer Gruppe von 30 steht man immer knapp an einer Auf- oder Abstiegsgrenze – das erzeugt die eigentliche Spannung. Und weil nach Wochen-EP gerankt wird, hilft es nichts, sich auf einem Platz auszuruhen: Wer pausiert, wird von den anderen überholt.
- **Rhythmus:** wöchentlich. Ergänzt den monatlichen Flottenwettbewerb (Abschnitt 6) sinnvoll – schneller Wochenrhythmus für den Einzelnen, langsamer Monatsrhythmus fürs Schiff. Ein Monat wäre für Ligen zu lang, um Spannung zu erzeugen.

**Verhältnis zum bestehenden Ranglisten-Reiter:** Die Liga **ersetzt die Rangliste nicht als eigener Reiter**, sondern wird zur Hauptansicht des vorhandenen Reiters "Rangliste" (Abschnitt 16). Zwei getrennte Reiter wären redundant, da die Liga im Kern selbst eine Rangliste ist – nur auf ca. 30 Personen zugeschnitten.
- **Standardansicht:** die eigene aktuelle Liga mit farblich markierten Auf-/Abstiegszonen und Countdown bis zum Wochenende.
- **Nebenansicht über einen kleinen Umschalter:** die globale Bestenliste des Schiffs – das Einzige, was die Liga nicht leisten kann, nämlich zu zeigen, wer insgesamt ganz vorne steht (motivierend für Spitzenspieler, Orientierung für alle anderen).
- Reiteranzahl bleibt damit bei 5, keine zusätzliche Navigationsebene.

**Stärkeres Antwort-Feedback:**
- Sofortiges, üppiges Feedback bei jeder Antwort: Konfetti-/Partikeleffekte bei richtigen Antworten, hochzählende Punktzahlen, deutliche Animationen, passende Sounds.
- Bei falschen Antworten klares, aber nicht entmutigendes Feedback (der Wackel-Effekt ist ein guter Anfang), plus sofortige Anzeige der richtigen Lösung im Lernmodus.

**Bewusst nicht übernommen:** Mechaniken, die auf Verlustangst und künstliche Dringlichkeit setzen (ablaufende Timer mit Druckaufbau, "dein Streak stirbt in 2 Stunden!", Lootboxen). Die App hat echten beruflichen Nutzen – Motivation über sichtbaren Fortschritt und Wettbewerb mit Kollegen trägt hier weiter als künstlicher Druck, und es besteht sonst das Risiko, dass die App als nervig empfunden und deinstalliert wird.

## 18d. Verteilung: Web-Version + APK-Download über Firebase Hosting

**Entscheidung:** Erster Verteilweg ist **nicht** der App Store, sondern eine eigene Adresse über **Firebase Hosting** (bereits Teil des Projekts, kostenlos im bestehenden Tarif, keine zusätzliche Plattform nötig – Vercel o. Ä. wäre redundant).

**Umfang:**
- Die **Web-Version der App** wird unter einer festen Adresse gehostet und ist direkt im Browser nutzbar – ohne Installation, auf Android, iPhone und Desktop gleichermaßen.
- Auf derselben Seite steht zusätzlich die **APK zum Download** für Android-Nutzer, die die installierte Variante bevorzugen (bessere Offline-Nutzung, Icon auf dem Startbildschirm).
- **Die App ist kostenfrei.**

**Warum nicht (zunächst) App Store:** Google Play wäre machbar (einmalig 25 $), Apple dagegen deutlich aufwendiger: 99 $ pro Jahr und iOS-Builds erfordern zwingend einen Mac mit Xcode – auf der aktuellen Windows-Umgebung nicht möglich. Über die Web-Version erreicht man iPhone-Nutzer ohne diese Hürde vollständig.

**Zum Geschäftsmodell (offen, später zu entscheiden):** Angedacht ist, dass Crew-Mitglieder zahlen und die Kosten über Crew Welfare erstattet bekommen (wiederkehrende Einnahmen statt einer einmaligen Zahlung der Reederei). Marktanhaltspunkte: etablierte Sprachlern-Anbieter im Firmengeschäft liegen bei ca. 8-10 € pro Nutzer/Monat; für ein Modell mit Vorleistung durch die Crew wären realistisch eher 2-5 € pro Monat bzw. 20-40 € im Jahr. Eine Direktzahlung der Reederei läge grob bei 2.000-10.000 € pro Schiff und Jahr, bedeutet aber Ausschreibungen, Datenschutzprüfungen und lange Verkaufszyklen. Stärkste Verhandlungsposition entsteht ohnehin erst mit belegbaren Nutzungszahlen – deshalb zunächst kostenfrei verteilen.

## 19. Englische Bedienoberfläche (Reiter "Optionen")

In den Optionen soll es eine Sprachumschaltung Deutsch/Englisch geben – aber **nur für die Bedienoberfläche** (Menüs, Reiter-Beschriftungen, Buttons, Anleitungstexte, Systemmeldungen usw.). Die eigentlichen Deutsch-Lerninhalte/Fragen bleiben immer auf Deutsch, unabhängig von der gewählten Oberflächensprache – macht didaktisch Sinn, da das Ziel ja das Deutschlernen ist, nur die Bedienung soll für alle verständlich sein, unabhängig vom Englisch-Niveau.

## Status Abschnitt 18e Teil 1 – Antwort-Feedback + Lernmodus-Fortschritt (Stand 2026-09-05)

Wie angewiesen **nur** die beiden unten stehenden Punkte umgesetzt – Ligen-System und Aktivitäts-EP bewusst ausgelassen, da das Ranking-Konzept laut Statuszeile oben noch nicht final ist. In zwei Teilschritten committet/gepusht:

**1. Stärkeres Antwort-Feedback in allen Formaten:** Bisher hatten nur "Allgemeinwissen-Quiz" und "Hörverständnis" Konfetti/Wackel-Effekt/Haptik. Neuer `AnswerFeedbackMixin` (`lib/widgets/answer_feedback.dart`) bündelt Konfetti, grünes Aufblitzen, Wackeln und Haptik und wurde in allen 14 verbleibenden Formaten ergänzt (Wahr/Falsch, Lückentext, Richtige Reihenfolge, Gameshow-Quiz, Bild-Quiz, Open the Box, Random Wheel, Duell, Rank Order, Word Magnets, Find the Match, Flip Tiles, Match Up, Group Sort). Punktzahlen zählen jetzt hoch (`CountUpNumber`) statt zu springen, und wo bisher nicht vorhanden, wird die richtige Lösung bei falscher Antwort jetzt explizit als Text angezeigt (Multiple-Choice-Formate zeigten sie vorher nur indirekt über die grüne Einfärbung der richtigen Option). Karteikarten bewusst ausgenommen (Selbsteinschätzung, kein Richtig/Falsch). Für die Sounds gab es kein Audio-Package im Projekt und keine unbedenkliche Quelle für fertige Sound-Dateien - stattdessen werden kurze Töne zur Laufzeit per Sinus-Synthese erzeugt (`lib/audio/tone_generator.dart`, `lib/audio/sound_effects.dart`, neues Package `audioplayers`), kein Lizenzrisiko.

**2. Fortschrittsanzeige im Lernmodus:** `Question`-Modell um `level` (1-6) und `topic` (grammatisches Schlagwort, z. B. "Kasus", "Höflichkeitsformen") ergänzt, analog zum bisherigen Scoping der Department-Tags nur für dieses eine Datenmodell. Der bestehende Fragenkatalog (`assets/questions.json`, 37 Fragen) wurde mit plausiblen Level-/Themen-Werten befüllt. Neuer `QuestionMasteryService` (`lib/services/question_mastery_service.dart`) speichert rein lokal über `shared_preferences` pro Frage Versuche und aktuellen Richtig-Serien-Zähler (2 in Folge richtig = "sicher") - bewusst kein Firestore, da der Lernmodus offline-first bleiben und keine EP vergeben soll. Neuer `ProgressScreen`, erreichbar über eine neue Kachel oben im Lernmodus-Reiter, zeigt Fortschritt pro Level, die (mindestens einmal versuchten) drei schwächsten Themen und die Liste noch nicht sicher sitzender Fragen. Mastery wird bei jeder Antwort in Allgemeinwissen-Quiz, Gameshow-Quiz, Open the Box, Random Wheel und Duell mitgeschrieben (nicht bei "Konversation üben", das keine echten Katalogfragen, sondern aus Sentence-Daten synthetisierte nutzt).

Bewusst nicht umgesetzt: Ligen-System, Aktivitäts-EP, Timer mit Drohkulisse, Lootboxen.

**Getestet:** `flutter analyze`, `flutter test` (32 Tests, davon 5 neu für den Mastery-Service inkl. Schwachstellen-Sortierung) und `flutter build web` laufen sauber. Echter visueller/akustischer Eindruck konnte von mir nicht geprüft werden (kein Browser-/Audio-Werkzeug in dieser Umgebung).

**Noch nicht deployt** - wie angewiesen, wird gesammelt am Ende deployt.
