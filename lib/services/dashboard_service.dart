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
    final QuerySnapshot usersSnapshot = 
        await _firestore.collection(AppConstants.usersCollection).get();

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
    final QuerySnapshot facilitiesSnapshot = 
        await _firestore.collection(AppConstants.facilitiesCollection).get();

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
    final QuerySnapshot patientsSnapshot = 
        await _firestore.collection(AppConstants.patientsCollection).get();

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

    final QuerySnapshot allVisitsSnapshot = 
        await _firestore.collection(AppConstants.visitsCollection).get();

    final QuerySnapshot thisWeekVisitsSnapshot = await _firestore
        .collection(AppConstants.visitsCollection)
        .where('visitDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .get();

    final QuerySnapshot thisMonthVisitsSnapshot = await _firestore
        .collection(AppConstants.visitsCollection)
        .where('visitDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
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
      activities.add(ActivityItem(
        type: 'user_created',
        title: 'New user registered',
        description: '${data['name']} joined as ${data['role']}',
        timestamp: (data['createdAt'] as Timestamp).toDate(),
        icon: 'person_add',
      ));
    }

    // Get recent facilities (last 3)
    final QuerySnapshot recentFacilities = await _firestore
        .collection(AppConstants.facilitiesCollection)
        .orderBy('createdAt', descending: true)
        .limit(3)
        .get();

    for (var doc in recentFacilities.docs) {
      final data = doc.data() as Map<String, dynamic>;
      activities.add(ActivityItem(
        type: 'facility_created',
        title: 'New facility added',
        description: '${data['name']} (${data['type']}) was registered',
        timestamp: (data['createdAt'] as Timestamp).toDate(),
        icon: 'business',
      ));
    }

    // Sort by timestamp (most recent first)
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return activities.take(10).toList(); // Return top 10 most recent
  }

  // Get real-time metrics stream for live updates
  static Stream<DashboardMetrics> getDashboardMetricsStream() {
    return Stream.periodic(const Duration(minutes: 5), (i) => getDashboardMetrics())
        .asyncMap((future) => future);
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