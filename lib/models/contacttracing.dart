import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String? referredFacilityId; // ID of facility patient is referred to
  final String? referredFacilityName; // Name of facility for display
  final String? referralReason; // Reason for referral
  final String? referralUrgency; // 'low', 'medium', 'high', 'urgent'
  final DateTime? referralDate; // When referral was made
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
    this.referredFacilityId,
    this.referredFacilityName,
    this.referralReason,
    this.referralUrgency,
    this.referralDate,
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
      'referredFacilityId': referredFacilityId,
      'referredFacilityName': referredFacilityName,
      'referralReason': referralReason,
      'referralUrgency': referralUrgency,
      'referralDate': referralDate != null
          ? Timestamp.fromDate(referralDate!)
          : null,
      'notes': notes,
      'followUpDate': followUpDate != null
          ? Timestamp.fromDate(followUpDate!)
          : null,
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
      screeningDate:
          (data['screeningDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      screenedBy: data['screenedBy'] ?? '',
      symptoms: List<String>.from(data['symptoms'] ?? []),
      testResult: data['testResult'] ?? 'pending',
      referralNeeded: data['referralNeeded'] ?? false,
      referredFacilityId: data['referredFacilityId'],
      referredFacilityName: data['referredFacilityName'],
      referralReason: data['referralReason'],
      referralUrgency: data['referralUrgency'],
      referralDate: (data['referralDate'] as Timestamp?)?.toDate(),
      notes: data['notes'] ?? '',
      followUpDate: (data['followUpDate'] as Timestamp?)?.toDate(),
    );
  }
}
