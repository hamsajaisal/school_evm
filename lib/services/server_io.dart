import 'dart:io';
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
      print('SERVER: Client connected (hashCode: ${webSocket.hashCode})');
      _clients.add(webSocket);
      _onConnectionChanged?.call(true);

      webSocket.stream.listen((message) {
        print('SERVER: Received message: $message');
        if (message is String) {
          _onMessageReceived?.call(message);
        }
      }, onDone: () {
        print('SERVER: Client disconnected (onDone, hashCode: ${webSocket.hashCode})');
        _clients.remove(webSocket);
        _onConnectionChanged?.call(_clients.isNotEmpty);
      }, onError: (err) {
        print('SERVER: Client error ($err, hashCode: ${webSocket.hashCode})');
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
      final interfaces = await NetworkInterface.list();
      final List<String> ips = [];
      
      // 1. Collect Wi-Fi, Ethernet, and Hotspot/AP interfaces
      for (var interface in interfaces) {
        final name = interface.name.toLowerCase();
        if (name.contains('wlan') || name.contains('wifi') || name.contains('eth') || name.contains('en') || name.contains('ap') || name.contains('softap')) {
          for (var addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
              if (!ips.contains(addr.address)) {
                ips.add(addr.address);
              }
            }
          }
        }
      }
      
      // 2. Collect other interfaces (excluding loopback, cellular, or p2p if possible in fallback)
      for (var interface in interfaces) {
        final name = interface.name.toLowerCase();
        if (name.contains('lo') || name.contains('rmnet') || name.contains('p2p')) continue;
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            if (!ips.contains(addr.address)) {
              ips.add(addr.address);
            }
          }
        }
      }

      // 3. Collect everything else
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            if (!ips.contains(addr.address)) {
              ips.add(addr.address);
            }
          }
        }
      }
      
      if (ips.isNotEmpty) {
        return ips.join(',');
      }
    } catch (e) {
      print('Error getting local IP: $e');
    }
    return null;
  }
}
