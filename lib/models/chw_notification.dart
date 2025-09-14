import 'package:cloud_firestore/cloud_firestore.dart';

class CHWNotification {
  final String notificationId;
  final String userId; // CHW or Staff user ID
  final String type; // new_assignment, referral_accepted, referral_declined, followup_scheduled, followup_reminder, etc.
  final String title;
  final String message;
  final String? relatedId; // ID of related patient, assignment, referral, etc.
  final String priority; // low, medium, high, urgent
  final String status; // unread, read, dismissed
  final DateTime sentAt;
  final DateTime? readAt;
  final DateTime? dismissedAt;
  final Map<String, dynamic>? data; // Additional data for the notification
  final String? actionUrl; // Deep link or route to relevant screen
  final bool isSystemNotification; // System vs user-generated
  final String? senderUserId; // User who triggered this notification
  final DateTime? expiresAt; // Optional expiration date

  CHWNotification({
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedId,
    this.priority = 'medium',
    this.status = 'unread',
    required this.sentAt,
    this.readAt,
    this.dismissedAt,
    this.data,
    this.actionUrl,
    this.isSystemNotification = false,
    this.senderUserId,
    this.expiresAt,
  });

  // Convert CHWNotification to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'relatedId': relatedId,
      'priority': priority,
      'status': status,
      'sentAt': Timestamp.fromDate(sentAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'dismissedAt': dismissedAt != null ? Timestamp.fromDate(dismissedAt!) : null,
      'data': data,
      'actionUrl': actionUrl,
      'isSystemNotification': isSystemNotification,
      'senderUserId': senderUserId,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  // Create CHWNotification from Firestore document
  factory CHWNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CHWNotification(
      notificationId: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      relatedId: data['relatedId'],
      priority: data['priority'] ?? 'medium',
      status: data['status'] ?? 'unread',
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      dismissedAt: (data['dismissedAt'] as Timestamp?)?.toDate(),
      data: data['data']?.cast<String, dynamic>(),
      actionUrl: data['actionUrl'],
      isSystemNotification: data['isSystemNotification'] ?? false,
      senderUserId: data['senderUserId'],
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  // Create from Map
  factory CHWNotification.fromMap(Map<String, dynamic> data, String id) {
    return CHWNotification(
      notificationId: id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      relatedId: data['relatedId'],
      priority: data['priority'] ?? 'medium',
      status: data['status'] ?? 'unread',
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      dismissedAt: (data['dismissedAt'] as Timestamp?)?.toDate(),
      data: data['data']?.cast<String, dynamic>(),
      actionUrl: data['actionUrl'],
      isSystemNotification: data['isSystemNotification'] ?? false,
      senderUserId: data['senderUserId'],
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  // Copy with method for immutable updates
  CHWNotification copyWith({
    String? notificationId,
    String? userId,
    String? type,
    String? title,
    String? message,
    String? relatedId,
    String? priority,
    String? status,
    DateTime? sentAt,
    DateTime? readAt,
    DateTime? dismissedAt,
    Map<String, dynamic>? data,
    String? actionUrl,
    bool? isSystemNotification,
    String? senderUserId,
    DateTime? expiresAt,
  }) {
    return CHWNotification(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      relatedId: relatedId ?? this.relatedId,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
      isSystemNotification: isSystemNotification ?? this.isSystemNotification,
      senderUserId: senderUserId ?? this.senderUserId,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  // Type constants
  static const String typeNewAssignment = 'new_assignment';
  static const String typeReferralAccepted = 'referral_accepted';
  static const String typeReferralDeclined = 'referral_declined';
  static const String typeFollowupScheduled = 'followup_scheduled';
  static const String typeFollowupReminder = 'followup_reminder';
  static const String typeFollowupCompleted = 'followup_completed';
  static const String typeFollowupMissed = 'followup_missed';
  static const String typePatientUpdated = 'patient_updated';
  static const String typeSystemAlert = 'system_alert';
  static const String typeTaskReminder = 'task_reminder';

  // Priority constants
  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';
  static const String priorityUrgent = 'urgent';

  // Status constants
  static const String statusUnread = 'unread';
  static const String statusRead = 'read';
  static const String statusDismissed = 'dismissed';

  // Helper methods
  bool get isUnread => status == statusUnread;
  bool get isRead => status == statusRead;
  bool get isDismissed => status == statusDismissed;

  bool get isLowPriority => priority == priorityLow;
  bool get isMediumPriority => priority == priorityMedium;
  bool get isHighPriority => priority == priorityHigh;
  bool get isUrgentPriority => priority == priorityUrgent;

  // Type checking helpers
  bool get isAssignmentNotification => type == typeNewAssignment;
  bool get isReferralNotification => type == typeReferralAccepted || type == typeReferralDeclined;
  bool get isFollowupNotification => [
    typeFollowupScheduled,
    typeFollowupReminder,
    typeFollowupCompleted,
    typeFollowupMissed
  ].contains(type);

  // Status display helpers
  String get statusDisplayName {
    switch (status) {
      case statusUnread:
        return 'Unread';
      case statusRead:
        return 'Read';
      case statusDismissed:
        return 'Dismissed';
      default:
        return 'Unknown Status';
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case priorityLow:
        return 'Low';
      case priorityMedium:
        return 'Medium';
      case priorityHigh:
        return 'High';
      case priorityUrgent:
        return 'Urgent';
      default:
        return 'Unknown Priority';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case typeNewAssignment:
        return 'New Assignment';
      case typeReferralAccepted:
        return 'Referral Accepted';
      case typeReferralDeclined:
        return 'Referral Declined';
      case typeFollowupScheduled:
        return 'Follow-up Scheduled';
      case typeFollowupReminder:
        return 'Follow-up Reminder';
      case typeFollowupCompleted:
        return 'Follow-up Completed';
      case typeFollowupMissed:
        return 'Follow-up Missed';
      case typePatientUpdated:
        return 'Patient Updated';
      case typeSystemAlert:
        return 'System Alert';
      case typeTaskReminder:
        return 'Task Reminder';
      default:
        return 'Notification';
    }
  }

  // Time-related helpers
  bool get isToday {
    final now = DateTime.now();
    return sentAt.year == now.year && 
           sentAt.month == now.month && 
           sentAt.day == now.day;
  }

  bool get isRecent {
    return DateTime.now().difference(sentAt).inHours <= 24;
  }

  bool get isExpired {
    return expiresAt != null && DateTime.now().isAfter(expiresAt!);
  }

  // Calculate time since sent
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(sentAt);

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

  // Format dates for display
  String get formattedSentDate {
    return '${sentAt.day}/${sentAt.month}/${sentAt.year}';
  }

  String get formattedSentDateTime {
    return '${formattedSentDate} ${sentAt.hour.toString().padLeft(2, '0')}:${sentAt.minute.toString().padLeft(2, '0')}';
  }

  String? get formattedReadDate {
    if (readAt == null) return null;
    return '${readAt!.day}/${readAt!.month}/${readAt!.year}';
  }

  // Check if notification has additional data
  bool get hasData => data != null && data!.isNotEmpty;

  // Check if notification has action URL
  bool get hasAction => actionUrl != null && actionUrl!.isNotEmpty;

  // Validation methods
  bool get isValid {
    return userId.isNotEmpty && 
           type.isNotEmpty &&
           title.isNotEmpty &&
           message.isNotEmpty;
  }

  // Check if notification can be marked as read
  bool get canBeRead {
    return isUnread;
  }

  // Check if notification can be dismissed
  bool get canBeDismissed {
    return !isDismissed;
  }

  // Get priority color for UI
  String get priorityColor {
    switch (priority) {
      case priorityLow:
        return '#4CAF50'; // Green
      case priorityMedium:
        return '#2196F3'; // Blue
      case priorityHigh:
        return '#FF9800'; // Orange
      case priorityUrgent:
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  // Get type icon for UI
  String get typeIcon {
    switch (type) {
      case typeNewAssignment:
        return 'assignment_ind';
      case typeReferralAccepted:
        return 'check_circle';
      case typeReferralDeclined:
        return 'cancel';
      case typeFollowupScheduled:
        return 'event_available';
      case typeFollowupReminder:
        return 'alarm';
      case typeFollowupCompleted:
        return 'event_note';
      case typeFollowupMissed:
        return 'event_busy';
      case typePatientUpdated:
        return 'person';
      case typeSystemAlert:
        return 'warning';
      case typeTaskReminder:
        return 'task_alt';
      default:
        return 'notifications';
    }
  }

  // Helper method to create new notification
  static CHWNotification createNew({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? relatedId,
    String priority = priorityMedium,
    Map<String, dynamic>? data,
    String? actionUrl,
    bool isSystemNotification = false,
    String? senderUserId,
    DateTime? expiresAt,
  }) {
    return CHWNotification(
      notificationId: '', // Will be set by Firestore
      userId: userId,
      type: type,
      title: title,
      message: message,
      relatedId: relatedId,
      priority: priority,
      sentAt: DateTime.now(),
      data: data,
      actionUrl: actionUrl,
      isSystemNotification: isSystemNotification,
      senderUserId: senderUserId,
      expiresAt: expiresAt,
    );
  }

  // Get all type options
  static List<String> get allTypes => [
    typeNewAssignment,
    typeReferralAccepted,
    typeReferralDeclined,
    typeFollowupScheduled,
    typeFollowupReminder,
    typeFollowupCompleted,
    typeFollowupMissed,
    typePatientUpdated,
    typeSystemAlert,
    typeTaskReminder,
  ];

  // Get all priority options
  static List<String> get allPriorities => [
    priorityLow,
    priorityMedium,
    priorityHigh,
    priorityUrgent,
  ];

  // Get all status options
  static List<String> get allStatuses => [
    statusUnread,
    statusRead,
    statusDismissed,
  ];

  @override
  String toString() {
    return 'CHWNotification(notificationId: $notificationId, userId: $userId, type: $type, title: $title, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CHWNotification && other.notificationId == notificationId;
  }

  @override
  int get hashCode => notificationId.hashCode;
}