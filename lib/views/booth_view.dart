import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/election_provider.dart';
import '../services/network_service.dart';
import '../widgets/election_symbols.dart';
import '../models/candidate.dart';

class BoothView extends StatefulWidget {
  const BoothView({super.key});

  @override
  State<BoothView> createState() => _BoothViewState();
}

class _BoothViewState extends State<BoothView> {
  Candidate? _tempSelectedCandidate;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ElectionProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-pop to HomeView if connection is lost
    if (!provider.net.isConnected && provider.net.role == NetworkRole.none) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    }

    switch (provider.boothState) {
      case BoothState.locked:
        return _buildLockedScreen(context, isDark);
      case BoothState.activeVoting:
        return _buildBallotScreen(context, provider, isDark);
      case BoothState.voteCastSuccess:
        return _buildSuccessScreen(context, isDark);
      case BoothState.results:
        return _buildFinishedScreen(context, isDark);
    }
  }

  // 1. Locked waiting screen
  Widget _buildLockedScreen(BuildContext context, bool isDark) {
    return Scaffold(
      body: Semantics(
        label: 'Voting booth locked. Please wait for the teacher to authorize you.',
        focused: true,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2F) : const Color(0xFFF0F4F8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 80,
                  color: Colors.indigoAccent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Voting Booth Locked',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.indigo[900],
                    ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please stand in line.\nThe teacher will unlock the booth for the next voter shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.indigoAccent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. EVM Ballot screen
  Widget _buildBallotScreen(BuildContext context, ElectionProvider provider, bool isDark) {
    final voter = provider.activeVoter;
    final candidates = provider.db.candidates;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${provider.db.settings?.schoolName ?? "School"} Election ${provider.db.settings?.year ?? ""}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            color: Colors.indigoAccent,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            alignment: Alignment.center,
            child: Text(
              voter != null
                  ? 'Voter ID: ${voter.serialNumber} | Full Name: ${voter.fullName} | Class: ${voter.classLevel}-${voter.division}'
                  : 'Active Ballot',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ),
      ),
      body: Container(
        color: isDark ? const Color(0xFF11111E) : const Color(0xFFF9FAFC),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Tap your candidate\'s name or symbol to vote.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 2.2, // Rectangular EVM keys
                ),
                itemCount: candidates.length,
                itemBuilder: (ctx, idx) {
                  final cand = candidates[idx];
                  return _buildCandidateTile(context, provider, cand, isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateTile(
    BuildContext context,
    ElectionProvider provider,
    Candidate cand,
    bool isDark,
  ) {
    return Semantics(
      label: 'Candidate ${cand.serialNumber}: ${cand.name}. Symbol: ${cand.symbolName}.',
      button: true,
      child: ElevatedButton(
        onPressed: () => _confirmVote(context, provider, cand),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF1F1F35) : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black87,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadowColor: isDark ? Colors.transparent : Colors.black26,
        ),
        child: Row(
          children: [
            // Serial Number Key Button
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                cand.serialNumber.toString(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigoAccent,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Candidate Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    cand.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Symbol: ${cand.symbolName}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  )
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Symbol Image
            ElectionSymbol(name: cand.symbolName, size: 56),
            
            const SizedBox(width: 16),
            
            // Big Blue EVM Button
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.blue[600],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: const Icon(Icons.touch_app_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Success Cast Screen (with Beep)
  Widget _buildSuccessScreen(BuildContext context, bool isDark) {
    return Scaffold(
      body: Semantics(
        label: 'Thank you! Your vote has been successfully cast. Please leave the booth.',
        focused: true,
        child: Container(
          width: double.infinity,
          color: isDark ? const Color(0xFF11111E) : Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 96,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Vote Registered!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your vote was cast successfully.\nThank you for participating!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.5, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              const Text(
                'Please exit the booth.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigoAccent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. Completed Election Screen
  Widget _buildFinishedScreen(BuildContext context, bool isDark) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        color: isDark ? const Color(0xFF1E1E2F) : const Color(0xFFECEFF1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.done_all_rounded,
              size: 84,
              color: Colors.indigo,
            ),
            const SizedBox(height: 24),
            Text(
              'Voting Concluded',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.indigo[900],
                  ),
            ),
            const SizedBox(height: 12),
            const Text(
              'All ballots are now closed.\nThe final tally has been securely submitted to the controller.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmVote(BuildContext context, ElectionProvider provider, Candidate cand) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Confirm Your Ballot'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Are you sure you want to vote for:'),
              const SizedBox(height: 16),
              Text(
                cand.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'Candidate symbol: ${cand.symbolName}',
                child: ElectionSymbol(name: cand.symbolName, size: 72),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Change'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                provider.castVoterBallot(cand.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Confirm Vote'),
            ),
          ],
        );
      },
    );
  }
}
