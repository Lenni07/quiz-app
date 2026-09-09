import 'app_language.dart';

/// Singular-/Pluralform einer Übersetzungs-Vorlage - siehe [S.plural].
class _PluralForms {
  final String one;
  final String other;

  const _PluralForms({required this.one, required this.other});
}

/// Übersetzungen für die Bedienoberfläche (siehe ROADMAP_QuizApp.md
/// Abschnitt 19) - deckt bewusst nur die App-Hülle ab (Reiter, Menüs,
/// Profil, Rangliste, Start-/Warteschlangen-/Draft-/Ergebnisbildschirme).
/// Die 16 einzelnen Spielformat-Bildschirme selbst bleiben vorerst Deutsch.
class S {
  static String t(String key) {
    final entry = _values[key];
    if (entry == null) return key;
    return entry[appLanguage.value] ?? entry[AppLanguage.de] ?? key;
  }

  /// Ersetzt {0}, {1}, ... in der übersetzten Vorlage durch [args].
  static String f(String key, List<Object> args) {
    var result = t(key);
    for (var i = 0; i < args.length; i++) {
      result = result.replaceAll('{$i}', '${args[i]}');
    }
    return result;
  }

  /// Wie [f], wählt aber je nach [count] die Singular- oder Pluralform aus
  /// [_pluralValues] - wichtig in einer Deutsch-Lern-App, wo "1 Tage" ein
  /// besonders schädlicher Grammatikfehler wäre. Deutsch und Englisch
  /// kennen hier beide nur die einfache Unterscheidung "genau 1" vs. "alles
  /// andere" (auch 0), keine komplexeren Plural-Kategorien.
  static String plural(String key, int count, [List<Object>? args]) {
    final entry = _pluralValues[key];
    if (entry == null) return key;
    final forms = entry[appLanguage.value] ?? entry[AppLanguage.de]!;
    var result = count == 1 ? forms.one : forms.other;
    final substitutionArgs = args ?? [count];
    for (var i = 0; i < substitutionArgs.length; i++) {
      result = result.replaceAll('{$i}', '${substitutionArgs[i]}');
    }
    return result;
  }

  static const Map<String, Map<AppLanguage, _PluralForms>> _pluralValues = {
    'streak_label': {
      AppLanguage.de: _PluralForms(one: '{0} Tag', other: '{0} Tage'),
      AppLanguage.en: _PluralForms(one: '{0} day', other: '{0} days'),
    },
    'daily_challenge_streak': {
      AppLanguage.de: _PluralForms(
        one: 'Tages-Challenge geschafft! 🔥 {0} Tag in Folge',
        other: 'Tages-Challenge geschafft! 🔥 {0} Tage in Folge',
      ),
      AppLanguage.en: _PluralForms(
        one: 'Daily challenge complete! 🔥 {0}-day streak',
        other: 'Daily challenge complete! 🔥 {0}-day streak',
      ),
    },
    // Die Pluralform hängt hier vom zweiten Platzhalter ({1}, der
    // Gesamtzahl) ab, nicht vom ersten - deshalb übergibt der Aufrufer
    // count: totalCount und beide Werte explizit als args.
    'progress_level_detail': {
      AppLanguage.de: _PluralForms(one: '{0} von {1} Frage sicher', other: '{0} von {1} Fragen sicher'),
      AppLanguage.en: _PluralForms(one: '{0} of {1} question mastered', other: '{0} of {1} questions mastered'),
    },
  };

  static const Map<String, Map<AppLanguage, String>> _values = {
    // Startbildschirm
    'app_title': {AppLanguage.de: 'Quiz Up Your Rank', AppLanguage.en: 'Quiz Up Your Rank'},
    'tagline': {
      AppLanguage.de: 'Teste dein Wissen über die deutsche Sprache',
      AppLanguage.en: 'Test your knowledge of the German language',
    },
    'start_button': {AppLanguage.de: 'Spiel starten', AppLanguage.en: 'Start Game'},

    // Reiter-Navigation
    'tab_learn': {AppLanguage.de: 'Lernmodus', AppLanguage.en: 'Learning Mode'},
    'tab_fleet': {AppLanguage.de: 'Flottentreffen', AppLanguage.en: 'Fleet Meetup'},
    'tab_1v1': {AppLanguage.de: '1 vs 1', AppLanguage.en: '1 vs 1'},
    'tab_ranking': {AppLanguage.de: 'Rangliste', AppLanguage.en: 'Ranking'},
    'tab_profile': {AppLanguage.de: 'Profil', AppLanguage.en: 'Profile'},
    'landing_1v1_subtitle': {
      AppLanguage.de: 'Gegner mit ähnlicher Wertung, Draft-Phase, Best of 3.',
      AppLanguage.en: 'Opponent with a similar rating, draft phase, best of 3.',
    },
    'landing_1v1_button': {AppLanguage.de: 'Quiz-Duell starten', AppLanguage.en: 'Start Quiz Duel'},

    // Lernmodus: Abschnitts-Überschriften
    'section_basics': {AppLanguage.de: 'Grundmodi', AppLanguage.en: 'Basics'},
    'section_more_formats': {AppLanguage.de: 'Weitere Formate', AppLanguage.en: 'More Formats'},
    'section_drag_drop': {AppLanguage.de: 'Drag-and-Drop', AppLanguage.en: 'Drag & Drop'},
    'section_personalized': {AppLanguage.de: 'Persönlich', AppLanguage.en: 'Personal'},
    'section_multiplayer': {AppLanguage.de: 'Mehrspieler', AppLanguage.en: 'Multiplayer'},

    // Spielformat-Namen (auch in Draft-Phase/Match-Ergebnis verwendet) -
    // Anleitungen/Inhalte INNERHALB der Formate bleiben Deutsch.
    'format_allgemeinwissen-quiz': {AppLanguage.de: 'Allgemeinwissen-Quiz', AppLanguage.en: 'General Knowledge Quiz'},
    'format_allgemeinwissen-quiz_subtitle': {
      AppLanguage.de: '25 Wissensfragen zur deutschen Sprache',
      AppLanguage.en: '25 knowledge questions about the German language',
    },
    'format_konversation-ueben': {AppLanguage.de: 'Konversation üben', AppLanguage.en: 'Practice Conversation'},
    'format_konversation-ueben_subtitle': {
      AppLanguage.de: '8 typische Vorstellungsfragen',
      AppLanguage.en: '8 typical introduction questions',
    },
    'format_lueckentext': {AppLanguage.de: 'Lückentext', AppLanguage.en: 'Fill in the Blank'},
    'format_lueckentext_subtitle': {
      AppLanguage.de: 'Fehlendes Wort eintippen',
      AppLanguage.en: 'Type the missing word',
    },
    'format_richtige-reihenfolge': {AppLanguage.de: 'Richtige Reihenfolge', AppLanguage.en: 'Correct Order'},
    'format_richtige-reihenfolge_subtitle': {
      AppLanguage.de: 'Wörter in die richtige Reihenfolge bringen',
      AppLanguage.en: 'Put the words in the correct order',
    },
    'format_karteikarten': {AppLanguage.de: 'Karteikarten üben', AppLanguage.en: 'Practice Flashcards'},
    'format_karteikarten_subtitle': {
      AppLanguage.de: 'Selbst antworten, dann Musterantwort ansehen',
      AppLanguage.en: 'Answer yourself, then check the model answer',
    },
    'format_wahr-oder-falsch': {AppLanguage.de: 'Wahr oder Falsch', AppLanguage.en: 'True or False'},
    'format_wahr-oder-falsch_subtitle': {
      AppLanguage.de: 'Aussage lesen und richtig einschätzen',
      AppLanguage.en: 'Read the statement and judge correctly',
    },
    'format_gameshow-quiz': {AppLanguage.de: 'Gameshow-Quiz', AppLanguage.en: 'Game Show Quiz'},
    'format_gameshow-quiz_subtitle': {
      AppLanguage.de: 'Antwort sperren, dann spannungsgeladen aufdecken',
      AppLanguage.en: 'Lock in your answer, then reveal it dramatically',
    },
    'format_bild-quiz': {AppLanguage.de: 'Bild-Quiz', AppLanguage.en: 'Picture Quiz'},
    'format_bild-quiz_subtitle': {
      AppLanguage.de: 'Symbol sehen, passendes Wort wählen',
      AppLanguage.en: 'See the symbol, choose the matching word',
    },
    'format_open-the-box': {AppLanguage.de: 'Open the Box', AppLanguage.en: 'Open the Box'},
    'format_open-the-box_subtitle': {
      AppLanguage.de: 'Box öffnen und versteckte Frage beantworten',
      AppLanguage.en: 'Open the box and answer the hidden question',
    },
    'format_find-the-match': {AppLanguage.de: 'Find the Match', AppLanguage.en: 'Find the Match'},
    'format_find-the-match_subtitle': {
      AppLanguage.de: 'Memory: Deutsch und Englisch zusammenfinden',
      AppLanguage.en: 'Memory: match German and English',
    },
    'format_random-wheel': {AppLanguage.de: 'Random Wheel', AppLanguage.en: 'Random Wheel'},
    'format_random-wheel_subtitle': {
      AppLanguage.de: 'Glücksrad drehen und Frage beantworten',
      AppLanguage.en: 'Spin the wheel and answer the question',
    },
    'format_flip-tiles': {AppLanguage.de: 'Flip Tiles', AppLanguage.en: 'Flip Tiles'},
    'format_flip-tiles_subtitle': {
      AppLanguage.de: 'Buchstaben raten und Wort Stück für Stück aufdecken',
      AppLanguage.en: 'Guess letters and reveal the word piece by piece',
    },
    'format_match-up': {AppLanguage.de: 'Match Up', AppLanguage.en: 'Match Up'},
    'format_match-up_subtitle': {
      AppLanguage.de: 'Deutsche Wörter zur englischen Übersetzung ziehen',
      AppLanguage.en: 'Drag German words to their English translation',
    },
    'format_word-magnets': {AppLanguage.de: 'Word Magnets', AppLanguage.en: 'Word Magnets'},
    'format_word-magnets_subtitle': {
      AppLanguage.de: 'Wortmagnete (inkl. Ablenkern) zum Satz zusammenziehen',
      AppLanguage.en: 'Drag word magnets (including decoys) into a sentence',
    },
    'format_group-sort': {AppLanguage.de: 'Group Sort', AppLanguage.en: 'Group Sort'},
    'format_group-sort_subtitle': {
      AppLanguage.de: 'Wörter in die richtige Kategorie ziehen',
      AppLanguage.en: 'Drag words into the correct category',
    },
    'format_rank-order': {AppLanguage.de: 'Rank Order', AppLanguage.en: 'Rank Order'},
    'format_rank-order_subtitle': {
      AppLanguage.de: 'Zahlwörter der Größe nach sortieren',
      AppLanguage.en: 'Sort number words by size',
    },
    'format_hoerverstehen': {AppLanguage.de: 'Hörverständnis', AppLanguage.en: 'Listening Comprehension'},
    'format_hoerverstehen_subtitle': {
      AppLanguage.de: 'Deutschen Satz anhören und die Bedeutung erkennen',
      AppLanguage.en: 'Listen to a German sentence and recognize its meaning',
    },
    'format_persoenliche-fragen': {AppLanguage.de: 'Persönliche Fragen', AppLanguage.en: 'Personal Questions'},
    'format_persoenliche-fragen_subtitle': {
      AppLanguage.de: 'Fragen mit deinem eigenen Namen, Alter und deiner Position',
      AppLanguage.en: 'Questions using your own name, age and position',
    },
    'personal_questions_profile_incomplete': {
      AppLanguage.de: 'Fülle zuerst dein Profil aus (Name, Geburtsdatum, Position, Sprachform), um personalisierte Fragen zu erhalten.',
      AppLanguage.en: 'Fill in your profile first (name, birth date, position, language form) to get personalized questions.',
    },
    // Nur der Modus "Persönliche Fragen" wird gesperrt, wenn diese Angaben
    // fehlen (siehe ROADMAP_QuizApp.md Abschnitt 18f/18h) - der Rest der App
    // bleibt nutzbar. {0} = kommagetrennte Liste der fehlenden Angaben.
    'personal_questions_missing': {
      AppLanguage.de: 'Für persönliche Fragen fehlt in deinem Profil noch: {0}.',
      AppLanguage.en: 'Personal questions still need this in your profile: {0}.',
    },
    'pq_req_firstname': {AppLanguage.de: 'Vorname', AppLanguage.en: 'first name'},
    'pq_req_birthdate': {AppLanguage.de: 'Geburtsdatum', AppLanguage.en: 'date of birth'},
    'pq_req_form': {AppLanguage.de: 'Sprachform', AppLanguage.en: 'language form'},
    'duel_title': {AppLanguage.de: 'Lokales Duell', AppLanguage.en: 'Local Duel'},
    'duel_subtitle': {
      AppLanguage.de: 'Gegen ein anderes Gerät im selben WLAN antreten',
      AppLanguage.en: 'Compete against another device on the same WiFi',
    },

    // Flottentreffen
    'fleet_season_info': {
      AppLanguage.de: 'Season {0} · Punkte zählen für dein Schiff, Reset jeden Monatsanfang',
      AppLanguage.en: 'Season {0} · points count for your ship, reset at the start of each month',
    },
    'fleet_no_account': {
      AppLanguage.de: 'Keine Verbindung zum Konto - Flottentreffen ist gerade nicht verfügbar.',
      AppLanguage.en: 'No connection to your account - Fleet Meetup is currently unavailable.',
    },
    'fleet_my_ship': {AppLanguage.de: 'Dein Schiff: {0}', AppLanguage.en: 'Your ship: {0}'},
    'fleet_ranking_label': {AppLanguage.de: 'Flottenrangliste:', AppLanguage.en: 'Fleet ranking:'},
    'fleet_join_prompt': {
      AppLanguage.de: 'Noch keinem Schiff beigetreten. Name eingeben, um mitzumachen:',
      AppLanguage.en: 'Not part of a ship yet. Enter a name to join in:',
    },
    'fleet_ship_name_label': {AppLanguage.de: 'Schiffsname', AppLanguage.en: 'Ship name'},
    'fleet_ship_name_hint': {AppLanguage.de: 'z. B. MS Freedom', AppLanguage.en: 'e.g. MS Freedom'},
    'fleet_joining': {AppLanguage.de: 'Beitreten ...', AppLanguage.en: 'Joining ...'},
    'fleet_join_button': {AppLanguage.de: 'Schiff beitreten', AppLanguage.en: 'Join Ship'},
    'fleet_ranking_empty': {
      AppLanguage.de: 'Noch keine Punkte diese Season - sei das erste Schiff!',
      AppLanguage.en: 'No points yet this season - be the first ship!',
    },
    'fleet_points_suffix': {AppLanguage.de: 'Pkt.', AppLanguage.en: 'pts'},

    // Rangliste
    'ranking_unavailable': {
      AppLanguage.de: 'Rangliste gerade nicht verfügbar.',
      AppLanguage.en: 'Ranking currently unavailable.',
    },
    'ranking_empty': {
      AppLanguage.de: 'Noch keine gewerteten Matches – spiel eine Runde im 1-vs-1-Modus, um zu starten.',
      AppLanguage.en: 'No ranked matches yet – play a round in 1 vs 1 mode to get started.',
    },
    'ranking_you_suffix': {AppLanguage.de: '(du)', AppLanguage.en: '(you)'},

    // Lernmodus-Fortschritt (siehe ROADMAP_QuizApp.md Abschnitt 18e)
    'progress_card_title': {AppLanguage.de: 'Mein Fortschritt', AppLanguage.en: 'My Progress'},
    'progress_card_subtitle': {
      AppLanguage.de: 'Level-Fortschritt, Schwachstellen und offene Fragen',
      AppLanguage.en: 'Level progress, weak spots and open questions',
    },
    'progress_title': {AppLanguage.de: 'Mein Fortschritt', AppLanguage.en: 'My Progress'},
    'progress_levels_heading': {AppLanguage.de: 'Fortschritt pro Level', AppLanguage.en: 'Progress by Level'},
    'progress_level_label': {AppLanguage.de: 'Level {0}', AppLanguage.en: 'Level {0}'},
    'progress_weak_spots_heading': {AppLanguage.de: 'Deine Schwachstellen', AppLanguage.en: 'Your Weak Spots'},
    'progress_weak_spots_empty': {
      AppLanguage.de: 'Noch keine Daten - spiel ein paar Runden im Lernmodus!',
      AppLanguage.en: 'No data yet - play a few rounds in Learning Mode!',
    },
    'progress_weak_spot_detail': {
      AppLanguage.de: '{0} von {1} sicher',
      AppLanguage.en: '{0} of {1} mastered',
    },
    'progress_open_questions_heading': {AppLanguage.de: 'Noch nicht sicher', AppLanguage.en: 'Not Yet Mastered'},
    'progress_open_questions_empty': {
      AppLanguage.de: 'Alles sicher! Du beherrschst aktuell den ganzen Fragenkatalog.',
      AppLanguage.en: 'All mastered! You currently know the entire question catalog.',
    },
    'progress_unavailable': {
      AppLanguage.de: 'Fortschritt konnte nicht geladen werden.',
      AppLanguage.en: 'Progress could not be loaded.',
    },

    // 1-vs-1-Warteschlange
    'queue_no_account': {
      AppLanguage.de: 'Keine Verbindung zum Konto - 1 vs 1 ist gerade nicht verfügbar.',
      AppLanguage.en: 'No connection to your account - 1 vs 1 is currently unavailable.',
    },
    'queue_searching': {AppLanguage.de: 'Suche Gegner ...', AppLanguage.en: 'Searching for opponent ...'},
    'queue_hint': {
      AppLanguage.de: 'Sobald ein ähnlich gerankter Spieler ebenfalls sucht, geht es automatisch weiter.',
      AppLanguage.en: 'As soon as a similarly ranked player is also searching, it continues automatically.',
    },
    'queue_cancel': {AppLanguage.de: 'Abbrechen', AppLanguage.en: 'Cancel'},

    // Draft-Phase
    'draft_title': {AppLanguage.de: 'Draft-Phase', AppLanguage.en: 'Draft Phase'},
    'draft_your_turn_ban': {AppLanguage.de: 'Du bist dran: Format bannen', AppLanguage.en: 'Your turn: ban a format'},
    'draft_your_turn_pick': {AppLanguage.de: 'Du bist dran: Format wählen', AppLanguage.en: 'Your turn: pick a format'},
    'draft_opponent_ban': {AppLanguage.de: 'Gegner bannt ...', AppLanguage.en: 'Opponent is banning ...'},
    'draft_opponent_pick': {AppLanguage.de: 'Gegner wählt ...', AppLanguage.en: 'Opponent is picking ...'},
    'draft_aborted_title': {AppLanguage.de: 'Match abgebrochen', AppLanguage.en: 'Match cancelled'},
    'draft_aborted_body': {
      AppLanguage.de: 'Dein Gegner hat in der Draft-Phase nicht mehr reagiert. '
          'Das Match wurde abgebrochen – deine Wertung ändert sich nicht.',
      AppLanguage.en: 'Your opponent stopped responding during the draft. '
          'The match was cancelled – your rating is unchanged.',
    },
    'draft_aborted_button': {AppLanguage.de: 'Zurück', AppLanguage.en: 'Back'},

    // Match-Ergebnis
    'match_result_title': {AppLanguage.de: 'Match-Ergebnis', AppLanguage.en: 'Match Result'},
    'match_draw': {AppLanguage.de: 'Unentschieden!', AppLanguage.en: 'Draw!'},
    'match_win': {AppLanguage.de: 'Du hast gewonnen! 🎉', AppLanguage.en: 'You won! 🎉'},
    'match_loss': {AppLanguage.de: 'Diesmal verloren.', AppLanguage.en: 'Lost this time.'},
    'match_rounds_label': {AppLanguage.de: 'Runden: {0} : {1}', AppLanguage.en: 'Rounds: {0} : {1}'},
    'match_new_rating': {AppLanguage.de: 'Neue Wertung: {0}', AppLanguage.en: 'New rating: {0}'},
    'match_back_to_start': {AppLanguage.de: 'Zurück zum Start', AppLanguage.en: 'Back to Start'},

    // Runden-Zwischenstand (result_screen.dart im Match-Modus)
    'round_label': {AppLanguage.de: 'Runde {0}: {1} von {2} richtig', AppLanguage.en: 'Round {0}: {1} of {2} correct'},
    'round_waiting': {
      AppLanguage.de: 'Warte auf Ergebnis des Gegners ...',
      AppLanguage.en: 'Waiting for opponent\'s result ...',
    },
    'round_waiting_timeout_hint': {
      AppLanguage.de: 'Kommt der Gegner nicht zurück, wird das Match nach einigen Minuten zu deinen Gunsten gewertet.',
      AppLanguage.en: 'If the opponent does not return, the match is decided in your favour after a few minutes.',
    },
    'match_aborted_body': {
      AppLanguage.de: 'Beide Spieler sind aus dem Match ausgestiegen. Es wurde ohne Wertung verworfen.',
      AppLanguage.en: 'Both players left the match. It was discarded without a rating change.',
    },
    'resume_match_title': {
      AppLanguage.de: 'Du hast ein laufendes Match',
      AppLanguage.en: 'You have a match in progress',
    },
    'resume_match_button': {AppLanguage.de: 'Zurück ins Match', AppLanguage.en: 'Back to match'},
    'round_draw': {AppLanguage.de: 'Runde unentschieden.', AppLanguage.en: 'Round drawn.'},
    'round_win': {AppLanguage.de: 'Runde gewonnen!', AppLanguage.en: 'Round won!'},
    'round_loss': {AppLanguage.de: 'Runde verloren.', AppLanguage.en: 'Round lost.'},
    'round_view_result': {AppLanguage.de: 'Ergebnis ansehen', AppLanguage.en: 'View Result'},
    'round_next': {AppLanguage.de: 'Nächste Runde', AppLanguage.en: 'Next Round'},

    // Solo-Ergebnisbildschirm
    'result_title': {AppLanguage.de: 'Ergebnis', AppLanguage.en: 'Result'},
    'result_score_label': {AppLanguage.de: '{0} von {1} richtig', AppLanguage.en: '{0} of {1} correct'},
    'result_play_again': {AppLanguage.de: 'Nochmal spielen', AppLanguage.en: 'Play Again'},

    // Profil
    'profile_no_account': {AppLanguage.de: 'Keine Verbindung zum Konto.', AppLanguage.en: 'No connection to your account.'},
    'profile_avatar_choose': {AppLanguage.de: 'Avatar wählen', AppLanguage.en: 'Choose Avatar'},
    'profile_nickname_label': {AppLanguage.de: 'Nickname', AppLanguage.en: 'Nickname'},
    'profile_firstname_label': {AppLanguage.de: 'Vorname', AppLanguage.en: 'First name'},
    'profile_public_helper': {
      AppLanguage.de: 'Wird auch in der Rangliste angezeigt',
      AppLanguage.en: 'Also shown in the ranking',
    },
    // Namensänderung mit Sperrfrist (siehe ROADMAP_QuizApp.md Abschnitt 18h Punkt 4)
    'names_change_helper': {
      AppLanguage.de: 'Nach einer Änderung 30 Tage gesperrt',
      AppLanguage.en: 'Locked for 30 days after a change',
    },
    'names_locked_until': {
      AppLanguage.de: 'Wieder änderbar ab {0}',
      AppLanguage.en: 'Changeable again from {0}',
    },
    'names_save': {AppLanguage.de: 'Namen speichern', AppLanguage.en: 'Save names'},
    'names_save_success': {AppLanguage.de: 'Namen gespeichert.', AppLanguage.en: 'Names saved.'},
    'names_locked': {
      AppLanguage.de: 'Vor- oder Nickname wurde kürzlich geändert – erst in {0} Tagen wieder möglich.',
      AppLanguage.en: 'First name or nickname was changed recently – possible again in {0} days.',
    },
    'names_invalid': {
      AppLanguage.de: 'Name muss zwischen 1 und 40 Zeichen lang sein.',
      AppLanguage.en: 'Name must be between 1 and 40 characters.',
    },

    // Konto- und Datenlöschung (DSGVO, siehe ROADMAP_QuizApp.md Abschnitt 18i)
    'delete_account_title': {AppLanguage.de: 'Konto löschen', AppLanguage.en: 'Delete account'},
    'delete_account_explainer': {
      AppLanguage.de: 'Löscht dein Konto und alle zugehörigen Daten unwiderruflich: '
          'Profil, Fortschritt, Wertung, Ranglisteneintrag und die Freigabe deiner Crew-ID.',
      AppLanguage.en: 'Permanently deletes your account and all associated data: '
          'profile, progress, rating, ranking entry, and releases your crew ID.',
    },
    'delete_account_button': {AppLanguage.de: 'Konto löschen', AppLanguage.en: 'Delete account'},
    'delete_account_keyword': {AppLanguage.de: 'LÖSCHEN', AppLanguage.en: 'DELETE'},
    'delete_account_dialog_body': {
      AppLanguage.de: 'Das kann nicht rückgängig gemacht werden. Dein gesamter Fortschritt geht verloren.',
      AppLanguage.en: 'This cannot be undone. All your progress will be lost.',
    },
    'delete_account_dialog_prompt': {
      AppLanguage.de: 'Tippe {0} ein, um zu bestätigen:',
      AppLanguage.en: 'Type {0} to confirm:',
    },
    'delete_account_cancel': {AppLanguage.de: 'Abbrechen', AppLanguage.en: 'Cancel'},
    'delete_account_confirm': {AppLanguage.de: 'Endgültig löschen', AppLanguage.en: 'Delete permanently'},
    'delete_account_done': {
      AppLanguage.de: 'Konto gelöscht. Du bist jetzt wieder ohne Anmeldung unterwegs.',
      AppLanguage.en: 'Account deleted. You are now using the app without an account.',
    },
    'delete_account_error': {
      AppLanguage.de: 'Löschen fehlgeschlagen – bitte Internetverbindung prüfen und erneut versuchen.',
      AppLanguage.en: 'Deletion failed – please check your connection and try again.',
    },
    'profile_position_label': {AppLanguage.de: 'Position', AppLanguage.en: 'Position'},
    'profile_realname_label': {AppLanguage.de: 'Nachname', AppLanguage.en: 'Last name'},
    'profile_private_helper': {
      AppLanguage.de: 'Nur in deinem Profil sichtbar',
      AppLanguage.en: 'Only visible in your own profile',
    },
    'profile_department_label': {AppLanguage.de: 'Department', AppLanguage.en: 'Department'},
    'department_unspecified': {AppLanguage.de: 'Nicht angegeben', AppLanguage.en: 'Not specified'},
    'department_restaurant': {AppLanguage.de: 'Restaurant', AppLanguage.en: 'Restaurant'},
    'department_housekeeping': {AppLanguage.de: 'Housekeeping', AppLanguage.en: 'Housekeeping'},
    'department_rezeption': {AppLanguage.de: 'Rezeption', AppLanguage.en: 'Front Desk'},
    'department_spa': {AppLanguage.de: 'Spa', AppLanguage.en: 'Spa'},
    'department_security': {AppLanguage.de: 'Security', AppLanguage.en: 'Security'},
    'profile_crewid_label': {AppLanguage.de: 'Crew-ID', AppLanguage.en: 'Crew ID'},
    // Crew-ID einreichen (siehe ROADMAP_QuizApp.md Abschnitt 18h/18i)
    'crewid_helper': {
      AppLanguage.de: 'Genau 6 Ziffern. Wird nur verschlüsselt geprüft und gespeichert und gehört zu genau einem Konto.',
      AppLanguage.en: 'Exactly 6 digits. Checked and stored only in encrypted form, and belongs to exactly one account.',
    },
    'crewid_save': {AppLanguage.de: 'Crew-ID speichern', AppLanguage.en: 'Save crew ID'},
    'crewid_set_label': {AppLanguage.de: 'Crew-ID ist hinterlegt', AppLanguage.en: 'Crew ID is on file'},
    'crewid_change': {AppLanguage.de: 'Ändern', AppLanguage.en: 'Change'},
    'crewid_claim_success': {AppLanguage.de: 'Crew-ID gespeichert.', AppLanguage.en: 'Crew ID saved.'},
    'crewid_error_taken': {
      AppLanguage.de: 'Diese Crew-ID ist bereits einem anderen Konto zugeordnet.',
      AppLanguage.en: 'This crew ID is already linked to another account.',
    },
    'crewid_error_needs_google': {
      AppLanguage.de: 'Bitte zuerst mit Google anmelden, dann die Crew-ID hinterlegen.',
      AppLanguage.en: 'Please sign in with Google first, then add your crew ID.',
    },
    'crewid_error_invalid': {
      AppLanguage.de: 'Die Crew-ID muss aus genau 6 Ziffern bestehen.',
      AppLanguage.en: 'The crew ID must be exactly 6 digits.',
    },
    'crewid_error_generic': {
      AppLanguage.de: 'Speichern fehlgeschlagen - bitte Internetverbindung prüfen.',
      AppLanguage.en: 'Save failed - please check your internet connection.',
    },
    // Was zum Freischalten von 1 vs 1 / Flottentreffen / Rangliste noch fehlt
    // (siehe ROADMAP_QuizApp.md Abschnitt 18h "Gestufter Zugang"). Offene
    // Schritte werden rot hervorgehoben - im Profil und auf dem Sperrbildschirm.
    'unlock_todo_title': {
      AppLanguage.de: 'Zum Freischalten von 1 vs 1, Flottentreffen und Rangliste fehlt noch:',
      AppLanguage.en: 'To unlock 1 vs 1, Fleet Meetup and Ranking you still need:',
    },
    'unlock_step_google': {
      AppLanguage.de: 'Mit Google anmelden',
      AppLanguage.en: 'Sign in with Google',
    },
    'unlock_step_crewid': {
      AppLanguage.de: 'Crew-ID hinterlegen (6 Ziffern)',
      AppLanguage.en: 'Add your crew ID (6 digits)',
    },
    'unlock_step_nickname': {
      AppLanguage.de: 'Nickname eintragen (steht in der Rangliste)',
      AppLanguage.en: 'Add a nickname (shown in the ranking)',
    },
    'unlock_step_position': {
      AppLanguage.de: 'Position eintragen (steht in der Rangliste)',
      AppLanguage.en: 'Add your position (shown in the ranking)',
    },
    'unlock_step_done': {AppLanguage.de: 'erledigt', AppLanguage.en: 'done'},
    'unlock_step_open': {AppLanguage.de: 'fehlt noch', AppLanguage.en: 'still missing'},
    'unlock_all_done': {
      AppLanguage.de: 'Alles erledigt – 1 vs 1, Flottentreffen und Rangliste sind frei.',
      AppLanguage.en: 'All done – 1 vs 1, Fleet Meetup and Ranking are unlocked.',
    },
    'profile_level_label': {AppLanguage.de: 'Deutsch-Level', AppLanguage.en: 'German Level'},
    'profile_level_helper': {
      AppLanguage.de: 'Selbsteinschätzung, ohne Einfluss auf deine Wertung im 1-vs-1-Modus',
      AppLanguage.en: 'Self-assessment, has no effect on your 1 vs 1 rating',
    },
    'profile_level_option': {AppLanguage.de: 'Level {0}', AppLanguage.en: 'Level {0}'},
    'profile_certificate_title': {AppLanguage.de: 'Zertifikat', AppLanguage.en: 'Certificate'},
    'profile_certificate_none': {
      AppLanguage.de: 'Kein Ausstellungsdatum hinterlegt',
      AppLanguage.en: 'No issue date on file',
    },
    'profile_certificate_issued': {AppLanguage.de: 'Ausgestellt am {0}', AppLanguage.en: 'Issued on {0}'},
    'profile_certificate_valid': {AppLanguage.de: 'Gültig bis {0}', AppLanguage.en: 'Valid until {0}'},
    'profile_certificate_expired': {AppLanguage.de: 'Abgelaufen seit {0}', AppLanguage.en: 'Expired since {0}'},

    // Geburtsdatum/Sprachform (siehe ROADMAP_QuizApp.md Abschnitt 18f, für
    // personalisierte Fragen) - beide bleiben wie realName/department nur
    // im eigenen Profil sichtbar. Die Sprachform dient ausschließlich der
    // Wahl der grammatischen Form (Kellner/Kellnerin), nicht einer
    // Identitätsangabe - deshalb keine "Geschlecht"-Frage.
    'profile_birthdate_title': {AppLanguage.de: 'Geburtsdatum', AppLanguage.en: 'Date of Birth'},
    'profile_birthdate_none': {
      AppLanguage.de: 'Noch kein Geburtsdatum hinterlegt',
      AppLanguage.en: 'No date of birth on file',
    },
    'profile_birthdate_set': {AppLanguage.de: '{0} ({1} Jahre)', AppLanguage.en: '{0} ({1} years)'},
    'profile_grammatical_form_label': {AppLanguage.de: 'Sprachform', AppLanguage.en: 'Language form'},
    'profile_grammatical_form_title': {
      AppLanguage.de: 'Welche Sprachform möchtest du lernen?',
      AppLanguage.en: 'Which language form would you like to learn?',
    },
    'profile_grammatical_form_male': {AppLanguage.de: 'Männlich', AppLanguage.en: 'Male'},
    'profile_grammatical_form_female': {AppLanguage.de: 'Weiblich', AppLanguage.en: 'Female'},

    // Konto / Google-Anmeldung (siehe ROADMAP_QuizApp.md Abschnitt 18h)
    'account_section_title': {AppLanguage.de: 'Konto', AppLanguage.en: 'Account'},
    'account_anonymous_info': {
      AppLanguage.de: 'Dein Fortschritt ist zurzeit nur auf diesem Gerät gespeichert. '
          'Melde dich an, damit er einen Gerätewechsel übersteht – '
          'und um 1 vs 1, Flottentreffen und Rangliste freizuschalten.',
      AppLanguage.en: 'Your progress is currently stored only on this device. '
          'Sign in so it survives a device change – '
          'and to unlock 1 vs 1, Fleet Meetup and Ranking.',
    },
    'account_link_google_button': {
      AppLanguage.de: 'Mit Google anmelden',
      AppLanguage.en: 'Sign in with Google',
    },
    'account_link_email_button': {
      AppLanguage.de: 'Mit E-Mail-Link anmelden (ohne Passwort)',
      AppLanguage.en: 'Sign in with email link (no password)',
    },
    'account_email_link_helper': {
      AppLanguage.de: 'Wir schicken dir einen Link zum Anklicken – kein Passwort nötig.',
      AppLanguage.en: 'We send you a link to tap – no password needed.',
    },
    'account_email_link_send': {AppLanguage.de: 'Link senden', AppLanguage.en: 'Send link'},
    'account_email_link_resend': {AppLanguage.de: 'Link erneut senden', AppLanguage.en: 'Send link again'},
    'account_email_link_sent': {
      AppLanguage.de: 'Anmeldelink an {0} geschickt. Öffne ihn möglichst auf diesem Gerät; '
          'auf einem anderen Gerät fragt die App noch einmal nach deiner Adresse.',
      AppLanguage.en: 'Sign-in link sent to {0}. Open it on this device if you can; '
          'on another device the app will ask for your address again.',
    },
    'account_email_invalid': {
      AppLanguage.de: 'Bitte eine gültige E-Mail-Adresse eingeben.',
      AppLanguage.en: 'Please enter a valid email address.',
    },
    'account_email_link_error': {
      AppLanguage.de: 'Link konnte nicht gesendet werden – bitte Internetverbindung prüfen.',
      AppLanguage.en: 'Could not send the link – please check your internet connection.',
    },
    'account_linked_as': {
      AppLanguage.de: 'Angemeldet als {0}',
      AppLanguage.en: 'Signed in as {0}',
    },
    'account_link_success': {
      AppLanguage.de: 'Konto verknüpft – dein Fortschritt ist jetzt gesichert.',
      AppLanguage.en: 'Account linked – your progress is now backed up.',
    },
    'account_link_error_in_use': {
      AppLanguage.de: 'Dieses Konto ist bereits mit einem anderen Spielstand verknüpft.',
      AppLanguage.en: 'This account is already linked to another progress record.',
    },
    'account_link_error_generic': {
      AppLanguage.de: 'Anmeldung nicht abgeschlossen. Bitte erneut versuchen.',
      AppLanguage.en: 'Sign-in was not completed. Please try again.',
    },
    'account_link_web_only': {
      AppLanguage.de: 'Die Anmeldung ist zurzeit nur in der Web-Version möglich.',
      AppLanguage.en: 'Signing in is currently only available in the web version.',
    },
    // Abmelden / Konto wechseln (siehe ROADMAP_QuizApp.md Abschnitt 18h)
    'account_sign_out_button': {AppLanguage.de: 'Abmelden / Konto wechseln', AppLanguage.en: 'Sign out / switch account'},
    'account_sign_out_title': {AppLanguage.de: 'Abmelden?', AppLanguage.en: 'Sign out?'},
    'account_sign_out_explainer': {
      AppLanguage.de: 'Die App läuft danach anonym weiter – der Lernmodus bleibt nutzbar. '
          'Dein bisheriger Fortschritt hängt am abgemeldeten Konto und kommt zurück, '
          'sobald du dich dort wieder anmeldest. 1 vs 1, Flottentreffen und Rangliste '
          'sind bis dahin gesperrt.',
      AppLanguage.en: 'The app then continues anonymously – Learning Mode stays usable. '
          'Your progress so far stays with the account you signed out of and returns '
          'once you sign back in there. 1 vs 1, Fleet Meetup and Ranking are locked '
          'until then.',
    },
    'account_sign_out_done': {
      AppLanguage.de: 'Abgemeldet. Melde dich jederzeit wieder an, um deinen Fortschritt zu holen.',
      AppLanguage.en: 'Signed out. Sign in again any time to get your progress back.',
    },
    'cancel': {AppLanguage.de: 'Abbrechen', AppLanguage.en: 'Cancel'},

    // E-Mail-Link abschließen (CompleteEmailSignInScreen, ROADMAP 18h)
    'email_link_title': {AppLanguage.de: 'Anmeldung abschließen', AppLanguage.en: 'Finish signing in'},
    'email_link_needs_email': {
      AppLanguage.de: 'Zur Sicherheit noch einmal: Für welche E-Mail-Adresse wurde dieser '
          'Anmeldelink angefordert? (Der Link wurde auf einem anderen Gerät geöffnet.)',
      AppLanguage.en: 'For security, once more: which email address was this sign-in link '
          'requested for? (The link was opened on a different device.)',
    },
    'email_link_email_label': {AppLanguage.de: 'E-Mail-Adresse', AppLanguage.en: 'Email address'},
    'email_link_finish': {AppLanguage.de: 'Anmelden', AppLanguage.en: 'Sign in'},
    'email_link_success': {AppLanguage.de: 'Angemeldet – dein Fortschritt ist gesichert.', AppLanguage.en: 'Signed in – your progress is backed up.'},
    'email_link_success_as': {AppLanguage.de: 'Angemeldet als {0} – dein Fortschritt ist gesichert.', AppLanguage.en: 'Signed in as {0} – your progress is backed up.'},
    'email_link_failed': {
      AppLanguage.de: 'Dieser Anmeldelink ist ungültig oder abgelaufen. Fordere im Profil einen neuen an.',
      AppLanguage.en: 'This sign-in link is invalid or has expired. Request a new one in your profile.',
    },
    'email_link_continue': {AppLanguage.de: 'Weiter zur App', AppLanguage.en: 'Continue to app'},

    // Gestufter Zugang / Konto-Sperre (siehe ROADMAP_QuizApp.md Abschnitt 18h)
    'gate_title': {AppLanguage.de: 'Wettkampf-Profil unvollständig', AppLanguage.en: 'Competitive profile incomplete'},
    'gate_locked_intro': {
      AppLanguage.de: '1 vs 1, Flottentreffen und Rangliste brauchen ein vollständiges Wettkampf-Profil. '
          'Im Profil eintragen, was noch fehlt:',
      AppLanguage.en: '1 vs 1, Fleet Meetup and Ranking need a complete competitive profile. '
          'Add what is still missing in your profile:',
    },
    'gate_no_connection': {
      AppLanguage.de: 'Konto gerade nicht prüfbar – bitte Internetverbindung prüfen.',
      AppLanguage.en: 'Cannot verify your account right now – please check your internet connection.',
    },
    'gate_go_to_profile': {AppLanguage.de: 'Zum Profil', AppLanguage.en: 'Go to profile'},

    'profile_save': {AppLanguage.de: 'Speichern', AppLanguage.en: 'Save'},
    'profile_save_success': {AppLanguage.de: 'Profil gespeichert.', AppLanguage.en: 'Profile saved.'},
    'profile_save_error': {
      AppLanguage.de: 'Speichern fehlgeschlagen - bitte Internetverbindung prüfen.',
      AppLanguage.en: 'Save failed - please check your internet connection.',
    },
    'profile_rating_label': {AppLanguage.de: '1-vs-1-Wertung', AppLanguage.en: '1 vs 1 Rating'},
    'profile_ship_label': {AppLanguage.de: 'Schiff', AppLanguage.en: 'Ship'},
    'profile_ship_none': {AppLanguage.de: 'Keinem beigetreten', AppLanguage.en: 'Not joined'},
    'profile_language_title': {AppLanguage.de: 'Sprache', AppLanguage.en: 'Language'},
    'profile_language_de': {AppLanguage.de: 'Deutsch', AppLanguage.en: 'German'},
    'profile_language_en': {AppLanguage.de: 'English', AppLanguage.en: 'English'},
    'profile_sound_title': {AppLanguage.de: 'Sound', AppLanguage.en: 'Sound'},
    'profile_sound_subtitle': {
      AppLanguage.de: 'Antwort- und Button-Sounds - z. B. in gemeinsamen Räumen an Bord stummschalten.',
      AppLanguage.en: 'Answer and button sounds - e.g. mute in shared rooms on board.',
    },
    'profile_sound_on': {AppLanguage.de: 'An', AppLanguage.en: 'On'},
    'profile_sound_off': {AppLanguage.de: 'Aus', AppLanguage.en: 'Off'},

    // Tages-Challenge / Streak
    'streak_tile_label': {AppLanguage.de: 'Streak', AppLanguage.en: 'Streak'},
    'season_rank_label': {AppLanguage.de: 'Platz {0} diese Season', AppLanguage.en: 'Rank {0} this season'},
    'recent_matches_title': {AppLanguage.de: 'Letzte Matches', AppLanguage.en: 'Recent Matches'},
    'recent_matches_empty': {
      AppLanguage.de: 'Noch keine Quiz-Duelle – starte dein erstes!',
      AppLanguage.en: 'No quiz duels yet – start your first one!',
    },
    'recent_matches_unavailable': {
      AppLanguage.de: 'Letzte Matches gerade nicht verfügbar.',
      AppLanguage.en: 'Recent matches currently unavailable.',
    },
    'recent_match_win': {AppLanguage.de: 'Sieg', AppLanguage.en: 'Win'},
    'recent_match_loss': {AppLanguage.de: 'Niederlage', AppLanguage.en: 'Loss'},
    'recent_match_draw': {AppLanguage.de: 'Unentschieden', AppLanguage.en: 'Draw'},
  };
}
