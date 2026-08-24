import 'dart:io';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'duel_message_bus.dart';
import 'duel_protocol.dart';

/// Startet einen lokalen WebSocket-Server im selben WLAN, mit dem sich genau
/// ein zweites Gerät verbinden kann (siehe ROADMAP_QuizApp.md Abschnitt 5,
/// Option 2). Nur auf Android/iOS/Windows/macOS/Linux verfügbar, nicht im Web.
class DuelHostService {
  HttpServer? _server;
  final _bus = DuelMessageBus();
  WebSocketChannel? _channel;

  Stream<DuelMessage> get messages => _bus.stream;
  bool get hasClient => _channel != null;

  Future<T> waitFor<T extends DuelMessage>() => _bus.waitFor<T>();

  /// Ermittelt die lokale LAN-IP-Adresse, die der zweite Spieler eintippen kann.
  Future<String?> findLocalIp() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );
    for (final interface in interfaces) {
      for (final addr in interface.addresses) {
        if (!addr.isLoopback) return addr.address;
      }
    }
    return null;
  }

  Future<int> start({int port = 8123, void Function()? onConnected}) async {
    final handler = webSocketHandler((webSocket, protocol) {
      _channel = webSocket;
      onConnected?.call();
      webSocket.stream.listen(
        (raw) => _bus.add(DuelMessage.decode(raw as String)),
        onDone: () => _channel = null,
      );
    });
    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
    return _server!.port;
  }

  void send(DuelMessage message) {
    _channel?.sink.add(message.encode());
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    await _bus.close();
  }
}
