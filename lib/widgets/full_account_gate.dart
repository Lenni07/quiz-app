import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/current_uid.dart';
import 'empty_state.dart';
import 'game_button.dart';
import 'game_panel.dart';

/// Zustand der Konto-Sperre für die wettbewerbsrelevanten Bereiche (siehe
/// ROADMAP_QuizApp.md Abschnitt 18h, "Gestufter Zugang").
enum GateState {
  /// Konto lässt sich gerade nicht prüfen (offline / Firebase nicht erreichbar).
  noConnection,

  /// Noch kein Google-Konto verknüpft (Konto ist anonym).
  needsGoogle,

  /// Google ist da, aber noch keine Crew-ID hinterlegt.
  needsCrewId,

  /// Vollwertiges Konto - Zugang frei.
  open,
}

/// Reine Entscheidungslogik der Sperre (ohne Firebase/Widgets, damit
/// testbar). [crewIdSet] wird erst ausgewertet, wenn Konto + Google stimmen.
GateState gateStateFor({
  required String? uid,
  required bool isFullAccount,
  required bool crewIdLoaded,
  required bool crewIdSet,
  bool firestoreError = false,
}) {
  if (uid == null || firestoreError) return GateState.noConnection;
  if (!isFullAccount) return GateState.needsGoogle;
  if (!crewIdLoaded) return GateState.open; // Ladeanzeige übernimmt das Widget
  return crewIdSet ? GateState.open : GateState.needsCrewId;
}

/// Sperrt wettbewerbsrelevante Bereiche (1 vs 1, Flottentreffen, Rangliste)
/// für Konten, die noch nicht vollwertig sind: Google-Anmeldung UND eine
/// eindeutige Crew-ID. Der Lernmodus bleibt bewusst ohne Anmeldung nutzbar
/// und wird NICHT mit diesem Gate umschlossen.
class FullAccountGate extends StatelessWidget {
  final Widget child;

  /// Führt den Nutzer zum Profil-Reiter, wo er sich anmelden / die Crew-ID
  /// hinterlegen kann.
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
    final isFull = _authService.isFullAccount;

    if (uid == null) return _LockScreen(state: GateState.noConnection, onGoToProfile: onGoToProfile);
    if (!isFull) return _LockScreen(state: GateState.needsGoogle, onGoToProfile: onGoToProfile);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _LockScreen(state: GateState.noConnection, onGoToProfile: onGoToProfile);
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final state = gateStateFor(
          uid: uid,
          isFullAccount: isFull,
          crewIdLoaded: true,
          crewIdSet: snapshot.data!.data()?['crewIdHash'] != null,
        );
        return state == GateState.open
            ? child
            : _LockScreen(state: state, onGoToProfile: onGoToProfile);
      },
    );
  }
}

class _LockScreen extends StatelessWidget {
  final GateState state;
  final VoidCallback onGoToProfile;

  const _LockScreen({required this.state, required this.onGoToProfile});

  @override
  Widget build(BuildContext context) {
    if (state == GateState.noConnection) {
      return EmptyState(icon: Icons.wifi_off, message: S.t('gate_no_connection'));
    }

    final message = state == GateState.needsGoogle ? S.t('gate_needs_google') : S.t('gate_needs_crewid');

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
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.canvas.withValues(alpha: 0.85), fontSize: 13),
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
