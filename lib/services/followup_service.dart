import 'package:cloud_firestore/cloud_firestore.dart';

class FollowupService {
  FollowupService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _followupsCol =>
      _firestore.collection('followups');

  Stream<List<Map<String, dynamic>>> getPatientFollowups(String patientId) {
    return _followupsCol
        .where('patientId', isEqualTo: patientId)
        .orderBy('scheduledDate', descending: true)
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

  // Query followups by facility and date range (for calendar lazy loading)
  Stream<QuerySnapshot<Map<String, dynamic>>> getFacilityFollowupsInRange({
    required String facilityId,
    required DateTime start,
    required DateTime end,
  }) {
    return _followupsCol
        .where('facilityId', isEqualTo: facilityId)
        .where(
          'scheduledDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where('scheduledDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('scheduledDate')
        .snapshots();
  }

  Future<int> countOverlappingAppointments({
    required String facilityId,
    required DateTime start,
    required int durationMinutes,
  }) async {
    final DateTime end = start.add(Duration(minutes: durationMinutes));
    // Fetch appointments that start before end and end after start (approx by scheduledDate window)
    final snap = await _followupsCol
        .where('facilityId', isEqualTo: facilityId)
        .where('scheduledDate', isLessThan: Timestamp.fromDate(end))
        .get();
    int count = 0;
    for (final doc in snap.docs) {
      final data = doc.data();
      final DateTime s = (data['scheduledDate'] as Timestamp).toDate();
      final int dur = (data['durationMinutes'] as int?) ?? 30;
      final DateTime e = s.add(Duration(minutes: dur));
      final bool overlap = s.isBefore(end) && e.isAfter(start);
      if (overlap && (data['status'] ?? 'scheduled') == 'scheduled') {
        count++;
      }
    }
    return count;
  }
}
