// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/semantics.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'server_factory.dart';
import 'server_interface.dart';
import '../models/voter.dart';

enum NetworkRole { none, host, client }
enum BoothState { locked, activeVoting, voteCastSuccess, results }

class NetworkService extends ChangeNotifier {
  NetworkRole _role = NetworkRole.none;
  NetworkRole get role => _role;

  BoothState _boothState = BoothState.locked;
  BoothState get boothState => _boothState;

  // Server (Used by Host device)
  BoothServer? _server;
  String? _serverIp;
  String? get serverIp => _serverIp;
  String? _schoolName;
  String? _year;

  // Client (Used by Client device connecting to Host)
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Active Voter details currently voting in the Booth
  Voter? _activeVoter;
  Voter? get activeVoter => _activeVoter;

  // Callback registers
  Function(String candidateId)? onVoteReceived;
  Function(String admissionNumber)? onVoteCastNotification;
  Function(List<dynamic> candidatesSync)? onSyncResultsReceived;

  // Host/Server Mode (E.g. Controller phone hosting)
  Future<void> startHosting(
    int port,
    String schoolName,
    String year,
    Function(String candidateId) onVoteReceived,
    Function(String admissionNumber) onVoteCastNotification,
  ) async {
    if (kIsWeb) return; // Web cannot host a server
    await stop();

    _schoolName = schoolName;
    _year = year;
    _role = NetworkRole.host;
    this.onVoteReceived = onVoteReceived;
    this.onVoteCastNotification = onVoteCastNotification;
    _server = createServer();
    
    try {
      await _server!.start(
        port,
        _handleIncomingMessage,
        (connected) {
          _isConnected = connected;
          notifyListeners();
          if (!connected) {
            SemanticsService.announce("Voting booth disconnected", TextDirection.ltr);
          }
        },
      );

      _serverIp = await _server!.getLocalIp();
      notifyListeners();
      _startUdpBroadcast();
    } catch (e) {
      debugPrint('Error starting server: $e');
      _role = NetworkRole.none;
      _server = null;
      _serverIp = 'Error: $e';
      notifyListeners();
      
      // Accessibility screen reader announcement
      SemanticsService.announce(
        "Server failed to start. Check network connection.",
        TextDirection.ltr,
      );
    }
  }

  // Client Mode (E.g. Windows PC connecting to Phone Host)
  Future<void> connectToHost(
    String ipAddress,
    int port,
    Function(List<dynamic> candidatesSync) onSyncResultsReceived,
  ) async {
    await stop();
    _role = NetworkRole.client;
    this.onSyncResultsReceived = onSyncResultsReceived;

    final uri = Uri.parse('ws://$ipAddress:$port');
    try {
      final WebSocketChannel channel;
      if (kIsWeb) {
        channel = WebSocketChannel.connect(uri);
      } else {
        channel = IOWebSocketChannel.connect(uri, pingInterval: const Duration(seconds: 5));
      }
      // Wait for handshake connection to succeed (up to 5 seconds)
      await channel.ready.timeout(const Duration(seconds: 5));
      
      _channel = channel;
      _isConnected = true;
      _boothState = BoothState.locked;
      notifyListeners();

      // Announce connection on client
      SemanticsService.announce("Connected to controller successfully", TextDirection.ltr);

      // Send CLIENT_CONNECTED handshake to server
      final handshake = {'action': 'CLIENT_CONNECTED'};
      _channel!.sink.add(jsonEncode(handshake));

      _channel!.stream.listen(
        (message) {
          if (message is String) {
            _handleIncomingMessage(message);
          }
        },
        onDone: () {
          _isConnected = false;
          _role = NetworkRole.none;
          notifyListeners();
          SemanticsService.announce("Disconnected from controller", TextDirection.ltr);
        },
        onError: (err) {
          _isConnected = false;
          _role = NetworkRole.none;
          notifyListeners();
          SemanticsService.announce("Disconnected from controller due to error", TextDirection.ltr);
        },
      );
    } catch (e) {
      _isConnected = false;
      _role = NetworkRole.none;
      notifyListeners();
      rethrow;
    }
  }

  // Stop connection/hosting
  Future<void> stop() async {
    _stopUdpBroadcast();
    stopListeningForHost();
    if (_server != null) {
      await _server!.stop();
      _server = null;
    }
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }
    _role = NetworkRole.none;
    _isConnected = false;
    _serverIp = null;
    _activeVoter = null;
    _boothState = BoothState.locked;
    notifyListeners();
  }

  // Controller -> Booth: Unlock screen for voter
  void authorizeVoter(Voter voter) {
    if (_role == NetworkRole.host && _isConnected) {
      final packet = {
        'action': 'AUTHORIZE_VOTER',
        'voter': voter.toMap(),
      };
      _server!.broadcast(jsonEncode(packet));
    }
  }

  // Booth -> Controller: Student has voted
  void notifyVoteCast(String admissionNumber, String candidateId) {
    if (_role == NetworkRole.client && _isConnected) {
      final packet = {
        'action': 'VOTE_CAST',
        'admissionNumber': admissionNumber,
        'candidateId': candidateId,
      };
      _channel!.sink.add(jsonEncode(packet));
      _boothState = BoothState.voteCastSuccess;
      notifyListeners();
    }
  }

  // Controller -> Booth: Lock screen back to wait
  void sendNextVoter() {
    if (_role == NetworkRole.host && _isConnected) {
      final packet = {'action': 'NEXT_VOTER'};
      _server!.broadcast(jsonEncode(packet));
    }
  }

  // Controller -> Booth: Finish election & lock
  void sendFinishElection() {
    if (_role == NetworkRole.host && _isConnected) {
      final packet = {'action': 'FINISH_ELECTION'};
      _server!.broadcast(jsonEncode(packet));
    }
  }

  // Sync final results from Booth -> Controller at finish
  void syncResults(List<Map<String, dynamic>> candidateTally) {
    if (_role == NetworkRole.client && _isConnected) {
      final packet = {
        'action': 'SYNC_RESULTS',
        'candidates': candidateTally,
      };
      _channel!.sink.add(jsonEncode(packet));
    }
  }

  // Process incoming JSON packets
  void _handleIncomingMessage(String message) {
    try {
      final packet = jsonDecode(message) as Map<String, dynamic>;
      final action = packet['action'] as String;

      switch (action) {
        case 'CLIENT_CONNECTED':
          if (_role == NetworkRole.host) {
            print('HOST: Client handshaked successfully.');
            _isConnected = true;
            notifyListeners();
            SemanticsService.announce("Voting booth connected successfully", TextDirection.ltr);
          }
          break;

        case 'AUTHORIZE_VOTER':
          if (_role == NetworkRole.client) {
            _activeVoter = Voter.fromMap(packet['voter']);
            _boothState = BoothState.activeVoting;
            notifyListeners();
            SemanticsService.announce("Voting booth unlocked for ${_activeVoter?.fullName ?? 'voter'}", TextDirection.ltr);
          }
          break;

        case 'VOTE_CAST':
          if (_role == NetworkRole.host) {
            final admissionNumber = packet['admissionNumber'] as String;
            final candidateId = packet['candidateId'] as String;
            
            // Trigger callbacks in database to store vote anonymously
            onVoteReceived?.call(candidateId);
            onVoteCastNotification?.call(admissionNumber);
          }
          break;

        case 'NEXT_VOTER':
          if (_role == NetworkRole.client) {
            _activeVoter = null;
            _boothState = BoothState.locked;
            notifyListeners();
          }
          break;

        case 'FINISH_ELECTION':
          if (_role == NetworkRole.client) {
            _activeVoter = null;
            _boothState = BoothState.results;
            notifyListeners();
          }
          break;

        case 'SYNC_RESULTS':
          if (_role == NetworkRole.host) {
            final list = packet['candidates'] as List<dynamic>;
            onSyncResultsReceived?.call(list);
          }
          break;
      }
    } catch (e) {
      print('Error parsing network message: $e');
    }
  }

  // UDP Auto-Discovery Broadcast & Listener variables
  static const int _udpPort = 8888;
  RawDatagramSocket? _udpBroadcastSocket;
  Timer? _udpBroadcastTimer;
  RawDatagramSocket? _udpListenerSocket;
  StreamSubscription? _udpListenerSub;

  // Host: Start UDP Broadcast
  void _startUdpBroadcast() async {
    _stopUdpBroadcast();
    if (kIsWeb) return;
    try {
      _udpBroadcastSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _udpBroadcastSocket!.broadcastEnabled = true;
      _udpBroadcastTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (_serverIp != null) {
          final data = utf8.encode('SCHOOL_EVM_HOST:$_serverIp:${_schoolName ?? "EVM"}:${_year ?? "2026"}');
          try {
            _udpBroadcastSocket!.send(
              data,
              InternetAddress('255.255.255.255'),
              _udpPort,
            );
          } catch (_) {}
        }
      });
    } catch (e) {
      debugPrint('Error starting UDP broadcast: $e');
    }
  }

  void _stopUdpBroadcast() {
    _udpBroadcastTimer?.cancel();
    _udpBroadcastTimer = null;
    _udpBroadcastSocket?.close();
    _udpBroadcastSocket = null;
  }

  // Client: Start listening for Host discovery
  void startListeningForHost(Function(String hostIp, String schoolName, String year) onHostFound) async {
    stopListeningForHost();
    if (kIsWeb) return;
    try {
      _udpListenerSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _udpPort);
      _udpListenerSub = _udpListenerSocket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _udpListenerSocket!.receive();
          if (datagram != null) {
            final message = utf8.decode(datagram.data);
            if (message.startsWith('SCHOOL_EVM_HOST:')) {
              final parts = message.substring('SCHOOL_EVM_HOST:'.length).split(':');
              if (parts.length >= 3) {
                final ip = parts[0];
                final name = parts[1];
                final yr = parts[2];
                onHostFound(ip, name, yr);
              }
            }
          }
        }
      });
    } catch (e) {
      debugPrint('Error starting UDP listener: $e');
    }
  }

  void stopListeningForHost() {
    _udpListenerSub?.cancel();
    _udpListenerSub = null;
    _udpListenerSocket?.close();
    _udpListenerSocket = null;
  }
}
