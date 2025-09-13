import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class CHWUser {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String workingArea;
  final String role; // Always 'chw'
  final String status; // active, inactive
  final String? facilityId; // Null for multi-facility work
  final String idNumber; // Auto-generated CHW ID: CHW001, CHW002, etc.
  final String? dateOfBirth;
  final String? gender;
  final DateTime createdAt;

  CHWUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.workingArea,
    this.role = AppConstants.chwRole,
    this.status = AppConstants.activeStatus,
    this.facilityId,
    required this.idNumber,
    this.dateOfBirth,
    this.gender,
    required this.createdAt,
  });

  // Convert CHWUser to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'workingArea': workingArea,
      'role': role,
      'status': status,
      'facilityId': facilityId,
      'idNumber': idNumber,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'createdAt': createdAt,
    };
  }

  // Create CHWUser from Firestore document
  factory CHWUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CHWUser(
      userId: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      workingArea: data['workingArea'] ?? '',
      role: data['role'] ?? AppConstants.chwRole,
      status: data['status'] ?? AppConstants.activeStatus,
      facilityId: data['facilityId'],
      idNumber: data['idNumber'] ?? '',
      dateOfBirth: data['dateOfBirth'],
      gender: data['gender'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create from Map
  factory CHWUser.fromMap(Map<String, dynamic> data, String id) {
    return CHWUser(
      userId: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      workingArea: data['workingArea'] ?? '',
      role: data['role'] ?? AppConstants.chwRole,
      status: data['status'] ?? AppConstants.activeStatus,
      facilityId: data['facilityId'],
      idNumber: data['idNumber'] ?? '',
      dateOfBirth: data['dateOfBirth'],
      gender: data['gender'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Copy with method for immutable updates
  CHWUser copyWith({
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? workingArea,
    String? role,
    String? status,
    String? facilityId,
    String? idNumber,
    String? dateOfBirth,
    String? gender,
    DateTime? createdAt,
  }) {
    return CHWUser(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      workingArea: workingArea ?? this.workingArea,
      role: role ?? this.role,
      status: status ?? this.status,
      facilityId: facilityId ?? this.facilityId,
      idNumber: idNumber ?? this.idNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper methods
  bool get isActive => status == AppConstants.activeStatus;
  bool get isInactive => status == AppConstants.inactiveStatus;

  // Validation methods
  bool get isValid {
    return name.isNotEmpty && 
           email.isNotEmpty && 
           phone.isNotEmpty &&
           workingArea.isNotEmpty &&
           idNumber.isNotEmpty;
  }

  @override
  String toString() {
    return 'CHWUser(userId: $userId, name: $name, email: $email, idNumber: $idNumber, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CHWUser && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}