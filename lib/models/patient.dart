import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class Patient {
  final String patientId;
  final String name;
  final int age;
  final String phone;
  final String address;
  final String gender;
  final String tbStatus; // newly_diagnosed, on_treatment, treatment_completed, lost_to_followup
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

  // Convert Patient to Firestore document
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
      'createdAt': createdAt,
      'diagnosisDate': diagnosisDate,
    };
  }

  // Create Patient from Firestore document
  factory Patient.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Patient(
      patientId: doc.id,
      name: data['name'] ?? '',
      age: data['age'] ?? 0,
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      gender: data['gender'] ?? '',
      tbStatus: data['tbStatus'] ?? AppConstants.newlyDiagnosedStatus,
      assignedCHW: data['assignedCHW'] ?? '',
      assignedFacility: data['assignedFacility'] ?? '',
      treatmentFacility: data['treatmentFacility'] ?? '',
      gpsLocation: Map<String, double>.from(data['gpsLocation'] ?? {}),
      consent: data['consent'] ?? false,
      consentSignature: data['consentSignature'],
      createdBy: data['createdBy'] ?? '',
      validatedBy: data['validatedBy'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      diagnosisDate: (data['diagnosisDate'] as Timestamp?)?.toDate(),
    );
  }

  // Create from Map
  factory Patient.fromMap(Map<String, dynamic> data, String id) {
    return Patient(
      patientId: id,
      name: data['name'] ?? '',
      age: data['age'] ?? 0,
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      gender: data['gender'] ?? '',
      tbStatus: data['tbStatus'] ?? AppConstants.newlyDiagnosedStatus,
      assignedCHW: data['assignedCHW'] ?? '',
      assignedFacility: data['assignedFacility'] ?? '',
      treatmentFacility: data['treatmentFacility'] ?? '',
      gpsLocation: Map<String, double>.from(data['gpsLocation'] ?? {}),
      consent: data['consent'] ?? false,
      consentSignature: data['consentSignature'],
      createdBy: data['createdBy'] ?? '',
      validatedBy: data['validatedBy'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      diagnosisDate: (data['diagnosisDate'] as Timestamp?)?.toDate(),
    );
  }

  // Copy with method for immutable updates
  Patient copyWith({
    String? patientId,
    String? name,
    int? age,
    String? phone,
    String? address,
    String? gender,
    String? tbStatus,
    String? assignedCHW,
    String? assignedFacility,
    String? treatmentFacility,
    Map<String, double>? gpsLocation,
    bool? consent,
    String? consentSignature,
    String? createdBy,
    String? validatedBy,
    DateTime? createdAt,
    DateTime? diagnosisDate,
  }) {
    return Patient(
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      age: age ?? this.age,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      tbStatus: tbStatus ?? this.tbStatus,
      assignedCHW: assignedCHW ?? this.assignedCHW,
      assignedFacility: assignedFacility ?? this.assignedFacility,
      treatmentFacility: treatmentFacility ?? this.treatmentFacility,
      gpsLocation: gpsLocation ?? this.gpsLocation,
      consent: consent ?? this.consent,
      consentSignature: consentSignature ?? this.consentSignature,
      createdBy: createdBy ?? this.createdBy,
      validatedBy: validatedBy ?? this.validatedBy,
      createdAt: createdAt ?? this.createdAt,
      diagnosisDate: diagnosisDate ?? this.diagnosisDate,
    );
  }

  // Helper methods
  bool get isNewlyDiagnosed => tbStatus == AppConstants.newlyDiagnosedStatus;
  bool get isOnTreatment => tbStatus == AppConstants.onTreatmentStatus;
  bool get isTreatmentCompleted => tbStatus == AppConstants.treatmentCompletedStatus;
  bool get isLostToFollowUp => tbStatus == AppConstants.lostToFollowUpStatus;
  bool get hasConsent => consent;
  bool get isValidated => validatedBy != null && validatedBy!.isNotEmpty;

  // Status display helpers
  String get statusDisplayName {
    switch (tbStatus) {
      case AppConstants.newlyDiagnosedStatus:
        return 'Newly Diagnosed';
      case AppConstants.onTreatmentStatus:
        return 'On Treatment';
      case AppConstants.treatmentCompletedStatus:
        return 'Treatment Completed';
      case AppConstants.lostToFollowUpStatus:
        return 'Lost to Follow-up';
      default:
        return 'Unknown Status';
    }
  }

  // Validation methods
  bool get isValid {
    return name.isNotEmpty && 
           age > 0 && 
           phone.isNotEmpty &&
           address.isNotEmpty &&
           gender.isNotEmpty &&
           assignedCHW.isNotEmpty &&
           assignedFacility.isNotEmpty &&
           consent;
  }

  // Calculate days since diagnosis
  int? get daysSinceDiagnosis {
    if (diagnosisDate == null) return null;
    return DateTime.now().difference(diagnosisDate!).inDays;
  }

  // Calculate days since creation
  int get daysSinceCreation {
    return DateTime.now().difference(createdAt).inDays;
  }

  @override
  String toString() {
    return 'Patient(patientId: $patientId, name: $name, age: $age, tbStatus: $tbStatus, assignedCHW: $assignedCHW)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Patient && other.patientId == patientId;
  }

  @override
  int get hashCode => patientId.hashCode;
}