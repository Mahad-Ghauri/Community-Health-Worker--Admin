import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationService {
  MedicationService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _medsCol =>
      _firestore.collection('medications');

  Stream<List<Map<String, dynamic>>> getActiveMedications(String patientId) {
    return _medsCol
        .where('patientId', isEqualTo: patientId)
        .where('isActive', isEqualTo: true)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> getMedicationHistory(String patientId) {
    return _medsCol
        .where('patientId', isEqualTo: patientId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<void> addMedication(Map<String, dynamic> data) async {
    await _medsCol.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMedication(String id, Map<String, dynamic> data) async {
    await _medsCol.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deactivateMedication(String id) async {
    await _medsCol.doc(id).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
