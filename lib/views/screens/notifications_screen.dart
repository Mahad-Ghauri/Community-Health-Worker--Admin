import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chw_tb/config/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;

  String _selectedFilter = 'all';

  final List<String> _filterOptions = [
    'all',
    'unread',
    'missed_followup',
    'new_assignment',
    'reminder',
    'system_update',
    'emergency_alert',
  ];

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
    _tabController = TabController(length: 3, vsync: this);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String _getFilterDisplayName(String filter) {
    switch (filter) {
      case 'all':
        return 'All Notifications';
      case 'unread':
        return 'Unread';
      case 'missed_followup':
        return 'Missed Follow-ups';
      case 'new_assignment':
        return 'New Assignments';
      case 'reminder':
        return 'Reminders';
      case 'system_update':
        return 'System Updates';
      case 'emergency_alert':
        return 'Emergency Alerts';
      default:
        return 'All Notifications';
    }
  }

  IconData _getNotificationTypeIcon(String type) {
    switch (type) {
      case 'missed_followup':
        return Icons.schedule_outlined;
      case 'new_assignment':
        return Icons.assignment_outlined;
      case 'reminder':
        return Icons.notifications_outlined;
      case 'system_update':
        return Icons.system_update;
      case 'emergency_alert':
        return Icons.warning_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationTypeColor(String type) {
    switch (type) {
      case 'missed_followup':
        return Colors.orange;
      case 'new_assignment':
        return MadadgarTheme.primaryColor;
      case 'reminder':
        return Colors.blue;
      case 'system_update':
        return Colors.green;
      case 'emergency_alert':
        return MadadgarTheme.errorColor;
      default:
        return MadadgarTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MadadgarTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: MadadgarTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _showFilterBottomSheet,
            icon: const Icon(Icons.filter_list),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read),
                    SizedBox(width: 8),
                    Text('Mark All as Read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear All'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Notification Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unread'),
            Tab(text: 'Priority'),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Filter chip
            if (_selectedFilter != 'all') _buildActiveFilterChip(),
            
            // Notification content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNotificationList('all'),
                  _buildNotificationList('unread'),
                  _buildNotificationList('priority'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: MadadgarTheme.primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: MadadgarTheme.primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.filter_alt,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  _getFilterDisplayName(_selectedFilter),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => setState(() => _selectedFilter = 'all'),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(String tabType) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Notification count header
          Row(
            children: [
              Text(
                _getTabTitle(tabType),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MadadgarTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Loading...',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: MadadgarTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Notifications list placeholder
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getTabIcon(tabType),
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No ${_getTabTitle(tabType)} Found',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getEmptyMessage(tabType),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Sample notification examples
                  if (tabType == 'all') _buildSampleNotifications(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleNotifications() {
    return Column(
      children: [
        Text(
          'Example Notifications:',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildSampleNotificationCard(
          type: 'missed_followup',
          title: 'Missed Follow-up Alert',
          message: 'Patient Ahmad Khan missed hospital appointment',
          time: '2 hours ago',
        ),
        
        const SizedBox(height: 8),
        
        _buildSampleNotificationCard(
          type: 'new_assignment',
          title: 'New Patient Assignment',
          message: 'You have been assigned 3 new patients',
          time: '1 day ago',
        ),
        
        const SizedBox(height: 8),
        
        _buildSampleNotificationCard(
          type: 'reminder',
          title: 'Visit Reminder',
          message: 'Visit due for Maria Ahmed today',
          time: '3 hours ago',
        ),
      ],
    );
  }

  Widget _buildSampleNotificationCard({
    required String type,
    required String title,
    required String message,
    required String time,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNotificationTypeColor(type).withOpacity(0.1),
          child: Icon(
            _getNotificationTypeIcon(type),
            color: _getNotificationTypeColor(type),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        trailing: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _getNotificationTypeColor(type),
            shape: BoxShape.circle,
          ),
        ),
        onTap: () => _handleNotificationTap(type),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  String _getTabTitle(String tabType) {
    switch (tabType) {
      case 'unread':
        return 'Unread Notifications';
      case 'priority':
        return 'Priority Notifications';
      default:
        return 'All Notifications';
    }
  }

  IconData _getTabIcon(String tabType) {
    switch (tabType) {
      case 'unread':
        return Icons.mark_email_unread;
      case 'priority':
        return Icons.priority_high;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _getEmptyMessage(String tabType) {
    switch (tabType) {
      case 'unread':
        return 'You\'re all caught up!\nNo unread notifications at the moment.';
      case 'priority':
        return 'No urgent notifications.\nYou\'re on top of things!';
      default:
        return 'No notifications yet.\nYou\'ll see alerts and updates here when they arrive.';
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Notifications',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 300,
              child: SingleChildScrollView(
                child: Column(
                  children: _filterOptions.map((filter) => _buildFilterOption(filter)).toList(),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MadadgarTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Apply Filter',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String filter) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = filter);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? MadadgarTheme.primaryColor.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? MadadgarTheme.primaryColor
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? MadadgarTheme.primaryColor : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getFilterDisplayName(filter),
                style: GoogleFonts.poppins(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? MadadgarTheme.primaryColor : Colors.black87,
                ),
              ),
            ),
            if (filter != 'all') 
              Icon(
                _getNotificationTypeIcon(filter),
                color: _getNotificationTypeColor(filter),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'mark_all_read':
        _markAllAsRead();
        break;
      case 'clear_all':
        _clearAllNotifications();
        break;
      case 'settings':
        Navigator.pushNamed(context, '/notification-settings');
        break;
    }
  }

  void _handleNotificationTap(String type) {
    switch (type) {
      case 'missed_followup':
        Navigator.pushNamed(context, '/missed-followup-alert');
        break;
      case 'new_assignment':
        Navigator.pushNamed(context, '/patients');
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Opening notification details...',
              style: GoogleFonts.poppins(),
            ),
          ),
        );
    }
  }

  void _markAllAsRead() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'All notifications marked as read',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear All Notifications',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'All notifications cleared',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MadadgarTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Clear All',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }
}
