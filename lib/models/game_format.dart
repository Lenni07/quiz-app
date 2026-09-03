import 'package:flutter/material.dart';

/// Der Katalog aller Spielformate mit ihrer Format-Kennung (wie an
/// ResultScreen übergeben), Anzeigename und Icon. Zentrale Stelle für die
/// Draft-Phase (Abschnitt 17) und die Reiter-Navigation (Abschnitt 16).
/// Die Liste der IDs muss exakt zu FORMAT_IDS in functions/index.js passen.
/// Muss zu BANS_PER_PLAYER in functions/index.js passen.
const int bansPerPlayer = 3;

class GameFormat {
  final String id;
  final String displayName;
  final IconData icon;

  const GameFormat({required this.id, required this.displayName, required this.icon});
}

const List<GameFormat> allGameFormats = [
  GameFormat(id: 'allgemeinwissen-quiz', displayName: 'Allgemeinwissen-Quiz', icon: Icons.public),
  GameFormat(id: 'konversation-ueben', displayName: 'Konversation üben', icon: Icons.chat_bubble_outline),
  GameFormat(id: 'lueckentext', displayName: 'Lückentext', icon: Icons.short_text),
  GameFormat(id: 'richtige-reihenfolge', displayName: 'Richtige Reihenfolge', icon: Icons.low_priority),
  GameFormat(id: 'karteikarten', displayName: 'Karteikarten üben', icon: Icons.style_outlined),
  GameFormat(id: 'wahr-oder-falsch', displayName: 'Wahr oder Falsch', icon: Icons.rule),
  GameFormat(id: 'gameshow-quiz', displayName: 'Gameshow-Quiz', icon: Icons.theater_comedy),
  GameFormat(id: 'bild-quiz', displayName: 'Bild-Quiz', icon: Icons.image_outlined),
  GameFormat(id: 'open-the-box', displayName: 'Open the Box', icon: Icons.card_giftcard),
  GameFormat(id: 'find-the-match', displayName: 'Find the Match', icon: Icons.grid_view),
  GameFormat(id: 'random-wheel', displayName: 'Random Wheel', icon: Icons.donut_large),
  GameFormat(id: 'flip-tiles', displayName: 'Flip Tiles', icon: Icons.view_module),
  GameFormat(id: 'match-up', displayName: 'Match Up', icon: Icons.compare_arrows),
  GameFormat(id: 'word-magnets', displayName: 'Word Magnets', icon: Icons.dashboard_customize),
  GameFormat(id: 'group-sort', displayName: 'Group Sort', icon: Icons.category),
  GameFormat(id: 'rank-order', displayName: 'Rank Order', icon: Icons.sort),
];

GameFormat gameFormatById(String id) {
  return allGameFormats.firstWhere(
    (f) => f.id == id,
    orElse: () => GameFormat(id: id, displayName: id, icon: Icons.extension),
  );
}
