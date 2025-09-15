// ignore_for_file: deprecated_member_use

import 'package:chw_admin/screens/staff/patients/patient_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_provider.dart';
import '../../../services/facility_service.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../theme/theme.dart';
import '../../../models/user.dart';
import '../../../models/patient.dart';
import '../../../utils/responsive_helper.dart';
import '../../../widgets/dashboard_layout.dart';
import '../../../constants/app_constants.dart';
import 'package:go_router/go_router.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  Map<String, dynamic>? _facilityMetrics;
  List<Map<String, dynamic>>? _recentActivities;
  List<Patient>? _patients;
  Map<String, List<Patient>>? _patientsByStatus;
  String? _facilityId;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // Get current user's facility ID
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // For demo purposes, we'll use a fixed facility ID
      // In a real app, you would get this from the user's profile
      _facilityId = user.facilityId ?? 'fac001';

      // Load facility metrics
      final metrics = await FacilityService.getFacilityMetrics(_facilityId!);

      // Load recent activities
      final activities = await FacilityService.getFacilityActivities(
        _facilityId!,
      );

      // Load patients for this facility
      final patientsSnapshot = await FirebaseFirestore.instance
          .collection(AppConstants.patientsCollection)
          .where('treatmentFacility', isEqualTo: _facilityId)
          .get();

      // Convert to Patient objects
      final patients = patientsSnapshot.docs
          .map((doc) => Patient.fromFirestore(doc))
          .toList();

      // Group patients by TB status
      final patientsByStatus = <String, List<Patient>>{};

      // Initialize with empty lists for each status
      patientsByStatus[AppConstants.newlyDiagnosedStatus] = [];
      patientsByStatus[AppConstants.onTreatmentStatus] = [];
      patientsByStatus[AppConstants.treatmentCompletedStatus] = [];
      patientsByStatus[AppConstants.lostToFollowUpStatus] = [];

      // Group patients by their TB status
      for (final patient in patients) {
        patientsByStatus[patient.tbStatus]?.add(patient);
      }

      setState(() {
        _facilityMetrics = metrics;
        _recentActivities = activities;
        _patients = patients;
        _patientsByStatus = patientsByStatus;
        _lastUpdated = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load dashboard data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CHWTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        backgroundColor: CHWTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh Data',
          ),
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
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _buildDashboardContent(),
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: CHWTheme.errorColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Dashboard',
              style: CHWTheme.headingStyle.copyWith(color: CHWTheme.errorColor),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: CHWTheme.bodyStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CHWTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.currentUser;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: CHWTheme.primaryColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: CHWTheme.bodyStyle.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.name ?? 'Staff Member',
                      style: CHWTheme.headingStyle.copyWith(
                        fontSize: 24,
                        color: CHWTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: CHWTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        UserRole.getDisplayName(user?.role ?? 'staff'),
                        style: CHWTheme.bodyStyle.copyWith(
                          color: CHWTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Last Updated Info
          if (_lastUpdated != null)
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Last updated: ${DateFormat('MMM d, y h:mm a').format(_lastUpdated!)}',
                style: CHWTheme.bodyStyle.copyWith(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Metrics Cards
          Text(
            'Facility Metrics',
            style: CHWTheme.subheadingStyle.copyWith(
              color: CHWTheme.primaryColor,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 16),

          // Metrics Grid
          ResponsiveWidget(
            mobile: Column(children: _buildMetricsCards()),
            tablet: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: _buildMetricsCards(),
            ),
            desktop: GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: _buildMetricsCards(),
            ),
          ),

          const SizedBox(height: 32),

          // Quick Actions
          Text(
            'Quick Actions',
            style: CHWTheme.subheadingStyle.copyWith(
              color: CHWTheme.primaryColor,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 16),

          // Quick Actions Grid
          ResponsiveWidget(
            mobile: Column(children: _buildQuickActions()),
            tablet: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: _buildQuickActions(),
            ),
            desktop: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: _buildQuickActions(),
            ),
          ),

          const SizedBox(height: 32),

          // Recent Activities
          Text(
            'Recent Activities',
            style: CHWTheme.subheadingStyle.copyWith(
              color: CHWTheme.primaryColor,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 16),

          // Activities List
          _buildRecentActivities(),

          const SizedBox(height: 32),

          // Treatment Progress Chart (Placeholder)
          Text(
            'Treatment Progress',
            style: CHWTheme.subheadingStyle.copyWith(
              color: CHWTheme.primaryColor,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 16),

          FutureBuilder<List<Map<String, dynamic>>>(
            future: FacilityService.getTreatmentAdherenceData(
              _facilityId ?? '',
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  width: double.infinity,
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError || !snapshot.hasData) {
                return Container(
                  width: double.infinity,
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Failed to load treatment progress data',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              // Data loaded successfully
              final adherenceData = snapshot.data!;

              return Container(
                width: double.infinity,
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _buildTreatmentProgressChart(adherenceData),
              );
            },
          ),

          const SizedBox(height: 32),

          // Patient Status Section
          Text(
            'Patient Status Overview',
            style: CHWTheme.subheadingStyle.copyWith(
              color: CHWTheme.primaryColor,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 16),

          ResponsiveWidget(
            mobile: _buildPatientStatusSection(),
            tablet: _buildPatientStatusSection(),
            desktop: _buildPatientStatusSection(),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  List<Widget> _buildMetricsCards() {
    // If we have patient data, use it for the metrics
    if (_patients != null && _patientsByStatus != null) {
      final totalPatients = _patients!.length;
      final onTreatment =
          _patientsByStatus![AppConstants.onTreatmentStatus]?.length ?? 0;
      final pendingReferrals =
          _facilityMetrics?['pendingReferrals'] ??
          0; // Keep from facility metrics
      final lostToFollowUp =
          _patientsByStatus![AppConstants.lostToFollowUpStatus]?.length ?? 0;

      // Calculate trends (mock data for now)
      final patientsTrend = _facilityMetrics?['patientsTrend'] ?? 0.0;
      final treatmentTrend = _facilityMetrics?['treatmentTrend'] ?? 0.0;
      final referralsTrend = _facilityMetrics?['referralsTrend'] ?? 0.0;
      final ltfuTrend = _facilityMetrics?['ltfuTrend'] ?? 0.0;

      return [
        _buildMetricCard(
          'Total Patients',
          totalPatients.toString(),
          Icons.people,
          CHWTheme.primaryColor,
          patientsTrend,
        ),
        _buildMetricCard(
          'Active Treatments',
          onTreatment.toString(),
          Icons.medication,
          Colors.green,
          treatmentTrend,
        ),
        _buildMetricCard(
          'Pending Referrals',
          pendingReferrals.toString(),
          Icons.assignment_return,
          Colors.orange,
          referralsTrend,
        ),
        _buildMetricCard(
          'Lost to Follow-up',
          lostToFollowUp.toString(),
          Icons.person_off,
          CHWTheme.errorColor,
          ltfuTrend,
        ),
      ];
    } else if (_facilityMetrics != null) {
      // Fall back to facility metrics if patient data isn't available
      return [
        _buildMetricCard(
          'Total Patients',
          _facilityMetrics!['totalPatients'].toString(),
          Icons.people,
          CHWTheme.primaryColor,
          _facilityMetrics!['patientsTrend'],
        ),
        _buildMetricCard(
          'Active Treatments',
          _facilityMetrics!['onTreatment'].toString(),
          Icons.medication,
          Colors.green,
          _facilityMetrics!['treatmentTrend'],
        ),
        _buildMetricCard(
          'Pending Referrals',
          _facilityMetrics!['pendingReferrals'].toString(),
          Icons.assignment_return,
          Colors.orange,
          _facilityMetrics!['referralsTrend'],
        ),
        _buildMetricCard(
          'Lost to Follow-up',
          _facilityMetrics!['lostToFollowUp'].toString(),
          Icons.person_off,
          CHWTheme.errorColor,
          _facilityMetrics!['ltfuTrend'],
        ),
      ];
    } else {
      return [];
    }
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    double trend,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigate to detailed view based on metric type
        _navigateToDetailView(title);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: trend >= 0
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trend >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        color: trend >= 0 ? Colors.green : Colors.red,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${trend.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: trend >= 0 ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: CHWTheme.headingStyle.copyWith(fontSize: 28, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: CHWTheme.bodyStyle.copyWith(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildQuickActions() {
    return [
      QuickAction(
        title: 'Assign New Patient',
        subtitle: 'Create new patient assignment',
        icon: Icons.person_add,
        onTap: () {
          // Navigate to patient assignment screen
          context.goNamed('assignPatients');
        },
      ),
      QuickAction(
        title: 'Schedule Follow-up',
        subtitle: 'Create follow-up appointment',
        icon: Icons.event,
        onTap: () {
          // Navigate to follow-up creation screen
          context.goNamed('createFollowups');
        },
      ),
      QuickAction(
        title: 'View Referrals',
        subtitle: 'Manage pending referrals',
        icon: Icons.assignment_return,
        onTap: () {
          // Navigate to referrals screen
          context.goNamed('referrals');
        },
      ),
      QuickAction(
        title: 'Generate Reports',
        subtitle: 'Export facility data',
        icon: Icons.assessment,
        onTap: () {
          // Show report generation dialog
          _showReportDialog();
        },
      ),
    ];
  }

  Widget _buildRecentActivities() {
    if (_recentActivities == null || _recentActivities!.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No recent activities',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentActivities!.length > 5
            ? 5
            : _recentActivities!.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final activity = _recentActivities![index];
          return ListTile(
            leading: _getActivityIcon(activity['type']),
            title: Text(activity['title']),
            subtitle: Text(activity['description']),
            trailing: Text(
              _formatActivityTime(activity['timestamp']),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            onTap: () {
              // Navigate to activity details
            },
          );
        },
      ),
    );
  }

  Widget _getActivityIcon(String type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'visit':
        iconData = Icons.home_work;
        iconColor = Colors.blue;
        break;
      case 'assignment':
        iconData = Icons.assignment_ind;
        iconColor = Colors.green;
        break;
      case 'referral':
        iconData = Icons.compare_arrows;
        iconColor = Colors.orange;
        break;
      case 'followup':
        iconData = Icons.event_note;
        iconColor = Colors.purple;
        break;
      default:
        iconData = Icons.event;
        iconColor = CHWTheme.primaryColor;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  String _formatActivityTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Patient Report'),
              onTap: () {
                Navigator.pop(context);
                // Generate patient report
              },
            ),
            ListTile(
              leading: const Icon(Icons.medication),
              title: const Text('Treatment Report'),
              onTap: () {
                Navigator.pop(context);
                // Generate treatment report
              },
            ),
            ListTile(
              leading: const Icon(Icons.assessment),
              title: const Text('Performance Report'),
              onTap: () {
                Navigator.pop(context);
                // Generate performance report
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientStatusSection() {
    if (_patients == null || _patients!.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'No patients found for this facility',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status tabs
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ResponsiveWidget(
              mobile: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatusTab(
                        'Newly Diagnosed',
                        _patientsByStatus?[AppConstants.newlyDiagnosedStatus]
                                ?.length ??
                            0,
                        Colors.blue,
                      ),
                      _buildStatusTab(
                        'On Treatment',
                        _patientsByStatus?[AppConstants.onTreatmentStatus]
                                ?.length ??
                            0,
                        Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatusTab(
                        'Completed',
                        _patientsByStatus?[AppConstants
                                    .treatmentCompletedStatus]
                                ?.length ??
                            0,
                        Colors.purple,
                      ),
                      _buildStatusTab(
                        'Lost to Follow-up',
                        _patientsByStatus?[AppConstants.lostToFollowUpStatus]
                                ?.length ??
                            0,
                        CHWTheme.errorColor,
                      ),
                    ],
                  ),
                ],
              ),
              tablet: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatusTab(
                    'Newly Diagnosed',
                    _patientsByStatus?[AppConstants.newlyDiagnosedStatus]
                            ?.length ??
                        0,
                    Colors.blue,
                  ),
                  _buildStatusTab(
                    'On Treatment',
                    _patientsByStatus?[AppConstants.onTreatmentStatus]
                            ?.length ??
                        0,
                    Colors.green,
                  ),
                  _buildStatusTab(
                    'Completed',
                    _patientsByStatus?[AppConstants.treatmentCompletedStatus]
                            ?.length ??
                        0,
                    Colors.purple,
                  ),
                  _buildStatusTab(
                    'Lost to Follow-up',
                    _patientsByStatus?[AppConstants.lostToFollowUpStatus]
                            ?.length ??
                        0,
                    CHWTheme.errorColor,
                  ),
                ],
              ),
              desktop: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatusTab(
                    'Newly Diagnosed',
                    _patientsByStatus?[AppConstants.newlyDiagnosedStatus]
                            ?.length ??
                        0,
                    Colors.blue,
                  ),
                  _buildStatusTab(
                    'On Treatment',
                    _patientsByStatus?[AppConstants.onTreatmentStatus]
                            ?.length ??
                        0,
                    Colors.green,
                  ),
                  _buildStatusTab(
                    'Completed',
                    _patientsByStatus?[AppConstants.treatmentCompletedStatus]
                            ?.length ??
                        0,
                    Colors.purple,
                  ),
                  _buildStatusTab(
                    'Lost to Follow-up',
                    _patientsByStatus?[AppConstants.lostToFollowUpStatus]
                            ?.length ??
                        0,
                    CHWTheme.errorColor,
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Recent patients list
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Patients',
                  style: CHWTheme.bodyStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ..._buildRecentPatientsList(),
              ],
            ),
          ),

          // View all button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // Navigate to patients list
                context.goNamed('patients');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: CHWTheme.primaryColor,
                side: BorderSide(color: CHWTheme.primaryColor),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('View All Patients'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTab(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        ),
      ],
    );
  }

  List<Widget> _buildRecentPatientsList() {
    if (_patients == null || _patients!.isEmpty) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No patients found'),
          ),
        ),
      ];
    }

    // Sort patients by creation date (most recent first)
    final sortedPatients = List<Patient>.from(_patients!)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Take only the 5 most recent patients
    final recentPatients = sortedPatients.take(5).toList();

    return recentPatients.map((patient) {
      return ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(patient.tbStatus).withOpacity(0.1),
          child: Icon(
            _getStatusIcon(patient.tbStatus),
            color: _getStatusColor(patient.tbStatus),
            size: 20,
          ),
        ),
        title: Text(
          patient.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${patient.age} years • ${patient.gender} • ${patient.statusDisplayName}',
        ),
        trailing: Text(
          _formatTimeAgo(patient.createdAt),
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        onTap: () {
          // Navigate to patient details
          Navigator.pushNamed(
            context,
            AppConstants.patientDetailsRoute,
            arguments: patient.patientId,
          );
        },
      );
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.newlyDiagnosedStatus:
        return Colors.blue;
      case AppConstants.onTreatmentStatus:
        return Colors.green;
      case AppConstants.treatmentCompletedStatus:
        return Colors.purple;
      case AppConstants.lostToFollowUpStatus:
        return CHWTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case AppConstants.newlyDiagnosedStatus:
        return Icons.new_releases;
      case AppConstants.onTreatmentStatus:
        return Icons.medication;
      case AppConstants.treatmentCompletedStatus:
        return Icons.check_circle;
      case AppConstants.lostToFollowUpStatus:
        return Icons.person_off;
      default:
        return Icons.person;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return DateFormat('MMM d, y').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildTreatmentProgressChart(
    List<Map<String, dynamic>> adherenceData,
  ) {
    // In a real implementation, you would use a charting library like fl_chart
    // For now, we'll create a simple visual representation

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Treatment Adherence',
              style: CHWTheme.bodyStyle.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: CHWTheme.primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Adherence',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Target',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: adherenceData.map((data) {
              final adherence = data['adherence'] as int;
              final target = data['target'] as int;
              final week = data['week'] as String;

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: (adherence / 100) * 100,
                      width: 16,
                      decoration: BoxDecoration(
                        color: CHWTheme.primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      week.split(' ')[1], // Just show the week number
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Navigate to the appropriate detail view based on the metric title
  void _navigateToDetailView(String title) {
    switch (title) {
      case 'Total Patients':
        Navigator.pushNamed(context, AppConstants.facilityPatientsRoute);
        break;
      case 'Active Treatments':
        Navigator.pushNamed(
          context,
          AppConstants.facilityPatientsRoute,
          arguments: {'filter': AppConstants.onTreatmentStatus},
        );
        break;
      case 'Pending Referrals':
        Navigator.pushNamed(context, AppConstants.referralsRoute);
        break;
      case 'Lost to Follow-up':
        Navigator.pushNamed(
          context,
          AppConstants.facilityPatientsRoute,
          arguments: {'filter': AppConstants.lostToFollowUpStatus},
        );
        break;
      default:
        // Default to facility patients view
        Navigator.pushNamed(context, AppConstants.facilityPatientsRoute);
    }
  }
}
