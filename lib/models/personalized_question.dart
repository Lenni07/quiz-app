import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'question.dart';

/// Berechnet das Alter aus einem Geburtsdatum (siehe ROADMAP_QuizApp.md
/// Abschnitt 18f) - das Profil speichert bewusst das Geburtsdatum, nicht
/// eine feste Alterszahl, die sonst nie mehr aktuell wäre.
int calculateAge(DateTime birthDate, {DateTime? now}) {
  final today = now ?? DateTime.now();
  var age = today.year - birthDate.year;
  final birthdayAlreadyPassedThisYear =
      today.month > birthDate.month || (today.month == birthDate.month && today.day >= birthDate.day);
  if (!birthdayAlreadyPassedThisYear) age--;
  return age;
}

/// Die für die Platzhalter-Auflösung nötigen Profildaten - bewusst von
/// Firestore entkoppelt (siehe user_profile_service.dart für die
/// Umwandlung), damit diese Datei ohne Firebase testbar bleibt.
class PersonalizationProfile {
  final String firstName;
  final int? age;
  final String position;
  final String crewId;
  final String? grammaticalForm;

  const PersonalizationProfile({
    required this.firstName,
    required this.age,
    required this.position,
    required this.crewId,
    required this.grammaticalForm,
  });

  static const empty = PersonalizationProfile(
    firstName: '',
    age: null,
    position: '',
    crewId: '',
    grammaticalForm: null,
  );
}

final _placeholderPattern = RegExp(r'\{([^{}]+)\}');

/// Ersetzt Platzhalter in [template]: einfache Werte wie "{vorname}",
/// "{alter}", "{position}", "{crewid}" aus dem Profil, sowie
/// geschlechtsabhängige Formen wie "{Kellner/Kellnerin}" oder
/// "{Deutscher/Deutsche}" (männliche Form vor dem Schrägstrich, weibliche
/// danach) - passend zu `profile.grammaticalForm` aufgelöst. Ein
/// Platzhalter, dessen Wert im Profil fehlt, bleibt unverändert stehen -
/// `usableTemplates()` sortiert solche Fragen vorher aus.
String fillTemplate(String template, PersonalizationProfile profile) {
  return template.replaceAllMapped(_placeholderPattern, (match) {
    final content = match.group(1)!;
    if (content.contains('/')) {
      final parts = content.split('/');
      final male = parts[0];
      final female = parts.length > 1 ? parts[1] : parts[0];
      if (profile.grammaticalForm == 'female') return female;
      if (profile.grammaticalForm == 'male') return male;
      return match.group(0)!; // keine Form gewählt - Platzhalter unverändert lassen
    }
    switch (content) {
      case 'vorname':
        return profile.firstName.isEmpty ? match.group(0)! : profile.firstName;
      case 'alter':
        return profile.age == null ? match.group(0)! : profile.age.toString();
      case 'position':
        return profile.position.isEmpty ? match.group(0)! : profile.position;
      case 'crewid':
        return profile.crewId.isEmpty ? match.group(0)! : profile.crewId;
      default:
        return match.group(0)!;
    }
  });
}

/// Ob [template] nach dem Auflösen noch einen unaufgelösten Platzhalter
/// enthält - also ob dem Profil eine für dieses Template nötige Angabe
/// fehlt (fehlendes Geburtsdatum, keine gewählte grammatische Form, ...).
bool _hasUnresolvedPlaceholder(String template, PersonalizationProfile profile) {
  return _placeholderPattern.hasMatch(fillTemplate(template, profile));
}

class PersonalizedQuestionTemplate {
  final String id;
  final String questionTemplate;
  final String correctAnswerTemplate;
  final List<String> decoyPool;
  final int level;
  final String topic;

  const PersonalizedQuestionTemplate({
    required this.id,
    required this.questionTemplate,
    required this.correctAnswerTemplate,
    required this.decoyPool,
    this.level = 1,
    this.topic = 'Persönliche Angaben',
  });

  factory PersonalizedQuestionTemplate.fromJson(Map<String, dynamic> json) {
    return PersonalizedQuestionTemplate(
      id: json['id'] as String,
      questionTemplate: json['question'] as String,
      correctAnswerTemplate: json['correctAnswer'] as String,
      decoyPool: List<String>.from(json['decoyPool'] as List),
      level: json['level'] as int? ?? 1,
      topic: json['topic'] as String? ?? 'Persönliche Angaben',
    );
  }
}

Future<List<PersonalizedQuestionTemplate>> loadPersonalizedQuestionTemplates() async {
  final jsonString = await rootBundle.loadString('assets/personalized_questions.json');
  final List<dynamic> data = jsonDecode(jsonString);
  return data.map((e) => PersonalizedQuestionTemplate.fromJson(e as Map<String, dynamic>)).toList();
}

/// Nur die Vorlagen, für die [profile] alle nötigen Angaben hat (Vorname,
/// Alter, Position, Crew-ID, bzw. eine gewählte grammatische Form) - eine
/// Vorlage mit fehlenden Daten würde sonst mit einer sichtbaren
/// "{platzhalter}"-Lücke angezeigt.
List<PersonalizedQuestionTemplate> usableTemplates(
  List<PersonalizedQuestionTemplate> templates,
  PersonalizationProfile profile,
) {
  return templates.where((t) {
    final combined = '${t.questionTemplate} ${t.correctAnswerTemplate}';
    return !_hasUnresolvedPlaceholder(combined, profile);
  }).toList();
}

/// Baut aus einer Vorlage eine fertige Multiple-Choice-Frage: die richtige
/// Antwort kommt aus dem Profil, die falschen aus dem Platzhalter-Pool der
/// Vorlage (ebenfalls über [fillTemplate] aufgelöst, damit geschlechts-
/// abhängige Falsch-Antworten wie "{Köchin/Koch}" zur gewählten Form
/// passen). [random] ist injizierbar für deterministische Tests.
Question buildPersonalizedQuestion(
  PersonalizedQuestionTemplate template,
  PersonalizationProfile profile, {
  Random? random,
}) {
  final rng = random ?? Random();
  final questionText = fillTemplate(template.questionTemplate, profile);
  final correctAnswer = fillTemplate(template.correctAnswerTemplate, profile);

  final decoys = template.decoyPool
      .map((d) => fillTemplate(d, profile))
      .where((d) => d.toLowerCase() != correctAnswer.toLowerCase())
      .toSet()
      .toList()
    ..shuffle(rng);

  final options = [correctAnswer, ...decoys.take(3)]..shuffle(rng);

  return Question(
    id: 'personal_${template.id}',
    question: questionText,
    options: options,
    correctIndex: options.indexOf(correctAnswer),
    department: 'general',
    level: template.level,
    topic: template.topic,
  );
}

List<Question> buildPersonalizedQuestions(
  List<PersonalizedQuestionTemplate> templates,
  PersonalizationProfile profile, {
  Random? random,
}) {
  return templates.map((t) => buildPersonalizedQuestion(t, profile, random: random)).toList();
}
