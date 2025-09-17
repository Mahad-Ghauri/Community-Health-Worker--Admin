// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/followup_provider.dart';
import '../../../services/auth_provider.dart';
import '../../../models/followup.dart';
import '../../../models/patient.dart';

class CreateFollowupsScreen extends StatefulWidget {
  const CreateFollowupsScreen({super.key});

  @override
  State<CreateFollowupsScreen> createState() => _CreateFollowupsScreenState();
}

class _CreateFollowupsScreenState extends State<CreateFollowupsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Patient? _selectedPatient;
  DateTime? _selectedDateTime;
  String _selectedType = Followup.typeRoutineCheckup;
  String _selectedPriority = Followup.priorityRoutine;
  int? _duration;
  final TextEditingController _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Initialize facility context and load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final fup = context.read<FollowupProvider>();
      final facilityId = auth.currentUser?.facilityId;
      if (facilityId != null && facilityId.isNotEmpty) {
        fup.setFacilityId(facilityId);
        fup.loadPatients();
        fup.loadFollowups();
        fup.loadCHWUsers();
        fup.loadStatistics();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final fup = context.watch<FollowupProvider>();

    // Responsive text sizing
    final titleFontSize = screenWidth < 600
        ? 24.0
        : screenWidth < 1024
        ? 28.0
        : 32.0;
    final subtitleFontSize = screenWidth < 600
        ? 14.0
        : screenWidth < 1024
        ? 16.0
        : 18.0;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: screenWidth < 900
                  ? _buildMobile(context, fup, titleFontSize, subtitleFontSize)
                  : _buildDesktop(
                      context,
                      fup,
                      titleFontSize,
                      subtitleFontSize,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktop(
    BuildContext context,
    FollowupProvider fup,
    double titleFontSize,
    double subtitleFontSize,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildPatientPanel(
            context,
            fup,
            titleFontSize,
            subtitleFontSize,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: _buildForm(context, fup, titleFontSize, subtitleFontSize),
        ),
      ],
    );
  }

  Widget _buildMobile(
    BuildContext context,
    FollowupProvider fup,
    double titleFontSize,
    double subtitleFontSize,
  ) {
    return ListView(
      children: [
        _buildPatientPanel(context, fup, titleFontSize, subtitleFontSize),
        const SizedBox(height: 16),
        _buildForm(context, fup, titleFontSize, subtitleFontSize),
      ],
    );
  }

  Widget _buildPatientPanel(
    BuildContext context,
    FollowupProvider fup,
    double titleFontSize,
    double subtitleFontSize,
  ) {
    final patients = _searchCtrl.text.isEmpty
        ? fup.eligiblePatients
        : fup.patients.where((p) {
            final q = _searchCtrl.text.toLowerCase();
            return p.name.toLowerCase().contains(q) ||
                p.patientId.toLowerCase().contains(q) ||
                p.phone.toLowerCase().contains(q);
          }).toList();
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Patient',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Search by name, ID, or phone',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 380,
              child: patients.isEmpty
                  ? const Center(child: Text('No eligible patients found'))
                  : ListView.builder(
                      itemCount: patients.length,
                      itemBuilder: (context, i) {
                        final p = patients[i];
                        final selected =
                            _selectedPatient?.patientId == p.patientId;
                        return ListTile(
                          selected: selected,
                          title: Text('${p.name} (${p.patientId})'),
                          subtitle: Text(
                            '${p.gender}, ${p.age} • ${p.phone} • ${p.statusDisplayName}',
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : null,
                          onTap: () => setState(() => _selectedPatient = p),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    FollowupProvider fup,
    double titleFontSize,
    double subtitleFontSize,
  ) {
    final canSubmit = _selectedPatient != null && _selectedDateTime != null;
    final slotMin = fup.slotMinutes;
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule Follow-up',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Appointment Date & Time',
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedDateTime == null
                                ? 'Select...'
                                : '${_selectedDateTime!.toLocal()}',
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 90),
                              ),
                              initialDate: DateTime.now(),
                            );
                            if (date == null) return;
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(hour: 9, minute: 0),
                            );
                            if (time == null) return;
                            setState(() {
                              _selectedDateTime = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          },
                          icon: const Icon(Icons.event),
                          label: const Text('Pick'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 250,
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    items: Followup.allFollowupTypes
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.replaceAll('_', ' ').toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedType = v ?? _selectedType),
                    decoration: const InputDecoration(
                      labelText: 'Follow-up Type',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    value: _selectedPriority,
                    items: const [
                      DropdownMenuItem(
                        value: 'routine',
                        child: Text('Routine'),
                      ),
                      DropdownMenuItem(
                        value: 'important',
                        child: Text('Important'),
                      ),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                    ],
                    onChanged: (v) => setState(
                      () => _selectedPriority = v ?? _selectedPriority,
                    ),
                    decoration: const InputDecoration(labelText: 'Priority'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 200,
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Duration (min, default $slotMin)',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        setState(() => _duration = int.tryParse(v)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notes / Special Instructions',
                    ),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: !canSubmit || fup.isLoading
                      ? null
                      : () async {
                          final id = await fup.createFollowup(
                            patientId: _selectedPatient!.patientId,
                            createdBy: 'system',
                            scheduledDate: _selectedDateTime!,
                            followupType: _selectedType,
                            priority: _selectedPriority,
                            notes: _notesCtrl.text.trim(),
                            durationMinutes: _duration,
                          );
                          if (id != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Follow-up scheduled'),
                              ),
                            );
                            setState(() {
                              _selectedDateTime = null;
                              _notesCtrl.clear();
                            });
                          }
                        },
                  icon: const Icon(Icons.save),
                  label: Text(fup.isLoading ? 'Scheduling...' : 'Schedule'),
                ),
                const SizedBox(width: 12),
                Text(
                  fup.error == null ? '' : '${fup.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
