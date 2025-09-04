import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/core_models.dart';
import 'gps_service.dart';

/// Audit Service - Handles all system audit logging
/// Used by: All screens that create/modify data (10, 12, 14, 17, 18, 20)
/// Automatically logs CHW actions for compliance and tracking
class AuditService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GPSService _gpsService = GPSService();

  /// Log any CHW action with automatic GPS capture
  /// Used by all services when CHWs create/update data
  Future<void> logAction({
    required String action,
    required String what,
    Map<String, dynamic>? additionalData,
    bool captureGPS = true,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return; // Silent fail for audit logs

      // Generate unique log ID
      final logId = _firestore.collection('auditLogs').doc().id;
      
      // Get GPS location if requested
      Map<String, double>? gpsLocation;
      if (captureGPS) {
        try {
          gpsLocation = await _gpsService.getCurrentLocation();
        } catch (e) {
          // Continue without GPS if location fails
          gpsLocation = null;
        }
      }

      final auditLog = AuditLog(
        logId: logId,
        action: action,
        who: currentUser.uid,
        what: what,
        when: DateTime.now(),
        where: gpsLocation,
        additionalData: additionalData,
      );

      // Save audit log to Firestore
      await _firestore
          .collection('auditLogs')
          .doc(logId)
          .set(auditLog.toFirestore());

    } catch (e) {
      // Silent fail for audit logs to not disrupt main operations
      print('Audit log failed: $e');
    }
  }

  /// Log patient registration action
  /// Used by: Register New Patient Screen (Screen 10)
  Future<void> logPatientRegistration(String patientId, Map<String, dynamic> patientData) async {
    await logAction(
      action: 'registered_patient',
      what: patientId,
      additionalData: {
        'patient_name': patientData['name'],
        'tb_status': patientData['tbStatus'],
        'facility': patientData['treatmentFacility'],
        'consent_given': patientData['consent'],
      },
    );
  }

  /// Log patient update action
  /// Used by: Edit Patient Screen (Screen 12)
  Future<void> logPatientUpdate(String patientId, Map<String, dynamic> changes, String reason) async {
    await logAction(
      action: 'updated_patient',
      what: patientId,
      additionalData: {
        'changes': changes,
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log home visit action
  /// Used by: New Visit Screen (Screen 14)
  Future<void> logHomeVisit(String visitId, Map<String, dynamic> visitData) async {
    await logAction(
      action: 'home_visit',
      what: visitId,
      additionalData: {
        'patient_id': visitData['patientId'],
        'visit_type': visitData['visitType'],
        'patient_found': visitData['found'],
        'visit_notes': visitData['notes'],
      },
    );
  }

  /// Log household member addition
  /// Used by: Add Household Member Screen (Screen 17)
  Future<void> logHouseholdMemberAdded(String householdId, Map<String, dynamic> memberData) async {
    await logAction(
      action: 'added_household_member',
      what: householdId,
      additionalData: {
        'member_name': memberData['name'],
        'relationship': memberData['relationship'],
        'age': memberData['age'],
      },
    );
  }

  /// Log contact screening action
  /// Used by: Contact Screening Screen (Screen 18)
  Future<void> logContactScreening(String contactId, Map<String, dynamic> screeningData) async {
    await logAction(
      action: 'contact_screening',
      what: contactId,
      additionalData: {
        'contact_name': screeningData['contactName'],
        'symptoms_found': screeningData['symptoms'],
        'test_result': screeningData['testResult'],
        'referral_needed': screeningData['referralNeeded'],
      },
    );
  }

  /// Log adherence tracking action
  /// Used by: Adherence Tracking Screen (Screen 20)
  Future<void> logAdherenceTracking(String adherenceId, Map<String, dynamic> adherenceData) async {
    await logAction(
      action: 'adherence_tracking',
      what: adherenceId,
      additionalData: {
        'patient_id': adherenceData['patientId'],
        'doses_today': adherenceData['dosesToday'],
        'side_effects': adherenceData['sideEffects'],
        'adherence_score': adherenceData['adherenceScore'],
        'counseling_given': adherenceData['counselingGiven'],
      },
    );
  }

  /// Log user authentication action
  /// Used by: Login/Registration processes
  Future<void> logUserAction(String action, Map<String, dynamic>? additionalData) async {
    await logAction(
      action: action,
      what: 'user_session',
      additionalData: additionalData,
      captureGPS: false, // Don't capture GPS for auth actions
    );
  }

  /// Get audit trail for specific entity (patient, visit, etc.)
  /// Used by: System monitoring and compliance reporting
  Future<List<AuditLog>> getAuditTrail({
    required String entityId,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('auditLogs')
          .where('what', isEqualTo: entityId)
          .orderBy('when', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => AuditLog.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get audit trail: $e');
    }
  }

  /// Get CHW activity summary for reporting
  /// Used by: Reports Screen (Screen 27)
  Future<Map<String, dynamic>> getCHWActivitySummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      Query query = _firestore
          .collection('auditLogs')
          .where('who', isEqualTo: currentUser.uid);

      if (startDate != null) {
        query = query.where('when', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('when', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      final logs = snapshot.docs
          .map((doc) => AuditLog.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();

      // Aggregate activity data
      final summary = <String, dynamic>{
        'total_actions': logs.length,
        'patients_registered': 0,
        'visits_conducted': 0,
        'contacts_screened': 0,
        'adherence_tracked': 0,
        'actions_by_date': <String, int>{},
      };

      for (final log in logs) {
        // Count specific actions
        switch (log.action) {
          case 'registered_patient':
            summary['patients_registered']++;
            break;
          case 'home_visit':
            summary['visits_conducted']++;
            break;
          case 'contact_screening':
            summary['contacts_screened']++;
            break;
          case 'adherence_tracking':
            summary['adherence_tracked']++;
            break;
        }

        // Group by date
        final dateKey = log.when.toIso8601String().split('T')[0];
        summary['actions_by_date'][dateKey] = 
            (summary['actions_by_date'][dateKey] ?? 0) + 1;
      }

      return summary;
    } catch (e) {
      throw Exception('Failed to get CHW activity summary: $e');
    }
  }
}
