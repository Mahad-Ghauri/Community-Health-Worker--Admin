import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import 'package:flutter/foundation.dart';

class VisitService {
  VisitService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _visitsCol =>
      _firestore.collection(AppConstants.visitsCollection);

  Stream<List<Map<String, dynamic>>> getPatientVisits(
    String patientId, {
    int limit = 50,
  }) {
    return _visitsCol
        .where('patientId', isEqualTo: patientId)
        .orderBy('visitDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  // Get visits by CHW ID
  Stream<List<Map<String, dynamic>>> getCHWVisits(
    String chwId, {
    int limit = 100,
  }) {
    return _visitsCol
        .where('chwId', isEqualTo: chwId)
        .orderBy('visitDate', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList(),
        );
  }

  // Get all visits (for supervisor)
  Stream<List<Map<String, dynamic>>> getAllVisits({
    int limit = 200,
    String? facilityId,
  }) {
    if (kDebugMode) {
      print('📋 VisitService.getAllVisits called');
      print('   Limit: $limit');
      print('   FacilityId: $facilityId');
    }

    try {
      // Query without orderBy first to avoid index requirements
      return _visitsCol.limit(limit).snapshots().map((snap) {
        if (kDebugMode) {
          print('📋 Firestore response received');
          print('   Documents count: ${snap.docs.length}');
        }

        var docs = snap.docs.map((d) {
          var data = d.data();
          data['id'] = d.id;
          return data;
        }).toList();

        // Filter by facilityId client-side if provided
        if (facilityId != null && facilityId.isNotEmpty) {
          docs = docs.where((doc) => doc['facilityId'] == facilityId).toList();
          if (kDebugMode) {
            print('   After facility filter: ${docs.length}');
          }
        }

        // Sort by visitDate or date client-side
        docs.sort((a, b) {
          final dateA =
              (a['visitDate'] as Timestamp?)?.toDate() ??
              (a['date'] as Timestamp?)?.toDate() ??
              DateTime(1970);
          final dateB =
              (b['visitDate'] as Timestamp?)?.toDate() ??
              (b['date'] as Timestamp?)?.toDate() ??
              DateTime(1970);
          return dateB.compareTo(dateA); // Descending order
        });

        if (kDebugMode) {
          print('   Final sorted list: ${docs.length} visits');
        }

        return docs;
      });
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error in getAllVisits: $e');
        print('   Stack: $stackTrace');
      }
      rethrow;
    }
  }

  Future<void> createVisit(Map<String, dynamic> data) async {
    await _visitsCol.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
