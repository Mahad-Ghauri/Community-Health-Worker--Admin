import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../constants/app_constants.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get users collection reference
  CollectionReference get _usersCollection => 
      _firestore.collection(AppConstants.usersCollection);

  // Get all users with optional filtering
  Stream<List<User>> getUsers({
    String? role,
    String? facilityId,
    int? limit,
  }) {
    Query query = _usersCollection.orderBy('createdAt', descending: true);
    
    if (role != null && role.isNotEmpty) {
      query = query.where('role', isEqualTo: role);
    }
    
    if (facilityId != null && facilityId.isNotEmpty) {
      query = query.where('facilityId', isEqualTo: facilityId);
    }
    
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => User.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return User.fromFirestore(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Create new user
  Future<String> createUser(User user) async {
    try {
      final docRef = await _usersCollection.add(user.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  // Update user
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(userId).update(data);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // Check if email exists
  Future<bool> emailExists(String email, {String? excludeUserId}) async {
    try {
      Query query = _usersCollection.where('email', isEqualTo: email);
      final snapshot = await query.get();
      
      if (excludeUserId != null) {
        return snapshot.docs.any((doc) => doc.id != excludeUserId);
      }
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check email: $e');
    }
  }

  // Get users by role
  Stream<List<User>> getUsersByRole(String role) {
    return _usersCollection
        .where('role', isEqualTo: role)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => User.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Get users by facility
  Stream<List<User>> getUsersByFacility(String facilityId) {
    return _usersCollection
        .where('facilityId', isEqualTo: facilityId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => User.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Search users by name or email
  Future<List<User>> searchUsers(String searchTerm) async {
    try {
      // Firestore doesn't support full-text search, so we'll get all users and filter
      final snapshot = await _usersCollection.get();
      final users = snapshot.docs
          .map((doc) => User.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();

      final searchLower = searchTerm.toLowerCase();
      return users.where((user) =>
          user.name.toLowerCase().contains(searchLower) ||
          user.email.toLowerCase().contains(searchLower)).toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  // Get user statistics
  Future<Map<String, int>> getUserStatistics() async {
    try {
      final snapshot = await _usersCollection.get();
      final users = snapshot.docs
          .map((doc) => User.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();

      final stats = <String, int>{
        'total': users.length,
        'admin': users.where((u) => u.isAdmin).length,
        'staff': users.where((u) => u.isStaff).length,
        'supervisor': users.where((u) => u.isSupervisor).length,
      };

      return stats;
    } catch (e) {
      throw Exception('Failed to get user statistics: $e');
    }
  }

  // Batch operations
  Future<void> updateMultipleUsers(Map<String, Map<String, dynamic>> updates) async {
    try {
      final batch = _firestore.batch();
      
      for (final entry in updates.entries) {
        final docRef = _usersCollection.doc(entry.key);
        batch.update(docRef, entry.value);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update multiple users: $e');
    }
  }

  // Get paginated users
  Future<List<User>> getPaginatedUsers({
    DocumentSnapshot? lastDocument,
    int limit = 20,
    String? role,
    String? facilityId,
  }) async {
    try {
      Query query = _usersCollection.orderBy('createdAt', descending: true);
      
      if (role != null && role.isNotEmpty) {
        query = query.where('role', isEqualTo: role);
      }
      
      if (facilityId != null && facilityId.isNotEmpty) {
        query = query.where('facilityId', isEqualTo: facilityId);
      }
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      query = query.limit(limit);
      
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => User.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get paginated users: $e');
    }
  }
}