import 'dart:io';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'server_interface.dart';

class BoothServerImpl implements BoothServer {
  HttpServer? _server;
  final List<WebSocketChannel> _clients = [];
  Function(String message)? _onMessageReceived;
  Function(bool connected)? _onConnectionChanged;

  @override
  Future<void> start(
    int port,
    Function(String message) onMessageReceived,
    Function(bool connected) onConnectionChanged,
  ) async {
    _onMessageReceived = onMessageReceived;
    _onConnectionChanged = onConnectionChanged;

    final handler = webSocketHandler((WebSocketChannel webSocket) {
      _clients.add(webSocket);
      _onConnectionChanged?.call(true);

      webSocket.stream.listen((message) {
        if (message is String) {
          _onMessageReceived?.call(message);
        }
      }, onDone: () {
        _clients.remove(webSocket);
        _onConnectionChanged?.call(_clients.isNotEmpty);
      }, onError: (err) {
        _clients.remove(webSocket);
        _onConnectionChanged?.call(_clients.isNotEmpty);
      });
    });

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
    print('WebSocket server listening on port ${_server!.port}');
  }

  @override
  Future<void> stop() async {
    for (var client in _clients) {
      client.sink.close();
    }
    _clients.clear();
    await _server?.close(force: true);
    _server = null;
  }

  @override
  void broadcast(String message) {
    for (var client in _clients) {
      try {
        client.sink.add(message);
      } catch (e) {
        print('Error broadcasting to client: $e');
      }
    }
  }

  @override
  Future<String?> getLocalIp() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('Error getting local IP: $e');
    }
    return null;
  }
}
