// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chw_tb/config/theme.dart';

class NotificationsListScreen extends StatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  State<NotificationsListScreen> createState() => _NotificationsListScreenState();
}

class _NotificationsListScreenState extends State<NotificationsListScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;
  
  bool _isLoading = false;
  String _selectedFilter = 'all';
  
  // Mock notifications data
  List<Map<String, dynamic>> _notifications = [];

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
    
    _loadNotifications();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _loadNotifications() {
    setState(() => _isLoading = true);
    
    // Mock notifications data
    _notifications = [
      {
        'id': '1',
        'type': 'missed_followup',
        'title': 'Missed Follow-up',
        'message': 'Ahmad Khan missed scheduled visit',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
        'isRead': false,
        'priority': 'high',
        'patientId': 'PAT001',
        'patientName': 'Ahmad Khan',
        'actionRequired': true,
      },
      {
        'id': '2',
        'type': 'new_assignment',
        'title': 'New Patient Assignment',
        'message': 'New TB patient assigned to your care',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        'isRead': false,
        'priority': 'medium',
        'patientId': 'PAT005',
        'patientName': 'Fatima Sheikh',
        'actionRequired': true,
      },
      {
        'id': '3',
        'type': 'reminder',
        'title': 'Medication Reminder',
        'message': 'Time to check pill count for 3 patients',
        'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
        'isRead': true,
        'priority': 'medium',
        'actionRequired': false,
      },
      {
        'id': '4',
        'type': 'system_update',
        'title': 'App Update Available',
        'message': 'Version 2.1.0 is now available with new features',
        'timestamp': DateTime.now().subtract(const Duration(days: 1)),
        'isRead': true,
        'priority': 'low',
        'actionRequired': false,
      },
      {
        'id': '5',
        'type': 'emergency_alert',
        'title': 'Emergency Protocol Update',
        'message': 'New COVID-19 safety guidelines for TB patients',
        'timestamp': DateTime.now().subtract(const Duration(days: 2)),
        'isRead': false,
        'priority': 'high',
        'actionRequired': true,
      },
      {
        'id': '6',
        'type': 'missed_followup',
        'title': 'Multiple Missed Visits',
        'message': 'Sarah Khan has missed 3 consecutive visits',
        'timestamp': DateTime.now().subtract(const Duration(days: 3)),
        'isRead': true,
        'priority': 'high',
        'patientId': 'PAT003',
        'patientName': 'Sarah Khan',
        'actionRequired': true,
      },
    ];
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MadadgarTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Notifications',
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
            onPressed: () => _markAllAsRead(),
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark All Read',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings),
                    const SizedBox(width: 8),
                    Text('Notification Settings', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    const Icon(Icons.clear_all),
                    const SizedBox(width: 8),
                    Text('Clear All', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              _buildNotificationsSummary(),
              TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Unread'),
                  Tab(text: 'Action Required'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildFilterChips(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildNotificationsList(_notifications),
                        _buildNotificationsList(_notifications.where((n) => !n['isRead']).toList()),
                        _buildNotificationsList(_notifications.where((n) => n['actionRequired']).toList()),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNotificationsSummary() {
    int unreadCount = _notifications.where((n) => !n['isRead']).length;
    int actionRequiredCount = _notifications.where((n) => n['actionRequired']).length;
    int highPriorityCount = _notifications.where((n) => n['priority'] == 'high').length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem('Unread', unreadCount.toString(), Colors.red),
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _buildSummaryItem('Action Required', actionRequiredCount.toString(), Colors.orange),
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _buildSummaryItem('High Priority', highPriorityCount.toString(), Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
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

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'All', 'icon': Icons.list},
      {'key': 'missed_followup', 'label': 'Missed Follow-up', 'icon': Icons.person_off},
      {'key': 'new_assignment', 'label': 'New Assignment', 'icon': Icons.person_add},
      {'key': 'reminder', 'label': 'Reminders', 'icon': Icons.alarm},
      {'key': 'emergency_alert', 'label': 'Emergency', 'icon': Icons.emergency},
      {'key': 'system_update', 'label': 'System', 'icon': Icons.system_update},
    ];
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            bool isSelected = _selectedFilter == filter['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : MadadgarTheme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      filter['label'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isSelected ? Colors.white : MadadgarTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                selectedColor: MadadgarTheme.primaryColor,
                backgroundColor: Colors.white,
                side: BorderSide(color: MadadgarTheme.primaryColor),
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter['key'] as String;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotificationsList(List<Map<String, dynamic>> notifications) {
    List<Map<String, dynamic>> filteredNotifications = notifications;
    
    if (_selectedFilter != 'all') {
      filteredNotifications = notifications.where((n) => n['type'] == _selectedFilter).toList();
    }
    
    if (filteredNotifications.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredNotifications.length,
      itemBuilder: (context, index) {
        return _buildNotificationItem(filteredNotifications[index]);
      },
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    bool isUnread = !notification['isRead'];
    String priority = notification['priority'] ?? 'medium';
    Color priorityColor = _getPriorityColor(priority);
    IconData typeIcon = _getNotificationIcon(notification['type']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isUnread ? 4 : 1,
        child: InkWell(
          onTap: () => _openNotification(notification),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: isUnread ? Border.all(color: priorityColor, width: 2) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        typeIcon,
                        color: priorityColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification['title'],
                                  style: GoogleFonts.poppins(
                                    fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              if (isUnread)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: priorityColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            _formatTimestamp(notification['timestamp']),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (action) => _handleNotificationAction(action, notification),
                      itemBuilder: (context) => [
                        if (isUnread)
                          PopupMenuItem(
                            value: 'mark_read',
                            child: Row(
                              children: [
                                const Icon(Icons.mark_email_read, size: 16),
                                const SizedBox(width: 8),
                                Text('Mark as Read', style: GoogleFonts.poppins(fontSize: 12)),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete, size: 16, color: Colors.red),
                              const SizedBox(width: 8),
                              Text('Delete', style: GoogleFonts.poppins(fontSize: 12, color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Message
                Text(
                  notification['message'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                
                // Patient info if available
                if (notification['patientName'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Patient: ${notification['patientName']}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (notification['patientId'] != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(${notification['patientId']})',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                
                // Action buttons
                if (notification['actionRequired']) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _takeAction(notification),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: priorityColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text(
                            _getActionButtonText(notification['type']),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _dismissNotification(notification),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade400),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(
                          'Dismiss',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Priority indicator
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          priority.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: priorityColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (notification['type'] == 'missed_followup')
                        Icon(Icons.schedule, size: 14, color: Colors.red),
                      if (notification['actionRequired'])
                        Icon(Icons.priority_high, size: 14, color: Colors.orange),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            'You\'re all caught up!',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'missed_followup':
        return Icons.person_off;
      case 'new_assignment':
        return Icons.person_add;
      case 'reminder':
        return Icons.alarm;
      case 'system_update':
        return Icons.system_update;
      case 'emergency_alert':
        return Icons.emergency;
      default:
        return Icons.notifications;
    }
  }

  String _getActionButtonText(String type) {
    switch (type) {
      case 'missed_followup':
        return 'Trace Patient';
      case 'new_assignment':
        return 'View Patient';
      case 'emergency_alert':
        return 'View Details';
      default:
        return 'Take Action';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'settings':
        _openNotificationSettings();
        break;
      case 'clear':
        _clearAllNotifications();
        break;
    }
  }

  void _handleNotificationAction(String action, Map<String, dynamic> notification) {
    switch (action) {
      case 'mark_read':
        _markAsRead(notification);
        break;
      case 'delete':
        _deleteNotification(notification);
        break;
    }
  }

  void _openNotification(Map<String, dynamic> notification) {
    // Mark as read when opened
    if (!notification['isRead']) {
      setState(() {
        notification['isRead'] = true;
      });
    }
    
    // Navigate based on notification type
    String type = notification['type'];
    switch (type) {
      case 'missed_followup':
        Navigator.pushNamed(context, '/missed-followup-alert', arguments: notification);
        break;
      case 'new_assignment':
        Navigator.pushNamed(context, '/patient-details', arguments: notification['patientId']);
        break;
      default:
        _showNotificationDetails(notification);
    }
  }

  void _takeAction(Map<String, dynamic> notification) {
    String type = notification['type'];
    switch (type) {
      case 'missed_followup':
        Navigator.pushNamed(context, '/missed-followup-alert', arguments: notification);
        break;
      case 'new_assignment':
        Navigator.pushNamed(context, '/patient-details', arguments: notification['patientId']);
        break;
      case 'emergency_alert':
        _showEmergencyDetails(notification);
        break;
      default:
        _showNotificationDetails(notification);
    }
  }

  void _markAsRead(Map<String, dynamic> notification) {
    setState(() {
      notification['isRead'] = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification marked as read', style: GoogleFonts.poppins()),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteNotification(Map<String, dynamic> notification) {
    setState(() {
      _notifications.removeWhere((n) => n['id'] == notification['id']);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification deleted', style: GoogleFonts.poppins()),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _notifications.add(notification);
            });
          },
        ),
      ),
    );
  }

  void _dismissNotification(Map<String, dynamic> notification) {
    setState(() {
      notification['actionRequired'] = false;
      notification['isRead'] = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification dismissed', style: GoogleFonts.poppins()),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All notifications marked as read', style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Notifications', style: GoogleFonts.poppins()),
        content: Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _notifications.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('All notifications cleared', style: GoogleFonts.poppins()),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Clear All', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openNotificationSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notification settings coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification['title'], style: GoogleFonts.poppins()),
        content: Text(notification['message'], style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showEmergencyDetails(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.emergency, color: Colors.red),
            const SizedBox(width: 8),
            Text(notification['title'], style: GoogleFonts.poppins()),
          ],
        ),
        content: Text(notification['message'], style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Acknowledge', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}
