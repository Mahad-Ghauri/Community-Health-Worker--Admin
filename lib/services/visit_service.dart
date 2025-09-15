import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

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

  Future<void> createVisit(Map<String, dynamic> data) async {
    await _visitsCol.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
