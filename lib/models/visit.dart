import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class Visit {
  final String visitId;
  final String patientId;
  final String chwId;
  final String visitType; // home_visit, follow_up, tracing, medicine_delivery, counseling
  final DateTime date;
  final bool found; // Patient found/not found toggle
  final String notes;
  final Map<String, double> gpsLocation;
  final List<String>? photos; // Photo capture URLs - Optional

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

  // Convert Visit to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'visitId': visitId,
      'patientId': patientId,
      'chwId': chwId,
      'visitType': visitType,
      'date': date,
      'found': found,
      'notes': notes,
      'gpsLocation': gpsLocation,
      'photos': photos,
    };
  }

  // Create Visit from Firestore document
  factory Visit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Visit(
      visitId: doc.id,
      patientId: data['patientId'] ?? '',
      chwId: data['chwId'] ?? '',
      visitType: data['visitType'] ?? AppConstants.homeVisitType,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      found: data['found'] ?? false,
      notes: data['notes'] ?? '',
      gpsLocation: Map<String, double>.from(data['gpsLocation'] ?? {}),
      photos: data['photos'] != null ? List<String>.from(data['photos']) : null,
    );
  }

  // Create from Map
  factory Visit.fromMap(Map<String, dynamic> data, String id) {
    return Visit(
      visitId: id,
      patientId: data['patientId'] ?? '',
      chwId: data['chwId'] ?? '',
      visitType: data['visitType'] ?? AppConstants.homeVisitType,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      found: data['found'] ?? false,
      notes: data['notes'] ?? '',
      gpsLocation: Map<String, double>.from(data['gpsLocation'] ?? {}),
      photos: data['photos'] != null ? List<String>.from(data['photos']) : null,
    );
  }

  // Copy with method for immutable updates
  Visit copyWith({
    String? visitId,
    String? patientId,
    String? chwId,
    String? visitType,
    DateTime? date,
    bool? found,
    String? notes,
    Map<String, double>? gpsLocation,
    List<String>? photos,
  }) {
    return Visit(
      visitId: visitId ?? this.visitId,
      patientId: patientId ?? this.patientId,
      chwId: chwId ?? this.chwId,
      visitType: visitType ?? this.visitType,
      date: date ?? this.date,
      found: found ?? this.found,
      notes: notes ?? this.notes,
      gpsLocation: gpsLocation ?? this.gpsLocation,
      photos: photos ?? this.photos,
    );
  }

  // Helper methods
  bool get isHomeVisit => visitType == AppConstants.homeVisitType;
  bool get isFollowUp => visitType == AppConstants.followUpType;
  bool get isTracing => visitType == AppConstants.tracingType;
  bool get isMedicineDelivery => visitType == AppConstants.medicineDeliveryType;
  bool get isCounseling => visitType == AppConstants.counselingType;
  bool get hasPhotos => photos != null && photos!.isNotEmpty;

  // Visit type display name
  String get visitTypeDisplayName {
    switch (visitType) {
      case AppConstants.homeVisitType:
        return 'Home Visit';
      case AppConstants.followUpType:
        return 'Follow-up';
      case AppConstants.tracingType:
        return 'Tracing';
      case AppConstants.medicineDeliveryType:
        return 'Medicine Delivery';
      case AppConstants.counselingType:
        return 'Counseling';
      default:
        return 'Unknown Visit Type';
    }
  }

  // Visit status
  String get statusDisplayName {
    return found ? 'Patient Found' : 'Patient Not Found';
  }

  // Format date for display
  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  String get formattedDateTime {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Calculate days since visit
  int get daysSinceVisit {
    return DateTime.now().difference(date).inDays;
  }

  // Is visit recent (within last 7 days)
  bool get isRecent {
    return daysSinceVisit <= 7;
  }

  // Is visit today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  // Validation methods
  bool get isValid {
    return patientId.isNotEmpty && 
           chwId.isNotEmpty &&
           visitType.isNotEmpty &&
           notes.isNotEmpty &&
           gpsLocation.isNotEmpty;
  }

  // GPS validation
  bool get hasValidGPS {
    return gpsLocation.containsKey('latitude') && 
           gpsLocation.containsKey('longitude') &&
           gpsLocation['latitude'] != null &&
           gpsLocation['longitude'] != null;
  }

  @override
  String toString() {
    return 'Visit(visitId: $visitId, patientId: $patientId, chwId: $chwId, visitType: $visitType, found: $found, date: $formattedDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Visit && other.visitId == visitId;
  }

  @override
  int get hashCode => visitId.hashCode;
}