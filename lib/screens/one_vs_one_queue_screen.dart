import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../l10n/strings.dart';
import '../services/career_match_service.dart';
import '../utils/current_uid.dart';
import '../utils/page_transitions.dart';
import '../widgets/maritime_background.dart';
import 'draft_screen.dart';

/// Warteschlange fürs 1-vs-1 (siehe ROADMAP_QuizApp.md Abschnitt 16/17).
///
/// Der Warteschlangen-Listener wird in [initState] abonniert, nicht über
/// einen `StreamBuilder` im `build()` - so wird die Navigation zum
/// Draft-Screen genau einmal ausgelöst und nie aus einem laufenden
/// `build()` heraus (gleiche Fehlerklasse wie der frühere Draft-Freeze,
/// siehe draft_screen.dart).
class OneVsOneQueueScreen extends StatefulWidget {
  /// Nur für Tests injizierbar.
  final CareerMatchService? service;

  const OneVsOneQueueScreen({super.key, this.service});

  @override
  State<OneVsOneQueueScreen> createState() => _OneVsOneQueueScreenState();
}

class _OneVsOneQueueScreenState extends State<OneVsOneQueueScreen> {
  late final CareerMatchService _service = widget.service ?? CareerMatchService();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _queueSub;
  bool _matched = false;
  String? _uid;

  @override
  void initState() {
    super.initState();
    final uid = currentUid();
    _uid = uid;
    if (uid != null) {
      _service.joinQueue(uid);
      _queueSub = _service.watchQueue(uid).listen(_onQueueUpdate);
    }
  }

  @override
  void dispose() {
    _queueSub?.cancel();
    if (!_matched) {
      final uid = _uid;
      if (uid != null) _service.cancelQueue(uid);
    }
    super.dispose();
  }

  void _onQueueUpdate(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    if (_matched || !mounted) return;
    final data = snapshot.data();
    if (data == null) return;
    if (data['status'] == 'matched' && data['matchId'] != null) {
      _matched = true;
      _queueSub?.cancel();
      Navigator.pushReplacement(
        context,
        buildFadeSlideRoute(DraftScreen(matchId: data['matchId'] as String)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, language, _) => Scaffold(
        appBar: AppBar(title: Text(S.t('tab_1v1'))),
        body: MaritimeBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: _uid == null
                  ? Text(
                      S.t('queue_no_account'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.error),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 24),
                        Text(
                          S.t('queue_searching'),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          S.t('queue_hint'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                        ),
                        const SizedBox(height: 32),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(S.t('queue_cancel')),
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
