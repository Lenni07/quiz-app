import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/avatar_option.dart';
import '../services/career_service.dart';
import '../services/fleet_war_service.dart';
import '../services/user_profile_service.dart';

/// Profil/Optionen-Bildschirm (siehe ROADMAP_QuizApp.md Abschnitt 16/18):
/// Nickname, echter Name, Position, Department und ein vordefinierter
/// Avatar (kein echter Fotoupload). Das Avatarbild ist bewusst nur hier zu
/// sehen - Nickname + Position zusätzlich in der Rangliste, echter Name und
/// Department bleiben ausschließlich hier im eigenen Profil.
class ProfileScreen extends StatefulWidget {
  final bool embedded;

  const ProfileScreen({super.key, this.embedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nicknameController = TextEditingController();
  final _realNameController = TextEditingController();
  final _positionController = TextEditingController();
  final _departmentController = TextEditingController();

  String _avatarId = allAvatarOptions.first.id;
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _realNameController.dispose();
    _positionController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile(String uid) async {
    if (_loaded) return;
    final data = await UserProfileService().loadProfile(uid);
    if (!mounted) return;
    setState(() {
      _nicknameController.text = (data?['nickname'] as String?) ?? '';
      _realNameController.text = (data?['realName'] as String?) ?? '';
      _positionController.text = (data?['position'] as String?) ?? '';
      _departmentController.text = (data?['department'] as String?) ?? '';
      _avatarId = (data?['avatarId'] as String?) ?? allAvatarOptions.first.id;
      _loaded = true;
    });
  }

  Future<void> _save(String uid) async {
    setState(() => _saving = true);
    try {
      await UserProfileService().updateProfile(
        uid: uid,
        nickname: _nicknameController.text.trim(),
        realName: _realNameController.text.trim(),
        position: _positionController.text.trim(),
        department: _departmentController.text.trim(),
        avatarId: _avatarId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil gespeichert.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speichern fehlgeschlagen - bitte Internetverbindung prüfen.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final body = uid == null
        ? const Center(child: Text('Keine Verbindung zum Konto.'))
        : FutureBuilder<void>(
            future: _loadProfile(uid),
            builder: (context, snapshot) {
              if (!_loaded) {
                return const Center(child: CircularProgressIndicator());
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: avatarById(_avatarId).color,
                        child: Icon(avatarById(_avatarId).icon, size: 40, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Avatar wählen', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final option in allAvatarOptions)
                          _AvatarChoice(
                            option: option,
                            selected: option.id == _avatarId,
                            onTap: () => setState(() => _avatarId = option.id),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        labelText: 'Nickname',
                        helperText: 'Wird auch in der Rangliste angezeigt',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _positionController,
                      decoration: const InputDecoration(
                        labelText: 'Position',
                        helperText: 'Wird auch in der Rangliste angezeigt',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _realNameController,
                      decoration: const InputDecoration(
                        labelText: 'Echter Name',
                        helperText: 'Nur in deinem Profil sichtbar',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _departmentController,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        helperText: 'Nur in deinem Profil sichtbar',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saving ? null : () => _save(uid),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Speichern'),
                    ),
                    const SizedBox(height: 32),
                    FutureBuilder<List<dynamic>>(
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
                            _InfoRow(icon: Icons.emoji_events_outlined, label: '1-vs-1-Wertung', value: '$rating'),
                            const SizedBox(height: 12),
                            _InfoRow(icon: Icons.groups_outlined, label: 'Schiff', value: ship ?? 'Keinem beigetreten'),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: body,
    );
  }
}

class _AvatarChoice extends StatelessWidget {
  final AvatarOption option;
  final bool selected;
  final VoidCallback onTap;

  const _AvatarChoice({required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? colorScheme.primary : Colors.transparent,
            width: 3,
          ),
        ),
        child: CircleAvatar(
          radius: 24,
          backgroundColor: option.color,
          child: Icon(option.icon, color: Colors.white),
        ),
      ),
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
