import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../l10n/strings.dart';
import '../services/career_match_service.dart';
import '../services/daily_challenge_service.dart';
import '../services/fleet_war_service.dart';
import '../services/format_screen_builder.dart';
import '../services/match_round_context.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import '../widgets/firework_particle.dart';
import '../widgets/game_button.dart';
import 'match_result_screen.dart';

class ResultScreen extends StatefulWidget {
  final int score;
  final int total;
  final String formatId;
  final VoidCallback onPlayAgain;

  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.formatId,
    required this.onPlayAgain,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final List<ConfettiController> _fireworkControllers;
  late final List<Alignment> _fireworkPositions;

  String? _matchId;
  int? _roundIndex;
  bool get _inMatch => _matchId != null;

  bool get _isGoodResult => widget.score > widget.total / 2;

  @override
  void initState() {
    super.initState();
    _fireworkPositions = const [
      Alignment(-0.5, -0.4),
      Alignment(0.4, -0.6),
      Alignment(-0.2, -0.2),
    ];
    _fireworkControllers = List.generate(
      _fireworkPositions.length,
      (_) => ConfettiController(duration: const Duration(milliseconds: 700)),
    );
    if (_isGoodResult) {
      _launchFireworks();
    }
    _submitToFleetWar();
    _recordDailyChallenge();

    final matchContext = MatchRoundContext.consume();
    if (matchContext != null) {
      _matchId = matchContext.matchId;
      _roundIndex = matchContext.roundIndex;
      _submitMatchRound();
    }
  }

  void _submitToFleetWar() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    FleetWarService().submitScore(uid: user.uid, score: widget.score, total: widget.total);
  }

  Future<void> _recordDailyChallenge() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final streak = await DailyChallengeService().recordCompletion(user.uid);
    if (streak == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.f('daily_challenge_streak', [streak]))),
    );
  }

  Future<void> _submitMatchRound() async {
    try {
      await CareerMatchService().submitRoundResult(
        matchId: _matchId!,
        roundIndex: _roundIndex!,
        score: widget.score,
        total: widget.total,
      );
    } catch (_) {
      // Netzwerkfehler: Nutzer bleibt beim Warte-Zustand, App friert aber
      // nicht ein - lässt sich normal weiter benutzen.
    }
  }

  void _launchFireworks() async {
    for (var i = 0; i < _fireworkControllers.length; i++) {
      if (!mounted) return;
      _fireworkControllers[i].play();
      await Future.delayed(const Duration(milliseconds: 350));
    }
  }

  @override
  void dispose() {
    for (final controller in _fireworkControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _continueAfterRound(String status, Map<String, dynamic> matchData) async {
    if (status == 'finished') {
      Navigator.pushReplacement(context, buildFadeSlideRoute(MatchResultScreen(matchId: _matchId!)));
      return;
    }
    final formats = List<String>.from(matchData['formats'] as List);
    final nextRound = matchData['currentRound'] as int;
    MatchRoundContext.set(_matchId!, nextRound);
    final screen = await buildFormatScreen(formats[nextRound]);
    if (!mounted) return;
    Navigator.pushReplacement(context, buildFadeSlideRoute(screen));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, language, _) {
        if (_inMatch) return _buildMatchRoundView(context);
        return _buildSoloView(context);
      },
    );
  }

  Widget _buildMatchRoundView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: CareerMatchService().watchMatch(_matchId!),
            builder: (context, snapshot) {
              final data = snapshot.data?.data();
              if (data == null) {
                return const CircularProgressIndicator();
              }
              final status = data['status'] as String;
              final currentRound = data['currentRound'] as int? ?? _roundIndex!;
              final roundResolved = status == 'finished' || currentRound > _roundIndex!;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    S.f('round_label', [_roundIndex! + 1, widget.score, widget.total]),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 32),
                  if (!roundResolved) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      S.t('round_waiting'),
                      style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    ),
                  ] else ...[
                    _buildRoundOutcomeText(data),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _continueAfterRound(status, data),
                      child: Text(S.t(status == 'finished' ? 'round_view_result' : 'round_next')),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRoundOutcomeText(Map<String, dynamic> data) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final roundWinners = List<dynamic>.from(data['roundWinners'] as List);
    final winner = roundWinners[_roundIndex!];
    final String text;
    final Color color;
    if (winner == null) {
      text = S.t('round_draw');
      color = Colors.grey;
    } else if (winner == myUid) {
      text = S.t('round_win');
      color = Colors.green;
    } else {
      text = S.t('round_loss');
      color = Colors.red;
    }
    return Text(text, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color));
  }

  Widget _buildSoloView(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                    child: Icon(
                      _isGoodResult ? Icons.emoji_events : Icons.school,
                      size: 90,
                      color: _isGoodResult ? Colors.amber[700] : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    S.t('result_title'),
                    style: displayStyle(fontSize: 32, color: AppColors.canvas),
                  ),
                  const SizedBox(height: 20),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: widget.score),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => Text(
                      S.f('result_score_label', [value, widget.total]),
                      textAlign: TextAlign.center,
                      style: displayStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.brassLight),
                    ),
                  ),
                  const SizedBox(height: 48),
                  GameButton(
                    label: S.t('result_play_again'),
                    icon: Icons.replay,
                    onPressed: widget.onPlayAgain,
                  ),
                ],
              ),
            ),
          ),
          for (var i = 0; i < _fireworkPositions.length; i++)
            Align(
              alignment: _fireworkPositions[i],
              child: ConfettiWidget(
                confettiController: _fireworkControllers[i],
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 30,
                maxBlastForce: 28,
                minBlastForce: 12,
                gravity: 0.15,
                minimumSize: const Size(5, 5),
                maximumSize: const Size(11, 11),
                colors: fireworkColors,
                createParticlePath: drawFireworkSpark,
                shouldLoop: false,
              ),
            ),
        ],
      ),
    );
  }
}
