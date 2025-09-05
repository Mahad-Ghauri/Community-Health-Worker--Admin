// ignore_for_file: deprecated_member_use, unnecessary_to_list_in_spreads
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:chw_tb/config/theme.dart';
import 'package:chw_tb/controllers/providers/app_providers.dart';

class SyncStatusScreen extends StatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _syncController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _syncAnimation;
  
  bool _isOnline = true;
  bool _isSyncing = false;
  bool _autoSync = true;
  DateTime _lastSyncTime = DateTime.now().subtract(const Duration(minutes: 15));
  
  // Sync statistics
  Map<String, dynamic> _syncStats = {};
  List<Map<String, dynamic>> _syncHistory = [];
  List<Map<String, dynamic>> _pendingData = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _syncController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _syncAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _syncController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    
    _loadSyncData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _syncController.dispose();
    super.dispose();
  }

  void _loadSyncData() {
    // Mock sync statistics
    _syncStats = {
      'totalRecords': 1247,
      'syncedRecords': 1195,
      'pendingRecords': 52,
      'failedRecords': 0,
      'lastSuccessfulSync': _lastSyncTime,
      'dataSize': '12.4 MB',
      'compressionRatio': '68%',
    };
    
    // Mock sync history
    _syncHistory = [
      {
        'timestamp': DateTime.now().subtract(const Duration(minutes: 15)),
        'status': 'Success',
        'recordsProcessed': 23,
        'duration': '12s',
        'dataSize': '1.2 MB',
        'type': 'Automatic',
      },
      {
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        'status': 'Success',
        'recordsProcessed': 156,
        'duration': '45s',
        'dataSize': '8.7 MB',
        'type': 'Manual',
      },
      {
        'timestamp': DateTime.now().subtract(const Duration(hours: 6)),
        'status': 'Partial',
        'recordsProcessed': 89,
        'duration': '38s',
        'dataSize': '4.2 MB',
        'type': 'Automatic',
        'error': 'Network timeout for 3 records',
      },
      {
        'timestamp': DateTime.now().subtract(const Duration(days: 1)),
        'status': 'Success',
        'recordsProcessed': 234,
        'duration': '67s',
        'dataSize': '15.3 MB',
        'type': 'Manual',
      },
      {
        'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 12)),
        'status': 'Failed',
        'recordsProcessed': 0,
        'duration': '5s',
        'dataSize': '0 MB',
        'type': 'Automatic',
        'error': 'No internet connection',
      },
    ];
    
    // Mock pending data
    _pendingData = [
      {
        'type': 'Patient Record',
        'name': 'Ahmad Khan - Profile Update',
        'size': '2.1 KB',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
        'priority': 'High',
        'retries': 0,
      },
      {
        'type': 'Visit Record',
        'name': 'Sarah Ahmed - Follow-up Visit',
        'size': '1.8 KB',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 12)),
        'priority': 'Medium',
        'retries': 1,
      },
      {
        'type': 'Medication Log',
        'name': 'Multiple Patients - Adherence Data',
        'size': '5.7 KB',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 18)),
        'priority': 'Low',
        'retries': 0,
      },
      {
        'type': 'Photo Upload',
        'name': 'Treatment Card Photos (15 files)',
        'size': '24.6 KB',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 25)),
        'priority': 'Medium',
        'retries': 2,
      },
      {
        'type': 'Form Submission',
        'name': 'Side Effects Report - Fatima Ali',
        'size': '0.9 KB',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
        'priority': 'High',
        'retries': 0,
      },
    ];
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appStateProvider, child) {
        // Sync local state with AppStateProvider
        _isOnline = appStateProvider.isOnline;
        _isSyncing = appStateProvider.isSyncing;
        _lastSyncTime = appStateProvider.lastSyncTime ?? DateTime.now().subtract(const Duration(minutes: 15));
        
        return Scaffold(
          backgroundColor: MadadgarTheme.backgroundColor,
          appBar: AppBar(
            title: Text(
              'Sync Status',
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
                onPressed: () => _showSyncSettings(),
                icon: const Icon(Icons.settings),
                tooltip: 'Sync Settings',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'force_sync',
                    child: Row(
                      children: [
                        const Icon(Icons.sync),
                        const SizedBox(width: 8),
                        Text('Force Full Sync', style: GoogleFonts.poppins()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear_cache',
                    child: Row(
                      children: [
                        const Icon(Icons.clear_all),
                        const SizedBox(width: 8),
                        Text('Clear Sync Cache', style: GoogleFonts.poppins()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export_logs',
                    child: Row(
                      children: [
                        const Icon(Icons.download),
                        const SizedBox(width: 8),
                        Text('Export Sync Logs', style: GoogleFonts.poppins()),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: _refreshSyncStatus,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildConnectionStatus(),
                    _buildSyncOverview(),
                    _buildPendingData(),
                    _buildSyncHistory(),
                    const SizedBox(height: 100), // Space for floating button
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: _isSyncing
              ? FloatingActionButton(
                  onPressed: null,
                  backgroundColor: Colors.grey,
                  child: RotationTransition(
                    turns: _syncAnimation,
                    child: const Icon(Icons.sync, color: Colors.white),
                  ),
                )
              : FloatingActionButton.extended(
                  onPressed: _isOnline ? _syncNow : null,
                  backgroundColor: _isOnline ? MadadgarTheme.primaryColor : Colors.grey,
                  icon: Icon(
                    _isOnline ? Icons.sync : Icons.sync_disabled,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isOnline ? 'Sync Now' : 'Offline',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isOnline
              ? [MadadgarTheme.primaryColor, MadadgarTheme.primaryColor.withOpacity(0.8)]
              : [Colors.orange, Colors.orange.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _isOnline ? Icons.wifi : Icons.wifi_off,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isOnline ? 'Online' : 'Offline',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _isOnline 
                          ? 'Connected to server • Last sync: ${_formatTimeAgo(_lastSyncTime)}'
                          : 'No internet connection • Working in offline mode',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _autoSync,
                onChanged: _isOnline ? (value) {
                  setState(() => _autoSync = value);
                  _showAutoSyncMessage(value);
                } : null,
                activeColor: Colors.white,
                activeTrackColor: Colors.white.withOpacity(0.3),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildConnectionStat('Signal', _isOnline ? 'Strong' : 'None'),
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildConnectionStat('Auto Sync', _autoSync ? 'On' : 'Off'),
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildConnectionStat('Pending', '${_pendingData.length}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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

  Widget _buildSyncOverview() {
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
                  Icon(Icons.analytics, color: MadadgarTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Sync Overview',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Progress indicator
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sync Progress',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${_syncStats['syncedRecords']}/${_syncStats['totalRecords']}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _syncStats['syncedRecords'] / _syncStats['totalRecords'],
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(MadadgarTheme.primaryColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Sync statistics grid
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2,
                children: [
                  _buildStatCard(
                    'Total Records',
                    '${_syncStats['totalRecords']}',
                    Icons.storage,
                    MadadgarTheme.primaryColor,
                  ),
                  _buildStatCard(
                    'Pending Sync',
                    '${_syncStats['pendingRecords']}',
                    Icons.sync_problem,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'Data Size',
                    _syncStats['dataSize'],
                    Icons.storage,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Compression',
                    _syncStats['compressionRatio'],
                    Icons.compress,
                    Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingData() {
    if (_pendingData.isEmpty) {
      return const SizedBox.shrink();
    }
    
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
                  Icon(Icons.schedule, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Pending Data (${_pendingData.length})',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _retryPendingSync,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text(
                      'Retry All',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              ..._pendingData.take(5).map((item) {
                return _buildPendingItem(item);
              }).toList(),
              
              if (_pendingData.length > 5)
                TextButton(
                  onPressed: () => _showAllPendingData(),
                  child: Text(
                    'View all ${_pendingData.length} pending items',
                    style: GoogleFonts.poppins(
                      color: MadadgarTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingItem(Map<String, dynamic> item) {
    Color priorityColor = _getPriorityColor(item['priority']);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: priorityColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getDataTypeIcon(item['type']), color: priorityColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item['name'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['priority'],
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: priorityColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${item['type']} • ${item['size']}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
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
          if (item['retries'] > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Retries: ${item['retries']}',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSyncHistory() {
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
                  Icon(Icons.history, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Sync History',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              ..._syncHistory.map((sync) {
                return _buildSyncHistoryItem(sync);
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncHistoryItem(Map<String, dynamic> sync) {
    Color statusColor = _getSyncStatusColor(sync['status']);
    IconData statusIcon = _getSyncStatusIcon(sync['status']);
    
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
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                sync['status'],
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSyncTypeColor(sync['type']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  sync['type'],
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: _getSyncTypeColor(sync['type']),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${sync['recordsProcessed']} records',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              Text(
                ' • ${sync['duration']}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              Text(
                ' • ${sync['dataSize']}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const Spacer(),
              Text(
                _formatDateTime(sync['timestamp']),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          if (sync['error'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
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
                        sync['error'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getDataTypeIcon(String type) {
    switch (type) {
      case 'Patient Record':
        return Icons.person;
      case 'Visit Record':
        return Icons.event_note;
      case 'Medication Log':
        return Icons.medication;
      case 'Photo Upload':
        return Icons.photo;
      case 'Form Submission':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
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

  Color _getSyncStatusColor(String status) {
    switch (status) {
      case 'Success':
        return Colors.green;
      case 'Failed':
        return Colors.red;
      case 'Partial':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getSyncStatusIcon(String status) {
    switch (status) {
      case 'Success':
        return Icons.check_circle;
      case 'Failed':
        return Icons.error;
      case 'Partial':
        return Icons.warning;
      default:
        return Icons.sync;
    }
  }

  Color _getSyncTypeColor(String type) {
    switch (type) {
      case 'Manual':
        return Colors.blue;
      case 'Automatic':
        return Colors.green;
      default:
        return Colors.grey;
    }
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _refreshSyncStatus() async {
    final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
    await appStateProvider.startSync();
    _loadSyncData();
  }

  Future<void> _syncNow() async {
    final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
    if (!appStateProvider.isOnline) return;
    
    _syncController.repeat();
    
    try {
      await appStateProvider.startSync();
      
      setState(() {
        // Clear some pending data to simulate successful sync
        if (_pendingData.isNotEmpty) {
          _pendingData.removeAt(0);
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync completed successfully!', style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _syncController.stop();
      _syncController.reset();
    }
  }

  void _showSyncSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sync settings feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _showAutoSyncMessage(bool enabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled ? 'Auto sync enabled' : 'Auto sync disabled',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: enabled ? Colors.green : Colors.orange,
      ),
    );
  }

  void _retryPendingSync() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Retrying pending sync...', style: GoogleFonts.poppins())),
    );
  }

  void _showAllPendingData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Show all pending data feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'force_sync':
        _forceSyncAll();
        break;
      case 'clear_cache':
        _clearSyncCache();
        break;
      case 'export_logs':
        _exportSyncLogs();
        break;
    }
  }

  void _forceSyncAll() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Force sync initiated...', style: GoogleFonts.poppins())),
    );
  }

  void _clearSyncCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sync cache cleared', style: GoogleFonts.poppins())),
    );
  }

  void _exportSyncLogs() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export sync logs feature coming soon!', style: GoogleFonts.poppins())),
    );
  }
}
