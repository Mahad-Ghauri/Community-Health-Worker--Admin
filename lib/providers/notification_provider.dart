import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chw_notification.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<CHWNotification> _notifications = [];
  CHWNotification? _selectedNotification;
  bool _isLoading = false;
  String? _error;
  Map<String, int> _statistics = {};

  // Filter properties
  String? _selectedType;
  String? _selectedStatus;
  String? _selectedPriority;
  String _searchTerm = '';
  String? _userId; // For staff/CHW specific notifications
  bool _showSystemNotifications = true;
  DateTimeRange? _dateRange;

  // Getters
  List<CHWNotification> get notifications => _notifications;
  CHWNotification? get selectedNotification => _selectedNotification;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, int> get statistics => _statistics;

  // Filter getters
  String? get selectedType => _selectedType;
  String? get selectedStatus => _selectedStatus;
  String? get selectedPriority => _selectedPriority;
  String get searchTerm => _searchTerm;
  bool get showSystemNotifications => _showSystemNotifications;
  DateTimeRange? get dateRange => _dateRange;

  // Filtered notifications
  List<CHWNotification> get filteredNotifications {
    var filtered = _notifications;

    // Filter by user if set
    if (_userId != null) {
      filtered = filtered.where((notification) => notification.userId == _userId).toList();
    }

    // Filter by type
    if (_selectedType != null && _selectedType!.isNotEmpty) {
      filtered = filtered.where((notification) => notification.type == _selectedType).toList();
    }

    // Filter by status
    if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
      filtered = filtered.where((notification) => notification.status == _selectedStatus).toList();
    }

    // Filter by priority
    if (_selectedPriority != null && _selectedPriority!.isNotEmpty) {
      filtered = filtered.where((notification) => notification.priority == _selectedPriority).toList();
    }

    // Filter system notifications
    if (!_showSystemNotifications) {
      filtered = filtered.where((notification) => !notification.isSystemNotification).toList();
    }

    // Date range filter
    if (_dateRange != null) {
      filtered = filtered.where((notification) =>
          notification.sentAt.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
          notification.sentAt.isBefore(_dateRange!.end.add(const Duration(days: 1)))).toList();
    }

    // Search filter
    if (_searchTerm.isNotEmpty) {
      final searchLower = _searchTerm.toLowerCase();
      filtered = filtered.where((notification) =>
          notification.title.toLowerCase().contains(searchLower) ||
          notification.message.toLowerCase().contains(searchLower)).toList();
    }

    return filtered;
  }

  // Get unread notifications
  List<CHWNotification> get unreadNotifications => 
      _notifications.where((notification) => notification.isUnread).toList();

  // Get recent notifications (last 24 hours)
  List<CHWNotification> get recentNotifications {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _notifications.where((notification) => 
        notification.sentAt.isAfter(yesterday)).toList();
  }

  // Get priority notifications
  List<CHWNotification> get urgentNotifications => 
      _notifications.where((notification) => notification.isUrgentPriority).toList();

  List<CHWNotification> get highPriorityNotifications => 
      _notifications.where((notification) => notification.isHighPriority).toList();

  // Set user context (for staff or CHW specific notifications)
  void setUserId(String userId) {
    _userId = userId;
    notifyListeners();
  }

  // Load notifications for user
  Future<void> loadNotifications() async {
    if (_userId == null) return;
    
    _setLoading(true);
    _setError(null);

    try {
      // Listen to notifications stream
      _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _userId)
          .orderBy('sentAt', descending: true)
          .snapshots()
          .listen(
        (snapshot) {
          _notifications = snapshot.docs
              .map((doc) => CHWNotification.fromFirestore(doc))
              .toList();
          _setLoading(false);
          notifyListeners();
        },
        onError: (error) {
          _setError('Failed to load notifications: $error');
          _setLoading(false);
        },
      );
    } catch (e) {
      _setError('Failed to load notifications: $e');
      _setLoading(false);
    }
  }

  // Load all notifications (for admin view)
  Future<void> loadAllNotifications() async {
    _setLoading(true);
    _setError(null);

    try {
      // Listen to all notifications stream
      _firestore
          .collection('notifications')
          .orderBy('sentAt', descending: true)
          .limit(500) // Limit to avoid too much data
          .snapshots()
          .listen(
        (snapshot) {
          _notifications = snapshot.docs
              .map((doc) => CHWNotification.fromFirestore(doc))
              .toList();
          _setLoading(false);
          notifyListeners();
        },
        onError: (error) {
          _setError('Failed to load notifications: $error');
          _setLoading(false);
        },
      );
    } catch (e) {
      _setError('Failed to load notifications: $e');
      _setLoading(false);
    }
  }

  // Create new notification
  Future<String?> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String priority = CHWNotification.priorityMedium,
    String? relatedId,
    String? actionUrl,
    bool isSystemNotification = false,
    DateTime? expiresAt,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      // Create notification
      final notification = CHWNotification.createNew(
        userId: userId,
        type: type,
        title: title,
        message: message,
        priority: priority,
        relatedId: relatedId,
        actionUrl: actionUrl,
        isSystemNotification: isSystemNotification,
        expiresAt: expiresAt,
      );

      final docRef = await _firestore
          .collection('notifications')
          .add(notification.toFirestore());

      _setLoading(false);
      await loadStatistics();
      return docRef.id;
    } catch (e) {
      _setError('Failed to create notification: $e');
      _setLoading(false);
      return null;
    }
  }

  // Send bulk notifications
  Future<bool> sendBulkNotifications({
    required List<String> userIds,
    required String type,
    required String title,
    required String message,
    String priority = CHWNotification.priorityMedium,
    String? relatedId,
    String? actionUrl,
    bool isSystemNotification = false,
    DateTime? expiresAt,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final batch = _firestore.batch();
      
      for (final userId in userIds) {
        final notification = CHWNotification.createNew(
          userId: userId,
          type: type,
          title: title,
          message: message,
          priority: priority,
          relatedId: relatedId,
          actionUrl: actionUrl,
          isSystemNotification: isSystemNotification,
          expiresAt: expiresAt,
        );

        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, notification.toFirestore());
      }
      
      await batch.commit();
      
      _setLoading(false);
      await loadStatistics();
      return true;
    } catch (e) {
      _setError('Failed to send bulk notifications: $e');
      _setLoading(false);
      return false;
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({
        'status': CHWNotification.statusRead,
        'readAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local state
      final index = _notifications.indexWhere((n) => n.notificationId == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          status: CHWNotification.statusRead,
          readAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to mark notification as read: $e');
      return false;
    }
  }

  // Mark notification as dismissed
  Future<bool> dismissNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({
        'status': CHWNotification.statusDismissed,
        'dismissedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local state
      final index = _notifications.indexWhere((n) => n.notificationId == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          status: CHWNotification.statusDismissed,
          dismissedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to dismiss notification: $e');
      return false;
    }
  }

  // Mark all notifications as read for user
  Future<bool> markAllAsRead() async {
    if (_userId == null) return false;

    _setLoading(true);
    _setError(null);

    try {
      final unreadNotifications = _notifications.where((n) => n.isUnread).toList();
      
      if (unreadNotifications.isEmpty) {
        _setLoading(false);
        return true;
      }

      final batch = _firestore.batch();
      
      for (final notification in unreadNotifications) {
        final notificationRef = _firestore.collection('notifications').doc(notification.notificationId);
        batch.update(notificationRef, {
          'status': CHWNotification.statusRead,
          'readAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to mark all notifications as read: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();

      // Remove from local state
      _notifications.removeWhere((n) => n.notificationId == notificationId);
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to delete notification: $e');
      return false;
    }
  }

  // Delete old notifications (cleanup)
  Future<bool> deleteOldNotifications({int daysOld = 30}) async {
    _setLoading(true);
    _setError(null);

    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      final oldNotifications = await _firestore
          .collection('notifications')
          .where('sentAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      
      for (final doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete old notifications: $e');
      _setLoading(false);
      return false;
    }
  }

  // Load notification by ID
  Future<void> loadNotificationById(String notificationId) async {
    _setLoading(true);
    _setError(null);

    try {
      final doc = await _firestore
          .collection('notifications')
          .doc(notificationId)
          .get();

      if (doc.exists) {
        _selectedNotification = CHWNotification.fromFirestore(doc);
      } else {
        _setError('Notification not found');
      }
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load notification: $e');
      _setLoading(false);
    }
  }

  // Load statistics
  Future<void> loadStatistics() async {
    try {
      final notifications = _notifications;

      _statistics = {
        'total': notifications.length,
        'unread': notifications.where((n) => n.isUnread).length,
        'read': notifications.where((n) => n.isRead).length,
        'dismissed': notifications.where((n) => n.isDismissed).length,
        'urgent': notifications.where((n) => n.isUrgentPriority).length,
        'high': notifications.where((n) => n.isHighPriority).length,
        'today': notifications.where((n) => n.isToday).length,
        'recent': notifications.where((n) => n.isRecent).length,
        'expired': notifications.where((n) => n.isExpired).length,
        'system': notifications.where((n) => n.isSystemNotification).length,
      };

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load notification statistics: $e');
      }
    }
  }

  // Filter methods
  void searchNotifications(String searchTerm) {
    _searchTerm = searchTerm;
    notifyListeners();
  }

  void filterByType(String? type) {
    _selectedType = type;
    notifyListeners();
  }

  void filterByStatus(String? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void filterByPriority(String? priority) {
    _selectedPriority = priority;
    notifyListeners();
  }

  void toggleSystemNotifications() {
    _showSystemNotifications = !_showSystemNotifications;
    notifyListeners();
  }

  void filterByDateRange(DateTimeRange? dateRange) {
    _dateRange = dateRange;
    notifyListeners();
  }

  void clearFilters() {
    _selectedType = null;
    _selectedStatus = null;
    _selectedPriority = null;
    _searchTerm = '';
    _dateRange = null;
    _showSystemNotifications = true;
    notifyListeners();
  }

  // Selection methods
  void selectNotification(CHWNotification notification) {
    _selectedNotification = notification;
    notifyListeners();
  }

  void clearSelectedNotification() {
    _selectedNotification = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Utility methods
  List<CHWNotification> getNotificationsByType(String type) {
    return _notifications.where((notification) => notification.type == type).toList();
  }

  List<CHWNotification> getNotificationsByPriority(String priority) {
    return _notifications.where((notification) => notification.priority == priority).toList();
  }

  List<CHWNotification> getTodaysNotifications() {
    return _notifications.where((notification) => notification.isToday).toList();
  }

  List<CHWNotification> getExpiredNotifications() {
    return _notifications.where((notification) => notification.isExpired).toList();
  }

  // Get notification count for badge
  int get unreadCount => unreadNotifications.length;
  int get urgentCount => urgentNotifications.length;

  // Check if user has urgent notifications
  bool get hasUrgentNotifications => urgentNotifications.isNotEmpty;

  // Get notifications grouped by type
  Map<String, List<CHWNotification>> getNotificationsByTypeGrouped() {
    final Map<String, List<CHWNotification>> byType = {};
    for (final notification in _notifications) {
      byType[notification.type] = [...(byType[notification.type] ?? []), notification];
    }
    return byType;
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Helper getters for UI
  bool get hasActiveFilters {
    return _selectedType != null ||
        _selectedStatus != null ||
        _selectedPriority != null ||
        _searchTerm.isNotEmpty ||
        _dateRange != null ||
        !_showSystemNotifications;
  }

  int get totalNotificationsCount => _notifications.length;
  int get filteredNotificationsCount => filteredNotifications.length;

  String get filtersDescription {
    final filters = <String>[];
    
    if (_searchTerm.isNotEmpty) {
      filters.add('Search: "$_searchTerm"');
    }
    if (_selectedType != null) {
      filters.add('Type: $_selectedType');
    }
    if (_selectedStatus != null) {
      filters.add('Status: $_selectedStatus');
    }
    if (_selectedPriority != null) {
      filters.add('Priority: $_selectedPriority');
    }
    if (!_showSystemNotifications) {
      filters.add('Excluding system notifications');
    }
    if (_dateRange != null) {
      filters.add('Date: ${_dateRange!.start.toString().split(' ')[0]} - ${_dateRange!.end.toString().split(' ')[0]}');
    }
    
    return filters.join(', ');
  }

  @override
  void dispose() {
    super.dispose();
  }
}