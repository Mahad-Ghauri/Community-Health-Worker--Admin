// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../models/followup.dart';
import '../../../providers/followup_provider.dart';

class ManageFollowupsScreen extends StatefulWidget {
  const ManageFollowupsScreen({super.key});

  @override
  State<ManageFollowupsScreen> createState() => _ManageFollowupsScreenState();
}

class _ManageFollowupsScreenState extends State<ManageFollowupsScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Set<String> _selectedIds = <String>{};

  @override
  void initState() {
    super.initState();
    final provider = context.read<FollowupProvider>();
    provider.selectDate(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FollowupProvider>();
    final isLoading = provider.isLoading;
    final calendarFollowups = provider.calendarFollowups;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Follow-ups'),
        actions: [
          IconButton(
            tooltip: 'Today',
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = _focusedDay;
              });
              provider.selectDate(_focusedDay);
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'View',
            onSelected: (v) {
              setState(() {
                _calendarFormat = v == 'Month'
                    ? CalendarFormat.month
                    : v == '2 Weeks'
                    ? CalendarFormat.twoWeeks
                    : CalendarFormat.week;
              });
            },
            itemBuilder: (c) => const [
              PopupMenuItem(value: 'Month', child: Text('Month View')),
              PopupMenuItem(value: '2 Weeks', child: Text('2-Week View')),
              PopupMenuItem(value: 'Week', child: Text('Week View')),
            ],
            icon: const Icon(Icons.calendar_view_month),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _FiltersBar(provider: provider),
                Expanded(
                  child: Column(
                    children: [
                      _buildCalendar(provider),
                      const Divider(height: 1),
                      Expanded(
                        child: _AgendaList(
                          followups: calendarFollowups,
                          selectedIds: _selectedIds,
                          onTap: _openFollowupDetails,
                          onToggleSelect: (id, selected) {
                            setState(() {
                              if (selected) {
                                _selectedIds.add(id);
                              } else {
                                _selectedIds.remove(id);
                              }
                            });
                          },
                          onMarkAttended: (f) => _markAttended(provider, f),
                          onMarkMissed: (f) => _markMissed(provider, f),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedIds.isNotEmpty)
                  _BulkActionsBar(
                    count: _selectedIds.length,
                    onClear: () => setState(() => _selectedIds.clear()),
                    onAttend: () => _bulkAttend(provider),
                    onMissed: () => _bulkMissed(provider),
                  ),
                if (isLoading) const LinearProgressIndicator(minHeight: 2),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 1,
            child: _Sidebar(provider: provider, onTapRow: _openFollowupDetails),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(FollowupProvider provider) {
    return TableCalendar<Followup>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2035, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      calendarFormat: _calendarFormat,
      eventLoader: (day) => provider.getFollowupsForDate(day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        provider.selectDate(selectedDay);
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (events.isEmpty) return const SizedBox.shrink();
          final List<Followup> ev = events.cast<Followup>();
          final int scheduled = ev.where((e) => e.isScheduled).length;
          final int completed = ev.where((e) => e.isCompleted).length;
          final int missed = ev.where((e) => e.isMissed).length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (scheduled > 0) _dot(Colors.blue),
                if (completed > 0) _dot(Colors.green),
                if (missed > 0) _dot(Colors.red),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: 8,
    height: 8,
    margin: const EdgeInsets.symmetric(horizontal: 2),
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  void _openFollowupDetails(Followup f) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _FollowupDetailsSheet(followup: f),
    );
  }

  Future<void> _markAttended(FollowupProvider p, Followup f) async {
    await p.completeFollowup(f.followupId, 'current_staff');
  }

  Future<void> _markMissed(FollowupProvider p, Followup f) async {
    await p.markMissed(f.followupId);
  }

  Future<void> _bulkAttend(FollowupProvider p) async {
    await p.bulkMarkAttended(_selectedIds.toList(), 'current_staff');
    setState(() => _selectedIds.clear());
  }

  Future<void> _bulkMissed(FollowupProvider p) async {
    await p.bulkMarkMissed(_selectedIds.toList());
    setState(() => _selectedIds.clear());
  }
}

class _FiltersBar extends StatelessWidget {
  final FollowupProvider provider;
  const _FiltersBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 240,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search notes/type...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: provider.searchFollowups,
              ),
            ),
            DropdownButton<String>(
              value: provider.selectedStatus,
              hint: const Text('Status'),
              onChanged: provider.filterByStatus,
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...Followup.allStatuses.map(
                  (s) => DropdownMenuItem(value: s, child: Text(s)),
                ),
              ],
            ),
            DropdownButton<String>(
              value: provider.selectedType,
              hint: const Text('Type'),
              onChanged: provider.filterByType,
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...Followup.allFollowupTypes.map(
                  (t) => DropdownMenuItem(value: t, child: Text(t)),
                ),
              ],
            ),
            DropdownButton<String>(
              value: provider.selectedPriority,
              hint: const Text('Priority'),
              onChanged: provider.filterByPriority,
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...Followup.allPriorities.map(
                  (p) => DropdownMenuItem(value: p, child: Text(p)),
                ),
              ],
            ),
            if (provider.hasActiveFilters)
              TextButton.icon(
                onPressed: provider.clearFilters,
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Clear filters'),
              ),
          ],
        ),
      ),
    );
  }
}

class _AgendaList extends StatelessWidget {
  final List<Followup> followups;
  final Set<String> selectedIds;
  final void Function(Followup) onTap;
  final void Function(String id, bool selected) onToggleSelect;
  final void Function(Followup) onMarkAttended;
  final void Function(Followup) onMarkMissed;

  const _AgendaList({
    required this.followups,
    required this.selectedIds,
    required this.onTap,
    required this.onToggleSelect,
    required this.onMarkAttended,
    required this.onMarkMissed,
  });

  @override
  Widget build(BuildContext context) {
    if (followups.isEmpty) {
      return const Center(child: Text('No appointments for selected day'));
    }
    return ListView.separated(
      itemCount: followups.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final f = followups[index];
        final selected = selectedIds.contains(f.followupId);
        final color = f.isCompleted
            ? Colors.green
            : f.isMissed
            ? Colors.red
            : f.isCancelled
            ? Colors.grey
            : f.isRescheduled
            ? Colors.orange
            : (f.isScheduled && f.isUrgentPriority)
            ? Colors.deepOrange
            : Colors.blue;
        return ListTile(
          onTap: () => onTap(f),
          leading: Checkbox(
            value: selected,
            onChanged: (v) => onToggleSelect(f.followupId, v ?? false),
          ),
          title: Text(
            '${f.formattedScheduledDateTime} • ${f.followupTypeDisplayName}',
          ),
          subtitle: Text(
            'Priority: ${f.priorityDisplayName} • Status: ${f.statusDisplayName}',
          ),
          trailing: Wrap(
            spacing: 8,
            children: [
              Icon(Icons.circle, color: color, size: 12),
              IconButton(
                tooltip: 'Mark Attended',
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: f.canBeCompleted ? () => onMarkAttended(f) : null,
              ),
              IconButton(
                tooltip: 'Mark Missed',
                icon: const Icon(Icons.cancel, color: Colors.redAccent),
                onPressed: f.isScheduled ? () => onMarkMissed(f) : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BulkActionsBar extends StatelessWidget {
  final int count;
  final VoidCallback onClear;
  final VoidCallback onAttend;
  final VoidCallback onMissed;

  const _BulkActionsBar({
    required this.count,
    required this.onClear,
    required this.onAttend,
    required this.onMissed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text('$count selected'),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: onAttend,
            icon: const Icon(Icons.check),
            label: const Text('Mark attended'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onMissed,
            icon: const Icon(Icons.close),
            label: const Text('Mark missed'),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear selection'),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final FollowupProvider provider;
  final void Function(Followup) onTapRow;
  const _Sidebar({required this.provider, required this.onTapRow});

  @override
  Widget build(BuildContext context) {
    final todays = provider.getTodaysFollowups();
    final missed = provider
        .getOverdueFollowups()
        .where((f) => f.isMissed || f.isOverdue)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SidebarSection(
          title: 'Today',
          count: todays.length,
          child: _SidebarList(followups: todays, onTapRow: onTapRow),
        ),
        const Divider(height: 1),
        _SidebarSection(
          title: 'Missed (7 days)',
          count: missed.length,
          child: _SidebarList(followups: missed, onTapRow: onTapRow),
        ),
      ],
    );
  }
}

class _SidebarSection extends StatelessWidget {
  final String title;
  final int count;
  final Widget child;
  const _SidebarSection({
    required this.title,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Text('$title', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 8),
                Chip(label: Text('$count')),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SidebarList extends StatelessWidget {
  final List<Followup> followups;
  final void Function(Followup) onTapRow;
  const _SidebarList({required this.followups, required this.onTapRow});

  @override
  Widget build(BuildContext context) {
    if (followups.isEmpty) {
      return const Center(child: Text('No items'));
    }
    return ListView.builder(
      itemCount: followups.length,
      itemBuilder: (context, idx) {
        final f = followups[idx];
        return ListTile(
          dense: true,
          title: Text(f.formattedScheduledDateTime),
          subtitle: Text(f.followupTypeDisplayName),
          trailing: Text(f.priorityDisplayName),
          onTap: () => onTapRow(f),
        );
      },
    );
  }
}

class _FollowupDetailsSheet extends StatelessWidget {
  final Followup followup;
  const _FollowupDetailsSheet({required this.followup});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<FollowupProvider>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    followup.followupTypeDisplayName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Chip(label: Text(followup.statusDisplayName)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Scheduled: ${followup.formattedScheduledDateTime}'),
            if (followup.notes != null && followup.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Notes: ${followup.notes}'),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: followup.canBeCompleted
                      ? () async {
                          await provider.completeFollowup(
                            followup.followupId,
                            'current_staff',
                          );
                          if (context.mounted) Navigator.pop(context);
                        }
                      : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Patient Attended'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: followup.isScheduled
                      ? () async {
                          await provider.markMissed(followup.followupId);
                          if (context.mounted) Navigator.pop(context);
                        }
                      : null,
                  icon: const Icon(Icons.close),
                  label: const Text('Patient Missed'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: followup.canBeRescheduled
                      ? () async {
                          final newDate = followup.scheduledDate.add(
                            const Duration(hours: 1),
                          );
                          await provider.rescheduleFollowup(
                            followup.followupId,
                            newDate,
                            'current_staff',
                          );
                          if (context.mounted) Navigator.pop(context);
                        }
                      : null,
                  icon: const Icon(Icons.schedule),
                  label: const Text('Reschedule +1h'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: followup.canBeCancelled
                      ? () async {
                          await provider.cancelFollowup(followup.followupId);
                          if (context.mounted) Navigator.pop(context);
                        }
                      : null,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
