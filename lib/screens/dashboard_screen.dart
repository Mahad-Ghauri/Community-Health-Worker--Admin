// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;
import '../providers/dashboard_provider.dart';
import '../services/patient_service.dart';
import '../utils/export_utils.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboardProvider = Provider.of<DashboardProvider>(
        context,
        listen: false,
      );
      dashboardProvider.loadMetrics();
      dashboardProvider.startAutoRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Consumer<DashboardProvider>(
          builder: (context, dashboardProvider, child) {
            return RefreshIndicator(
              onRefresh: dashboardProvider.refreshMetrics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(dashboardProvider),
                    const SizedBox(height: 24),
                    if (dashboardProvider.isLoading &&
                        !dashboardProvider.hasData)
                      const Center(child: CircularProgressIndicator())
                    else if (dashboardProvider.error != null)
                      _buildErrorCard(dashboardProvider)
                    else if (dashboardProvider.hasData)
                      ..._buildDashboardContent(dashboardProvider)
                    else
                      _buildEmptyState(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(DashboardProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHW TB Management',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Admin Dashboard',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (provider.isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else ...[
              IconButton(
                onPressed: () => _showExportDialog(context),
                icon: Icon(Icons.download, color: Colors.green[600]),
                tooltip: 'Export Patient Data',
              ),
              IconButton(
                onPressed: provider.refreshMetrics,
                icon: Icon(Icons.refresh, color: Colors.blue[600]),
                tooltip: 'Refresh Dashboard',
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.schedule, size: 16, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              'Last updated: ${provider.lastRefreshText}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(
                  provider.systemHealthStatus,
                ).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStatusColor(provider.systemHealthStatus),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _getStatusColor(provider.systemHealthStatus),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    provider.systemHealthStatus,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getStatusColor(provider.systemHealthStatus),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Excellent':
        return Colors.green;
      case 'Good':
        return Colors.blue;
      case 'Fair':
        return Colors.orange;
      case 'Needs Attention':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<Widget> _buildDashboardContent(DashboardProvider provider) {
    return [
      _buildMetricsGrid(provider),
      const SizedBox(height: 24),
      _buildChartsSection(provider),
      const SizedBox(height: 24),
      _buildRecentActivity(provider),
    ];
  }

  Widget _buildMetricsGrid(DashboardProvider provider) {
    final metrics = provider.metrics!;
    final width = MediaQuery.of(context).size.width;
    // Responsive grid settings for small screens to prevent overflow
    final isVeryNarrow = width < 340;
    final isNarrow = width < 380;
    final crossAxisCount = isVeryNarrow ? 1 : 2;
    final childAspectRatio = isVeryNarrow
        ? 0.85 // single column, make cards taller to prevent overflow
        : (isNarrow
              ? 0.75 // two columns: taller on narrow phones to prevent overflow
              : 1.2); // normal aspect ratio for wider screens

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: childAspectRatio,
      children: [
        _buildMetricCard(
          title: 'Total Users',
          value: metrics.usersMetrics.totalUsers.toString(),
          subtitle: '${metrics.usersMetrics.activeToday} active today',
          icon: Icons.people,
          color: Colors.blue,
          growth: provider.usersGrowthPercentage,
        ),
        _buildMetricCard(
          title: 'Facilities',
          value: metrics.facilitiesMetrics.totalFacilities.toString(),
          subtitle: '${metrics.facilitiesMetrics.activeFacilities} active',
          icon: Icons.local_hospital,
          color: Colors.green,
          growth: provider.facilitiesGrowthPercentage,
        ),
        _buildMetricCard(
          title: 'Patients',
          value: metrics.patientsMetrics.totalPatients.toString(),
          subtitle: '${metrics.patientsMetrics.onTreatment} on treatment',
          icon: Icons.person,
          color: Colors.orange,
          growth: provider.patientsGrowthPercentage,
        ),
        _buildMetricCard(
          title: 'Total Visits',
          value: metrics.visitsMetrics.totalVisits.toString(),
          subtitle: '${metrics.visitsMetrics.thisWeekVisits} this week',
          icon: Icons.assignment,
          color: Colors.purple,
          growth: provider.visitsGrowthPercentage,
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
    required double growth,
  }) {
    final width = MediaQuery.of(context).size.width;
    final isVeryNarrow = width < 340;
    
    // Responsive padding and spacing
    final cardPadding = isVeryNarrow ? 10.0 : 12.0;
    final iconPadding = isVeryNarrow ? 6.0 : 8.0;
    final iconSize = isVeryNarrow ? 18.0 : 20.0;
    final titleFontSize = isVeryNarrow ? 11.0 : 12.0;
    final valueFontSize = isVeryNarrow ? 18.0 : 20.0;
    final subtitleFontSize = isVeryNarrow ? 10.0 : 11.0;
    final verticalSpacing = isVeryNarrow ? 4.0 : 6.0;
    
    return Container(
      padding: EdgeInsets.all(cardPadding),
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: iconSize),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: growth >= 0
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      growth >= 0 ? Icons.trending_up : Icons.trending_down,
                      size: 12,
                      color: growth >= 0 ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${growth.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: growth >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: verticalSpacing),
          Text(
            title,
            style: TextStyle(
              fontSize: titleFontSize,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: subtitleFontSize,
                color: Colors.grey[600],
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(DashboardProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Overview',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
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
            children: [
              _buildSystemHealthIndicator(provider),
              const SizedBox(height: 20),
              _buildDistributionChart(provider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSystemHealthIndicator(DashboardProvider provider) {
    final indicators = provider.performanceIndicators;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Health Indicators',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildIndicatorChip('Users Active', indicators['hasUsers']!),
            _buildIndicatorChip(
              'Facilities Online',
              indicators['hasFacilities']!,
            ),
            _buildIndicatorChip(
              'Patients Registered',
              indicators['hasPatients']!,
            ),
            _buildIndicatorChip(
              'Recent Activity',
              indicators['hasRecentActivity']!,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIndicatorChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionChart(DashboardProvider provider) {
    final metrics = provider.metrics!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data Distribution',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDistributionBar(
                'CHWs',
                metrics.usersMetrics.staffUsers,
                metrics.usersMetrics.totalUsers,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDistributionBar(
                'Supervisors',
                metrics.usersMetrics.supervisorUsers,
                metrics.usersMetrics.totalUsers,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDistributionBar(
                'Admins',
                metrics.usersMetrics.adminUsers,
                metrics.usersMetrics.totalUsers,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDistributionBar(
    String label,
    int value,
    int total,
    Color color,
  ) {
    final percentage = total > 0 ? (value / total) : 0.0;

    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                FractionallySizedBox(
                  heightFactor: 1,
                  widthFactor: percentage,
                  child: Container(color: color),
                ),
                Center(
                  child: Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${(percentage * 100).toStringAsFixed(1)}%',
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(DashboardProvider provider) {
    final activities = provider.recentActivity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // Navigate to full activity log
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
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
          child: activities.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'No recent activity',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activities.length > 5 ? 5 : activities.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey[200]),
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return _buildActivityItem(activity);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(dynamic activity) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getActivityColor(activity.type).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getActivityIcon(activity.type),
          size: 20,
          color: _getActivityColor(activity.type),
        ),
      ),
      title: Text(
        activity.description,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        _formatActivityTime(activity.timestamp),
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'user_created':
        return Icons.person_add;
      case 'facility_created':
        return Icons.add_location;
      case 'patient_registered':
        return Icons.person_add_alt;
      case 'visit_recorded':
        return Icons.assignment_add;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'user_created':
        return Colors.blue;
      case 'facility_created':
        return Colors.green;
      case 'patient_registered':
        return Colors.orange;
      case 'visit_recorded':
        return Colors.purple;
      default:
        return Colors.grey;
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
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildErrorCard(DashboardProvider provider) {
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
          Text(provider.error!, style: TextStyle(color: Colors.red[600])),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: provider.clearError,
                child: const Text('Dismiss'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: provider.refreshMetrics,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.dashboard, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No dashboard data available',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Data will appear here once users start using the system',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.download, color: Colors.green),
            SizedBox(width: 8),
            Text('Export Patient Data'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will export all patient data from the system as a CSV file.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, 
                    size: 20, 
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This may take a moment for large datasets.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await _exportPatientsData(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.download),
            label: const Text('Export CSV'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPatientsData(BuildContext context) async {
    print('[EXPORT] Starting patient data export...');
    final startTime = DateTime.now();
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Exporting patient data...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      print('[EXPORT] Creating PatientService instance...');
      final patientService = PatientService();
      
      print('[EXPORT] Fetching all patients from Firestore...');
      final fetchStartTime = DateTime.now();
      final patients = await patientService.getAllPatients();
      final fetchDuration = DateTime.now().difference(fetchStartTime);
      print('[EXPORT] Fetched ${patients.length} patients in ${fetchDuration.inMilliseconds}ms');

      // Close loading dialog first
      if (context.mounted) {
        Navigator.of(context).pop();
        print('[EXPORT] Loading dialog closed');
      }

      if (patients.isEmpty) {
        print('[EXPORT] No patients found to export');
        if (context.mounted) {
          _showMessage(
            context,
            'No patient data to export',
            isError: true,
          );
        }
        return;
      }

      print('[EXPORT] Generating CSV data...');
      final csvStartTime = DateTime.now();
      final csvData = ExportUtils.generatePatientsCsv(patients);
      final csvDuration = DateTime.now().difference(csvStartTime);
      print('[EXPORT] CSV generated in ${csvDuration.inMilliseconds}ms, size: ${csvData.length} characters');
      
      final filename = 'patients_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      print('[EXPORT] Initiating download for file: $filename');
      
      final downloadStartTime = DateTime.now();
      _downloadCsv(csvData, filename);
      final downloadDuration = DateTime.now().difference(downloadStartTime);
      print('[EXPORT] Download initiated in ${downloadDuration.inMilliseconds}ms');
      
      final totalDuration = DateTime.now().difference(startTime);
      print('[EXPORT] Total export process completed in ${totalDuration.inSeconds}s');
      
      if (context.mounted) {
        _showMessage(
          context,
          'Successfully exported ${patients.length} patient records',
        );
      }
    } catch (e, stackTrace) {
      print('[EXPORT] ERROR: $e');
      print('[EXPORT] Stack trace: $stackTrace');
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (context.mounted) {
        _showMessage(
          context,
          'Failed to export patient data: $e',
          isError: true,
        );
      }
    }
  }

  void _downloadCsv(String csvData, String filename) {
    print('[DOWNLOAD] Starting download for: $filename');
    print('[DOWNLOAD] CSV size: ${csvData.length} characters (${(csvData.length / 1024).toStringAsFixed(2)} KB)');
    print('[DOWNLOAD] Platform: ${kIsWeb ? "Web" : "Mobile/Desktop"}');
    
    if (kIsWeb) {
      try {
        print('[DOWNLOAD] Creating blob for web download...');
        // Web download
        final bytes = utf8.encode(csvData);
        print('[DOWNLOAD] Encoded ${bytes.length} bytes');
        
        final blob = html.Blob([bytes]);
        print('[DOWNLOAD] Blob created');
        
        final url = html.Url.createObjectUrlFromBlob(blob);
        print('[DOWNLOAD] Object URL created: $url');
        
        print('[DOWNLOAD] Creating and clicking anchor element...');
        html.AnchorElement(href: url)
          ..setAttribute('download', filename)
          ..click();
        print('[DOWNLOAD] Click triggered');
        
        html.Url.revokeObjectUrl(url);
        print('[DOWNLOAD] Object URL revoked');
        print('[DOWNLOAD] Web download completed successfully');
      } catch (e, stackTrace) {
        print('[DOWNLOAD] ERROR in web download: $e');
        print('[DOWNLOAD] Stack trace: $stackTrace');
      }
    } else {
      print('[DOWNLOAD] Showing CSV preview dialog for mobile/desktop...');
      // For mobile/desktop, show the CSV in a dialog
      // In a production app, you would use file_picker or path_provider
      _showCsvPreviewDialog(csvData, filename);
    }
  }

  void _showCsvPreviewDialog(String csvData, String filename) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('CSV Export: $filename'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              csvData,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
