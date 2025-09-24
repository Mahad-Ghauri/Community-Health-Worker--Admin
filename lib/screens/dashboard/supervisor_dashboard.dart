// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/theme.dart';
import '../../providers/supervisor_dashboard_provider.dart';

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
                    _sectionTitle('Trends & Distributions'),
                    _placeholderBox(height: 220, label: 'Charts go here'),
                    const SizedBox(height: 16),
                    _sectionTitle('Leaderboards'),
                    _placeholderBox(
                      height: 220,
                      label: 'Top CHWs / Facilities',
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

Widget _placeholderBox({double height = 180, required String label}) {
  return Container(
    height: height,
    width: double.infinity,
    decoration: BoxDecoration(
      color: CHWTheme.backgroundColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Center(
      child: Text(
        label,
        style: CHWTheme.bodyStyle.copyWith(color: Colors.grey),
      ),
    ),
  );
}
