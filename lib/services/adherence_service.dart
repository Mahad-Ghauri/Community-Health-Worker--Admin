import 'package:cloud_firestore/cloud_firestore.dart';

class AdherenceService {
  AdherenceService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _adherenceCol =>
      _firestore.collection('adherence');

  Stream<List<Map<String, dynamic>>> getPatientAdherence(
    String patientId, {
    DateTime? from,
    DateTime? to,
  }) {
    Query<Map<String, dynamic>> q = _adherenceCol.where(
      'patientId',
      isEqualTo: patientId,
    );
    if (from != null) {
      q = q.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      q = q.where('date', isLessThanOrEqualTo: Timestamp.fromDate(to));
    }
    return q
        .orderBy('date', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<double> calculateAdherenceScore(
    String patientId, {
    DateTime? from,
    DateTime? to,
  }) async {
    Query<Map<String, dynamic>> q = _adherenceCol.where(
      'patientId',
      isEqualTo: patientId,
    );
    if (from != null) {
      q = q.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      q = q.where('date', isLessThanOrEqualTo: Timestamp.fromDate(to));
    }
    final snap = await q.get();
    int planned = 0;
    int taken = 0;
    for (final d in snap.docs) {
      final m = d.data();
      planned += (m['dosesPlanned'] ?? 0) as int;
      taken += (m['dosesTaken'] ?? 0) as int;
    }
    if (planned == 0) return 0;
    return (taken / planned) * 100.0;
  }
}
