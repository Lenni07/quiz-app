import 'package:flutter/material.dart';
import '../widgets/maritime_icon.dart';

/// Vordefinierte Profilbilder (kein echter Fotoupload, siehe
/// ROADMAP_QuizApp.md Abschnitt 18) - durchgängig maritimes Icon-Set statt
/// zufälliger, thematisch fremder Symbole (siehe Abschnitt 13b, zweite
/// Optik-Runde).
class AvatarOption {
  final String id;
  final MaritimeIconShape shape;
  final Color color;

  const AvatarOption({required this.id, required this.shape, required this.color});
}

const List<AvatarOption> allAvatarOptions = [
  AvatarOption(id: 'anchor', shape: MaritimeIconShape.anchor, color: Color(0xFF0B3D5C)),
  AvatarOption(id: 'sailboat', shape: MaritimeIconShape.sailboat, color: Color(0xFFC9A227)),
  AvatarOption(id: 'waves', shape: MaritimeIconShape.waves, color: Color(0xFF00897B)),
  AvatarOption(id: 'compass', shape: MaritimeIconShape.compass, color: Color(0xFF7B1FA2)),
  AvatarOption(id: 'lighthouse', shape: MaritimeIconShape.lighthouse, color: Color(0xFFD7263D)),
  AvatarOption(id: 'lifeRing', shape: MaritimeIconShape.lifeRing, color: Color(0xFFE6C158)),
  AvatarOption(id: 'shipWheel', shape: MaritimeIconShape.shipWheel, color: Color(0xFF1C6690)),
  AvatarOption(id: 'seagull', shape: MaritimeIconShape.seagull, color: Color(0xFF607D8B)),
  AvatarOption(id: 'porthole', shape: MaritimeIconShape.porthole, color: Color(0xFF8F6F14)),
  AvatarOption(id: 'captainHat', shape: MaritimeIconShape.captainHat, color: Color(0xFF071B29)),
];

AvatarOption avatarById(String? id) {
  return allAvatarOptions.firstWhere(
    (option) => option.id == id,
    orElse: () => allAvatarOptions.first,
  );
}
