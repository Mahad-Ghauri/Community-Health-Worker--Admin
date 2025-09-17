import 'package:cloud_firestore/cloud_firestore.dart';

class Followup {
  final String followupId;
  final String patientId;
  final DateTime scheduledDate;
  final String status; // scheduled, completed, missed, cancelled, rescheduled
  final String facilityId;
  final String
  followupType; // routine_checkup, medication_review, lab_results, xray_followup, treatment_completion
  final String priority; // routine, important, urgent
  final String? notes;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? completedDate;
  final String? completedBy;
  final String? outcomeNotes;
  final DateTime? missedDate;
  final String? missedReason;
  final DateTime? rescheduledDate;
  final String? rescheduledBy;
  final bool sendReminder;
  final DateTime? reminderSentAt;
  // Scheduling extensions
  final int? durationMinutes; // default 30
  final String? assignedStaffId;
  final String? roomId;
  final String? seriesId; // recurring series grouping
  final String? seriesRule; // RRULE or similar text
  final String? cancelReason;
  final String? appointmentType; // visual categorization
  final String? urgencyLevel; // mirrors priority for integrations

  Followup({
    required this.followupId,
    required this.patientId,
    required this.scheduledDate,
    this.status = 'scheduled',
    required this.facilityId,
    required this.followupType,
    this.priority = 'routine',
    this.notes,
    required this.createdBy,
    required this.createdAt,
    this.completedDate,
    this.completedBy,
    this.outcomeNotes,
    this.missedDate,
    this.missedReason,
    this.rescheduledDate,
    this.rescheduledBy,
    this.sendReminder = true,
    this.reminderSentAt,
    this.durationMinutes,
    this.assignedStaffId,
    this.roomId,
    this.seriesId,
    this.seriesRule,
    this.cancelReason,
    this.appointmentType,
    this.urgencyLevel,
  });

  // Convert Followup to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'followupId': followupId,
      'patientId': patientId,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'status': status,
      'facilityId': facilityId,
      'followupType': followupType,
      'priority': priority,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedDate': completedDate != null
          ? Timestamp.fromDate(completedDate!)
          : null,
      'completedBy': completedBy,
      'outcomeNotes': outcomeNotes,
      'missedDate': missedDate != null ? Timestamp.fromDate(missedDate!) : null,
      'missedReason': missedReason,
      'rescheduledDate': rescheduledDate != null
          ? Timestamp.fromDate(rescheduledDate!)
          : null,
      'rescheduledBy': rescheduledBy,
      'sendReminder': sendReminder,
      'reminderSentAt': reminderSentAt != null
          ? Timestamp.fromDate(reminderSentAt!)
          : null,
      'durationMinutes': durationMinutes ?? 30,
      'assignedStaffId': assignedStaffId,
      'roomId': roomId,
      'seriesId': seriesId,
      'seriesRule': seriesRule,
      'cancelReason': cancelReason,
      'appointmentType': appointmentType,
      'urgencyLevel': urgencyLevel ?? priority,
    };
  }

  // Create Followup from Firestore document
  factory Followup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Followup(
      followupId: doc.id,
      patientId: data['patientId'] ?? '',
      scheduledDate:
          (data['scheduledDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'scheduled',
      facilityId: data['facilityId'] ?? '',
      followupType: data['followupType'] ?? 'routine_checkup',
      priority: data['priority'] ?? 'routine',
      notes: data['notes'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedDate: (data['completedDate'] as Timestamp?)?.toDate(),
      completedBy: data['completedBy'],
      outcomeNotes: data['outcomeNotes'],
      missedDate: (data['missedDate'] as Timestamp?)?.toDate(),
      missedReason: data['missedReason'],
      rescheduledDate: (data['rescheduledDate'] as Timestamp?)?.toDate(),
      rescheduledBy: data['rescheduledBy'],
      sendReminder: data['sendReminder'] ?? true,
      reminderSentAt: (data['reminderSentAt'] as Timestamp?)?.toDate(),
      durationMinutes: (data['durationMinutes'] as int?) ?? 30,
      assignedStaffId: data['assignedStaffId'],
      roomId: data['roomId'],
      seriesId: data['seriesId'],
      seriesRule: data['seriesRule'],
      cancelReason: data['cancelReason'],
      appointmentType: data['appointmentType'],
      urgencyLevel: data['urgencyLevel'] ?? data['priority'],
    );
  }

  // Create from Map
  factory Followup.fromMap(Map<String, dynamic> data, String id) {
    return Followup(
      followupId: id,
      patientId: data['patientId'] ?? '',
      scheduledDate:
          (data['scheduledDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'scheduled',
      facilityId: data['facilityId'] ?? '',
      followupType: data['followupType'] ?? 'routine_checkup',
      priority: data['priority'] ?? 'routine',
      notes: data['notes'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedDate: (data['completedDate'] as Timestamp?)?.toDate(),
      completedBy: data['completedBy'],
      outcomeNotes: data['outcomeNotes'],
      missedDate: (data['missedDate'] as Timestamp?)?.toDate(),
      missedReason: data['missedReason'],
      rescheduledDate: (data['rescheduledDate'] as Timestamp?)?.toDate(),
      rescheduledBy: data['rescheduledBy'],
      sendReminder: data['sendReminder'] ?? true,
      reminderSentAt: (data['reminderSentAt'] as Timestamp?)?.toDate(),
      durationMinutes: (data['durationMinutes'] as int?) ?? 30,
      assignedStaffId: data['assignedStaffId'],
      roomId: data['roomId'],
      seriesId: data['seriesId'],
      seriesRule: data['seriesRule'],
      cancelReason: data['cancelReason'],
      appointmentType: data['appointmentType'],
      urgencyLevel: data['urgencyLevel'] ?? data['priority'],
    );
  }

  // Copy with method for immutable updates
  Followup copyWith({
    String? followupId,
    String? patientId,
    DateTime? scheduledDate,
    String? status,
    String? facilityId,
    String? followupType,
    String? priority,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? completedDate,
    String? completedBy,
    String? outcomeNotes,
    DateTime? missedDate,
    String? missedReason,
    DateTime? rescheduledDate,
    String? rescheduledBy,
    bool? sendReminder,
    DateTime? reminderSentAt,
    int? durationMinutes,
    String? assignedStaffId,
    String? roomId,
    String? seriesId,
    String? seriesRule,
    String? cancelReason,
    String? appointmentType,
    String? urgencyLevel,
  }) {
    return Followup(
      followupId: followupId ?? this.followupId,
      patientId: patientId ?? this.patientId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      facilityId: facilityId ?? this.facilityId,
      followupType: followupType ?? this.followupType,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      completedDate: completedDate ?? this.completedDate,
      completedBy: completedBy ?? this.completedBy,
      outcomeNotes: outcomeNotes ?? this.outcomeNotes,
      missedDate: missedDate ?? this.missedDate,
      missedReason: missedReason ?? this.missedReason,
      rescheduledDate: rescheduledDate ?? this.rescheduledDate,
      rescheduledBy: rescheduledBy ?? this.rescheduledBy,
      sendReminder: sendReminder ?? this.sendReminder,
      reminderSentAt: reminderSentAt ?? this.reminderSentAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
      roomId: roomId ?? this.roomId,
      seriesId: seriesId ?? this.seriesId,
      seriesRule: seriesRule ?? this.seriesRule,
      cancelReason: cancelReason ?? this.cancelReason,
      appointmentType: appointmentType ?? this.appointmentType,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
    );
  }

  // Status constants
  static const String statusScheduled = 'scheduled';
  static const String statusCompleted = 'completed';
  static const String statusMissed = 'missed';
  static const String statusCancelled = 'cancelled';
  static const String statusRescheduled = 'rescheduled';

  // Priority constants
  static const String priorityRoutine = 'routine';
  static const String priorityImportant = 'important';
  static const String priorityUrgent = 'urgent';

  // Followup type constants
  static const String typeRoutineCheckup = 'routine_checkup';
  static const String typeMedicationReview = 'medication_review';
  static const String typeLabResults = 'lab_results';
  static const String typeXrayFollowup = 'xray_followup';
  static const String typeTreatmentCompletion = 'treatment_completion';

  // Helper methods
  bool get isScheduled => status == statusScheduled;
  bool get isCompleted => status == statusCompleted;
  bool get isMissed => status == statusMissed;
  bool get isCancelled => status == statusCancelled;
  bool get isRescheduled => status == statusRescheduled;

  bool get isRoutinePriority => priority == priorityRoutine;
  bool get isImportantPriority => priority == priorityImportant;
  bool get isUrgentPriority => priority == priorityUrgent;

  // Status display helpers
  String get statusDisplayName {
    switch (status) {
      case statusScheduled:
        return 'Scheduled';
      case statusCompleted:
        return 'Completed';
      case statusMissed:
        return 'Missed';
      case statusCancelled:
        return 'Cancelled';
      case statusRescheduled:
        return 'Rescheduled';
      default:
        return 'Unknown Status';
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case priorityRoutine:
        return 'Routine';
      case priorityImportant:
        return 'Important';
      case priorityUrgent:
        return 'Urgent';
      default:
        return 'Unknown Priority';
    }
  }

  String get followupTypeDisplayName {
    switch (followupType) {
      case typeRoutineCheckup:
        return 'Routine Checkup';
      case typeMedicationReview:
        return 'Medication Review';
      case typeLabResults:
        return 'Lab Results';
      case typeXrayFollowup:
        return 'X-Ray Follow-up';
      case typeTreatmentCompletion:
        return 'Treatment Completion';
      default:
        return 'Unknown Type';
    }
  }

  // Time-related helpers
  bool get isToday {
    final now = DateTime.now();
    return scheduledDate.year == now.year &&
        scheduledDate.month == now.month &&
        scheduledDate.day == now.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return scheduledDate.year == tomorrow.year &&
        scheduledDate.month == tomorrow.month &&
        scheduledDate.day == tomorrow.day;
  }

  bool get isPast {
    return scheduledDate.isBefore(DateTime.now()) && !isToday;
  }

  bool get isUpcoming {
    return scheduledDate.isAfter(DateTime.now());
  }

  bool get isOverdue {
    return isPast && isScheduled;
  }

  // Calculate days until/since appointment
  int get daysUntilAppointment {
    if (isPast) return 0;
    return scheduledDate.difference(DateTime.now()).inDays;
  }

  int get daysSinceScheduled {
    return DateTime.now().difference(createdAt).inDays;
  }

  // Format dates for display
  String get formattedScheduledDate {
    return '${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}';
  }

  String get formattedScheduledDateTime {
    return '$formattedScheduledDate ${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}';
  }

  String? get formattedCompletedDate {
    if (completedDate == null) return null;
    return '${completedDate!.day}/${completedDate!.month}/${completedDate!.year}';
  }

  // Check if reminder should be sent
  bool get shouldSendReminder {
    return sendReminder &&
        isScheduled &&
        reminderSentAt == null &&
        daysUntilAppointment <= 1; // Send reminder 1 day before
  }

  // Validation methods
  bool get isValid {
    return patientId.isNotEmpty &&
        facilityId.isNotEmpty &&
        followupType.isNotEmpty &&
        createdBy.isNotEmpty;
  }

  // Check if followup can be modified
  bool get canBeModified {
    return isScheduled && isUpcoming;
  }

  // Check if followup can be completed
  bool get canBeCompleted {
    return isScheduled && (isToday || isPast);
  }

  // Check if followup can be cancelled
  bool get canBeCancelled {
    return isScheduled && isUpcoming;
  }

  // Check if followup can be rescheduled
  bool get canBeRescheduled {
    return (isScheduled || isMissed) && isUpcoming;
  }

  // Get priority color for UI
  String get priorityColor {
    switch (priority) {
      case priorityRoutine:
        return '#4CAF50'; // Green
      case priorityImportant:
        return '#FF9800'; // Orange
      case priorityUrgent:
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  // Get status color for UI
  String get statusColor {
    switch (status) {
      case statusScheduled:
        return '#2196F3'; // Blue
      case statusCompleted:
        return '#4CAF50'; // Green
      case statusMissed:
        return '#F44336'; // Red
      case statusCancelled:
        return '#9E9E9E'; // Grey
      case statusRescheduled:
        return '#FF9800'; // Orange
      default:
        return '#9E9E9E';
    }
  }

  // Helper method to create new followup
  static Followup createNew({
    required String patientId,
    required DateTime scheduledDate,
    required String facilityId,
    required String followupType,
    required String createdBy,
    String priority = priorityRoutine,
    String? notes,
    bool sendReminder = true,
    int durationMinutes = 30,
    String? assignedStaffId,
    String? roomId,
    String? appointmentType,
  }) {
    return Followup(
      followupId: '', // Will be set by Firestore
      patientId: patientId,
      scheduledDate: scheduledDate,
      facilityId: facilityId,
      followupType: followupType,
      priority: priority,
      notes: notes,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      sendReminder: sendReminder,
      durationMinutes: durationMinutes,
      assignedStaffId: assignedStaffId,
      roomId: roomId,
      appointmentType: appointmentType,
    );
  }

  // Get all priority options
  static List<String> get allPriorities => [
    priorityRoutine,
    priorityImportant,
    priorityUrgent,
  ];

  // Get all status options
  static List<String> get allStatuses => [
    statusScheduled,
    statusCompleted,
    statusMissed,
    statusCancelled,
    statusRescheduled,
  ];

  // Get all followup type options
  static List<String> get allFollowupTypes => [
    typeRoutineCheckup,
    typeMedicationReview,
    typeLabResults,
    typeXrayFollowup,
    typeTreatmentCompletion,
  ];

  @override
  String toString() {
    return 'Followup(followupId: $followupId, patientId: $patientId, scheduledDate: $formattedScheduledDateTime, status: $status, type: $followupType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Followup && other.followupId == followupId;
  }

  @override
  int get hashCode => followupId.hashCode;
}
