import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class Facility {
  final String facilityId;
  final String name;
  final String type; // hospital, health_center, clinic
  final String address;
  final String contactPhone;
  final String contactEmail;
  final String contactPerson;
  final Map<String, double>? coordinates;
  final List<String> staff;
  final List<String> supervisors;
  final List<String> services; // tb_treatment, xray, lab_tests
  final String status; // active, inactive
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Facility({
    required this.facilityId,
    required this.name,
    required this.type,
    required this.address,
    required this.contactPhone,
    required this.contactEmail,
    required this.contactPerson,
    this.coordinates,
    required this.staff,
    required this.supervisors,
    required this.services,
    this.status = 'active',
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert Facility to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'facilityId': facilityId,
      'name': name,
      'type': type,
      'address': address,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'contactPerson': contactPerson,
      'coordinates': coordinates,
      'staff': staff,
      'supervisors': supervisors,
      'services': services,
      'status': status,
      'createdBy': createdBy,
      'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  // Create Facility from Firestore document
  factory Facility.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Facility(
      facilityId: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? AppConstants.clinicType,
      address: data['address'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      contactPerson: data['contactPerson'] ?? '',
      coordinates: data['coordinates'] != null 
          ? Map<String, double>.from(data['coordinates'])
          : null,
      staff: List<String>.from(data['staff'] ?? []),
      supervisors: List<String>.from(data['supervisors'] ?? []),
      services: List<String>.from(data['services'] ?? []),
      status: data['status'] ?? 'active',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Create from Map
  factory Facility.fromMap(Map<String, dynamic> data, String id) {
    return Facility(
      facilityId: id,
      name: data['name'] ?? '',
      type: data['type'] ?? AppConstants.clinicType,
      address: data['address'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      contactPerson: data['contactPerson'] ?? '',
      coordinates: data['coordinates'] != null 
          ? Map<String, double>.from(data['coordinates'])
          : null,
      staff: List<String>.from(data['staff'] ?? []),
      supervisors: List<String>.from(data['supervisors'] ?? []),
      services: List<String>.from(data['services'] ?? []),
      status: data['status'] ?? 'active',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Copy with method for immutable updates
  Facility copyWith({
    String? facilityId,
    String? name,
    String? type,
    String? address,
    String? contactPhone,
    String? contactEmail,
    String? contactPerson,
    Map<String, double>? coordinates,
    List<String>? staff,
    List<String>? supervisors,
    List<String>? services,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Facility(
      facilityId: facilityId ?? this.facilityId,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPerson: contactPerson ?? this.contactPerson,
      coordinates: coordinates ?? this.coordinates,
      staff: staff ?? this.staff,
      supervisors: supervisors ?? this.supervisors,
      services: services ?? this.services,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isHospital => type == AppConstants.hospitalType;
  bool get isHealthCenter => type == AppConstants.healthCenterType;
  bool get isClinic => type == AppConstants.clinicType;
  bool get isActive => status == 'active';

  // Facility type display name
  String get typeDisplayName {
    switch (type) {
      case AppConstants.hospitalType:
        return 'Hospital';
      case AppConstants.healthCenterType:
        return 'Health Center';
      case AppConstants.clinicType:
        return 'Clinic';
      default:
        return 'Unknown Type';
    }
  }

  // Services helpers
  bool get providesTBTreatment => services.contains(AppConstants.tbTreatmentService);
  bool get providesXray => services.contains(AppConstants.xrayService);
  bool get providesLabTests => services.contains(AppConstants.labTestsService);

  // Staff counts
  int get staffCount => staff.length;
  int get supervisorCount => supervisors.length;
  int get totalPersonnel => staffCount + supervisorCount;

  // Status helpers
  String get statusDisplayName => isActive ? 'Active' : 'Inactive';

  // Check if user is assigned to this facility
  bool hasStaffMember(String userId) => staff.contains(userId);
  bool hasSupervisor(String userId) => supervisors.contains(userId);
  bool hasPersonnel(String userId) => hasStaffMember(userId) || hasSupervisor(userId);

  // Services display
  List<String> get servicesDisplayNames {
    return services.map((service) {
      switch (service) {
        case AppConstants.tbTreatmentService:
          return 'TB Treatment';
        case AppConstants.xrayService:
          return 'X-ray';
        case AppConstants.labTestsService:
          return 'Lab Tests';
        default:
          return service.replaceAll('_', ' ').toUpperCase();
      }
    }).toList();
  }

  String get servicesDisplayText {
    if (services.isEmpty) return 'No services';
    return servicesDisplayNames.join(', ');
  }

  // Validation methods
  bool get isValid {
    return name.isNotEmpty && 
           type.isNotEmpty &&
           address.isNotEmpty &&
           contactPhone.isNotEmpty &&
           contactEmail.isNotEmpty &&
           services.isNotEmpty;
  }

  bool get hasValidLocation {
    return address.isNotEmpty;
  }

  bool get hasValidContact {
    return contactPhone.isNotEmpty && contactPerson.isNotEmpty;
  }

  bool get hasValidCoordinates {
    return coordinates != null && 
           coordinates!.containsKey('latitude') && 
           coordinates!.containsKey('longitude');
  }

  // Format date for display
  String get formattedCreatedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  @override
  String toString() {
    return 'Facility(facilityId: $facilityId, name: $name, type: $type, status: $status, staffCount: $staffCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Facility && other.facilityId == facilityId;
  }

  @override
  int get hashCode => facilityId.hashCode;
}