import 'server_interface.dart';

class BoothServerImpl implements BoothServer {
  @override
  Future<void> start(
    int port,
    Function(String message) onMessageReceived,
    Function(bool connected) onConnectionChanged,
  ) async {}

  @override
  Future<void> stop() async {}

  @override
  void broadcast(String message) {}

  @override
  Future<String?> getLocalIp() async => null;
}
