import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLog {
  final String logId;
  final String action; // 'registered_patient', 'home_visit', 'contact_screening', etc.
  final String who; // CHW ID
  final String what; // Patient ID, Visit ID, etc.
  final DateTime when;
  final Map<String, double>? where; // GPS location
  final Map<String, dynamic>? additionalData; // Extra context

  AuditLog({
    required this.logId,
    required this.action,
    required this.who,
    required this.what,
    required this.when,
    this.where,
    this.additionalData,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'logId': logId,
      'action': action,
      'who': who,
      'what': what,
      'when': Timestamp.fromDate(when),
      'where': where,
      'additionalData': additionalData,
    };
  }

  factory AuditLog.fromFirestore(Map<String, dynamic> data) {
    return AuditLog(
      logId: data['logId'] ?? '',
      action: data['action'] ?? '',
      who: data['who'] ?? '',
      what: data['what'] ?? '',
      when: (data['when'] as Timestamp?)?.toDate() ?? DateTime.now(),
      where: data['where'] != null ? _parseLocationMap(data['where']) : null,
      additionalData: data['additionalData'],
    );
  }

  // Helper method to safely parse location map handling both int and double types
  static Map<String, double>? _parseLocationMap(dynamic locationData) {
    if (locationData == null) return null;
    
    try {
      final Map<String, dynamic> rawMap = Map<String, dynamic>.from(locationData);
      final Map<String, double> result = {};
      
      rawMap.forEach((key, value) {
        if (value is num) {
          result[key] = value.toDouble();
        }
      });
      
      return result.isNotEmpty ? result : null;
    } catch (e) {
      // If parsing fails, return null to avoid crashes
      return null;
    }
  }

  // Create AuditLog from Firestore document (for backward compatibility)
  factory AuditLog.fromFirestoreDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLog.fromFirestore({
      ...data,
      'logId': doc.id,
    });
  }

  // Create from Map
  factory AuditLog.fromMap(Map<String, dynamic> data, String id) {
    return AuditLog.fromFirestore({
      ...data,
      'logId': id,
    });
  }

  // Copy with method for immutable updates
  AuditLog copyWith({
    String? logId,
    String? action,
    String? who,
    String? what,
    DateTime? when,
    Map<String, double>? where,
    Map<String, dynamic>? additionalData,
  }) {
    return AuditLog(
      logId: logId ?? this.logId,
      action: action ?? this.action,
      who: who ?? this.who,
      what: what ?? this.what,
      when: when ?? this.when,
      where: where ?? this.where,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  // Backward compatibility getters for existing code
  String get entity => additionalData?['entity'] ?? 'system';
  String get entityId => what;
  String get userId => who;
  String get userName => additionalData?['userName'] ?? _getUserNameFromId(who);
  String get userRole => additionalData?['userRole'] ?? 'CHW';
  DateTime get timestamp => when;
  String? get description => additionalData?['description'];
  String? get ipAddress => additionalData?['ipAddress'];
  String? get userAgent => additionalData?['userAgent'];
  Map<String, dynamic>? get metadata => additionalData;
  Map<String, dynamic>? get oldData => additionalData?['oldData'];
  Map<String, dynamic>? get newData => additionalData?['newData'];

  // Helper method to get user name from ID
  String _getUserNameFromId(String userId) {
    if (userId.isEmpty) return 'System';
    if (userId.startsWith('CHW')) return 'CHW User';
    if (userId.startsWith('STAFF')) return 'Staff User';
    if (userId.startsWith('ADMIN')) return 'Admin User';
    return 'User $userId';
  }

  // Action constants (for backward compatibility)
  static const String actionCreate = 'create';
  static const String actionUpdate = 'update';
  static const String actionDelete = 'delete';
  static const String actionLogin = 'login';
  static const String actionLogout = 'logout';
  static const String actionView = 'view';
  static const String actionExport = 'export';
  static const String actionImport = 'import';

  // Entity constants (for backward compatibility)
  static const String entityUser = 'user';
  static const String entityFacility = 'facility';
  static const String entityPatient = 'patient';
  static const String entityVisit = 'visit';
  static const String entitySystem = 'system';

  // Display names
  String get actionDisplayName {
    switch (action) {
      case actionCreate:
      case 'registered_patient':
        return 'Created';
      case actionUpdate:
        return 'Updated';
      case actionDelete:
        return 'Deleted';
      case actionLogin:
        return 'Logged In';
      case actionLogout:
        return 'Logged Out';
      case actionView:
        return 'Viewed';
      case actionExport:
        return 'Exported';
      case actionImport:
        return 'Imported';
      case 'home_visit':
        return 'Home Visit';
      case 'contact_screening':
        return 'Contact Screening';
      default:
        return action.replaceAll('_', ' ').toUpperCase();
    }
  }

  String get entityDisplayName {
    switch (entity) {
      case entityUser:
        return 'User';
      case entityFacility:
        return 'Facility';
      case entityPatient:
        return 'Patient';
      case entityVisit:
        return 'Visit';
      case entitySystem:
        return 'System';
      default:
        return entity.replaceAll('_', ' ').toUpperCase();
    }
  }

  // Helper getters
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(when);

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

  String get fullDescription {
    if (description != null && description!.isNotEmpty) {
      return description!;
    }
    
    return '$userName ($userRole) ${actionDisplayName.toLowerCase()} $entityDisplayName';
  }

  bool get hasDataChanges => oldData != null || newData != null;

  List<DataChange> get dataChanges {
    if (!hasDataChanges) return [];
    
    final changes = <DataChange>[];
    final oldKeys = oldData?.keys.toSet() ?? <String>{};
    final newKeys = newData?.keys.toSet() ?? <String>{};
    final allKeys = {...oldKeys, ...newKeys};

    for (final key in allKeys) {
      final oldValue = oldData?[key];
      final newValue = newData?[key];
      
      if (oldValue != newValue) {
        changes.add(DataChange(
          field: key,
          oldValue: oldValue,
          newValue: newValue,
        ));
      }
    }

    return changes;
  }

  // Severity level for UI display
  AuditLogSeverity get severity {
    switch (action) {
      case actionDelete:
        return AuditLogSeverity.high;
      case actionCreate:
      case actionUpdate:
      case 'registered_patient':
        return AuditLogSeverity.medium;
      case actionLogin:
      case actionLogout:
      case actionView:
      case 'home_visit':
      case 'contact_screening':
        return AuditLogSeverity.low;
      default:
        return AuditLogSeverity.medium;
    }
  }

  // Time helpers
  String get formattedDate {
    return '${when.day}/${when.month}/${when.year}';
  }

  String get formattedDateTime {
    return '${when.day}/${when.month}/${when.year} ${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
  }

  String get formattedTime {
    return '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
  }

  // Check if action was performed today
  bool get isToday {
    final now = DateTime.now();
    return when.year == now.year && 
           when.month == now.month && 
           when.day == now.day;
  }

  // Validation methods
  bool get isValid {
    return action.isNotEmpty && 
           who.isNotEmpty && 
           what.isNotEmpty;
  }

  // Helper method to create audit log for common actions
  static AuditLog createLog({
    required String action,
    required String who,
    required String what,
    Map<String, double>? where,
    Map<String, dynamic>? additionalData,
  }) {
    return AuditLog(
      logId: '', // Will be set by Firestore
      action: action,
      who: who,
      what: what,
      when: DateTime.now(),
      where: where,
      additionalData: additionalData,
    );
  }

  // Helper method for backward compatibility
  static AuditLog createLogLegacy({
    required String action,
    required String entity,
    required String entityId,
    required String userId,
    required String userName,
    required String userRole,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
    String? description,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? metadata,
  }) {
    final additionalData = <String, dynamic>{
      'entity': entity,
      'userName': userName,
      'userRole': userRole,
      if (oldData != null) 'oldData': oldData,
      if (newData != null) 'newData': newData,
      if (description != null) 'description': description,
      if (ipAddress != null) 'ipAddress': ipAddress,
      if (userAgent != null) 'userAgent': userAgent,
      if (metadata != null) ...metadata,
    };

    return AuditLog(
      logId: '', // Will be set by Firestore
      action: action,
      who: userId,
      what: entityId,
      when: DateTime.now(),
      additionalData: additionalData,
    );
  }

  @override
  String toString() {
    return 'AuditLog(logId: $logId, action: $action, who: $who, what: $what, when: $formattedDateTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuditLog && other.logId == logId;
  }

  @override
  int get hashCode => logId.hashCode;
}

// Helper class for data changes (for backward compatibility)
class DataChange {
  final String field;
  final dynamic oldValue;
  final dynamic newValue;

  DataChange({
    required this.field,
    this.oldValue,
    this.newValue,
  });

  String get fieldDisplayName {
    switch (field) {
      case 'name':
        return 'Name';
      case 'email':
        return 'Email';
      case 'phone':
        return 'Phone';
      case 'role':
        return 'Role';
      case 'status':
        return 'Status';
      case 'address':
        return 'Address';
      case 'type':
        return 'Type';
      case 'isActive':
        return 'Active Status';
      default:
        return field.replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(1)}',
        ).trim();
    }
  }

  String get changeDescription {
    if (oldValue == null && newValue != null) {
      return 'Set to: $newValue';
    } else if (oldValue != null && newValue == null) {
      return 'Removed: $oldValue';
    } else {
      return 'Changed from: $oldValue to: $newValue';
    }
  }
}

// Severity levels for audit logs
enum AuditLogSeverity {
  low,
  medium,
  high,
}

// Action types helper class (for backward compatibility)
class AuditLogActions {
  static const String create = AuditLog.actionCreate;
  static const String update = AuditLog.actionUpdate;
  static const String delete = AuditLog.actionDelete;
  static const String login = AuditLog.actionLogin;
  static const String logout = AuditLog.actionLogout;
  static const String view = AuditLog.actionView;
  static const String export = AuditLog.actionExport;
  static const String import = AuditLog.actionImport;
  
  static const List<String> all = [
    create,
    update,
    delete,
    login,
    logout,
    view,
    export,
    import,
  ];
}

// Entity types helper class (for backward compatibility)
class AuditLogEntities {
  static const String user = AuditLog.entityUser;
  static const String facility = AuditLog.entityFacility;
  static const String patient = AuditLog.entityPatient;
  static const String visit = AuditLog.entityVisit;
  static const String system = AuditLog.entitySystem;
  
  static const List<String> all = [
    user,
    facility,
    patient,
    visit,
    system,
  ];
}