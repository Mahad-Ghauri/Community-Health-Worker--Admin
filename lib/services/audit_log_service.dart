import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/audit_log.dart';
import '../constants/app_constants.dart';

class AuditLogService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _auditLogsCollection = 
      _firestore.collection(AppConstants.auditLogsCollection);

  // Create audit log entry
  static Future<void> createAuditLog(AuditLog auditLog) async {
    try {
      await _auditLogsCollection.add(auditLog.toFirestore());
    } catch (e) {
      throw Exception('Failed to create audit log: $e');
    }
  }

  // Get audit logs with pagination
  static Future<List<AuditLog>> getAuditLogs({
    int limit = 50,
    DocumentSnapshot? startAfter,
    String? actionFilter,
    String? entityFilter,
    String? userFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _auditLogsCollection.orderBy('timestamp', descending: true);

      // Apply filters
      if (actionFilter != null && actionFilter.isNotEmpty) {
        query = query.where('action', isEqualTo: actionFilter);
      }

      if (entityFilter != null && entityFilter.isNotEmpty) {
        query = query.where('entity', isEqualTo: entityFilter);
      }

      if (userFilter != null && userFilter.isNotEmpty) {
        query = query.where('userId', isEqualTo: userFilter);
      }

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final QuerySnapshot snapshot = await query.get();
      return snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get audit logs: $e');
    }
  }

  // Search audit logs by text
  static Future<List<AuditLog>> searchAuditLogs({
    required String searchText,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      // For simple text search, we'll search in description and userName fields
      // In a production app, you might want to use Algolia or similar for better search
      
      final queries = <Future<QuerySnapshot>>[];
      
      // Search in description
      queries.add(
        _auditLogsCollection
            .where('description', isGreaterThanOrEqualTo: searchText)
            .where('description', isLessThan: '${searchText}z')
            .orderBy('description')
            .orderBy('timestamp', descending: true)
            .limit(limit ~/ 2)
            .get()
      );

      // Search in userName
      queries.add(
        _auditLogsCollection
            .where('userName', isGreaterThanOrEqualTo: searchText)
            .where('userName', isLessThan: '${searchText}z')
            .orderBy('userName')
            .orderBy('timestamp', descending: true)
            .limit(limit ~/ 2)
            .get()
      );

      final results = await Future.wait(queries);
      final logs = <AuditLog>[];
      final seenIds = <String>{};

      for (final snapshot in results) {
        for (final doc in snapshot.docs) {
          if (!seenIds.contains(doc.id)) {
            logs.add(AuditLog.fromFirestore(doc));
            seenIds.add(doc.id);
          }
        }
      }

      // Sort by timestamp descending
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return logs.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to search audit logs: $e');
    }
  }

  // Get audit logs for specific entity
  static Future<List<AuditLog>> getEntityAuditLogs({
    required String entityId,
    required String entity,
    int limit = 20,
  }) async {
    try {
      final QuerySnapshot snapshot = await _auditLogsCollection
          .where('entityId', isEqualTo: entityId)
          .where('entity', isEqualTo: entity)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get entity audit logs: $e');
    }
  }

  // Get audit logs for specific user
  static Future<List<AuditLog>> getUserAuditLogs({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final QuerySnapshot snapshot = await _auditLogsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get user audit logs: $e');
    }
  }

  // Get audit log statistics
  static Future<Map<String, dynamic>> getAuditLogStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _auditLogsCollection;

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final QuerySnapshot snapshot = await query.get();
      final logs = snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList();

      final stats = <String, dynamic>{
        'totalLogs': logs.length,
        'actionBreakdown': <String, int>{},
        'entityBreakdown': <String, int>{},
        'userBreakdown': <String, int>{},
        'severityBreakdown': <String, int>{
          'low': 0,
          'medium': 0,
          'high': 0,
        },
        'dailyActivity': <String, int>{},
      };

      for (final log in logs) {
        // Action breakdown
        stats['actionBreakdown'][log.action] = 
            (stats['actionBreakdown'][log.action] ?? 0) + 1;

        // Entity breakdown
        stats['entityBreakdown'][log.entity] = 
            (stats['entityBreakdown'][log.entity] ?? 0) + 1;

        // User breakdown
        stats['userBreakdown'][log.userName] = 
            (stats['userBreakdown'][log.userName] ?? 0) + 1;

        // Severity breakdown
        final severity = log.severity.name;
        stats['severityBreakdown'][severity] = 
            (stats['severityBreakdown'][severity] ?? 0) + 1;

        // Daily activity
        final dateKey = '${log.timestamp.year}-${log.timestamp.month.toString().padLeft(2, '0')}-${log.timestamp.day.toString().padLeft(2, '0')}';
        stats['dailyActivity'][dateKey] = 
            (stats['dailyActivity'][dateKey] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get audit log statistics: $e');
    }
  }

  // Delete old audit logs (for maintenance)
  static Future<void> deleteOldAuditLogs({required int daysToKeep}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final QuerySnapshot snapshot = await _auditLogsCollection
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete old audit logs: $e');
    }
  }

  // Get real-time audit logs stream
  static Stream<List<AuditLog>> getAuditLogsStream({
    int limit = 20,
    String? actionFilter,
    String? entityFilter,
  }) {
    Query query = _auditLogsCollection.orderBy('timestamp', descending: true);

    if (actionFilter != null && actionFilter.isNotEmpty) {
      query = query.where('action', isEqualTo: actionFilter);
    }

    if (entityFilter != null && entityFilter.isNotEmpty) {
      query = query.where('entity', isEqualTo: entityFilter);
    }

    query = query.limit(limit);

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList());
  }

  // Helper methods to create common audit logs
  static Future<void> logUserAction({
    required String action,
    required String entityId,
    required String userId,
    required String userName,
    required String userRole,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
    String? description,
  }) async {
    final auditLog = AuditLog.createLog(
      action: action,
      entity: AuditLog.entityUser,
      entityId: entityId,
      userId: userId,
      userName: userName,
      userRole: userRole,
      oldData: oldData,
      newData: newData,
      description: description,
    );

    await createAuditLog(auditLog);
  }

  static Future<void> logFacilityAction({
    required String action,
    required String entityId,
    required String userId,
    required String userName,
    required String userRole,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
    String? description,
  }) async {
    final auditLog = AuditLog.createLog(
      action: action,
      entity: AuditLog.entityFacility,
      entityId: entityId,
      userId: userId,
      userName: userName,
      userRole: userRole,
      oldData: oldData,
      newData: newData,
      description: description,
    );

    await createAuditLog(auditLog);
  }

  static Future<void> logSystemAction({
    required String action,
    required String userId,
    required String userName,
    required String userRole,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    final auditLog = AuditLog.createLog(
      action: action,
      entity: AuditLog.entitySystem,
      entityId: 'system',
      userId: userId,
      userName: userName,
      userRole: userRole,
      description: description,
      metadata: metadata,
    );

    await createAuditLog(auditLog);
  }

  static Future<void> logLoginAction({
    required String userId,
    required String userName,
    required String userRole,
    String? ipAddress,
    String? userAgent,
  }) async {
    final auditLog = AuditLog.createLog(
      action: AuditLog.actionLogin,
      entity: AuditLog.entitySystem,
      entityId: 'system',
      userId: userId,
      userName: userName,
      userRole: userRole,
      description: 'User logged in to the system',
      ipAddress: ipAddress,
      userAgent: userAgent,
    );

    await createAuditLog(auditLog);
  }

  static Future<void> logLogoutAction({
    required String userId,
    required String userName,
    required String userRole,
  }) async {
    final auditLog = AuditLog.createLog(
      action: AuditLog.actionLogout,
      entity: AuditLog.entitySystem,
      entityId: 'system',
      userId: userId,
      userName: userName,
      userRole: userRole,
      description: 'User logged out of the system',
    );

    await createAuditLog(auditLog);
  }
}