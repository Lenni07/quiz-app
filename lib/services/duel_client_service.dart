import 'package:web_socket_channel/web_socket_channel.dart';
import 'duel_message_bus.dart';
import 'duel_protocol.dart';

/// Verbindet sich als zweiter Spieler mit einem lokal gehosteten Duell.
/// Läuft auf allen Plattformen inkl. Web.
class DuelClientService {
  WebSocketChannel? _channel;
  final _bus = DuelMessageBus();

  Stream<DuelMessage> get messages => _bus.stream;

  Future<T> waitFor<T extends DuelMessage>() => _bus.waitFor<T>();

  Future<void> connect(String host, int port) async {
    final channel = WebSocketChannel.connect(Uri.parse('ws://$host:$port'));
    await channel.ready;
    _channel = channel;
    channel.stream.listen(
      (raw) => _bus.add(DuelMessage.decode(raw as String)),
    );
  }

  void send(DuelMessage message) {
    _channel?.sink.add(message.encode());
  }

  Future<void> disconnect() async {
    await _channel?.sink.close();
    await _bus.close();
  }
}
