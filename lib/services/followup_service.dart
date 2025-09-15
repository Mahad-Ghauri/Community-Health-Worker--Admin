import 'package:cloud_firestore/cloud_firestore.dart';

class FollowupService {
  FollowupService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _followupsCol =>
      _firestore.collection('followups');

  Stream<List<Map<String, dynamic>>> getPatientFollowups(String patientId) {
    return _followupsCol
        .where('patientId', isEqualTo: patientId)
        .orderBy('scheduledAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<void> scheduleFollowup(Map<String, dynamic> data) async {
    await _followupsCol.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFollowupStatus(String id, String status) async {
    await _followupsCol.doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
