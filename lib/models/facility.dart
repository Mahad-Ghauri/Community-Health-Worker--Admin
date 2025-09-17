import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

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

  // Convert Facility to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'facilityId': facilityId,
      'name': name,
      'type': type,
      'location': location,
      'contact': contact,
      'staff': staff,
      'supervisors': supervisors,
      'services': services,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }

  // Create Facility from Firestore document (for backward compatibility)
  factory Facility.fromFirestoreDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Facility.fromFirestore({
      ...data,
      'facilityId': doc.id,
    });
  }

  // Create from Map
  factory Facility.fromMap(Map<String, dynamic> data, String id) {
    return Facility.fromFirestore({
      ...data,
      'facilityId': id,
    });
  }

  // Copy with method for immutable updates
  Facility copyWith({
    String? facilityId,
    String? name,
    String? type,
    Map<String, dynamic>? location,
    Map<String, String>? contact,
    List<String>? staff,
    List<String>? supervisors,
    List<String>? services,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return Facility(
      facilityId: facilityId ?? this.facilityId,
      name: name ?? this.name,
      type: type ?? this.type,
      location: location ?? this.location,
      contact: contact ?? this.contact,
      staff: staff ?? this.staff,
      supervisors: supervisors ?? this.supervisors,
      services: services ?? this.services,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper methods
  bool get isHospital => type == AppConstants.hospitalType;
  bool get isHealthCenter => type == AppConstants.healthCenterType;
  bool get isClinic => type == AppConstants.clinicType;

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
  String get status => isActive ? 'active' : 'inactive'; // For backward compatibility

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

  // Location and contact helpers
  String get address => location['address']?.toString() ?? '';
  String get contactPhone => contact['phone'] ?? '';
  String get contactEmail => contact['email'] ?? '';
  String get contactPerson => contact['person'] ?? '';
  
  // Coordinates helpers
  Map<String, double>? get coordinates {
    final lat = location['latitude'];
    final lng = location['longitude'];
    if (lat != null && lng != null) {
      return {
        'latitude': double.tryParse(lat.toString()) ?? 0.0,
        'longitude': double.tryParse(lng.toString()) ?? 0.0,
      };
    }
    return null;
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
    return 'Facility(facilityId: $facilityId, name: $name, type: $type, isActive: $isActive, staffCount: $staffCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Facility && other.facilityId == facilityId;
  }

  @override
  int get hashCode => facilityId.hashCode;
}