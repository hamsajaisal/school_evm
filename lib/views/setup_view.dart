import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/election_provider.dart';
import '../widgets/election_symbols.dart';
import 'controller_view.dart';

class SetupView extends StatefulWidget {
  const SetupView({super.key});

  @override
  State<SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<SetupView> {
  int _currentStep = 0;

  // Step 1 Controllers
  final _schoolNameCtrl = TextEditingController();
  final _yearCtrl = TextEditingController(text: '2026');
  final _classCtrl = TextEditingController();

  // Step 2 Controllers (Candidate Add)
  final _candNameCtrl = TextEditingController();
  String _selectedSymbol = ElectionSymbol.availableSymbols[0];

  // Step 3 Controllers (Voter Add & CSV)
  final _voterSerialCtrl = TextEditingController();
  final _voterAdmCtrl = TextEditingController();
  final _voterNameCtrl = TextEditingController();
  final _voterDivCtrl = TextEditingController(text: 'A');
  final _csvPasteCtrl = TextEditingController();

  @override
  void dispose() {
    _schoolNameCtrl.dispose();
    _yearCtrl.dispose();
    _classCtrl.dispose();
    _candNameCtrl.dispose();
    _voterSerialCtrl.dispose();
    _voterAdmCtrl.dispose();
    _voterNameCtrl.dispose();
    _voterDivCtrl.dispose();
    _csvPasteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ElectionProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Election Setup Wizard'),
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepTapped: (step) => setState(() => _currentStep = step),
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep += 1);
          } else {
            // Setup Complete, launch controller hosting
            _finishSetupAndHost(provider);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        controlsBuilder: (BuildContext context, ControlsDetails details) {
          final isLast = _currentStep == 2;
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(isLast ? 'Complete & Start Controller' : 'Continue'),
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                ]
              ],
            ),
          );
        },
        steps: [
          // Step 1: Metadata Settings
          Step(
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.editing,
            title: const Text('Details'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configure School & Year',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _schoolNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'School Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.school),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _yearCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Election Year',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.calendar_month),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _classCtrl,
                        decoration: InputDecoration(
                          labelText: 'Class (e.g. Class 5)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.class_),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_schoolNameCtrl.text.isEmpty || _classCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill in School Name and Class')),
                      );
                      return;
                    }
                    provider.startNewElectionSetup(
                      _schoolNameCtrl.text.trim(),
                      _yearCtrl.text.trim(),
                      _classCtrl.text.trim(),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Election details saved!')),
                    );
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                )
              ],
            ),
          ),

          // Step 2: Candidates management
          Step(
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.editing,
            title: const Text('Candidates'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Candidates',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _candNameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Candidate Full Name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Symbol Picker button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showSymbolGrid(context),
                        icon: ElectionSymbol(name: _selectedSymbol, size: 28),
                        label: Text(_selectedSymbol),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_candNameCtrl.text.isEmpty) return;
                    await provider.createCandidate(
                      _candNameCtrl.text.trim(),
                      _selectedSymbol,
                      null, // optional base64 photo
                    );
                    _candNameCtrl.clear();
                    setState(() {
                      // Cycle to next symbol automatically to save clicks
                      final idx = (ElectionSymbol.availableSymbols.indexOf(_selectedSymbol) + 1) %
                          ElectionSymbol.availableSymbols.length;
                      _selectedSymbol = ElectionSymbol.availableSymbols[idx];
                    });
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Candidate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Text(
                  'Candidate List:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (provider.db.candidates.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No candidates added yet. Add at least two.'),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.db.candidates.length,
                    itemBuilder: (ctx, idx) {
                      final cand = provider.db.candidates[idx];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo[100],
                          child: Text(cand.serialNumber.toString()),
                        ),
                        title: Text(cand.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElectionSymbol(name: cand.symbolName, size: 36),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => provider.deleteCandidate(cand.id),
                            )
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          // Step 3: Voters management
          Step(
            isActive: _currentStep >= 2,
            state: _currentStep == 2 ? StepState.editing : StepState.complete,
            title: const Text('Voters'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Import Student Voter Directory',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Paste CSV Area
                TextField(
                  controller: _csvPasteCtrl,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Paste CSV Format Voter Directory',
                    hintText: 'SerialNo, AdmissionNo, FullName\n1, ADM501, Aarav Sharma\n2, ADM502, Sneha Rao',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_csvPasteCtrl.text.isEmpty) return;
                    final count = await provider.importVotersFromCSV(_csvPasteCtrl.text);
                    _csvPasteCtrl.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Successfully imported $count voters!')),
                    );
                  },
                  icon: const Icon(Icons.file_download_rounded),
                  label: const Text('Parse & Add CSV List'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),

                // Add Single Voter Manually
                const Text(
                  'Or Add Single Voter Manually:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _voterSerialCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Serial No'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _voterAdmCtrl,
                        decoration: const InputDecoration(labelText: 'Adm No'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _voterNameCtrl,
                        decoration: const InputDecoration(labelText: 'Full Name'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _voterDivCtrl,
                        decoration: const InputDecoration(labelText: 'Div'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_voterAdmCtrl.text.isEmpty || _voterNameCtrl.text.isEmpty) return;
                    await provider.createVoter(
                      _voterSerialCtrl.text.trim(),
                      _voterAdmCtrl.text.trim(),
                      _voterNameCtrl.text.trim(),
                      _classCtrl.text.trim(),
                      _voterDivCtrl.text.trim(),
                    );
                    _voterAdmCtrl.clear();
                    _voterNameCtrl.clear();
                    _voterSerialCtrl.clear();
                  },
                  icon: const Icon(Icons.person_add_rounded),
                  label: const Text('Add Voter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  'Total Voters Registered: ${provider.db.voters.length}',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.indigo),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showSymbolGrid(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Choose Candidate Symbol'),
          content: SizedBox(
            width: 400,
            height: 300,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: ElectionSymbol.availableSymbols.length,
              itemBuilder: (context, idx) {
                final symbol = ElectionSymbol.availableSymbols[idx];
                return InkWell(
                  onTap: () {
                    setState(() => _selectedSymbol = symbol);
                    Navigator.pop(ctx);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElectionSymbol(name: symbol, size: 40),
                      const SizedBox(height: 4),
                      Text(
                        symbol,
                        style: const TextStyle(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _finishSetupAndHost(ElectionProvider provider) {
    if (provider.db.candidates.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 2 candidates to start.')),
      );
      return;
    }

    if (provider.db.voters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 1 voter to start.')),
      );
      return;
    }

    // Initialize Server Host Console
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const ControllerView(autoHost: true),
      ),
    );
  }
}
