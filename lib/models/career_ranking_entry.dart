class CareerRankingEntry {
  final String uid;
  final int eloRating;

  CareerRankingEntry({required this.uid, required this.eloRating});

  factory CareerRankingEntry.fromFirestore(String uid, Map<String, dynamic> data) {
    return CareerRankingEntry(
      uid: uid,
      eloRating: (data['eloRating'] as num?)?.toInt() ?? 1000,
    );
  }

  /// Kurzes Platzhalter-Label, solange es noch keine echten Spielernamen
  /// gibt (siehe ROADMAP_QuizApp.md Abschnitt 13 - visueller Feinschliff
  /// kommt später).
  String get displayName => 'Spieler-${uid.substring(0, uid.length < 6 ? uid.length : 6)}';
}
