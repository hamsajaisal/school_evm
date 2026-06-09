import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/candidate.dart';
import '../models/voter.dart';
import '../models/election_settings.dart';

class DatabaseService extends ChangeNotifier {
  static const String _settingsBoxName = 'settings_box';
  static const String _candidatesBoxName = 'candidates_box';
  static const String _votersBoxName = 'voters_box';
  static const String _votesBoxName = 'votes_box'; // Stores anonymous candidate IDs

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  ElectionSettings? _settings;
  ElectionSettings? get settings => _settings;

  List<Candidate> _candidates = [];
  List<Candidate> get candidates => _candidates;

  List<Voter> _voters = [];
  List<Voter> get voters => _voters;

  List<String> _anonymousVotes = [];
  List<String> get anonymousVotes => _anonymousVotes;

  Future<void> init() async {
    if (_isInitialized) return;
    await Hive.initFlutter();
    
    await Hive.openBox(_settingsBoxName);
    await Hive.openBox(_candidatesBoxName);
    await Hive.openBox(_votersBoxName);
    await Hive.openBox(_votesBoxName);

    _isInitialized = true;
    _loadData();
  }

  void _loadData() {
    final settingsBox = Hive.box(_settingsBoxName);
    final candidatesBox = Hive.box(_candidatesBoxName);
    final votersBox = Hive.box(_votersBoxName);
    final votesBox = Hive.box(_votesBoxName);

    // Load settings
    if (settingsBox.isNotEmpty) {
      final map = settingsBox.get('current_settings');
      if (map != null) {
        _settings = ElectionSettings.fromMap(Map<dynamic, dynamic>.from(map));
      }
    }

    // Load candidates (sorted by serial number)
    _candidates = candidatesBox.values.map((map) {
      return Candidate.fromMap(Map<dynamic, dynamic>.from(map));
    }).toList();
    _candidates.sort((a, b) => a.serialNumber.compareTo(b.serialNumber));

    // Load voters (sorted by serial number)
    _voters = votersBox.values.map((map) {
      return Voter.fromMap(Map<dynamic, dynamic>.from(map));
    }).toList();
    _voters.sort((a, b) {
      // Try to parse serial numbers as integers for proper sorting if possible
      final aInt = int.tryParse(a.serialNumber);
      final bInt = int.tryParse(b.serialNumber);
      if (aInt != null && bInt != null) {
        return aInt.compareTo(bInt);
      }
      return a.serialNumber.compareTo(b.serialNumber);
    });

    // Load votes
    _anonymousVotes = List<String>.from(votesBox.values);

    notifyListeners();
  }

  // Update Settings
  Future<void> saveSettings(ElectionSettings settings) async {
    _settings = settings;
    final box = Hive.box(_settingsBoxName);
    await box.put('current_settings', settings.toMap());
    notifyListeners();
  }

  // Clear current election database for a new setup
  Future<void> resetElection() async {
    await Hive.box(_settingsBoxName).clear();
    await Hive.box(_candidatesBoxName).clear();
    await Hive.box(_votersBoxName).clear();
    await Hive.box(_votesBoxName).clear();
    _settings = null;
    _candidates = [];
    _voters = [];
    _anonymousVotes = [];
    notifyListeners();
  }

  // Add Candidate
  Future<void> addCandidate(Candidate candidate) async {
    final box = Hive.box(_candidatesBoxName);
    await box.put(candidate.id, candidate.toMap());
    _candidates.add(candidate);
    _candidates.sort((a, b) => a.serialNumber.compareTo(b.serialNumber));
    notifyListeners();
  }

  // Delete Candidate
  Future<void> deleteCandidate(String id) async {
    final box = Hive.box(_candidatesBoxName);
    await box.delete(id);
    _candidates.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  // Add Voter
  Future<void> addVoter(Voter voter) async {
    final box = Hive.box(_votersBoxName);
    await box.put(voter.admissionNumber, voter.toMap());
    _voters.add(voter);
    _voters.sort((a, b) {
      final aInt = int.tryParse(a.serialNumber);
      final bInt = int.tryParse(b.serialNumber);
      if (aInt != null && bInt != null) {
        return aInt.compareTo(bInt);
      }
      return a.serialNumber.compareTo(b.serialNumber);
    });
    notifyListeners();
  }

  // Bulk add voters (from CSV)
  Future<void> addVoters(List<Voter> newVoters) async {
    final box = Hive.box(_votersBoxName);
    final Map<String, dynamic> entries = {};
    for (var voter in newVoters) {
      entries[voter.admissionNumber] = voter.toMap();
    }
    await box.putAll(entries);
    _loadData();
  }

  // Mark Voter as Voted
  Future<void> markVoterAsVoted(String admissionNumber) async {
    final box = Hive.box(_votersBoxName);
    final map = box.get(admissionNumber);
    if (map != null) {
      final voter = Voter.fromMap(Map<dynamic, dynamic>.from(map));
      voter.hasVoted = true;
      await box.put(admissionNumber, voter.toMap());
      
      // Update in memory
      final index = _voters.indexWhere((v) => v.admissionNumber == admissionNumber);
      if (index != -1) {
        _voters[index].hasVoted = true;
        notifyListeners();
      }
    }
  }

  // Register Anonymous Vote (Cast ballot)
  Future<void> castVote(String candidateId) async {
    final votesBox = Hive.box(_votesBoxName);
    await votesBox.add(candidateId);
    _anonymousVotes.add(candidateId);

    // Update the candidate's count
    final candidatesBox = Hive.box(_candidatesBoxName);
    final map = candidatesBox.get(candidateId);
    if (map != null) {
      final candidate = Candidate.fromMap(Map<dynamic, dynamic>.from(map));
      candidate.votes += 1;
      await candidatesBox.put(candidateId, candidate.toMap());

      // Update in memory
      final index = _candidates.indexWhere((c) => c.id == candidateId);
      if (index != -1) {
        _candidates[index].votes += 1;
      }
    }
    notifyListeners();
  }
}
