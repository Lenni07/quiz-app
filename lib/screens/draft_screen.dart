import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../l10n/strings.dart';
import '../models/game_format.dart';
import '../services/career_match_service.dart';
import '../services/format_screen_builder.dart';
import '../services/match_round_context.dart';
import '../widgets/maritime_background.dart';
import '../utils/page_transitions.dart';

/// Draft-Phase vor einem 1-vs-1-Match (siehe ROADMAP_QuizApp.md Abschnitt
/// 17): abwechselndes Bannen, danach je eine Formatauswahl pro Spieler,
/// jeweils mit Zeitlimit - bei Ablauf wird automatisch zufällig
/// gebannt/gewählt. Beide Spieler sehen denselben Stand live über
/// Firestore-Listener; alle Züge laufen über die submitDraftAction
/// Cloud Function (siehe career_match_service.dart).
class DraftScreen extends StatefulWidget {
  final String matchId;

  const DraftScreen({super.key, required this.matchId});

  @override
  State<DraftScreen> createState() => _DraftScreenState();
}

class _DraftScreenState extends State<DraftScreen> {
  final _service = CareerMatchService();
  Timer? _ticker;
  int _remainingSeconds = 0;
  int? _autoSubmittedStep;
  bool _navigatedToPlay = false;

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _handleUpdate(Map<String, dynamic> data) {
    final status = data['status'] as String;
    if (status == 'playing') {
      if (!_navigatedToPlay) {
        _navigatedToPlay = true;
        _ticker?.cancel();
        _startFirstRound(data);
      }
      return;
    }
    if (status != 'drafting') return;

    final turnUid = data['turnUid'] as String?;
    final deadline = (data['turnDeadline'] as num?)?.toInt();
    final draftStep = (data['draftStep'] as num?)?.toInt() ?? 0;

    _ticker?.cancel();
    if (turnUid == null || deadline == null) return;

    void tick() {
      if (!mounted) return;
      final remainingMs = deadline - DateTime.now().millisecondsSinceEpoch;
      final remaining = (remainingMs / 1000).ceil();
      setState(() => _remainingSeconds = remaining < 0 ? 0 : remaining);
      if (remaining <= 0 && turnUid == _myUid && _autoSubmittedStep != draftStep) {
        _autoSubmittedStep = draftStep;
        _autoSubmit(data);
      }
    }

    tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void _autoSubmit(Map<String, dynamic> data) {
    final pool = List<String>.from(data['pool'] as List);
    final banned = List<String>.from(data['banned'] as List);
    final picks = List<String>.from((data['picks'] as Map).values);
    final available = pool.where((f) => !banned.contains(f) && !picks.contains(f)).toList()..shuffle();
    if (available.isEmpty) return;
    _service.submitDraftAction(matchId: widget.matchId, formatId: available.first);
  }

  void _selectFormat(String formatId) {
    _service.submitDraftAction(matchId: widget.matchId, formatId: formatId);
  }

  Future<void> _startFirstRound(Map<String, dynamic> data) async {
    final formats = List<String>.from(data['formats'] as List);
    MatchRoundContext.set(widget.matchId, 0);
    final screen = await buildFormatScreen(formats[0]);
    if (!mounted) return;
    Navigator.pushReplacement(context, buildFadeSlideRoute(screen));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, language, _) => Scaffold(
      appBar: AppBar(title: Text(S.t('draft_title')), automaticallyImplyLeading: false),
      body: MaritimeBackground(child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _service.watchMatch(widget.matchId),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          if (data == null || data['status'] == 'playing') {
            return const Center(child: CircularProgressIndicator());
          }
          _handleUpdate(data);

          final pool = List<String>.from(data['pool'] as List);
          final banned = List<String>.from(data['banned'] as List);
          final picks = Map<String, dynamic>.from(data['picks'] as Map);
          final pickedFormats = picks.values.map((v) => v as String).toSet();
          final turnUid = data['turnUid'] as String?;
          final myTurn = turnUid == _myUid;
          final draftStep = (data['draftStep'] as num?)?.toInt() ?? 0;
          final isBanStep = draftStep < bansPerPlayer * 2;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  myTurn
                      ? S.t(isBanStep ? 'draft_your_turn_ban' : 'draft_your_turn_pick')
                      : S.t(isBanStep ? 'draft_opponent_ban' : 'draft_opponent_pick'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_remainingSeconds s',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: _remainingSeconds <= 5 ? Colors.red : colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.6,
                    ),
                    itemCount: pool.length,
                    itemBuilder: (context, index) {
                      final formatId = pool[index];
                      final format = gameFormatById(formatId);
                      final isBanned = banned.contains(formatId);
                      final isPicked = pickedFormats.contains(formatId);
                      final unavailable = isBanned || isPicked;

                      return Material(
                        color: isBanned
                            ? colorScheme.errorContainer.withValues(alpha: 0.5)
                            : isPicked
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: myTurn && !unavailable ? () => _selectFormat(formatId) : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Row(
                              children: [
                                Icon(format.icon, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    format.displayName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      decoration: isBanned ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      )),
      ),
    );
  }
}
