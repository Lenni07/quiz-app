import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../audio/sound_settings.dart';
import '../services/auth_service.dart';
import '../l10n/app_language.dart';
import '../l10n/strings.dart';
import '../models/avatar_option.dart';
import '../models/department.dart';
import '../models/personalized_question.dart';
import '../services/career_service.dart';
import '../services/crew_id_service.dart';
import '../services/fleet_war_service.dart';
import '../services/name_service.dart';
import '../services/user_profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/account_status.dart';
import '../widgets/delete_account_dialog.dart';
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
  final _firstNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _realNameController = TextEditingController();
  final _positionController = TextEditingController();
  final _crewIdController = TextEditingController();

  String _avatarId = allAvatarOptions.first.id;
  String? _department;
  int? _germanLevel;
  DateTime? _certificateIssuedAt;
  DateTime? _birthDate;
  String? _grammaticalForm;
  bool _crewIdSet = false;
  bool _editingCrewId = false;
  bool _claimingCrewId = false;
  bool _savingNames = false;
  DateTime? _firstNameChangedAt;
  DateTime? _nicknameChangedAt;
  bool _loaded = false;
  bool _saving = false;
  bool _linking = false;
  bool _deletingAccount = false;

  final _authService = AuthService();
  final _crewIdService = CrewIdService();
  final _nameService = NameService();

  @override
  void dispose() {
    _firstNameController.dispose();
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
      _firstNameController.text = (data?['firstName'] as String?) ?? '';
      _nicknameController.text = (data?['nickname'] as String?) ?? '';
      _realNameController.text = (data?['realName'] as String?) ?? '';
      _positionController.text = (data?['position'] as String?) ?? '';
      _department = data?['department'] as String?;
      _firstNameChangedAt = (data?['firstNameChangedAt'] as Timestamp?)?.toDate();
      _nicknameChangedAt = (data?['nicknameChangedAt'] as Timestamp?)?.toDate();
      _crewIdSet = data?['crewIdHash'] != null;
      _avatarId = (data?['avatarId'] as String?) ?? allAvatarOptions.first.id;
      _germanLevel = (data?['germanLevel'] as num?)?.toInt();
      _certificateIssuedAt = (data?['certificateIssuedAt'] as Timestamp?)?.toDate();
      _birthDate = (data?['birthDate'] as Timestamp?)?.toDate();
      _grammaticalForm = data?['grammaticalForm'] as String?;
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

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 16, now.month, now.day),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _save(String uid) async {
    setState(() => _saving = true);
    try {
      await UserProfileService().updateProfile(
        uid: uid,
        realName: _realNameController.text.trim(),
        position: _positionController.text.trim(),
        department: _department ?? '',
        avatarId: _avatarId,
        germanLevel: _germanLevel,
        certificateIssuedAt: _certificateIssuedAt,
        birthDate: _birthDate,
        grammaticalForm: _grammaticalForm,
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

  /// Vorname + Nickname über die Cloud Function speichern (30-Tage-Sperrfrist
  /// pro Feld, serverseitig - siehe ROADMAP_QuizApp.md Abschnitt 18h Punkt 4).
  Future<void> _saveNames(String uid) async {
    setState(() => _savingNames = true);
    try {
      await _nameService.updateNames(
        firstName: _firstNameController.text.trim(),
        nickname: _nicknameController.text.trim(),
      );
      if (!mounted) return;
      // Frist-Anzeige aus dem frisch gespeicherten Stand aktualisieren.
      final data = await UserProfileService().loadProfile(uid);
      if (!mounted) return;
      setState(() {
        _firstNameChangedAt = (data?['firstNameChangedAt'] as Timestamp?)?.toDate();
        _nicknameChangedAt = (data?['nicknameChangedAt'] as Timestamp?)?.toDate();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t('names_save_success'))));
    } on NameLockedException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.f('names_locked', [e.daysLeft ?? 30])),
      ));
    } on NameInvalidException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t('names_invalid'))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t('profile_save_error'))));
    } finally {
      if (mounted) setState(() => _savingNames = false);
    }
  }

  /// Verknüpft das anonyme Konto mit Google (siehe ROADMAP_QuizApp.md
  /// Abschnitt 18h). Bei Erfolg bleibt die UID gleich, der Fortschritt also
  /// erhalten - danach nur die Anzeige aktualisieren.
  Future<void> _linkGoogle() async {
    setState(() => _linking = true);
    try {
      await _authService.linkGoogleAccount();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t('account_link_success'))),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final inUse = e.code == 'credential-already-in-use' || e.code == 'email-already-in-use';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.t(inUse ? 'account_link_error_in_use' : 'account_link_error_generic')),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t('account_link_error_generic'))),
      );
    } finally {
      if (mounted) setState(() => _linking = false);
    }
  }

  /// Konto + alle Daten löschen (DSGVO, siehe ROADMAP_QuizApp.md Abschnitt
  /// 18i). Verlangt vorher, dass der Nutzer ein Bestätigungswort eintippt -
  /// die Aktion ist unwiderruflich.
  Future<void> _confirmDeleteAccount(String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const DeleteAccountDialog(),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingAccount = true);
    try {
      await _authService.deleteAccount();
      // Frisches anonymes Konto anlegen, damit die App sofort wieder im
      // Startzustand nutzbar ist (kein Neustart nötig).
      final user = await _authService.ensureSignedIn();
      await UserProfileService().ensureProfileExists(user.uid);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t('delete_account_done'))),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _deletingAccount = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t('delete_account_error'))),
      );
    }
  }

  /// Reicht die eingegebene Crew-ID serverseitig ein (siehe
  /// ROADMAP_QuizApp.md Abschnitt 18h/18i). Gespeichert wird nur ein Hash;
  /// ist die ID schon vergeben, lehnt der Server ab.
  Future<void> _claimCrewId() async {
    final value = _crewIdController.text.trim();
    if (value.isEmpty) return;
    setState(() => _claimingCrewId = true);
    try {
      await _crewIdService.claim(value);
      if (!mounted) return;
      setState(() {
        _crewIdSet = true;
        _editingCrewId = false;
        _crewIdController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t('crewid_claim_success'))));
    } on CrewIdTakenException {
      _showCrewIdError('crewid_error_taken');
    } on CrewIdNeedsGoogleException {
      _showCrewIdError('crewid_error_needs_google');
    } on CrewIdInvalidException {
      _showCrewIdError('crewid_error_invalid');
    } catch (_) {
      _showCrewIdError('crewid_error_generic');
    } finally {
      if (mounted) setState(() => _claimingCrewId = false);
    }
  }

  void _showCrewIdError(String key) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t(key))));
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
                    Text(S.t('account_section_title'), style: displayStyle(fontSize: 15, color: AppColors.brassLight)),
                    const SizedBox(height: 8),
                    AccountStatus(
                      isFullAccount: _authService.isFullAccount,
                      email: _authService.linkedEmail,
                      linking: _linking,
                      canLink: kIsWeb,
                      onLink: _linkGoogle,
                    ),
                    const SizedBox(height: 24),
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
                    _NameSection(
                      firstNameController: _firstNameController,
                      nicknameController: _nicknameController,
                      firstNameChangedAt: _firstNameChangedAt,
                      nicknameChangedAt: _nicknameChangedAt,
                      saving: _savingNames,
                      onSave: () => _saveNames(uid),
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
                    _CrewIdField(
                      controller: _crewIdController,
                      alreadySet: _crewIdSet,
                      editing: _editingCrewId,
                      claiming: _claimingCrewId,
                      onStartEdit: () => setState(() => _editingCrewId = true),
                      onSubmit: _claimCrewId,
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
                    const SizedBox(height: 16),
                    Text(S.t('profile_birthdate_title'), style: displayStyle(fontSize: 15, color: AppColors.brassLight)),
                    const SizedBox(height: 8),
                    _BirthDateStatus(
                      birthDate: _birthDate,
                      onPick: _pickBirthDate,
                    ),
                    const SizedBox(height: 16),
                    Text(S.t('profile_grammatical_form_title'), style: displayStyle(fontSize: 15, color: AppColors.brassLight)),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(value: 'male', label: Text(S.t('profile_grammatical_form_male'))),
                        ButtonSegment(value: 'female', label: Text(S.t('profile_grammatical_form_female'))),
                      ],
                      selected: _grammaticalForm == null ? {} : {_grammaticalForm!},
                      emptySelectionAllowed: true,
                      onSelectionChanged: (selection) =>
                          setState(() => _grammaticalForm = selection.isEmpty ? null : selection.first),
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
                    const SizedBox(height: 40),
                    _DangerZone(deleting: _deletingAccount, onDelete: () => _confirmDeleteAccount(uid)),
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

/// Konto-Löschung (DSGVO, ROADMAP_QuizApp.md Abschnitt 18i) - ganz unten im
/// Profil, klar als unwiderruflich markiert.
class _DangerZone extends StatelessWidget {
  final bool deleting;
  final VoidCallback onDelete;

  const _DangerZone({required this.deleting, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      borderRadius: 14,
      borderColor: AppColors.signalRed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(S.t('delete_account_title'), style: displayStyle(fontSize: 15, color: AppColors.signalRed)),
          const SizedBox(height: 6),
          Text(
            S.t('delete_account_explainer'),
            style: TextStyle(fontSize: 12, color: AppColors.canvas.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 12),
          deleting
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(6),
                    child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.signalRed,
                    side: const BorderSide(color: AppColors.signalRed),
                  ),
                  icon: const Icon(Icons.delete_forever_outlined, size: 18),
                  label: Text(S.t('delete_account_button')),
                ),
        ],
      ),
    );
  }
}

/// Crew-ID-Feld (siehe ROADMAP_QuizApp.md Abschnitt 18h/18i): Ist die
/// Crew-ID hinterlegt, wird nur "hinterlegt ✓" angezeigt - die ID selbst
/// liegt nur als Hash auf dem Server, ist also nicht rückholbar. Über
/// "Ändern" lässt sich eine neue eingeben (z. B. bei Tippfehler).
class _CrewIdField extends StatelessWidget {
  final TextEditingController controller;
  final bool alreadySet;
  final bool editing;
  final bool claiming;
  final VoidCallback onStartEdit;
  final VoidCallback onSubmit;

  const _CrewIdField({
    required this.controller,
    required this.alreadySet,
    required this.editing,
    required this.claiming,
    required this.onStartEdit,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    if (alreadySet && !editing) {
      return GamePanel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: 14,
        child: Row(
          children: [
            Icon(Icons.badge_outlined, color: Colors.greenAccent.shade400),
            const SizedBox(width: 12),
            Expanded(
              child: Text(S.t('crewid_set_label'), style: const TextStyle(color: AppColors.canvas)),
            ),
            TextButton(onPressed: onStartEdit, child: Text(S.t('crewid_change'))),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: S.t('profile_crewid_label'),
            helperText: S.t('crewid_helper'),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: claiming
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton.icon(
                  onPressed: onSubmit,
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(S.t('crewid_save')),
                ),
        ),
      ],
    );
  }
}

/// Vorname + Nickname mit 30-Tage-Sperrfrist pro Feld (siehe
/// ROADMAP_QuizApp.md Abschnitt 18h Punkt 4). Muss zur Frist in
/// functions/index.js (NAME_LOCK_MS) passen.
const _nameLockDuration = Duration(days: 30);

class _NameSection extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController nicknameController;
  final DateTime? firstNameChangedAt;
  final DateTime? nicknameChangedAt;
  final bool saving;
  final VoidCallback onSave;

  const _NameSection({
    required this.firstNameController,
    required this.nicknameController,
    required this.firstNameChangedAt,
    required this.nicknameChangedAt,
    required this.saving,
    required this.onSave,
  });

  String? _lockHint(DateTime? changedAt) {
    if (changedAt == null) return null;
    final unlockAt = changedAt.add(_nameLockDuration);
    if (DateTime.now().isAfter(unlockAt)) return null;
    final d = unlockAt;
    final date = '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    return S.f('names_locked_until', [date]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: firstNameController,
          decoration: InputDecoration(
            labelText: S.t('profile_firstname_label'),
            helperText: _lockHint(firstNameChangedAt) ?? S.t('names_change_helper'),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: nicknameController,
          decoration: InputDecoration(
            labelText: S.t('profile_nickname_label'),
            helperText: _lockHint(nicknameChangedAt) ?? S.t('profile_public_helper'),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: saving
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(S.t('names_save')),
                ),
        ),
      ],
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

/// Zeigt das Geburtsdatum und das daraus berechnete Alter (siehe
/// ROADMAP_QuizApp.md Abschnitt 18f) - gespeichert wird bewusst das Datum,
/// nicht eine feste Alterszahl, die sonst nie mehr aktuell wäre.
class _BirthDateStatus extends StatelessWidget {
  final DateTime? birthDate;
  final VoidCallback onPick;

  const _BirthDateStatus({required this.birthDate, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final date = birthDate;
    String formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

    return GamePanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 14,
      child: Row(
        children: [
          Expanded(
            child: Text(
              date == null ? S.t('profile_birthdate_none') : S.f('profile_birthdate_set', [formatDate(date), calculateAge(date)]),
              style: const TextStyle(color: AppColors.canvas),
            ),
          ),
          TextButton(onPressed: onPick, child: Text(S.t('profile_birthdate_pick'))),
        ],
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
