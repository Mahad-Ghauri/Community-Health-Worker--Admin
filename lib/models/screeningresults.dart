import 'package:cloud_firestore/cloud_firestore.dart';
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
