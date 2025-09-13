import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  
  List<User> _users = [];
  User? _selectedUser;
  bool _isLoading = false;
  String? _error;
  Map<String, int> _statistics = {};

  // Getters
  List<User> get users => _users;
  User? get selectedUser => _selectedUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, int> get statistics => _statistics;

  // Filter properties
  String? _selectedRole;
  String? _selectedFacility;
  String _searchTerm = '';

  String? get selectedRole => _selectedRole;
  String? get selectedFacility => _selectedFacility;
  String get searchTerm => _searchTerm;

  // Filtered users
  List<User> get filteredUsers {
    var filtered = _users;

    if (_selectedRole != null && _selectedRole!.isNotEmpty) {
      filtered = filtered.where((user) => user.role == _selectedRole).toList();
    }

    if (_selectedFacility != null && _selectedFacility!.isNotEmpty) {
      filtered = filtered.where((user) => user.facilityId == _selectedFacility).toList();
    }

    if (_searchTerm.isNotEmpty) {
      final searchLower = _searchTerm.toLowerCase();
      filtered = filtered.where((user) =>
          user.name.toLowerCase().contains(searchLower) ||
          user.email.toLowerCase().contains(searchLower) ||
          user.phone.contains(_searchTerm)).toList();
    }

    return filtered;
  }

  // Load users
  Future<void> loadUsers() async {
    _setLoading(true);
    _setError(null);

    try {
      // Listen to users stream
      _userService.getUsers().listen(
        (users) {
          _users = users;
          _setLoading(false);
          notifyListeners();
        },
        onError: (error) {
          _setError('Failed to load users: $error');
          _setLoading(false);
        },
      );
    } catch (e) {
      _setError('Failed to load users: $e');
      _setLoading(false);
    }
  }

  // Load user by ID
  Future<void> loadUserById(String userId) async {
    _setLoading(true);
    _setError(null);

    try {
      final user = await _userService.getUserById(userId);
      _selectedUser = user;
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load user: $e');
      _setLoading(false);
    }
  }

  // Create user
  Future<String?> createUser(User user) async {
    _setLoading(true);
    _setError(null);

    try {
      // Check if email exists
      final emailExists = await _userService.emailExists(user.email);
      if (emailExists) {
        _setError('Email already exists');
        _setLoading(false);
        return null;
      }

      final userId = await _userService.createUser(user);
      _setLoading(false);
      
      // Reload users to get updated list
      await loadUsers();
      
      return userId;
    } catch (e) {
      _setError('Failed to create user: $e');
      _setLoading(false);
      return null;
    }
  }

  // Update user
  Future<bool> updateUser(String userId, Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);

    try {
      // Check if email exists (excluding current user)
      if (data.containsKey('email')) {
        final emailExists = await _userService.emailExists(
          data['email'],
          excludeUserId: userId,
        );
        if (emailExists) {
          _setError('Email already exists');
          _setLoading(false);
          return false;
        }
      }

      await _userService.updateUser(userId, data);
      _setLoading(false);
      
      // Update selected user if it's the one being updated
      if (_selectedUser?.userId == userId) {
        await loadUserById(userId);
      }
      
      // Reload users to get updated list
      await loadUsers();
      
      return true;
    } catch (e) {
      _setError('Failed to update user: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete user
  Future<bool> deleteUser(String userId) async {
    _setLoading(true);
    _setError(null);

    try {
      await _userService.deleteUser(userId);
      _setLoading(false);
      
      // Clear selected user if it's the one being deleted
      if (_selectedUser?.userId == userId) {
        _selectedUser = null;
      }
      
      // Reload users to get updated list
      await loadUsers();
      
      return true;
    } catch (e) {
      _setError('Failed to delete user: $e');
      _setLoading(false);
      return false;
    }
  }

  // Load statistics
  Future<void> loadStatistics() async {
    try {
      _statistics = await _userService.getUserStatistics();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load statistics: $e');
    }
  }

  // Search users
  Future<void> searchUsers(String searchTerm) async {
    _searchTerm = searchTerm;
    notifyListeners();
  }

  // Filter by role
  void filterByRole(String? role) {
    _selectedRole = role;
    notifyListeners();
  }

  // Filter by facility
  void filterByFacility(String? facilityId) {
    _selectedFacility = facilityId;
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _selectedRole = null;
    _selectedFacility = null;
    _searchTerm = '';
    notifyListeners();
  }

  // Select user
  void selectUser(User user) {
    _selectedUser = user;
    notifyListeners();
  }

  // Clear selected user
  void clearSelectedUser() {
    _selectedUser = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}