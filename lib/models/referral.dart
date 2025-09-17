import 'package:cloud_firestore/cloud_firestore.dart';

class Referral {
  final String referralId;
  final String patientId;
  final String referringCHWId;
  final String referringFacilityId;
  final String receivingFacilityId;
  final DateTime referralDate;
  final String status; // pending, accepted, declined, completed
  final String urgency; // low, medium, high, urgent
  final String referralReason;
  final String? symptoms;
  final String? clinicalNotes;
  final String? referringCHWNotes;
  final DateTime? responseDate;
  final String? respondedBy;
  final String? responseNotes;
  final String? declineReason;
  final DateTime? acceptedDate;
  final String? acceptedBy;
  final DateTime? completedDate;
  final String? outcome;
  final List<String>? attachments; // URLs to images or documents
  final Map<String, dynamic>?
  patientCondition; // Vital signs, symptoms severity
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? appointmentDate;
  final String? assignedStaffId;

  Referral({
    required this.referralId,
    required this.patientId,
    required this.referringCHWId,
    required this.referringFacilityId,
    required this.receivingFacilityId,
    required this.referralDate,
    this.status = 'pending',
    this.urgency = 'medium',
    required this.referralReason,
    this.symptoms,
    this.clinicalNotes,
    this.referringCHWNotes,
    this.responseDate,
    this.respondedBy,
    this.responseNotes,
    this.declineReason,
    this.acceptedDate,
    this.acceptedBy,
    this.completedDate,
    this.outcome,
    this.attachments,
    this.patientCondition,
    required this.createdAt,
    this.updatedAt,
    this.appointmentDate,
    this.assignedStaffId,
  });

  // Convert Referral to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'referralId': referralId,
      'patientId': patientId,
      'referringCHWId': referringCHWId,
      'referringFacilityId': referringFacilityId,
      'receivingFacilityId': receivingFacilityId,
      'referralDate': Timestamp.fromDate(referralDate),
      'status': status,
      'urgency': urgency,
      'referralReason': referralReason,
      'symptoms': symptoms,
      'clinicalNotes': clinicalNotes,
      'referringCHWNotes': referringCHWNotes,
      'responseDate': responseDate != null
          ? Timestamp.fromDate(responseDate!)
          : null,
      'respondedBy': respondedBy,
      'responseNotes': responseNotes,
      'declineReason': declineReason,
      'acceptedDate': acceptedDate != null
          ? Timestamp.fromDate(acceptedDate!)
          : null,
      'acceptedBy': acceptedBy,
      'completedDate': completedDate != null
          ? Timestamp.fromDate(completedDate!)
          : null,
      'outcome': outcome,
      'attachments': attachments,
      'patientCondition': patientCondition,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'appointmentDate': appointmentDate != null
          ? Timestamp.fromDate(appointmentDate!)
          : null,
      'assignedStaffId': assignedStaffId,
    };
  }

  // Create Referral from Firestore document
  factory Referral.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Referral(
      referralId: doc.id,
      patientId: data['patientId'] ?? '',
      referringCHWId: data['referringCHWId'] ?? '',
      referringFacilityId: data['referringFacilityId'] ?? '',
      receivingFacilityId: data['receivingFacilityId'] ?? '',
      referralDate:
          (data['referralDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
      urgency: data['urgency'] ?? 'medium',
      referralReason: data['referralReason'] ?? '',
      symptoms: data['symptoms'],
      clinicalNotes: data['clinicalNotes'],
      referringCHWNotes: data['referringCHWNotes'],
      responseDate: (data['responseDate'] as Timestamp?)?.toDate(),
      respondedBy: data['respondedBy'],
      responseNotes: data['responseNotes'],
      declineReason: data['declineReason'],
      acceptedDate: (data['acceptedDate'] as Timestamp?)?.toDate(),
      acceptedBy: data['acceptedBy'],
      completedDate: (data['completedDate'] as Timestamp?)?.toDate(),
      outcome: data['outcome'],
      attachments: data['attachments'] != null
          ? List<String>.from(data['attachments'])
          : null,
      patientCondition: data['patientCondition']?.cast<String, dynamic>(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      appointmentDate: (data['appointmentDate'] as Timestamp?)?.toDate(),
      assignedStaffId: data['assignedStaffId'],
    );
  }

  // Create from Map
  factory Referral.fromMap(Map<String, dynamic> data, String id) {
    return Referral(
      referralId: id,
      patientId: data['patientId'] ?? '',
      referringCHWId: data['referringCHWId'] ?? '',
      referringFacilityId: data['referringFacilityId'] ?? '',
      receivingFacilityId: data['receivingFacilityId'] ?? '',
      referralDate:
          (data['referralDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
      urgency: data['urgency'] ?? 'medium',
      referralReason: data['referralReason'] ?? '',
      symptoms: data['symptoms'],
      clinicalNotes: data['clinicalNotes'],
      referringCHWNotes: data['referringCHWNotes'],
      responseDate: (data['responseDate'] as Timestamp?)?.toDate(),
      respondedBy: data['respondedBy'],
      responseNotes: data['responseNotes'],
      declineReason: data['declineReason'],
      acceptedDate: (data['acceptedDate'] as Timestamp?)?.toDate(),
      acceptedBy: data['acceptedBy'],
      completedDate: (data['completedDate'] as Timestamp?)?.toDate(),
      outcome: data['outcome'],
      attachments: data['attachments'] != null
          ? List<String>.from(data['attachments'])
          : null,
      patientCondition: data['patientCondition']?.cast<String, dynamic>(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      appointmentDate: (data['appointmentDate'] as Timestamp?)?.toDate(),
      assignedStaffId: data['assignedStaffId'],
    );
  }

  // Copy with method for immutable updates
  Referral copyWith({
    String? referralId,
    String? patientId,
    String? referringCHWId,
    String? referringFacilityId,
    String? receivingFacilityId,
    DateTime? referralDate,
    String? status,
    String? urgency,
    String? referralReason,
    String? symptoms,
    String? clinicalNotes,
    String? referringCHWNotes,
    DateTime? responseDate,
    String? respondedBy,
    String? responseNotes,
    String? declineReason,
    DateTime? acceptedDate,
    String? acceptedBy,
    DateTime? completedDate,
    String? outcome,
    List<String>? attachments,
    Map<String, dynamic>? patientCondition,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? appointmentDate,
    String? assignedStaffId,
  }) {
    return Referral(
      referralId: referralId ?? this.referralId,
      patientId: patientId ?? this.patientId,
      referringCHWId: referringCHWId ?? this.referringCHWId,
      referringFacilityId: referringFacilityId ?? this.referringFacilityId,
      receivingFacilityId: receivingFacilityId ?? this.receivingFacilityId,
      referralDate: referralDate ?? this.referralDate,
      status: status ?? this.status,
      urgency: urgency ?? this.urgency,
      referralReason: referralReason ?? this.referralReason,
      symptoms: symptoms ?? this.symptoms,
      clinicalNotes: clinicalNotes ?? this.clinicalNotes,
      referringCHWNotes: referringCHWNotes ?? this.referringCHWNotes,
      responseDate: responseDate ?? this.responseDate,
      respondedBy: respondedBy ?? this.respondedBy,
      responseNotes: responseNotes ?? this.responseNotes,
      declineReason: declineReason ?? this.declineReason,
      acceptedDate: acceptedDate ?? this.acceptedDate,
      acceptedBy: acceptedBy ?? this.acceptedBy,
      completedDate: completedDate ?? this.completedDate,
      outcome: outcome ?? this.outcome,
      attachments: attachments ?? this.attachments,
      patientCondition: patientCondition ?? this.patientCondition,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
    );
  }

  // Status constants
  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusDeclined = 'declined';
  static const String statusCompleted = 'completed';

  // Urgency constants
  static const String urgencyLow = 'low';
  static const String urgencyMedium = 'medium';
  static const String urgencyHigh = 'high';
  static const String urgencyUrgent = 'urgent';

  // Helper methods
  bool get isPending => status == statusPending;
  bool get isAccepted => status == statusAccepted;
  bool get isDeclined => status == statusDeclined;
  bool get isCompleted => status == statusCompleted;

  bool get isLowUrgency => urgency == urgencyLow;
  bool get isMediumUrgency => urgency == urgencyMedium;
  bool get isHighUrgency => urgency == urgencyHigh;
  bool get isUrgentUrgency => urgency == urgencyUrgent;

  // Status display helpers
  String get statusDisplayName {
    switch (status) {
      case statusPending:
        return 'Pending';
      case statusAccepted:
        return 'Accepted';
      case statusDeclined:
        return 'Declined';
      case statusCompleted:
        return 'Completed';
      default:
        return 'Unknown Status';
    }
  }

  String get urgencyDisplayName {
    switch (urgency) {
      case urgencyLow:
        return 'Low';
      case urgencyMedium:
        return 'Medium';
      case urgencyHigh:
        return 'High';
      case urgencyUrgent:
        return 'Urgent';
      default:
        return 'Unknown Urgency';
    }
  }

  // Time-related helpers
  bool get isToday {
    final now = DateTime.now();
    return referralDate.year == now.year &&
        referralDate.month == now.month &&
        referralDate.day == now.day;
  }

  bool get isRecent {
    return DateTime.now().difference(referralDate).inDays <= 7;
  }

  bool get isOverdue {
    return isPending && DateTime.now().difference(referralDate).inDays > 3;
  }

  // Calculate days since referral
  int get daysSinceReferral {
    return DateTime.now().difference(referralDate).inDays;
  }

  // Calculate response time
  int? get responseTimeInDays {
    if (responseDate == null) return null;
    return responseDate!.difference(referralDate).inDays;
  }

  // Format dates for display
  String get formattedReferralDate {
    return '${referralDate.day}/${referralDate.month}/${referralDate.year}';
  }

  String? get formattedResponseDate {
    if (responseDate == null) return null;
    return '${responseDate!.day}/${responseDate!.month}/${responseDate!.year}';
  }

  String? get formattedAcceptedDate {
    if (acceptedDate == null) return null;
    return '${acceptedDate!.day}/${acceptedDate!.month}/${acceptedDate!.year}';
  }

  String? get formattedCompletedDate {
    if (completedDate == null) return null;
    return '${completedDate!.day}/${completedDate!.month}/${completedDate!.year}';
  }

  // Check if referral has attachments
  bool get hasAttachments => attachments != null && attachments!.isNotEmpty;

  // Get attachment count
  int get attachmentCount => attachments?.length ?? 0;

  // Check if referral has patient condition data
  bool get hasPatientCondition =>
      patientCondition != null && patientCondition!.isNotEmpty;

  // Validation methods
  bool get isValid {
    return patientId.isNotEmpty &&
        referringCHWId.isNotEmpty &&
        referringFacilityId.isNotEmpty &&
        receivingFacilityId.isNotEmpty &&
        referralReason.isNotEmpty;
  }

  // Check if referral can be responded to
  bool get canBeResponded {
    return isPending;
  }

  // Check if referral can be accepted
  bool get canBeAccepted {
    return isPending;
  }

  // Check if referral can be declined
  bool get canBeDeclined {
    return isPending;
  }

  // Check if referral can be completed
  bool get canBeCompleted {
    return isAccepted;
  }

  // Get urgency color for UI
  String get urgencyColor {
    switch (urgency) {
      case urgencyLow:
        return '#4CAF50'; // Green
      case urgencyMedium:
        return '#FF9800'; // Orange
      case urgencyHigh:
        return '#F44336'; // Red
      case urgencyUrgent:
        return '#9C27B0'; // Purple
      default:
        return '#9E9E9E'; // Grey
    }
  }

  // Get status color for UI
  String get statusColor {
    switch (status) {
      case statusPending:
        return '#FF9800'; // Orange
      case statusAccepted:
        return '#2196F3'; // Blue
      case statusDeclined:
        return '#F44336'; // Red
      case statusCompleted:
        return '#4CAF50'; // Green
      default:
        return '#9E9E9E'; // Grey
    }
  }

  // Helper method to create new referral
  static Referral createNew({
    required String patientId,
    required String referringCHWId,
    required String referringFacilityId,
    required String receivingFacilityId,
    required String referralReason,
    String urgency = urgencyMedium,
    String? symptoms,
    String? clinicalNotes,
    String? referringCHWNotes,
    List<String>? attachments,
    Map<String, dynamic>? patientCondition,
  }) {
    return Referral(
      referralId: '', // Will be set by Firestore
      patientId: patientId,
      referringCHWId: referringCHWId,
      referringFacilityId: referringFacilityId,
      receivingFacilityId: receivingFacilityId,
      referralDate: DateTime.now(),
      urgency: urgency,
      referralReason: referralReason,
      symptoms: symptoms,
      clinicalNotes: clinicalNotes,
      referringCHWNotes: referringCHWNotes,
      attachments: attachments,
      patientCondition: patientCondition,
      createdAt: DateTime.now(),
    );
  }

  // Get all urgency options
  static List<String> get allUrgencies => [
    urgencyLow,
    urgencyMedium,
    urgencyHigh,
    urgencyUrgent,
  ];

  // Get all status options
  static List<String> get allStatuses => [
    statusPending,
    statusAccepted,
    statusDeclined,
    statusCompleted,
  ];

  // Common referral reasons
  static List<String> get commonReferralReasons => [
    'Suspected TB',
    'Treatment monitoring',
    'Drug resistance suspected',
    'Treatment failure',
    'Severe side effects',
    'Complications',
    'Laboratory tests required',
    'X-ray required',
    'Specialist consultation',
    'Treatment completion assessment',
  ];

  @override
  String toString() {
    return 'Referral(referralId: $referralId, patientId: $patientId, status: $status, urgency: $urgency, reason: $referralReason)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Referral && other.referralId == referralId;
  }

  @override
  int get hashCode => referralId.hashCode;
}
