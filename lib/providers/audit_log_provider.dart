import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/audit_log.dart';
import '../services/audit_log_service.dart';
import '../utils/export_utils.dart';

class AuditLogProvider with ChangeNotifier {
  List<AuditLog> _auditLogs = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  String? _error;
  DocumentSnapshot? _lastDocument;
  Map<String, dynamic> _statistics = {};

  // Filters
  String _actionFilter = '';
  String _entityFilter = '';
  String _userFilter = '';
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';

  // Getters
  List<AuditLog> get auditLogs => _auditLogs;
  bool get isLoading => _isLoading;
  bool get hasMoreData => _hasMoreData;
  String? get error => _error;
  Map<String, dynamic> get statistics => _statistics;

  // Filter getters
  String get actionFilter => _actionFilter;
  String get entityFilter => _entityFilter;
  String get userFilter => _userFilter;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String get searchQuery => _searchQuery;

  // Helper getters
  bool get hasActiveFilters =>
      _actionFilter.isNotEmpty ||
      _entityFilter.isNotEmpty ||
      _userFilter.isNotEmpty ||
      _startDate != null ||
      _endDate != null ||
      _searchQuery.isNotEmpty;

  String get filtersDescription {
    final filters = <String>[];
    
    if (_actionFilter.isNotEmpty) {
      filters.add('Action: $_actionFilter');
    }
    if (_entityFilter.isNotEmpty) {
      filters.add('Entity: $_entityFilter');
    }
    if (_userFilter.isNotEmpty) {
      filters.add('User: $_userFilter');
    }
    if (_startDate != null || _endDate != null) {
      if (_startDate != null && _endDate != null) {
        filters.add('Date: ${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}');
      } else if (_startDate != null) {
        filters.add('From: ${_formatDate(_startDate!)}');
      } else if (_endDate != null) {
        filters.add('Until: ${_formatDate(_endDate!)}');
      }
    }
    if (_searchQuery.isNotEmpty) {
      filters.add('Search: "$_searchQuery"');
    }

    return filters.join(', ');
  }

  // Load audit logs
  Future<void> loadAuditLogs({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    if (refresh) {
      _auditLogs.clear();
      _lastDocument = null;
      _hasMoreData = true;
      _error = null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      List<AuditLog> logs;

      if (_searchQuery.isNotEmpty) {
        logs = await AuditLogService.searchAuditLogs(
          searchText: _searchQuery,
          limit: 50,
          startAfter: _lastDocument,
        );
      } else {
        logs = await AuditLogService.getAuditLogs(
          limit: 50,
          startAfter: _lastDocument,
          actionFilter: _actionFilter.isEmpty ? null : _actionFilter,
          entityFilter: _entityFilter.isEmpty ? null : _entityFilter,
          userFilter: _userFilter.isEmpty ? null : _userFilter,
          startDate: _startDate,
          endDate: _endDate,
        );
      }

      if (logs.isNotEmpty) {
        if (refresh) {
          _auditLogs = logs;
        } else {
          _auditLogs.addAll(logs);
        }
        // Note: Since we're getting logs from Firestore, we'd need to store the last document
        // for pagination. This is a simplified version.
        _hasMoreData = logs.length == 50;
      } else {
        _hasMoreData = false;
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to load audit logs: $e';
      if (kDebugMode) {
        print('AuditLogProvider error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more audit logs (pagination)
  Future<void> loadMoreAuditLogs() async {
    if (!_hasMoreData || _isLoading) return;
    
    await loadAuditLogs(refresh: false);
  }

  // Load statistics
  Future<void> loadStatistics() async {
    try {
      _statistics = await AuditLogService.getAuditLogStatistics(
        startDate: _startDate,
        endDate: _endDate,
      );
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load audit log statistics: $e');
      }
    }
  }

  // Search audit logs
  void searchAuditLogs(String query) {
    _searchQuery = query;
    loadAuditLogs(refresh: true);
  }

  // Filter by action
  void filterByAction(String action) {
    _actionFilter = action == 'All Actions' ? '' : action;
    loadAuditLogs(refresh: true);
  }

  // Filter by entity
  void filterByEntity(String entity) {
    _entityFilter = entity == 'All Entities' ? '' : entity;
    loadAuditLogs(refresh: true);
  }

  // Filter by user
  void filterByUser(String user) {
    _userFilter = user == 'All Users' ? '' : user;
    loadAuditLogs(refresh: true);
  }

  // Filter by date range
  void filterByDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    loadAuditLogs(refresh: true);
    loadStatistics();
  }

  // Clear all filters
  void clearFilters() {
    _actionFilter = '';
    _entityFilter = '';
    _userFilter = '';
    _startDate = null;
    _endDate = null;
    _searchQuery = '';
    loadAuditLogs(refresh: true);
    loadStatistics();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get audit logs for specific entity
  Future<List<AuditLog>> getEntityAuditLogs({
    required String entityId,
    required String entity,
  }) async {
    try {
      return await AuditLogService.getEntityAuditLogs(
        entityId: entityId,
        entity: entity,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get entity audit logs: $e');
      }
      return [];
    }
  }

  // Get audit logs for specific user
  Future<List<AuditLog>> getUserAuditLogs({required String userId}) async {
    try {
      return await AuditLogService.getUserAuditLogs(userId: userId);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get user audit logs: $e');
      }
      return [];
    }
  }

  // Export audit logs to CSV
  Future<String> exportAuditLogs() async {
    try {
      return ExportUtils.generateAuditLogsCsv(_auditLogs);
    } catch (e) {
      throw Exception('Failed to export audit logs: $e');
    }
  }

  // Export audit logs (legacy method - returns data for export)
  Future<List<Map<String, dynamic>>> exportAuditLogsData() async {
    try {
      final exportData = <Map<String, dynamic>>[];
      
      for (final log in _auditLogs) {
        exportData.add({
          'Date/Time': log.formattedDateTime,
          'Action': log.actionDisplayName,
          'Entity': log.entityDisplayName,
          'User': log.userName,
          'Role': log.userRole,
          'Description': log.fullDescription,
          'IP Address': log.ipAddress ?? 'N/A',
        });
      }

      return exportData;
    } catch (e) {
      throw Exception('Failed to export audit logs: $e');
    }
  }

  // Refresh data
  Future<void> refresh() async {
    await Future.wait([
      loadAuditLogs(refresh: true),
      loadStatistics(),
    ]);
  }

  // Format date helper
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Get filter options
  static const List<String> actionFilterOptions = [
    'All Actions',
    'Created',
    'Updated',
    'Deleted',
    'Logged In',
    'Logged Out',
    'Viewed',
    'Exported',
    'Imported',
  ];

  static const List<String> entityFilterOptions = [
    'All Entities',
    'User',
    'Facility',
    'Patient',
    'Visit',
    'System',
  ];

  // Helper methods for UI
  List<AuditLog> get recentLogs => _auditLogs.take(10).toList();

  List<AuditLog> get highSeverityLogs =>
      _auditLogs.where((log) => log.severity == AuditLogSeverity.high).toList();

  List<AuditLog> get todaysLogs =>
      _auditLogs.where((log) => log.isToday).toList();

  Map<String, int> get actionCounts {
    final counts = <String, int>{};
    for (final log in _auditLogs) {
      counts[log.actionDisplayName] = (counts[log.actionDisplayName] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> get entityCounts {
    final counts = <String, int>{};
    for (final log in _auditLogs) {
      counts[log.entityDisplayName] = (counts[log.entityDisplayName] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> get userCounts {
    final counts = <String, int>{};
    for (final log in _auditLogs) {
      counts[log.userName] = (counts[log.userName] ?? 0) + 1;
    }
    return counts;
  }

  // Get activity summary for dashboard
  Map<String, dynamic> get activitySummary {
    return {
      'totalLogs': _auditLogs.length,
      'todayLogs': todaysLogs.length,
      'highSeverityLogs': highSeverityLogs.length,
      'uniqueUsers': userCounts.keys.length,
      'mostActiveUser': userCounts.isNotEmpty 
          ? userCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : 'N/A',
      'mostCommonAction': actionCounts.isNotEmpty
          ? actionCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : 'N/A',
    };
  }
}