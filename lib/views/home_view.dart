import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/election_provider.dart';
import 'setup_view.dart';
import 'controller_view.dart';
import 'booth_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final TextEditingController _ipController = TextEditingController(text: '192.168.1.');

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ElectionProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1E1E2F), const Color(0xFF11111E)]
                : [const Color(0xFFEEF2F3), const Color(0xFFECE9E6)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Header Branding
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.how_to_vote_rounded,
                      size: 72,
                      color: Colors.indigoAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'School EVM Pro',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.indigo[900],
                          letterSpacing: 0.8,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Offline Peer-to-Peer School Voting System',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Selection Cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Controller Card (Host)
                      Expanded(
                        child: _buildRoleCard(
                          context: context,
                          title: 'Controller Desk',
                          subtitle: 'Teacher Console\nConfigure election & authorize voters.',
                          icon: Icons.admin_panel_settings_rounded,
                          gradient: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                          onTap: () {
                            if (provider.db.settings == null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SetupView()),
                              );
                            } else {
                              // If already setup, go straight to hosting screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ControllerView(autoHost: true),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Voting Booth Card (Client)
                      Expanded(
                        child: _buildRoleCard(
                          context: context,
                          title: 'Voting Booth',
                          subtitle: 'Student Terminal\nSecure anonymous interface for voters.',
                          icon: Icons.devices_other_rounded,
                          gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                          onTap: () => _showConnectDialog(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  // Footer metadata info
                  if (provider.db.settings != null)
                    Card(
                      elevation: 0,
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline_rounded,
                                color: Colors.green[600], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Active Election Profile: ${provider.db.settings!.schoolName} (${provider.db.settings!.year})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Card(
          margin: EdgeInsets.zero,
          color: Colors.transparent,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.85),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showConnectDialog(BuildContext context) {
    final provider = Provider.of<ElectionProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.wifi_find_rounded, color: Colors.amber),
              SizedBox(width: 8),
              Text('Connect to Controller'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the IP Address displayed on the Teacher\'s Controller screen:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ipController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'e.g. 192.168.1.5',
                  labelText: 'Controller IP Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.network_wifi_rounded),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final ip = _ipController.text.trim();
                if (ip.isNotEmpty) {
                  Navigator.pop(ctx);
                  
                  // Connect as client on port 8080
                  await provider.startAsBoothClient(ip, 8080);
                  
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BoothView()),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Connect'),
            ),
          ],
        );
      },
    );
  }
}
