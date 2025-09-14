import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assignment.dart';
import '../models/patient.dart';
import '../models/chw_user.dart';

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
      filtered = filtered.where((assignment) => assignment.facilityId == _facilityId).toList();
    }

    // Filter by CHW
    if (_selectedCHW != null && _selectedCHW!.isNotEmpty) {
      filtered = filtered.where((assignment) => assignment.chwId == _selectedCHW).toList();
    }

    // Filter by status
    if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
      filtered = filtered.where((assignment) => assignment.status == _selectedStatus).toList();
    }

    // Filter by priority
    if (_selectedPriority != null && _selectedPriority!.isNotEmpty) {
      filtered = filtered.where((assignment) => assignment.priority == _selectedPriority).toList();
    }

    // Search filter
    if (_searchTerm.isNotEmpty) {
      final searchLower = _searchTerm.toLowerCase();
      filtered = filtered.where((assignment) =>
          assignment.workArea.toLowerCase().contains(searchLower) ||
          assignment.notes?.toLowerCase().contains(searchLower) == true).toList();
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
    if (_facilityId == null) return;

    try {
      final snapshot = await _firestore
          .collection('chw_users')
          .where('facilityId', isEqualTo: _facilityId)
          .where('status', isEqualTo: 'active')
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
    if (_facilityId == null) return null;

    _setLoading(true);
    _setError(null);

    try {
      // Create assignment
      final assignment = Assignment.createNew(
        chwId: chwId,
        patientIds: patientIds,
        assignedBy: assignedBy,
        facilityId: _facilityId!,
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
          'assignedFacility': _facilityId,
        });
      }
      await batch.commit();

      // Create notification for CHW
      await _createCHWNotification(
        chwId: chwId,
        type: 'new_assignment',
        title: 'New Patient Assignment',
        message: 'You have been assigned ${patientIds.length} new patient(s)',
        relatedId: docRef.id,
      );

      _setLoading(false);
      await loadStatistics();
      return docRef.id;
    } catch (e) {
      _setError('Failed to create assignment: $e');
      _setLoading(false);
      return null;
    }
  }

  // Update assignment
  Future<bool> updateAssignment(String assignmentId, Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);

    try {
      await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .update({
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

  // Complete assignment
  Future<bool> completeAssignment(String assignmentId, String completedBy) async {
    _setLoading(true);
    _setError(null);

    try {
      await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .update({
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
      final assignment = _assignments.firstWhere((a) => a.assignmentId == assignmentId);
      
      // Update assignment status
      await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .update({
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

      final assignments = snapshot.docs.map((doc) => Assignment.fromFirestore(doc)).toList();

      _statistics = {
        'total': assignments.length,
        'active': assignments.where((a) => a.isActive).length,
        'completed': assignments.where((a) => a.isCompleted).length,
        'cancelled': assignments.where((a) => a.isCancelled).length,
        'overdue': assignments.where((a) => a.isOverdue).length,
        'highPriority': assignments.where((a) => a.isHighPriority || a.isUrgentPriority).length,
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
    return _assignments.where((assignment) => assignment.chwId == chwId).toList();
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
      final chw = _availableCHWs.firstWhere((c) => c.userId == _selectedCHW, orElse: () => CHWUser(userId: '', name: 'Unknown', email: '', phone: '', workingArea: '', idNumber: '', createdAt: DateTime.now()));
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
  List<Assignment> get overdueAssignments => _assignments.where((a) => a.isOverdue).toList();

  // Get high priority assignments
  List<Assignment> get highPriorityAssignments => 
      _assignments.where((a) => a.isHighPriority || a.isUrgentPriority).toList();

  @override
  void dispose() {
    super.dispose();
  }
}