import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'duel_protocol.dart';

/// Verbindet sich als zweiter Spieler mit einem lokal gehosteten Duell.
/// Läuft auf allen Plattformen inkl. Web.
class DuelClientService {
  WebSocketChannel? _channel;
  final _messageController = StreamController<DuelMessage>.broadcast();

  Stream<DuelMessage> get messages => _messageController.stream;

  Future<void> connect(String host, int port) async {
    final channel = WebSocketChannel.connect(Uri.parse('ws://$host:$port'));
    await channel.ready;
    _channel = channel;
    channel.stream.listen(
      (raw) => _messageController.add(DuelMessage.decode(raw as String)),
    );
  }

  void send(DuelMessage message) {
    _channel?.sink.add(message.encode());
  }

  Future<void> disconnect() async {
    await _channel?.sink.close();
    await _messageController.close();
  }
}
