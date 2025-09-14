import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/referral.dart';
import '../models/patient.dart';
import '../models/chw_user.dart';
import '../models/facility.dart';

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

  // Filtered referrals
  List<Referral> get filteredReferrals {
    var filtered = _referrals;

    // Filter by facility if set
    if (_facilityId != null) {
      filtered = filtered.where((referral) => 
          referral.referringFacilityId == _facilityId || 
          referral.receivingFacilityId == _facilityId).toList();
    }

    // Filter by patient
    if (_selectedPatient != null && _selectedPatient!.isNotEmpty) {
      filtered = filtered.where((referral) => referral.patientId == _selectedPatient).toList();
    }

    // Filter by CHW
    if (_selectedCHW != null && _selectedCHW!.isNotEmpty) {
      filtered = filtered.where((referral) => referral.referringCHWId == _selectedCHW).toList();
    }

    // Filter by status
    if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
      filtered = filtered.where((referral) => referral.status == _selectedStatus).toList();
    }

    // Filter by urgency
    if (_selectedUrgency != null && _selectedUrgency!.isNotEmpty) {
      filtered = filtered.where((referral) => referral.urgency == _selectedUrgency).toList();
    }

    // Date range filter
    if (_dateRange != null) {
      filtered = filtered.where((referral) =>
          referral.createdAt.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
          referral.createdAt.isBefore(_dateRange!.end.add(const Duration(days: 1)))).toList();
    }

    // Search filter
    if (_searchTerm.isNotEmpty) {
      final searchLower = _searchTerm.toLowerCase();
      filtered = filtered.where((referral) =>
          referral.referralReason.toLowerCase().contains(searchLower) ||
          referral.symptoms?.toLowerCase().contains(searchLower) == true ||
          referral.clinicalNotes?.toLowerCase().contains(searchLower) == true).toList();
    }

    return filtered;
  }

  // Set facility context
  void setFacilityId(String facilityId) {
    _facilityId = facilityId;
    notifyListeners();
  }

  // Load referrals for facility
  Future<void> loadReferrals() async {
    if (_facilityId == null) return;
    
    _setLoading(true);
    _setError(null);

    try {
      // Listen to referrals stream (both sent from and received by this facility)
      _firestore
          .collection('referrals')
          .where('referringFacilityId', isEqualTo: _facilityId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
        (snapshot) {
          final fromReferrals = snapshot.docs
              .map((doc) => Referral.fromFirestore(doc))
              .toList();
          
          // Also get referrals sent TO this facility
          _firestore
              .collection('referrals')
              .where('receivingFacilityId', isEqualTo: _facilityId)
              .orderBy('createdAt', descending: true)
              .snapshots()
              .listen(
            (toSnapshot) {
              final toReferrals = toSnapshot.docs
                  .map((doc) => Referral.fromFirestore(doc))
                  .toList();
              
              // Combine and deduplicate
              final allReferrals = <String, Referral>{};
              for (final referral in [...fromReferrals, ...toReferrals]) {
                allReferrals[referral.referralId] = referral;
              }
              
              _referrals = allReferrals.values.toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              
              _setLoading(false);
              notifyListeners();
            },
          );
        },
        onError: (error) {
          _setError('Failed to load referrals: $error');
          _setLoading(false);
        },
      );
    } catch (e) {
      _setError('Failed to load referrals: $e');
      _setLoading(false);
    }
  }

  // Load patients for facility
  Future<void> loadPatients() async {
    if (_facilityId == null) return;

    try {
      final snapshot = await _firestore
          .collection('patients')
          .where('assignedFacility', isEqualTo: _facilityId)
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

  // Load all facilities for referral options
  Future<void> loadFacilities() async {
    try {
      final snapshot = await _firestore
          .collection('facilities')
          .where('status', isEqualTo: 'active')
          .get();

      _facilities = snapshot.docs
          .map((doc) => Facility.fromFirestore(doc))
          .toList();

      notifyListeners();
    } catch (e) {
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
    if (_facilityId == null) return null;

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

      final docRef = await _firestore
          .collection('referrals')
          .add(referral.toFirestore());

      // Create notification for receiving facility staff
      await _createFacilityNotification(
        facilityId: receivingFacilityId,
        type: 'referral_received',
        title: 'New Patient Referral',
        message: 'New ${referral.urgencyDisplayName} referral for $referralReason',
        relatedId: docRef.id,
        priority: referral.isUrgentUrgency ? 'urgent' : 'medium',
      );

      _setLoading(false);
      await loadStatistics();
      return docRef.id;
    } catch (e) {
      _setError('Failed to create referral: $e');
      _setLoading(false);
      return null;
    }
  }

  // Update referral
  Future<bool> updateReferral(String referralId, Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);

    try {
      await _firestore
          .collection('referrals')
          .doc(referralId)
          .update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update referral: $e');
      _setLoading(false);
      return false;
    }
  }

  // Accept referral
  Future<bool> acceptReferral(String referralId, String acceptedBy, {String? notes}) async {
    _setLoading(true);
    _setError(null);

    try {
      final updateData = {
        'status': Referral.statusAccepted,
        'acceptedBy': acceptedBy,
        'acceptedDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (notes != null && notes.isNotEmpty) {
        updateData['responseNotes'] = notes;
      }

      await _firestore
          .collection('referrals')
          .doc(referralId)
          .update(updateData);

      // Notify referring CHW/facility
      final referral = _referrals.firstWhere((r) => r.referralId == referralId);
      await _createCHWNotification(
        chwId: referral.referringCHWId,
        type: 'referral_accepted',
        title: 'Referral Accepted',
        message: 'Your referral for ${referral.referralReason} has been accepted',
        relatedId: referralId,
      );

      _setLoading(false);
      await loadStatistics();
      return true;
    } catch (e) {
      _setError('Failed to accept referral: $e');
      _setLoading(false);
      return false;
    }
  }

  // Decline referral
  Future<bool> declineReferral(String referralId, String declinedBy, String reason) async {
    _setLoading(true);
    _setError(null);

    try {
      await _firestore
          .collection('referrals')
          .doc(referralId)
          .update({
        'status': Referral.statusDeclined,
        'respondedBy': declinedBy,
        'responseDate': FieldValue.serverTimestamp(),
        'declineReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify referring CHW/facility
      final referral = _referrals.firstWhere((r) => r.referralId == referralId);
      await _createCHWNotification(
        chwId: referral.referringCHWId,
        type: 'referral_declined',
        title: 'Referral Declined',
        message: 'Your referral for ${referral.referralReason} has been declined',
        relatedId: referralId,
        priority: 'high',
      );

      _setLoading(false);
      await loadStatistics();
      return true;
    } catch (e) {
      _setError('Failed to decline referral: $e');
      _setLoading(false);
      return false;
    }
  }

  // Complete referral
  Future<bool> completeReferral(String referralId, String completedBy, {String? outcome}) async {
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
      await _createCHWNotification(
        chwId: referral.referringCHWId,
        type: 'referral_completed',
        title: 'Referral Completed',
        message: 'Referral for ${referral.referralReason} has been completed',
        relatedId: referralId,
      );

      _setLoading(false);
      await loadStatistics();
      return true;
    } catch (e) {
      _setError('Failed to complete referral: $e');
      _setLoading(false);
      return false;
    }
  }

  // Load referral by ID
  Future<void> loadReferralById(String referralId) async {
    _setLoading(true);
    _setError(null);

    try {
      final doc = await _firestore
          .collection('referrals')
          .doc(referralId)
          .get();

      if (doc.exists) {
        _selectedReferral = Referral.fromFirestore(doc);
      } else {
        _setError('Referral not found');
      }
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load referral: $e');
      _setLoading(false);
    }
  }

  // Load statistics
  Future<void> loadStatistics() async {
    if (_facilityId == null) return;

    try {
      final fromSnapshot = await _firestore
          .collection('referrals')
          .where('referringFacilityId', isEqualTo: _facilityId)
          .get();

      final toSnapshot = await _firestore
          .collection('referrals')
          .where('receivingFacilityId', isEqualTo: _facilityId)
          .get();

      final sentReferrals = fromSnapshot.docs.map((doc) => Referral.fromFirestore(doc)).toList();
      final receivedReferrals = toSnapshot.docs.map((doc) => Referral.fromFirestore(doc)).toList();

      _statistics = {
        'total': sentReferrals.length + receivedReferrals.length,
        'sent': sentReferrals.length,
        'received': receivedReferrals.length,
        'pending': [...sentReferrals, ...receivedReferrals].where((r) => r.isPending).length,
        'accepted': [...sentReferrals, ...receivedReferrals].where((r) => r.isAccepted).length,
        'completed': [...sentReferrals, ...receivedReferrals].where((r) => r.isCompleted).length,
        'declined': [...sentReferrals, ...receivedReferrals].where((r) => r.isDeclined).length,
        'urgent': [...sentReferrals, ...receivedReferrals].where((r) => r.isUrgentUrgency).length,
        'overdue': [...sentReferrals, ...receivedReferrals].where((r) => r.isOverdue).length,
      };

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load referral statistics: $e');
      }
    }
  }

  // Filter methods
  void searchReferrals(String searchTerm) {
    _searchTerm = searchTerm;
    notifyListeners();
  }

  void filterByPatient(String? patientId) {
    _selectedPatient = patientId;
    notifyListeners();
  }

  void filterByCHW(String? chwId) {
    _selectedCHW = chwId;
    notifyListeners();
  }

  void filterByStatus(String? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void filterByUrgency(String? urgency) {
    _selectedUrgency = urgency;
    notifyListeners();
  }

  void filterByDateRange(DateTimeRange? dateRange) {
    _dateRange = dateRange;
    notifyListeners();
  }

  void clearFilters() {
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
    _selectedReferral = referral;
    notifyListeners();
  }

  void clearSelectedReferral() {
    _selectedReferral = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Utility methods
  List<Referral> getReferralsByPatient(String patientId) {
    return _referrals.where((referral) => referral.patientId == patientId).toList();
  }

  List<Referral> getReferralsByCHW(String chwId) {
    return _referrals.where((referral) => referral.referringCHWId == chwId).toList();
  }

  List<Referral> getSentReferrals() {
    return _referrals.where((referral) => referral.referringFacilityId == _facilityId).toList();
  }

  List<Referral> getReceivedReferrals() {
    return _referrals.where((referral) => referral.receivingFacilityId == _facilityId).toList();
  }

  List<Referral> getPendingReferrals() {
    return _referrals.where((referral) => referral.isPending).toList();
  }

  List<Referral> getUrgentReferrals() {
    return _referrals.where((referral) => referral.isUrgentUrgency).toList();
  }

  List<Referral> getOverdueReferrals() {
    return _referrals.where((referral) => referral.isOverdue).toList();
  }

  // Get referrals by reason
  Map<String, List<Referral>> getReferralsByReason() {
    final Map<String, List<Referral>> byReason = {};
    for (final referral in _referrals) {
      byReason[referral.referralReason] = [...(byReason[referral.referralReason] ?? []), referral];
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

  // Create facility notification helper
  Future<void> _createFacilityNotification({
    required String facilityId,
    required String type,
    required String title,
    required String message,
    String? relatedId,
    String priority = 'medium',
  }) async {
    try {
      // Get all staff users for the facility
      final staffSnapshot = await _firestore
          .collection('staff_users')
          .where('facilityId', isEqualTo: facilityId)
          .where('status', isEqualTo: 'active')
          .get();

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
    } catch (e) {
      if (kDebugMode) {
        print('Failed to create facility notifications: $e');
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
      final patient = _patients.firstWhere((p) => p.patientId == _selectedPatient, orElse: () => 
          Patient(
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
            createdAt: DateTime.now()
          ));
      filters.add('Patient: ${patient.name}');
    }
    if (_selectedCHW != null) {
      final chw = _chwUsers.firstWhere((c) => c.userId == _selectedCHW, orElse: () => CHWUser(userId: '', name: 'Unknown', email: '', phone: '', workingArea: '', idNumber: '', createdAt: DateTime.now()));
      filters.add('CHW: ${chw.name}');
    }
    if (_selectedStatus != null) {
      filters.add('Status: $_selectedStatus');
    }
    if (_selectedUrgency != null) {
      filters.add('Urgency: $_selectedUrgency');
    }
    if (_dateRange != null) {
      filters.add('Date: ${_dateRange!.start.toString().split(' ')[0]} - ${_dateRange!.end.toString().split(' ')[0]}');
    }
    
    return filters.join(', ');
  }

  @override
  void dispose() {
    super.dispose();
  }
}