// ignore_for_file: use_build_context_synchronously, duplicate_ignore, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/facility_patients_provider.dart';
import '../../../services/patient_service.dart';
import '../../../services/auth_provider.dart';
import '../../../constants/app_constants.dart';
import '../../../utils/export_utils.dart';
import '../../../services/followup_service.dart';
import '../../../services/visit_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/patient_service.dart' as ps;

class FacilityPatientsScreen extends StatelessWidget {
  const FacilityPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider?>();
    final facilityId = auth?.currentUser?.facilityId ?? '';

    return ChangeNotifierProvider(
      create: (_) =>
          FacilityPatientsProvider(patientService: PatientService())
            ..init(facilityId),
      child: const _FacilityPatientsView(),
    );
  }
}

class _FacilityPatientsView extends StatelessWidget {
  const _FacilityPatientsView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FacilityPatientsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Facility Patients'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: provider.patients.isEmpty
                ? null
                : () {
                    debugPrint(
                      '[FacilityPatients] Export CSV (all rows): count=${provider.patients.length}',
                    );
                    final csv = ExportUtils.generatePatientsCsv(
                      provider.patients,
                    );
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('CSV Preview'),
                        content: SizedBox(
                          width: 600,
                          child: SingleChildScrollView(
                            child: SelectableText(csv),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
            icon: const Icon(Icons.download),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              debugPrint('[FacilityPatients] Refresh pressed');
              provider.refresh();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchAndFiltersBar(),
          const Divider(height: 1),
          if (provider.error != null)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.error.withOpacity(0.1),
              padding: const EdgeInsets.all(12),
              child: Text(
                provider.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: provider.refresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount:
                    (provider.patients.isEmpty &&
                        !provider.isLoading &&
                        provider.error == null)
                    ? 1
                    : provider.patients.length + 1,
                itemBuilder: (context, index) {
                  if (provider.patients.isEmpty &&
                      !provider.isLoading &&
                      provider.error == null) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text('No patients found for this facility.'),
                      ),
                    );
                  }
                  if (index == provider.patients.length) {
                    if (provider.isLoading) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (provider.hasMore) {
                      return Center(
                        child: TextButton(
                          onPressed: () {
                            debugPrint('[FacilityPatients] Load more pressed');
                            provider.loadMore();
                          },
                          child: const Text('Load more'),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }

                  final p = provider.patients[index];
                  final selected = provider.selectedIds.contains(p.patientId);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Checkbox(
                        value: selected,
                        onChanged: (_) => provider.toggleSelect(p.patientId),
                      ),
                      title: Text(p.name),
                      subtitle: Text(
                        '${p.gender} • ${p.age} • ${p.phone}\nStatus: ${p.statusDisplayName}',
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              Navigator.of(context).pushNamed(
                                '${AppConstants.patientDetailsRoute}/${p.patientId}',
                              );
                              break;
                            case 'followup':
                              debugPrint(
                                '[FacilityPatients] QuickAction: schedule follow-up for ${p.patientId}',
                              );
                              _showScheduleFollowupDialog(context, p.patientId);
                              break;
                            case 'visit':
                              debugPrint(
                                '[FacilityPatients] QuickAction: record visit for ${p.patientId}',
                              );
                              _showRecordVisitDialog(context, p.patientId);
                              break;
                            case 'report':
                              debugPrint(
                                '[FacilityPatients] QuickAction: generate report for ${p.patientId}',
                              );
                              _showPatientReportDialog(context, p);
                              break;
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit Patient'),
                          ),
                          PopupMenuItem(
                            value: 'followup',
                            child: Text('Schedule Follow-up'),
                          ),
                          PopupMenuItem(
                            value: 'visit',
                            child: Text('Record Visit'),
                          ),
                          PopupMenuItem(
                            value: 'report',
                            child: Text('Generate Report'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: provider.selectedIds.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Row(
                children: [
                  Text('${provider.selectedIds.length} selected'),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      debugPrint(
                        '[FacilityPatients] Bulk action: Mark LTFU for ${provider.selectedIds.length}',
                      );
                      await _bulkMarkLtfu(
                        context,
                        provider.selectedIds.toList(),
                      );
                      // After action, refresh and clear selection
                      // ignore: use_build_context_synchronously
                      context.read<FacilityPatientsProvider>().clearSelection();
                      // ignore: use_build_context_synchronously
                      await context.read<FacilityPatientsProvider>().refresh();
                    },
                    icon: const Icon(Icons.warning_amber),
                    label: const Text('Mark LTFU'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () async {
                      debugPrint(
                        '[FacilityPatients] Bulk action: Transfer ${provider.selectedIds.length}',
                      );
                      await _bulkTransferDialog(
                        context,
                        provider.selectedIds.toList(),
                      );
                    },
                    icon: const Icon(Icons.compare_arrows),
                    label: const Text('Transfer'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      debugPrint(
                        '[FacilityPatients] Export CSV (selection): count=${provider.selectedIds.length}',
                      );
                      final selected = provider.patients
                          .where(
                            (p) => provider.selectedIds.contains(p.patientId),
                          )
                          .toList();
                      final csv = ExportUtils.generatePatientsCsv(selected);
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('CSV Preview (Selection)'),
                          content: SizedBox(
                            width: 600,
                            child: SingleChildScrollView(
                              child: SelectableText(csv),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Export'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SearchAndFiltersBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FacilityPatientsProvider>();
    final controller = TextEditingController(text: provider.searchTerm);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Search by name, ID, phone, address',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.clear();
                        provider.setSearchTerm('');
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: provider.setSearchTerm,
                  onSubmitted: (_) => debugPrint(
                    '[FacilityPatients] Search submit: ${controller.text}',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<FacilityPatientsSort>(
                value: provider.sort,
                onChanged: (v) {
                  if (v != null) {
                    debugPrint('[FacilityPatients] Sort changed: $v');
                    provider.setSort(v);
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: FacilityPatientsSort.nameAsc,
                    child: Text('Name A-Z'),
                  ),
                  DropdownMenuItem(
                    value: FacilityPatientsSort.nameDesc,
                    child: Text('Name Z-A'),
                  ),
                  DropdownMenuItem(
                    value: FacilityPatientsSort.registrationNewest,
                    child: Text('Newest'),
                  ),
                  DropdownMenuItem(
                    value: FacilityPatientsSort.registrationOldest,
                    child: Text('Oldest'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusFilterChip(
                label: 'Newly Diagnosed',
                value: 'newly_diagnosed',
              ),
              _StatusFilterChip(label: 'On Treatment', value: 'on_treatment'),
              _StatusFilterChip(
                label: 'Completed',
                value: 'treatment_completed',
              ),
              _StatusFilterChip(label: 'LTFU', value: 'lost_to_followup'),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _showScheduleFollowupDialog(
  BuildContext context,
  String patientId,
) async {
  final facilityId =
      context.read<AuthProvider?>()?.currentUser?.facilityId ?? '';
  final service = FollowupService();
  final typeController = TextEditingController();
  final purposeController = TextEditingController();
  DateTime? scheduledAt = DateTime.now().add(const Duration(days: 1));

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Schedule Follow-up'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: typeController,
            decoration: const InputDecoration(
              labelText: 'Type (e.g., Follow-up)',
            ),
          ),
          TextField(
            controller: purposeController,
            decoration: const InputDecoration(labelText: 'Purpose'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('When: '),
              const SizedBox(width: 8),
              Text(scheduledAt != null ? scheduledAt.toString() : ''),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: scheduledAt ?? now,
                    firstDate: now.subtract(const Duration(days: 1)),
                    lastDate: now.add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    final time = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.fromDateTime(scheduledAt ?? now),
                    );
                    if (time != null) {
                      scheduledAt = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        time.hour,
                        time.minute,
                      );
                      // ignore: use_build_context_synchronously
                      (ctx as Element).markNeedsBuild();
                    }
                  }
                },
                child: const Text('Pick date/time'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final data = {
              'patientId': patientId,
              'facilityId': facilityId,
              'type': typeController.text.trim().isEmpty
                  ? 'Follow-up'
                  : typeController.text.trim(),
              'purpose': purposeController.text.trim(),
              'scheduledAt': Timestamp.fromDate(
                scheduledAt ?? DateTime.now().add(const Duration(days: 1)),
              ),
              'status': 'scheduled',
              'remindersSent': 0,
            };
            debugPrint('[FacilityPatients] Scheduling follow-up: $data');
            await service.scheduleFollowup(data);
            // ignore: use_build_context_synchronously
            Navigator.of(ctx).pop();
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Follow-up scheduled')),
            );
          },
          child: const Text('Schedule'),
        ),
      ],
    ),
  );
}

Future<void> _showRecordVisitDialog(
  BuildContext context,
  String patientId,
) async {
  final facilityId =
      context.read<AuthProvider?>()?.currentUser?.facilityId ?? '';
  final service = VisitService();
  final visitTypeController = TextEditingController();
  final notesController = TextEditingController();
  bool found = true;
  DateTime visitDate = DateTime.now();

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Record Visit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: visitTypeController,
              decoration: const InputDecoration(
                labelText: 'Type (home/follow-up/tracing)',
              ),
            ),
            Row(
              children: [
                const Text('Found patient'),
                const Spacer(),
                Switch(
                  value: found,
                  onChanged: (v) => setState(() => found = v),
                ),
              ],
            ),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Date: '),
                const SizedBox(width: 8),
                Text(visitDate.toString()),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: visitDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) {
                      final time = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(visitDate),
                      );
                      if (time != null) {
                        setState(
                          () => visitDate = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            time.hour,
                            time.minute,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Pick date/time'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'patientId': patientId,
                'facilityId': facilityId,
                'visitType': visitTypeController.text.trim().isEmpty
                    ? 'home'
                    : visitTypeController.text.trim(),
                'found': found,
                'notes': notesController.text.trim(),
                'visitDate': Timestamp.fromDate(visitDate),
              };
              debugPrint('[FacilityPatients] Recording visit: $data');
              await service.createVisit(data);
              // ignore: use_build_context_synchronously
              Navigator.of(ctx).pop();
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Visit recorded')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FacilityPatientsProvider>();
    final isSelected = provider.filters.tbStatuses.contains(value);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        final current = Set<String>.from(provider.filters.tbStatuses);
        if (selected) {
          current.add(value);
        } else {
          current.remove(value);
        }
        debugPrint(
          '[FacilityPatients] Filter chip toggled: $value => $selected',
        );
        provider.updateFilters(provider.filters.copyWith(tbStatuses: current));
      },
    );
  }
}

void _showPatientReportDialog(BuildContext context, dynamic patient) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Patient Report'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: SelectableText(
            'Patient Summary\n\n'
            'ID: ${patient.patientId}\n'
            'Name: ${patient.name}\n'
            'Gender: ${patient.gender}\n'
            'Age: ${patient.age}\n'
            'Phone: ${patient.phone}\n'
            'Address: ${patient.address}\n'
            'TB Status: ${patient.statusDisplayName}\n'
            'Facility: ${patient.treatmentFacility}\n'
            'Assigned CHW: ${patient.assignedCHW}\n',
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

Future<void> _bulkMarkLtfu(
  BuildContext context,
  List<String> patientIds,
) async {
  final service = ps.PatientService();
  try {
    final updates = <String, Map<String, dynamic>>{};
    for (final id in patientIds) {
      updates[id] = {'tbStatus': AppConstants.lostToFollowUpStatus};
    }
    debugPrint('[FacilityPatients] bulkUpdatePatients LTFU: ${updates.length}');
    await service.bulkUpdatePatients(updates);
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Marked ${patientIds.length} as LTFU')),
    );
  } catch (e) {
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Failed to mark LTFU: $e')));
  }
}

Future<void> _bulkTransferDialog(
  BuildContext context,
  List<String> patientIds,
) async {
  final facilityController = TextEditingController();
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Transfer Patients'),
      content: TextField(
        controller: facilityController,
        decoration: const InputDecoration(
          labelText: 'New Facility ID',
          hintText: 'e.g., fac002',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final newId = facilityController.text.trim();
            if (newId.isEmpty) return;
            debugPrint(
              '[FacilityPatients] Bulk transfer to $newId for ${patientIds.length} patients',
            );
            final service = ps.PatientService();
            final updates = <String, Map<String, dynamic>>{};
            for (final id in patientIds) {
              updates[id] = {'treatmentFacility': newId};
            }
            await service.bulkUpdatePatients(updates);
            // ignore: use_build_context_synchronously
            Navigator.of(ctx).pop();
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Transferred ${patientIds.length} patients'),
              ),
            );
            // ignore: use_build_context_synchronously
            context.read<FacilityPatientsProvider>().clearSelection();
            // ignore: use_build_context_synchronously
            await context.read<FacilityPatientsProvider>().refresh();
          },
          child: const Text('Transfer'),
        ),
      ],
    ),
  );
}
