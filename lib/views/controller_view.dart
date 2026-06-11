// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/election_provider.dart';
import '../services/pdf_service.dart';
import '../models/voter.dart';
import 'live_count_view.dart';

class ControllerView extends StatefulWidget {
  final bool autoHost;
  const ControllerView({super.key, this.autoHost = false});

  @override
  State<ControllerView> createState() => _ControllerViewState();
}

class _ControllerViewState extends State<ControllerView> {
  String _searchQuery = '';
  Voter? _selectedVoter;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.autoHost) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<ElectionProvider>(context, listen: false).startAsControllerHost(8080);
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ElectionProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Filtered voters
    final filteredVoters = provider.db.voters.where((v) {
      final query = _searchQuery.toLowerCase();
      return v.fullName.toLowerCase().contains(query) ||
             v.admissionNumber.toLowerCase().contains(query) ||
             v.serialNumber.contains(query);
    }).toList();

    // Stats
    final totalVoters = provider.db.voters.length;
    final votedCount = provider.db.voters.where((v) => v.hasVoted).length;
    final turnoutPct = totalVoters > 0 ? (votedCount / totalVoters) * 100 : 0.0;
    
    // Connection info
    final ipAddress = provider.net.serverIp ?? 'Retrieving IP...';
    final isConnected = provider.net.isConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Election Controller Desk'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // Export slips
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Print Voter Slips',
            onPressed: () {
              if (provider.db.settings != null && provider.db.voters.isNotEmpty) {
                PdfService.generateAndPrintVoterSlips(provider.db.voters, provider.db.settings!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Setup incomplete or no voters found.')),
                );
              }
            },
          ),
          // Reset election completely
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset Election',
            onPressed: () => _confirmReset(context, provider),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Panel: Network Setup & Stats
          Expanded(
            flex: 2,
            child: Container(
              color: isDark ? const Color(0xFF181824) : Colors.indigo.withOpacity(0.03),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pairing Header
                    const Text('Booth Pairing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    
                    // Connection Status Card
                    Card(
                      elevation: 0,
                      color: isConnected ? Colors.green.withOpacity(0.12) : Colors.orange.withOpacity(0.12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isConnected ? Colors.green : Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              isConnected ? Icons.check_circle : Icons.warning_rounded,
                              color: isConnected ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isConnected
                                    ? 'Voting Booth Connected!'
                                    : 'Waiting for Booth to Connect...',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isConnected ? Colors.green[800] : Colors.orange[800],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Host IP Card & QR Code
                    Center(
                      child: Column(
                        children: [
                          Text('IP Address: $ipAddress', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 8),
                          if (provider.net.serverIp != null)
                            QrImageView(
                              data: provider.net.serverIp!,
                              version: QrVersions.auto,
                              size: 160.0,
                              eyeStyle: QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: isDark ? Colors.white : Colors.indigo,
                              ),
                              dataModuleStyle: QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: isDark ? Colors.white : Colors.indigo,
                              ),
                            ),
                          const SizedBox(height: 8),
                          const Text(
                            'Scan this QR code from the student\'s Voting Booth device to link them instantly.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Stats Dashboard
                    const Text('Turnout Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: totalVoters > 0 ? (votedCount / totalVoters) : 0,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigo),
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$votedCount / $totalVoters Voted'),
                        Text('${turnoutPct.toStringAsFixed(1)}% Turnout'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Finish Election Actions
                    const Text('Controls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (provider.db.settings?.isElectionFinished ?? false) ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LiveCountView()),
                          );
                        },
                        icon: const Icon(Icons.bar_chart_rounded),
                        label: const Text('Start Live Count Animation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: () => _confirmFinish(context, provider),
                        icon: const Icon(Icons.lock_clock_rounded),
                        label: const Text('Finish Voting & End Election'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          // Right Panel: Voter List & Selection
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Student Voter Directory',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Search Bar
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search by Name, Admission Number, or Serial...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Voters Table List
                  Expanded(
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: filteredVoters.isEmpty
                          ? const Center(child: Text('No matching voters found.'))
                          : ListView.separated(
                              itemCount: filteredVoters.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (ctx, idx) {
                                final voter = filteredVoters[idx];
                                final isSelected = _selectedVoter?.admissionNumber == voter.admissionNumber;
                                final isAuthorized = provider.currentlyAuthorizedVoter?.admissionNumber == voter.admissionNumber;
                                
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: voter.hasVoted
                                        ? Colors.green[50]
                                        : isSelected
                                            ? Colors.indigo[100]
                                            : Colors.grey[100],
                                    foregroundColor: voter.hasVoted
                                        ? Colors.green
                                        : isSelected
                                            ? Colors.indigo
                                            : Colors.black54,
                                    child: Text(voter.serialNumber),
                                  ),
                                  title: Text(
                                    voter.fullName,
                                    style: TextStyle(
                                      fontWeight: voter.hasVoted ? FontWeight.normal : FontWeight.w600,
                                      decoration: voter.hasVoted ? TextDecoration.lineThrough : null,
                                      color: voter.hasVoted ? Colors.grey : null,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Admission No: ${voter.admissionNumber} | Class ${voter.classLevel}-${voter.division}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: _buildStatusWidget(voter, isAuthorized),
                                  selected: isSelected,
                                  selectedColor: Colors.indigo,
                                  onTap: voter.hasVoted
                                      ? null // Already voted: disabled
                                      : () {
                                          setState(() => _selectedVoter = voter);
                                          SemanticsService.announce("Voter ${voter.fullName} selected", TextDirection.ltr);
                                        },
                                );
                              },
                            ),
                    ),
                  ),
                  
                  // Active Control bar at the bottom
                  if (_selectedVoter != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.indigo.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Selected Voter:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(
                                '${_selectedVoter!.fullName} (${_selectedVoter!.admissionNumber})',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: !isConnected
                                ? null // Disable if booth not connected
                                : () {
                                    final name = _selectedVoter!.fullName;
                                    provider.authorizeVoterForBooth(_selectedVoter!);
                                    setState(() => _selectedVoter = null);
                                    SemanticsService.announce("Voter $name authorized successfully", TextDirection.ltr);
                                  },
                            icon: const Icon(Icons.how_to_reg_rounded),
                            label: const Text('Authorize to Vote'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // If someone is currently voting
                  if (provider.currentlyAuthorizedVoter != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Authorized: ${provider.currentlyAuthorizedVoter!.fullName} is in the Voting Booth...',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green),
                            ),
                          ),
                          TextButton(
                            onPressed: () => provider.nextVoter(),
                            child: const Text('Cancel / Next', style: TextStyle(color: Colors.red)),
                          )
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusWidget(Voter voter, bool isAuthorized) {
    if (voter.hasVoted) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Voted ', style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w500)),
          Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
        ],
      );
    }
    if (isAuthorized) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Voting...',
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Eligible',
        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  void _confirmReset(BuildContext context, ElectionProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reset Election?'),
          content: const Text(
            'This will permanently delete all candidates, voters, and vote counts for this election profile. Are you absolutely sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await provider.clearAll();
                if (!context.mounted) return;
                Navigator.pop(context); // Go back to Role Selection Home
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reset Everything'),
            )
          ],
        );
      },
    );
  }

  void _confirmFinish(BuildContext context, ElectionProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Finish Voting?'),
          content: const Text(
            'This will freeze the Voting Booth, lock out any remaining voters, and prepare the counts for live display. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                provider.finishVoting();
                SemanticsService.announce("Election finished successfully", TextDirection.ltr);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Finish & Freeze'),
            )
          ],
        );
      },
    );
  }
}
