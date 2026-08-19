import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../utils/page_transitions.dart';
import 'duel_host_screen.dart';
import 'duel_join_screen.dart';

class DuelModeScreen extends StatelessWidget {
  const DuelModeScreen({super.key});

  Future<void> _startHosting(BuildContext context) async {
    final questions = await loadQuestions();
    if (context.mounted) {
      Navigator.push(context, buildFadeSlideRoute(DuelHostScreen(questionPool: questions)));
    }
  }

  void _startJoining(BuildContext context) {
    Navigator.push(context, buildFadeSlideRoute(const DuelJoinScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Lokales Duell')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Zwei Geräte im selben WLAN treten gegeneinander an – kein Internet nötig, nur ein gemeinsames Netzwerk.',
              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 24),
            _DuelOptionCard(
              title: 'Duell hosten',
              subtitle: kIsWeb
                  ? 'Im Browser nicht verfügbar – bitte die App auf einem Gerät installieren'
                  : 'Startet ein Duell, dein Mitspieler tritt bei',
              icon: Icons.wifi_tethering,
              onTap: kIsWeb ? null : () => _startHosting(context),
            ),
            const SizedBox(height: 16),
            _DuelOptionCard(
              title: 'Duell beitreten',
              subtitle: 'Einem bereits gestarteten Duell beitreten',
              icon: Icons.login,
              onTap: () => _startJoining(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _DuelOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _DuelOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  bool get _enabled => onTap != null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = _enabled ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.4);

    return Material(
      color: _enabled ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 36, color: foreground),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: foreground),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: foreground.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
              if (_enabled) Icon(Icons.chevron_right, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}
