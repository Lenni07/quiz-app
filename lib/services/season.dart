/// "YYYY-MM", z. B. "2026-08" - identifiziert eine Flottenkrieg-Season
/// eindeutig. Muss exakt zur gleichnamigen Funktion in
/// functions/index.js passen (beide rechnen in UTC).
String currentSeasonKey([DateTime? now]) {
  final date = (now ?? DateTime.now()).toUtc();
  final month = date.month.toString().padLeft(2, '0');
  return '${date.year}-$month';
}
