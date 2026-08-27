import 'package:flutter_test/flutter_test.dart';
import 'package:rank_up/models/ship.dart';
import 'package:rank_up/services/season.dart';

void main() {
  group('currentSeasonKey', () {
    test('formatiert Jahr und Monat zweistellig in UTC', () {
      expect(currentSeasonKey(DateTime.utc(2026, 8, 27)), '2026-08');
      expect(currentSeasonKey(DateTime.utc(2026, 1, 1)), '2026-01');
      expect(currentSeasonKey(DateTime.utc(2026, 12, 31)), '2026-12');
    });
  });

  group('shipIdFromName', () {
    test('macht Groß-/Kleinschreibung und Leerzeichen egal', () {
      expect(shipIdFromName('MS Freedom'), 'ms-freedom');
      expect(shipIdFromName('ms freedom'), 'ms-freedom');
      expect(shipIdFromName('  MS   Freedom  '), 'ms-freedom');
    });

    test('entfernt Sonderzeichen', () {
      expect(shipIdFromName('MS Freedom & Sun!'), 'ms-freedom-sun');
    });

    test('leerer Name fällt auf einen Standardwert zurück', () {
      expect(shipIdFromName('   '), 'schiff');
    });
  });
}
