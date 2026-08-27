import 'package:flutter/material.dart';
import '../services/game_mode_context.dart';
import '../utils/page_transitions.dart';
import 'fleet_war_screen.dart';
import 'mode_select_screen.dart';

/// Zeigt die drei gleichrangigen Hauptbereiche (siehe ROADMAP_QuizApp.md
/// Abschnitt 15) - erreichbar über "Spiel starten" auf der Startseite,
/// nicht direkt als Kacheln auf der Startseite selbst.
class HomeAreaScreen extends StatelessWidget {
  const HomeAreaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bereich wählen')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HomeAreaButton(
                icon: Icons.emoji_events_outlined,
                label: 'Karrieremodus',
                onPressed: () {
                  Navigator.push(
                    context,
                    buildFadeSlideRoute(const ModeSelectScreen(mode: GameMode.career)),
                  );
                },
              ),
              const SizedBox(height: 16),
              _HomeAreaButton(
                icon: Icons.school_outlined,
                label: 'Lernmodus',
                onPressed: () {
                  Navigator.push(
                    context,
                    buildFadeSlideRoute(const ModeSelectScreen(mode: GameMode.learn)),
                  );
                },
              ),
              const SizedBox(height: 16),
              _HomeAreaButton(
                icon: Icons.groups_outlined,
                label: 'Flottentreffen',
                onPressed: () {
                  Navigator.push(context, buildFadeSlideRoute(const FleetWarScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeAreaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _HomeAreaButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
      ),
    );
  }
}
