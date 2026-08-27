class Ship {
  final String id;
  final String name;
  final int seasonScore;

  Ship({required this.id, required this.name, required this.seasonScore});

  factory Ship.fromFirestore(String id, Map<String, dynamic> data) {
    return Ship(
      id: id,
      name: data['name'] as String? ?? id,
      seasonScore: (data['seasonScore'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Normiert einen eingetippten Schiffsnamen zu einer stabilen Dokument-ID,
/// damit z. B. "MS Freedom" und "ms freedom" demselben Schiff beitreten.
String shipIdFromName(String name) {
  final normalized = name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return normalized.isEmpty ? 'schiff' : normalized;
}
