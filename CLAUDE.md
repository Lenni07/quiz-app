# Quiz-App – Projektkontext für Claude Code

## Wichtiger Hinweis für Claude Code
Der Projektinhaber (ich) hat **keine Coding-Vorkenntnisse**. Bitte:
- Erkläre jeden Schritt kurz und in einfacher Sprache, bevor du ihn ausführst.
- Führe nur **einen kleinen, testbaren Schritt** nach dem anderen aus – nicht mehrere Features gleichzeitig.
- Nach jedem Schritt: kurz sagen, wie ich das Ergebnis selbst prüfen/sehen kann (z. B. "starte `flutter run` und du siehst jetzt Bildschirm X").
- Wenn eine Entscheidung ansteht (z. B. welches Package, welche Struktur), gib mir 2 einfache Optionen mit kurzer Empfehlung, statt automatisch zu entscheiden.
- Keine Fachbegriffe ohne kurze Erklärung in Klammern.

---

## 1. Projektziel

Eine einfache, plattformübergreifende Quiz-App (iOS & Android) im Stil bekannter TV-Gewinnstufen-Formate. Nutzer beantworten Multiple-Choice-Fragen und steigen dabei Gewinnstufen auf.

**Kein Multiplayer, kein Echtzeit-Feature, keine KI-Content-Generierung in dieser ersten Version.** Das kommt erst später (siehe Abschnitt 5).

## 2. MVP-Umfang (Version 1 – JETZT bauen)

**Enthalten:**
- Startbildschirm mit "Spiel starten"-Button
- Eine Frage-Ansicht: Frage + 4 Antwortmöglichkeiten (Multiple-Choice)
- Richtig/Falsch-Feedback nach Antwortauswahl
- Einfache Gewinnstufen-Logik (z. B. 10 Fragen, je richtige Antwort = nächste Stufe)
- Ergebnisbildschirm am Ende (erreichte Stufe / Punktzahl)
- Fragen zunächst **lokal** in der App gespeichert (feste Liste, z. B. 20–30 Fragen als JSON-Datei) – **kein Backend, keine Datenbank in Version 1**

**Explizit NICHT enthalten (bewusst weggelassen für später):**
- Kein Server/Backend
- Kein Multiplayer
- Keine Joker
- Kein Admin-Panel
- Keine Drag-and-Drop-Fragetypen
- Keine Nutzerkonten/Login

## 3. Technologie-Entscheidung

- **Framework:** Flutter (Dart) – eine Codebasis für iOS und Android, wie im Projektdokument empfohlen.
- **Datenhaltung Version 1:** Statische JSON-Datei mit Fragen, direkt in der App.
- **State Management:** Einfachster sinnvoller Ansatz für Anfänger (z. B. `setState` oder `Provider`) – Claude Code soll die einfachste Lösung wählen, die für den Umfang ausreicht, nicht die "sauberste" Enterprise-Lösung.

## 4. Schritt-für-Schritt-Plan (bitte in dieser Reihenfolge abarbeiten)

- [x] **Schritt 0: Setup-Check** – Prüfen, ob Flutter, ein Editor (VS Code) und ein Emulator/Testgerät vorhanden sind. Falls nicht: Anleitung zur Installation geben.
- [x] **Schritt 1: Neues Flutter-Projekt anlegen** – Leeres, lauffähiges Grundgerüst erstellen, testen dass es startet.
- [x] **Schritt 2: Startbildschirm** – Einfacher Screen mit App-Titel und "Spiel starten"-Button (noch ohne Funktion).
- [x] **Schritt 3: Fragen-Datenmodell** – JSON-Datei mit ca. 5 Test-Fragen anlegen, in Dart einlesen.
- [x] **Schritt 4: Frage-Bildschirm (statisch)** – Eine Frage mit 4 Antwortbuttons anzeigen, ohne Logik.
- [x] **Schritt 5: Antwort-Logik** – Klick auf Antwort prüfen (richtig/falsch), visuelles Feedback geben.
- [x] **Schritt 6: Navigation durch mehrere Fragen** – Nach Antwort zur nächsten Frage springen.
- [x] **Schritt 7: Punkte-/Gewinnstufen-Logik** – Fortschritt durch Stufen anzeigen und mitzählen.
- [x] **Schritt 8: Ergebnisbildschirm** – Endstand nach letzter Frage anzeigen, Option "Nochmal spielen".
- [x] **Schritt 9: Fragen-Set erweitern** – Von 5 Test-Fragen auf vollständigen Fragenkatalog (z. B. 20–30 Fragen) erweitern.
- [x] **Schritt 10: Feinschliff** – Einfache Animationen/Styling, App-Icon, Testen auf echtem Gerät.

**Regel:** Ein Schritt gilt erst als abgeschlossen, wenn ich (der Projektinhaber) das Ergebnis gesehen und bestätigt habe. Erst dann geht es zum nächsten Schritt.

## 5. Spätere Phasen (NICHT jetzt, nur zur Einordnung)

- **Phase 2:** Backend/Datenbank für Fragen (statt lokaler JSON-Datei), Admin-Panel
- **Phase 3:** Asynchroner rundenbasierter Multiplayer (kein Echtzeit-WebSocket nötig)
- **Phase 4:** Joker-System, Leaderboards, tägliche Herausforderungen
- **Phase 5:** Echtzeit-1v1-Multiplayer (erst wenn App etabliert ist)

## 6. Arbeitsweise / Konventionen

- Code so einfach und lesbar wie möglich halten, auch wenn das nicht die "eleganteste" Lösung ist.
- Nach jedem Schritt kurz zusammenfassen: Was wurde gemacht, was kann ich jetzt testen, was kommt als Nächstes.
- Bei Fehlern: Fehler in einfachen Worten erklären, nicht nur den Stacktrace zeigen.
- Regelmäßig committen (Claude Code kann git-Befehle vorschlagen, aber vorher kurz erklären was passiert).
