import 'package:flutter/material.dart';
import '../models/department.dart';
import '../models/flip_tile_word.dart';
import '../models/group_sort.dart';
import '../models/image_quiz.dart';
import '../models/number_word.dart';
import '../models/question.dart';
import '../models/sentence.dart';
import '../models/true_false.dart';
import '../screens/fill_blank_screen.dart';
import '../screens/flashcard_screen.dart';
import '../screens/flip_tiles_screen.dart';
import '../screens/gameshow_quiz_screen.dart';
import '../screens/group_sort_screen.dart';
import '../screens/image_quiz_screen.dart';
import '../screens/listening_screen.dart';
import '../screens/match_pairs_screen.dart';
import '../screens/match_up_screen.dart';
import '../screens/open_box_screen.dart';
import '../screens/question_screen.dart';
import '../screens/random_wheel_screen.dart';
import '../screens/rank_order_screen.dart';
import '../screens/true_false_screen.dart';
import '../screens/word_magnets_screen.dart';
import '../screens/word_order_screen.dart';

/// Lädt die Daten für ein Format und baut den passenden Spiel-Bildschirm -
/// gebraucht für die 1-vs-1-Match-Runden (Abschnitt 17), wo das Format erst
/// nach der Draft-Phase feststeht statt fest in der Modus-Auswahl verdrahtet
/// zu sein. "Karteikarten üben" überspringt dabei die Sprachauswahl und
/// nutzt direkt Englisch, damit eine Runde ohne Zusatzschritt startet.
/// Question-basierte Formate werden bewusst NUR mit allgemeinen,
/// abteilungsübergreifenden Inhalten geladen (siehe ROADMAP_QuizApp.md
/// Abschnitt 18c) - im 1-vs-1-Modus wird nicht nach Department gefiltert
/// oder gematcht, beide Seiten haben dieselben Voraussetzungen.
Future<Widget> buildFormatScreen(String formatId) async {
  switch (formatId) {
    case 'allgemeinwissen-quiz':
      final questions = questionsForCompetitive(await loadQuestions());
      return QuestionScreen(questions: questions, formatId: formatId);
    case 'konversation-ueben':
      final sentences = await loadSentences();
      return QuestionScreen(questions: sentencesToQuestions(sentences), formatId: formatId);
    case 'lueckentext':
      return FillBlankScreen(sentences: await loadSentences());
    case 'richtige-reihenfolge':
      return WordOrderScreen(sentences: await loadSentences());
    case 'karteikarten':
      return FlashcardScreen(
        sentences: await loadSentences(),
        languageCode: 'en',
        languageLabel: 'Englisch',
      );
    case 'wahr-oder-falsch':
      return TrueFalseScreen(statements: await loadTrueFalseStatements());
    case 'gameshow-quiz':
      return GameshowQuizScreen(questions: questionsForCompetitive(await loadQuestions()));
    case 'bild-quiz':
      return ImageQuizScreen(items: await loadImageQuizItems());
    case 'open-the-box':
      final questions = questionsForCompetitive(await loadQuestions());
      return OpenBoxScreen(questions: questions.take(9).toList());
    case 'find-the-match':
      return MatchPairsScreen(sentences: await loadSentences());
    case 'random-wheel':
      return RandomWheelScreen(questions: questionsForCompetitive(await loadQuestions()));
    case 'flip-tiles':
      return FlipTilesScreen(words: await loadFlipTileWords());
    case 'match-up':
      return MatchUpScreen(sentences: await loadSentences());
    case 'word-magnets':
      return WordMagnetsScreen(sentences: await loadSentences());
    case 'group-sort':
      return GroupSortScreen(data: await loadGroupSortData());
    case 'rank-order':
      return RankOrderScreen(words: await loadNumberWords());
    case 'hoerverstehen':
      return ListeningScreen(sentences: await loadSentences());
    default:
      throw ArgumentError('Unbekanntes Format: $formatId');
  }
}
