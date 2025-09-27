// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/theme.dart';
import '../../providers/supervisor_dashboard_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/dashboard_service.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_constants.dart';
import 'package:flutter/services.dart';
// import 'package:go_router/go_router.dart';
// import '../../constants/app_constants.dart';

class SupervisorDashboard extends StatelessWidget {
  const SupervisorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CHWTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Supervisor Dashboard'),
        backgroundColor: CHWTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'logout':
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  await authProvider.signOut();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: CHWTheme.errorColor),
                  title: Text(
                    'Logout',
                    style: TextStyle(color: CHWTheme.errorColor),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => SupervisorDashboardProvider()..load(),
          ),
        ],
        child: Consumer2<AuthProvider, SupervisorDashboardProvider>(
          builder: (context, authProvider, supProv, child) {
            final user = authProvider.currentUser;

            if (supProv.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (supProv.error != null) {
              return Center(
                child: Text(
                  supProv.error!,
                  style: CHWTheme.bodyStyle.copyWith(
                    color: CHWTheme.errorColor,
                  ),
                ),
              );
            }

            final stats = supProv.followupStats;
            final patientsByStatus = supProv.patientsByStatus;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Supervisor Dashboard',
                          style: CHWTheme.headingStyle.copyWith(
                            color: CHWTheme.primaryColor,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Welcome, ${user?.name ?? 'Supervisor'}',
                              style: CHWTheme.subheadingStyle,
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () => supProv.load(),
                              child: const Text('Refresh'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Filters
                    _filtersBar(context, supProv),
                    const SizedBox(height: 16),

                    // KPI cards (with View details)
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _kpiCard(
                          'Follow-ups (Total)',
                          (stats?.total ?? 0).toString(),
                          onViewDetails: () =>
                              _showDetails(context, 'followups', supProv),
                        ),
                        _kpiCard(
                          'Overdue Follow-ups',
                          (stats?.overdue ?? 0).toString(),
                          onViewDetails: () =>
                              _showDetails(context, 'overdue', supProv),
                        ),
                        _kpiCard(
                          'Newly Diagnosed',
                          (patientsByStatus['newly_diagnosed'] ?? 0).toString(),
                          onViewDetails: () =>
                              _showDetails(context, 'newly_diagnosed', supProv),
                        ),
                        _kpiCard(
                          'On Treatment',
                          (patientsByStatus['on_treatment'] ?? 0).toString(),
                          onViewDetails: () =>
                              _showDetails(context, 'on_treatment', supProv),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Placeholders for charts/leaderboards to be implemented next
                    _sectionTitle('Distributions'),
                    Row(
                      children: [
                        Expanded(
                          child: _pieCard(
                            title: 'TB Status',
                            sections: _tbStatusSections(patientsByStatus),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _pieCard(
                            title: 'Follow-up Status',
                            sections: _followupSections(stats),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle('Leaderboards'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _leaderboardCard(
                            context,
                            'Top CHWs',
                            supProv.chwLeaderboard,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _facilityPerfCard(
                            context,
                            'Facility Performance',
                            supProv.facilityPerformance,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

void _showDetails(
  BuildContext context,
  String type,
  SupervisorDashboardProvider supProv,
) {
  final stats = supProv.followupStats;
  final patientsByStatus = supProv.patientsByStatus;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _detailsTitle(type),
                  style: CHWTheme.subheadingStyle.copyWith(
                    color: CHWTheme.primaryColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (type == 'followups' && stats != null) ...[
              _detailsRow('Total', stats.total.toString()),
              _detailsRow('Completed', stats.completed.toString()),
              _detailsRow('Scheduled', stats.scheduled.toString()),
              _detailsRow('Missed', stats.missed.toString()),
              _detailsRow('Rescheduled', stats.rescheduled.toString()),
              _detailsRow('Cancelled', stats.cancelled.toString()),
              _detailsRow('Overdue', stats.overdue.toString()),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go(AppConstants.manageFollowupsRoute);
                  },
                  child: const Text('Manage Follow-ups'),
                ),
              ),
            ] else if (type == 'overdue' && stats != null) ...[
              _detailsRow('Overdue', stats.overdue.toString()),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go(AppConstants.manageFollowupsRoute);
                  },
                  child: const Text('View Overdue'),
                ),
              ),
            ] else if (type == 'newly_diagnosed') ...[
              _detailsRow(
                'Newly Diagnosed',
                (patientsByStatus['newly_diagnosed'] ?? 0).toString(),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go(AppConstants.supervisorPatientsRoute);
                  },
                  child: const Text('View Patients'),
                ),
              ),
            ] else if (type == 'on_treatment') ...[
              _detailsRow(
                'On Treatment',
                (patientsByStatus['on_treatment'] ?? 0).toString(),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go(AppConstants.supervisorPatientsRoute);
                  },
                  child: const Text('View Patients'),
                ),
              ),
            ] else ...[
              Text(
                'No details available',
                style: CHWTheme.bodyStyle.copyWith(color: Colors.grey),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}

String _detailsTitle(String type) {
  switch (type) {
    case 'followups':
      return 'Follow-ups Summary';
    case 'overdue':
      return 'Overdue Follow-ups';
    case 'newly_diagnosed':
      return 'Newly Diagnosed Patients';
    case 'on_treatment':
      return 'Patients On Treatment';
    default:
      return 'Details';
  }
}

Widget _detailsRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: CHWTheme.bodyStyle.copyWith(color: Colors.grey.shade700),
        ),
        Text(
          value,
          style: CHWTheme.bodyStyle.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

Widget _kpiCard(String title, String value, {VoidCallback? onViewDetails}) {
  return Container(
    width: 220,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: CHWTheme.bodyStyle.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: CHWTheme.headingStyle.copyWith(color: CHWTheme.primaryColor),
        ),
        const SizedBox(height: 12),
        TextButton(onPressed: onViewDetails, child: const Text('View details')),
      ],
    ),
  );
}

Widget _sectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(
      title,
      style: CHWTheme.subheadingStyle.copyWith(color: CHWTheme.primaryColor),
    ),
  );
}

// (placeholder removed)

Widget _pieCard({
  required String title,
  required List<PieChartSectionData> sections,
}) {
  return Container(
    height: 260,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: CHWTheme.subheadingStyle.copyWith(
            color: CHWTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: sections,
            ),
          ),
        ),
      ],
    ),
  );
}

List<PieChartSectionData> _tbStatusSections(Map<String, int> counts) {
  final total = counts.values.fold<int>(0, (a, b) => a + b);
  if (total == 0) {
    return [
      PieChartSectionData(
        value: 1,
        color: Colors.grey.shade300,
        title: 'No Data',
        radius: 50,
      ),
    ];
  }
  return [
    PieChartSectionData(
      value: counts['newly_diagnosed']?.toDouble() ?? 0,
      color: const Color(0xFF42A5F5),
      title: '',
    ),
    PieChartSectionData(
      value: counts['on_treatment']?.toDouble() ?? 0,
      color: const Color(0xFF66BB6A),
      title: '',
    ),
    PieChartSectionData(
      value: counts['treatment_completed']?.toDouble() ?? 0,
      color: const Color(0xFFFFB300),
      title: '',
    ),
    PieChartSectionData(
      value: counts['lost_to_followup']?.toDouble() ?? 0,
      color: const Color(0xFFEF5350),
      title: '',
    ),
  ];
}

List<PieChartSectionData> _followupSections(FollowupStats? stats) {
  if (stats == null || stats.total == 0) {
    return [
      PieChartSectionData(
        value: 1,
        color: Colors.grey.shade300,
        title: 'No Data',
        radius: 50,
      ),
    ];
  }
  return [
    PieChartSectionData(
      value: stats.completed.toDouble(),
      color: const Color(0xFF66BB6A),
      title: '',
    ),
    PieChartSectionData(
      value: stats.scheduled.toDouble(),
      color: const Color(0xFF42A5F5),
      title: '',
    ),
    PieChartSectionData(
      value: stats.missed.toDouble(),
      color: const Color(0xFFEF5350),
      title: '',
    ),
    PieChartSectionData(
      value: stats.rescheduled.toDouble(),
      color: const Color(0xFFFFB300),
      title: '',
    ),
    PieChartSectionData(
      value: stats.cancelled.toDouble(),
      color: const Color(0xFF9E9E9E),
      title: '',
    ),
  ];
}

Widget _leaderboardCard(
  BuildContext context,
  String title,
  List<LeaderboardItem> items,
) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: CHWTheme.subheadingStyle.copyWith(
            color: CHWTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        ...items
            .take(8)
            .map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: InkWell(
                  onTap: () {
                    context.go(AppConstants.supervisorPatientsRoute);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(e.label, style: CHWTheme.bodyStyle)),
                      Text(
                        e.score.toString(),
                        style: CHWTheme.bodyStyle.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        if (items.isEmpty)
          Text(
            'No data',
            style: CHWTheme.bodyStyle.copyWith(color: Colors.grey),
          ),
      ],
    ),
  );
}

Widget _facilityPerfCard(
  BuildContext context,
  String title,
  List<FacilityPerformance> items,
) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: CHWTheme.subheadingStyle.copyWith(
                color: CHWTheme.primaryColor,
              ),
            ),
            TextButton(
              onPressed: () async {
                final buffer = StringBuffer();
                buffer.writeln('Facility ID,Patients,Completed Follow-ups');
                for (final e in items) {
                  buffer.writeln(
                    '${e.facilityId},${e.patients},${e.completedFollowups}',
                  );
                }
                await Clipboard.setData(ClipboardData(text: buffer.toString()));
              },
              child: const Text('Copy CSV'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items
            .take(8)
            .map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: InkWell(
                  onTap: () {
                    context.go(AppConstants.facilityPatientsRoute);
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(e.facilityId, style: CHWTheme.bodyStyle),
                      ),
                      Text(
                        'Patients: ${e.patients}',
                        style: CHWTheme.bodyStyle.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Completed: ${e.completedFollowups}',
                        style: CHWTheme.bodyStyle.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        if (items.isEmpty)
          Text(
            'No data',
            style: CHWTheme.bodyStyle.copyWith(color: Colors.grey),
          ),
      ],
    ),
  );
}

Widget _filtersBar(BuildContext context, SupervisorDashboardProvider supProv) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _filterChip(
          label: 'Last 30 days',
          selected: supProv.from != null,
          onTap: () {
            final now = DateTime.now();
            supProv.setDateRange(now.subtract(const Duration(days: 30)), now);
          },
        ),
        _filterChip(
          label: 'This Month',
          selected: supProv.from != null,
          onTap: () {
            final now = DateTime.now();
            final start = DateTime(now.year, now.month, 1);
            supProv.setDateRange(start, now);
          },
        ),
        _filterChip(
          label: 'Clear',
          selected: false,
          onTap: () {
            supProv.setDateRange(null, null);
          },
        ),
      ],
    ),
  );
}

Widget _filterChip({
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  return ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
  );
}
