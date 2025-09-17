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
  String? _selectedPriority;
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
  String? get selectedPriority => _selectedPriority;
  String get searchTerm => _searchTerm;
  DateTimeRange? get dateRange => _dateRange;

  // Filtered followups
  List<Followup> get filteredFollowups {
    if (kDebugMode) {
      print('🔍 FollowupProvider: Computing filtered followups');
      print('   Total followups: ${_followups.length}');
      print('   Facility ID: $_facilityId');
      print('   Selected patient: $_selectedPatient');
      print('   Selected status: $_selectedStatus');
      print('   Selected type: $_selectedType');
      print('   Search term: "$_searchTerm"');
      print('   Date range: $_dateRange');
    }

    var filtered = _followups;

    // Filter by facility if set
    if (_facilityId != null) {
      final beforeCount = filtered.length;
      filtered = filtered
          .where((followup) => followup.facilityId == _facilityId)
          .toList();
      if (kDebugMode) {
        print(
          '   After facility filter: ${filtered.length} (removed ${beforeCount - filtered.length})',
        );
      }
    }

    // Filter by patient
    if (_selectedPatient != null && _selectedPatient!.isNotEmpty) {
      final beforeCount = filtered.length;
      filtered = filtered
          .where((followup) => followup.patientId == _selectedPatient)
          .toList();
      if (kDebugMode) {
        print(
          '   After patient filter: ${filtered.length} (removed ${beforeCount - filtered.length})',
        );
      }
    }

    // Filter by status
    if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
      final beforeCount = filtered.length;
      filtered = filtered
          .where((followup) => followup.status == _selectedStatus)
          .toList();
      if (kDebugMode) {
        print(
          '   After status filter: ${filtered.length} (removed ${beforeCount - filtered.length})',
        );
      }
    }

    // Filter by type
    if (_selectedType != null && _selectedType!.isNotEmpty) {
      final beforeCount = filtered.length;
      filtered = filtered
          .where((followup) => followup.followupType == _selectedType)
          .toList();
      if (kDebugMode) {
        print(
          '   After type filter: ${filtered.length} (removed ${beforeCount - filtered.length})',
        );
      }
    }

    // Filter by priority
    if (_selectedPriority != null && _selectedPriority!.isNotEmpty) {
      final beforeCount = filtered.length;
      filtered = filtered
          .where((followup) => followup.priority == _selectedPriority)
          .toList();
      if (kDebugMode) {
        print(
          '   After priority filter: ${filtered.length} (removed ${beforeCount - filtered.length})',
        );
      }
    }

    // Date range filter
    if (_dateRange != null) {
      final beforeCount = filtered.length;
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
      if (kDebugMode) {
        print(
          '   After date range filter: ${filtered.length} (removed ${beforeCount - filtered.length})',
        );
      }
    }

    // Search filter
    if (_searchTerm.isNotEmpty) {
      final beforeCount = filtered.length;
      final searchLower = _searchTerm.toLowerCase();
      filtered = filtered
          .where(
            (followup) =>
                followup.followupType.toLowerCase().contains(searchLower) ||
                followup.notes?.toLowerCase().contains(searchLower) == true,
          )
          .toList();
      if (kDebugMode) {
        print(
          '   After search filter: ${filtered.length} (removed ${beforeCount - filtered.length})',
        );
      }
    }

    if (kDebugMode) {
      print('   Final filtered count: ${filtered.length}');
    }

    return filtered;
  }

  // Set facility context
  void setFacilityId(String facilityId) {
    if (kDebugMode) {
      print('🏥 FollowupProvider: Setting facility ID to $facilityId');
    }

    _facilityId = facilityId;

    // subscribe to scheduling config
    if (kDebugMode) {
      print(
        '🏥 FollowupProvider: Subscribing to scheduling config for facility $facilityId',
      );
    }

    _schedulingService.getFacilityScheduling(facilityId).listen((cfg) {
      if (kDebugMode) {
        print(
          '📋 FollowupProvider: Received scheduling config - maxPerSlot: ${cfg.maxPerSlot}, slotMinutes: ${cfg.slotMinutes}',
        );
      }

      _schedulingConfig = cfg;
      _slotCapacity = cfg.maxPerSlot;
      _slotMinutes = cfg.slotMinutes;
      notifyListeners();
    });
    notifyListeners();
  }

  // Load followups for facility
  Future<void> loadFollowups() async {
    if (_facilityId == null) {
      if (kDebugMode) {
        print(
          '⚠️ FollowupProvider: Cannot load followups - facility ID is null',
        );
      }
      return;
    }

    if (kDebugMode) {
      print('📥 FollowupProvider: Loading followups for facility $_facilityId');
    }

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
              if (kDebugMode) {
                print(
                  '📥 FollowupProvider: Received ${snapshot.docs.length} followup documents',
                );
              }

              _followups = snapshot.docs
                  .map((doc) => Followup.fromFirestore(doc))
                  .toList();

              if (kDebugMode) {
                print(
                  '📥 FollowupProvider: Parsed ${_followups.length} followup objects',
                );
                for (var i = 0; i < _followups.length && i < 3; i++) {
                  final f = _followups[i];
                  print(
                    '   [$i] ID: ${f.followupId}, Patient: ${f.patientId}, Date: ${f.scheduledDate}, Status: ${f.status}',
                  );
                }
                if (_followups.length > 3) {
                  print('   ... and ${_followups.length - 3} more');
                }
              }

              _updateCalendarData();
              _setLoading(false);
              notifyListeners();
            },
            onError: (error) {
              if (kDebugMode) {
                print('❌ FollowupProvider: Error in followups stream: $error');
              }
              _setError('Failed to load followups: $error');
              _setLoading(false);
            },
          );
    } catch (e) {
      if (kDebugMode) {
        print('❌ FollowupProvider: Exception in loadFollowups: $e');
      }
      _setError('Failed to load followups: $e');
      _setLoading(false);
    }
  }

  // Load patients for facility
  Future<void> loadPatients() async {
    if (_facilityId == null) {
      if (kDebugMode) {
        print(
          '⚠️ FollowupProvider: Cannot load patients - facility ID is null',
        );
      }
      return;
    }

    if (kDebugMode) {
      print('👥 FollowupProvider: Loading patients for facility $_facilityId');
    }

    try {
      final snapshot = await _firestore
          .collection('patients')
          .where('treatmentFacility', isEqualTo: _facilityId)
          .get();

      if (kDebugMode) {
        print(
          '👥 FollowupProvider: Received ${snapshot.docs.length} patient documents',
        );
      }

      _patients = snapshot.docs
          .map((doc) => Patient.fromFirestore(doc))
          .toList();

      if (kDebugMode) {
        print(
          '👥 FollowupProvider: Parsed ${_patients.length} patient objects',
        );
        for (var i = 0; i < _patients.length && i < 3; i++) {
          final p = _patients[i];
          print(
            '   [$i] ID: ${p.patientId}, Name: ${p.name}, CHW: ${p.assignedCHW}',
          );
        }
        if (_patients.length > 3) {
          print('   ... and ${_patients.length - 3} more');
        }
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ FollowupProvider: Exception in loadPatients: $e');
      }
      _setError('Failed to load patients: $e');
    }
  }

  // Load CHW users for facility
  Future<void> loadCHWUsers() async {
    if (_facilityId == null) {
      if (kDebugMode) {
        print(
          '⚠️ FollowupProvider: Cannot load CHW users - facility ID is null',
        );
      }
      return;
    }

    if (kDebugMode) {
      print(
        '👨‍⚕️ FollowupProvider: Loading CHW users for facility $_facilityId',
      );
    }

    try {
      final snapshot = await _firestore
          .collection('chw_users')
          .where('facilityId', isEqualTo: _facilityId)
          .where('status', isEqualTo: 'active')
          .get();

      if (kDebugMode) {
        print(
          '👨‍⚕️ FollowupProvider: Received ${snapshot.docs.length} CHW user documents',
        );
      }

      _chwUsers = snapshot.docs
          .map((doc) => CHWUser.fromFirestore(doc))
          .toList();

      if (kDebugMode) {
        print(
          '👨‍⚕️ FollowupProvider: Parsed ${_chwUsers.length} CHW user objects',
        );
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ FollowupProvider: Exception in loadCHWUsers: $e');
      }
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
    if (_facilityId == null) {
      if (kDebugMode) {
        print(
          '⚠️ FollowupProvider: Cannot create followup - facility ID is null',
        );
      }
      return null;
    }

    if (kDebugMode) {
      print('➕ FollowupProvider: Creating followup');
      print('   Patient ID: $patientId');
      print('   Created by: $createdBy');
      print('   Scheduled date: $scheduledDate');
      print('   Type: $followupType');
      print('   Priority: $priority');
      print('   Duration: ${durationMinutes ?? _slotMinutes} minutes');
      print('   Facility ID: $_facilityId');
    }

    _setLoading(true);
    _setError(null);

    try {
      // validations
      final int dur = durationMinutes ?? _slotMinutes;

      if (kDebugMode) {
        print('🔍 FollowupProvider: Running scheduling validations');
        print('   Duration: $dur minutes');
        print(
          '   Scheduling config: ${_schedulingConfig != null ? 'available' : 'null'}',
        );
      }

      if (_schedulingConfig != null) {
        if (_schedulingService.isHoliday(scheduledDate, _schedulingConfig!)) {
          if (kDebugMode) {
            print(
              '❌ FollowupProvider: Validation failed - selected date is a holiday',
            );
          }
          throw Exception('Selected date is a holiday');
        }
        if (!_schedulingService.isWithinWorkingHours(
          scheduledDate,
          dur,
          _schedulingConfig!,
        )) {
          if (kDebugMode) {
            print(
              '❌ FollowupProvider: Validation failed - outside working hours',
            );
          }
          throw Exception('Outside working hours');
        }
        if (_schedulingService.isWithinBreaks(
          scheduledDate,
          dur,
          _schedulingConfig!,
        )) {
          if (kDebugMode) {
            print(
              '❌ FollowupProvider: Validation failed - overlaps with break time',
            );
          }
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

      if (kDebugMode) {
        print(
          '🔍 FollowupProvider: Capacity check - existing overlapping: $existing, capacity: $_slotCapacity',
        );
      }

      if (existing >= _slotCapacity) {
        if (kDebugMode) {
          print('❌ FollowupProvider: Validation failed - slot is full');
        }
        throw Exception('Slot is full');
      }

      // Create followup
      if (kDebugMode) {
        print('✨ FollowupProvider: Creating followup object');
      }

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

      if (kDebugMode) {
        print('💾 FollowupProvider: Saving followup to Firestore');
      }

      final docRef = await _firestore
          .collection('followups')
          .add(followup.toFirestore());

      if (kDebugMode) {
        print('✅ FollowupProvider: Followup saved with ID: ${docRef.id}');
      }

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

      if (kDebugMode) {
        print(
          '👥 FollowupProvider: Found patient - Name: ${patient.name}, CHW: ${patient.assignedCHW}',
        );
      }

      if (patient.assignedCHW.isNotEmpty) {
        if (kDebugMode) {
          print(
            '🔔 FollowupProvider: Creating notification for CHW: ${patient.assignedCHW}',
          );
        }

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

      if (kDebugMode) {
        print('✅ FollowupProvider: Followup creation completed successfully');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FollowupProvider: Exception in createFollowup: $e');
      }
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
    if (kDebugMode) {
      print('📝 FollowupProvider: Updating followup $followupId');
      print('   Data: $data');
    }

    _setLoading(true);
    _setError(null);

    try {
      await _firestore.collection('followups').doc(followupId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ FollowupProvider: Followup updated successfully');
      }

      _setLoading(false);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FollowupProvider: Exception in updateFollowup: $e');
      }
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
    if (kDebugMode) {
      print('✅ FollowupProvider: Completing followup $followupId');
      print('   Completed by: $completedBy');
      print('   Notes: $notes');
    }

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

      if (kDebugMode) {
        print('✅ FollowupProvider: Followup completed successfully');
      }

      _setLoading(false);
      await loadStatistics();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FollowupProvider: Exception in completeFollowup: $e');
      }
      _setError('Failed to complete followup: $e');
      _setLoading(false);
      return false;
    }
  }

  // Cancel followup
  Future<bool> cancelFollowup(String followupId, {String? reason}) async {
    if (kDebugMode) {
      print('❌ FollowupProvider: Cancelling followup $followupId');
      print('   Reason: $reason');
    }

    _setLoading(true);
    _setError(null);

    try {
      await _firestore.collection('followups').doc(followupId).update({
        'status': Followup.statusCancelled,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ FollowupProvider: Followup cancelled successfully');
      }

      _setLoading(false);
      await loadStatistics();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FollowupProvider: Exception in cancelFollowup: $e');
      }
      _setError('Failed to cancel followup: $e');
      _setLoading(false);
      return false;
    }
  }

  // Mark missed with LTFU logic
  Future<bool> markMissed(String followupId, {String? missedReason}) async {
    if (kDebugMode) {
      print('⛔ FollowupProvider: Marking followup as missed $followupId');
      print('   Reason: $missedReason');
    }

    _setLoading(true);
    _setError(null);

    try {
      final followupDoc = _firestore.collection('followups').doc(followupId);
      final followSnap = await followupDoc.get();
      if (!followSnap.exists) {
        throw Exception('Followup not found');
      }
      final followup = Followup.fromFirestore(followSnap);

      await followupDoc.update({
        'status': Followup.statusMissed,
        'missedDate': FieldValue.serverTimestamp(),
        if (missedReason != null) 'missedReason': missedReason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final patientRef = _firestore
          .collection('patients')
          .doc(followup.patientId);
      await _firestore.runTransaction((txn) async {
        final pSnap = await txn.get(patientRef);
        if (!pSnap.exists) {
          return;
        }
        final data = pSnap.data() as Map<String, dynamic>;
        final currentMisses = (data['consecutiveMisses'] as int?) ?? 0;
        final newMisses = currentMisses + 1;
        final updates = <String, dynamic>{
          'consecutiveMisses': newMisses,
          'lastMissedAt': FieldValue.serverTimestamp(),
        };
        if (newMisses >= 2 &&
            (data['tbStatus'] as String?) != 'lost_to_followup') {
          updates['tbStatus'] = 'lost_to_followup';
          updates['ltfuDate'] = FieldValue.serverTimestamp();
        }
        txn.update(patientRef, updates);
      });

      try {
        final patient = _patients.firstWhere(
          (p) => p.patientId == followup.patientId,
          orElse: () => Patient(
            patientId: followup.patientId,
            name: 'Patient',
            age: 0,
            phone: '',
            address: '',
            gender: '',
            tbStatus: 'on_treatment',
            assignedCHW: '',
            assignedFacility: '',
            treatmentFacility: '',
            gpsLocation: const {},
            consent: false,
            createdBy: '',
            createdAt: DateTime.now(),
          ),
        );
        if (patient.assignedCHW.isNotEmpty) {
          await _createCHWNotification(
            chwId: patient.assignedCHW,
            type: 'followup_missed',
            title: 'Missed Follow-up',
            message:
                'Patient ${patient.name} missed follow-up - Tracing visit required (48h)',
            relatedId: followupId,
            priority: 'high',
          );
        }
      } catch (_) {}

      _setLoading(false);
      await loadStatistics();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FollowupProvider: Exception in markMissed: $e');
      }
      _setError('Failed to mark missed: $e');
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
    if (kDebugMode) {
      print('📅 FollowupProvider: Rescheduling followup $followupId');
      print('   New date: $newDate');
      print('   Rescheduled by: $rescheduledBy');
      print('   Reason: $reason');
    }

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

      if (kDebugMode) {
        print('✅ FollowupProvider: Followup rescheduled successfully');
      }

      _setLoading(false);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FollowupProvider: Exception in rescheduleFollowup: $e');
      }
      _setError('Failed to reschedule followup: $e');
      _setLoading(false);
      return false;
    }
  }

  // Load followup by ID
  Future<void> loadFollowupById(String followupId) async {
    if (kDebugMode) {
      print('📄 FollowupProvider: Loading followup by ID: $followupId');
    }

    _setLoading(true);
    _setError(null);

    try {
      final doc = await _firestore
          .collection('followups')
          .doc(followupId)
          .get();

      if (doc.exists) {
        _selectedFollowup = Followup.fromFirestore(doc);
        if (kDebugMode) {
          print('✅ FollowupProvider: Followup loaded successfully');
        }
      } else {
        if (kDebugMode) {
          print('❌ FollowupProvider: Followup not found');
        }
        _setError('Followup not found');
      }

      _setLoading(false);
    } catch (e) {
      if (kDebugMode) {
        print('❌ FollowupProvider: Exception in loadFollowupById: $e');
      }
      _setError('Failed to load followup: $e');
      _setLoading(false);
    }
  }

  // Load statistics
  Future<void> loadStatistics() async {
    if (_facilityId == null) {
      if (kDebugMode) {
        print(
          '⚠️ FollowupProvider: Cannot load statistics - facility ID is null',
        );
      }
      return;
    }

    if (kDebugMode) {
      print(
        '📊 FollowupProvider: Loading statistics for facility $_facilityId',
      );
    }

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

      if (kDebugMode) {
        print('📊 FollowupProvider: Statistics loaded:');
        _statistics.forEach((key, value) {
          print('   $key: $value');
        });
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ FollowupProvider: Exception in loadStatistics: $e');
      }
    }
  }

  // Calendar methods
  void selectDate(DateTime date) {
    if (kDebugMode) {
      print('📅 FollowupProvider: Selecting date: $date');
    }

    _selectedDate = date;
    _updateCalendarFollowups();

    if (kDebugMode) {
      print(
        '📅 FollowupProvider: Calendar followups for selected date: ${_calendarFollowups.length}',
      );
    }

    notifyListeners();
  }

  void _updateCalendarData() {
    if (kDebugMode) {
      print('📅 FollowupProvider: Updating calendar data');
    }

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

    if (kDebugMode) {
      print(
        '📅 FollowupProvider: Calendar data updated - ${_followupsByDate.length} dates with followups',
      );
      _followupsByDate.forEach((date, followups) {
        print(
          '   ${date.toString().split(' ')[0]}: ${followups.length} followups',
        );
      });
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

    if (kDebugMode) {
      print(
        '📅 FollowupProvider: Updated calendar followups for ${selectedDay.toString().split(' ')[0]}: ${_calendarFollowups.length}',
      );
    }
  }

  // Get followups for specific date
  List<Followup> getFollowupsForDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final followups = _followupsByDate[day] ?? [];

    if (kDebugMode) {
      print(
        '📅 FollowupProvider: Getting followups for ${day.toString().split(' ')[0]}: ${followups.length}',
      );
    }

    return followups;
  }

  // Check if date has followups
  bool hasFollowupsOnDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final hasFollowups =
        _followupsByDate.containsKey(day) && _followupsByDate[day]!.isNotEmpty;

    if (kDebugMode) {
      print(
        '📅 FollowupProvider: Date ${day.toString().split(' ')[0]} has followups: $hasFollowups',
      );
    }

    return hasFollowups;
  }

  // Filter methods
  void searchFollowups(String searchTerm) {
    if (kDebugMode) {
      print('🔍 FollowupProvider: Setting search term: "$searchTerm"');
    }

    _searchTerm = searchTerm;
    notifyListeners();
  }

  void filterByPatient(String? patientId) {
    if (kDebugMode) {
      print('👥 FollowupProvider: Filtering by patient: $patientId');
    }

    _selectedPatient = patientId;
    notifyListeners();
  }

  void filterByStatus(String? status) {
    if (kDebugMode) {
      print('📊 FollowupProvider: Filtering by status: $status');
    }

    _selectedStatus = status;
    notifyListeners();
  }

  void filterByType(String? type) {
    if (kDebugMode) {
      print('🏷️ FollowupProvider: Filtering by type: $type');
    }

    _selectedType = type;
    notifyListeners();
  }

  void filterByPriority(String? priority) {
    if (kDebugMode) {
      print('⚠️ FollowupProvider: Filtering by priority: $priority');
    }
    _selectedPriority = priority;
    notifyListeners();
  }

  void filterByDateRange(DateTimeRange? dateRange) {
    if (kDebugMode) {
      print('📅 FollowupProvider: Filtering by date range: $dateRange');
    }

    _dateRange = dateRange;
    notifyListeners();
  }

  void clearFilters() {
    if (kDebugMode) {
      print('🔄 FollowupProvider: Clearing all filters');
    }

    _selectedPatient = null;
    _selectedStatus = null;
    _selectedType = null;
    _selectedPriority = null;
    _searchTerm = '';
    _dateRange = null;
    notifyListeners();
  }

  // Selection methods
  void selectFollowup(Followup followup) {
    if (kDebugMode) {
      print('👆 FollowupProvider: Selecting followup: ${followup.followupId}');
    }

    _selectedFollowup = followup;
    notifyListeners();
  }

  void clearSelectedFollowup() {
    if (kDebugMode) {
      print('🔄 FollowupProvider: Clearing selected followup');
    }

    _selectedFollowup = null;
    notifyListeners();
  }

  void clearError() {
    if (kDebugMode) {
      print('🔄 FollowupProvider: Clearing error');
    }

    _error = null;
    notifyListeners();
  }

  // Utility methods
  // Eligible patients per business rules
  List<Patient> get eligiblePatients {
    if (kDebugMode) {
      print('👥 FollowupProvider: Computing eligible patients');
    }

    final eligible = _patients.where((p) {
      final hasPending = _followups.any(
        (f) => f.patientId == p.patientId && f.isScheduled && f.isUpcoming,
      );
      final isEligible =
          p.treatmentFacility == _facilityId && p.isOnTreatment && !hasPending;

      if (kDebugMode && isEligible) {
        print('   Eligible: ${p.name} (${p.patientId})');
      }

      return isEligible;
    }).toList();

    if (kDebugMode) {
      print(
        '👥 FollowupProvider: Found ${eligible.length} eligible patients out of ${_patients.length} total',
      );
    }

    return eligible;
  }

  List<Followup> getFollowupsByPatient(String patientId) {
    if (kDebugMode) {
      print('🔍 FollowupProvider: Getting followups for patient: $patientId');
    }

    final followups = _followups
        .where((followup) => followup.patientId == patientId)
        .toList();

    if (kDebugMode) {
      print(
        '🔍 FollowupProvider: Found ${followups.length} followups for patient $patientId',
      );
    }

    return followups;
  }

  List<Followup> getTodaysFollowups() {
    if (kDebugMode) {
      print('📅 FollowupProvider: Getting today\'s followups');
    }

    final todaysFollowups = _followups
        .where((followup) => followup.isToday)
        .toList();

    if (kDebugMode) {
      print(
        '📅 FollowupProvider: Found ${todaysFollowups.length} followups for today',
      );
    }

    return todaysFollowups;
  }

  List<Followup> getUpcomingFollowups({int days = 7}) {
    if (kDebugMode) {
      print(
        '📅 FollowupProvider: Getting upcoming followups for next $days days',
      );
    }

    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days));
    final upcoming = _followups
        .where(
          (followup) =>
              followup.scheduledDate.isAfter(now) &&
              followup.scheduledDate.isBefore(futureDate) &&
              followup.isScheduled,
        )
        .toList();

    if (kDebugMode) {
      print('📅 FollowupProvider: Found ${upcoming.length} upcoming followups');
    }

    return upcoming;
  }

  List<Followup> getOverdueFollowups() {
    if (kDebugMode) {
      print('⏰ FollowupProvider: Getting overdue followups');
    }

    final overdue = _followups.where((followup) => followup.isOverdue).toList();

    if (kDebugMode) {
      print('⏰ FollowupProvider: Found ${overdue.length} overdue followups');
    }

    return overdue;
  }

  // Bulk operations
  Future<bool> bulkMarkAttended(
    List<String> followupIds,
    String staffId,
  ) async {
    if (kDebugMode) {
      print(
        '✅ FollowupProvider: Bulk mark attended for ${followupIds.length} followups',
      );
    }
    _setLoading(true);
    try {
      final batch = _firestore.batch();
      for (final id in followupIds) {
        final ref = _firestore.collection('followups').doc(id);
        batch.update(ref, {
          'status': Followup.statusCompleted,
          'completedDate': FieldValue.serverTimestamp(),
          'completedBy': staffId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      _setLoading(false);
      await loadStatistics();
      return true;
    } catch (e) {
      _setError('Bulk mark attended failed: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> bulkMarkMissed(List<String> followupIds) async {
    if (kDebugMode) {
      print(
        '⛔ FollowupProvider: Bulk mark missed for ${followupIds.length} followups',
      );
    }
    for (final id in followupIds) {
      final ok = await markMissed(id);
      if (!ok) return false;
    }
    return true;
  }

  Future<bool> bulkReschedule(
    List<String> followupIds,
    DateTime newDate,
    String rescheduledBy,
  ) async {
    if (kDebugMode) {
      print(
        '📅 FollowupProvider: Bulk reschedule ${followupIds.length} followups to $newDate',
      );
    }
    _setLoading(true);
    try {
      final batch = _firestore.batch();
      for (final id in followupIds) {
        final ref = _firestore.collection('followups').doc(id);
        batch.update(ref, {
          'scheduledDate': Timestamp.fromDate(newDate),
          'status': Followup.statusScheduled,
          'rescheduledBy': rescheduledBy,
          'rescheduledDate': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Bulk reschedule failed: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> bulkCancel(List<String> followupIds, {String? reason}) async {
    if (kDebugMode) {
      print('🛑 FollowupProvider: Bulk cancel ${followupIds.length} followups');
    }
    _setLoading(true);
    try {
      final batch = _firestore.batch();
      for (final id in followupIds) {
        final ref = _firestore.collection('followups').doc(id);
        batch.update(ref, {
          'status': Followup.statusCancelled,
          if (reason != null) 'cancelReason': reason,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      _setLoading(false);
      await loadStatistics();
      return true;
    } catch (e) {
      _setError('Bulk cancel failed: $e');
      _setLoading(false);
      return false;
    }
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
    if (kDebugMode) {
      print('🔔 FollowupProvider: Creating CHW notification');
      print('   CHW ID: $chwId');
      print('   Type: $type');
      print('   Title: $title');
      print('   Message: $message');
      print('   Related ID: $relatedId');
      print('   Priority: $priority');
    }

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

      if (kDebugMode) {
        print('✅ FollowupProvider: CHW notification created successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FollowupProvider: Failed to create CHW notification: $e');
      }
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    if (kDebugMode) {
      print('⏳ FollowupProvider: Setting loading state to $loading');
    }

    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    if (kDebugMode) {
      if (error != null) {
        print('❌ FollowupProvider: Setting error: $error');
      } else {
        print('🔄 FollowupProvider: Clearing error state');
      }
    }

    _error = error;
    notifyListeners();
  }

  // Helper getters for UI
  bool get hasActiveFilters {
    final hasFilters =
        _selectedPatient != null ||
        _selectedStatus != null ||
        _selectedType != null ||
        _searchTerm.isNotEmpty ||
        _dateRange != null;

    if (kDebugMode) {
      print('🔍 FollowupProvider: Has active filters: $hasFilters');
    }

    return hasFilters;
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
    if (_selectedPriority != null) {
      filters.add('Priority: $_selectedPriority');
    }
    if (_dateRange != null) {
      filters.add(
        'Date: ${_dateRange!.start.toString().split(' ')[0]} - ${_dateRange!.end.toString().split(' ')[0]}',
      );
    }

    final description = filters.join(', ');

    if (kDebugMode && description.isNotEmpty) {
      print('🔍 FollowupProvider: Active filters - $description');
    }

    return description;
  }
}
