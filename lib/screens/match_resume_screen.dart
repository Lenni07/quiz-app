import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../l10n/app_language.dart';
import '../l10n/strings.dart';
import '../services/career_match_service.dart';
import '../services/format_screen_builder.dart';
import '../services/match_round_context.dart';
import '../utils/current_uid.dart';
import '../utils/page_transitions.dart';
import '../widgets/maritime_background.dart';
import 'draft_screen.dart';
import 'match_result_screen.dart';

/// Wiedereinstieg in ein laufendes 1-vs-1-Match nach einem
/// Verbindungsabriss (siehe ROADMAP_QuizApp.md Abschnitt 17). Führt je nach
/// Match-Stand zurück in die Draft-Phase, in die nächste offene Runde oder -
/// wenn die eigene Runde schon eingereicht ist - in die Warteansicht, die
/// bei abgelaufener Frist den Server um die Auswertung bittet.
class MatchResumeScreen extends StatefulWidget {
  final String matchId;
  final CareerMatchService? service;

  const MatchResumeScreen({super.key, required this.matchId, this.service});

  @override
  State<MatchResumeScreen> createState() => _MatchResumeScreenState();
}

class _MatchResumeScreenState extends State<MatchResumeScreen> {
  late final CareerMatchService _service = widget.service ?? CareerMatchService();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  Timer? _timeoutTicker;
  Map<String, dynamic>? _match;
  bool _navigated = false;
  DateTime? _lastTimeoutCall;

  String get _myUid => currentUid() ?? '';

  @override
  void initState() {
    super.initState();
    _sub = _service.watchMatch(widget.matchId).listen((snapshot) {
      final data = snapshot.data();
      if (data == null) return;
      if (mounted) setState(() => _match = data);
      _route(data);
    });
    _timeoutTicker = Timer.periodic(const Duration(seconds: 5), (_) => _checkRoundTimeout());
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timeoutTicker?.cancel();
    super.dispose();
  }

  void _route(Map<String, dynamic> match) {
    if (_navigated || !mounted) return;
    final status = match['status'] as String?;

    if (status == 'drafting') {
      _replace(DraftScreen(matchId: widget.matchId));
      return;
    }
    if (status == 'finished') {
      _replace(MatchResultScreen(matchId: widget.matchId));
      return;
    }
    if (status != 'playing') return; // aborted -> Ansicht unten

    final currentRound = match['currentRound'] as int? ?? 0;
    final roundScores = (match['roundScores'] as Map?)?.cast<String, dynamic>() ?? {};
    final thisRound = (roundScores['$currentRound'] as Map?)?.cast<String, dynamic>() ?? {};
    final iSubmitted = thisRound[_myUid] != null;
    if (iSubmitted) return; // Warteansicht unten übernimmt

    final formats = List<String>.from(match['formats'] as List? ?? const []);
    if (currentRound >= formats.length) return;
    _navigated = true;
    MatchRoundContext.set(widget.matchId, currentRound);
    () async {
      final screen = await buildFormatScreen(formats[currentRound]);
      if (mounted) Navigator.pushReplacement(context, buildFadeSlideRoute(screen));
    }();
  }

  void _replace(Widget screen) {
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pushReplacement(context, buildFadeSlideRoute(screen));
    });
  }

  void _checkRoundTimeout() {
    final match = _match;
    if (match == null || match['status'] != 'playing') return;
    final deadline = (match['roundDeadline'] as num?)?.toInt();
    if (deadline == null) return;
    if (DateTime.now().millisecondsSinceEpoch < deadline + 15000) return;
    final now = DateTime.now();
    if (_lastTimeoutCall != null && now.difference(_lastTimeoutCall!) < const Duration(seconds: 10)) {
      return;
    }
    _lastTimeoutCall = now;
    _service.claimRoundTimeout(widget.matchId).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final aborted = _match?['status'] == 'aborted';
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, language, _) => Scaffold(
        appBar: AppBar(title: Text(S.t('tab_1v1')), automaticallyImplyLeading: false),
        body: MaritimeBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: aborted
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(S.t('match_aborted_body'), textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(S.t('match_back_to_start')),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(S.t('round_waiting'), textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        Text(
                          S.t('round_waiting_timeout_hint'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
