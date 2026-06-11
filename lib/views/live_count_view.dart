// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';
import '../services/election_provider.dart';
import '../widgets/election_symbols.dart';
import '../models/candidate.dart';
import '../services/sound_service.dart';

class LiveCountView extends StatefulWidget {
  const LiveCountView({super.key});

  @override
  State<LiveCountView> createState() => _LiveCountViewState();
}

class _LiveCountViewState extends State<LiveCountView> {
  List<String> _shuffledVotes = [];
  int _currentIndex = 0;
  
  // Local tally: candidateId -> voteCount
  final Map<String, int> _liveTally = {};
  
  // Auto-play timer
  Timer? _autoTimer;
  bool _isAutoPlaying = false;
  double _playSpeedSeconds = 1.5;

  String? _lastDrawnCandidateName;
  String? _lastDrawnSymbolName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCounting();
    });
  }

  void _initializeCounting() {
    final provider = Provider.of<ElectionProvider>(context, listen: false);
    
    // Scramble the order of cast ballot tokens to ensure 100% secret ballot
    _shuffledVotes = List<String>.from(provider.db.anonymousVotes)..shuffle();
    
    // Initialize live tally map
    for (var cand in provider.db.candidates) {
      _liveTally[cand.id] = 0;
    }
    
    _currentIndex = 0;
    _isAutoPlaying = false;
    _lastDrawnCandidateName = null;
    _lastDrawnSymbolName = null;
    setState(() {});
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  // Draw a single ballot from the box
  void _drawNextBallot() async {
    if (_currentIndex >= _shuffledVotes.length) {
      _stopAutoPlay();
      return;
    }

    final provider = Provider.of<ElectionProvider>(context, listen: false);
    final candidateId = _shuffledVotes[_currentIndex];
    
    // Play sound effect
    await SoundService.playBuzzer();

    final candidate = provider.db.candidates.firstWhere((c) => c.id == candidateId);

    setState(() {
      _liveTally[candidateId] = (_liveTally[candidateId] ?? 0) + 1;
      _lastDrawnCandidateName = candidate.name;
      _lastDrawnSymbolName = candidate.symbolName;
      _currentIndex += 1;
    });

    // Spoken announcement for the drawn ballot
    SemanticsService.announce(
      "Vote drawn for ${candidate.name}, symbol ${candidate.symbolName}",
      TextDirection.ltr,
    );

    if (_currentIndex >= _shuffledVotes.length) {
      _stopAutoPlay();
      
      // Calculate winner and announce at the end
      Candidate? winner;
      int maxVotes = -1;
      for (var cand in provider.db.candidates) {
        final votes = _liveTally[cand.id] ?? 0;
        if (votes > maxVotes) {
          maxVotes = votes;
          winner = cand;
        }
      }
      
      if (winner != null) {
        // Delay slightly to not conflict with the last vote announcement
        Future.delayed(const Duration(milliseconds: 1500), () {
          SemanticsService.announce(
            "Counting complete. Winner is ${winner!.name} with $maxVotes votes.",
            TextDirection.ltr,
          );
        });
      }
    }
  }

  void _toggleAutoPlay() {
    if (_isAutoPlaying) {
      _stopAutoPlay();
    } else {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _isAutoPlaying = true;
    _autoTimer = Timer.periodic(
      Duration(milliseconds: (_playSpeedSeconds * 1000).toInt()),
      (timer) {
        if (_currentIndex < _shuffledVotes.length) {
          _drawNextBallot();
        } else {
          _stopAutoPlay();
        }
      },
    );
    setState(() {});
  }

  void _stopAutoPlay() {
    _autoTimer?.cancel();
    _isAutoPlaying = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ElectionProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isFinished = _currentIndex >= _shuffledVotes.length && _shuffledVotes.isNotEmpty;
    
    // Calculate current stats
    final totalCast = _shuffledVotes.length;
    final progress = totalCast > 0 ? _currentIndex / totalCast : 0.0;

    // Leader Calculations
    Candidate? leader;
    int maxVotes = -1;
    int leadMargin = 0;
    
    if (_currentIndex > 0) {
      // Find candidate with max votes in live tally
      for (var cand in provider.db.candidates) {
        final votes = _liveTally[cand.id] ?? 0;
        if (votes > maxVotes) {
          maxVotes = votes;
          leader = cand;
        }
      }
      
      // Calculate lead margin relative to second place
      List<int> sortedScores = _liveTally.values.toList()..sort((a, b) => b.compareTo(a));
      if (sortedScores.length > 1) {
        leadMargin = sortedScores[0] - sortedScores[1];
      } else {
        leadMargin = sortedScores[0];
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Election Tally Board'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.replay_rounded),
            tooltip: 'Restart Counting (Reshuffle)',
            onPressed: () => _initializeCounting(),
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1E1E2F), const Color(0xFF11111E)]
                : [const Color(0xFFF4F6F9), const Color(0xFFE3E7ED)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Stats / Status Bar
              _buildStatusBar(context, isDark, totalCast, progress, isFinished, leader, leadMargin),
              const SizedBox(height: 24),

              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Column: The Ballot Box & Auto Controls
                    Expanded(
                      flex: 2,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: isDark ? const Color(0xFF1F1F35) : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Ballot box drawing button
                              InkWell(
                                onTap: (_isAutoPlaying || isFinished) ? null : _drawNextBallot,
                                borderRadius: BorderRadius.circular(70),
                                child: Semantics(
                                  label: isFinished
                                      ? 'Ballot box. Counting complete.'
                                      : _isAutoPlaying
                                          ? 'Ballot box. Auto counting in progress.'
                                          : 'Ballot box. Tap or press Enter to draw the next ballot.',
                                  button: true,
                                  excludeSemantics: true,
                                  child: _buildBallotBoxWidget(isDark, isFinished),
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Last drawn ballot label
                              if (_lastDrawnCandidateName != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Vote Drawn for: ', style: TextStyle(color: Colors.grey)),
                                      Text(
                                        _lastDrawnCandidateName!,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      if (_lastDrawnSymbolName != null)
                                        ElectionSymbol(name: _lastDrawnSymbolName!, size: 32),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Controls
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: isFinished ? null : _drawNextBallot,
                                    icon: const Icon(Icons.arrow_forward_rounded),
                                    label: const Text('Draw Next'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: isFinished ? null : _toggleAutoPlay,
                                    icon: Icon(_isAutoPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                                    label: Text(_isAutoPlaying ? 'Pause' : 'Auto Play'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isAutoPlaying ? Colors.amber[700] : Colors.green[600],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              ),
                              
                              if (!isFinished) ...[
                                const SizedBox(height: 20),
                                Text('Auto Play Interval: ${_playSpeedSeconds.toStringAsFixed(1)}s'),
                                Slider(
                                  value: _playSpeedSeconds,
                                  min: 0.5,
                                  max: 3.0,
                                  divisions: 5,
                                  label: '${_playSpeedSeconds}s',
                                  activeColor: Colors.indigo,
                                  onChanged: _isAutoPlaying
                                      ? null
                                      : (val) => setState(() => _playSpeedSeconds = val),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Right Column: Live Bar Charts
                    Expanded(
                      flex: 3,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: isDark ? const Color(0xFF1F1F35) : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Live Results Tally', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: provider.db.candidates.length,
                                  itemBuilder: (ctx, idx) {
                                    final cand = provider.db.candidates[idx];
                                    final score = _liveTally[cand.id] ?? 0;
                                    
                                    // Calculate percentage of currently drawn votes
                                    final drawnTotal = _currentIndex == 0 ? 1 : _currentIndex;
                                    final pct = score / drawnTotal;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 14,
                                                    backgroundColor: Colors.indigo.withOpacity(0.1),
                                                    child: Text(
                                                      cand.serialNumber.toString(),
                                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(cand.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  ElectionSymbol(name: cand.symbolName, size: 28),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    '$score votes',
                                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          // Animated growth bar
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Stack(
                                                  children: [
                                                    // Track background
                                                    Container(
                                                      height: 16,
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[200],
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                    ),
                                                    // Tally growth
                                                    AnimatedContainer(
                                                      duration: const Duration(milliseconds: 300),
                                                      curve: Curves.easeOutCubic,
                                                      width: MediaQuery.of(context).size.width * 0.3 * pct,
                                                      height: 16,
                                                      decoration: BoxDecoration(
                                                        gradient: const LinearGradient(
                                                          colors: [Colors.indigoAccent, Colors.indigo],
                                                        ),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar(
    BuildContext context,
    bool isDark,
    int totalCast,
    double progress,
    bool isFinished,
    Candidate? leader,
    int leadMargin,
  ) {
    if (isFinished && leader != null) {
      return Card(
        elevation: 6,
        shadowColor: Colors.green.withOpacity(0.3),
        color: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 36),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ELECTION COMPLETED - WINNER ANNOUNCED!',
                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      Text(
                        '${leader.name} Wins by $leadMargin votes!',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ],
              ),
              ElectionSymbol(name: leader.symbolName, size: 56),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1F1F35) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Counting Progress: $_currentIndex / $totalCast Ballots Drawn',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigoAccent, fontSize: 16),
                )
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigoAccent),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            if (_currentIndex > 0 && leader != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.indigoAccent, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'Current Leader: ',
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                  ),
                  Text(
                    leader.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigoAccent),
                  ),
                  Text(
                    ' leading by $leadMargin votes.',
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildBallotBoxWidget(bool isDark, bool isFinished) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: isFinished
                ? Colors.grey.withOpacity(0.1)
                : _isAutoPlaying
                    ? Colors.green.withOpacity(0.1)
                    : Colors.indigo.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: isFinished
                  ? Colors.grey
                  : _isAutoPlaying
                      ? Colors.green
                      : Colors.indigoAccent,
              width: 3,
            ),
          ),
          child: Icon(
            isFinished
                ? Icons.inventory_2_outlined
                : Icons.all_inbox_rounded,
            size: 64,
            color: isFinished
                ? Colors.grey
                : _isAutoPlaying
                    ? Colors.green
                    : Colors.indigoAccent,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isFinished
              ? 'Tally Complete'
              : _isAutoPlaying
                  ? 'Auto-Counting...'
                  : 'Tap to Draw Ballot',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isFinished
                ? Colors.grey
                : _isAutoPlaying
                    ? Colors.green
                    : Colors.indigoAccent,
          ),
        ),
      ],
    );
  }
}
