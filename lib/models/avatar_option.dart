import 'package:flutter/material.dart';

/// Vordefinierte Profilbilder (kein echter Fotoupload, siehe
/// ROADMAP_QuizApp.md Abschnitt 18) - einfache Icon+Farbe-Kombinationen.
class AvatarOption {
  final String id;
  final IconData icon;
  final Color color;

  const AvatarOption({required this.id, required this.icon, required this.color});
}

const List<AvatarOption> allAvatarOptions = [
  AvatarOption(id: 'anchor', icon: Icons.anchor, color: Color(0xFF01579B)),
  AvatarOption(id: 'sailing', icon: Icons.sailing, color: Color(0xFFFF8A50)),
  AvatarOption(id: 'waves', icon: Icons.waves, color: Color(0xFF00897B)),
  AvatarOption(id: 'compass', icon: Icons.explore, color: Color(0xFF7B1FA2)),
  AvatarOption(id: 'trophy', icon: Icons.emoji_events, color: Color(0xFFFFB300)),
  AvatarOption(id: 'star', icon: Icons.star, color: Color(0xFFD81B60)),
  AvatarOption(id: 'bolt', icon: Icons.bolt, color: Color(0xFFF9A825)),
  AvatarOption(id: 'heart', icon: Icons.favorite, color: Color(0xFFE53935)),
  AvatarOption(id: 'paw', icon: Icons.pets, color: Color(0xFF6D4C41)),
  AvatarOption(id: 'rocket', icon: Icons.rocket_launch, color: Color(0xFF3949AB)),
];

AvatarOption avatarById(String? id) {
  return allAvatarOptions.firstWhere(
    (option) => option.id == id,
    orElse: () => allAvatarOptions.first,
  );
}
