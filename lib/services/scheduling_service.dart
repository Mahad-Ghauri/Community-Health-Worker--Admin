import 'package:cloud_firestore/cloud_firestore.dart';

class SchedulingConfig {
  final Map<String, Map<String, String>>
  workingHours; // dayOfWeek: {start, end}
  final List<Map<String, String>> breaks; // [{start, end}]
  final List<DateTime> holidayDates;
  final int maxPerSlot;
  final int slotMinutes;
  final bool emergencyOverflow;

  SchedulingConfig({
    required this.workingHours,
    required this.breaks,
    required this.holidayDates,
    required this.maxPerSlot,
    required this.slotMinutes,
    required this.emergencyOverflow,
  });

  factory SchedulingConfig.fromFirestore(Map<String, dynamic> data) {
    final Map<String, Map<String, String>> wh = {};
    (data['workingHours'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      wh[k] = {
        'start': (v['start'] as String?) ?? '08:00',
        'end': (v['end'] as String?) ?? '17:00',
      };
    });
    final List<Map<String, String>> brks =
        ((data['breaks'] as List<dynamic>?) ?? [])
            .map(
              (e) => {
                'start': (e['start'] as String?) ?? '12:00',
                'end': (e['end'] as String?) ?? '13:00',
              },
            )
            .toList();
    final List<DateTime> holidays =
        ((data['holidayDates'] as List<dynamic>?) ?? [])
            .map((e) => (e as Timestamp).toDate())
            .toList();
    return SchedulingConfig(
      workingHours: wh,
      breaks: brks,
      holidayDates: holidays,
      maxPerSlot: (data['maxPerSlot'] as int?) ?? 3,
      slotMinutes: (data['slotMinutes'] as int?) ?? 30,
      emergencyOverflow: (data['emergencySlots']?['enabled'] as bool?) ?? false,
    );
  }
}

class SchedulingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _facilityConfigDoc(
    String facilityId,
  ) => _firestore.collection('facility_scheduling').doc(facilityId);

  Stream<SchedulingConfig> getFacilityScheduling(String facilityId) {
    return _facilityConfigDoc(facilityId).snapshots().map((snap) {
      final data = snap.data() ?? {};
      return SchedulingConfig.fromFirestore(data);
    });
  }

  Future<SchedulingConfig> fetchFacilityScheduling(String facilityId) async {
    final snap = await _facilityConfigDoc(facilityId).get();
    return SchedulingConfig.fromFirestore(snap.data() ?? {});
  }

  bool isHoliday(DateTime date, SchedulingConfig cfg) {
    final d = DateTime(date.year, date.month, date.day);
    return cfg.holidayDates.any(
      (h) => h.year == d.year && h.month == d.month && h.day == d.day,
    );
  }

  bool _isWithin(String hhmm, DateTime dt) {
    final parts = hhmm.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return dt.hour > h || (dt.hour == h && dt.minute >= m);
  }

  bool _isBefore(String hhmm, DateTime dt) {
    final parts = hhmm.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return dt.hour < h || (dt.hour == h && dt.minute < m);
  }

  bool isWithinWorkingHours(
    DateTime start,
    int durationMinutes,
    SchedulingConfig cfg,
  ) {
    final day = [
      'mon',
      'tue',
      'wed',
      'thu',
      'fri',
      'sat',
      'sun',
    ][start.weekday - 1];
    final hours = cfg.workingHours[day] ?? {'start': '08:00', 'end': '17:00'};
    final end = start.add(Duration(minutes: durationMinutes));
    return _isWithin(hours['start']!, start) && _isBefore(hours['end']!, end);
  }

  bool isWithinBreaks(
    DateTime start,
    int durationMinutes,
    SchedulingConfig cfg,
  ) {
    final end = start.add(Duration(minutes: durationMinutes));
    for (final b in cfg.breaks) {
      final bs = b['start']!;
      final be = b['end']!;
      // If any overlap with break window
      final bsDt = DateTime(
        start.year,
        start.month,
        start.day,
        int.parse(bs.split(':')[0]),
        int.parse(bs.split(':')[1]),
      );
      final beDt = DateTime(
        start.year,
        start.month,
        start.day,
        int.parse(be.split(':')[0]),
        int.parse(be.split(':')[1]),
      );
      final overlap = start.isBefore(beDt) && end.isAfter(bsDt);
      if (overlap) return true;
    }
    return false;
  }
}
