import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../l10n/strings.dart';
import '../services/career_match_service.dart';
import '../utils/page_transitions.dart';
import '../widgets/maritime_background.dart';
import 'draft_screen.dart';

class OneVsOneQueueScreen extends StatefulWidget {
  const OneVsOneQueueScreen({super.key});

  @override
  State<OneVsOneQueueScreen> createState() => _OneVsOneQueueScreenState();
}

class _OneVsOneQueueScreenState extends State<OneVsOneQueueScreen> {
  final _service = CareerMatchService();
  bool _matched = false;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) _service.joinQueue(uid);
  }

  @override
  void dispose() {
    if (!_matched) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) _service.cancelQueue(uid);
    }
    super.dispose();
  }

  void _onQueueUpdate(Map<String, dynamic>? data) {
    if (_matched || data == null) return;
    if (data['status'] == 'matched' && data['matchId'] != null) {
      _matched = true;
      Navigator.pushReplacement(
        context,
        buildFadeSlideRoute(DraftScreen(matchId: data['matchId'] as String)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, language, _) => Scaffold(
      appBar: AppBar(title: Text(S.t('tab_1v1'))),
      body: MaritimeBackground(child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: uid == null
              ? Text(
                  S.t('queue_no_account'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.error),
                )
              : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _service.watchQueue(uid),
                  builder: (context, snapshot) {
                    _onQueueUpdate(snapshot.data?.data());
                    return Column(
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
                    );
                  },
                ),
        ),
      )),
      ),
    );
  }
}
