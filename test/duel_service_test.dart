// Prüft den echten Netzwerk-Code des lokalen Duells (Host- und Client-
// Dienst, siehe lib/services/duel_*.dart) end-to-end über einen echten
// WebSocket auf localhost - ganz ohne zwei physische Geräte.
import 'package:flutter_test/flutter_test.dart';
import 'package:rank_up/models/question.dart';
import 'package:rank_up/services/duel_client_service.dart';
import 'package:rank_up/services/duel_host_service.dart';
import 'package:rank_up/services/duel_protocol.dart';

void main() {
  test('Host schickt Fragen, beide Seiten tauschen am Ende ihr Ergebnis aus', () async {
    final host = DuelHostService();
    final client = DuelClientService();
    addTearDown(() async {
      await host.stop();
      await client.disconnect();
    });

    final port = await host.start(port: 0);

    final testQuestions = [
      Question(question: 'Testfrage 1', options: ['A', 'B', 'C', 'D'], correctIndex: 0),
      Question(question: 'Testfrage 2', options: ['A', 'B', 'C', 'D'], correctIndex: 1),
    ];

    await client.connect('localhost', port);
    // Kurz warten, bis der Server die Verbindung tatsächlich registriert hat.
    await Future.delayed(const Duration(milliseconds: 200));
    expect(host.hasClient, isTrue);

    host.send(QuestionsMessage(testQuestions));
    final received = await client.waitFor<QuestionsMessage>();

    expect(received.questions.length, 2);
    expect(received.questions[0].question, 'Testfrage 1');
    expect(received.questions[1].correctIndex, 1);

    client.send(ScoreMessage(1, 2));
    final hostReceivedScore = await host.waitFor<ScoreMessage>();
    expect(hostReceivedScore.score, 1);
    expect(hostReceivedScore.total, 2);

    host.send(ScoreMessage(2, 2));
    final clientReceivedScore = await client.waitFor<ScoreMessage>();
    expect(clientReceivedScore.score, 2);
  });

  test('Ergebnis, das schon ankam bevor jemand darauf wartet, geht nicht verloren', () async {
    // Regressionstest für den Bug vom 2026-08-24: Auf einem echten Gerät
    // spielt jede Seite die 8 Fragen unterschiedlich schnell durch. Kommt
    // das Ergebnis der Gegenseite an, *bevor* die eigene Seite überhaupt
    // fertig gespielt hat (also bevor waitFor aufgerufen wird), durfte es
    // vorher nicht verloren gehen - genau das ist auf dem Handy passiert
    // und beide Seiten blieben für immer bei "Warte auf Ergebnis" hängen.
    final host = DuelHostService();
    final client = DuelClientService();
    addTearDown(() async {
      await host.stop();
      await client.disconnect();
    });

    final port = await host.start(port: 0);
    await client.connect('localhost', port);
    await Future.delayed(const Duration(milliseconds: 200));

    // Client "spielt schneller" und schickt sein Ergebnis sofort.
    client.send(ScoreMessage(3, 8));
    // Host lässt sich Zeit (simuliert: noch mitten im eigenen Fragenspiel),
    // bevor er überhaupt anfängt, auf das Ergebnis zu warten.
    await Future.delayed(const Duration(milliseconds: 300));

    final hostReceivedScore = await host.waitFor<ScoreMessage>();
    expect(hostReceivedScore.score, 3);
    expect(hostReceivedScore.total, 8);
  });
}
