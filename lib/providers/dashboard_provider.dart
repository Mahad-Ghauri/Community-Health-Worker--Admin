import 'package:flutter/foundation.dart';
import '../services/dashboard_service.dart';

class DashboardProvider with ChangeNotifier {
  DashboardMetrics? _metrics;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastRefresh;

  // Getters
  DashboardMetrics? get metrics => _metrics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastRefresh => _lastRefresh;

  // Derived getters for easy access
  UsersMetrics? get usersMetrics => _metrics?.usersMetrics;
  FacilitiesMetrics? get facilitiesMetrics => _metrics?.facilitiesMetrics;
  PatientsMetrics? get patientsMetrics => _metrics?.patientsMetrics;
  VisitsMetrics? get visitsMetrics => _metrics?.visitsMetrics;
  List<ActivityItem> get recentActivity => _metrics?.recentActivity ?? [];

  // Load dashboard metrics
  Future<void> loadMetrics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _metrics = await DashboardService.getDashboardMetrics();
      _lastRefresh = DateTime.now();
      _error = null;
    } catch (e) {
      _error = 'Failed to load dashboard metrics: $e';
      if (kDebugMode) {
        print('Dashboard error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh metrics
  Future<void> refreshMetrics() async {
    await loadMetrics();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Auto-refresh every 5 minutes
  void startAutoRefresh() {
    Future.delayed(const Duration(minutes: 5), () {
      if (_metrics != null) {
        refreshMetrics().then((_) {
          startAutoRefresh(); // Schedule next refresh
        });
      }
    });
  }

  // Helper methods for UI
  bool get hasData => _metrics != null;
  
  String get lastRefreshText {
    if (_lastRefresh == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(_lastRefresh!);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  // Calculate growth percentages (mock data for now)
  double get usersGrowthPercentage => 12.5; // This would come from historical data
  double get facilitiesGrowthPercentage => 8.3;
  double get patientsGrowthPercentage => 15.7;
  double get visitsGrowthPercentage => 22.1;

  // Get summary statistics
  Map<String, dynamic> get summaryStats {
    if (_metrics == null) return {};
    
    return {
      'totalUsers': _metrics!.usersMetrics.totalUsers,
      'totalFacilities': _metrics!.facilitiesMetrics.totalFacilities,
      'totalPatients': _metrics!.patientsMetrics.totalPatients,
      'totalVisits': _metrics!.visitsMetrics.totalVisits,
      'activeFacilities': _metrics!.facilitiesMetrics.activeFacilities,
      'activeUsers': _metrics!.usersMetrics.activeToday,
      'recentActivity': _metrics!.recentActivity.length,
    };
  }

  // Get system health status
  String get systemHealthStatus {
    if (_metrics == null) return 'Unknown';
    
    final totalUsers = _metrics!.usersMetrics.totalUsers;
    final activeFacilities = _metrics!.facilitiesMetrics.activeFacilities;
    final totalPatients = _metrics!.patientsMetrics.totalPatients;
    
    if (totalUsers > 10 && activeFacilities > 5 && totalPatients > 20) {
      return 'Excellent';
    } else if (totalUsers > 5 && activeFacilities > 2 && totalPatients > 10) {
      return 'Good';
    } else if (totalUsers > 0 && activeFacilities > 0) {
      return 'Fair';
    } else {
      return 'Needs Attention';
    }
  }

  // Get performance indicators
  Map<String, bool> get performanceIndicators {
    if (_metrics == null) {
      return {
        'hasUsers': false,
        'hasFacilities': false,
        'hasPatients': false,
        'hasRecentActivity': false,
      };
    }
    
    return {
      'hasUsers': _metrics!.usersMetrics.totalUsers > 0,
      'hasFacilities': _metrics!.facilitiesMetrics.totalFacilities > 0,
      'hasPatients': _metrics!.patientsMetrics.totalPatients > 0,
      'hasRecentActivity': _metrics!.recentActivity.isNotEmpty,
    };
  }
}