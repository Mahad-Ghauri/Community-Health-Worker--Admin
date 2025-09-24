import 'package:flutter/foundation.dart';
import '../services/dashboard_service.dart';

class SupervisorDashboardProvider with ChangeNotifier {
  SupervisorMetrics? _metrics;
  bool _isLoading = false;
  String? _error;

  // Filters
  String? _facilityId;
  String? _chwId;
  DateTime? _from;
  DateTime? _to;

  // Getters
  SupervisorMetrics? get metrics => _metrics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String? get facilityId => _facilityId;
  String? get chwId => _chwId;
  DateTime? get from => _from;
  DateTime? get to => _to;

  // Load
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _metrics = await DashboardService.getSupervisorMetrics(
        facilityId: _facilityId,
        chwId: _chwId,
        from: _from,
        to: _to,
      );
    } catch (e) {
      _error = 'Failed to load supervisor metrics: $e';
      if (kDebugMode) {
        print(_error);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filters setters
  void setFacility(String? facilityId) {
    _facilityId = facilityId;
    load();
  }

  void setChw(String? chwId) {
    _chwId = chwId;
    load();
  }

  void setDateRange(DateTime? from, DateTime? to) {
    _from = from;
    _to = to;
    load();
  }

  // Convenience getters
  FollowupStats? get followupStats => _metrics?.followupStats;
  Map<String, int> get patientsByStatus => _metrics?.patientsByStatus ?? {};
  List<LeaderboardItem> get chwLeaderboard => _metrics?.chwLeaderboard ?? [];
  List<FacilityPerformance> get facilityPerformance =>
      _metrics?.facilityPerformance ?? [];
}
