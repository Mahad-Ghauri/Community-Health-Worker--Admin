import 'package:cloud_firestore/cloud_firestore.dart';

class CHWNotification {
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
    };
  }
  final String notificationId;
  final String userId; // CHW ID
  final String type; // 'missed_followup', 'new_assignment', 'reminder', 'system_update', 'emergency_alert'
  final String title;
  final String message;
  final String? relatedId; // Patient ID, Visit ID, etc.
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String status; // 'unread', 'read', 'archived'
  final DateTime sentAt;
  final DateTime? readAt;

  CHWNotification({
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedId,
    required this.priority,
    required this.status,
    required this.sentAt,
    this.readAt,
  });

  factory CHWNotification.fromFirestore(Map<String, dynamic> data) {
    return CHWNotification(
      notificationId: data['notificationId'] ?? '',
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      relatedId: data['relatedId'],
      priority: data['priority'] ?? 'medium',
      status: data['status'] ?? 'unread',
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
    );
  }
}