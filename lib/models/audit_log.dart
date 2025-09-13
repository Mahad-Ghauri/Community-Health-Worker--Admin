import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLog {
  final String logId;
  final String action; // create, update, delete, login, logout, view, export, import
  final String entity; // user, facility, patient, visit, system
  final String entityId; // ID of the affected entity
  final String userId; // ID of user who performed action
  final String userName; // Name of user who performed action
  final String userRole; // Role of user who performed action
  final Map<String, dynamic>? oldData; // Previous state
  final Map<String, dynamic>? newData; // New state
  final String? description; // Optional description
  final DateTime timestamp;
  final String? ipAddress; // IP address of user
  final String? userAgent; // Browser/device info
  final Map<String, dynamic>? metadata; // Additional context

  AuditLog({
    required this.logId,
    required this.action,
    required this.entity,
    required this.entityId,
    required this.userId,
    required this.userName,
    required this.userRole,
    this.oldData,
    this.newData,
    this.description,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
    this.metadata,
  });

  // Convert AuditLog to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'action': action,
      'entity': entity,
      'entityId': entityId,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'oldData': oldData,
      'newData': newData,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'metadata': metadata,
    };
  }

  // Create AuditLog from Firestore document
  factory AuditLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLog(
      logId: doc.id,
      action: data['action'] ?? '',
      entity: data['entity'] ?? '',
      entityId: data['entityId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userRole: data['userRole'] ?? '',
      oldData: data['oldData']?.cast<String, dynamic>(),
      newData: data['newData']?.cast<String, dynamic>(),
      description: data['description'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ipAddress: data['ipAddress'],
      userAgent: data['userAgent'],
      metadata: data['metadata']?.cast<String, dynamic>(),
    );
  }

  // Create from Map
  factory AuditLog.fromMap(Map<String, dynamic> data, String id) {
    return AuditLog(
      logId: id,
      action: data['action'] ?? '',
      entity: data['entity'] ?? '',
      entityId: data['entityId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userRole: data['userRole'] ?? '',
      oldData: data['oldData']?.cast<String, dynamic>(),
      newData: data['newData']?.cast<String, dynamic>(),
      description: data['description'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ipAddress: data['ipAddress'],
      userAgent: data['userAgent'],
      metadata: data['metadata']?.cast<String, dynamic>(),
    );
  }

  // Copy with method for immutable updates
  AuditLog copyWith({
    String? logId,
    String? action,
    String? entity,
    String? entityId,
    String? userId,
    String? userName,
    String? userRole,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
    String? description,
    DateTime? timestamp,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? metadata,
  }) {
    return AuditLog(
      logId: logId ?? this.logId,
      action: action ?? this.action,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      oldData: oldData ?? this.oldData,
      newData: newData ?? this.newData,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      metadata: metadata ?? this.metadata,
    );
  }

  // Action constants
  static const String actionCreate = 'create';
  static const String actionUpdate = 'update';
  static const String actionDelete = 'delete';
  static const String actionLogin = 'login';
  static const String actionLogout = 'logout';
  static const String actionView = 'view';
  static const String actionExport = 'export';
  static const String actionImport = 'import';

  // Entity constants
  static const String entityUser = 'user';
  static const String entityFacility = 'facility';
  static const String entityPatient = 'patient';
  static const String entityVisit = 'visit';
  static const String entitySystem = 'system';

  // Display names
  String get actionDisplayName {
    switch (action) {
      case actionCreate:
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
      default:
        return action.toUpperCase();
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
        return entity.toUpperCase();
    }
  }

  // Helper getters
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
        return AuditLogSeverity.medium;
      case actionLogin:
      case actionLogout:
      case actionView:
        return AuditLogSeverity.low;
      default:
        return AuditLogSeverity.medium;
    }
  }

  // Time helpers
  String get formattedDate {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  String get formattedDateTime {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  // Check if action was performed today
  bool get isToday {
    final now = DateTime.now();
    return timestamp.year == now.year && 
           timestamp.month == now.month && 
           timestamp.day == now.day;
  }

  // Validation methods
  bool get isValid {
    return action.isNotEmpty && 
           entity.isNotEmpty && 
           entityId.isNotEmpty && 
           userId.isNotEmpty &&
           userName.isNotEmpty;
  }

  // Helper method to create audit log for common actions
  static AuditLog createLog({
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
    return AuditLog(
      logId: '', // Will be set by Firestore
      action: action,
      entity: entity,
      entityId: entityId,
      userId: userId,
      userName: userName,
      userRole: userRole,
      oldData: oldData,
      newData: newData,
      description: description,
      timestamp: DateTime.now(),
      ipAddress: ipAddress,
      userAgent: userAgent,
      metadata: metadata,
    );
  }

  @override
  String toString() {
    return 'AuditLog(logId: $logId, action: $action, entity: $entity, user: $userName, timestamp: $formattedDateTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuditLog && other.logId == logId;
  }

  @override
  int get hashCode => logId.hashCode;
}

// Helper class for data changes
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

// Action types helper class
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

// Entity types helper class
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