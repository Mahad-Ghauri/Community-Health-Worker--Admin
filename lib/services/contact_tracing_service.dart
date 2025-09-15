import 'package:cloud_firestore/cloud_firestore.dart';

class ContactTracingService {
  ContactTracingService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _contactsCol =>
      _firestore.collection('contacts');

  Stream<List<Map<String, dynamic>>> getHousehold(String indexPatientId) {
    return _contactsCol
        .where('indexPatientId', isEqualTo: indexPatientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<void> recordScreeningResult(
    String contactId,
    Map<String, dynamic> data,
  ) async {
    await _contactsCol.doc(contactId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
