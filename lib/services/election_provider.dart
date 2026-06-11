import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import '../models/candidate.dart';
import '../models/voter.dart';
import '../models/election_settings.dart';
import 'database_service.dart';
import 'network_service.dart';
import 'sound_service.dart';

class ElectionProvider extends ChangeNotifier {
  final DatabaseService db = DatabaseService();
  final NetworkService net = NetworkService();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Active voter at the booth (used in both Controller and Booth client)
  Voter? get activeVoter => net.activeVoter;
  BoothState get boothState => net.boothState;

  // Track if a voter is authorized and waiting to vote
  Voter? _currentlyAuthorizedVoter;
  Voter? get currentlyAuthorizedVoter => _currentlyAuthorizedVoter;

  // Results Sync for Host Controller (updated at the end of election)
  List<Candidate> _finalSyncResults = [];
  List<Candidate> get finalSyncResults =>
      net.role == NetworkRole.host ? _finalSyncResults : db.candidates;

  Future<void> init() async {
    if (_isInitialized) return;
    await db.init();
    _isInitialized = true;
    
    // Connect database and network service callbacks
    net.onVoteReceived = (candidateId) async {
      await db.castVote(candidateId);
      // Play buzzer sound locally on the host if needed (typically plays on Booth)
    };

    net.onVoteCastNotification = (admissionNumber) async {
      await db.markVoterAsVoted(admissionNumber);
      _currentlyAuthorizedVoter = null;
      notifyListeners();
    };

    net.onSyncResultsReceived = (candidatesSync) {
      _finalSyncResults = candidatesSync.map((data) {
        return Candidate.fromMap(Map<String, dynamic>.from(data));
      }).toList();
      _finalSyncResults.sort((a, b) => a.serialNumber.compareTo(b.serialNumber));
      notifyListeners();
    };

    // Sync configuration from Host -> Client when client connects
    net.onClientConnected = () {
      if (db.settings != null) {
        final settingsMap = db.settings!.toMap();
        final candidatesMapList = db.candidates.map((c) => c.toMap()).toList();
        net.sendElectionConfig(settingsMap, candidatesMapList);
      }
    };

    // Client receives configuration from Host
    net.onSyncConfigReceived = (settingsMap, candidatesList) async {
      await db.syncElectionConfig(settingsMap, candidatesList);
      SemanticsService.announce("Election settings and candidates synchronized from controller", TextDirection.ltr);
      notifyListeners();
    };

    db.addListener(_onDbChanged);
    net.addListener(_onNetChanged);
    notifyListeners();
  }

  void _onDbChanged() {
    notifyListeners();
  }

  void _onNetChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    db.removeListener(_onDbChanged);
    net.removeListener(_onNetChanged);
    net.stop();
    super.dispose();
  }

  // Define new election setup
  Future<void> startNewElectionSetup(String schoolName, String year, String targetClass) async {
    await db.resetElection();
    final settings = ElectionSettings(
      schoolName: schoolName,
      year: year,
      targetClass: targetClass,
    );
    await db.saveSettings(settings);
    notifyListeners();
  }

  // Reset entirely
  Future<void> clearAll() async {
    await db.resetElection();
    await net.stop();
    _currentlyAuthorizedVoter = null;
    _finalSyncResults = [];
    notifyListeners();
  }

  // Add Candidate
  Future<void> createCandidate(String name, String symbolName, String? photoBase64) async {
    final serial = db.candidates.length + 1;
    final candidate = Candidate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      serialNumber: serial,
      name: name,
      symbolName: symbolName,
      photoBase64: photoBase64,
    );
    await db.addCandidate(candidate);
  }

  // Remove Candidate
  Future<void> deleteCandidate(String id) async {
    await db.deleteCandidate(id);
    // Re-adjust serial numbers
    final list = List<Candidate>.from(db.candidates);
    for (int i = 0; i < list.length; i++) {
      final updated = Candidate(
        id: list[i].id,
        serialNumber: i + 1,
        name: list[i].name,
        symbolName: list[i].symbolName,
        photoBase64: list[i].photoBase64,
        votes: list[i].votes,
      );
      final box = Hive.box('candidates_box');
      await box.put(updated.id, updated.toMap());
    }
    db.init(); // reload data
  }

  // Bulk Import Voters from CSV
  Future<int> importVotersFromCSV(String csvContent) async {
    final List<Voter> imported = [];
    final lines = const LineSplitter().convert(csvContent);
    int successCount = 0;

    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      final parts = line.split(',');
      if (parts.length >= 3) {
        // Serial, AdmissionNo, Name, [Class], [Division]
        final serial = parts[0].trim();
        final admNo = parts[1].trim();
        final name = parts[2].trim();
        final classLvl = parts.length > 3 ? parts[3].trim() : (db.settings?.targetClass ?? '');
        final div = parts.length > 4 ? parts[4].trim() : '';

        if (admNo.isNotEmpty && name.isNotEmpty) {
          imported.add(Voter(
            serialNumber: serial.isEmpty ? (db.voters.length + imported.length + 1).toString() : serial,
            admissionNumber: admNo,
            fullName: name,
            classLevel: classLvl,
            division: div,
          ));
          successCount++;
        }
      }
    }

    if (imported.isNotEmpty) {
      await db.addVoters(imported);
    }
    return successCount;
  }

  // Bulk Import Voters from Excel (.xlsx) bytes
  Future<int> importVotersFromExcel(List<int> bytes) async {
    final decoder = SpreadsheetDecoder.decodeBytes(bytes);
    final List<Voter> imported = [];
    int successCount = 0;

    for (var table in decoder.tables.keys) {
      final sheet = decoder.tables[table];
      if (sheet == null || sheet.maxRows == 0) continue;

      // Check if first row contains header strings
      bool hasHeader = false;
      if (sheet.maxRows > 0) {
        final firstRow = sheet.rows[0];
        for (var cell in firstRow) {
          final valStr = cell?.toString().toLowerCase() ?? '';
          if (valStr.contains('name') || valStr.contains('admission') || valStr.contains('serial') || valStr.contains('adm')) {
            hasHeader = true;
            break;
          }
        }
      }

      final startRow = hasHeader ? 1 : 0;
      for (int i = startRow; i < sheet.maxRows; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;

        // Extract: Serial, AdmissionNo, Name, [Class], [Division]
        final serial = row.isNotEmpty ? row[0]?.toString().trim() ?? '' : '';
        final admNo = row.length > 1 ? row[1]?.toString().trim() ?? '' : '';
        final name = row.length > 2 ? row[2]?.toString().trim() ?? '' : '';
        final classLvl = row.length > 3 ? row[3]?.toString().trim() ?? '' : (db.settings?.targetClass ?? '');
        final div = row.length > 4 ? row[4]?.toString().trim() ?? '' : '';

        if (admNo.isNotEmpty && name.isNotEmpty) {
          imported.add(Voter(
            serialNumber: serial.isEmpty ? (db.voters.length + imported.length + 1).toString() : serial,
            admissionNumber: admNo,
            fullName: name,
            classLevel: classLvl,
            division: div,
          ));
          successCount++;
        }
      }
    }

    if (imported.isNotEmpty) {
      await db.addVoters(imported);
    }
    return successCount;
  }

  // Add single voter manually
  Future<void> createVoter(String serial, String admNo, String name, String classLvl, String div) async {
    final voter = Voter(
      serialNumber: serial.isEmpty ? (db.voters.length + 1).toString() : serial,
      admissionNumber: admNo,
      fullName: name,
      classLevel: classLvl,
      division: div,
    );
    await db.addVoter(voter);
  }

  // Start Hosting Server on Controller (Teacher Phone)
  Future<void> startAsControllerHost(int port) async {
    final schoolName = db.settings?.schoolName ?? 'EVM Host';
    final year = db.settings?.year ?? '2026';
    final targetClass = db.settings?.targetClass ?? '';
    final displayName = targetClass.isNotEmpty ? "$schoolName ($targetClass)" : schoolName;

    await net.startHosting(
      port,
      displayName,
      year,
      (candidateId) async {
        await db.castVote(candidateId);
      },
      (admissionNumber) async {
        await db.markVoterAsVoted(admissionNumber);
        _currentlyAuthorizedVoter = null;
        notifyListeners();
      },
    );
  }

  // Connect Booth to Host Controller
  Future<void> startAsBoothClient(String ipAddress, int port) async {
    await net.connectToHost(ipAddress, port, (candidatesSync) {
      _finalSyncResults = candidatesSync.map((data) {
        return Candidate.fromMap(Map<String, dynamic>.from(data));
      }).toList();
      notifyListeners();
    });
  }

  // Booth -> Request election settings and candidates config from host
  void requestElectionConfig() {
    net.requestElectionConfig();
  }

  // Controller -> Authorize Voter
  void authorizeVoterForBooth(Voter voter) {
    _currentlyAuthorizedVoter = voter;
    net.authorizeVoter(voter);
    notifyListeners();
  }

  // Booth -> Cast Vote locally, play sound, notify host
  Future<void> castVoterBallot(String candidateId) async {
    if (activeVoter != null) {
      final voterAdm = activeVoter!.admissionNumber;
      
      // 1. Play EVM buzzer beep sound
      await SoundService.playBuzzer();

      // 2. Cast vote in database locally
      await db.castVote(candidateId);
      await db.markVoterAsVoted(voterAdm);

      // 3. Inform host controller
      net.notifyVoteCast(voterAdm, candidateId);
      notifyListeners();

      // 4. Accessibility announcement
      SemanticsService.announce(
        "Thank you! Your vote has been successfully cast. Please exit the booth.",
        TextDirection.ltr,
      );
    }
  }

  // Controller -> Advance Booth back to Locked/Ready
  void nextVoter() {
    _currentlyAuthorizedVoter = null;
    net.sendNextVoter();
    notifyListeners();
  }

  // Controller -> End voting, Sync tally, lock booth
  void finishVoting() {
    _currentlyAuthorizedVoter = null;
    
    // Sync final candidate counts from DB to clients
    final tally = db.candidates.map((c) => c.toMap()).toList();
    if (net.role == NetworkRole.host) {
      net.syncResults(tally);
    }
    net.sendFinishElection();

    if (db.settings != null) {
      final updatedSettings = ElectionSettings(
        schoolName: db.settings!.schoolName,
        year: db.settings!.year,
        targetClass: db.settings!.targetClass,
        isElectionFinished: true,
      );
      db.saveSettings(updatedSettings);
    }
    notifyListeners();
  }
}
