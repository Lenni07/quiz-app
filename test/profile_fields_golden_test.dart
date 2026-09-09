// Optik-Kontrolle für den Profil-Bildschirm (siehe ROADMAP_QuizApp.md
// Abschnitt 18): Alle Datenfelder sollen dasselbe Muster haben - Rahmen
// und schwebende Beschriftung aus dem inputDecorationTheme, gleiche
// Abstände. Dieser Test baut die Feldliste mit Beispieldaten nach und legt
// davon ein Bild ab (test/goldens/profile_fields.png), damit man die
// Gestaltung ohne laufende Firebase-Umgebung ansehen kann.
//
// Bild neu erzeugen:  flutter test --update-goldens test/profile_fields_golden_test.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rank_up/l10n/strings.dart';
import 'package:rank_up/theme/app_theme.dart';

Future<void> _loadFonts() async {
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    final data = File('assets/fonts/Baloo2-$weight.ttf').readAsBytesSync();
    // Baloo2 für die Display-Schrift und ersatzweise als Standard-Schrift,
    // damit im Bild lesbarer Text statt Platzhalter-Kästchen steht.
    for (final family in ['Baloo2', 'Roboto']) {
      final loader = FontLoader(family)
        ..addFont(Future.value(ByteData.view(data.buffer)));
      await loader.load();
    }
  }

  // Material-Icons aus dem Flutter-SDK laden, damit die Symbole (Kalender,
  // Speichern) im Bild sichtbar sind statt als leere Kästchen.
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? r'C:\dev\flutter';
  final iconsDir = Directory('$flutterRoot/bin/cache/artifacts/material_fonts');
  if (iconsDir.existsSync()) {
    final otf = iconsDir
        .listSync()
        .whereType<File>()
        .firstWhere((f) => f.path.toLowerCase().endsWith('materialicons-regular.otf'));
    await (FontLoader('MaterialIcons')
          ..addFont(Future.value(ByteData.view(otf.readAsBytesSync().buffer))))
        .load();
  }
}

/// Feld zum Antippen im selben Stil wie die Textfelder - Kopie von
/// `_PickerField` aus lib/screens/profile_screen.dart, nur für dieses Bild.
class _PickerField extends StatelessWidget {
  final String label;
  final String valueText;
  final String? helperText;

  const _PickerField({
    required this.label,
    required this.valueText,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        isEmpty: false,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          suffixIcon: const Icon(Icons.event_outlined, size: 20),
        ),
        child: Text(valueText, style: const TextStyle(color: AppColors.canvas)),
      ),
    );
  }
}

void main() {
  testWidgets('Profil-Felder haben ein einheitliches Muster', (tester) async {
    await _loadFonts();
    await tester.binding.setSurfaceSize(const Size(430, 880));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final nickname = TextEditingController(text: 'SeaWolf');
    final firstName = TextEditingController(text: 'Lena');
    final lastName = TextEditingController(text: 'Meyer');
    final position = TextEditingController(text: 'Kellnerin');

    Widget field(Widget child) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: child,
        );

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: Scaffold(
        backgroundColor: AppColors.deepSea,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              field(TextField(
                controller: nickname,
                decoration: InputDecoration(
                  labelText: S.t('profile_nickname_label'),
                  helperText: S.t('profile_public_helper'),
                ),
              )),
              field(TextField(
                controller: firstName,
                decoration: InputDecoration(
                  labelText: S.t('profile_firstname_label'),
                  helperText: S.t('names_change_helper'),
                ),
              )),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {},
                  style: TextButton.styleFrom(foregroundColor: AppColors.brassLight),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(S.t('names_save')),
                ),
              ),
              const SizedBox(height: 12),
              field(TextField(
                controller: lastName,
                decoration: InputDecoration(
                  labelText: S.t('profile_realname_label'),
                  helperText: S.t('profile_private_helper'),
                ),
              )),
              field(const _PickerField(
                label: 'Geburtsdatum',
                valueText: '12.03.1990 (35 Jahre)',
                helperText: 'Nur in deinem Profil sichtbar',
              )),
              field(DropdownButtonFormField<String?>(
                initialValue: 'restaurant',
                decoration: InputDecoration(
                  labelText: S.t('profile_department_label'),
                  helperText: S.t('profile_private_helper'),
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text(S.t('department_unspecified'))),
                  DropdownMenuItem(value: 'restaurant', child: Text(S.t('department_restaurant'))),
                ],
                onChanged: (_) {},
              )),
              field(TextField(
                controller: position,
                decoration: InputDecoration(
                  labelText: S.t('profile_position_label'),
                  helperText: S.t('profile_public_helper'),
                ),
              )),
              field(DropdownButtonFormField<String?>(
                initialValue: 'female',
                decoration: InputDecoration(
                  labelText: S.t('profile_grammatical_form_label'),
                  helperText: S.t('profile_grammatical_form_title'),
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text(S.t('department_unspecified'))),
                  DropdownMenuItem(value: 'male', child: Text(S.t('profile_grammatical_form_male'))),
                  DropdownMenuItem(value: 'female', child: Text(S.t('profile_grammatical_form_female'))),
                ],
                onChanged: (_) {},
              )),
              field(DropdownButtonFormField<int>(
                initialValue: 3,
                decoration: InputDecoration(
                  labelText: S.t('profile_level_label'),
                  helperText: S.t('profile_level_helper'),
                ),
                items: [
                  for (var level = 1; level <= 6; level++)
                    DropdownMenuItem(value: level, child: Text(S.f('profile_level_option', [level]))),
                ],
                onChanged: (_) {},
              )),
              field(_PickerField(
                label: S.t('profile_certificate_title'),
                valueText: S.f('profile_certificate_issued', ['01.06.2025']),
                helperText: S.f('profile_certificate_valid', ['01.06.2027']),
              )),
            ],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/profile_fields.png'),
    );
  });
}
