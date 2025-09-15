import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/facility.dart';
import '../constants/app_constants.dart';

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
          return facility.name.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              facility.address.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              facility.contactEmail.toLowerCase().contains(
                searchQuery.toLowerCase(),
              );
        }).toList();
      }

      return facilities;
    });
  }

  // Get facility by ID
  static Future<Facility?> getFacilityById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collection)
          .doc(id)
          .get();
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
      QuerySnapshot allFacilities = await _firestore
          .collection(_collection)
          .get();

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

  // Get facility dashboard metrics
  static Future<Map<String, dynamic>> getFacilityMetrics(
    String facilityId,
  ) async {
    try {
      // Get facility details
      DocumentSnapshot facilityDoc = await _firestore
          .collection(_collection)
          .doc(facilityId)
          .get();
      if (!facilityDoc.exists) {
        throw Exception('Facility not found');
      }

      // Get total patients count for this facility
      QuerySnapshot totalPatientsSnapshot = await _firestore
          .collection(AppConstants.patientsCollection)
          .where('treatmentFacility', isEqualTo: facilityId)
          .get();

      // Get patients on treatment count
      QuerySnapshot onTreatmentSnapshot = await _firestore
          .collection(AppConstants.patientsCollection)
          .where('treatmentFacility', isEqualTo: facilityId)
          .where('tbStatus', isEqualTo: AppConstants.onTreatmentStatus)
          .get();

      // Get pending referrals count
      QuerySnapshot pendingReferralsSnapshot = await _firestore
          .collection(AppConstants.patientsCollection)
          .where('assignedFacility', isEqualTo: facilityId)
          .where('treatmentFacility', isEqualTo: null)
          .get();

      // Get lost to follow-up count
      QuerySnapshot lostToFollowUpSnapshot = await _firestore
          .collection(AppConstants.patientsCollection)
          .where('treatmentFacility', isEqualTo: facilityId)
          .where('tbStatus', isEqualTo: AppConstants.lostToFollowUpStatus)
          .get();

      // Calculate trend percentages (mock data for now)
      // In a real implementation, you would compare with historical data
      double patientsTrend = 5.2;
      double treatmentTrend = 8.7;
      double referralsTrend = -3.1;
      double ltfuTrend = 2.4;

      return {
        'totalPatients': totalPatientsSnapshot.docs.length,
        'onTreatment': onTreatmentSnapshot.docs.length,
        'pendingReferrals': pendingReferralsSnapshot.docs.length,
        'lostToFollowUp': lostToFollowUpSnapshot.docs.length,
        'patientsTrend': patientsTrend,
        'treatmentTrend': treatmentTrend,
        'referralsTrend': referralsTrend,
        'ltfuTrend': ltfuTrend,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting facility metrics: $e');
      }
      throw Exception('Failed to get facility metrics: $e');
    }
  }

  // Get facility activities
  static Future<List<Map<String, dynamic>>> getFacilityActivities(
    String facilityId,
  ) async {
    try {
      List<Map<String, dynamic>> activities = [];

      // Get recent visits for this facility
      QuerySnapshot visitsSnapshot = await _firestore
          .collection(AppConstants.visitsCollection)
          .where('facilityId', isEqualTo: facilityId)
          .orderBy('visitDate', descending: true)
          .limit(10)
          .get();

      for (var doc in visitsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Get patient name
        String patientId = data['patientId'] ?? '';
        String patientName = 'Unknown Patient';

        if (patientId.isNotEmpty) {
          try {
            DocumentSnapshot patientDoc = await _firestore
                .collection(AppConstants.patientsCollection)
                .doc(patientId)
                .get();

            if (patientDoc.exists) {
              Map<String, dynamic> patientData =
                  patientDoc.data() as Map<String, dynamic>;
              patientName = patientData['name'] ?? 'Unknown Patient';
            }
          } catch (e) {
            // Ignore patient lookup errors
          }
        }

        activities.add({
          'id': doc.id,
          'type': 'visit',
          'title': 'Patient Visit',
          'description': '${data['visitType']} visit for $patientName',
          'timestamp': (data['visitDate'] as Timestamp).toDate(),
        });
      }

      // Get recent assignments for this facility
      QuerySnapshot assignmentsSnapshot = await _firestore
          .collection('assignments')
          .where('facilityId', isEqualTo: facilityId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      for (var doc in assignmentsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        activities.add({
          'id': doc.id,
          'type': 'assignment',
          'title': 'CHW Assignment',
          'description': 'Patient assigned to ${data['chwName'] ?? 'a CHW'}',
          'timestamp': (data['createdAt'] as Timestamp).toDate(),
        });
      }

      // Get recent referrals for this facility
      QuerySnapshot referralsSnapshot = await _firestore
          .collection('referrals')
          .where('facilityId', isEqualTo: facilityId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      for (var doc in referralsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        activities.add({
          'id': doc.id,
          'type': 'referral',
          'title': 'Patient Referral',
          'description':
              'Referral ${data['status']} for ${data['patientName'] ?? 'a patient'}',
          'timestamp': (data['createdAt'] as Timestamp).toDate(),
        });
      }

      // Get recent follow-ups for this facility
      QuerySnapshot followupsSnapshot = await _firestore
          .collection('followups')
          .where('facilityId', isEqualTo: facilityId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      for (var doc in followupsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        activities.add({
          'id': doc.id,
          'type': 'followup',
          'title': 'Follow-up Scheduled',
          'description': 'Follow-up for ${data['patientName'] ?? 'a patient'}',
          'timestamp': (data['createdAt'] as Timestamp).toDate(),
        });
      }

      // Sort all activities by timestamp (most recent first)
      activities.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      // Return top 15 most recent activities
      return activities.take(15).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting facility activities: $e');
      }
      throw Exception('Failed to get facility activities: $e');
    }
  }

  // Get treatment adherence data for charts
  static Future<List<Map<String, dynamic>>> getTreatmentAdherenceData(
    String facilityId,
  ) async {
    try {
      // This would normally query a treatment_adherence collection
      // For now, we'll return mock data for the chart

      List<Map<String, dynamic>> mockData = [
        {'week': 'Week 1', 'adherence': 92, 'target': 95},
        {'week': 'Week 2', 'adherence': 88, 'target': 95},
        {'week': 'Week 3', 'adherence': 94, 'target': 95},
        {'week': 'Week 4', 'adherence': 90, 'target': 95},
        {'week': 'Week 5', 'adherence': 96, 'target': 95},
        {'week': 'Week 6', 'adherence': 93, 'target': 95},
        {'week': 'Week 7', 'adherence': 91, 'target': 95},
        {'week': 'Week 8', 'adherence': 95, 'target': 95},
      ];

      return mockData;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting treatment adherence data: $e');
      }
      throw Exception('Failed to get treatment adherence data: $e');
    }
  }
}
