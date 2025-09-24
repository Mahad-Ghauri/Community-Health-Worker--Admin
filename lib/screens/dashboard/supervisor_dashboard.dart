// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/theme.dart';
import '../../providers/supervisor_dashboard_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/dashboard_service.dart';

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
                        Text(
                          'Welcome, ${user?.name ?? 'Supervisor'}',
                          style: CHWTheme.subheadingStyle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // KPI cards (initial subset)
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _kpiCard(
                          'Follow-ups (Total)',
                          (stats?.total ?? 0).toString(),
                        ),
                        _kpiCard(
                          'Overdue Follow-ups',
                          (stats?.overdue ?? 0).toString(),
                        ),
                        _kpiCard(
                          'Newly Diagnosed',
                          (patientsByStatus['newly_diagnosed'] ?? 0).toString(),
                        ),
                        _kpiCard(
                          'On Treatment',
                          (patientsByStatus['on_treatment'] ?? 0).toString(),
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
                            'Top CHWs',
                            supProv.chwLeaderboard,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _facilityPerfCard(
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

Widget _kpiCard(String title, String value) {
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

Widget _leaderboardCard(String title, List<LeaderboardItem> items) {
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
        if (items.isEmpty)
          Text(
            'No data',
            style: CHWTheme.bodyStyle.copyWith(color: Colors.grey),
          ),
      ],
    ),
  );
}

Widget _facilityPerfCard(String title, List<FacilityPerformance> items) {
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
        if (items.isEmpty)
          Text(
            'No data',
            style: CHWTheme.bodyStyle.copyWith(color: Colors.grey),
          ),
      ],
    ),
  );
}
