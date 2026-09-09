import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/current_uid.dart';
import 'empty_state.dart';
import 'game_button.dart';
import 'game_panel.dart';
import 'unlock_steps.dart';

/// Die Voraussetzungen für die wettbewerbsrelevanten Bereiche (1 vs 1,
/// Flottentreffen, Rangliste) - siehe ROADMAP_QuizApp.md Abschnitt 18h,
/// "Gestufter Zugang". Verlangt werden Google-Anmeldung, eine eindeutige
/// Crew-ID sowie Nickname UND Position: beide erscheinen in der Rangliste,
/// ohne sie entstünden dort leere Einträge.
class CompetitiveAccess {
  /// false = Konto/Profil lässt sich gerade nicht prüfen (offline).
  final bool connected;
  final bool google;
  final bool crewId;
  final bool nickname;
  final bool position;

  const CompetitiveAccess({
    required this.connected,
    required this.google,
    required this.crewId,
    required this.nickname,
    required this.position,
  });

  static const offline = CompetitiveAccess(
    connected: false,
    google: false,
    crewId: false,
    nickname: false,
    position: false,
  );

  bool get open => connected && google && crewId && nickname && position;
}

/// Reine Entscheidungslogik der Sperre (ohne Firebase/Widgets, damit
/// testbar). [profileLoaded] false = Profil noch nicht geladen; dann gilt der
/// Zugang vorläufig als offen und die Ladeanzeige übernimmt das Widget.
CompetitiveAccess competitiveAccessFor({
  required String? uid,
  required bool isFullAccount,
  required bool profileLoaded,
  bool crewIdSet = false,
  String? nickname,
  String? position,
  bool firestoreError = false,
}) {
  if (uid == null || firestoreError) return CompetitiveAccess.offline;
  if (!profileLoaded) {
    return const CompetitiveAccess(
      connected: true,
      google: true,
      crewId: true,
      nickname: true,
      position: true,
    );
  }
  return CompetitiveAccess(
    connected: true,
    google: isFullAccount,
    crewId: crewIdSet,
    nickname: (nickname ?? '').trim().isNotEmpty,
    position: (position ?? '').trim().isNotEmpty,
  );
}

/// Sperrt wettbewerbsrelevante Bereiche (1 vs 1, Flottentreffen, Rangliste)
/// für Konten, die das Wettkampf-Profil noch nicht vollständig haben. Der
/// Lernmodus bleibt bewusst ohne Anmeldung nutzbar und wird NICHT mit diesem
/// Gate umschlossen.
class FullAccountGate extends StatelessWidget {
  final Widget child;

  /// Führt den Nutzer zum Profil-Reiter, wo er sich anmelden / die fehlenden
  /// Angaben nachtragen kann.
  final VoidCallback onGoToProfile;

  final AuthService _authService;

  FullAccountGate({
    super.key,
    required this.child,
    required this.onGoToProfile,
    AuthService? authService,
  }) : _authService = authService ?? AuthService();

  @override
  Widget build(BuildContext context) {
    final uid = currentUid();
    if (uid == null) {
      return _LockScreen(access: CompetitiveAccess.offline, onGoToProfile: onGoToProfile);
    }

    final isFull = _authService.isFullAccount;
    if (!isFull) {
      // Ohne Google zählt der Rest ohnehin nicht - den billigen Weg ohne
      // Firestore-Lesezugriff nehmen und nur "mit Google anmelden" als
      // offenen Schritt zeigen. Sobald Google steht, liefert der
      // StreamBuilder unten die genaue Restliste.
      return _LockScreen(
        access: const CompetitiveAccess(
          connected: true,
          google: false,
          crewId: false,
          nickname: false,
          position: false,
        ),
        onGoToProfile: onGoToProfile,
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _LockScreen(access: CompetitiveAccess.offline, onGoToProfile: onGoToProfile);
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!.data();
        final access = competitiveAccessFor(
          uid: uid,
          isFullAccount: isFull,
          profileLoaded: true,
          crewIdSet: data?['crewIdHash'] != null,
          nickname: data?['nickname'] as String?,
          position: data?['position'] as String?,
        );
        return access.open
            ? child
            : _LockScreen(access: access, onGoToProfile: onGoToProfile);
      },
    );
  }
}

class _LockScreen extends StatelessWidget {
  final CompetitiveAccess access;
  final VoidCallback onGoToProfile;

  const _LockScreen({required this.access, required this.onGoToProfile});

  @override
  Widget build(BuildContext context) {
    if (!access.connected) {
      return EmptyState(icon: Icons.wifi_off, message: S.t('gate_no_connection'));
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: GamePanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: AppColors.brassLight),
              const SizedBox(height: 12),
              Text(
                S.t('gate_title'),
                textAlign: TextAlign.center,
                style: displayStyle(fontSize: 20, color: AppColors.canvas),
              ),
              const SizedBox(height: 10),
              Text(
                S.t('gate_locked_intro'),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.canvas.withValues(alpha: 0.85), fontSize: 13),
              ),
              const SizedBox(height: 16),
              UnlockSteps(
                google: access.google,
                crewId: access.crewId,
                nickname: access.nickname,
                position: access.position,
                compact: true,
              ),
              const SizedBox(height: 18),
              GameButton(
                label: S.t('gate_go_to_profile'),
                icon: Icons.person_outline,
                fontSize: 15,
                onPressed: onGoToProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
