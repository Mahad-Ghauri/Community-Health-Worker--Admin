import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';
import '../models/user.dart';

class FirebaseAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get the API key based on platform
  String get _apiKey {
    if (kIsWeb) {
      return DefaultFirebaseOptions.web.apiKey;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return DefaultFirebaseOptions.android.apiKey;
      case TargetPlatform.iOS:
        return DefaultFirebaseOptions.ios.apiKey;
      default:
        return DefaultFirebaseOptions.web.apiKey;
    }
  }

  // Create user account using Firebase Auth REST API
  Future<User?> createUserWithFirebaseAuth({
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
      // Step 1: Create the Firebase Auth user using REST API
      final authUrl = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_apiKey',
      );

      final authResponse = await http.post(
        authUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      if (authResponse.statusCode != 200) {
        final error = jsonDecode(authResponse.body);
        throw _handleFirebaseRestError(error);
      }

      final authData = jsonDecode(authResponse.body);
      final userId = authData['localId'];

      if (userId == null) {
        throw 'Failed to create user account';
      }

      // Step 2: Create user profile in Firestore
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

      // Step 3: Send email verification (optional)
      await _sendEmailVerification(authData['idToken']);

      return user;
    } catch (e) {
      print('Error creating user with Firebase Auth: $e');
      throw 'Failed to create user account: $e';
    }
  }

  // Send email verification
  Future<void> _sendEmailVerification(String idToken) async {
    try {
      final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=$_apiKey',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'requestType': 'VERIFY_EMAIL',
          'idToken': idToken,
        }),
      );

      if (response.statusCode != 200) {
        print('Failed to send email verification: ${response.body}');
        // Don't throw error here as user creation was successful
      }
    } catch (e) {
      print('Error sending email verification: $e');
      // Don't throw error here as user creation was successful
    }
  }

  // Handle Firebase REST API errors
  String _handleFirebaseRestError(Map<String, dynamic> error) {
    if (error.containsKey('error')) {
      final errorDetails = error['error'];
      if (errorDetails.containsKey('message')) {
        final message = errorDetails['message'];
        
        switch (message) {
          case 'EMAIL_EXISTS':
            return 'An account already exists with this email address.';
          case 'INVALID_EMAIL':
            return 'The email address is not valid.';
          case 'WEAK_PASSWORD':
            return 'The password is too weak. Please choose a stronger password.';
          case 'OPERATION_NOT_ALLOWED':
            return 'Email/password accounts are not enabled.';
          default:
            return 'Authentication error: $message';
        }
      }
    }
    return 'An unknown error occurred during account creation.';
  }

  // Check if email already exists
  Future<bool> checkEmailExists(String email) async {
    try {
      final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:createAuthUri?key=$_apiKey',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'identifier': email,
          'continueUri': 'http://localhost', // Required but not used
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['registered'] == true;
      }
      
      return false;
    } catch (e) {
      print('Error checking email exists: $e');
      return false;
    }
  }

  // Send password reset email using REST API
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=$_apiKey',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'requestType': 'PASSWORD_RESET',
          'email': email,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw _handleFirebaseRestError(error);
      }
    } catch (e) {
      throw 'Failed to send password reset email: $e';
    }
  }
}