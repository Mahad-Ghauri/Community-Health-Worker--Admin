

// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

// =================== CHW CREATED COLLECTIONS ===================

/// Users Collection - CHW registration and profile management
/// Created by: CHW Registration Screen (Screen 2)
/// Used by: Login (3), Forgot Password (4), Profile Settings (28)
class CHWUser {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String workingArea;
  final String role; // Always 'chw' for CHWs
  final String status; // 'active', 'inactive'
  final String? facilityId; // Null because CHWs can work at multiple facilities
  final String idNumber; // Automatically generated CHW ID (CHW001, CHW002, etc.)
  final String? dateOfBirth; // Date of birth
  final String? gender; // Genderif first-time setup is done
  final DateTime createdAt;

  CHWUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.workingArea,
    this.role = 'chw',
    this.status = 'active',
    this.facilityId, // Keep null for multi-facility work
    required this.idNumber, // Required auto-generated ID
    this.dateOfBirth,
    this.gender,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'workingArea': workingArea,
      'role': role,
      'status': status,
      'facilityId': facilityId, // Null for multi-facility CHWs
      'idNumber': idNumber, // Auto-generated CHW ID
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CHWUser.fromFirestore(Map<String, dynamic> data) {
    return CHWUser(
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      workingArea: data['workingArea'] ?? '',
      role: data['role'] ?? 'chw',
      status: data['status'] ?? 'active',
      facilityId: data['facilityId'], // Null for multi-facility CHWs
      idNumber: data['idNumber'] ?? '', // Auto-generated CHW ID
      dateOfBirth: data['dateOfBirth'],
      gender: data['gender'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Patients Collection - TB patient registration and management
/// Created by: Register New Patient Screen (Screen 10)
/// Used by: Patient List (8), Patient Search (9), Patient Details (11), Edit Patient (12)
class Patient {
  final String patientId;
  final String name;
  final int age;
  final String phone;
  final String address;
  final String gender;
  final String tbStatus; // 'newly_diagnosed', 'on_treatment', 'treatment_completed', 'lost_to_followup'
  final String assignedCHW;
  final String assignedFacility;
  final String treatmentFacility;
  final Map<String, double> gpsLocation;
  final bool consent;
  final String? consentSignature;
  final String createdBy;
  final String? validatedBy;
  final DateTime createdAt;
  final DateTime? diagnosisDate;

  Patient({
    required this.patientId,
    required this.name,
    required this.age,
    required this.phone,
    required this.address,
    required this.gender,
    required this.tbStatus,
    required this.assignedCHW,
    required this.assignedFacility,
    required this.treatmentFacility,
    required this.gpsLocation,
    required this.consent,
    this.consentSignature,
    required this.createdBy,
    this.validatedBy,
    required this.createdAt,
    this.diagnosisDate,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'name': name,
      'age': age,
      'phone': phone,
      'address': address,
      'gender': gender,
      'tbStatus': tbStatus,
      'assignedCHW': assignedCHW,
      'assignedFacility': assignedFacility,
      'treatmentFacility': treatmentFacility,
      'gpsLocation': gpsLocation,
      'consent': consent,
      'consentSignature': consentSignature,
      'createdBy': createdBy,
      'validatedBy': validatedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'diagnosisDate': diagnosisDate != null ? Timestamp.fromDate(diagnosisDate!) : null,
    };
  }

  factory Patient.fromFirestore(Map<String, dynamic> data) {
    return Patient(
      patientId: data['patientId'] ?? '',
      name: data['name'] ?? '',
      age: data['age'] ?? 0,
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      gender: data['gender'] ?? '',
      tbStatus: data['tbStatus'] ?? '',
      assignedCHW: data['assignedCHW'] ?? '',
      assignedFacility: data['assignedFacility'] ?? '',
      treatmentFacility: data['treatmentFacility'] ?? '',
      gpsLocation: Map<String, double>.from(data['gpsLocation'] ?? {}),
      consent: data['consent'] ?? false,
      consentSignature: data['consentSignature'],
      createdBy: data['createdBy'] ?? '',
      validatedBy: data['validatedBy'],
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      diagnosisDate: _parseDateTime(data['diagnosisDate']),
    );
  }

  /// Helper method to parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Warning: Failed to parse date string: $value');
        return null;
      }
    }
    
    return null;
  }
}

/// Visits Collection - Every CHW visit to patient with GPS proof
/// Created by: New Visit Screen (Screen 14)
/// Used by: Visit List (13), Visit Details (15), Home Dashboard (6)
class Visit {
  final String visitId;
  final String patientId;
  final String chwId;
  final String visitType; // 'home_visit', 'follow_up', 'tracing', 'medicine_delivery', 'counseling'
  final DateTime date;
  final bool found; // Patient found/not found toggle
  final String notes;
  final Map<String, double> gpsLocation;
  final List<String>? photos; // Photo capture URLs

  Visit({
    required this.visitId,
    required this.patientId,
    required this.chwId,
    required this.visitType,
    required this.date,
    required this.found,
    required this.notes,
    required this.gpsLocation,
    this.photos,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'visitId': visitId,
      'patientId': patientId,
      'chwId': chwId,
      'visitType': visitType,
      'date': Timestamp.fromDate(date),
      'found': found,
      'notes': notes,
      'gpsLocation': gpsLocation,
      'photos': photos,
    };
  }

  factory Visit.fromFirestore(Map<String, dynamic> data) {
    return Visit(
      visitId: data['visitId'] ?? '',
      patientId: data['patientId'] ?? '',
      chwId: data['chwId'] ?? '',
      visitType: data['visitType'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      found: data['found'] ?? false,
      notes: data['notes'] ?? '',
      gpsLocation: Map<String, double>.from(data['gpsLocation'] ?? {}),
      photos: data['photos'] != null ? List<String>.from(data['photos']) : null,
    );
  }
}

/// Households Collection - Family members of TB patients
/// Created by: Add Household Member Screen (Screen 17)
/// Used by: Household Members Screen (Screen 16)
class Household {
  final String householdId;
  final String patientId; // Index patient
  final String address;
  final int totalMembers;
  final int screenedMembers;
  final List<HouseholdMember> members;
  final DateTime createdAt;

  Household({
    required this.householdId,
    required this.patientId,
    required this.address,
    required this.totalMembers,
    required this.screenedMembers,
    required this.members,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'householdId': householdId,
      'patientId': patientId,
      'address': address,
      'totalMembers': totalMembers,
      'screenedMembers': screenedMembers,
      'members': members.map((member) => member.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Household.fromFirestore(Map<String, dynamic> data) {
    return Household(
      householdId: data['householdId'] ?? '',
      patientId: data['patientId'] ?? '',
      address: data['address'] ?? '',
      totalMembers: data['totalMembers'] ?? 0,
      screenedMembers: data['screenedMembers'] ?? 0,
      members: (data['members'] as List<dynamic>?)
              ?.map((memberData) => HouseholdMember.fromMap(memberData))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Household Member - Sub-document for households
class HouseholdMember {
  final String name;
  final int age;
  final String gender;
  final String relationship; // to index patient
  final String? phone;
  final bool screened;
  final String screeningStatus; // 'not_screened', 'negative', 'positive', 'pending'
  final DateTime? lastScreeningDate;

  HouseholdMember({
    required this.name,
    required this.age,
    required this.gender,
    required this.relationship,
    this.phone,
    this.screened = false,
    this.screeningStatus = 'not_screened',
    this.lastScreeningDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'relationship': relationship,
      'phone': phone,
      'screened': screened,
      'screeningStatus': screeningStatus,
      'lastScreeningDate': lastScreeningDate != null ? Timestamp.fromDate(lastScreeningDate!) : null,
    };
  }

  factory HouseholdMember.fromMap(Map<String, dynamic> data) {
    // Extract relationship from name if present (e.g., "Khadija Ali (Wife)" -> "Wife")
    String name = data['name'] ?? '';
    String relationship = '';
    if (name.contains('(') && name.contains(')')) {
      final start = name.lastIndexOf('(');
      final end = name.lastIndexOf(')');
      if (start != -1 && end != -1 && end > start) {
        relationship = name.substring(start + 1, end);
        name = name.substring(0, start).trim();
      }
    }
    
    // Handle both 'result' and 'screeningStatus' fields for compatibility
    String screeningStatus = data['screeningStatus'] ?? data['result'] ?? 'not_screened';
    if (screeningStatus == 'not_tested') {
      screeningStatus = 'not_screened';
    }
    
    return HouseholdMember(
      name: name,
      age: data['age'] ?? 0,
      gender: data['gender'] ?? 'Unknown',
      relationship: data['relationship'] ?? relationship,
      phone: data['phone'],
      screened: data['screened'] ?? false,
      screeningStatus: screeningStatus,
      lastScreeningDate: (data['lastScreeningDate'] as Timestamp?)?.toDate(),
    );
  }
}

/// Treatment Adherence Collection - Medicine taking records by CHWs
/// Created by: Adherence Tracking Screen (Screen 20)
/// Used by: Patient Details (11), Side Effects Log (21), Pill Count (22)
class TreatmentAdherence {
  final String adherenceId;
  final String patientId;
  final String? visitId; // Optional - can be standalone or linked to visit
  final DateTime date;
  final String reportedBy; // CHW ID
  final Map<String, String> dosesToday; // 'morning': 'taken', 'evening': 'missed', etc.
  final List<String> sideEffects; // From predefined list
  final Map<String, int> pillsRemaining; // Map of medication name to remaining pills
  final double adherenceScore; // Calculated percentage
  final bool counselingGiven;
  final String notes;

  TreatmentAdherence({
    required this.adherenceId,
    required this.patientId,
    this.visitId,
    required this.date,
    required this.reportedBy,
    required this.dosesToday,
    required this.sideEffects,
    required this.pillsRemaining,
    required this.adherenceScore,
    required this.counselingGiven,
    required this.notes,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'adherenceId': adherenceId,
      'patientId': patientId,
      'visitId': visitId,
      'date': Timestamp.fromDate(date),
      'reportedBy': reportedBy,
      'dosesToday': dosesToday,
      'sideEffects': sideEffects,
      'pillsRemaining': pillsRemaining,
      'adherenceScore': adherenceScore,
      'counselingGiven': counselingGiven,
      'notes': notes,
    };
  }

  factory TreatmentAdherence.fromFirestore(Map<String, dynamic> data) {
    return TreatmentAdherence(
      adherenceId: data['adherenceId'] ?? '',
      patientId: data['patientId'] ?? '',
      visitId: data['visitId'],
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reportedBy: data['reportedBy'] ?? '',
      dosesToday: Map<String, String>.from(data['dosesToday'] ?? {}),
      sideEffects: List<String>.from(data['sideEffects'] ?? []),
      pillsRemaining: data['pillsRemaining'] is Map 
          ? Map<String, int>.from(data['pillsRemaining']) 
          : <String, int>{}, // Handle legacy int format
      adherenceScore: (data['adherenceScore'] ?? 0).toDouble(),
      counselingGiven: data['counselingGiven'] ?? false,
      notes: data['notes'] ?? '',
    );
  }
}

/// Contact Tracing Collection - Family screening results by CHWs
/// Created by: Contact Screening Screen (Screen 18)
/// Used by: Screening Results Screen (Screen 19)
class ContactTracing {
  final String contactId;
  final String householdId;
  final String indexPatientId;
  final String contactName;
  final String relationship;
  final int age;
  final String gender;
  final DateTime screeningDate;
  final String screenedBy; // CHW ID
  final List<String> symptoms; // From symptoms checklist
  final String testResult; // 'negative', 'positive', 'pending', 'not_tested'
  final bool referralNeeded;
  final String notes;
  final DateTime? followUpDate;

  ContactTracing({
    required this.contactId,
    required this.householdId,
    required this.indexPatientId,
    required this.contactName,
    required this.relationship,
    required this.age,
    required this.gender,
    required this.screeningDate,
    required this.screenedBy,
    required this.symptoms,
    required this.testResult,
    required this.referralNeeded,
    required this.notes,
    this.followUpDate,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'contactId': contactId,
      'householdId': householdId,
      'indexPatientId': indexPatientId,
      'contactName': contactName,
      'relationship': relationship,
      'age': age,
      'gender': gender,
      'screeningDate': Timestamp.fromDate(screeningDate),
      'screenedBy': screenedBy,
      'symptoms': symptoms,
      'testResult': testResult,
      'referralNeeded': referralNeeded,
      'notes': notes,
      'followUpDate': followUpDate != null ? Timestamp.fromDate(followUpDate!) : null,
    };
  }

  factory ContactTracing.fromFirestore(Map<String, dynamic> data) {
    return ContactTracing(
      contactId: data['contactId'] ?? '',
      householdId: data['householdId'] ?? '',
      indexPatientId: data['indexPatientId'] ?? '',
      contactName: data['contactName'] ?? '',
      relationship: data['relationship'] ?? '',
      age: data['age'] ?? 0,
      gender: data['gender'] ?? '',
      screeningDate: (data['screeningDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      screenedBy: data['screenedBy'] ?? '',
      symptoms: List<String>.from(data['symptoms'] ?? []),
      testResult: data['testResult'] ?? 'pending',
      referralNeeded: data['referralNeeded'] ?? false,
      notes: data['notes'] ?? '',
      followUpDate: (data['followUpDate'] as Timestamp?)?.toDate(),
    );
  }
}

/// Screening Result - Detailed test results for household members
/// Used by: Screening Results Screen (Screen 19) and Household Member Details
class ScreeningResult {
  final String resultId;
  final String contactId; // Links to ContactTracing
  final String contactName;
  final String householdId;
  final String indexPatientId;
  final String testType; // 'chest_xray', 'sputum_microscopy', 'tuberculin_skin_test', 'interferon_gamma_release', 'clinical_assessment'
  final String testResult; // 'negative', 'positive', 'inconclusive', 'pending'
  final DateTime testDate;
  final String testFacility;
  final String facilityContact;
  final String conductedBy; // Doctor/Lab technician name
  final String notes;
  final bool requiresFollowUp;
  final DateTime? nextTestDate;
  final Map<String, dynamic> testDetails; // Additional test-specific data
  final DateTime createdAt;
  final String recordedBy; // CHW who recorded the result

  ScreeningResult({
    required this.resultId,
    required this.contactId,
    required this.contactName,
    required this.householdId,
    required this.indexPatientId,
    required this.testType,
    required this.testResult,
    required this.testDate,
    required this.testFacility,
    required this.facilityContact,
    required this.conductedBy,
    required this.notes,
    required this.requiresFollowUp,
    this.nextTestDate,
    required this.testDetails,
    required this.createdAt,
    required this.recordedBy,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'resultId': resultId,
      'contactId': contactId,
      'contactName': contactName,
      'householdId': householdId,
      'indexPatientId': indexPatientId,
      'testType': testType,
      'testResult': testResult,
      'testDate': Timestamp.fromDate(testDate),
      'testFacility': testFacility,
      'facilityContact': facilityContact,
      'conductedBy': conductedBy,
      'notes': notes,
      'requiresFollowUp': requiresFollowUp,
      'nextTestDate': nextTestDate != null ? Timestamp.fromDate(nextTestDate!) : null,
      'testDetails': testDetails,
      'createdAt': Timestamp.fromDate(createdAt),
      'recordedBy': recordedBy,
    };
  }

  factory ScreeningResult.fromFirestore(Map<String, dynamic> data) {
    return ScreeningResult(
      resultId: data['resultId'] ?? '',
      contactId: data['contactId'] ?? '',
      contactName: data['contactName'] ?? '',
      householdId: data['householdId'] ?? '',
      indexPatientId: data['indexPatientId'] ?? '',
      testType: data['testType'] ?? '',
      testResult: data['testResult'] ?? 'pending',
      testDate: (data['testDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      testFacility: data['testFacility'] ?? '',
      facilityContact: data['facilityContact'] ?? '',
      conductedBy: data['conductedBy'] ?? '',
      notes: data['notes'] ?? '',
      requiresFollowUp: data['requiresFollowUp'] ?? false,
      nextTestDate: (data['nextTestDate'] as Timestamp?)?.toDate(),
      testDetails: Map<String, dynamic>.from(data['testDetails'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      recordedBy: data['recordedBy'] ?? '',
    );
  }

  String get testTypeName {
    switch (testType) {
      case 'chest_xray':
        return 'Chest X-Ray';
      case 'sputum_microscopy':
        return 'Sputum Microscopy';
      case 'tuberculin_skin_test':
        return 'Tuberculin Skin Test (TST)';
      case 'interferon_gamma_release':
        return 'Interferon Gamma Release Assay (IGRA)';
      case 'clinical_assessment':
        return 'Clinical Assessment';
      default:
        return testType.replaceAll('_', ' ').toUpperCase();
    }
  }
}

/// Audit Logs Collection - Everything that happens in the system
/// Created by: Multiple screens (10, 12, 14, 17, 18, 20)
/// Used by: System tracking and compliance
class AuditLog {
  final String logId;
  final String action; // 'registered_patient', 'home_visit', 'contact_screening', etc.
  final String who; // CHW ID
  final String what; // Patient ID, Visit ID, etc.
  final DateTime when;
  final Map<String, double>? where; // GPS location
  final Map<String, dynamic>? additionalData; // Extra context

  AuditLog({
    required this.logId,
    required this.action,
    required this.who,
    required this.what,
    required this.when,
    this.where,
    this.additionalData,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'logId': logId,
      'action': action,
      'who': who,
      'what': what,
      'when': Timestamp.fromDate(when),
      'where': where,
      'additionalData': additionalData,
    };
  }

  factory AuditLog.fromFirestore(Map<String, dynamic> data) {
    return AuditLog(
      logId: data['logId'] ?? '',
      action: data['action'] ?? '',
      who: data['who'] ?? '',
      what: data['what'] ?? '',
      when: (data['when'] as Timestamp?)?.toDate() ?? DateTime.now(),
      where: data['where'] != null ? Map<String, double>.from(data['where']) : null,
      additionalData: data['additionalData'],
    );
  }
}

// =================== CHW READ-ONLY COLLECTIONS ===================

/// Facilities Collection - Hospitals and clinics (Created by Admin)
/// Used by: Register New Patient Screen (Screen 10)
class Facility {
  final String facilityId;
  final String name;
  final String type; // 'hospital', 'health_center', 'clinic'
  final Map<String, dynamic> location;
  final Map<String, String> contact;
  final List<String> staff;
  final List<String> supervisors;
  final List<String> services; // 'tb_treatment', 'xray', 'lab_tests'
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;

  Facility({
    required this.facilityId,
    required this.name,
    required this.type,
    required this.location,
    required this.contact,
    required this.staff,
    required this.supervisors,
    required this.services,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
  });

  factory Facility.fromFirestore(Map<String, dynamic> data) {
    return Facility(
      facilityId: data['facilityId'] ?? '',
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      location: Map<String, dynamic>.from(data['location'] ?? {}),
      contact: Map<String, String>.from(data['contact'] ?? {}),
      staff: List<String>.from(data['staff'] ?? []),
      supervisors: List<String>.from(data['supervisors'] ?? []),
      services: List<String>.from(data['services'] ?? []),
      isActive: data['isActive'] ?? true,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Follow-ups Collection - Hospital appointments (Created by Admin/Staff)
/// Used by: Patient Details (11), Notifications List (23), Missed Follow-up Alert (24)
class Followup {
  final String followupId;
  final String patientId;
  final DateTime scheduledDate;
  final String status; // 'scheduled', 'completed', 'missed', 'cancelled'
  final String facility;
  final String notes;
  final DateTime? completedDate;

  Followup({
    required this.followupId,
    required this.patientId,
    required this.scheduledDate,
    required this.status,
    required this.facility,
    required this.notes,
    this.completedDate,
  });

  factory Followup.fromFirestore(Map<String, dynamic> data) {
    return Followup(
      followupId: data['followupId'] ?? '',
      patientId: data['patientId'] ?? '',
      scheduledDate: (data['scheduledDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'scheduled',
      facility: data['facility'] ?? '',
      notes: data['notes'] ?? '',
      completedDate: (data['completedDate'] as Timestamp?)?.toDate(),
    );
  }
}

/// Notifications Collection - Alerts and messages sent to CHWs
/// Used by: Home Dashboard (6), Notifications List (23), Missed Follow-up Alert (24)
class CHWNotification {
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

/// Assignments Collection - Which CHW handles which patients
/// Used by: Patient List Screen (Screen 8)
class Assignment {
  final String assignmentId;
  final String chwId;
  final List<String> patientIds;
  final String assignedBy; // Staff ID
  final String facilityId;
  final DateTime assignedDate;
  final String status; // 'active', 'inactive', 'transferred'
  final String workArea;
  final String priority; // 'low', 'medium', 'high'

  Assignment({
    required this.assignmentId,
    required this.chwId,
    required this.patientIds,
    required this.assignedBy,
    required this.facilityId,
    required this.assignedDate,
    required this.status,
    required this.workArea,
    required this.priority,
  });

  factory Assignment.fromFirestore(Map<String, dynamic> data) {
    return Assignment(
      assignmentId: data['assignmentId'] ?? '',
      chwId: data['chwId'] ?? '',
      patientIds: List<String>.from(data['patientIds'] ?? []),
      assignedBy: data['assignedBy'] ?? '',
      facilityId: data['facilityId'] ?? '',
      assignedDate: (data['assignedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'active',
      workArea: data['workArea'] ?? '',
      priority: data['priority'] ?? 'medium',
    );
  }
}

/// Outcomes Collection - Final treatment results (Created by Staff)
/// Used by: Patient Details Screen (Screen 11)
class TreatmentOutcome {
  final String outcomeId;
  final String patientId;
  final DateTime treatmentStartDate;
  final DateTime? treatmentEndDate;
  final String outcome; // 'cured', 'treatment_completed', 'failed', 'died', 'lost_to_followup'
  final String recordedBy; // Staff ID
  final String facilityId;
  final String notes;
  final double? finalWeight;
  final String? finalXrayResult;
  final DateTime recordedAt;

  TreatmentOutcome({
    required this.outcomeId,
    required this.patientId,
    required this.treatmentStartDate,
    this.treatmentEndDate,
    required this.outcome,
    required this.recordedBy,
    required this.facilityId,
    required this.notes,
    this.finalWeight,
    this.finalXrayResult,
    required this.recordedAt,
  });

  factory TreatmentOutcome.fromFirestore(Map<String, dynamic> data) {
    return TreatmentOutcome(
      outcomeId: data['outcomeId'] ?? '',
      patientId: data['patientId'] ?? '',
      treatmentStartDate: (data['treatmentStartDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      treatmentEndDate: (data['treatmentEndDate'] as Timestamp?)?.toDate(),
      outcome: data['outcome'] ?? '',
      recordedBy: data['recordedBy'] ?? '',
      facilityId: data['facilityId'] ?? '',
      notes: data['notes'] ?? '',
      finalWeight: data['finalWeight']?.toDouble(),
      finalXrayResult: data['finalXrayResult'],
      recordedAt: (data['recordedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// =================== ENUMS AND CONSTANTS ===================

class TBStatus {
  static const String newlyDiagnosed = 'newly_diagnosed';
  static const String onTreatment = 'on_treatment';
  static const String treatmentCompleted = 'treatment_completed';
  static const String lostToFollowup = 'lost_to_followup';
  
  static List<String> get all => [newlyDiagnosed, onTreatment, treatmentCompleted, lostToFollowup];
}

class VisitType {
  static const String homeVisit = 'home_visit';
  static const String followUp = 'follow_up';
  static const String tracing = 'tracing';
  static const String medicineDelivery = 'medicine_delivery';
  static const String counseling = 'counseling';
  
  static List<String> get all => [homeVisit, followUp, tracing, medicineDelivery, counseling];
}

class DoseStatus {
  static const String taken = 'taken';
  static const String missed = 'missed';
  static const String late = 'late';
  static const String vomited = 'vomited';
  
  static List<String> get all => [taken, missed, late, vomited];
}

class SideEffects {
  static const String nausea = 'nausea';
  static const String vomiting = 'vomiting';
  static const String rash = 'rash';
  static const String dizziness = 'dizziness';
  static const String hearingProblems = 'hearing_problems';
  static const String jointPain = 'joint_pain';
  static const String visionChanges = 'vision_changes';
  
  static List<String> get all => [nausea, vomiting, rash, dizziness, hearingProblems, jointPain, visionChanges];
}

class Symptoms {
  static const String persistentCough = 'persistent_cough';
  static const String weightLoss = 'weight_loss';
  static const String nightSweats = 'night_sweats';
  static const String fever = 'fever';
  static const String fatigue = 'fatigue';
  static const String lossOfAppetite = 'loss_of_appetite';
  
  static List<String> get all => [persistentCough, weightLoss, nightSweats, fever, fatigue, lossOfAppetite];
}

class NotificationType {
  static const String missedFollowup = 'missed_followup';
  static const String newAssignment = 'new_assignment';
  static const String reminder = 'reminder';
  static const String systemUpdate = 'system_update';
  static const String emergencyAlert = 'emergency_alert';
  
  static List<String> get all => [missedFollowup, newAssignment, reminder, systemUpdate, emergencyAlert];
}