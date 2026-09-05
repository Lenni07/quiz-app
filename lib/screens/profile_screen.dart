import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../audio/sound_settings.dart';
import '../l10n/app_language.dart';
import '../l10n/strings.dart';
import '../models/avatar_option.dart';
import '../models/department.dart';
import '../services/career_service.dart';
import '../services/fleet_war_service.dart';
import '../services/user_profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/game_button.dart';
import '../widgets/maritime_icon.dart';
import '../widgets/game_panel.dart';

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
  final _crewIdController = TextEditingController();

  String _avatarId = allAvatarOptions.first.id;
  String? _department;
  int? _germanLevel;
  DateTime? _certificateIssuedAt;
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _realNameController.dispose();
    _positionController.dispose();
    _crewIdController.dispose();
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
      _department = data?['department'] as String?;
      _crewIdController.text = (data?['crewId'] as String?) ?? '';
      _avatarId = (data?['avatarId'] as String?) ?? allAvatarOptions.first.id;
      _germanLevel = (data?['germanLevel'] as num?)?.toInt();
      _certificateIssuedAt = (data?['certificateIssuedAt'] as Timestamp?)?.toDate();
      _loaded = true;
    });
  }

  Future<void> _changeLanguage(AppLanguage language) async {
    await setAppLanguage(language);
    if (mounted) setState(() {});
  }

  Future<void> _toggleSound(bool enabled) async {
    await setSoundEnabled(enabled);
    if (mounted) setState(() {});
  }

  Future<void> _pickCertificateDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _certificateIssuedAt ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _certificateIssuedAt = picked);
    }
  }

  Future<void> _save(String uid) async {
    setState(() => _saving = true);
    try {
      await UserProfileService().updateProfile(
        uid: uid,
        nickname: _nicknameController.text.trim(),
        realName: _realNameController.text.trim(),
        position: _positionController.text.trim(),
        department: _department ?? '',
        avatarId: _avatarId,
        crewId: _crewIdController.text.trim(),
        germanLevel: _germanLevel,
        certificateIssuedAt: _certificateIssuedAt,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t('profile_save_success'))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t('profile_save_error'))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final body = ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, language, _) => uid == null
        ? Center(child: Text(S.t('profile_no_account')))
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
                    Text(S.t('profile_language_title'), style: displayStyle(fontSize: 15, color: AppColors.brassLight)),
                    const SizedBox(height: 8),
                    SegmentedButton<AppLanguage>(
                      segments: [
                        ButtonSegment(value: AppLanguage.de, label: Text(S.t('profile_language_de'))),
                        ButtonSegment(value: AppLanguage.en, label: Text(S.t('profile_language_en'))),
                      ],
                      selected: {language},
                      onSelectionChanged: (selection) => _changeLanguage(selection.first),
                    ),
                    const SizedBox(height: 24),
                    Text(S.t('profile_sound_title'), style: displayStyle(fontSize: 15, color: AppColors.brassLight)),
                    const SizedBox(height: 4),
                    Text(
                      S.t('profile_sound_subtitle'),
                      style: TextStyle(fontSize: 12, color: AppColors.canvas.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<bool>(
                      valueListenable: soundEnabled,
                      builder: (context, enabled, _) => SegmentedButton<bool>(
                        segments: [
                          ButtonSegment(value: true, label: Text(S.t('profile_sound_on'))),
                          ButtonSegment(value: false, label: Text(S.t('profile_sound_off'))),
                        ],
                        selected: {enabled},
                        onSelectionChanged: (selection) => _toggleSound(selection.first),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(BorderSide(color: AppColors.brass, width: 2.5)),
                          boxShadow: [BoxShadow(color: Colors.black45, offset: Offset(0, 4), blurRadius: 10)],
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: avatarById(_avatarId).color,
                          child: MaritimeIcon(avatarById(_avatarId).shape, size: 40, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(S.t('profile_avatar_choose'), style: displayStyle(fontSize: 15, color: AppColors.brassLight)),
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
                      decoration: InputDecoration(
                        labelText: S.t('profile_nickname_label'),
                        helperText: S.t('profile_public_helper'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _positionController,
                      decoration: InputDecoration(
                        labelText: S.t('profile_position_label'),
                        helperText: S.t('profile_public_helper'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _realNameController,
                      decoration: InputDecoration(
                        labelText: S.t('profile_realname_label'),
                        helperText: S.t('profile_private_helper'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: departmentIds.contains(_department) ? _department : null,
                      decoration: InputDecoration(
                        labelText: S.t('profile_department_label'),
                        helperText: S.t('profile_private_helper'),
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text(S.t('department_unspecified'))),
                        for (final id in departmentIds)
                          DropdownMenuItem(value: id, child: Text(S.t('department_$id'))),
                      ],
                      onChanged: (value) => setState(() => _department = value),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _crewIdController,
                      decoration: InputDecoration(
                        labelText: S.t('profile_crewid_label'),
                        helperText: S.t('profile_private_helper'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _germanLevel,
                      decoration: InputDecoration(
                        labelText: S.t('profile_level_label'),
                        helperText: S.t('profile_level_helper'),
                      ),
                      items: [
                        for (var level = 1; level <= 6; level++)
                          DropdownMenuItem(value: level, child: Text(S.f('profile_level_option', [level]))),
                      ],
                      onChanged: (value) => setState(() => _germanLevel = value),
                    ),
                    const SizedBox(height: 16),
                    Text(S.t('profile_certificate_title'), style: displayStyle(fontSize: 15, color: AppColors.brassLight)),
                    const SizedBox(height: 8),
                    _CertificateStatus(
                      issuedAt: _certificateIssuedAt,
                      onPick: _pickCertificateDate,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: _saving
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : GameButton(
                              label: S.t('profile_save'),
                              icon: Icons.save_outlined,
                              fontSize: 16,
                              onPressed: () => _save(uid),
                            ),
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
                            _InfoRow(icon: Icons.emoji_events_outlined, label: S.t('profile_rating_label'), value: '$rating'),
                            const SizedBox(height: 12),
                            _InfoRow(icon: Icons.groups_outlined, label: S.t('profile_ship_label'), value: ship ?? S.t('profile_ship_none')),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
    );

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(S.t('tab_profile'))),
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
          child: MaritimeIcon(option.shape, color: Colors.white),
        ),
      ),
    );
  }
}

/// Zeigt das Ausstellungsdatum des Zertifikats und den automatisch daraus
/// berechneten Status (Ausstellung + 2 Jahre, siehe ROADMAP_QuizApp.md
/// Abschnitt 18) - keine manuelle Ablaufprüfung nötig.
class _CertificateStatus extends StatelessWidget {
  final DateTime? issuedAt;
  final VoidCallback onPick;

  const _CertificateStatus({required this.issuedAt, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final issued = issuedAt;
    DateTime? expiry;
    bool? isValid;
    if (issued != null) {
      expiry = DateTime(issued.year + 2, issued.month, issued.day);
      isValid = DateTime.now().isBefore(expiry);
    }

    String formatDate(DateTime date) =>
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

    return GamePanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 14,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issued == null ? S.t('profile_certificate_none') : S.f('profile_certificate_issued', [formatDate(issued)]),
                  style: const TextStyle(color: AppColors.canvas),
                ),
                if (expiry != null)
                  Text(
                    isValid!
                        ? S.f('profile_certificate_valid', [formatDate(expiry)])
                        : S.f('profile_certificate_expired', [formatDate(expiry)]),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isValid ? Colors.greenAccent.shade400 : AppColors.signalRed,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(onPressed: onPick, child: Text(S.t('profile_certificate_pick'))),
        ],
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
    return GamePanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 14,
      child: Row(
        children: [
          Icon(icon, color: AppColors.brassLight),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.canvas))),
          Text(value, style: displayStyle(fontSize: 15, color: AppColors.canvas)),
        ],
      ),
    );
  }
}
