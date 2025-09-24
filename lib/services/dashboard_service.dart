import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class DashboardService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get comprehensive dashboard metrics
  static Future<DashboardMetrics> getDashboardMetrics() async {
    try {
      // Get data from all collections concurrently
      final results = await Future.wait([
        _getUsersMetrics(),
        _getFacilitiesMetrics(),
        _getPatientsMetrics(),
        _getVisitsMetrics(),
        _getRecentActivity(),
      ]);

      return DashboardMetrics(
        usersMetrics: results[0] as UsersMetrics,
        facilitiesMetrics: results[1] as FacilitiesMetrics,
        patientsMetrics: results[2] as PatientsMetrics,
        visitsMetrics: results[3] as VisitsMetrics,
        recentActivity: results[4] as List<ActivityItem>,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to load dashboard metrics: $e');
    }
  }

  // Get users metrics
  static Future<UsersMetrics> _getUsersMetrics() async {
    final QuerySnapshot usersSnapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .get();

    int totalUsers = usersSnapshot.docs.length;
    int adminUsers = 0;
    int staffUsers = 0;
    int supervisorUsers = 0;
    int activeToday = 0;

    final DateTime today = DateTime.now();
    final DateTime startOfDay = DateTime(today.year, today.month, today.day);

    for (var doc in usersSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final role = data['role'] ?? '';

      switch (role) {
        case AppConstants.adminRole:
          adminUsers++;
          break;
        case AppConstants.staffRole:
          staffUsers++;
          break;
        case AppConstants.supervisorRole:
          supervisorUsers++;
          break;
      }

      // Check if user was active today (created today or has recent activity)
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null && createdAt.isAfter(startOfDay)) {
        activeToday++;
      }
    }

    return UsersMetrics(
      totalUsers: totalUsers,
      adminUsers: adminUsers,
      staffUsers: staffUsers,
      supervisorUsers: supervisorUsers,
      activeToday: activeToday,
    );
  }

  // Get facilities metrics
  static Future<FacilitiesMetrics> _getFacilitiesMetrics() async {
    final QuerySnapshot facilitiesSnapshot = await _firestore
        .collection(AppConstants.facilitiesCollection)
        .get();

    int totalFacilities = facilitiesSnapshot.docs.length;
    int activeFacilities = 0;
    int hospitals = 0;
    int healthCenters = 0;
    int clinics = 0;

    for (var doc in facilitiesSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] ?? '';
      final type = data['type'] ?? '';

      if (status == 'active') {
        activeFacilities++;
      }

      switch (type) {
        case AppConstants.hospitalType:
          hospitals++;
          break;
        case AppConstants.healthCenterType:
          healthCenters++;
          break;
        case AppConstants.clinicType:
          clinics++;
          break;
      }
    }

    return FacilitiesMetrics(
      totalFacilities: totalFacilities,
      activeFacilities: activeFacilities,
      hospitals: hospitals,
      healthCenters: healthCenters,
      clinics: clinics,
    );
  }

  // Get patients metrics
  static Future<PatientsMetrics> _getPatientsMetrics() async {
    final QuerySnapshot patientsSnapshot = await _firestore
        .collection(AppConstants.patientsCollection)
        .get();

    int totalPatients = patientsSnapshot.docs.length;
    int newlyDiagnosed = 0;
    int onTreatment = 0;
    int completed = 0;
    int lostToFollowUp = 0;

    for (var doc in patientsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['tbStatus'] ?? '';

      switch (status) {
        case AppConstants.newlyDiagnosedStatus:
          newlyDiagnosed++;
          break;
        case AppConstants.onTreatmentStatus:
          onTreatment++;
          break;
        case AppConstants.treatmentCompletedStatus:
          completed++;
          break;
        case AppConstants.lostToFollowUpStatus:
          lostToFollowUp++;
          break;
      }
    }

    return PatientsMetrics(
      totalPatients: totalPatients,
      newlyDiagnosed: newlyDiagnosed,
      onTreatment: onTreatment,
      completed: completed,
      lostToFollowUp: lostToFollowUp,
    );
  }

  // Get visits metrics
  static Future<VisitsMetrics> _getVisitsMetrics() async {
    final DateTime now = DateTime.now();
    final DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final DateTime startOfMonth = DateTime(now.year, now.month, 1);

    final QuerySnapshot allVisitsSnapshot = await _firestore
        .collection(AppConstants.visitsCollection)
        .get();

    final QuerySnapshot thisWeekVisitsSnapshot = await _firestore
        .collection(AppConstants.visitsCollection)
        .where(
          'visitDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek),
        )
        .get();

    final QuerySnapshot thisMonthVisitsSnapshot = await _firestore
        .collection(AppConstants.visitsCollection)
        .where(
          'visitDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
        )
        .get();

    int homeVisits = 0;
    int followUps = 0;
    int tracing = 0;
    int medicineDelivery = 0;
    int counseling = 0;

    for (var doc in allVisitsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final visitType = data['visitType'] ?? '';

      switch (visitType) {
        case AppConstants.homeVisitType:
          homeVisits++;
          break;
        case AppConstants.followUpType:
          followUps++;
          break;
        case AppConstants.tracingType:
          tracing++;
          break;
        case AppConstants.medicineDeliveryType:
          medicineDelivery++;
          break;
        case AppConstants.counselingType:
          counseling++;
          break;
      }
    }

    return VisitsMetrics(
      totalVisits: allVisitsSnapshot.docs.length,
      thisWeekVisits: thisWeekVisitsSnapshot.docs.length,
      thisMonthVisits: thisMonthVisitsSnapshot.docs.length,
      homeVisits: homeVisits,
      followUps: followUps,
      tracing: tracing,
      medicineDelivery: medicineDelivery,
      counseling: counseling,
    );
  }

  // Get recent activity
  static Future<List<ActivityItem>> _getRecentActivity() async {
    final List<ActivityItem> activities = [];

    // Get recent users (last 5)
    final QuerySnapshot recentUsers = await _firestore
        .collection(AppConstants.usersCollection)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

    for (var doc in recentUsers.docs) {
      final data = doc.data() as Map<String, dynamic>;
      activities.add(
        ActivityItem(
          type: 'user_created',
          title: 'New user registered',
          description: '${data['name']} joined as ${data['role']}',
          timestamp: (data['createdAt'] as Timestamp).toDate(),
          icon: 'person_add',
        ),
      );
    }

    // Get recent facilities (last 3)
    final QuerySnapshot recentFacilities = await _firestore
        .collection(AppConstants.facilitiesCollection)
        .orderBy('createdAt', descending: true)
        .limit(3)
        .get();

    for (var doc in recentFacilities.docs) {
      final data = doc.data() as Map<String, dynamic>;
      activities.add(
        ActivityItem(
          type: 'facility_created',
          title: 'New facility added',
          description: '${data['name']} (${data['type']}) was registered',
          timestamp: (data['createdAt'] as Timestamp).toDate(),
          icon: 'business',
        ),
      );
    }

    // Sort by timestamp (most recent first)
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return activities.take(10).toList(); // Return top 10 most recent
  }

  // Get real-time metrics stream for live updates
  static Stream<DashboardMetrics> getDashboardMetricsStream() {
    return Stream.periodic(
      const Duration(minutes: 5),
      (i) => getDashboardMetrics(),
    ).asyncMap((future) => future);
  }

  // Supervisor-specific metrics -------------------------------------------------
  static Future<SupervisorMetrics> getSupervisorMetrics({
    String? facilityId,
    String? chwId,
    DateTime? from,
    DateTime? to,
  }) async {
    final DateTime rangeStart =
        from ?? DateTime.now().subtract(const Duration(days: 30));
    final DateTime rangeEnd = to ?? DateTime.now();

    // Run queries in parallel
    final results = await Future.wait([
      _getFollowupStats(facilityId: facilityId, from: rangeStart, to: rangeEnd),
      _getPatientsByTbStatus(facilityId: facilityId),
      _getChwLeaderboard(
        facilityId: facilityId,
        from: rangeStart,
        to: rangeEnd,
      ),
      _getFacilityPerformance(from: rangeStart, to: rangeEnd),
    ]);

    return SupervisorMetrics(
      followupStats: results[0] as FollowupStats,
      patientsByStatus: results[1] as Map<String, int>,
      chwLeaderboard: results[2] as List<LeaderboardItem>,
      facilityPerformance: results[3] as List<FacilityPerformance>,
      from: rangeStart,
      to: rangeEnd,
    );
  }

  static Future<FollowupStats> _getFollowupStats({
    String? facilityId,
    required DateTime from,
    required DateTime to,
  }) async {
    Query<Map<String, dynamic>> q = _firestore.collection('followups');
    if (facilityId != null && facilityId.isNotEmpty) {
      q = q.where('facilityId', isEqualTo: facilityId);
    }
    q = q
        .where(
          'scheduledDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(from),
        )
        .where('scheduledDate', isLessThanOrEqualTo: Timestamp.fromDate(to));

    final snap = await q.get();
    int scheduled = 0,
        completed = 0,
        missed = 0,
        cancelled = 0,
        rescheduled = 0,
        overdue = 0;
    final now = DateTime.now();
    for (final d in snap.docs) {
      final data = d.data();
      final String status = (data['status'] as String?) ?? 'scheduled';
      final DateTime sched =
          (data['scheduledDate'] as Timestamp?)?.toDate() ?? now;
      switch (status) {
        case 'scheduled':
          scheduled++;
          if (sched.isBefore(now)) overdue++;
          break;
        case 'completed':
          completed++;
          break;
        case 'missed':
          missed++;
          break;
        case 'cancelled':
          cancelled++;
          break;
        case 'rescheduled':
          rescheduled++;
          break;
      }
    }
    return FollowupStats(
      scheduled: scheduled,
      completed: completed,
      missed: missed,
      cancelled: cancelled,
      rescheduled: rescheduled,
      overdue: overdue,
      total: snap.docs.length,
    );
  }

  static Future<Map<String, int>> _getPatientsByTbStatus({
    String? facilityId,
  }) async {
    Query<Map<String, dynamic>> q = _firestore.collection(
      AppConstants.patientsCollection,
    );
    if (facilityId != null && facilityId.isNotEmpty) {
      q = q.where('assignedFacility', isEqualTo: facilityId);
    }
    final snap = await q.get();
    final Map<String, int> counts = {
      AppConstants.newlyDiagnosedStatus: 0,
      AppConstants.onTreatmentStatus: 0,
      AppConstants.treatmentCompletedStatus: 0,
      AppConstants.lostToFollowUpStatus: 0,
    };
    for (final d in snap.docs) {
      final status =
          (d.data()['tbStatus'] as String?) ??
          AppConstants.newlyDiagnosedStatus;
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  static Future<List<LeaderboardItem>> _getChwLeaderboard({
    String? facilityId,
    required DateTime from,
    required DateTime to,
  }) async {
    // Approximation using followups completed per CHW within range
    Query<Map<String, dynamic>> q = _firestore
        .collection('followups')
        .where('status', isEqualTo: 'completed')
        .where(
          'completedDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(from),
        )
        .where('completedDate', isLessThanOrEqualTo: Timestamp.fromDate(to));
    if (facilityId != null && facilityId.isNotEmpty) {
      q = q.where('facilityId', isEqualTo: facilityId);
    }
    final snap = await q.get();
    final Map<String, int> perChw = {};
    for (final d in snap.docs) {
      final chwId =
          (d.data()['completedBy'] as String?) ??
          (d.data()['assignedStaffId'] as String?) ??
          '';
      if (chwId.isEmpty) continue;
      perChw[chwId] = (perChw[chwId] ?? 0) + 1;
    }
    final items = perChw.entries
        .map(
          (e) => LeaderboardItem(
            entityId: e.key,
            label:
                'CHW ${e.key.substring(0, e.key.length > 6 ? 6 : e.key.length)}',
            score: e.value,
          ),
        )
        .toList();
    items.sort((a, b) => b.score.compareTo(a.score));
    return items.take(10).toList();
  }

  static Future<List<FacilityPerformance>> _getFacilityPerformance({
    required DateTime from,
    required DateTime to,
  }) async {
    // Compute per-facility counts: patients, followups completed, visits this month
    final patientsSnap = await _firestore
        .collection(AppConstants.patientsCollection)
        .get();
    final followupsSnap = await _firestore
        .collection('followups')
        .where(
          'completedDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(from),
        )
        .where('completedDate', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .get();

    final Map<String, int> facilityPatients = {};
    for (final d in patientsSnap.docs) {
      final fac = (d.data()['assignedFacility'] as String?) ?? '';
      if (fac.isEmpty) continue;
      facilityPatients[fac] = (facilityPatients[fac] ?? 0) + 1;
    }

    final Map<String, int> facilityCompletedFollowups = {};
    for (final d in followupsSnap.docs) {
      final fac = (d.data()['facilityId'] as String?) ?? '';
      if (fac.isEmpty) continue;
      facilityCompletedFollowups[fac] =
          (facilityCompletedFollowups[fac] ?? 0) + 1;
    }

    final Set<String> facilityIds = {
      ...facilityPatients.keys,
      ...facilityCompletedFollowups.keys,
    };
    final List<FacilityPerformance> perf = [];
    for (final id in facilityIds) {
      perf.add(
        FacilityPerformance(
          facilityId: id,
          patients: facilityPatients[id] ?? 0,
          completedFollowups: facilityCompletedFollowups[id] ?? 0,
        ),
      );
    }
    perf.sort((a, b) => b.completedFollowups.compareTo(a.completedFollowups));
    return perf;
  }
}

// Data models for dashboard metrics
class DashboardMetrics {
  final UsersMetrics usersMetrics;
  final FacilitiesMetrics facilitiesMetrics;
  final PatientsMetrics patientsMetrics;
  final VisitsMetrics visitsMetrics;
  final List<ActivityItem> recentActivity;
  final DateTime lastUpdated;

  DashboardMetrics({
    required this.usersMetrics,
    required this.facilitiesMetrics,
    required this.patientsMetrics,
    required this.visitsMetrics,
    required this.recentActivity,
    required this.lastUpdated,
  });
}

class UsersMetrics {
  final int totalUsers;
  final int adminUsers;
  final int staffUsers;
  final int supervisorUsers;
  final int activeToday;

  UsersMetrics({
    required this.totalUsers,
    required this.adminUsers,
    required this.staffUsers,
    required this.supervisorUsers,
    required this.activeToday,
  });
}

class FacilitiesMetrics {
  final int totalFacilities;
  final int activeFacilities;
  final int hospitals;
  final int healthCenters;
  final int clinics;

  FacilitiesMetrics({
    required this.totalFacilities,
    required this.activeFacilities,
    required this.hospitals,
    required this.healthCenters,
    required this.clinics,
  });
}

class PatientsMetrics {
  final int totalPatients;
  final int newlyDiagnosed;
  final int onTreatment;
  final int completed;
  final int lostToFollowUp;

  PatientsMetrics({
    required this.totalPatients,
    required this.newlyDiagnosed,
    required this.onTreatment,
    required this.completed,
    required this.lostToFollowUp,
  });
}

class VisitsMetrics {
  final int totalVisits;
  final int thisWeekVisits;
  final int thisMonthVisits;
  final int homeVisits;
  final int followUps;
  final int tracing;
  final int medicineDelivery;
  final int counseling;

  VisitsMetrics({
    required this.totalVisits,
    required this.thisWeekVisits,
    required this.thisMonthVisits,
    required this.homeVisits,
    required this.followUps,
    required this.tracing,
    required this.medicineDelivery,
    required this.counseling,
  });
}

class ActivityItem {
  final String type;
  final String title;
  final String description;
  final DateTime timestamp;
  final String icon;

  ActivityItem({
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.icon,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// Supervisor metrics models -----------------------------------------------------
class SupervisorMetrics {
  final FollowupStats followupStats;
  final Map<String, int> patientsByStatus;
  final List<LeaderboardItem> chwLeaderboard;
  final List<FacilityPerformance> facilityPerformance;
  final DateTime from;
  final DateTime to;

  SupervisorMetrics({
    required this.followupStats,
    required this.patientsByStatus,
    required this.chwLeaderboard,
    required this.facilityPerformance,
    required this.from,
    required this.to,
  });
}

class FollowupStats {
  final int total;
  final int scheduled;
  final int completed;
  final int missed;
  final int cancelled;
  final int rescheduled;
  final int overdue;

  FollowupStats({
    required this.total,
    required this.scheduled,
    required this.completed,
    required this.missed,
    required this.cancelled,
    required this.rescheduled,
    required this.overdue,
  });
}

class LeaderboardItem {
  final String entityId;
  final String label;
  final int score;

  LeaderboardItem({
    required this.entityId,
    required this.label,
    required this.score,
  });
}

class FacilityPerformance {
  final String facilityId;
  final int patients;
  final int completedFollowups;

  FacilityPerformance({
    required this.facilityId,
    required this.patients,
    required this.completedFollowups,
  });
}
