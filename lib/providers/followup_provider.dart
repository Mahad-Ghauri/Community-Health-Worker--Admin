import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/followup.dart';
import '../models/patient.dart';
import '../models/chw_user.dart';
import '../services/scheduling_service.dart';

class FollowupProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SchedulingService _schedulingService = SchedulingService();

  List<Followup> _followups = [];
  List<Patient> _patients = [];
  List<CHWUser> _chwUsers = [];
  Followup? _selectedFollowup;
  bool _isLoading = false;
  String? _error;
  Map<String, int> _statistics = {};

  // Calendar and scheduling state
  DateTime _selectedDate = DateTime.now();
  List<Followup> _calendarFollowups = [];
  final Map<DateTime, List<Followup>> _followupsByDate = {};

  // Filter properties
  String? _selectedPatient;
  String? _selectedStatus;
  String? _selectedType;
  String _searchTerm = '';
  String? _facilityId;
  DateTimeRange? _dateRange;
  SchedulingConfig? _schedulingConfig;
  int _slotCapacity = 3;
  int _slotMinutes = 30;

  // Getters
  List<Followup> get followups => _followups;
  List<Patient> get patients => _patients;
  List<CHWUser> get chwUsers => _chwUsers;
  Followup? get selectedFollowup => _selectedFollowup;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, int> get statistics => _statistics;

  // Calendar getters
  DateTime get selectedDate => _selectedDate;
  List<Followup> get calendarFollowups => _calendarFollowups;
  Map<DateTime, List<Followup>> get followupsByDate => _followupsByDate;
  SchedulingConfig? get schedulingConfig => _schedulingConfig;
  int get slotCapacity => _slotCapacity;
  int get slotMinutes => _slotMinutes;

  // Filter getters
  String? get selectedPatient => _selectedPatient;
  String? get selectedStatus => _selectedStatus;
  String? get selectedType => _selectedType;
  String get searchTerm => _searchTerm;
  DateTimeRange? get dateRange => _dateRange;

  // Filtered followups
  List<Followup> get filteredFollowups {
    var filtered = _followups;

    // Filter by facility if set
    if (_facilityId != null) {
      filtered = filtered
          .where((followup) => followup.facilityId == _facilityId)
          .toList();
    }

    // Filter by patient
    if (_selectedPatient != null && _selectedPatient!.isNotEmpty) {
      filtered = filtered
          .where((followup) => followup.patientId == _selectedPatient)
          .toList();
    }

    // Filter by status
    if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
      filtered = filtered
          .where((followup) => followup.status == _selectedStatus)
          .toList();
    }

    // Filter by type
    if (_selectedType != null && _selectedType!.isNotEmpty) {
      filtered = filtered
          .where((followup) => followup.followupType == _selectedType)
          .toList();
    }

    // Date range filter
    if (_dateRange != null) {
      filtered = filtered
          .where(
            (followup) =>
                followup.scheduledDate.isAfter(
                  _dateRange!.start.subtract(const Duration(days: 1)),
                ) &&
                followup.scheduledDate.isBefore(
                  _dateRange!.end.add(const Duration(days: 1)),
                ),
          )
          .toList();
    }

    // Search filter
    if (_searchTerm.isNotEmpty) {
      final searchLower = _searchTerm.toLowerCase();
      filtered = filtered
          .where(
            (followup) =>
                followup.followupType.toLowerCase().contains(searchLower) ||
                followup.notes?.toLowerCase().contains(searchLower) == true,
          )
          .toList();
    }

    return filtered;
  }

  // Set facility context
  void setFacilityId(String facilityId) {
    _facilityId = facilityId;
    // subscribe to scheduling config
    _schedulingService.getFacilityScheduling(facilityId).listen((cfg) {
      _schedulingConfig = cfg;
      _slotCapacity = cfg.maxPerSlot;
      _slotMinutes = cfg.slotMinutes;
      notifyListeners();
    });
    notifyListeners();
  }

  // Load followups for facility
  Future<void> loadFollowups() async {
    if (_facilityId == null) return;

    _setLoading(true);
    _setError(null);

    try {
      // Listen to followups stream
      _firestore
          .collection('followups')
          .where('facilityId', isEqualTo: _facilityId)
          .orderBy('scheduledDate', descending: false)
          .snapshots()
          .listen(
            (snapshot) {
              _followups = snapshot.docs
                  .map((doc) => Followup.fromFirestore(doc))
                  .toList();
              _updateCalendarData();
              _setLoading(false);
              notifyListeners();
            },
            onError: (error) {
              _setError('Failed to load followups: $error');
              _setLoading(false);
            },
          );
    } catch (e) {
      _setError('Failed to load followups: $e');
      _setLoading(false);
    }
  }

  // Load patients for facility
  Future<void> loadPatients() async {
    if (_facilityId == null) return;

    try {
      final snapshot = await _firestore
          .collection('patients')
          .where('treatmentFacility', isEqualTo: _facilityId)
          .get();

      _patients = snapshot.docs
          .map((doc) => Patient.fromFirestore(doc))
          .toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load patients: $e');
    }
  }

  // Load CHW users for facility
  Future<void> loadCHWUsers() async {
    if (_facilityId == null) return;

    try {
      final snapshot = await _firestore
          .collection('chw_users')
          .where('facilityId', isEqualTo: _facilityId)
          .where('status', isEqualTo: 'active')
          .get();

      _chwUsers = snapshot.docs
          .map((doc) => CHWUser.fromFirestore(doc))
          .toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load CHW users: $e');
    }
  }

  // Create new followup
  Future<String?> createFollowup({
    required String patientId,
    required String createdBy,
    required DateTime scheduledDate,
    required String followupType,
    String priority = Followup.priorityRoutine,
    String? notes,
    bool sendReminder = true,
    int? durationMinutes,
    String? assignedStaffId,
    String? roomId,
  }) async {
    if (_facilityId == null) return null;

    _setLoading(true);
    _setError(null);

    try {
      // validations
      final int dur = durationMinutes ?? _slotMinutes;
      if (_schedulingConfig != null) {
        if (_schedulingService.isHoliday(scheduledDate, _schedulingConfig!)) {
          throw Exception('Selected date is a holiday');
        }
        if (!_schedulingService.isWithinWorkingHours(
          scheduledDate,
          dur,
          _schedulingConfig!,
        )) {
          throw Exception('Outside working hours');
        }
        if (_schedulingService.isWithinBreaks(
          scheduledDate,
          dur,
          _schedulingConfig!,
        )) {
          throw Exception('Overlaps with break time');
        }
      }

      // capacity check (client-side best effort)
      final existing = getFollowupsForDate(scheduledDate).where((f) {
        final end = f.scheduledDate.add(
          Duration(minutes: f.durationMinutes ?? 30),
        );
        final selEnd = scheduledDate.add(Duration(minutes: dur));
        return f.status == Followup.statusScheduled &&
            f.scheduledDate.isBefore(selEnd) &&
            end.isAfter(scheduledDate);
      }).length;
      if (existing >= _slotCapacity) {
        throw Exception('Slot is full');
      }
      // Create followup
      final followup = Followup.createNew(
        patientId: patientId,
        scheduledDate: scheduledDate,
        facilityId: _facilityId!,
        followupType: followupType,
        createdBy: createdBy,
        priority: priority,
        notes: notes,
        sendReminder: sendReminder,
        durationMinutes: dur,
        assignedStaffId: assignedStaffId,
        roomId: roomId,
      );

      final docRef = await _firestore
          .collection('followups')
          .add(followup.toFirestore());

      // Get patient's assigned CHW for notification
      final patient = _patients.firstWhere(
        (p) => p.patientId == patientId,
        orElse: () => Patient(
          patientId: '',
          name: 'Unknown',
          age: 0,
          phone: '',
          address: '',
          gender: '',
          tbStatus: 'newly_diagnosed',
          assignedCHW: '',
          assignedFacility: '',
          treatmentFacility: '',
          gpsLocation: {},
          consent: false,
          createdBy: '',
          createdAt: DateTime.now(),
        ),
      );

      if (patient.assignedCHW.isNotEmpty) {
        // Create notification for CHW
        await _createCHWNotification(
          chwId: patient.assignedCHW,
          type: 'followup_scheduled',
          title: 'New Follow-up Scheduled',
          message:
              'Follow-up scheduled for ${followup.formattedScheduledDateTime}',
          relatedId: docRef.id,
        );
      }

      _setLoading(false);
      await loadStatistics();
      return docRef.id;
    } catch (e) {
      _setError('Failed to create followup: $e');
      _setLoading(false);
      return null;
    }
  }

  // Update followup
  Future<bool> updateFollowup(
    String followupId,
    Map<String, dynamic> data,
  ) async {
    _setLoading(true);
    _setError(null);

    try {
      await _firestore.collection('followups').doc(followupId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update followup: $e');
      _setLoading(false);
      return false;
    }
  }

  // Complete followup
  Future<bool> completeFollowup(
    String followupId,
    String completedBy, {
    String? notes,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final updateData = {
        'status': Followup.statusCompleted,
        'completedDate': FieldValue.serverTimestamp(),
        'completedBy': completedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (notes != null && notes.isNotEmpty) {
        updateData['outcomeNotes'] = notes;
      }

      await _firestore
          .collection('followups')
          .doc(followupId)
          .update(updateData);

      _setLoading(false);
      await loadStatistics();
      return true;
    } catch (e) {
      _setError('Failed to complete followup: $e');
      _setLoading(false);
      return false;
    }
  }

  // Cancel followup
  Future<bool> cancelFollowup(String followupId, {String? reason}) async {
    _setLoading(true);
    _setError(null);

    try {
      await _firestore.collection('followups').doc(followupId).update({
        'status': Followup.statusCancelled,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _setLoading(false);
      await loadStatistics();
      return true;
    } catch (e) {
      _setError('Failed to cancel followup: $e');
      _setLoading(false);
      return false;
    }
  }

  // Reschedule followup
  Future<bool> rescheduleFollowup(
    String followupId,
    DateTime newDate,
    String rescheduledBy, {
    String? reason,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await _firestore.collection('followups').doc(followupId).update({
        'scheduledDate': Timestamp.fromDate(newDate),
        'status': Followup.statusScheduled,
        'rescheduledBy': rescheduledBy,
        'rescheduledDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to reschedule followup: $e');
      _setLoading(false);
      return false;
    }
  }

  // Load followup by ID
  Future<void> loadFollowupById(String followupId) async {
    _setLoading(true);
    _setError(null);

    try {
      final doc = await _firestore
          .collection('followups')
          .doc(followupId)
          .get();

      if (doc.exists) {
        _selectedFollowup = Followup.fromFirestore(doc);
      } else {
        _setError('Followup not found');
      }

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load followup: $e');
      _setLoading(false);
    }
  }

  // Load statistics
  Future<void> loadStatistics() async {
    if (_facilityId == null) return;

    try {
      final snapshot = await _firestore
          .collection('followups')
          .where('facilityId', isEqualTo: _facilityId)
          .get();

      final followups = snapshot.docs
          .map((doc) => Followup.fromFirestore(doc))
          .toList();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final thisWeek = today.add(const Duration(days: 7));

      _statistics = {
        'total': followups.length,
        'scheduled': followups.where((f) => f.isScheduled).length,
        'completed': followups.where((f) => f.isCompleted).length,
        'cancelled': followups.where((f) => f.isCancelled).length,
        'overdue': followups.where((f) => f.isOverdue).length,
        'today': followups.where((f) => f.isToday).length,
        'tomorrow': followups
            .where(
              (f) =>
                  f.scheduledDate.isAfter(today) &&
                  f.scheduledDate.isBefore(
                    tomorrow.add(const Duration(days: 1)),
                  ),
            )
            .length,
        'thisWeek': followups
            .where(
              (f) =>
                  f.scheduledDate.isAfter(today) &&
                  f.scheduledDate.isBefore(thisWeek),
            )
            .length,
      };

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load followup statistics: $e');
      }
    }
  }

  // Calendar methods
  void selectDate(DateTime date) {
    _selectedDate = date;
    _updateCalendarFollowups();
    notifyListeners();
  }

  void _updateCalendarData() {
    // Update followups by date for calendar view
    _followupsByDate.clear();
    for (final followup in _followups) {
      final date = DateTime(
        followup.scheduledDate.year,
        followup.scheduledDate.month,
        followup.scheduledDate.day,
      );
      _followupsByDate[date] = [...(_followupsByDate[date] ?? []), followup];
    }
    _updateCalendarFollowups();
  }

  void _updateCalendarFollowups() {
    final selectedDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    _calendarFollowups = _followupsByDate[selectedDay] ?? [];
  }

  // Get followups for specific date
  List<Followup> getFollowupsForDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return _followupsByDate[day] ?? [];
  }

  // Check if date has followups
  bool hasFollowupsOnDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return _followupsByDate.containsKey(day) &&
        _followupsByDate[day]!.isNotEmpty;
  }

  // Filter methods
  void searchFollowups(String searchTerm) {
    _searchTerm = searchTerm;
    notifyListeners();
  }

  void filterByPatient(String? patientId) {
    _selectedPatient = patientId;
    notifyListeners();
  }

  void filterByStatus(String? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void filterByType(String? type) {
    _selectedType = type;
    notifyListeners();
  }

  void filterByDateRange(DateTimeRange? dateRange) {
    _dateRange = dateRange;
    notifyListeners();
  }

  void clearFilters() {
    _selectedPatient = null;
    _selectedStatus = null;
    _selectedType = null;
    _searchTerm = '';
    _dateRange = null;
    notifyListeners();
  }

  // Selection methods
  void selectFollowup(Followup followup) {
    _selectedFollowup = followup;
    notifyListeners();
  }

  void clearSelectedFollowup() {
    _selectedFollowup = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Utility methods
  // Eligible patients per business rules
  List<Patient> get eligiblePatients {
    return _patients.where((p) {
      final hasPending = _followups.any(
        (f) => f.patientId == p.patientId && f.isScheduled && f.isUpcoming,
      );
      return p.treatmentFacility == _facilityId &&
          p.isOnTreatment &&
          !hasPending;
    }).toList();
  }

  List<Followup> getFollowupsByPatient(String patientId) {
    return _followups
        .where((followup) => followup.patientId == patientId)
        .toList();
  }

  List<Followup> getTodaysFollowups() {
    return _followups.where((followup) => followup.isToday).toList();
  }

  List<Followup> getUpcomingFollowups({int days = 7}) {
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days));
    return _followups
        .where(
          (followup) =>
              followup.scheduledDate.isAfter(now) &&
              followup.scheduledDate.isBefore(futureDate) &&
              followup.isScheduled,
        )
        .toList();
  }

  List<Followup> getOverdueFollowups() {
    return _followups.where((followup) => followup.isOverdue).toList();
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
    return _selectedPatient != null ||
        _selectedStatus != null ||
        _selectedType != null ||
        _searchTerm.isNotEmpty ||
        _dateRange != null;
  }

  int get totalFollowupsCount => _followups.length;
  int get filteredFollowupsCount => filteredFollowups.length;

  String get filtersDescription {
    final filters = <String>[];

    if (_searchTerm.isNotEmpty) {
      filters.add('Search: "$_searchTerm"');
    }
    if (_selectedPatient != null) {
      final patient = _patients.firstWhere(
        (p) => p.patientId == _selectedPatient,
        orElse: () => Patient(
          patientId: '',
          name: 'Unknown',
          age: 0,
          phone: '',
          address: '',
          gender: '',
          tbStatus: 'newly_diagnosed',
          assignedCHW: '',
          assignedFacility: '',
          treatmentFacility: '',
          gpsLocation: {},
          consent: false,
          createdBy: '',
          createdAt: DateTime.now(),
        ),
      );
      filters.add('Patient: ${patient.name}');
    }
    if (_selectedStatus != null) {
      filters.add('Status: $_selectedStatus');
    }
    if (_selectedType != null) {
      filters.add('Type: $_selectedType');
    }
    if (_dateRange != null) {
      filters.add(
        'Date: ${_dateRange!.start.toString().split(' ')[0]} - ${_dateRange!.end.toString().split(' ')[0]}',
      );
    }

    return filters.join(', ');
  }
}
