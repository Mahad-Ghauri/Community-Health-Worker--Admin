import 'package:flutter/foundation.dart';
import '../models/facility.dart';
import '../services/facility_service.dart';

class FacilityProvider with ChangeNotifier {
  List<Facility> _facilities = [];
  List<Facility> _filteredFacilities = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _typeFilter = '';
  String _statusFilter = '';
  Map<String, int> _statistics = {};
  final Map<String, Map<String, dynamic>> _facilityMetrics = {};
  final Map<String, List<Map<String, dynamic>>> _facilityActivities = {};
  final Map<String, List<Map<String, dynamic>>> _treatmentAdherenceData = {};

  // Getters
  List<Facility> get facilities => _filteredFacilities;
  List<Facility> get allFacilities => _facilities;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get typeFilter => _typeFilter;
  String get statusFilter => _statusFilter;
  Map<String, int> get statistics => _statistics;

  // Filter options
  static const List<String> typeFilterOptions = [
    'All Types',
    'Hospital',
    'Health Center',
    'Clinic',
  ];

  static const List<String> statusFilterOptions = [
    'All Status',
    'Active',
    'Inactive',
  ];

  // Load facilities with real-time updates
  void loadFacilities() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      FacilityService.getFacilitiesStream(
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        typeFilter: _getTypeFilterValue(),
        statusFilter: _getStatusFilterValue(),
      ).listen(
        (facilities) {
          _facilities = facilities;
          _applyFilters();
          _isLoading = false;
          _error = null;
          notifyListeners();
        },
        onError: (error) {
          _error = 'Failed to load facilities: $error';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Failed to load facilities: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load statistics
  Future<void> loadStatistics() async {
    try {
      _statistics = await FacilityService.getFacilityStatistics();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load facility statistics: $e');
      }
    }
  }

  // Search facilities
  void searchFacilities(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Filter by type
  void filterByType(String type) {
    _typeFilter = type;
    _applyFilters();
    notifyListeners();
  }

  // Filter by status
  void filterByStatus(String status) {
    _statusFilter = status;
    _applyFilters();
    notifyListeners();
  }

  // Apply all filters
  void _applyFilters() {
    _filteredFacilities = _facilities.where((facility) {
      // Search filter
      bool matchesSearch =
          _searchQuery.isEmpty ||
          facility.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          facility.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          facility.contactEmail.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      // Type filter
      bool matchesType =
          _typeFilter.isEmpty ||
          _typeFilter == 'All Types' ||
          facility.typeDisplayName == _typeFilter;

      // Status filter
      bool matchesStatus =
          _statusFilter.isEmpty ||
          _statusFilter == 'All Status' ||
          facility.statusDisplayName == _statusFilter;

      return matchesSearch && matchesType && matchesStatus;
    }).toList();
  }

  // Get filter value for service
  String? _getTypeFilterValue() {
    if (_typeFilter.isEmpty || _typeFilter == 'All Types') return null;
    switch (_typeFilter) {
      case 'Hospital':
        return 'hospital';
      case 'Health Center':
        return 'health_center';
      case 'Clinic':
        return 'clinic';
      default:
        return null;
    }
  }

  String? _getStatusFilterValue() {
    if (_statusFilter.isEmpty || _statusFilter == 'All Status') return null;
    switch (_statusFilter) {
      case 'Active':
        return 'active';
      case 'Inactive':
        return 'inactive';
      default:
        return null;
    }
  }

  // Create facility
  Future<void> createFacility(Facility facility) async {
    try {
      _error = null;
      notifyListeners();

      await FacilityService.createFacility(facility);

      // Reload statistics
      await loadStatistics();
    } catch (e) {
      _error = 'Failed to create facility: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Update facility
  Future<void> updateFacility(String id, Facility facility) async {
    try {
      _error = null;
      notifyListeners();

      await FacilityService.updateFacility(id, facility);

      // Reload statistics
      await loadStatistics();
    } catch (e) {
      _error = 'Failed to update facility: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Delete facility
  Future<void> deleteFacility(String id) async {
    try {
      _error = null;
      notifyListeners();

      await FacilityService.deleteFacility(id);

      // Reload statistics
      await loadStatistics();
    } catch (e) {
      _error = 'Failed to delete facility: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Delete multiple facilities
  Future<void> deleteFacilities(List<String> ids) async {
    try {
      _error = null;
      notifyListeners();

      await FacilityService.deleteFacilities(ids);

      // Reload statistics
      await loadStatistics();
    } catch (e) {
      _error = 'Failed to delete facilities: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Update facility status
  Future<void> updateFacilityStatus(String id, String status) async {
    try {
      _error = null;
      notifyListeners();

      await FacilityService.updateFacilityStatus(id, status);

      // Reload statistics
      await loadStatistics();
    } catch (e) {
      _error = 'Failed to update facility status: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Get facility by ID
  Future<Facility?> getFacilityById(String id) async {
    try {
      return await FacilityService.getFacilityById(id);
    } catch (e) {
      _error = 'Failed to get facility: $e';
      notifyListeners();
      return null;
    }
  }

  // Clear filters
  void clearFilters() {
    _searchQuery = '';
    _typeFilter = '';
    _statusFilter = '';
    _applyFilters();
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get facility dashboard metrics
  Future<Map<String, dynamic>> getFacilityMetrics(String facilityId) async {
    try {
      if (_facilityMetrics.containsKey(facilityId)) {
        return _facilityMetrics[facilityId]!;
      }

      final metrics = await FacilityService.getFacilityMetrics(facilityId);
      _facilityMetrics[facilityId] = metrics;
      return metrics;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get facility metrics: $e');
      }
      rethrow;
    }
  }

  // Get facility activities
  Future<List<Map<String, dynamic>>> getFacilityActivities(
    String facilityId,
  ) async {
    try {
      if (_facilityActivities.containsKey(facilityId)) {
        return _facilityActivities[facilityId]!;
      }

      final activities = await FacilityService.getFacilityActivities(
        facilityId,
      );
      _facilityActivities[facilityId] = activities;
      return activities;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get facility activities: $e');
      }
      rethrow;
    }
  }

  // Get treatment adherence data for charts
  Future<List<Map<String, dynamic>>> getTreatmentAdherenceData(
    String facilityId,
  ) async {
    try {
      if (_treatmentAdherenceData.containsKey(facilityId)) {
        return _treatmentAdherenceData[facilityId]!;
      }

      final adherenceData = await FacilityService.getTreatmentAdherenceData(
        facilityId,
      );
      _treatmentAdherenceData[facilityId] = adherenceData;
      return adherenceData;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get treatment adherence data: $e');
      }
      rethrow;
    }
  }

  // Clear cached facility data
  void clearFacilityCache(String facilityId) {
    _facilityMetrics.remove(facilityId);
    _facilityActivities.remove(facilityId);
    _treatmentAdherenceData.remove(facilityId);
    notifyListeners();
  }

  // Clear all cached facility data
  void clearAllFacilityCache() {
    _facilityMetrics.clear();
    _facilityActivities.clear();
    _treatmentAdherenceData.clear();
    notifyListeners();
  }

  // Helper methods for UI
  bool get hasActiveFilters {
    return _searchQuery.isNotEmpty ||
        (_typeFilter.isNotEmpty && _typeFilter != 'All Types') ||
        (_statusFilter.isNotEmpty && _statusFilter != 'All Status');
  }

  int get totalFacilitiesCount => _facilities.length;
  int get filteredFacilitiesCount => _filteredFacilities.length;

  String get filtersDescription {
    List<String> activeFilters = [];

    if (_searchQuery.isNotEmpty) {
      activeFilters.add('Search: "$_searchQuery"');
    }
    if (_typeFilter.isNotEmpty && _typeFilter != 'All Types') {
      activeFilters.add('Type: $_typeFilter');
    }
    if (_statusFilter.isNotEmpty && _statusFilter != 'All Status') {
      activeFilters.add('Status: $_statusFilter');
    }

    return activeFilters.join(', ');
  }
}
