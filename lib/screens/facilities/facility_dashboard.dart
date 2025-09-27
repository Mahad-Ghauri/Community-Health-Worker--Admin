// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_constants.dart';
import '../../providers/facility_provider.dart';
import '../../utils/responsive_helper.dart';

class FacilityDashboard extends StatefulWidget {
  final String facilityId;

  const FacilityDashboard({super.key, required this.facilityId});

  @override
  State<FacilityDashboard> createState() => _FacilityDashboardState();
}

class _FacilityDashboardState extends State<FacilityDashboard> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _metrics = {};
  List<Map<String, dynamic>> _recentActivities = [];
  List<Map<String, dynamic>> _adherenceData = [];
  DateTime _lastRefresh = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    // Set up auto-refresh timer
    Future.delayed(const Duration(minutes: 5), _refreshData);
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final facilityProvider = Provider.of<FacilityProvider>(
        context,
        listen: false,
      );

      // Load facility metrics
      final metrics = await facilityProvider.getFacilityMetrics(
        widget.facilityId,
      );

      // Load recent activities
      final activities = await facilityProvider.getFacilityActivities(
        widget.facilityId,
      );

      // Load treatment adherence data for chart
      final adherenceData = await facilityProvider.getTreatmentAdherenceData(
        widget.facilityId,
      );

      setState(() {
        _metrics = metrics;
        _recentActivities = activities;
        _adherenceData = adherenceData;
        _lastRefresh = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load dashboard data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadDashboardData();
    // Schedule next refresh
    if (mounted) {
      Future.delayed(const Duration(minutes: 5), _refreshData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(
            ResponsiveHelper.isDesktop(context) ? 24 : 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(responsive),
              const SizedBox(height: 24),

              if (_isLoading && _metrics.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                _buildErrorMessage()
              else
                ..._buildDashboardContent(responsive),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ResponsiveHelper responsive) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Facility Dashboard',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Monitoring TB treatment progress',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.update, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Last updated: ${_formatLastUpdated()}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          IconButton(
            onPressed: _refreshData,
            icon: Icon(Icons.refresh, color: Colors.blue[600]),
            tooltip: 'Refresh Dashboard',
          ),
      ],
    );
  }

  List<Widget> _buildDashboardContent(ResponsiveHelper responsive) {
    return [
      _buildMetricsGrid(context),
      const SizedBox(height: 24),
      _buildTreatmentProgressChart(responsive),
      const SizedBox(height: 24),
      _buildRecentActivitiesFeed(responsive),
      const SizedBox(height: 24),
      _buildQuickActionsPanel(responsive),
    ];
  }

  Widget _buildMetricsGrid(BuildContext context) {
    final crossAxisCount = ResponsiveHelper.isDesktop(context)
        ? 4
        : (ResponsiveHelper.isTablet(context) ? 2 : 1);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: ResponsiveHelper.isDesktop(context) ? 1.3 : 1.5,
      children: [
        _buildMetricCard(
          title: 'Total Patients',
          value: _metrics['totalPatients']?.toString() ?? '0',
          subtitle: 'Receiving treatment at this facility',
          icon: Icons.people,
          color: Colors.blue,
          trend: _metrics['patientsTrend'] ?? 0.0,
        ),
        _buildMetricCard(
          title: 'Active Treatments',
          value: _metrics['onTreatment']?.toString() ?? '0',
          subtitle: 'Patients currently on treatment',
          icon: Icons.medication,
          color: Colors.green,
          trend: _metrics['treatmentTrend'] ?? 0.0,
        ),
        _buildMetricCard(
          title: 'Pending Referrals',
          value: _metrics['pendingReferrals']?.toString() ?? '0',
          subtitle: 'Awaiting approval',
          icon: Icons.assignment_late,
          color: Colors.orange,
          trend: _metrics['referralsTrend'] ?? 0.0,
          isWarning: true,
        ),
        _buildMetricCard(
          title: 'Lost to Follow-up',
          value: _metrics['lostToFollowUp']?.toString() ?? '0',
          subtitle: 'Patients requiring intervention',
          icon: Icons.warning,
          color: Colors.red,
          trend: _metrics['ltfuTrend'] ?? 0.0,
          isError: true,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double trend,
    bool isWarning = false,
    bool isError = false,
  }) {
    return InkWell(
      onTap: () {
        // Navigate to relevant screen based on metric type
        if (title == 'Total Patients') {
          // Navigate to patients list
        } else if (title == 'Pending Referrals') {
          context.go(AppConstants.referralsRoute);
        } else if (title == 'Lost to Follow-up') {
          // Navigate to LTFU patients list
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isError
              ? Border.all(color: Colors.red.shade200, width: 1)
              : isWarning
              ? Border.all(color: Colors.orange.shade200, width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                if (trend != 0.0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (trend >= 0 && !isError && !isWarning)
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (trend >= 0 && !isError && !isWarning)
                              ? Icons.trending_up
                              : Icons.trending_down,
                          size: 12,
                          color: (trend >= 0 && !isError && !isWarning)
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${trend.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: (trend >= 0 && !isError && !isWarning)
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isError
                    ? Colors.red
                    : isWarning
                    ? Colors.orange
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentProgressChart(ResponsiveHelper responsive) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Treatment Progress',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              DropdownButton<String>(
                value: 'weekly',
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(
                    value: 'quarterly',
                    child: Text('Quarterly'),
                  ),
                ],
                onChanged: (value) {
                  // Change chart time range
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: _adherenceData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No treatment data available',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : _buildAdherenceChart(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  // Export chart data
                },
                icon: const Icon(Icons.download),
                label: const Text('Export Data'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdherenceChart() {
    // This is a placeholder for the chart
    // In a real implementation, you would use a chart library like fl_chart
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'Treatment Adherence Chart',
          style: TextStyle(color: Colors.grey[500]),
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesFeed(ResponsiveHelper responsive) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Recent Activities',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigate to full activity log
                    context.go(AppConstants.auditLogsRoute);
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _recentActivities.isEmpty
              ? SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No recent activities',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentActivities.length > 5
                      ? 5
                      : _recentActivities.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final activity = _recentActivities[index];
                    return _buildActivityItem(activity);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    IconData icon;
    Color color;

    switch (activity['type']) {
      case 'visit':
        icon = Icons.home_work;
        color = Colors.blue;
        break;
      case 'assignment':
        icon = Icons.assignment_ind;
        color = Colors.green;
        break;
      case 'referral':
        icon = Icons.compare_arrows;
        color = Colors.orange;
        break;
      case 'followup':
        icon = Icons.event_note;
        color = Colors.purple;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        activity['title'] ?? 'Activity',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        activity['description'] ?? '',
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: Text(
        _formatActivityTime(activity['timestamp'] ?? DateTime.now()),
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      ),
      onTap: () {
        // Navigate to activity details
      },
    );
  }

  Widget _buildQuickActionsPanel(ResponsiveHelper responsive) {
    final buttonWidth = ResponsiveHelper.isDesktop(context)
        ? 200.0
        : (ResponsiveHelper.isTablet(context) ? 160.0 : double.infinity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: buttonWidth,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to assign patients
                    context.go(AppConstants.assignPatientsRoute);
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Assign New Patient'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              SizedBox(
                width: buttonWidth,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to schedule follow-up
                    context.go(AppConstants.createFollowupsRoute);
                  },
                  icon: const Icon(Icons.event),
                  label: const Text('Schedule Follow-up'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
              SizedBox(
                width: buttonWidth,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to referrals
                    context.go(AppConstants.referralsRoute);
                  },
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('View Referrals'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.orange,
                  ),
                ),
              ),
              SizedBox(
                width: buttonWidth,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Generate reports
                  },
                  icon: const Icon(Icons.summarize),
                  label: const Text('Generate Reports'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.purple,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Error Loading Dashboard',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            style: TextStyle(color: Colors.red[600]),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                  });
                },
                child: const Text('Dismiss'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _refreshData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatLastUpdated() {
    final now = DateTime.now();
    final difference = now.difference(_lastRefresh);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return DateFormat('MMM d, y HH:mm').format(_lastRefresh);
    }
  }

  String _formatActivityTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }
}
