import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assignment.dart';
import '../models/patient.dart';
import '../models/chw_user.dart';
import '../models/audit_log.dart';
import '../services/audit_log_service.dart';
import '../constants/app_constants.dart';

class AssignmentProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Assignment> _assignments = [];
  List<Patient> _availablePatients = [];
  List<CHWUser> _availableCHWs = [];
  Assignment? _selectedAssignment;
  bool _isLoading = false;
  String? _error;
  Map<String, int> _statistics = {};

  // Filter properties
  String? _selectedCHW;
  String? _selectedStatus;
  String? _selectedPriority;
  String _searchTerm = '';
  String? _facilityId;

  // Getters
  List<Assignment> get assignments => _assignments;
  List<Patient> get availablePatients => _availablePatients;
  List<CHWUser> get availableCHWs => _availableCHWs;
  Assignment? get selectedAssignment => _selectedAssignment;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, int> get statistics => _statistics;

  // Filter getters
  String? get selectedCHW => _selectedCHW;
  String? get selectedStatus => _selectedStatus;
  String? get selectedPriority => _selectedPriority;
  String get searchTerm => _searchTerm;

  // Filtered assignments
  List<Assignment> get filteredAssignments {
    var filtered = _assignments;

    // Filter by facility if set
    if (_facilityId != null) {
      filtered = filtered
          .where((assignment) => assignment.facilityId == _facilityId)
          .toList();
    }

    // Filter by CHW
    if (_selectedCHW != null && _selectedCHW!.isNotEmpty) {
      filtered = filtered
          .where((assignment) => assignment.chwId == _selectedCHW)
          .toList();
    }

    // Filter by status
    if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
      filtered = filtered
          .where((assignment) => assignment.status == _selectedStatus)
          .toList();
    }

    // Filter by priority
    if (_selectedPriority != null && _selectedPriority!.isNotEmpty) {
      filtered = filtered
          .where((assignment) => assignment.priority == _selectedPriority)
          .toList();
    }

    // Search filter
    if (_searchTerm.isNotEmpty) {
      final searchLower = _searchTerm.toLowerCase();
      filtered = filtered
          .where(
            (assignment) =>
                assignment.workArea.toLowerCase().contains(searchLower) ||
                assignment.notes?.toLowerCase().contains(searchLower) == true,
          )
          .toList();
    }

    return filtered;
  }

  // Set facility context
  void setFacilityId(String facilityId) {
    _facilityId = facilityId;
    notifyListeners();
  }

  // Load assignments for facility
  Future<void> loadAssignments() async {
    if (_facilityId == null) return;

    _setLoading(true);
    _setError(null);

    try {
      // Listen to assignments stream
      _firestore
          .collection('assignments')
          .where('facilityId', isEqualTo: _facilityId)
          .orderBy('assignedDate', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              _assignments = snapshot.docs
                  .map((doc) => Assignment.fromFirestore(doc))
                  .toList();
              _setLoading(false);
              notifyListeners();
            },
            onError: (error) {
              _setError('Failed to load assignments: $error');
              _setLoading(false);
            },
          );
    } catch (e) {
      _setError('Failed to load assignments: $e');
      _setLoading(false);
    }
  }

  // Load available patients (not yet assigned or assigned to this facility)
  Future<void> loadAvailablePatients() async {
    if (_facilityId == null) return;

    try {
      final snapshot = await _firestore
          .collection('patients')
          .where('assignedFacility', whereIn: [_facilityId, null])
          .get();

      _availablePatients = snapshot.docs
          .map((doc) => Patient.fromFirestore(doc))
          .toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load available patients: $e');
    }
  }

  // Load available CHWs for the facility
  Future<void> loadAvailableCHWs() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: AppConstants.chwRole)
          .where('status', isEqualTo: AppConstants.activeStatus)
          .get();

      _availableCHWs = snapshot.docs
          .map((doc) => CHWUser.fromFirestore(doc))
          .toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load available CHWs: $e');
    }
  }

  // Create new assignment
  Future<String?> createAssignment({
    required String chwId,
    required List<String> patientIds,
    required String assignedBy,
    required String workArea,
    String priority = Assignment.priorityMedium,
    String? notes,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      // Determine effective facilityId: prefer provider context, fallback to patient's facility
      String? effectiveFacilityId = _facilityId;
      if (effectiveFacilityId == null || effectiveFacilityId.isEmpty) {
        try {
          if (patientIds.isNotEmpty) {
            final firstPatientId = patientIds.first;
            final pDoc = await _firestore
                .collection(AppConstants.patientsCollection)
                .doc(firstPatientId)
                .get();
            if (pDoc.exists) {
              final pdata = pDoc.data() as Map<String, dynamic>;
              effectiveFacilityId = (pdata['assignedFacility'] as String?)
                  ?.trim();
              effectiveFacilityId =
                  (effectiveFacilityId == null || effectiveFacilityId.isEmpty)
                  ? (pdata['treatmentFacility'] as String?)?.trim()
                  : effectiveFacilityId;
            }
          }
        } catch (_) {}
      }

      if (effectiveFacilityId == null || effectiveFacilityId.isEmpty) {
        _setError('Facility context missing for assignment');
        _setLoading(false);
        return null;
      }

      // Create assignment
      final assignment = Assignment.createNew(
        chwId: chwId,
        patientIds: patientIds,
        assignedBy: assignedBy,
        facilityId: effectiveFacilityId,
        workArea: workArea,
        priority: priority,
        notes: notes,
      );

      final docRef = await _firestore
          .collection('assignments')
          .add(assignment.toFirestore());

      // Update patients with assignment info
      final batch = _firestore.batch();
      for (final patientId in patientIds) {
        final patientRef = _firestore.collection('patients').doc(patientId);
        batch.update(patientRef, {
          'assignedCHW': chwId,
          'assignedFacility': effectiveFacilityId,
        });
      }
      await batch.commit();

      // Create notification for CHW with patient name in title if available
      String notifTitle = 'New Patient Assignment';
      try {
        if (patientIds.isNotEmpty) {
          final pDoc = await _firestore
              .collection(AppConstants.patientsCollection)
              .doc(patientIds.first)
              .get();
          if (pDoc.exists) {
            final pdata = pDoc.data() as Map<String, dynamic>;
            final pname = (pdata['name'] as String?)?.trim();
            if (pname != null && pname.isNotEmpty) {
              notifTitle = 'Assigned: $pname';
            }
          }
        }
      } catch (_) {}

      await _createCHWNotification(
        chwId: chwId,
        type: 'new_assignment',
        title: notifTitle,
        message: 'You have been assigned ${patientIds.length} new patient(s)',
        relatedId: docRef.id,
      );

      // Audit log
      try {
        final auditLog = AuditLog.createLogLegacy(
          action: AuditLog.actionCreate,
          entity: AuditLog.entityPatient,
          entityId: patientIds.join(','),
          userId: assignedBy,
          userName: 'system',
          userRole: UserRoles.staff,
          description:
              'Assigned ${patientIds.length} patient(s) to CHW $chwId with priority $priority',
          metadata: {
            'assignmentId': docRef.id,
            'chwId': chwId,
            'facilityId': _facilityId,
            'workArea': workArea,
            'notes': notes,
          },
        );
        await AuditLogService.createAuditLog(auditLog);
      } catch (_) {}

      _setLoading(false);
      await loadStatistics();
      notifyListeners();
      return docRef.id;
    } catch (e) {
      _setError('Failed to create assignment: $e');
      _setLoading(false);
      return null;
    }
  }

  // Update assignment
  Future<bool> updateAssignment(
    String assignmentId,
    Map<String, dynamic> data,
  ) async {
    _setLoading(true);
    _setError(null);

    try {
      await _firestore.collection('assignments').doc(assignmentId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update assignment: $e');
      _setLoading(false);
      return false;
    }
  }

  // Generate next Patient ID like TB001, TB002 using a transaction on counters/patients
  Future<String> generateNextPatientId() async {
    final counterRef = _firestore.collection('counters').doc('patients');
    return _firestore.runTransaction((txn) async {
      final snap = await txn.get(counterRef);
      int next = 1;
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        next = (data['next'] as int? ?? 1);
      }
      txn.set(counterRef, {'next': next + 1}, SetOptions(merge: true));
      final id = 'TB${next.toString().padLeft(3, '0')}';
      return id;
    });
  }

  // Check duplicate phone by normalized phone field (fallback to raw phone)
  Future<bool> phoneExists(String phone) async {
    try {
      final q1 = await _firestore
          .collection(AppConstants.patientsCollection)
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (q1.docs.isNotEmpty) return true;
      final normalized = _normalizePhone(phone);
      final q2 = await _firestore
          .collection(AppConstants.patientsCollection)
          .where('phoneNormalized', isEqualTo: normalized)
          .limit(1)
          .get();
      return q2.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Create a new patient record
  Future<String?> createPatient({
    required String name,
    required int age,
    required String phone,
    required String address,
    required String gender,
    required String tbStatus,
    DateTime? diagnosisDate,
    required String createdBy,
    String? treatmentFacility,
    Map<String, double>? gpsLocation,
  }) async {
    if (_facilityId == null) return null;
    try {
      final id = await generateNextPatientId();
      final docRef = _firestore
          .collection(AppConstants.patientsCollection)
          .doc(id);
      final now = FieldValue.serverTimestamp();
      await docRef.set({
        'patientId': id,
        'name': name,
        'nameLower': name.toLowerCase(),
        'age': age,
        'phone': phone,
        'phoneNormalized': _normalizePhone(phone),
        'address': address,
        'gender': gender,
        'tbStatus': tbStatus,
        'assignedCHW': '',
        'assignedFacility': _facilityId,
        'treatmentFacility': treatmentFacility ?? _facilityId,
        'gpsLocation': gpsLocation ?? <String, double>{},
        'consent': true,
        'createdBy': createdBy,
        'validatedBy': null,
        'createdAt': now,
        'diagnosisDate': diagnosisDate != null
            ? Timestamp.fromDate(diagnosisDate)
            : null,
      });
      return id;
    } catch (e) {
      _setError('Failed to create patient: $e');
      return null;
    }
  }

  // Simple search: by id exact, by phone exact, or by name contains (client-side)
  Future<List<Patient>> searchPatients(String query) async {
    if (query.trim().isEmpty) return [];
    final q = query.trim();
    try {
      // Try id exact
      final idDoc = await _firestore
          .collection(AppConstants.patientsCollection)
          .doc(q)
          .get();
      if (idDoc.exists) {
        return [Patient.fromFirestore(idDoc)];
      }

      // Try phone exact
      final phoneSnap = await _firestore
          .collection(AppConstants.patientsCollection)
          .where('phone', isEqualTo: q)
          .limit(10)
          .get();
      if (phoneSnap.docs.isNotEmpty) {
        return phoneSnap.docs.map((d) => Patient.fromFirestore(d)).toList();
      }

      // Fallback: fetch a page and filter by name/address contains
      final col = _firestore.collection(AppConstants.patientsCollection);
      Query baseQuery;
      if (_facilityId != null && _facilityId!.isNotEmpty) {
        baseQuery = col.where('assignedFacility', isEqualTo: _facilityId);
      } else {
        baseQuery = col; // No facility filter when facility context unknown
      }
      final snap = await baseQuery
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();
      final lower = q.toLowerCase();
      return snap.docs
          .map((d) => Patient.fromFirestore(d))
          .where(
            (p) =>
                p.name.toLowerCase().contains(lower) ||
                p.address.toLowerCase().contains(lower),
          )
          .toList();
    } catch (e) {
      _setError('Failed to search patients: $e');
      return [];
    }
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  // Complete assignment
  Future<bool> completeAssignment(
    String assignmentId,
    String completedBy,
  ) async {
    _setLoading(true);
    _setError(null);

    try {
      await _firestore.collection('assignments').doc(assignmentId).update({
        'status': Assignment.statusCompleted,
        'completedDate': FieldValue.serverTimestamp(),
        'completedBy': completedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _setLoading(false);
      await loadStatistics();
      return true;
    } catch (e) {
      _setError('Failed to complete assignment: $e');
      _setLoading(false);
      return false;
    }
  }

  // Cancel assignment
  Future<bool> cancelAssignment(String assignmentId) async {
    _setLoading(true);
    _setError(null);

    try {
      final assignment = _assignments.firstWhere(
        (a) => a.assignmentId == assignmentId,
      );

      // Update assignment status
      await _firestore.collection('assignments').doc(assignmentId).update({
        'status': Assignment.statusCancelled,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Unassign patients
      final batch = _firestore.batch();
      for (final patientId in assignment.patientIds) {
        final patientRef = _firestore.collection('patients').doc(patientId);
        batch.update(patientRef, {
          'assignedCHW': null,
          'assignedFacility': null,
        });
      }
      await batch.commit();

      _setLoading(false);
      await loadStatistics();
      return true;
    } catch (e) {
      _setError('Failed to cancel assignment: $e');
      _setLoading(false);
      return false;
    }
  }

  // Load assignment by ID
  Future<void> loadAssignmentById(String assignmentId) async {
    _setLoading(true);
    _setError(null);

    try {
      final doc = await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .get();

      if (doc.exists) {
        _selectedAssignment = Assignment.fromFirestore(doc);
      } else {
        _setError('Assignment not found');
      }

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load assignment: $e');
      _setLoading(false);
    }
  }

  // Load statistics
  Future<void> loadStatistics() async {
    if (_facilityId == null) return;

    try {
      final snapshot = await _firestore
          .collection('assignments')
          .where('facilityId', isEqualTo: _facilityId)
          .get();

      final assignments = snapshot.docs
          .map((doc) => Assignment.fromFirestore(doc))
          .toList();

      _statistics = {
        'total': assignments.length,
        'active': assignments.where((a) => a.isActive).length,
        'completed': assignments.where((a) => a.isCompleted).length,
        'cancelled': assignments.where((a) => a.isCancelled).length,
        'overdue': assignments.where((a) => a.isOverdue).length,
        'highPriority': assignments
            .where((a) => a.isHighPriority || a.isUrgentPriority)
            .length,
      };

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load assignment statistics: $e');
      }
    }
  }

  // Search assignments
  void searchAssignments(String searchTerm) {
    _searchTerm = searchTerm;
    notifyListeners();
  }

  // Filter by CHW
  void filterByCHW(String? chwId) {
    _selectedCHW = chwId;
    notifyListeners();
  }

  // Filter by status
  void filterByStatus(String? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  // Filter by priority
  void filterByPriority(String? priority) {
    _selectedPriority = priority;
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _selectedCHW = null;
    _selectedStatus = null;
    _selectedPriority = null;
    _searchTerm = '';
    notifyListeners();
  }

  // Select assignment
  void selectAssignment(Assignment assignment) {
    _selectedAssignment = assignment;
    notifyListeners();
  }

  // Clear selected assignment
  void clearSelectedAssignment() {
    _selectedAssignment = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get assignments by CHW
  List<Assignment> getAssignmentsByCHW(String chwId) {
    return _assignments
        .where((assignment) => assignment.chwId == chwId)
        .toList();
  }

  // Get patient count for CHW
  int getPatientCountForCHW(String chwId) {
    return getAssignmentsByCHW(chwId)
        .where((assignment) => assignment.isActive)
        .fold(0, (total, assignment) => total + assignment.patientCount);
  }

  // Check if CHW has capacity for more patients
  bool chwHasCapacity(String chwId, {int maxPatients = 20}) {
    return getPatientCountForCHW(chwId) < maxPatients;
  }

  // Create CHW notification helper
  Future<void> _createCHWNotification({
    required String chwId,
    required String type,
    required String title,
    required String message,
    String? relatedId,
    String priority = 'medium',
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': chwId,
        'type': type,
        'title': title,
        'message': message,
        'relatedId': relatedId,
        'priority': priority,
        'status': 'unread',
        'sentAt': FieldValue.serverTimestamp(),
        'isSystemNotification': false,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Failed to create CHW notification: $e');
      }
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Helper getters for UI
  bool get hasActiveFilters {
    return _selectedCHW != null ||
        _selectedStatus != null ||
        _selectedPriority != null ||
        _searchTerm.isNotEmpty;
  }

  int get totalAssignmentsCount => _assignments.length;
  int get filteredAssignmentsCount => filteredAssignments.length;

  String get filtersDescription {
    final filters = <String>[];

    if (_searchTerm.isNotEmpty) {
      filters.add('Search: "$_searchTerm"');
    }
    if (_selectedCHW != null) {
      final chw = _availableCHWs.firstWhere(
        (c) => c.userId == _selectedCHW,
        orElse: () => CHWUser(
          userId: '',
          name: 'Unknown',
          email: '',
          phone: '',
          workingArea: '',
          idNumber: '',
          createdAt: DateTime.now(),
        ),
      );
      filters.add('CHW: ${chw.name}');
    }
    if (_selectedStatus != null) {
      filters.add('Status: $_selectedStatus');
    }
    if (_selectedPriority != null) {
      filters.add('Priority: $_selectedPriority');
    }

    return filters.join(', ');
  }

  // Get recent assignments
  List<Assignment> get recentAssignments => _assignments.take(10).toList();

  // Get overdue assignments
  List<Assignment> get overdueAssignments =>
      _assignments.where((a) => a.isOverdue).toList();

  // Get high priority assignments
  List<Assignment> get highPriorityAssignments => _assignments
      .where((a) => a.isHighPriority || a.isUrgentPriority)
      .toList();
}
