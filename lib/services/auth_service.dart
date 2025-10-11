// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'firebase_admin_service.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAdminService _adminService = FirebaseAdminService();

  // Get current user stream
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  firebase_auth.User? get currentUser => _auth.currentUser;

  // Get current user data from Firestore
  Future<User?> getCurrentUserData() async {
    final firebaseUser = currentUser;
    if (firebaseUser == null) return null;

    try {
      final doc = await _firestore
          .collection('accounts')
          .doc(firebaseUser.uid)
          .get();
      if (doc.exists) {
        return User.fromFirestore(doc.data()!);
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
    return null;
  }

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return await getCurrentUserData();
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
    return null;
  }

  // Register with email and password
  Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    String? facilityId,
    String? dateOfBirth,
    String? gender,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final user = User(
          userId: credential.user!.uid,
          name: name,
          email: email,
          phone: phone,
          role: role,
          facilityId: facilityId,
          dateOfBirth: dateOfBirth,
          gender: gender,
          createdAt: DateTime.now(),
        );

        // Save user data to Firestore
        await _firestore
            .collection('accounts')
            .doc(credential.user!.uid)
            .set(user.toFirestore());

        return user;
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
    return null;
  }

  // Create user account for admin (creates account without affecting current session)
  Future<User?> createUserAccount({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    String? facilityId,
    String? dateOfBirth,
    String? gender,
  }) async {
    try {
      // Use Firebase Admin Service to create user without affecting current session
      return await _adminService.createUserWithFirebaseAuth(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
        facilityId: facilityId,
        dateOfBirth: dateOfBirth,
        gender: gender,
      );
    } catch (e) {
      throw 'Failed to create user account: $e';
    }
  }

  // Create user with auth (admin-friendly approach - preserves admin session)
  Future<User?> createUserWithAuth({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    String? facilityId,
    String? dateOfBirth,
    String? gender,
  }) async {
    try {
      // Use Firebase Admin Service to create user with Firebase Auth without affecting current session
      return await _adminService.createUserWithFirebaseAuth(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
        facilityId: facilityId,
        dateOfBirth: dateOfBirth,
        gender: gender,
      );
    } catch (e) {
      throw 'Failed to create user: $e';
    }
  }

  // Create user profile only (no Firebase Auth, just Firestore)
  Future<User?> createUserProfile({
    required String email,
    required String name,
    required String phone,
    required String role,
    String? facilityId,
    String? dateOfBirth,
    String? gender,
  }) async {
    try {
      // Generate a unique ID for the user
      final userId = DateTime.now().millisecondsSinceEpoch.toString();

      final user = User(
        userId: userId,
        name: name,
        email: email,
        phone: phone,
        role: role,
        facilityId: facilityId,
        dateOfBirth: dateOfBirth,
        gender: gender,
        createdAt: DateTime.now(),
      );

      // Save user data to Firestore
      await _firestore
          .collection('accounts')
          .doc(userId)
          .set(user.toFirestore());

      return user;
    } catch (e) {
      throw 'Failed to create user profile: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('accounts').doc(userId).update(data);
    } catch (e) {
      throw 'Failed to update profile: $e';
    }
  }

  // Check if user exists in Firestore
  Future<bool> userExists(String userId) async {
    try {
      final doc = await _firestore.collection('accounts').doc(userId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Get user by role
  Future<List<User>> getUsersByRole(String role) async {
    try {
      final querySnapshot = await _firestore
          .collection('accounts')
          .where('role', isEqualTo: role)
          .get();

      return querySnapshot.docs
          .map((doc) => User.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting users by role: $e');
      return [];
    }
  }

  // Delete user account
  Future<void> deleteUserAccount(String userId) async {
    try {
      // Delete from Firestore
      await _firestore.collection('accounts').doc(userId).delete();

      // Delete from Firebase Auth (only if it's the current user)
      if (currentUser?.uid == userId) {
        await currentUser?.delete();
      }
    } catch (e) {
      throw 'Failed to delete account: $e';
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Signing in with Email and Password is not enabled.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}
