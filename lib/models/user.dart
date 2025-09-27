// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

/// Accounts Collection - User registration and profile management
/// Created by: User Registration Screen
/// Used by: Login, Forgot Password, Profile Settings
class User {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String role; // 'admin', 'staff', 'supervisor'
  final String?
  facilityId; // Can be null for users working at multiple facilities
  final String? dateOfBirth; // Date of birth
  final String? gender; // Gender
  final DateTime createdAt;
  final bool?
  needsPasswordSetup; // Flag to indicate if user needs to set up password

  User({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.facilityId, // Optional - null for multi-facility users
    this.dateOfBirth,
    this.gender,
    required this.createdAt,
    this.needsPasswordSetup,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'facilityId': facilityId,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'createdAt': Timestamp.fromDate(createdAt),
      'needsPasswordSetup': needsPasswordSetup,
    };
  }

  factory User.fromFirestore(Map<String, dynamic> data) {
    return User(
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] ?? 'staff',
      facilityId: data['facilityId'],
      dateOfBirth: data['dateOfBirth'],
      gender: data['gender'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      needsPasswordSetup: data['needsPasswordSetup'],
    );
  }

  // Helper method to check user role
  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff';
  bool get isSupervisor => role == 'supervisor';
}

// User role constants
class UserRole {
  static const String admin = 'admin';
  static const String staff = 'staff';
  static const String supervisor = 'supervisor';

  static List<String> get all => [admin, staff, supervisor];

  static String getDisplayName(String role) {
    switch (role) {
      case admin:
        return 'Administrator';
      case staff:
        return 'Staff Member';
      case supervisor:
        return 'Supervisor';
      default:
        return 'Unknown Role';
    }
  }
}
