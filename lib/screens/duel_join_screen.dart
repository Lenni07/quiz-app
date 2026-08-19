import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/duel_client_service.dart';
import '../services/duel_protocol.dart';
import '../utils/page_transitions.dart';
import 'duel_play_screen.dart';
import 'duel_result_screen.dart';

class DuelJoinScreen extends StatefulWidget {
  const DuelJoinScreen({super.key});

  @override
  State<DuelJoinScreen> createState() => _DuelJoinScreenState();
}

enum _Stage { enterAddress, connecting, waitingForQuestions, playing, waitingForOpponentScore, error }

class _DuelJoinScreenState extends State<DuelJoinScreen> {
  final _clientService = DuelClientService();
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '8123');
  _Stage _stage = _Stage.enterAddress;
  String? _errorMessage;
  List<Question>? _questions;

  @override
  void dispose() {
    _clientService.disconnect();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final host = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim());
    if (host.isEmpty || port == null) {
      setState(() {
        _stage = _Stage.error;
        _errorMessage = 'Bitte IP-Adresse und Port eingeben.';
      });
      return;
    }

    setState(() => _stage = _Stage.connecting);
    try {
      await _clientService.connect(host, port);
      setState(() => _stage = _Stage.waitingForQuestions);

      final questionsMessage = await _clientService.messages.firstWhere((m) => m is QuestionsMessage);
      _questions = (questionsMessage as QuestionsMessage).questions;
      if (!mounted) return;
      setState(() => _stage = _Stage.playing);
      await _playAndExchangeScore();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.error;
        _errorMessage = '$e';
      });
    }
  }

  Future<void> _playAndExchangeScore() async {
    final myScore = await Navigator.push<int>(
      context,
      buildFadeSlideRoute(DuelPlayScreen(questions: _questions!)),
    );
    if (myScore == null || !mounted) return;

    _clientService.send(ScoreMessage(myScore, _questions!.length));
    setState(() => _stage = _Stage.waitingForOpponentScore);

    final opponentMessage = await _clientService.messages.firstWhere((m) => m is ScoreMessage);
    final opponentScore = (opponentMessage as ScoreMessage).score;
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      buildFadeSlideRoute(
        DuelResultScreen(myScore: myScore, opponentScore: opponentScore, total: _questions!.length),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Duell beitreten')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              switch (_stage) {
                _Stage.enterAddress => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'IP-Adresse und Port vom Gastgeber eingeben (im selben WLAN):',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _ipController,
                        decoration: const InputDecoration(labelText: 'IP-Adresse', hintText: 'z. B. 192.168.1.42'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _portController,
                        decoration: const InputDecoration(labelText: 'Port'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(onPressed: _connect, child: const Text('Verbinden')),
                    ],
                  ),
                _Stage.connecting => const _LoadingText('Verbinde ...'),
                _Stage.waitingForQuestions => const _LoadingText('Warte auf Fragen vom Gastgeber ...'),
                _Stage.playing => const CircularProgressIndicator(),
                _Stage.waitingForOpponentScore => const _LoadingText('Warte auf Ergebnis des Gastgebers ...'),
                _Stage.error => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _errorMessage ?? 'Verbindung fehlgeschlagen.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => setState(() => _stage = _Stage.enterAddress),
                        child: const Text('Erneut versuchen'),
                      ),
                    ],
                  ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingText extends StatelessWidget {
  final String text;

  const _LoadingText(this.text);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
