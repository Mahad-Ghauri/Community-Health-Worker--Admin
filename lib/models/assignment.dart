import 'package:cloud_firestore/cloud_firestore.dart';

class Assignment {
  final String assignmentId;
  final String chwId;
  final List<String> patientIds;
  final String assignedBy;
  final String facilityId;
  final DateTime assignedDate;
  final String status; // active, completed, cancelled
  final String workArea;
  final String priority; // low, medium, high, urgent
  final String? notes;
  final DateTime? completedDate;
  final String? completedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Assignment({
    required this.assignmentId,
    required this.chwId,
    required this.patientIds,
    required this.assignedBy,
    required this.facilityId,
    required this.assignedDate,
    this.status = 'active',
    required this.workArea,
    this.priority = 'medium',
    this.notes,
    this.completedDate,
    this.completedBy,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert Assignment to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'assignmentId': assignmentId,
      'chwId': chwId,
      'patientIds': patientIds,
      'assignedBy': assignedBy,
      'facilityId': facilityId,
      'assignedDate': Timestamp.fromDate(assignedDate),
      'status': status,
      'workArea': workArea,
      'priority': priority,
      'notes': notes,
      'completedDate': completedDate != null ? Timestamp.fromDate(completedDate!) : null,
      'completedBy': completedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create Assignment from Firestore document
  factory Assignment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Assignment(
      assignmentId: doc.id,
      chwId: data['chwId'] ?? '',
      patientIds: List<String>.from(data['patientIds'] ?? []),
      assignedBy: data['assignedBy'] ?? '',
      facilityId: data['facilityId'] ?? '',
      assignedDate: (data['assignedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'active',
      workArea: data['workArea'] ?? '',
      priority: data['priority'] ?? 'medium',
      notes: data['notes'],
      completedDate: (data['completedDate'] as Timestamp?)?.toDate(),
      completedBy: data['completedBy'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Create from Map
  factory Assignment.fromMap(Map<String, dynamic> data, String id) {
    return Assignment(
      assignmentId: id,
      chwId: data['chwId'] ?? '',
      patientIds: List<String>.from(data['patientIds'] ?? []),
      assignedBy: data['assignedBy'] ?? '',
      facilityId: data['facilityId'] ?? '',
      assignedDate: (data['assignedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'active',
      workArea: data['workArea'] ?? '',
      priority: data['priority'] ?? 'medium',
      notes: data['notes'],
      completedDate: (data['completedDate'] as Timestamp?)?.toDate(),
      completedBy: data['completedBy'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Copy with method for immutable updates
  Assignment copyWith({
    String? assignmentId,
    String? chwId,
    List<String>? patientIds,
    String? assignedBy,
    String? facilityId,
    DateTime? assignedDate,
    String? status,
    String? workArea,
    String? priority,
    String? notes,
    DateTime? completedDate,
    String? completedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Assignment(
      assignmentId: assignmentId ?? this.assignmentId,
      chwId: chwId ?? this.chwId,
      patientIds: patientIds ?? this.patientIds,
      assignedBy: assignedBy ?? this.assignedBy,
      facilityId: facilityId ?? this.facilityId,
      assignedDate: assignedDate ?? this.assignedDate,
      status: status ?? this.status,
      workArea: workArea ?? this.workArea,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      completedDate: completedDate ?? this.completedDate,
      completedBy: completedBy ?? this.completedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Status constants
  static const String statusActive = 'active';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // Priority constants
  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';
  static const String priorityUrgent = 'urgent';

  // Helper methods
  bool get isActive => status == statusActive;
  bool get isCompleted => status == statusCompleted;
  bool get isCancelled => status == statusCancelled;
  
  bool get isLowPriority => priority == priorityLow;
  bool get isMediumPriority => priority == priorityMedium;
  bool get isHighPriority => priority == priorityHigh;
  bool get isUrgentPriority => priority == priorityUrgent;

  // Status display helpers
  String get statusDisplayName {
    switch (status) {
      case statusActive:
        return 'Active';
      case statusCompleted:
        return 'Completed';
      case statusCancelled:
        return 'Cancelled';
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

  // Get patient count
  int get patientCount => patientIds.length;

  // Calculate days since assignment
  int get daysSinceAssignment {
    return DateTime.now().difference(assignedDate).inDays;
  }

  // Calculate days since completion
  int? get daysSinceCompletion {
    if (completedDate == null) return null;
    return DateTime.now().difference(completedDate!).inDays;
  }

  // Check if assignment is overdue (more than 30 days active)
  bool get isOverdue {
    return isActive && daysSinceAssignment > 30;
  }

  // Check if assignment is recent (less than 7 days)
  bool get isRecent {
    return daysSinceAssignment <= 7;
  }

  // Format dates for display
  String get formattedAssignedDate {
    return '${assignedDate.day}/${assignedDate.month}/${assignedDate.year}';
  }

  String? get formattedCompletedDate {
    if (completedDate == null) return null;
    return '${completedDate!.day}/${completedDate!.month}/${completedDate!.year}';
  }

  // Validation methods
  bool get isValid {
    return chwId.isNotEmpty && 
           patientIds.isNotEmpty &&
           assignedBy.isNotEmpty &&
           facilityId.isNotEmpty &&
           workArea.isNotEmpty;
  }

  // Check if assignment can be modified
  bool get canBeModified {
    return isActive && daysSinceAssignment <= 1; // Can modify within 24 hours
  }

  // Check if assignment can be completed
  bool get canBeCompleted {
    return isActive;
  }

  // Check if assignment can be cancelled
  bool get canBeCancelled {
    return isActive;
  }

  // Get priority color for UI
  String get priorityColor {
    switch (priority) {
      case priorityLow:
        return '#4CAF50'; // Green
      case priorityMedium:
        return '#FF9800'; // Orange
      case priorityHigh:
        return '#F44336'; // Red
      case priorityUrgent:
        return '#9C27B0'; // Purple
      default:
        return '#9E9E9E'; // Grey
    }
  }

  // Get status color for UI
  String get statusColor {
    switch (status) {
      case statusActive:
        return '#2196F3'; // Blue
      case statusCompleted:
        return '#4CAF50'; // Green
      case statusCancelled:
        return '#9E9E9E'; // Grey
      default:
        return '#9E9E9E';
    }
  }

  // Helper method to create new assignment
  static Assignment createNew({
    required String chwId,
    required List<String> patientIds,
    required String assignedBy,
    required String facilityId,
    required String workArea,
    String priority = priorityMedium,
    String? notes,
  }) {
    return Assignment(
      assignmentId: '', // Will be set by Firestore
      chwId: chwId,
      patientIds: patientIds,
      assignedBy: assignedBy,
      facilityId: facilityId,
      assignedDate: DateTime.now(),
      workArea: workArea,
      priority: priority,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  // Get all priority options
  static List<String> get allPriorities => [
    priorityLow,
    priorityMedium,
    priorityHigh,
    priorityUrgent,
  ];

  // Get all status options
  static List<String> get allStatuses => [
    statusActive,
    statusCompleted,
    statusCancelled,
  ];

  @override
  String toString() {
    return 'Assignment(assignmentId: $assignmentId, chwId: $chwId, patientCount: $patientCount, status: $status, priority: $priority)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Assignment && other.assignmentId == assignmentId;
  }

  @override
  int get hashCode => assignmentId.hashCode;
}