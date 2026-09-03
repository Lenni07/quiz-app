import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/career_service.dart';
import '../services/fleet_war_service.dart';

/// Einfacher Profil/Optionen-Bildschirm (siehe ROADMAP_QuizApp.md
/// Abschnitt 16) - zeigt die eigenen Eckdaten. Bewusst noch schlicht
/// gehalten, kein Feinschliff (siehe Abschnitt 13 der Roadmap).
class ProfileScreen extends StatelessWidget {
  final bool embedded;

  const ProfileScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final body = Padding(
      padding: const EdgeInsets.all(24.0),
      child: uid == null
          ? const Center(child: Text('Keine Verbindung zum Konto.'))
          : FutureBuilder<List<dynamic>>(
              future: Future.wait([
                CareerService().currentRating(uid),
                FleetWarService().currentShip(uid),
              ]),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rating = snapshot.data![0] as int;
                final ship = snapshot.data![1] as String?;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(Icons.person, size: 44, color: colorScheme.onPrimaryContainer),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Spieler-${uid.substring(0, uid.length < 6 ? uid.length : 6)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),
                    _InfoRow(icon: Icons.emoji_events_outlined, label: '1-vs-1-Wertung', value: '$rating'),
                    const SizedBox(height: 12),
                    _InfoRow(icon: Icons.groups_outlined, label: 'Schiff', value: ship ?? 'Keinem beigetreten'),
                  ],
                );
              },
            ),
    );

    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: body,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onSurface.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
