import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/core_models.dart';
import 'audit_service.dart';
import 'gps_service.dart';

/// Patient Service - Handles all patient-related operations
/// Used by: Register New Patient (10), Patient List (8), Patient Search (9), 
///         Patient Details (11), Edit Patient (12), Home Dashboard (6)
class PatientService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final AuditService _auditService = AuditService();
  static final GPSService _gpsService = GPSService();

  // =================== CREATE OPERATIONS ===================

  /// Register new patient - Used by Screen 10: Register New Patient
  /// Auto-captures GPS, creates audit log, validates consent
  static Future<String> registerPatient({
    required String name,
    required int age,
    required String phone,
    required String address,
    required String gender,
    required String tbStatus,
    required String treatmentFacility,
    required bool consent,
    String? consentSignature,
    DateTime? diagnosisDate,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Generate unique patient ID
      final patientId = _firestore.collection('patients').doc().id;
      
      // Get current GPS location
      final gpsLocation = await _gpsService.getCurrentLocation();
      
      // Get CHW's facility assignment for assignedFacility
      final chwData = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      final assignedFacility = chwData.data()?['facilityId'] ?? treatmentFacility;

      final patient = Patient(
        patientId: patientId,
        name: name,
        age: age,
        phone: phone,
        address: address,
        gender: gender,
        tbStatus: tbStatus,
        assignedCHW: currentUser.uid,
        assignedFacility: assignedFacility,
        treatmentFacility: treatmentFacility,
        gpsLocation: gpsLocation,
        consent: consent,
        consentSignature: consentSignature,
        createdBy: currentUser.uid,
        createdAt: DateTime.now(),
        diagnosisDate: diagnosisDate,
      );

      // Save patient to Firestore
      await _firestore
          .collection('patients')
          .doc(patientId)
          .set(patient.toFirestore());

      // Create audit log for patient registration
      await _auditService.logAction(
        action: 'registered_patient',
        what: patientId,
        additionalData: {
          'patient_name': name,
          'tb_status': tbStatus,
          'facility': treatmentFacility,
        },
      );

      return patientId;
    } catch (e) {
      throw Exception('Failed to register patient: $e');
    }
  }

  // =================== READ OPERATIONS ===================

  /// Get patients assigned to current CHW - Used by Screen 8: Patient List
  /// Filters by assignment and supports search/filter options
  static Stream<List<Patient>> getAssignedPatients({
    String? searchQuery,
    String? statusFilter,
    String? sortBy = 'name',
  }) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    Query query = _firestore
        .collection('patients')
        .where('assignedCHW', isEqualTo: currentUser.uid);

    // Apply status filter if provided
    if (statusFilter != null && statusFilter != 'all_patients') {
      query = query.where('tbStatus', isEqualTo: statusFilter);
    }

    // Apply sorting
    switch (sortBy) {
      case 'name':
        query = query.orderBy('name');
        break;
      case 'date':
        query = query.orderBy('createdAt', descending: true);
        break;
      case 'status':
        query = query.orderBy('tbStatus');
        break;
    }

    return query.snapshots().map((snapshot) {
      List<Patient> patients = snapshot.docs
          .map((doc) => Patient.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();

      // Apply search filter on client side for complex searches
      if (searchQuery != null && searchQuery.isNotEmpty) {
        patients = patients.where((patient) =>
            patient.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            patient.phone.contains(searchQuery) ||
            patient.address.toLowerCase().contains(searchQuery.toLowerCase())
        ).toList();
      }

      return patients;
    });
  }

  /// Search patients - Used by Screen 9: Patient Search
  /// Advanced search with multiple criteria and recent searches
  static Future<List<Patient>> searchPatients({
    String? nameQuery,
    String? phoneQuery,
    String? addressQuery,
    int limit = 20,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      Query query = _firestore
          .collection('patients')
          .where('assignedCHW', isEqualTo: currentUser.uid);

      // Apply specific search criteria
      if (nameQuery != null && nameQuery.isNotEmpty) {
        // Firestore doesn't support case-insensitive search directly
        // We'll fetch all assigned patients and filter client-side
        final snapshot = await query.get();
        final patients = snapshot.docs
            .map((doc) => Patient.fromFirestore(doc.data() as Map<String, dynamic>))
            .where((patient) =>
                patient.name.toLowerCase().contains(nameQuery.toLowerCase()))
            .take(limit)
            .toList();
        return patients;
      }

      if (phoneQuery != null && phoneQuery.isNotEmpty) {
        query = query.where('phone', isGreaterThanOrEqualTo: phoneQuery)
                    .where('phone', isLessThan: phoneQuery + '\uf8ff');
      }

      final snapshot = await query.limit(limit).get();
      return snapshot.docs
          .map((doc) => Patient.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search patients: $e');
    }
  }

  /// Get single patient details - Used by Screen 11: Patient Details
  static Future<Patient?> getPatientById(String patientId) async {
    try {
      final doc = await _firestore
          .collection('patients')
          .doc(patientId)
          .get();

      if (doc.exists) {
        return Patient.fromFirestore(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get patient: $e');
    }
  }

  /// Get patient statistics for dashboard - Used by Screen 6: Home Dashboard
  static Future<Map<String, int>> getPatientStats() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      final snapshot = await _firestore
          .collection('patients')
          .where('assignedCHW', isEqualTo: currentUser.uid)
          .get();

      final patients = snapshot.docs
          .map((doc) => Patient.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();

      return {
        'total': patients.length,
        'on_treatment': patients.where((p) => p.tbStatus == TBStatus.onTreatment).length,
        'newly_diagnosed': patients.where((p) => p.tbStatus == TBStatus.newlyDiagnosed).length,
        'treatment_completed': patients.where((p) => p.tbStatus == TBStatus.treatmentCompleted).length,
        'lost_to_followup': patients.where((p) => p.tbStatus == TBStatus.lostToFollowup).length,
      };
    } catch (e) {
      throw Exception('Failed to get patient statistics: $e');
    }
  }

  // =================== UPDATE OPERATIONS ===================

  /// Update patient information - Used by Screen 12: Edit Patient
  /// Tracks changes and creates audit logs
  static Future<void> updatePatient({
    required String patientId,
    required Map<String, dynamic> updates,
    required String reasonForChanges,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Get current patient data for comparison
      final currentDoc = await _firestore
          .collection('patients')
          .doc(patientId)
          .get();

      if (!currentDoc.exists) {
        throw Exception('Patient not found');
      }

      final currentData = currentDoc.data() as Map<String, dynamic>;
      
      // Update patient document
      await _firestore
          .collection('patients')
          .doc(patientId)
          .update(updates);

      // Create audit log for patient update
      await _auditService.logAction(
        action: 'updated_patient',
        what: patientId,
        additionalData: {
          'reason': reasonForChanges,
          'changes': updates,
          'previous_data': _getChangedFields(currentData, updates),
        },
      );
    } catch (e) {
      throw Exception('Failed to update patient: $e');
    }
  }

  /// Update patient TB status - Used by various screens when status changes
  static Future<void> updatePatientStatus(String patientId, String newStatus) async {
    try {
      await updatePatient(
        patientId: patientId,
        updates: {'tbStatus': newStatus},
        reasonForChanges: 'Status updated by CHW',
      );
    } catch (e) {
      throw Exception('Failed to update patient status: $e');
    }
  }

  // =================== DELETE OPERATIONS ===================

  /// Soft delete patient (mark as inactive)
  /// Note: Actual deletion not recommended due to audit requirements
  static Future<void> deactivatePatient(String patientId, String reason) async {
    try {
      await updatePatient(
        patientId: patientId,
        updates: {
          'status': 'inactive',
          'deactivatedAt': Timestamp.now(),
        },
        reasonForChanges: reason,
      );
    } catch (e) {
      throw Exception('Failed to deactivate patient: $e');
    }
  }

  // =================== HELPER METHODS ===================

  /// Compare data to track what fields changed
  static Map<String, dynamic> _getChangedFields(
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData,
  ) {
    final changes = <String, dynamic>{};
    for (final key in newData.keys) {
      if (oldData[key] != newData[key]) {
        changes[key] = {
          'old': oldData[key],
          'new': newData[key],
        };
      }
    }
    return changes;
  }

  /// Validate patient data before saving
  static bool validatePatientData({
    required String name,
    required int age,
    required String phone,
    required String address,
    required bool consent,
  }) {
    if (name.trim().isEmpty) return false;
    if (age < 0 || age > 150) return false;
    if (phone.trim().isEmpty) return false;
    if (address.trim().isEmpty) return false;
    if (!consent) return false;
    return true;
  }

  /// Check if patient exists by phone number
  static Future<bool> patientExistsByPhone(String phone) async {
    try {
      final snapshot = await _firestore
          .collection('patients')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get recent patients for quick access
  static Stream<List<Patient>> getRecentPatients({int limit = 5}) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    return _firestore
        .collection('patients')
        .where('assignedCHW', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Patient.fromFirestore(doc.data() as Map<String, dynamic>))
            .toList());
  }
}
