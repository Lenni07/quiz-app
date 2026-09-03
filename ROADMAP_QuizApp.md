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
- **1 vs 1 / Wettkampf:** Bewusst **nur allgemeine, abteilungsübergreifende Inhalte**. Grund: Die Rangliste ist bereits nach Deutsch-Level segmentiert (Abschnitt 18b); käme Department dazu, entstünden 30-48 getrennte Matchmaking-Pools – bei ein paar hundert Crew-Mitgliedern pro Schiff wären viele Pools praktisch leer und die Warteschlange fände keinen Gegner. Außerdem haben so beide Spieler dieselben fairen Voraussetzungen, unabhängig von ihrer Abteilung.
- **Flottentreffen:** ebenfalls nur allgemeine Inhalte, da schiffsübergreifend.
- **Es wird also NICHT nach Department gematcht** – Housekeeper spielen ganz normal gegen alle anderen, nur eben mit allgemeinen Inhalten.

**Umsetzungsumfang (Entscheidung):** Im ersten Durchgang bekommt **nur das `Question`-Datenmodell** ein Department-Feld samt Filterlogik (genutzt u. a. von Allgemeinwissen-Quiz, Gameshow-Quiz, Open the Box, Random Wheel). Die übrigen sechs Datenmodelle (Sentence, TrueFalse, ImageQuiz, GroupSort, FlipTileWord, NumberWord) bleiben vorerst ungetaggt und gelten damit automatisch als "allgemein". Begründung: Echte Inhalte existieren noch nicht, es gibt also aktuell nichts zu taggen; außerdem wurden nach dem ersten Testdurchgang bereits fünf Formate wieder entfernt – Tagging-Infrastruktur für Formate zu bauen, die möglicherweise wegfallen, wäre Arbeit auf Verdacht.

**⚠️ Wichtige Bedingung:** Die restlichen sechs Datenmodelle **müssen das Department-Feld bekommen, bevor die echten Inhalte eingepflegt werden**. Sonst müssten sämtliche Inhalte später nochmal durchgegangen und nachträglich getaggt werden. Dieser Punkt ist Voraussetzung für den Arbeitsblock "echte Inhalte einpflegen".

**Tages-Challenge mit Streak:** Eine tägliche Aufgabe, die Bonuspunkte bringt, plus Streak-Zähler (aufeinanderfolgende Tage). Passt zur monatlichen Season-Logik und zur Clash-Royale-Gamification aus Abschnitt 16; gibt Crew-Mitgliedern mit unregelmäßigen Schichten einen klaren, kleinen täglichen Anreiz.

## 19. Englische Bedienoberfläche (Reiter "Optionen")

In den Optionen soll es eine Sprachumschaltung Deutsch/Englisch geben – aber **nur für die Bedienoberfläche** (Menüs, Reiter-Beschriftungen, Buttons, Anleitungstexte, Systemmeldungen usw.). Die eigentlichen Deutsch-Lerninhalte/Fragen bleiben immer auf Deutsch, unabhängig von der gewählten Oberflächensprache – macht didaktisch Sinn, da das Ziel ja das Deutschlernen ist, nur die Bedienung soll für alle verständlich sein, unabhängig vom Englisch-Niveau.

**Status: bereits umgesetzt** (`SegmentedButton` im Profil-Reiter, `lib/l10n/`) – deckt Reiter, Menüs, Profil, Rangliste, Flottentreffen, 1-vs-1-Warteschlange/Draft/Match-Ergebnis, Start-/Ergebnisbildschirm ab.

## 21. Status Abschnitt 18c – alle drei Features umgesetzt (Stand 2026-09-03)

**Hinweis:** Abschnitt 18c (oben) verweist noch darauf, dass die Rangliste "bereits nach Deutsch-Level segmentiert" sei - das ist durch Abschnitt 18b überholt (genau umgekehrt: ein einziger gemeinsamer Pool, keine Level-Segmentierung). Ändert aber nichts an der eigentlichen Regel ("kein Department-Matching") - die gilt mit einem einzigen Pool sogar noch klarer.

**1. Hörverständnis (Text-to-Speech):** 17. Spielformat, `flutter_tts`, liest einen deutschen Satz aus den bestehenden sentences.json-Daten vor, vier englische Bedeutungs-Optionen zur Auswahl (bewusst keine Dopplung zu "Konversation üben", das dieselben Daten für die passende deutsche Erwiderung nutzt). Wie alle 16 bisherigen Formate im Katalog registriert, dadurch automatisch auch im 1-vs-1-Draft-Pool.

**2. Department-Tags:** wie abgestimmt nur beim `Question`-Modell (Allgemeinwissen-Quiz, Gameshow-Quiz, Open the Box, Random Wheel) - die übrigen sechs Datenmodelle bleiben ungetaggt, **müssen das Feld aber bekommen, bevor echte Inhalte eingepflegt werden** (siehe Warnhinweis oben). Lernmodus zeigt eigenes Department + allgemeine Inhalte, 1 vs 1 bewusst nur allgemeine Inhalte (`lib/models/department.dart`, beide Filterfunktionen fallen auf die ungefilterte Liste zurück statt einen Nutzer ganz ohne Fragen dastehen zu lassen). Das Profil-Department-Feld wurde dafür von Freitext auf eine feste Auswahl umgestellt, damit die Filterung zuverlässig matcht. Ein Dutzend Platzhalter-Fragen mit Department-Tags ergänzt, damit überhaupt etwas zu filtern ist.

**3. Tages-Challenge mit Streak:** die erste abgeschlossene Runde eines Tages (egal welches Format) zählt, verlängert einen Streak-Zähler und gibt einen Punkte-Bonus (10 Punkte, eigene Wahl da die Roadmap keinen Betrag vorgab) auf den Flottentreffen-Punktestand der laufenden Season - kein neues Punktesystem, nutzt die bestehende scoreSubmissions-Infrastruktur. "Noch kein Schiff" wird sinnvoll abgefangen: der Streak zählt trotzdem, nur der Punkte-Bonus entfällt (nutzt dafür `FleetWarService.submitScore()`, das genau das schon eingebaut hatte). Streak-Anzeige (🔥-Icon) im Kopfbereich der Reiter-Navigation, Datumsvergleich auf Basis der Gerätezeit (kein serverseitiger Zeitzonen-Abgleich - Schiffe reisen durch Zeitzonen, "heute" ist bewusst das, was der Nutzer gerade auf seinem Gerät sieht).

**Getestet:** neue automatisierte Tests für die Department-Filterung (`test/department_test.dart`) und die Streak-Logik inkl. Tag-Sprung/Lücken-Verhalten (`test/daily_challenge_service_test.dart`, mit injizierbarer Uhrzeit für reproduzierbare Tests ohne echten Tageswechsel). `flutter analyze`, `flutter test` (27 Tests) und `flutter build web` laufen nach allen drei Teilschritten sauber. Sprachausgabe (TTS) konnte nicht tatsächlich gehört werden (kein Audio-Testwerkzeug in dieser Umgebung).

**Noch nicht deployt** - wie angewiesen, wird gesammelt am Ende deployt.

## 22. Status Abschnitt 13b Schritt 1 – rein Flutter-basierte Optik-Verbesserungen umgesetzt (Stand 2026-09-03)

Alle sechs angeforderten Punkte umgesetzt, in vier Teilschritten committet/gepusht:

- **Display-Schrift:** Baloo 2 (fünf Schnitte), lokal als Font-Asset gebündelt statt über Google Fonts zur Laufzeit geladen - läuft damit auch beim allerersten App-Start ganz ohne Internet (Offline-first-Prinzip). Nur für Überschriften/Buttons/Zahlen, Fließtext bleibt auf der Systemschrift.
- **Tiefe:** zwei wiederverwendbare Widgets (`GameButton`, `GamePanel` in `lib/widgets/`) mit Verlauf, Schlagschatten und Glanzlicht-Fase, angewendet auf die wichtigsten Buttons/Karten/Panels app-weit (Start-, 1-vs-1-, Lernmodus-, Profil-, Rangliste-, Flottentreffen- und Ergebnisbildschirme).
- **Maritime Farbpalette:** Tiefseeblau/Messing-Gold/Segeltuch-Beige/Signalrot ersetzt das bisherige einfarbige Blau-auf-Dunkelblau, zentral in `lib/theme/app_theme.dart` - wirkt automatisch auf die ganze App über das globale Theme.
- **Animationen:** federnde Antipp-Effekte auf `GameButton`/Lernmodus-Kacheln, ein neuer Wackel-Effekt (`lib/widgets/shake.dart`) bei falschen Antworten im meistgenutzten Frage-Bildschirm, animierte Fortschrittsbalken/Zahlen waren teils schon vorhanden und wurden nicht angetastet.
- **Dichteres Layout:** die von der Analyse in Abschnitt 13a explizit kritisierte 1-vs-1-Leere (ein einzelnes Icon in großer Fläche) zeigt jetzt Wertung, Tages-Streak, Saison-Platzierung (per Firestore-Aggregations-Query) und die letzten drei gewerteten Matches.
- **Programmatische Ornamente:** `WaveDivider` (Wellenband) und `RopeDivider` (gedrehtes Tau) über `CustomPainter`, ganz ohne Bild-Assets - eingesetzt am Startbildschirm, unter dem Kopfbereich der Reiter-Navigation und als Abschnitts-Trenner im Lernmodus.

**Kleine Verhaltensänderung dabei:** die 1-vs-1-Ansicht zeigt jetzt konsequent wie Profil/Flottentreffen eine "keine Verbindung zum Konto"-Meldung statt eines Buttons ohne Login (der sowieso fehlschlagen würde) - der bestehende Smoke-Test wurde entsprechend angepasst.

**Getestet:** `flutter analyze`, `flutter test` (27 Tests) und `flutter build web` laufen nach jedem der vier Teilschritte sauber; die beiden neuen Firestore-Abfragen für die 1-vs-1-Landing (letzte Matches, Saison-Rang) wurden im Emulator mit echtem Nutzer-Token gegen echte Sicherheitsregeln verifiziert, inkl. eines neuen Composite-Index in `firestore.indexes.json`. Echter visueller Eindruck im Browser konnte von mir nicht geprüft werden (kein Browser-Werkzeug in dieser Umgebung) - der lokale Server läuft unter `http://localhost:8768/` zur eigenen Ansicht.

**Nicht angefasst (bewusst, wie mit 16 der Format-Bildschirme):** die Bedienelemente innerhalb der 17 einzelnen Spielformate selbst - das wäre ein deutlich größerer, separater Schritt, analog zur Entscheidung bei der Sprachumschaltung (Abschnitt 19).

**Noch nicht deployt** - reine Flutter/Client-Änderung, kein Firebase-Deploy nötig.

## 23. Status Optik-Runde 2 – umgesetzt in vier Teilschritten (Stand 2026-09-03)

Aufbauend auf Abschnitt 22 (Design-Fundament), diesmal auf konkrete Kritikpunkte am zu generischen Standard-Flutter-Look:

**1. Maritimes Icon-Set:** neues `MaritimeIcon`-Widget - selbstgezeichnet per `CustomPainter` (Leuchtturm, Steuerrad, Rettungsring, Möwe, Bullauge, Kapitänsmütze, gekreuzte Ruder), keine externen Icon-Pakete. "1 vs 1" zeigt jetzt gekreuzte Ruder statt der Karate-Figur, alle 10 Profil-Avatare sind komplett maritim statt zufällig.

**2. Verlaufs-Hintergrund + Textur:** `MaritimeBackground` (Verlauf hell→dunkel plus sehr dezente Wellenlinien-Textur per `CustomPainter`) ersetzt die flache Fläche - über einen einzigen Wrap-Punkt auf allen fünf Reitern sowie den vier eigenständigen Bildschirmen (Warteschlange, Draft, Match-Ergebnis, Ergebnis) angewendet.

**3. Handy-Proportionen:** `PhoneFrame`, einmalig über `MaterialApp.builder` gelegt statt pro Bildschirm - begrenzt die komplette App (inkl. AppBar/Reiter-Leiste) auf 480px Breite, mittig zentriert mit dunkler Blende drumherum. Im breiten Browser sieht die App dadurch wie auf einem Handy aus.

**4. Gestaltete Leerzustände:** neues `EmptyState`-Widget (Icon + motivierende Zeile) ersetzt nackte Textzeilen bei "Letzte Matches", Rangliste und Flottentreffen-Leaderboard, auch für deren Fehlerzustände.

**5. Mehr Tiefe:** `GamePanel`/`GameButton` simulieren jetzt eine Innenschattierung (Glanzlicht-Streifen oben, Schatten-Streifen unten) statt der vorherigen einfachen Fase - Flutter hat keine echten CSS-artigen Inset-Schatten, das ist die Annäherung.

**6. Animation/Juice:** `CountUpNumber` (zählt vom zuletzt gezeigten zum neuen Wert hoch, nicht immer ab 0) für Wertung/Streak/Ranglisten-/Flottentreffen-Zahlen; `PopIn` (Panels poppen beim Erscheinen sanft auf) auf der 1-vs-1-Landing; `GameButton` hat einen optionalen `pulse`-Modus für die jeweils wichtigste Aktion (Start-/Kampf-Button) und federt beim Antippen jetzt spürbarer.

**7. Abstände/Rhythmus:** nicht als eigener systematischer Durchgang gemacht, sondern dort vereinheitlicht, wo ohnehin Code angefasst wurde (z. B. 1-vs-1-Landing auf durchgängig 16px zwischen Abschnitten) - kein flächendeckendes Spacing-System eingeführt. Bei Bedarf als eigener, gezielter Schritt nachholbar.

**Getestet:** `flutter analyze`, `flutter test` (27 Tests) und `flutter build web` laufen nach jedem der vier Teilschritte sauber. Echter visueller Eindruck im Browser konnte von mir weiterhin nicht geprüft werden (kein Browser-Werkzeug in dieser Umgebung).

**Nicht angefasst (bewusst, wie schon in Runde 1):** die Bedienelemente innerhalb der 17 einzelnen Spielformate selbst.

**Zurückgestellt (wie angewiesen):** Abschnitt 18d (Download-Seite). **Noch nicht deployt** - reine Flutter/Client-Änderung.
