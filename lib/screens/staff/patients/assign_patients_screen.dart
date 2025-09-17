// ignore_for_file: deprecated_member_use, use_build_context_synchronously

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
            onStepContinue: () async {
              if (_currentStep == 0) {
                if (_selectedPatient != null) {
                  setState(() => _currentStep = 1);
                } else {
                  if (_formKey.currentState?.validate() == true) {
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
              if (_currentStep > 0) {
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
              builder: (_) {
                return ListView.builder(
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
                            if (picked != null)
                              setState(() => _diagnosisDate = picked);
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
        return SizedBox(
          height: 320,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3,
            ),
            itemCount: chws.length,
            itemBuilder: (context, index) {
              final chw = chws[index];
              final load = provider.getPatientCountForCHW(chw.userId);
              final color = load < 20
                  ? Colors.green
                  : load <= 30
                  ? Colors.orange
                  : Colors.red;
              final selected = _selectedCHW?.userId == chw.userId;
              return InkWell(
                onTap: () => setState(() => _selectedCHW = chw),
                child: Card(
                  color: selected
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          child: Text(chw.name.isNotEmpty ? chw.name[0] : '?'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                chw.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                chw.workingArea,
                                style: const TextStyle(fontSize: 12),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.circle, size: 10, color: color),
                                  const SizedBox(width: 6),
                                  Text('Load: $load'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(_selectedPatient!.name),
            subtitle: Text('ID: ${_selectedPatient!.patientId}'),
          ),
        if (_selectedCHW != null)
          ListTile(
            leading: const Icon(Icons.badge),
            title: Text(_selectedCHW!.name),
            subtitle: Text('Area: ${_selectedCHW!.workingArea}'),
          ),
        const SizedBox(height: 8),
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
        const SizedBox(height: 8),
        TextField(
          controller: _notesCtrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Notes (optional)'),
        ),
      ],
    );
  }

  Future<void> _confirmAssignment(
    BuildContext context,
    AssignmentProvider provider,
  ) async {
    if (_selectedPatient == null || _selectedCHW == null) {
      _showSnack(context, 'Select patient and CHW');
      return;
    }
    final canAssign = provider.chwHasCapacity(
      _selectedCHW!.userId,
      maxPatients: 30,
    );
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
    final assignmentId = await provider.createAssignment(
      chwId: _selectedCHW!.userId,
      patientIds: [_selectedPatient!.patientId],
      assignedBy: userId,
      workArea: _selectedCHW!.workingArea,
      priority: _priority,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    if (assignmentId != null) {
      if (mounted) {
        _showSnack(context, 'Assignment created');
        Navigator.of(context).pop(true);
      }
    } else {
      _showSnack(context, 'Failed to create assignment');
    }
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

