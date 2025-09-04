// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chw_tb/config/theme.dart';

class OfflineQueueScreen extends StatefulWidget {
  const OfflineQueueScreen({super.key});

  @override
  State<OfflineQueueScreen> createState() => _OfflineQueueScreenState();
}

class _OfflineQueueScreenState extends State<OfflineQueueScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _uploadController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _uploadAnimation;
  
  bool _isUploading = false;
  final bool _isOnline = true;
  String _selectedFilter = 'All';
  
  List<Map<String, dynamic>> _queueItems = [];
  List<Map<String, dynamic>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _uploadController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _uploadAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _uploadController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    
    _loadQueueData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _uploadController.dispose();
    super.dispose();
  }

  void _loadQueueData() {
    // Mock offline queue data
    _queueItems = [
      {
        'id': 'Q001',
        'type': 'Patient Registration',
        'title': 'New Patient - Ahmad Khan',
        'description': 'Complete patient registration form',
        'size': '2.4 KB',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
        'status': 'Pending',
        'priority': 'High',
        'retries': 0,
        'maxRetries': 3,
        'estimatedTime': '10s',
        'data': {
          'patientName': 'Ahmad Khan',
          'age': 35,
          'gender': 'Male',
          'phone': '+92 300 1234567',
        },
      },
      {
        'id': 'Q002',
        'type': 'Visit Record',
        'title': 'Follow-up Visit - Sarah Ahmed',
        'description': 'Monthly treatment monitoring visit',
        'size': '1.8 KB',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 12)),
        'status': 'Uploading',
        'priority': 'Medium',
        'retries': 1,
        'maxRetries': 3,
        'estimatedTime': '8s',
        'progress': 0.65,
        'data': {
          'patientName': 'Sarah Ahmed',
          'visitType': 'Follow-up',
          'adherence': 95,
        },
      },
      {
        'id': 'Q003',
        'type': 'Medication Log',
        'title': 'Pill Count Update',
        'description': 'Daily medication adherence tracking',
        'size': '0.9 KB',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 18)),
        'status': 'Failed',
        'priority': 'Low',
        'retries': 3,
        'maxRetries': 3,
        'estimatedTime': '5s',
        'error': 'Server timeout',
        'data': {
          'pillsRemaining': 45,
          'adherenceRate': 88,
        },
      },
      {
        'id': 'Q004',
        'type': 'Photo Upload',
        'title': 'Treatment Card Photos',
        'description': '5 photos of patient treatment cards',
        'size': '24.6 KB',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 25)),
        'status': 'Pending',
        'priority': 'Medium',
        'retries': 0,
        'maxRetries': 3,
        'estimatedTime': '45s',
        'data': {
          'photoCount': 5,
          'totalSize': '24.6 KB',
        },
      },
      {
        'id': 'Q005',
        'type': 'Side Effects Report',
        'title': 'Side Effects - Fatima Ali',
        'description': 'Patient reported nausea and headache',
        'size': '1.2 KB',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
        'status': 'Completed',
        'priority': 'High',
        'retries': 0,
        'maxRetries': 3,
        'estimatedTime': '6s',
        'data': {
          'patientName': 'Fatima Ali',
          'sideEffects': ['Nausea', 'Headache'],
          'severity': 'Mild',
        },
      },
      {
        'id': 'Q006',
        'type': 'Form Submission',
        'title': 'Monthly Report',
        'description': 'CHW monthly activity summary',
        'size': '5.7 KB',
        'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
        'status': 'Pending',
        'priority': 'Low',
        'retries': 0,
        'maxRetries': 3,
        'estimatedTime': '15s',
        'data': {
          'reportType': 'Monthly Summary',
          'period': 'September 2025',
        },
      },
      {
        'id': 'Q007',
        'type': 'Patient Update',
        'title': 'Contact Information Update',
        'description': 'Updated phone number and address',
        'size': '0.8 KB',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        'status': 'Queued',
        'priority': 'Medium',
        'retries': 0,
        'maxRetries': 3,
        'estimatedTime': '7s',
        'data': {
          'patientName': 'Muhammad Ali',
          'updatedFields': ['phone', 'address'],
        },
      },
    ];
    
    _applyFilter();
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == 'All') {
        _filteredItems = List.from(_queueItems);
      } else {
        _filteredItems = _queueItems.where((item) => item['status'] == _selectedFilter).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MadadgarTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Offline Queue',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _isOnline ? MadadgarTheme.primaryColor : Colors.orange,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => _showQueueSettings(),
            icon: const Icon(Icons.settings),
            tooltip: 'Queue Settings',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'retry_all',
                child: Row(
                  children: [
                    const Icon(Icons.refresh),
                    const SizedBox(width: 8),
                    Text('Retry All Failed', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_completed',
                child: Row(
                  children: [
                    const Icon(Icons.clear_all),
                    const SizedBox(width: 8),
                    Text('Clear Completed', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export_queue',
                child: Row(
                  children: [
                    const Icon(Icons.download),
                    const SizedBox(width: 8),
                    Text('Export Queue', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildConnectionBanner(),
            _buildQueueSummary(),
            _buildFilterTabs(),
            Expanded(
              child: _buildQueueList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _isUploading
          ? FloatingActionButton(
              onPressed: null,
              backgroundColor: Colors.grey,
              child: RotationTransition(
                turns: _uploadAnimation,
                child: const Icon(Icons.cloud_upload, color: Colors.white),
              ),
            )
          : FloatingActionButton.extended(
              onPressed: _isOnline ? _uploadAll : null,
              backgroundColor: _isOnline ? MadadgarTheme.primaryColor : Colors.grey,
              icon: Icon(
                _isOnline ? Icons.cloud_upload : Icons.cloud_off,
                color: Colors.white,
              ),
              label: Text(
                _isOnline ? 'Upload All' : 'Offline',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }

  Widget _buildConnectionBanner() {
    if (_isOnline) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.orange,
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Working offline. Data will be uploaded when connection is restored.',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueSummary() {
    int pendingCount = _queueItems.where((item) => item['status'] == 'Pending' || item['status'] == 'Queued').length;
    int failedCount = _queueItems.where((item) => item['status'] == 'Failed').length;
    int completedCount = _queueItems.where((item) => item['status'] == 'Completed').length;
    int uploadingCount = _queueItems.where((item) => item['status'] == 'Uploading').length;
    
    double totalSize = _queueItems
        .where((item) => item['status'] != 'Completed')
        .map((item) => _parseSizeInKB(item['size']))
        .fold(0.0, (a, b) => a + b);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [MadadgarTheme.primaryColor, MadadgarTheme.primaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Queue Status',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_queueItems.length} total items • ${totalSize.toStringAsFixed(1)} KB pending',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.queue,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryStat('Pending', '$pendingCount', Colors.orange),
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildSummaryStat('Failed', '$failedCount', Colors.red),
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildSummaryStat('Uploading', '$uploadingCount', Colors.blue),
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildSummaryStat('Done', '$completedCount', Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, Color indicatorColor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: indicatorColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    List<String> filters = ['All', 'Pending', 'Uploading', 'Failed', 'Completed'];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            bool isSelected = filter == _selectedFilter;
            int count = filter == 'All' 
                ? _queueItems.length 
                : _queueItems.where((item) => item['status'] == filter).length;
            
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  '$filter ($count)',
                  style: GoogleFonts.poppins(
                    color: isSelected ? Colors.white : MadadgarTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedFilter = filter);
                  _applyFilter();
                },
                selectedColor: MadadgarTheme.primaryColor,
                backgroundColor: Colors.white,
                side: BorderSide(color: MadadgarTheme.primaryColor),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildQueueList() {
    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.queue,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'All' 
                  ? 'No items in queue'
                  : 'No ${_selectedFilter.toLowerCase()} items',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your offline data will appear here',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _refreshQueue,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          return _buildQueueItem(_filteredItems[index]);
        },
      ),
    );
  }

  Widget _buildQueueItem(Map<String, dynamic> item) {
    Color statusColor = _getStatusColor(item['status']);
    IconData statusIcon = _getStatusIcon(item['status']);
    Color priorityColor = _getPriorityColor(item['priority']);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Icon(_getDataTypeIcon(item['type']), color: MadadgarTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'],
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          item['type'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
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
                              item['status'],
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item['priority'],
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            color: priorityColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Description
              Text(
                item['description'],
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Progress bar for uploading items
              if (item['status'] == 'Uploading')
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: item['progress'] ?? 0.0,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${((item['progress'] ?? 0.0) * 100).round()}%',
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
              
              // Error message for failed items
              if (item['status'] == 'Failed' && item['error'] != null)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['error'],
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              
              // Footer row
              Row(
                children: [
                  Text(
                    '${item['size']} • ${item['estimatedTime']}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  if (item['retries'] > 0) ...[
                    Text(
                      ' • Retries: ${item['retries']}/${item['maxRetries']}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _formatTimeAgo(item['timestamp']),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Action buttons
              Row(
                children: [
                  if (item['status'] == 'Failed') ...[
                    TextButton.icon(
                      onPressed: () => _retryItem(item),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(
                        'Retry',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (item['status'] == 'Pending' || item['status'] == 'Queued') ...[
                    TextButton.icon(
                      onPressed: () => _prioritizeItem(item),
                      icon: const Icon(Icons.priority_high, size: 16),
                      label: Text(
                        'Priority',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton.icon(
                    onPressed: () => _viewItemDetails(item),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: Text(
                      'Details',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                  if (item['status'] != 'Uploading' && item['status'] != 'Completed')
                    IconButton(
                      onPressed: () => _deleteItem(item),
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      tooltip: 'Delete',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDataTypeIcon(String type) {
    switch (type) {
      case 'Patient Registration':
      case 'Patient Update':
        return Icons.person_add;
      case 'Visit Record':
        return Icons.event_note;
      case 'Medication Log':
        return Icons.medication;
      case 'Photo Upload':
        return Icons.photo_camera;
      case 'Side Effects Report':
        return Icons.report_problem;
      case 'Form Submission':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
      case 'Queued':
        return Colors.orange;
      case 'Uploading':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      case 'Failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
      case 'Queued':
        return Icons.schedule;
      case 'Uploading':
        return Icons.cloud_upload;
      case 'Completed':
        return Icons.check_circle;
      case 'Failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  double _parseSizeInKB(String sizeString) {
    final match = RegExp(r'(\d+\.?\d*)\s*(KB|MB|GB)').firstMatch(sizeString);
    if (match != null) {
      double value = double.parse(match.group(1)!);
      String unit = match.group(2)!;
      
      switch (unit) {
        case 'KB':
          return value;
        case 'MB':
          return value * 1024;
        case 'GB':
          return value * 1024 * 1024;
        default:
          return value;
      }
    }
    return 0.0;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
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

  Future<void> _refreshQueue() async {
    await Future.delayed(const Duration(seconds: 1));
    _loadQueueData();
  }

  void _uploadAll() async {
    setState(() => _isUploading = true);
    _uploadController.repeat();
    
    // Simulate upload process
    await Future.delayed(const Duration(seconds: 4));
    
    setState(() => _isUploading = false);
    _uploadController.stop();
    _uploadController.reset();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All items uploaded successfully!', style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ),
    );
    
    // Simulate successful uploads
    setState(() {
      for (var item in _queueItems) {
        if (item['status'] == 'Pending' || item['status'] == 'Queued') {
          item['status'] = 'Completed';
        }
      }
    });
    _applyFilter();
  }

  void _showQueueSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Queue settings feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'retry_all':
        _retryAllFailed();
        break;
      case 'clear_completed':
        _clearCompleted();
        break;
      case 'export_queue':
        _exportQueue();
        break;
    }
  }

  void _retryAllFailed() {
    setState(() {
      for (var item in _queueItems) {
        if (item['status'] == 'Failed') {
          item['status'] = 'Pending';
          item['retries'] = 0;
          item.remove('error');
        }
      }
    });
    _applyFilter();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All failed items queued for retry', style: GoogleFonts.poppins())),
    );
  }

  void _clearCompleted() {
    setState(() {
      _queueItems.removeWhere((item) => item['status'] == 'Completed');
    });
    _applyFilter();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Completed items cleared', style: GoogleFonts.poppins())),
    );
  }

  void _exportQueue() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export queue feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _retryItem(Map<String, dynamic> item) {
    setState(() {
      item['status'] = 'Pending';
      item['retries'] = 0;
      item.remove('error');
    });
    _applyFilter();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Item queued for retry', style: GoogleFonts.poppins())),
    );
  }

  void _prioritizeItem(Map<String, dynamic> item) {
    setState(() {
      item['priority'] = 'High';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Item priority increased', style: GoogleFonts.poppins())),
    );
  }

  void _viewItemDetails(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Item Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${item['id']}', style: GoogleFonts.poppins()),
            Text('Type: ${item['type']}', style: GoogleFonts.poppins()),
            Text('Status: ${item['status']}', style: GoogleFonts.poppins()),
            Text('Priority: ${item['priority']}', style: GoogleFonts.poppins()),
            Text('Size: ${item['size']}', style: GoogleFonts.poppins()),
            Text('Retries: ${item['retries']}/${item['maxRetries']}', style: GoogleFonts.poppins()),
            const SizedBox(height: 16),
            Text(
              'Data:',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            ...item['data'].entries.map((entry) {
              return Text('${entry.key}: ${entry.value}', style: GoogleFonts.poppins(fontSize: 12));
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _deleteItem(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Item',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this item? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _queueItems.remove(item);
              });
              _applyFilter();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Item deleted', style: GoogleFonts.poppins())),
              );
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
