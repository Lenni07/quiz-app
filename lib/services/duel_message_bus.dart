import 'dart:async';
import 'duel_protocol.dart';

/// Sammelt eingehende Duell-Nachrichten und merkt sie sich, damit auch eine
/// Nachricht noch abgeholt werden kann, die schon ankam, bevor überhaupt
/// jemand darauf gewartet hat (z. B. das Gegner-Ergebnis, das eintrifft,
/// während die eigene Seite noch ihre Fragen beantwortet).
class DuelMessageBus {
  final _controller = StreamController<DuelMessage>.broadcast();
  final List<DuelMessage> _received = [];

  Stream<DuelMessage> get stream => _controller.stream;

  void add(DuelMessage message) {
    _received.add(message);
    _controller.add(message);
  }

  Future<T> waitFor<T extends DuelMessage>() {
    for (final message in _received) {
      if (message is T) return Future.value(message);
    }
    return stream.firstWhere((m) => m is T).then((m) => m as T);
  }

  Future<void> close() => _controller.close();
}
