import 'app_language.dart';

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
    'landing_1v1_button': {AppLanguage.de: 'Kampf starten', AppLanguage.en: 'Start Battle'},

    // Lernmodus: Abschnitts-Überschriften
    'section_basics': {AppLanguage.de: 'Grundmodi', AppLanguage.en: 'Basics'},
    'section_more_formats': {AppLanguage.de: 'Weitere Formate', AppLanguage.en: 'More Formats'},
    'section_drag_drop': {AppLanguage.de: 'Drag-and-Drop', AppLanguage.en: 'Drag & Drop'},
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
    'profile_public_helper': {
      AppLanguage.de: 'Wird auch in der Rangliste angezeigt',
      AppLanguage.en: 'Also shown in the ranking',
    },
    'profile_position_label': {AppLanguage.de: 'Position', AppLanguage.en: 'Position'},
    'profile_realname_label': {AppLanguage.de: 'Echter Name', AppLanguage.en: 'Real Name'},
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
    'profile_certificate_pick': {AppLanguage.de: 'Datum wählen', AppLanguage.en: 'Pick Date'},
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
  };
}
