import 'package:flutter/material.dart';
import '../l10n/strings.dart';

/// Der Katalog aller Spielformate mit ihrer Format-Kennung (wie an
/// ResultScreen übergeben), Anzeigename und Icon. Zentrale Stelle für die
/// Draft-Phase (Abschnitt 17) und die Reiter-Navigation (Abschnitt 16).
/// Die Liste der IDs muss exakt zu FORMAT_IDS in functions/index.js passen.
/// Muss zu BANS_PER_PLAYER in functions/index.js passen.
const int bansPerPlayer = 3;

class GameFormat {
  final String id;
  final IconData icon;

  const GameFormat({required this.id, required this.icon});

  /// Der Anzeigename gehört zur Bedienoberfläche und wird deshalb übersetzt
  /// (siehe ROADMAP_QuizApp.md Abschnitt 19) - die Inhalte innerhalb des
  /// Formats selbst bleiben Deutsch.
  String get displayName => S.t('format_$id');
}

const List<GameFormat> allGameFormats = [
  GameFormat(id: 'allgemeinwissen-quiz', icon: Icons.public),
  GameFormat(id: 'konversation-ueben', icon: Icons.chat_bubble_outline),
  GameFormat(id: 'lueckentext', icon: Icons.short_text),
  GameFormat(id: 'richtige-reihenfolge', icon: Icons.low_priority),
  GameFormat(id: 'karteikarten', icon: Icons.style_outlined),
  GameFormat(id: 'wahr-oder-falsch', icon: Icons.rule),
  GameFormat(id: 'gameshow-quiz', icon: Icons.theater_comedy),
  GameFormat(id: 'bild-quiz', icon: Icons.image_outlined),
  GameFormat(id: 'open-the-box', icon: Icons.card_giftcard),
  GameFormat(id: 'find-the-match', icon: Icons.grid_view),
  GameFormat(id: 'random-wheel', icon: Icons.donut_large),
  GameFormat(id: 'flip-tiles', icon: Icons.view_module),
  GameFormat(id: 'match-up', icon: Icons.compare_arrows),
  GameFormat(id: 'word-magnets', icon: Icons.dashboard_customize),
  GameFormat(id: 'group-sort', icon: Icons.category),
  GameFormat(id: 'rank-order', icon: Icons.sort),
  GameFormat(id: 'hoerverstehen', icon: Icons.headphones),
];

GameFormat gameFormatById(String id) {
  return allGameFormats.firstWhere(
    (f) => f.id == id,
    orElse: () => GameFormat(id: id, icon: Icons.extension),
  );
}
