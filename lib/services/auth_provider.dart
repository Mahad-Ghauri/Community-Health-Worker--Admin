import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // Initialize auth state
  void initialize() {
    _authService.authStateChanges.listen((firebase_auth.User? firebaseUser) async {
      if (firebaseUser != null) {
        await _loadCurrentUser();
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  // Load current user data
  Future<void> _loadCurrentUser() async {
    try {
      _currentUser = await _authService.getCurrentUserData();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _currentUser = null;
    }
    notifyListeners();
  }

  // Sign in
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      final user = await _authService.signInWithEmailAndPassword(email, password);
      if (user != null) {
        _currentUser = user;
        _errorMessage = null;
        _setLoading(false);
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
    return false;
  }

  // Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    String? facilityId,
    String? dateOfBirth,
    String? gender,
  }) async {
    _setLoading(true);
    try {
      final user = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
        facilityId: facilityId,
        dateOfBirth: dateOfBirth,
        gender: gender,
      );
      
      if (user != null) {
        _currentUser = user;
        _errorMessage = null;
        _setLoading(false);
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
    return false;
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUser = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    try {
      await _authService.sendPasswordResetEmail(email);
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_currentUser == null) return false;
    
    _setLoading(true);
    try {
      await _authService.updateUserProfile(
        userId: _currentUser!.userId,
        data: data,
      );
      
      // Reload user data
      await _loadCurrentUser();
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Check user permissions
  bool hasPermission(String permission) {
    if (_currentUser == null) return false;
    
    switch (permission) {
      case 'admin_access':
        return _currentUser!.isAdmin;
      case 'staff_access':
        return _currentUser!.isAdmin || _currentUser!.isStaff;
      case 'supervisor_access':
        return _currentUser!.isAdmin || _currentUser!.isSupervisor;
      default:
        return false;
    }
  }

  // Get user dashboard route based on role
  String getDashboardRoute() {
    if (_currentUser == null) return '/login';
    
    switch (_currentUser!.role) {
      case 'admin':
        return '/admin-dashboard';
      case 'staff':
        return '/staff-dashboard';
      case 'supervisor':
        return '/supervisor-dashboard';
      default:
        return '/login';
    }
  }
}