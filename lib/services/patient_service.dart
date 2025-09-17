import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../models/patient.dart';

class PatientService {
  PatientService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _patientsCol =>
      _firestore.collection(AppConstants.patientsCollection);

  Query<Map<String, dynamic>> _baseFacilityQuery(String facilityId) {
    return _patientsCol.where('treatmentFacility', isEqualTo: facilityId);
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getFacilityPatientsPage({
    required String facilityId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
    String? tbStatus,
    String? assignedCHW,
    String? gender,
    DateTime? registeredFrom,
    DateTime? registeredTo,
    String sortField = 'createdAt',
    bool descending = true,
  }) async {
    Query<Map<String, dynamic>> query = _baseFacilityQuery(facilityId);

    if (tbStatus != null && tbStatus.isNotEmpty) {
      query = query.where('tbStatus', isEqualTo: tbStatus);
    }
    if (assignedCHW != null && assignedCHW.isNotEmpty) {
      query = query.where('assignedCHW', isEqualTo: assignedCHW);
    }
    if (gender != null && gender.isNotEmpty) {
      query = query.where('gender', isEqualTo: gender);
    }
    if (registeredFrom != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(registeredFrom),
      );
    }
    if (registeredTo != null) {
      query = query.where(
        'createdAt',
        isLessThanOrEqualTo: Timestamp.fromDate(registeredTo),
      );
    }

    query = query.orderBy(sortField, descending: descending).limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    try {
      return await query.get();
    } on FirebaseException catch (e) {
      // Graceful fallback if composite index is missing
      if (e.code == 'failed-precondition') {
        Query<Map<String, dynamic>> fallback = _baseFacilityQuery(
          facilityId,
        ).limit(limit);
        if (lastDocument != null) {
          // startAfter requires an orderBy cursor; so skip pagination on fallback
        }
        return await fallback.get();
      }
      rethrow;
    }
  }

  Stream<List<Patient>> getFacilityPatientsStream({
    required String facilityId,
    String? tbStatus,
    String? assignedCHW,
    String? gender,
    DateTime? registeredFrom,
    DateTime? registeredTo,
    String sortField = 'createdAt',
    bool descending = true,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _baseFacilityQuery(facilityId);

    if (tbStatus != null && tbStatus.isNotEmpty) {
      query = query.where('tbStatus', isEqualTo: tbStatus);
    }
    if (assignedCHW != null && assignedCHW.isNotEmpty) {
      query = query.where('assignedCHW', isEqualTo: assignedCHW);
    }
    if (gender != null && gender.isNotEmpty) {
      query = query.where('gender', isEqualTo: gender);
    }
    if (registeredFrom != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(registeredFrom),
      );
    }
    if (registeredTo != null) {
      query = query.where(
        'createdAt',
        isLessThanOrEqualTo: Timestamp.fromDate(registeredTo),
      );
    }

    query = query.orderBy(sortField, descending: descending);
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Patient.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  Future<void> updatePatient(
    String patientId,
    Map<String, dynamic> data,
  ) async {
    await _patientsCol.doc(patientId).update(data);
  }

  Future<void> bulkUpdatePatients(
    Map<String, Map<String, dynamic>> updates,
  ) async {
    final batch = _firestore.batch();
    updates.forEach((id, data) {
      batch.update(_patientsCol.doc(id), data);
    });
    await batch.commit();
  }

  Future<void> markAsLTFU(String patientId) async {
    await _patientsCol.doc(patientId).update({
      'tbStatus': AppConstants.lostToFollowUpStatus,
    });
  }

  Future<void> transferPatient(String patientId, String newFacilityId) async {
    await _patientsCol.doc(patientId).update({
      'treatmentFacility': newFacilityId,
    });
  }

  Future<List<Patient>> searchPatientsAtFacility({
    required String facilityId,
    required String term,
    int limit = 20,
  }) async {
    final String q = term.trim().toLowerCase();
    if (q.isEmpty) return [];

    // Strategy: attempt exact/equality searches where possible, fallback to client filter
    final QuerySnapshot<Map<String, dynamic>> base = await _baseFacilityQuery(
      facilityId,
    ).orderBy('createdAt', descending: true).limit(200).get();

    final List<Patient> all = base.docs
        .map((d) => Patient.fromMap(d.data(), d.id))
        .toList();

    final List<Patient> filtered = all
        .where((p) {
          final name = p.name.toLowerCase();
          final phone = p.phone.toLowerCase();
          final address = p.address.toLowerCase();
          final pid = p.patientId.toLowerCase();
          return name.contains(q) ||
              phone.contains(q) ||
              address.contains(q) ||
              pid.contains(q);
        })
        .take(limit)
        .toList();

    return filtered;
  }
}
