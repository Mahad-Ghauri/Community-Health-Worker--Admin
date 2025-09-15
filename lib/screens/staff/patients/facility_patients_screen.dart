import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/facility_patients_provider.dart';
import '../../../services/patient_service.dart';
import '../../../services/auth_provider.dart';
import '../../../constants/app_constants.dart';
import '../../../utils/export_utils.dart';

class FacilityPatientsScreen extends StatelessWidget {
  const FacilityPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider?>();
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
            onPressed: () => provider.refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchAndFiltersBar(),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: provider.refresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.patients.length + 1,
                itemBuilder: (context, index) {
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
                          onPressed: provider.loadMore,
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
                              // TODO: open follow-up
                              break;
                            case 'visit':
                              // TODO: record visit
                              break;
                            case 'report':
                              // TODO: generate report
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
                    onPressed: () {
                      // TODO: mark LTFU bulk
                    },
                    icon: const Icon(Icons.warning_amber),
                    label: const Text('Mark LTFU'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      // TODO: transfer bulk
                    },
                    icon: const Icon(Icons.compare_arrows),
                    label: const Text('Transfer'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      // TODO: export selection
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
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<FacilityPatientsSort>(
                value: provider.sort,
                onChanged: (v) => v == null ? null : provider.setSort(v),
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
        provider.updateFilters(provider.filters.copyWith(tbStatuses: current));
      },
    );
  }
}
