import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;
  User? _user;

  AuthProvider() {
    // listen to auth state changes
    _authService.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;

  Future<void> signIn(String email, String password) async {
    await _authService.signIn(email, password);
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    await _authService.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
