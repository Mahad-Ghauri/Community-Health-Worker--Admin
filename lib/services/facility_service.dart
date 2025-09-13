import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/facility.dart';

class FacilityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'facilities';

  // Get facilities stream with optional filtering
  static Stream<List<Facility>> getFacilitiesStream({
    String? searchQuery,
    String? typeFilter,
    String? statusFilter,
    int? limit,
  }) {
    Query query = _firestore.collection(_collection);

    // Apply filters
    if (typeFilter != null && typeFilter.isNotEmpty) {
      query = query.where('type', isEqualTo: typeFilter);
    }

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    // Order by created date
    query = query.orderBy('createdAt', descending: true);

    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      List<Facility> facilities = snapshot.docs
          .map((doc) => Facility.fromFirestore(doc))
          .toList();

      // Apply search filter on the client side
      if (searchQuery != null && searchQuery.isNotEmpty) {
        facilities = facilities.where((facility) {
          return facility.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                 facility.address.toLowerCase().contains(searchQuery.toLowerCase()) ||
                 facility.contactEmail.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();
      }

      return facilities;
    });
  }

  // Get facility by ID
  static Future<Facility?> getFacilityById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Facility.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get facility: $e');
    }
  }

  // Create new facility
  static Future<String> createFacility(Facility facility) async {
    try {
      // Validate facility data
      _validateFacility(facility);

      // Check if facility with same name already exists
      QuerySnapshot existingFacilities = await _firestore
          .collection(_collection)
          .where('name', isEqualTo: facility.name)
          .limit(1)
          .get();

      if (existingFacilities.docs.isNotEmpty) {
        throw Exception('A facility with this name already exists');
      }

      // Create facility with server timestamp
      DocumentReference docRef = await _firestore.collection(_collection).add({
        ...facility.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create facility: $e');
    }
  }

  // Update facility
  static Future<void> updateFacility(String id, Facility facility) async {
    try {
      // Validate facility data
      _validateFacility(facility);

      // Check if another facility with same name exists (excluding current)
      QuerySnapshot existingFacilities = await _firestore
          .collection(_collection)
          .where('name', isEqualTo: facility.name)
          .get();

      for (var doc in existingFacilities.docs) {
        if (doc.id != id) {
          throw Exception('A facility with this name already exists');
        }
      }

      await _firestore.collection(_collection).doc(id).update({
        ...facility.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update facility: $e');
    }
  }

  // Delete facility
  static Future<void> deleteFacility(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete facility: $e');
    }
  }

  // Get facility statistics
  static Future<Map<String, int>> getFacilityStatistics() async {
    try {
      QuerySnapshot allFacilities = await _firestore.collection(_collection).get();
      
      Map<String, int> stats = {
        'total': allFacilities.docs.length,
        'active': 0,
        'inactive': 0,
        'clinic': 0,
        'hospital': 0,
        'healthCenter': 0,
      };

      for (var doc in allFacilities.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String status = data['status'] ?? '';
        String type = data['type'] ?? '';

        // Count by status
        if (status == 'active') {
          stats['active'] = stats['active']! + 1;
        } else if (status == 'inactive') {
          stats['inactive'] = stats['inactive']! + 1;
        }

        // Count by type
        if (type == 'clinic') {
          stats['clinic'] = stats['clinic']! + 1;
        } else if (type == 'hospital') {
          stats['hospital'] = stats['hospital']! + 1;
        } else if (type == 'health_center') {
          stats['healthCenter'] = stats['healthCenter']! + 1;
        }
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get facility statistics: $e');
    }
  }

  // Bulk delete facilities
  static Future<void> deleteFacilities(List<String> ids) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      for (String id in ids) {
        DocumentReference docRef = _firestore.collection(_collection).doc(id);
        batch.delete(docRef);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete facilities: $e');
    }
  }

  // Update facility status
  static Future<void> updateFacilityStatus(String id, String status) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update facility status: $e');
    }
  }

  // Private validation method
  static void _validateFacility(Facility facility) {
    if (facility.name.trim().isEmpty) {
      throw Exception('Facility name is required');
    }
    if (facility.address.trim().isEmpty) {
      throw Exception('Facility address is required');
    }
    if (facility.contactPhone.trim().isEmpty) {
      throw Exception('Contact phone is required');
    }
    if (facility.contactEmail.trim().isEmpty) {
      throw Exception('Contact email is required');
    }
    if (!_isValidEmail(facility.contactEmail)) {
      throw Exception('Please enter a valid email address');
    }
  }

  // Email validation helper
  static bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}