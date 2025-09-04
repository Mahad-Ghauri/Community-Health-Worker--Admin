// ignore_for_file: deprecated_member_use, unnecessary_to_list_in_spreads, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chw_tb/config/theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  String _selectedPeriod = 'This Month';
  String _selectedReportType = 'Overview';
  bool _isGenerating = false;
  
  Map<String, dynamic> _reportData = {};
  List<Map<String, dynamic>> _recentReports = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();
    
    _loadReportData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _loadReportData() {
    // Mock report data
    _reportData = {
      'totalPatients': 247,
      'activePatients': 189,
      'newRegistrations': 23,
      'completedTreatments': 45,
      'defaultedPatients': 8,
      'visitsConducted': 567,
      'averageAdherence': 87.5,
      'sideEffectsReported': 34,
      'medicationDistributed': 1240,
      'pillCountsCompleted': 456,
      'photosTaken': 1589,
      'formsSubmitted': 234,
      'syncSuccessRate': 96.2,
      'dataQualityScore': 94.8,
      'workingDays': 22,
      'averageVisitsPerDay': 25.8,
      'totalWorkingHours': 176,
      'performanceRating': 'Excellent',
    };
    
    // Mock recent reports
    _recentReports = [
      {
        'id': 'RPT001',
        'title': 'Monthly Activity Summary - September 2025',
        'type': 'Monthly Report',
        'period': 'September 2025',
        'generatedDate': DateTime.now().subtract(const Duration(days: 2)),
        'status': 'Completed',
        'size': '2.4 MB',
        'pages': 15,
        'downloadUrl': 'https://example.com/report1.pdf',
      },
      {
        'id': 'RPT002',
        'title': 'Patient Adherence Analysis - Q3 2025',
        'type': 'Adherence Report',
        'period': 'Q3 2025',
        'generatedDate': DateTime.now().subtract(const Duration(days: 7)),
        'status': 'Completed',
        'size': '1.8 MB',
        'pages': 12,
        'downloadUrl': 'https://example.com/report2.pdf',
      },
      {
        'id': 'RPT003',
        'title': 'Side Effects Monitoring - August 2025',
        'type': 'Side Effects Report',
        'period': 'August 2025',
        'generatedDate': DateTime.now().subtract(const Duration(days: 15)),
        'status': 'Completed',
        'size': '954 KB',
        'pages': 8,
        'downloadUrl': 'https://example.com/report3.pdf',
      },
      {
        'id': 'RPT004',
        'title': 'Performance Metrics - Weekly Summary',
        'type': 'Performance Report',
        'period': 'Week 38, 2025',
        'generatedDate': DateTime.now().subtract(const Duration(days: 3)),
        'status': 'Generating',
        'size': 'N/A',
        'pages': 0,
        'progress': 0.75,
      },
    ];
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MadadgarTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Reports',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: MadadgarTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => _showReportSettings(),
            icon: const Icon(Icons.settings),
            tooltip: 'Report Settings',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export_all',
                child: Row(
                  children: [
                    const Icon(Icons.download),
                    const SizedBox(width: 8),
                    Text('Export All Reports', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'schedule_report',
                child: Row(
                  children: [
                    const Icon(Icons.schedule),
                    const SizedBox(width: 8),
                    Text('Schedule Report', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_old',
                child: Row(
                  children: [
                    const Icon(Icons.clear_all),
                    const SizedBox(width: 8),
                    Text('Clear Old Reports', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildReportControls(),
              _buildKPISummary(),
              _buildReportTypes(),
              _buildRecentReports(),
              const SizedBox(height: 100), // Space for floating button
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isGenerating ? null : _generateReport,
        backgroundColor: _isGenerating ? Colors.grey : MadadgarTheme.primaryColor,
        icon: _isGenerating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.assessment, color: Colors.white),
        label: Text(
          _isGenerating ? 'Generating...' : 'Generate Report',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildReportControls() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tune, color: MadadgarTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Report Configuration',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Period selector
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time Period',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedPeriod,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            'This Week',
                            'This Month',
                            'Last Month',
                            'This Quarter',
                            'Last Quarter',
                            'This Year',
                            'Custom Range'
                          ].map((period) {
                            return DropdownMenuItem(
                              value: period,
                              child: Text(period, style: GoogleFonts.poppins(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedPeriod = value ?? 'This Month');
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report Type',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedReportType,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            'Overview',
                            'Patient Management',
                            'Adherence Analysis',
                            'Side Effects',
                            'Performance Metrics',
                            'Data Quality',
                            'Custom Report'
                          ].map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type, style: GoogleFonts.poppins(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedReportType = value ?? 'Overview');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPISummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Key Performance Indicators',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _selectedPeriod,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // KPI Grid
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.2,
                children: [
                  _buildKPICard(
                    'Total Patients',
                    '${_reportData['totalPatients']}',
                    Icons.people,
                    MadadgarTheme.primaryColor,
                    '+12%',
                    true,
                  ),
                  _buildKPICard(
                    'Active Treatments',
                    '${_reportData['activePatients']}',
                    Icons.medical_services,
                    Colors.green,
                    '+5%',
                    true,
                  ),
                  _buildKPICard(
                    'Adherence Rate',
                    '${_reportData['averageAdherence']}%',
                    Icons.trending_up,
                    Colors.blue,
                    '+2.3%',
                    true,
                  ),
                  _buildKPICard(
                    'Default Rate',
                    '${((_reportData['defaultedPatients'] / _reportData['totalPatients']) * 100).toStringAsFixed(1)}%',
                    Icons.trending_down,
                    Colors.red,
                    '-1.2%',
                    false,
                  ),
                  _buildKPICard(
                    'Visits Conducted',
                    '${_reportData['visitsConducted']}',
                    Icons.event_note,
                    Colors.orange,
                    '+18%',
                    true,
                  ),
                  _buildKPICard(
                    'Data Quality',
                    '${_reportData['dataQualityScore']}%',
                    Icons.verified,
                    Colors.purple,
                    '+0.8%',
                    true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color, String change, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isPositive ? Colors.green : Colors.red,
                      size: 10,
                    ),
                    Text(
                      change,
                      style: GoogleFonts.poppins(
                        fontSize: 8,
                        color: isPositive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypes() {
    List<Map<String, dynamic>> reportTypes = [
      {
        'title': 'Patient Management',
        'description': 'Registration, treatment status, and outcomes',
        'icon': Icons.people,
        'color': MadadgarTheme.primaryColor,
        'fields': ['Total patients', 'New registrations', 'Treatment completion'],
      },
      {
        'title': 'Adherence Analysis',
        'description': 'Medication compliance and pill count tracking',
        'icon': Icons.medication,
        'color': Colors.green,
        'fields': ['Adherence rates', 'Pill counts', 'Missed doses'],
      },
      {
        'title': 'Visit Tracking',
        'description': 'Home visits, follow-ups, and scheduling',
        'icon': Icons.event_note,
        'color': Colors.blue,
        'fields': ['Visits conducted', 'Follow-up rates', 'Missed appointments'],
      },
      {
        'title': 'Side Effects Monitoring',
        'description': 'Adverse reactions and safety reporting',
        'icon': Icons.report_problem,
        'color': Colors.orange,
        'fields': ['Side effects reported', 'Severity levels', 'Referrals made'],
      },
      {
        'title': 'Performance Metrics',
        'description': 'CHW productivity and quality indicators',
        'icon': Icons.assessment,
        'color': Colors.purple,
        'fields': ['Working hours', 'Visits per day', 'Data quality'],
      },
      {
        'title': 'Data Quality',
        'description': 'Completeness, accuracy, and sync status',
        'icon': Icons.verified,
        'color': Colors.indigo,
        'fields': ['Data completeness', 'Sync success rate', 'Error rates'],
      },
    ];
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.library_books, color: Colors.brown),
                  const SizedBox(width: 8),
                  Text(
                    'Available Report Types',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              ...reportTypes.map((reportType) {
                return _buildReportTypeCard(reportType);
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportTypeCard(Map<String, dynamic> reportType) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () => _selectReportType(reportType['title']),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: reportType['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _selectedReportType == reportType['title']
                  ? reportType['color']
                  : reportType['color'].withOpacity(0.3),
              width: _selectedReportType == reportType['title'] ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(reportType['icon'], color: reportType['color'], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reportType['title'],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          reportType['description'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedReportType == reportType['title'])
                    Icon(Icons.check_circle, color: reportType['color']),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: reportType['fields'].map<Widget>((field) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: reportType['color'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      field,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: reportType['color'],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentReports() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Reports',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              ..._recentReports.map((report) {
                return _buildRecentReportItem(report);
              }).toList(),
              
              const SizedBox(height: 16),
              
              Center(
                child: TextButton.icon(
                  onPressed: () => _viewAllReports(),
                  icon: const Icon(Icons.folder_open),
                  label: Text(
                    'View All Reports',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentReportItem(Map<String, dynamic> report) {
    Color statusColor = _getReportStatusColor(report['status']);
    IconData statusIcon = _getReportStatusIcon(report['status']);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: MadadgarTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report['title'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${report['type']} • ${report['period']}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      report['status'],
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Progress bar for generating reports
          if (report['status'] == 'Generating')
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: report['progress'] ?? 0.0,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${((report['progress'] ?? 0.0) * 100).round()}%',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          
          Row(
            children: [
              if (report['status'] == 'Completed') ...[
                Text(
                  '${report['size']} • ${report['pages']} pages',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ] else if (report['status'] == 'Generating') ...[
                Text(
                  'Generating report...',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.blue,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                _formatDate(report['generatedDate']),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          
          if (report['status'] == 'Completed')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _viewReport(report),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: Text(
                      'View',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _downloadReport(report),
                    icon: const Icon(Icons.download, size: 16),
                    label: Text(
                      'Download',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _shareReport(report),
                    icon: const Icon(Icons.share, size: 16),
                    label: Text(
                      'Share',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getReportStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Generating':
        return Colors.blue;
      case 'Failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getReportStatusIcon(String status) {
    switch (status) {
      case 'Completed':
        return Icons.check_circle;
      case 'Generating':
        return Icons.hourglass_top;
      case 'Failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _selectReportType(String reportType) {
    setState(() => _selectedReportType = reportType);
  }

  void _generateReport() async {
    setState(() => _isGenerating = true);
    
    // Simulate report generation
    await Future.delayed(const Duration(seconds: 3));
    
    setState(() => _isGenerating = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Report generated successfully!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to generated report
          },
        ),
      ),
    );
    
    // Add new report to recent reports list
    final newReport = {
      'id': 'RPT${DateTime.now().millisecondsSinceEpoch}',
      'title': '$_selectedReportType Report - $_selectedPeriod',
      'type': _selectedReportType,
      'period': _selectedPeriod,
      'generatedDate': DateTime.now(),
      'status': 'Completed',
      'size': '1.5 MB',
      'pages': 10,
      'downloadUrl': 'https://example.com/new_report.pdf',
    };
    
    setState(() {
      _recentReports.insert(0, newReport);
    });
  }

  void _showReportSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Report settings feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export_all':
        _exportAllReports();
        break;
      case 'schedule_report':
        _scheduleReport();
        break;
      case 'clear_old':
        _clearOldReports();
        break;
    }
  }

  void _exportAllReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export all reports feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _scheduleReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Schedule report feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _clearOldReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Clear old reports feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _viewAllReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View all reports feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _viewReport(Map<String, dynamic> report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${report['title']}...', style: GoogleFonts.poppins())),
    );
  }

  void _downloadReport(Map<String, dynamic> report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading ${report['title']}...', style: GoogleFonts.poppins())),
    );
  }

  void _shareReport(Map<String, dynamic> report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing ${report['title']}...', style: GoogleFonts.poppins())),
    );
  }
}
