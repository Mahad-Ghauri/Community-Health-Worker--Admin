// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/referral.dart';
import '../models/patient.dart';
import '../models/chw_user.dart';
import '../models/facility.dart';
import '../services/patient_service.dart';
import '../services/audit_log_service.dart';
import '../constants/app_constants.dart';

class ReferralProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Referral> _referrals = [];
  List<Patient> _patients = [];
  List<CHWUser> _chwUsers = [];
  List<Facility> _facilities = [];
  Referral? _selectedReferral;
  bool _isLoading = false;
  String? _error;
  Map<String, int> _statistics = {};

  // Filter properties
  String? _selectedPatient;
  String? _selectedCHW;
  String? _selectedStatus;
  String? _selectedUrgency;
  String _searchTerm = '';
  String? _facilityId;
  DateTimeRange? _dateRange;

  // Getters
  List<Referral> get referrals => _referrals;
  List<Patient> get patients => _patients;
  List<CHWUser> get chwUsers => _chwUsers;
  List<Facility> get facilities => _facilities;
  Referral? get selectedReferral => _selectedReferral;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, int> get statistics => _statistics;

  // Filter getters
  String? get selectedPatient => _selectedPatient;
  String? get selectedCHW => _selectedCHW;
  String? get selectedStatus => _selectedStatus;
  String? get selectedUrgency => _selectedUrgency;
  String get searchTerm => _searchTerm;
  DateTimeRange? get dateRange => _dateRange;

  // Sorting state
  String _sortField = 'createdAt'; // createdAt | urgency | referralDate
  bool _sortDesc = true;

  void setSort({required String field, required bool descending}) {
    if (kDebugMode) {
      print(
        '🔄 ReferralProvider: Setting sort - field: $field, descending: $descending',
      );
    }
    _sortField = field;
    _sortDesc = descending;
    notifyListeners();
  }

  // Filtered referrals
  List<Referral> get filteredReferrals {
    if (kDebugMode) {
      print(
        '🔍 ReferralProvider: Getting filtered referrals - total referrals: ${_referrals.length}',
      );
    }

    var filtered = _referrals;

    // Filter by facility if set
    if (_facilityId != null) {
      final beforeCount = filtered.length;
      filtered = filtered
          .where(
            (referral) =>
                referral.referringFacilityId == _facilityId ||
                referral.receivingFacilityId == _facilityId,
          )
          .toList();
      if (kDebugMode) {
        print(
          '🏥 ReferralProvider: Facility filter applied - before: $beforeCount, after: ${filtered.length}',
        );
      }
    }

    // Filter by patient
    if (_selectedPatient != null && _selectedPatient!.isNotEmpty) {
      final beforeCount = filtered.length;
      filtered = filtered
          .where((referral) => referral.patientId == _selectedPatient)
          .toList();
      if (kDebugMode) {
        print(
          '👤 ReferralProvider: Patient filter applied ($_selectedPatient) - before: $beforeCount, after: ${filtered.length}',
        );
      }
    }

    // Filter by CHW
    if (_selectedCHW != null && _selectedCHW!.isNotEmpty) {
      final beforeCount = filtered.length;
      filtered = filtered
          .where((referral) => referral.referringCHWId == _selectedCHW)
          .toList();
      if (kDebugMode) {
        print(
          '👩‍⚕️ ReferralProvider: CHW filter applied ($_selectedCHW) - before: $beforeCount, after: ${filtered.length}',
        );
      }
    }

    // Filter by status
    if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
      final beforeCount = filtered.length;
      filtered = filtered
          .where((referral) => referral.status == _selectedStatus)
          .toList();
      if (kDebugMode) {
        print(
          '📊 ReferralProvider: Status filter applied ($_selectedStatus) - before: $beforeCount, after: ${filtered.length}',
        );
      }
    }

    // Filter by urgency
    if (_selectedUrgency != null && _selectedUrgency!.isNotEmpty) {
      final beforeCount = filtered.length;
      filtered = filtered
          .where((referral) => referral.urgency == _selectedUrgency)
          .toList();
      if (kDebugMode) {
        print(
          '⚠️ ReferralProvider: Urgency filter applied ($_selectedUrgency) - before: $beforeCount, after: ${filtered.length}',
        );
      }
    }

    // Date range filter
    if (_dateRange != null) {
      final beforeCount = filtered.length;
      filtered = filtered
          .where(
            (referral) =>
                referral.createdAt.isAfter(
                  _dateRange!.start.subtract(const Duration(days: 1)),
                ) &&
                referral.createdAt.isBefore(
                  _dateRange!.end.add(const Duration(days: 1)),
                ),
          )
          .toList();
      if (kDebugMode) {
        print(
          '📅 ReferralProvider: Date range filter applied (${_dateRange!.start} - ${_dateRange!.end}) - before: $beforeCount, after: ${filtered.length}',
        );
      }
    }

    // Search filter
    if (_searchTerm.isNotEmpty) {
      final beforeCount = filtered.length;
      final searchLower = _searchTerm.toLowerCase();
      filtered = filtered
          .where(
            (referral) =>
                referral.referralReason.toLowerCase().contains(searchLower) ||
                referral.symptoms?.toLowerCase().contains(searchLower) ==
                    true ||
                referral.clinicalNotes?.toLowerCase().contains(searchLower) ==
                    true,
          )
          .toList();
      if (kDebugMode) {
        print(
          '🔎 ReferralProvider: Search filter applied ("$_searchTerm") - before: $beforeCount, after: ${filtered.length}',
        );
      }
    }

    // Apply sort
    final list = [...filtered];
    list.sort((a, b) {
      int cmp = 0;
      switch (_sortField) {
        case 'urgency':
          const order = {
            Referral.urgencyUrgent: 3,
            Referral.urgencyHigh: 2,
            Referral.urgencyMedium: 1,
            Referral.urgencyLow: 0,
          };
          cmp = (order[a.urgency] ?? 0).compareTo(order[b.urgency] ?? 0);
          break;
        case 'referralDate':
          cmp = a.referralDate.compareTo(b.referralDate);
          break;
        default:
          cmp = a.createdAt.compareTo(b.createdAt);
      }
      return _sortDesc ? -cmp : cmp;
    });

    if (kDebugMode) {
      print(
        '📋 ReferralProvider: Final filtered and sorted list: ${list.length} referrals',
      );
    }

    return list;
  }

  // Set facility context
  void setFacilityId(String facilityId) {
    if (kDebugMode) {
      print('🏢 ReferralProvider: Setting facility ID: $facilityId');
    }
    _facilityId = facilityId;
    notifyListeners();
  }

  // Load referrals for facility
  Future<void> loadReferrals() async {
    if (_facilityId == null) {
      if (kDebugMode) {
        print(
          '⚠️ ReferralProvider: Cannot load referrals - facility ID is null',
        );
      }
      return;
    }

    if (kDebugMode) {
      print(
        '📥 ReferralProvider: Starting to load referrals for facility: $_facilityId',
      );
    }

    _setLoading(true);
    _setError(null);

    try {
      // Listen to referrals stream (both sent from and received by this facility)
      if (kDebugMode) {
        print(
          '👂 ReferralProvider: Setting up referrals listener for sent referrals',
        );
      }

      _firestore
          .collection('referrals')
          .where('referringFacilityId', isEqualTo: _facilityId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              if (kDebugMode) {
                print(
                  '📨 ReferralProvider: Received sent referrals update - ${snapshot.docs.length} documents',
                );
              }

              final fromReferrals = snapshot.docs
                  .map((doc) => Referral.fromFirestore(doc))
                  .toList();

              // Update immediately with "sent" referrals so UI isn't stuck waiting
              _referrals = [...fromReferrals]
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              _setLoading(false);
              notifyListeners();

              // Also get referrals sent TO this facility
              if (kDebugMode) {
                print(
                  '👂 ReferralProvider: Setting up listener for received referrals',
                );
              }

              _firestore
                  .collection('referrals')
                  .where('receivingFacilityId', isEqualTo: _facilityId)
                  .orderBy('createdAt', descending: true)
                  .snapshots()
                  .listen(
                    (toSnapshot) {
                      if (kDebugMode) {
                        print(
                          '📨 ReferralProvider: Received incoming referrals update - ${toSnapshot.docs.length} documents',
                        );
                      }

                      final toReferrals = toSnapshot.docs
                          .map((doc) => Referral.fromFirestore(doc))
                          .toList();

                      // Combine and deduplicate
                      final allReferrals = <String, Referral>{};
                      for (final referral in [
                        ...fromReferrals,
                        ...toReferrals,
                      ]) {
                        allReferrals[referral.referralId] = referral;
                      }

                      if (kDebugMode) {
                        print(
                          '🔄 ReferralProvider: Combined referrals - sent: ${fromReferrals.length}, received: ${toReferrals.length}, unique: ${allReferrals.length}',
                        );
                      }

                      _referrals = allReferrals.values.toList()
                        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                      // Ensure loading stays false after updates
                      _isLoading = false;
                      notifyListeners();
                    },
                    onError: (error) {
                      if (kDebugMode) {
                        print(
                          '❌ ReferralProvider: Error loading incoming referrals - $error',
                        );
                      }
                      _setError('Failed to load referrals: $error');
                      _setLoading(false);
                    },
                  );
            },
            onError: (error) {
              if (kDebugMode) {
                print('❌ ReferralProvider: Error loading referrals - $error');
              }
              _setError('Failed to load referrals: $error');
              _setLoading(false);
            },
          );
    } catch (e) {
      if (kDebugMode) {
        print('❌ ReferralProvider: Exception while loading referrals - $e');
      }
      _setError('Failed to load referrals: $e');
      _setLoading(false);
    }
  }

  // Load patients for facility
  Future<void> loadPatients() async {
    if (_facilityId == null) {
      if (kDebugMode) {
        print(
          '⚠️ ReferralProvider: Cannot load patients - facility ID is null',
        );
      }
      return;
    }

    if (kDebugMode) {
      print('👥 ReferralProvider: Loading patients for facility: $_facilityId');
    }

    try {
      final snapshot = await _firestore
          .collection('patients')
          .where('assignedFacility', isEqualTo: _facilityId)
          .get();

      _patients = snapshot.docs
          .map((doc) => Patient.fromFirestore(doc))
          .toList();

      if (kDebugMode) {
        print(
          '✅ ReferralProvider: Patients loaded successfully - ${_patients.length} patients',
        );
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ ReferralProvider: Failed to load patients - $e');
      }
      _setError('Failed to load patients: $e');
    }
  }

  // Load CHW users for facility
  Future<void> loadCHWUsers() async {
    if (_facilityId == null) {
      if (kDebugMode) {
        print(
          '⚠️ ReferralProvider: Cannot load CHW users - facility ID is null',
        );
      }
      return;
    }

    if (kDebugMode) {
      print(
        '👩‍⚕️ ReferralProvider: Loading CHW users for facility: $_facilityId',
      );
    }

    try {
      final snapshot = await _firestore
          .collection('chw_users')
          .where('facilityId', isEqualTo: _facilityId)
          .where('status', isEqualTo: 'active')
          .get();

      _chwUsers = snapshot.docs
          .map((doc) => CHWUser.fromFirestore(doc))
          .toList();

      if (kDebugMode) {
        print(
          '✅ ReferralProvider: CHW users loaded successfully - ${_chwUsers.length} CHW users',
        );
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ ReferralProvider: Failed to load CHW users - $e');
      }
      _setError('Failed to load CHW users: $e');
    }
  }

  // Load all facilities for referral options
  Future<void> loadFacilities() async {
    if (kDebugMode) {
      print('🏥 ReferralProvider: Loading all facilities');
    }

    try {
      final snapshot = await _firestore
          .collection('facilities')
          .where('status', isEqualTo: 'active')
          .get();

      _facilities = snapshot.docs
          .map((doc) => Facility.fromFirestore(doc))
          .toList();

      if (kDebugMode) {
        print(
          '✅ ReferralProvider: Facilities loaded successfully - ${_facilities.length} facilities',
        );
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ ReferralProvider: Failed to load facilities - $e');
      }
      _setError('Failed to load facilities: $e');
    }
  }

  // Create new referral
  Future<String?> createReferral({
    required String patientId,
    required String referringCHWId,
    required String receivingFacilityId,
    required String referralReason,
    String urgency = Referral.urgencyMedium,
    String? symptoms,
    String? clinicalNotes,
    String? referringCHWNotes,
    List<String>? attachments,
    Map<String, dynamic>? patientCondition,
  }) async {
    if (_facilityId == null) {
      if (kDebugMode) {
        print(
          '⚠️ ReferralProvider: Cannot create referral - facility ID is null',
        );
      }
      return null;
    }

    if (kDebugMode) {
      print('➕ ReferralProvider: Creating new referral');
      print('   Patient: $patientId');
      print('   Referring CHW: $referringCHWId');
      print('   Receiving Facility: $receivingFacilityId');
      print('   Reason: $referralReason');
      print('   Urgency: $urgency');
    }

    _setLoading(true);
    _setError(null);

    try {
      // Create referral
      final referral = Referral.createNew(
        patientId: patientId,
        referringCHWId: referringCHWId,
        referringFacilityId: _facilityId!,
        receivingFacilityId: receivingFacilityId,
        referralReason: referralReason,
        urgency: urgency,
        symptoms: symptoms,
        clinicalNotes: clinicalNotes,
        referringCHWNotes: referringCHWNotes,
        attachments: attachments,
        patientCondition: patientCondition,
      );

      if (kDebugMode) {
        print('💾 ReferralProvider: Saving referral to Firestore');
      }

      final docRef = await _firestore
          .collection('referrals')
          .add(referral.toFirestore());

      if (kDebugMode) {
        print('📋 ReferralProvider: Referral created with ID: ${docRef.id}');
        print(
          '📨 ReferralProvider: Creating notification for receiving facility',
        );
      }

      // Create notification for receiving facility staff
      await _createFacilityNotification(
        facilityId: receivingFacilityId,
        type: 'referral_received',
        title: 'New Patient Referral',
        message:
            'New ${referral.urgencyDisplayName} referral for $referralReason',
        relatedId: docRef.id,
        priority: referral.isUrgentUrgency ? 'urgent' : 'medium',
      );

      _setLoading(false);
      await loadStatistics();

      if (kDebugMode) {
        print(
          '✅ ReferralProvider: Referral created successfully - ID: ${docRef.id}',
        );
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ReferralProvider: Failed to create referral - $e');
      }
      _setError('Failed to create referral: $e');
      _setLoading(false);
      return null;
    }
  }

  // Update referral
  Future<bool> updateReferral(
    String referralId,
    Map<String, dynamic> data,
  ) async {
    if (kDebugMode) {
      print(
        '✏️ ReferralProvider: Updating referral $referralId with data: $data',
      );
    }

    _setLoading(true);
    _setError(null);

    try {
      await _firestore.collection('referrals').doc(referralId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ ReferralProvider: Referral updated successfully');
      }

      _setLoading(false);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ReferralProvider: Failed to update referral - $e');
      }
      _setError('Failed to update referral: $e');
      _setLoading(false);
      return false;
    }
  }

  // Accept referral (enhanced)
  Future<bool> acceptReferral(
    String referralId,
    String acceptedBy, {
    String? notes,
    DateTime? appointmentDate,
    String? assignedStaffId,
    String? patientName,
    String? facilityName,
    String? staffUserName,
  }) async {
    if (kDebugMode) {
      print('✅ ReferralProvider: Accepting referral $referralId');
      print('   Accepted by: $acceptedBy');
      print('   Appointment date: $appointmentDate');
      print('   Assigned staff: $assignedStaffId');
      print('   Notes: $notes');
    }

    _setLoading(true);
    _setError(null);

    try {
      final updateData = {
        'status': Referral.statusAccepted,
        'acceptedBy': acceptedBy,
        'acceptedDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (notes != null && notes.isNotEmpty) 'responseNotes': notes,
        if (appointmentDate != null)
          'appointmentDate': Timestamp.fromDate(appointmentDate),
        if (assignedStaffId != null && assignedStaffId.isNotEmpty)
          'assignedStaffId': assignedStaffId,
      };

      if (kDebugMode) {
        print('💾 ReferralProvider: Updating referral status to accepted');
      }

      await _firestore
          .collection('referrals')
          .doc(referralId)
          .update(updateData);

      // Get referral locally
      final referral = _referrals.firstWhere((r) => r.referralId == referralId);

      if (kDebugMode) {
        print(
          '👤 ReferralProvider: Updating patient record for ${referral.patientId}',
        );
      }

      // Update patient record to reflect treatment at receiving facility
      await PatientService().updatePatient(referral.patientId, {
        'treatmentFacility': referral.receivingFacilityId,
        'tbStatus': AppConstants.onTreatmentStatus,
        'validatedBy': acceptedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify referring CHW with context
      final pname = patientName ?? referral.patientId;
      final fname = facilityName ?? referral.receivingFacilityId;

      if (kDebugMode) {
        print(
          '📨 ReferralProvider: Sending notification to CHW ${referral.referringCHWId}',
        );
      }

      await _createCHWNotification(
        chwId: referral.referringCHWId,
        type: 'referral_accepted',
        title: 'Referral Accepted',
        message:
            'Your referral for $pname has been accepted by $fname'
            '${appointmentDate != null ? ' (appt: ${appointmentDate.toLocal()})' : ''}',
        relatedId: referralId,
      );

      // Audit log
      if (kDebugMode) {
        print('📝 ReferralProvider: Creating audit log entry');
      }

      await AuditLogService.logFacilityAction(
        action: 'referral_accept',
        entityId: referralId,
        userId: acceptedBy,
        userName: staffUserName ?? acceptedBy,
        userRole: UserRoles.staff,
        description: 'Referral accepted for patient $pname at $fname',
        newData: {
          'appointmentDate': appointmentDate?.toIso8601String(),
          'assignedStaffId': assignedStaffId,
        },
      );

      _setLoading(false);
      await loadStatistics();

      if (kDebugMode) {
        print('✅ ReferralProvider: Referral accepted successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ReferralProvider: Failed to accept referral - $e');
      }
      _setError('Failed to accept referral: $e');
      _setLoading(false);
      return false;
    }
  }

  // Decline referral (enhanced)
  Future<bool> declineReferral(
    String referralId,
    String declinedBy,
    String reason, {
    String? suggestions,
    String? patientName,
    String? staffUserName,
  }) async {
    if (kDebugMode) {
      print('❌ ReferralProvider: Declining referral $referralId');
      print('   Declined by: $declinedBy');
      print('   Reason: $reason');
      print('   Suggestions: $suggestions');
    }

    _setLoading(true);
    _setError(null);

    try {
      await _firestore.collection('referrals').doc(referralId).update({
        'status': Referral.statusDeclined,
        'respondedBy': declinedBy,
        'responseDate': FieldValue.serverTimestamp(),
        'declineReason': reason,
        if (suggestions != null && suggestions.isNotEmpty)
          'responseNotes': suggestions,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify referring CHW/facility
      final referral = _referrals.firstWhere((r) => r.referralId == referralId);
      final pname = patientName ?? referral.patientId;

      if (kDebugMode) {
        print(
          '📨 ReferralProvider: Sending decline notification to CHW ${referral.referringCHWId}',
        );
      }

      await _createCHWNotification(
        chwId: referral.referringCHWId,
        type: 'referral_declined',
        title: 'Referral Declined',
        message:
            'Your referral for $pname has been declined. Reason: $reason'
            '${suggestions != null && suggestions.isNotEmpty ? ' | Suggestions: $suggestions' : ''}',
        relatedId: referralId,
        priority: 'high',
      );

      if (kDebugMode) {
        print('📝 ReferralProvider: Creating audit log entry for decline');
      }

      await AuditLogService.logFacilityAction(
        action: 'referral_decline',
        entityId: referralId,
        userId: declinedBy,
        userName: staffUserName ?? declinedBy,
        userRole: UserRoles.staff,
        description: 'Referral declined for patient $pname',
        newData: {
          'reason': reason,
          if (suggestions != null && suggestions.isNotEmpty)
            'suggestions': suggestions,
        },
      );

      _setLoading(false);
      await loadStatistics();

      if (kDebugMode) {
        print('✅ ReferralProvider: Referral declined successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ReferralProvider: Failed to decline referral - $e');
      }
      _setError('Failed to decline referral: $e');
      _setLoading(false);
      return false;
    }
  }

  // Complete referral
  Future<bool> completeReferral(
    String referralId,
    String completedBy, {
    String? outcome,
  }) async {
    if (kDebugMode) {
      print('✅ ReferralProvider: Completing referral $referralId');
      print('   Completed by: $completedBy');
      print('   Outcome: $outcome');
    }

    _setLoading(true);
    _setError(null);

    try {
      final updateData = {
        'status': Referral.statusCompleted,
        'completedDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (outcome != null && outcome.isNotEmpty) {
        updateData['outcome'] = outcome;
      }

      await _firestore
          .collection('referrals')
          .doc(referralId)
          .update(updateData);

      // Notify referring CHW/facility
      final referral = _referrals.firstWhere((r) => r.referralId == referralId);

      if (kDebugMode) {
        print(
          '📨 ReferralProvider: Sending completion notification to CHW ${referral.referringCHWId}',
        );
      }

      await _createCHWNotification(
        chwId: referral.referringCHWId,
        type: 'referral_completed',
        title: 'Referral Completed',
        message: 'Referral for ${referral.referralReason} has been completed',
        relatedId: referralId,
      );

      _setLoading(false);
      await loadStatistics();

      if (kDebugMode) {
        print('✅ ReferralProvider: Referral completed successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ReferralProvider: Failed to complete referral - $e');
      }
      _setError('Failed to complete referral: $e');
      _setLoading(false);
      return false;
    }
  }

  // Load referral by ID
  Future<void> loadReferralById(String referralId) async {
    if (kDebugMode) {
      print('🔍 ReferralProvider: Loading referral by ID: $referralId');
    }

    _setLoading(true);
    _setError(null);

    try {
      final doc = await _firestore
          .collection('referrals')
          .doc(referralId)
          .get();

      if (doc.exists) {
        _selectedReferral = Referral.fromFirestore(doc);
        if (kDebugMode) {
          print('✅ ReferralProvider: Referral loaded successfully');
        }
      } else {
        if (kDebugMode) {
          print('❌ ReferralProvider: Referral not found');
        }
        _setError('Referral not found');
      }

      _setLoading(false);
    } catch (e) {
      if (kDebugMode) {
        print('❌ ReferralProvider: Failed to load referral by ID - $e');
      }
      _setError('Failed to load referral: $e');
      _setLoading(false);
    }
  }

  // Load statistics
  Future<void> loadStatistics() async {
    if (_facilityId == null) {
      if (kDebugMode) {
        print(
          '⚠️ ReferralProvider: Cannot load statistics - facility ID is null',
        );
      }
      return;
    }

    if (kDebugMode) {
      print(
        '📊 ReferralProvider: Loading statistics for facility: $_facilityId',
      );
    }

    try {
      final fromSnapshot = await _firestore
          .collection('referrals')
          .where('referringFacilityId', isEqualTo: _facilityId)
          .get();

      final toSnapshot = await _firestore
          .collection('referrals')
          .where('receivingFacilityId', isEqualTo: _facilityId)
          .get();

      final sentReferrals = fromSnapshot.docs
          .map((doc) => Referral.fromFirestore(doc))
          .toList();
      final receivedReferrals = toSnapshot.docs
          .map((doc) => Referral.fromFirestore(doc))
          .toList();

      _statistics = {
        'total': sentReferrals.length + receivedReferrals.length,
        'sent': sentReferrals.length,
        'received': receivedReferrals.length,
        'pending': [
          ...sentReferrals,
          ...receivedReferrals,
        ].where((r) => r.isPending).length,
        'accepted': [
          ...sentReferrals,
          ...receivedReferrals,
        ].where((r) => r.isAccepted).length,
        'completed': [
          ...sentReferrals,
          ...receivedReferrals,
        ].where((r) => r.isCompleted).length,
        'declined': [
          ...sentReferrals,
          ...receivedReferrals,
        ].where((r) => r.isDeclined).length,
        'urgent': [
          ...sentReferrals,
          ...receivedReferrals,
        ].where((r) => r.isUrgentUrgency).length,
        'overdue': [
          ...sentReferrals,
          ...receivedReferrals,
        ].where((r) => r.isOverdue).length,
      };

      if (kDebugMode) {
        print('📊 ReferralProvider: Statistics loaded:');
        print('   Total: ${_statistics['total']}');
        print('   Sent: ${_statistics['sent']}');
        print('   Received: ${_statistics['received']}');
        print('   Pending: ${_statistics['pending']}');
        print('   Accepted: ${_statistics['accepted']}');
        print('   Completed: ${_statistics['completed']}');
        print('   Declined: ${_statistics['declined']}');
        print('   Urgent: ${_statistics['urgent']}');
        print('   Overdue: ${_statistics['overdue']}');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ ReferralProvider: Failed to load referral statistics - $e');
      }
    }
  }

  // In-memory analytics for dashboards
  Map<String, dynamic> getReferralAnalytics() {
    if (kDebugMode) {
      print('📈 ReferralProvider: Generating referral analytics');
    }

    final all = _referrals;
    if (all.isEmpty) {
      if (kDebugMode) {
        print('📈 ReferralProvider: No referrals available for analytics');
      }
      return {
        'total': 0,
        'acceptanceRateByCHW': <String, double>{},
        'avgProcessingDays': 0.0,
        'declineReasons': <String, int>{},
      };
    }

    // Acceptance rate by CHW
    final Map<String, List<Referral>> byCHW = {};
    for (final r in all) {
      (byCHW[r.referringCHWId] ??= []).add(r);
    }
    final Map<String, double> acceptanceRateByCHW = {};
    byCHW.forEach((chw, list) {
      final accepted = list.where((r) => r.isAccepted).length;
      acceptanceRateByCHW[chw] = list.isEmpty ? 0.0 : accepted / list.length;
    });

    // Avg processing time (for responded referrals)
    final responded = all.where((r) => r.responseDate != null).toList();
    final avgProcessingDays = responded.isEmpty
        ? 0.0
        : responded
                  .map(
                    (r) =>
                        r.responseDate!.difference(r.referralDate).inHours /
                        24.0,
                  )
                  .fold<double>(0.0, (a, b) => a + b) /
              responded.length;

    // Decline reasons
    final Map<String, int> declineReasons = {};
    for (final r in all.where((r) => r.isDeclined)) {
      final key = (r.declineReason ?? 'unspecified').toLowerCase();
      declineReasons[key] = (declineReasons[key] ?? 0) + 1;
    }

    if (kDebugMode) {
      print('📈 ReferralProvider: Analytics generated:');
      print('   Total referrals: ${all.length}');
      print('   CHWs with referrals: ${byCHW.length}');
      print('   Avg processing days: ${avgProcessingDays.toStringAsFixed(2)}');
      print('   Decline reasons: ${declineReasons.keys.length}');
    }

    return {
      'total': all.length,
      'acceptanceRateByCHW': acceptanceRateByCHW,
      'avgProcessingDays': double.parse(avgProcessingDays.toStringAsFixed(2)),
      'declineReasons': declineReasons,
    };
  }

  // Filter methods
  void searchReferrals(String searchTerm) {
    if (kDebugMode) {
      print('🔎 ReferralProvider: Setting search term: "$searchTerm"');
    }
    _searchTerm = searchTerm;
    notifyListeners();
  }

  void filterByPatient(String? patientId) {
    if (kDebugMode) {
      print('👤 ReferralProvider: Setting patient filter: $patientId');
    }
    _selectedPatient = patientId;
    notifyListeners();
  }

  void filterByCHW(String? chwId) {
    if (kDebugMode) {
      print('👩‍⚕️ ReferralProvider: Setting CHW filter: $chwId');
    }
    _selectedCHW = chwId;
    notifyListeners();
  }

  void filterByStatus(String? status) {
    if (kDebugMode) {
      print('📊 ReferralProvider: Setting status filter: $status');
    }
    _selectedStatus = status;
    notifyListeners();
  }

  void filterByUrgency(String? urgency) {
    if (kDebugMode) {
      print('⚠️ ReferralProvider: Setting urgency filter: $urgency');
    }
    _selectedUrgency = urgency;
    notifyListeners();
  }

  void filterByDateRange(DateTimeRange? dateRange) {
    if (kDebugMode) {
      print(
        '📅 ReferralProvider: Setting date range filter: ${dateRange?.start} - ${dateRange?.end}',
      );
    }
    _dateRange = dateRange;
    notifyListeners();
  }

  void clearFilters() {
    if (kDebugMode) {
      print('🧹 ReferralProvider: Clearing all filters');
    }
    _selectedPatient = null;
    _selectedCHW = null;
    _selectedStatus = null;
    _selectedUrgency = null;
    _searchTerm = '';
    _dateRange = null;
    notifyListeners();
  }

  // Selection methods
  void selectReferral(Referral referral) {
    if (kDebugMode) {
      print('📋 ReferralProvider: Selecting referral: ${referral.referralId}');
    }
    _selectedReferral = referral;
    notifyListeners();
  }

  void clearSelectedReferral() {
    if (kDebugMode) {
      print('🧹 ReferralProvider: Clearing selected referral');
    }
    _selectedReferral = null;
    notifyListeners();
  }

  void clearError() {
    if (kDebugMode) {
      print('🧹 ReferralProvider: Clearing error');
    }
    _error = null;
    notifyListeners();
  }

  // Utility methods
  List<Referral> getReferralsByPatient(String patientId) {
    final referrals = _referrals
        .where((referral) => referral.patientId == patientId)
        .toList();

    if (kDebugMode) {
      print(
        '👤 ReferralProvider: Found ${referrals.length} referrals for patient: $patientId',
      );
    }

    return referrals;
  }

  List<Referral> getReferralsByCHW(String chwId) {
    final referrals = _referrals
        .where((referral) => referral.referringCHWId == chwId)
        .toList();

    if (kDebugMode) {
      print(
        '👩‍⚕️ ReferralProvider: Found ${referrals.length} referrals by CHW: $chwId',
      );
    }

    return referrals;
  }

  List<Referral> getSentReferrals() {
    final referrals = _referrals
        .where((referral) => referral.referringFacilityId == _facilityId)
        .toList();

    if (kDebugMode) {
      print('📤 ReferralProvider: Found ${referrals.length} sent referrals');
    }

    return referrals;
  }

  List<Referral> getReceivedReferrals() {
    final referrals = _referrals
        .where((referral) => referral.receivingFacilityId == _facilityId)
        .toList();

    if (kDebugMode) {
      print(
        '📥 ReferralProvider: Found ${referrals.length} received referrals',
      );
    }

    return referrals;
  }

  List<Referral> getPendingReferrals() {
    final referrals = _referrals
        .where((referral) => referral.isPending)
        .toList();

    if (kDebugMode) {
      print('⏳ ReferralProvider: Found ${referrals.length} pending referrals');
    }

    return referrals;
  }

  List<Referral> getUrgentReferrals() {
    final referrals = _referrals
        .where((referral) => referral.isUrgentUrgency)
        .toList();

    if (kDebugMode) {
      print('🚨 ReferralProvider: Found ${referrals.length} urgent referrals');
    }

    return referrals;
  }

  List<Referral> getOverdueReferrals() {
    final referrals = _referrals
        .where((referral) => referral.isOverdue)
        .toList();

    if (kDebugMode) {
      print('⏰ ReferralProvider: Found ${referrals.length} overdue referrals');
    }

    return referrals;
  }

  // Sorting helpers for UI
  String get sortField => _sortField;
  bool get sortDesc => _sortDesc;

  // Get referrals by reason
  Map<String, List<Referral>> getReferralsByReason() {
    final Map<String, List<Referral>> byReason = {};
    for (final referral in _referrals) {
      byReason[referral.referralReason] = [
        ...(byReason[referral.referralReason] ?? []),
        referral,
      ];
    }

    if (kDebugMode) {
      print(
        '📊 ReferralProvider: Referrals grouped by reason (${byReason.length} unique reasons)',
      );
      byReason.forEach((reason, referrals) {
        print('   $reason: ${referrals.length} referrals');
      });
    }

    return byReason;
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
      print('📨 ReferralProvider: Creating CHW notification');
      print('   CHW ID: $chwId');
      print('   Type: $type');
      print('   Title: $title');
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
        print('✅ ReferralProvider: CHW notification created successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ReferralProvider: Failed to create CHW notification - $e');
      }
    }
  }

  // Create facility notification helper
  Future<void> _createFacilityNotification({
    required String facilityId,
    required String type,
    required String title,
    required String message,
    String? relatedId,
    String priority = 'medium',
  }) async {
    if (kDebugMode) {
      print('📨 ReferralProvider: Creating facility notification');
      print('   Facility ID: $facilityId');
      print('   Type: $type');
      print('   Title: $title');
      print('   Priority: $priority');
    }

    try {
      // Get all staff users for the facility
      final staffSnapshot = await _firestore
          .collection('staff_users')
          .where('facilityId', isEqualTo: facilityId)
          .where('status', isEqualTo: 'active')
          .get();

      if (kDebugMode) {
        print(
          '👥 ReferralProvider: Found ${staffSnapshot.docs.length} active staff members',
        );
      }

      final batch = _firestore.batch();

      for (final staffDoc in staffSnapshot.docs) {
        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'userId': staffDoc.id,
          'type': type,
          'title': title,
          'message': message,
          'relatedId': relatedId,
          'priority': priority,
          'status': 'unread',
          'sentAt': FieldValue.serverTimestamp(),
          'isSystemNotification': false,
        });
      }

      await batch.commit();

      if (kDebugMode) {
        print(
          '✅ ReferralProvider: Facility notifications created successfully',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ ReferralProvider: Failed to create facility notifications - $e',
        );
      }
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    if (kDebugMode) {
      print('⏳ ReferralProvider: Setting loading state: $loading');
    }
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    if (kDebugMode) {
      print('❌ ReferralProvider: Setting error: $error');
    }
    _error = error;
    notifyListeners();
  }

  // Helper getters for UI
  bool get hasActiveFilters {
    return _selectedPatient != null ||
        _selectedCHW != null ||
        _selectedStatus != null ||
        _selectedUrgency != null ||
        _searchTerm.isNotEmpty ||
        _dateRange != null;
  }

  int get totalReferralsCount => _referrals.length;
  int get filteredReferralsCount => filteredReferrals.length;

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
    if (_selectedCHW != null) {
      final chw = _chwUsers.firstWhere(
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
    if (_selectedUrgency != null) {
      filters.add('Urgency: $_selectedUrgency');
    }
    if (_dateRange != null) {
      filters.add(
        'Date: ${_dateRange!.start.toString().split(' ')[0]} - ${_dateRange!.end.toString().split(' ')[0]}',
      );
    }

    if (kDebugMode && filters.isNotEmpty) {
      print('🏷️ ReferralProvider: Active filters - ${filters.join(', ')}');
    }

    return filters.join(', ');
  }

  @override
  void dispose() {
    if (kDebugMode) {
      print('🗑️ ReferralProvider: Disposing provider');
    }
    super.dispose();
  }
}
