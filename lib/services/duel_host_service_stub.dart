import 'dart:async';
import 'duel_protocol.dart';

/// Web-Ersatz: Im Browser können keine Server-Sockets geöffnet werden, daher
/// ist "Duell hosten" dort nicht verfügbar (siehe duel_mode_screen.dart, das
/// den Host-Button auf Web ausblendet, bevor diese Klasse benutzt würde).
class DuelHostService {
  Stream<DuelMessage> get messages => const Stream.empty();
  bool get hasClient => false;

  Future<T> waitFor<T extends DuelMessage>() => Completer<T>().future;

  Future<String?> findLocalIp() async => null;

  Future<int> start({int port = 8123, void Function()? onConnected}) {
    throw UnsupportedError('Duell hosten funktioniert nicht im Browser.');
  }

  void send(DuelMessage message) {}

  Future<void> stop() async {}
}
