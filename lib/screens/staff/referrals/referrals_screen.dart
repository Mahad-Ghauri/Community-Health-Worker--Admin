// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/referral.dart';
import '../../../providers/referral_provider.dart';
import '../../../services/auth_provider.dart';
import '../../../widgets/common_widgets.dart' as cw;

class ReferralsScreen extends StatefulWidget {
  const ReferralsScreen({super.key});

  @override
  State<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends State<ReferralsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  DateTime? _selectedApptDate; // temp holder for dialog

  @override
  void initState() {
    super.initState();
    // Initialize provider with facility context and load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final referralProv = context.read<ReferralProvider>();
      final facilityId = auth.currentUser?.facilityId;
      if (facilityId != null && facilityId.isNotEmpty) {
        referralProv.setFacilityId(facilityId);
        referralProv.loadReferrals();
        referralProv.loadStatistics();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Referrals'),
        actions: [_SortControls(), const SizedBox(width: 8)],
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          children: [
            _TopBar(searchCtrl: _searchCtrl),
            const SizedBox(height: 12),
            Expanded(
              child: Consumer<ReferralProvider>(
                builder: (context, refProv, _) {
                  if (refProv.isLoading && refProv.referrals.isEmpty) {
                    return const cw.LoadingWidget(
                      message: 'Loading referrals...',
                    );
                  }
                  if (refProv.error != null) {
                    return cw.ErrorWidget(
                      message: refProv.error!,
                      onRetry: () {
                        refProv.clearError();
                        refProv.loadReferrals();
                      },
                    );
                  }

                  final items = refProv.filteredReferrals;
                  if (items.isEmpty) {
                    return const cw.EmptyStateWidget(
                      title: 'No referrals',
                      message: 'There are no referrals matching your filters.',
                      icon: Icon(
                        Icons.assignment_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final r = items[index];
                      return _ReferralCard(
                        referral: r,
                        onAccept: () => _showAcceptDialog(context, r),
                        onDecline: () => _showDeclineDialog(context, r),
                        onComplete: r.isAccepted
                            ? () => _showCompleteDialog(context, r)
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAcceptDialog(
    BuildContext context,
    Referral referral,
  ) async {
    final auth = context.read<AuthProvider>();
    final refProv = context.read<ReferralProvider>();
    final notesCtrl = TextEditingController();
    final assignedCtrl = TextEditingController(
      text: auth.currentUser?.userId ?? '',
    );
    _selectedApptDate = null;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Accept Referral'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reason: ${referral.referralReason}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: assignedCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Staff ID (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedApptDate == null
                                ? 'No appointment date'
                                : 'Appointment: ${_formatDate(_selectedApptDate!)}',
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.event),
                          label: const Text('Pick date'),
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: ctx,
                              firstDate: DateTime(now.year - 1),
                              lastDate: DateTime(now.year + 2),
                              initialDate: now,
                            );
                            if (picked != null) {
                              setState(() => _selectedApptDate = picked);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final userId = auth.currentUser?.userId;
                    if (userId == null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('You must be signed in.'),
                          ),
                        );
                      }
                      return;
                    }

                    final success = await refProv.acceptReferral(
                      referral.referralId,
                      userId,
                      notes: notesCtrl.text.trim().isEmpty
                          ? null
                          : notesCtrl.text.trim(),
                      appointmentDate: _selectedApptDate,
                      assignedStaffId: assignedCtrl.text.trim().isEmpty
                          ? null
                          : assignedCtrl.text.trim(),
                      staffUserName: auth.currentUser?.name,
                      // Passing names optionally if the caller has them; we only have IDs here
                    );

                    if (mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Referral accepted'
                                : 'Failed to accept referral',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Accept'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDeclineDialog(
    BuildContext context,
    Referral referral,
  ) async {
    final auth = context.read<AuthProvider>();
    final refProv = context.read<ReferralProvider>();
    final reasonCtrl = TextEditingController();
    final suggestionsCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Decline Referral'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reason: ${referral.referralReason}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Decline reason (required)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: suggestionsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Suggestions (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final userId = auth.currentUser?.userId;
                final reason = reasonCtrl.text.trim();
                if (userId == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You must be signed in.')),
                    );
                  }
                  return;
                }
                if (reason.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Decline reason is required.'),
                      ),
                    );
                  }
                  return;
                }

                final success = await refProv.declineReferral(
                  referral.referralId,
                  userId,
                  reason,
                  suggestions: suggestionsCtrl.text.trim().isEmpty
                      ? null
                      : suggestionsCtrl.text.trim(),
                  staffUserName: auth.currentUser?.name,
                );

                if (mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Referral declined'
                            : 'Failed to decline referral',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Decline'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCompleteDialog(
    BuildContext context,
    Referral referral,
  ) async {
    final auth = context.read<AuthProvider>();
    final refProv = context.read<ReferralProvider>();
    final outcomeCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Complete Referral'),
          content: TextField(
            controller: outcomeCtrl,
            decoration: const InputDecoration(
              labelText: 'Outcome (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final userId = auth.currentUser?.userId;
                if (userId == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You must be signed in.')),
                    );
                  }
                  return;
                }

                final success = await refProv.completeReferral(
                  referral.referralId,
                  userId,
                  outcome: outcomeCtrl.text.trim().isEmpty
                      ? null
                      : outcomeCtrl.text.trim(),
                );
                if (mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Referral completed'
                            : 'Failed to complete referral',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Complete'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _TopBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  const _TopBar({required this.searchCtrl});

  @override
  Widget build(BuildContext context) {
    final refProv = context.watch<ReferralProvider>();
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: searchCtrl,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search referral reason, symptoms, notes...',
              border: OutlineInputBorder(),
            ),
            onChanged: refProv.searchReferrals,
          ),
        ),
        if (!isMobile) const SizedBox(width: 12),
        if (!isMobile)
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: refProv.selectedStatus?.isNotEmpty == true
                  ? refProv.selectedStatus
                  : null,
              hint: const Text('Status'),
              items: const [
                DropdownMenuItem(
                  value: Referral.statusPending,
                  child: Text('Pending'),
                ),
                DropdownMenuItem(
                  value: Referral.statusAccepted,
                  child: Text('Accepted'),
                ),
                DropdownMenuItem(
                  value: Referral.statusDeclined,
                  child: Text('Declined'),
                ),
                DropdownMenuItem(
                  value: Referral.statusCompleted,
                  child: Text('Completed'),
                ),
              ],
              onChanged: (v) => refProv.filterByStatus(v),
            ),
          ),
        if (!isMobile) const SizedBox(width: 12),
        if (!isMobile)
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: refProv.selectedUrgency?.isNotEmpty == true
                  ? refProv.selectedUrgency
                  : null,
              hint: const Text('Urgency'),
              items: const [
                DropdownMenuItem(
                  value: Referral.urgencyLow,
                  child: Text('Low'),
                ),
                DropdownMenuItem(
                  value: Referral.urgencyMedium,
                  child: Text('Medium'),
                ),
                DropdownMenuItem(
                  value: Referral.urgencyHigh,
                  child: Text('High'),
                ),
                DropdownMenuItem(
                  value: Referral.urgencyUrgent,
                  child: Text('Urgent'),
                ),
              ],
              onChanged: (v) => refProv.filterByUrgency(v),
            ),
          ),
        if (!isMobile) const SizedBox(width: 8),
        if (!isMobile)
          TextButton(
            onPressed: refProv.clearFilters,
            child: const Text('Clear filters'),
          ),
      ],
    );
  }
}

class _SortControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final refProv = context.watch<ReferralProvider>();
    return Row(
      children: [
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: refProv.sortField,
            items: const [
              DropdownMenuItem(
                value: 'createdAt',
                child: Text('Sort: Created'),
              ),
              DropdownMenuItem(value: 'urgency', child: Text('Sort: Urgency')),
              DropdownMenuItem(
                value: 'referralDate',
                child: Text('Sort: Referral Date'),
              ),
            ],
            onChanged: (v) {
              if (v != null) {
                refProv.setSort(field: v, descending: refProv.sortDesc);
              }
            },
          ),
        ),
        IconButton(
          tooltip: refProv.sortDesc ? 'Descending' : 'Ascending',
          icon: Icon(
            refProv.sortDesc ? Icons.arrow_downward : Icons.arrow_upward,
          ),
          onPressed: () => refProv.setSort(
            field: refProv.sortField,
            descending: !refProv.sortDesc,
          ),
        ),
      ],
    );
  }
}

class _ReferralCard extends StatelessWidget {
  final Referral referral;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback? onComplete;

  const _ReferralCard({
    required this.referral,
    required this.onAccept,
    required this.onDecline,
    this.onComplete,
  });

  Color _urgencyColor(BuildContext context) {
    switch (referral.urgency) {
      case Referral.urgencyLow:
        return Colors.green;
      case Referral.urgencyMedium:
        return Colors.orange;
      case Referral.urgencyHigh:
        return Colors.red;
      case Referral.urgencyUrgent:
        return Colors.purple;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _urgencyColor(context);
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withOpacity(0.35)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bolt, size: 16, color: color),
                      const SizedBox(width: 6),
                      Text(
                        referral.urgencyDisplayName,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: referral.statusDisplayName,
                  child: Chip(
                    label: Text(referral.statusDisplayName),
                    backgroundColor: Colors.grey.shade100,
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              referral.referralReason,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (referral.symptoms != null && referral.symptoms!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Symptoms: ${referral.symptoms}',
                style: textTheme.bodyMedium?.copyWith(color: Colors.black87),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Referred: ${referral.formattedReferralDate}',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
                if (referral.appointmentDate != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'Appt: ${_formatDate(referral.appointmentDate!)}',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                if (referral.assignedStaffId != null &&
                    referral.assignedStaffId!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.badge, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'Assigned: ${referral.assignedStaffId}',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (referral.canBeAccepted)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Accept'),
                    onPressed: onAccept,
                  ),
                const SizedBox(width: 8),
                if (referral.canBeDeclined)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Decline'),
                    onPressed: onDecline,
                  ),
                const Spacer(),
                if (onComplete != null)
                  TextButton.icon(
                    icon: const Icon(Icons.done_all),
                    label: const Text('Complete'),
                    onPressed: onComplete,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
