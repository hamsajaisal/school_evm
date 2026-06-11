// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<ElectionProvider>(context, listen: false);
        final assigned = provider.db.candidates.map((c) => c.symbolName).toSet();
        if (assigned.contains(_selectedSymbol)) {
          for (var sym in ElectionSymbol.availableSymbols) {
            if (!assigned.contains(sym)) {
              setState(() {
                _selectedSymbol = sym;
              });
              break;
            }
          }
        }
      }
    });
  }

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
        onStepTapped: (step) {
          setState(() => _currentStep = step);
          SemanticsService.announce("${step == 0 ? 'Details' : step == 1 ? 'Candidates' : 'Voters'} step selected", TextDirection.ltr);
        },
        onStepContinue: () {
          if (_currentStep < 2) {
            final nextStep = _currentStep + 1;
            setState(() => _currentStep = nextStep);
            SemanticsService.announce("${nextStep == 0 ? 'Details' : nextStep == 1 ? 'Candidates' : 'Voters'} step selected", TextDirection.ltr);
          } else {
            // Setup Complete, launch controller hosting
            _finishSetupAndHost(provider);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            final prevStep = _currentStep - 1;
            setState(() => _currentStep = prevStep);
            SemanticsService.announce("${prevStep == 0 ? 'Details' : prevStep == 1 ? 'Candidates' : 'Voters'} step selected", TextDirection.ltr);
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
            title: Semantics(
              selected: _currentStep == 0,
              child: const Text('Details'),
            ),
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
                    SemanticsService.announce("Election details saved successfully", TextDirection.ltr);
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
            title: Semantics(
              selected: _currentStep == 1,
              child: const Text('Candidates'),
            ),
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
                      child: Semantics(
                        label: 'Symbol picker. Current selected symbol is $_selectedSymbol.',
                        button: true,
                        onTap: () => _showSymbolGrid(context),
                        excludeSemantics: true,
                        child: OutlinedButton.icon(
                          onPressed: () => _showSymbolGrid(context),
                          icon: ElectionSymbol(name: _selectedSymbol, size: 28),
                          label: Text(_selectedSymbol),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_candNameCtrl.text.isEmpty) return;
                    final candName = _candNameCtrl.text.trim();
                    await provider.createCandidate(
                      candName,
                      _selectedSymbol,
                      null, // optional base64 photo
                    );
                    _candNameCtrl.clear();
                    SemanticsService.announce("Candidate $candName added successfully with symbol $_selectedSymbol", TextDirection.ltr);
                    setState(() {
                      final assignedSymbols = provider.db.candidates.map((c) => c.symbolName).toSet();
                      assignedSymbols.add(_selectedSymbol); // also exclude the one we just added
                      
                      String nextSym = _selectedSymbol;
                      final allSymbols = ElectionSymbol.availableSymbols;
                      int startIdx = allSymbols.indexOf(_selectedSymbol);
                      for (int i = 1; i <= allSymbols.length; i++) {
                        final checkSym = allSymbols[(startIdx + i) % allSymbols.length];
                        if (!assignedSymbols.contains(checkSym)) {
                          nextSym = checkSym;
                          break;
                        }
                      }
                      _selectedSymbol = nextSym;
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
                              tooltip: 'Delete candidate ${cand.name}',
                              onPressed: () {
                                provider.deleteCandidate(cand.id);
                                SemanticsService.announce("Candidate ${cand.name} deleted successfully", TextDirection.ltr);
                              },
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
            title: Semantics(
              selected: _currentStep == 2,
              child: const Text('Voters'),
            ),
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
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (_csvPasteCtrl.text.isEmpty) return;
                        final count = await provider.importVotersFromCSV(_csvPasteCtrl.text);
                        _csvPasteCtrl.clear();
                        SemanticsService.announce("Successfully imported $count voters from CSV", TextDirection.ltr);
                        if (!context.mounted) return;
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
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['xlsx', 'xls'],
                            withData: true,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            final file = result.files.first;
                            final bytes = file.bytes;
                            if (bytes != null) {
                              final count = await provider.importVotersFromExcel(bytes);
                              SemanticsService.announce("Successfully imported $count voters from Excel", TextDirection.ltr);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Successfully imported $count voters from Excel!')),
                              );
                            } else {
                              throw 'Could not read file bytes.';
                            }
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error importing Excel: $e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.table_chart_rounded),
                      label: const Text('Import Excel (.xlsx)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
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
                    final voterName = _voterNameCtrl.text.trim();
                    await provider.createVoter(
                      _voterSerialCtrl.text.trim(),
                      _voterAdmCtrl.text.trim(),
                      voterName,
                      _classCtrl.text.trim(),
                      _voterDivCtrl.text.trim(),
                    );
                    _voterAdmCtrl.clear();
                    _voterNameCtrl.clear();
                    _voterSerialCtrl.clear();
                    SemanticsService.announce("Voter $voterName added successfully", TextDirection.ltr);
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
    final provider = Provider.of<ElectionProvider>(context, listen: false);
    final assignedSymbols = provider.db.candidates.map((c) => c.symbolName).toSet();

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
                final isAssigned = assignedSymbols.contains(symbol);
                return Semantics(
                  label: isAssigned 
                      ? '$symbol symbol. Already chosen by another candidate.' 
                      : '$symbol symbol. Double tap to select.',
                  button: !isAssigned,
                  enabled: !isAssigned,
                  excludeSemantics: true,
                  child: Opacity(
                    opacity: isAssigned ? 0.35 : 1.0,
                    child: InkWell(
                      onTap: isAssigned 
                          ? null 
                          : () {
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
                            style: TextStyle(
                              fontSize: 10,
                              decoration: isAssigned ? TextDecoration.lineThrough : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          )
                        ],
                      ),
                    ),
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
