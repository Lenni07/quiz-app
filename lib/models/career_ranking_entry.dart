class CareerRankingEntry {
  final String uid;
  final int eloRating;
  final String? nickname;
  final String? position;

  CareerRankingEntry({required this.uid, required this.eloRating, this.nickname, this.position});

  factory CareerRankingEntry.fromFirestore(String uid, Map<String, dynamic> data) {
    return CareerRankingEntry(
      uid: uid,
      eloRating: (data['eloRating'] as num?)?.toInt() ?? 1000,
      nickname: data['nickname'] as String?,
      position: data['position'] as String?,
    );
  }

  /// Fällt auf ein Kurz-Platzhalter-Label zurück, solange kein Nickname
  /// gesetzt ist (siehe ROADMAP_QuizApp.md Abschnitt 18).
  String get displayName {
    if (nickname != null && nickname!.trim().isNotEmpty) return nickname!;
    return 'Spieler-${uid.substring(0, uid.length < 6 ? uid.length : 6)}';
  }
}
