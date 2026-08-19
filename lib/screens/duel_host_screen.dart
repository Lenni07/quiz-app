import 'dart:math';
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/duel_host_service.dart';
import '../services/duel_protocol.dart';
import '../utils/page_transitions.dart';
import 'duel_play_screen.dart';
import 'duel_result_screen.dart';

class DuelHostScreen extends StatefulWidget {
  final List<Question> questionPool;
  final int questionCount;

  const DuelHostScreen({super.key, required this.questionPool, this.questionCount = 8});

  @override
  State<DuelHostScreen> createState() => _DuelHostScreenState();
}

enum _Stage { starting, waitingForPlayer, playing, waitingForOpponentScore, error }

class _DuelHostScreenState extends State<DuelHostScreen> {
  final _hostService = DuelHostService();
  _Stage _stage = _Stage.starting;
  String? _localIp;
  int? _port;
  String? _errorMessage;
  late final List<Question> _questions;

  @override
  void initState() {
    super.initState();
    final shuffled = List<Question>.from(widget.questionPool)..shuffle(Random());
    _questions = shuffled.take(min(widget.questionCount, shuffled.length)).toList();
    _startHosting();
  }

  @override
  void dispose() {
    _hostService.stop();
    super.dispose();
  }

  Future<void> _startHosting() async {
    try {
      final ip = await _hostService.findLocalIp();
      final port = await _hostService.start(onConnected: _onPlayerConnected);
      if (!mounted) return;
      setState(() {
        _localIp = ip;
        _port = port;
        _stage = _Stage.waitingForPlayer;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.error;
        _errorMessage = '$e';
      });
    }
  }

  void _onPlayerConnected() {
    if (!mounted) return;
    _hostService.send(QuestionsMessage(_questions));
    setState(() => _stage = _Stage.playing);
    _playAndExchangeScore();
  }

  Future<void> _playAndExchangeScore() async {
    final myScore = await Navigator.push<int>(
      context,
      buildFadeSlideRoute(DuelPlayScreen(questions: _questions)),
    );
    if (myScore == null || !mounted) return;

    _hostService.send(ScoreMessage(myScore, _questions.length));
    setState(() => _stage = _Stage.waitingForOpponentScore);

    final opponentMessage = await _hostService.messages.firstWhere((m) => m is ScoreMessage);
    final opponentScore = (opponentMessage as ScoreMessage).score;
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      buildFadeSlideRoute(
        DuelResultScreen(myScore: myScore, opponentScore: opponentScore, total: _questions.length),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Duell hosten')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              switch (_stage) {
                _Stage.starting => const CircularProgressIndicator(),
                _Stage.waitingForPlayer => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      const Text(
                        'Warte auf Mitspieler ...',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Sag deinem Mitspieler, dass er im selben WLAN beitreten soll mit:',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_localIp ?? 'IP unbekannt'} : ${_port ?? '-'}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                _Stage.playing => const CircularProgressIndicator(),
                _Stage.waitingForOpponentScore => const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 24),
                      Text(
                        'Warte auf Ergebnis des Mitspielers ...',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                _Stage.error => Text(
                    'Duell konnte nicht gestartet werden:\n${_errorMessage ?? ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
              },
            ],
          ),
        ),
      ),
    );
  }
}
