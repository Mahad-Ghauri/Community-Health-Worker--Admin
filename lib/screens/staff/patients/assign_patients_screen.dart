// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/assignment_provider.dart';
import '../../../models/patient.dart';
import '../../../models/chw_user.dart';
import '../../../models/assignment.dart';
import '../../../services/auth_service.dart';

class AssignPatientsScreen extends StatefulWidget {
  const AssignPatientsScreen({super.key});

  @override
  State<AssignPatientsScreen> createState() => _AssignPatientsScreenState();
}

class _AssignPatientsScreenState extends State<AssignPatientsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _diagnosisDate;
  String _gender = 'male';
  String _tbStatus = 'newly_diagnosed';

  int _currentStep = 0;
  Patient? _selectedPatient;
  CHWUser? _selectedCHW;
  String _priority = Assignment.priorityMedium;
  final _authService = AuthService();

  // Add this flag to prevent multiple navigation calls
  bool _isProcessing = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AssignmentProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Assign Patients to CHW')),
          body: Stepper(
            currentStep: _currentStep,
            controlsBuilder: (context, details) {
              return Row(
                children: [
                  if (details.stepIndex < 2)
                    ElevatedButton(
                      onPressed: _isProcessing ? null : details.onStepContinue,
                      child: _isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Continue'),
                    )
                  else
                    ElevatedButton(
                      onPressed: _isProcessing ? null : details.onStepContinue,
                      child: _isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create Assignment'),
                    ),
                  const SizedBox(width: 8),
                  if (details.stepIndex > 0)
                    TextButton(
                      onPressed: _isProcessing ? null : details.onStepCancel,
                      child: const Text('Back'),
                    ),
                ],
              );
            },
            onStepContinue: () async {
              if (_isProcessing) return;

              if (_currentStep == 0) {
                if (_selectedPatient != null) {
                  setState(() => _currentStep = 1);
                } else {
                  if (_formKey.currentState?.validate() == true) {
                    setState(() => _isProcessing = true);
                    try {
                      final userId = _authService.currentUser?.uid ?? '';
                      final exists = await provider.phoneExists(
                        _phoneCtrl.text.trim(),
                      );
                      if (exists) {
                        _showSnack(context, 'Phone already exists');
                        return;
                      }
                      final id = await provider.createPatient(
                        name: _nameCtrl.text.trim(),
                        age: int.tryParse(_ageCtrl.text.trim()) ?? 0,
                        phone: _phoneCtrl.text.trim(),
                        address: _addressCtrl.text.trim(),
                        gender: _gender,
                        tbStatus: _tbStatus,
                        diagnosisDate: _diagnosisDate,
                        createdBy: userId,
                      );
                      if (id != null) {
                        final doc = await provider.searchPatients(id);
                        if (doc.isNotEmpty) {
                          setState(() {
                            _selectedPatient = doc.first;
                            _currentStep = 1;
                          });
                        }
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isProcessing = false);
                      }
                    }
                  }
                }
              } else if (_currentStep == 1) {
                if (_selectedCHW != null) {
                  setState(() => _currentStep = 2);
                } else {
                  _showSnack(context, 'Select a CHW');
                }
              } else if (_currentStep == 2) {
                await _confirmAssignment(context, provider);
              }
            },
            onStepCancel: () {
              if (_currentStep > 0 && !_isProcessing) {
                setState(() => _currentStep -= 1);
              }
            },
            steps: [
              Step(
                title: const Text('Patient'),
                isActive: _currentStep >= 0,
                state: _currentStep > 0
                    ? StepState.complete
                    : StepState.indexed,
                content: _buildPatientStep(context, provider),
              ),
              Step(
                title: const Text('CHW'),
                isActive: _currentStep >= 1,
                state: _currentStep > 1
                    ? StepState.complete
                    : StepState.indexed,
                content: _buildCHWStep(context, provider),
              ),
              Step(
                title: const Text('Confirm'),
                isActive: _currentStep >= 2,
                content: _buildConfirmStep(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPatientStep(BuildContext context, AssignmentProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _searchCtrl,
          decoration: const InputDecoration(
            labelText: 'Search existing patient (name / phone / ID)',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) async {
            if (v.trim().length < 2) return;
            final results = await provider.searchPatients(v.trim());
            if (!mounted) return;
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) {
                return DraggableScrollableSheet(
                  initialChildSize: 0.5,
                  minChildSize: 0.25,
                  maxChildSize: 0.9,
                  builder: (_, controller) {
                    return Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Search Results',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              controller: controller,
                              itemCount: results.length,
                              itemBuilder: (ctx, i) {
                                final p = results[i];
                                return ListTile(
                                  title: Text(p.name),
                                  subtitle: Text('${p.patientId} • ${p.phone}'),
                                  onTap: () {
                                    setState(() {
                                      _selectedPatient = p;
                                    });
                                    Navigator.of(ctx).pop();
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
        const SizedBox(height: 16),
        if (_selectedPatient != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(_selectedPatient!.name),
              subtitle: Text(
                'ID: ${_selectedPatient!.patientId} • ${_selectedPatient!.tbStatus}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() => _selectedPatient = null),
              ),
            ),
          )
        else
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) =>
                      (v == null ||
                          v.trim().length < 2 ||
                          v.trim().length > 100)
                      ? 'Enter 2-100 chars'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age'),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 1 || n > 120) return '1-120';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone (+92-XXX-XXXXXXX)',
                  ),
                  validator: (v) {
                    final re = RegExp(r'^\+?\d[\d\-]{9,}$');
                    if (v == null || !re.hasMatch(v)) return 'Invalid phone';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Address'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty || v.length > 500)
                      ? 'Required, max 500'
                      : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _gender,
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(
                            value: 'female',
                            child: Text('Female'),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _gender = v ?? 'male'),
                        decoration: const InputDecoration(labelText: 'Gender'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _tbStatus,
                        items: const [
                          DropdownMenuItem(
                            value: 'newly_diagnosed',
                            child: Text('Newly Diagnosed'),
                          ),
                          DropdownMenuItem(
                            value: 'on_treatment',
                            child: Text('On Treatment'),
                          ),
                          DropdownMenuItem(
                            value: 'treatment_completed',
                            child: Text('Completed'),
                          ),
                          DropdownMenuItem(
                            value: 'lost_to_followup',
                            child: Text('Lost to Follow-up'),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _tbStatus = v ?? 'newly_diagnosed'),
                        decoration: const InputDecoration(
                          labelText: 'TB Status',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Diagnosis Date',
                        ),
                        child: InkWell(
                          onTap: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _diagnosisDate ?? now,
                              firstDate: DateTime(now.year - 5),
                              lastDate: now,
                            );
                            if (picked != null) {
                              setState(() => _diagnosisDate = picked);
                            }
                          },
                          child: Text(
                            _diagnosisDate == null
                                ? 'Select date'
                                : '${_diagnosisDate!.day}/${_diagnosisDate!.month}/${_diagnosisDate!.year}',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCHWStep(BuildContext context, AssignmentProvider provider) {
    return FutureBuilder<void>(
      future: provider.loadAvailableCHWs(),
      builder: (context, snapshot) {
        final chws = provider.availableCHWs;
        if (chws.isEmpty) {
          return const Text('No active CHWs found for this facility.');
        }

        // Group CHWs by workingArea
        final groupedChws = <String, List<CHWUser>>{};
        for (final chw in chws) {
          final area = chw.workingArea.isNotEmpty
              ? chw.workingArea
              : 'Unknown Area';
          groupedChws.putIfAbsent(area, () => []).add(chw);
        }

        return SizedBox(
          height: 400,
          child: ListView.builder(
            itemCount: groupedChws.length,
            itemBuilder: (context, areaIndex) {
              final area = groupedChws.keys.elementAt(areaIndex);
              final areaChws = groupedChws[area]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      area,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: areaChws.length,
                    itemBuilder: (context, index) {
                      final chw = areaChws[index];
                      final load = provider.getPatientCountForCHW(chw.userId);
                      final color = load < 20
                          ? Colors.green
                          : load <= 30
                          ? Colors.orange
                          : Colors.red;
                      final selected = _selectedCHW?.userId == chw.userId;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: selected
                            ? Theme.of(context).colorScheme.secondaryContainer
                            : null,
                        child: ListTile(
                          onTap: () => setState(() => _selectedCHW = chw),
                          leading: CircleAvatar(
                            child: Text(
                              chw.name.isNotEmpty ? chw.name[0] : '?',
                            ),
                          ),
                          title: Text(chw.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(chw.idNumber),
                              Row(
                                children: [
                                  Icon(Icons.circle, size: 10, color: color),
                                  const SizedBox(width: 6),
                                  Text('Load: $load'),
                                ],
                              ),
                            ],
                          ),
                          trailing: selected
                              ? Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildConfirmStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedPatient != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(_selectedPatient!.name),
              subtitle: Text('ID: ${_selectedPatient!.patientId}'),
            ),
          ),
        if (_selectedCHW != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.badge),
              title: Text(_selectedCHW!.name),
              subtitle: Text('Area: ${_selectedCHW!.workingArea}'),
            ),
          ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _priority,
          items: Assignment.allPriorities
              .map(
                (p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase())),
              )
              .toList(),
          onChanged: (v) =>
              setState(() => _priority = v ?? Assignment.priorityMedium),
          decoration: const InputDecoration(labelText: 'Priority'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _notesCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAssignment(
    BuildContext context,
    AssignmentProvider provider,
  ) async {
    if (_isProcessing) return;

    print('DEBUG: Starting assignment confirmation');

    if (_selectedPatient == null || _selectedCHW == null) {
      print('DEBUG: Missing patient or CHW');
      _showSnack(context, 'Select patient and CHW');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      print(
        'DEBUG: Patient selected: ${_selectedPatient!.name} (ID: ${_selectedPatient!.patientId})',
      );
      print(
        'DEBUG: CHW selected: ${_selectedCHW!.name} (ID: ${_selectedCHW!.userId})',
      );

      final canAssign = provider.chwHasCapacity(
        _selectedCHW!.userId,
        maxPatients: 30,
      );

      print('DEBUG: CHW has capacity: $canAssign');

      if (!canAssign) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('CHW at capacity'),
            content: const Text(
              'Selected CHW is at full capacity (>30). Proceed anyway?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Proceed'),
              ),
            ],
          ),
        );

        if (proceed != true) return;
      }

      final userId = _authService.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        print('DEBUG: ERROR - No authenticated user found');
        if (mounted) {
          _showSnack(context, 'Authentication error - please login again');
        }
        return;
      }

      print('DEBUG: Calling createAssignment');
      final assignmentId = await provider.createAssignment(
        chwId: _selectedCHW!.userId,
        patientIds: [_selectedPatient!.patientId],
        assignedBy: userId,
        workArea: _selectedCHW!.workingArea,
        priority: _priority,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      if (!mounted) return; // Critical check before any UI operations

      if (assignmentId != null) {
        print('DEBUG: Assignment created successfully with ID: $assignmentId');

        // Show success message first
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment created successfully'),
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back after a short delay to ensure snackbar is shown
        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop(true);
        }
      } else {
        print('DEBUG: ERROR - createAssignment returned null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to create assignment - check logs for details',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('DEBUG: EXCEPTION during createAssignment: $e');
      print('DEBUG: Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating assignment: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSnack(BuildContext context, String msg) {
    if (!mounted) return;
    print('DEBUG: Showing snackbar: $msg');

    // Direct snackbar call without WidgetsBinding.instance.addPostFrameCallback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }
}
