abstract class BoothServer {
  Future<void> start(
    int port,
    Function(String message) onMessageReceived,
    Function(bool connected) onConnectionChanged,
  );
  Future<void> stop();
  void broadcast(String message);
  Future<String?> getLocalIp();
}
