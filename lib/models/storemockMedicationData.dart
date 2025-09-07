// ignore_for_file: avoid_print

import 'package:chw_tb/models/medicine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Function to store mock medication data for testing
Future<void> storeMockMedicationData() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    // Mock patient IDs - replace with actual patient IDs from your system
    final List<String> patientIds = [
      'sM6XsXIrFnJw1dWx4Upb', // The patient ID from your log
      'p002',
      'p003',
    ];

    // Mock medications data
    final List<Medication> mockMedications = [
      // TB Medications for patient 1
      Medication(
        medicationId: 'med001',
        patientId: 'sM6XsXIrFnJw1dWx4Upb',
        name: 'Rifampin (R)',
        type: 'first_line_anti_tb',
        dosage:
            '600mg', // You didn’t give dosage, I assumed common adult TB dose
        frequency: 'once_daily',
        duration:
            '6 months', // Derived from startDate & endDate (Jul 24 → Jan 20 ~ 6 months)
        instructions: 'Take on empty stomach, 30 minutes before breakfast',
        knownSideEffects: [
          'red_orange_urine',
          'red_orange_sweat',
          'nausea',
          'liver_problems',
        ],
        contraindications: [
          'Severe liver disease',
        ], // Not given, added for consistency
        tbPhase: 'intensive_phase',
        startDate: DateTime.parse('2025-07-24T15:21:51+05:00'),
        endDate: DateTime.parse('2026-01-20T15:07:05+05:00'),
        isActive: true,
        createdBy: 'System', // Or the doctor’s name if available
        createdAt:
            DateTime.now(), // You can replace with actual record creation time
        pillCount: 180, // Approx. 6 months daily, adjust as needed
      ),

      // Isoniazid (H)
      Medication(
        medicationId: 'sM6XsXIrFnJw1dWx4Upb',
        patientId: 'p001',
        name: 'Isoniazid (H)',
        type: 'first_line_anti_tb',
        dosage: '300mg',
        frequency: 'once_daily',
        duration: '6 months',
        instructions: 'Take with Rifampin on empty stomach',
        knownSideEffects: [
          'numbness_tingling',
          'liver_problems',
          'vision_changes',
        ],
        contraindications: ['severe_liver_disease', 'peripheral_neuropathy'],
        tbPhase: 'intensive_phase',
        startDate: DateTime.parse('2025-07-24T15:07:05+05:00'),
        endDate: DateTime.parse('2026-01-20T15:07:05+05:00'),
        isActive: true,
        createdBy: 'staff123',
        createdAt: DateTime.parse('2025-07-24T15:07:05.857555'),
        pillCount: 180, // 6 months daily (approx), adjust if exact count needed
      ),

      // Ethambutol (E)
      Medication(
        medicationId: 'sM6XsXIrFnJw1dWx4Upb',
        patientId: 'p001',
        name: 'Ethambutol (E)',
        type: 'first_line_anti_tb',
        dosage: '1200mg',
        frequency: 'once_daily',
        duration: '2 months',
        instructions: 'Take with other TB medicines',
        knownSideEffects: ['vision_changes', 'color_blindness', 'joint_pain'],
        contraindications: ['eye_problems', 'kidney_disease'],
        tbPhase: 'intensive_phase',
        startDate: DateTime.parse('2025-07-24T15:07:05+05:00'),
        endDate: DateTime.parse('2025-09-22T15:07:05+05:00'),
        isActive: true,
        createdBy: 'staff123',
        createdAt: DateTime.parse('2025-07-24T15:07:05.857577'),
        pillCount: 60, // 2 months daily (approx), adjust if exact count needed
      ),
    ];

    // Store each medication in Firestore
    for (Medication medication in mockMedications) {
      await firestore
          .collection('medications')
          .doc(medication.medicationId)
          .set(medication.toFirestore());

      print(
        '✅ Stored medication: ${medication.name} for patient ${medication.patientId}',
      );
    }

    print(
      '\n🎉 Successfully stored ${mockMedications.length} mock medications!',
    );
    print('📊 Breakdown:');
    print(
      '   - Patient ${patientIds[0]}: ${mockMedications.where((m) => m.patientId == patientIds[0]).length} medications',
    );
    print(
      '   - Patient ${patientIds[1]}: ${mockMedications.where((m) => m.patientId == patientIds[1]).length} medications',
    );
    print(
      '   - Patient ${patientIds[2]}: ${mockMedications.where((m) => m.patientId == patientIds[2]).length} medications',
    );
  } catch (e) {
    print('❌ Error storing mock medication data: $e');
    rethrow;
  }
}

// Alternative function to clear all mock data (useful for testing)
Future<void> clearMockMedicationData() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    // Get all medications
    QuerySnapshot snapshot = await firestore.collection('medications').get();

    // Delete each document
    for (QueryDocumentSnapshot doc in snapshot.docs) {
      await doc.reference.delete();
      print('🗑️ Deleted medication: ${doc.id}');
    }

    print('✅ Successfully cleared all medication data');
  } catch (e) {
    print('❌ Error clearing medication data: $e');
    rethrow;
  }
}

// Function to get mock data for a specific patient
Future<List<Medication>> getMockMedicationsForPatient(String patientId) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    QuerySnapshot snapshot = await firestore
        .collection('medications')
        .where('patientId', isEqualTo: patientId)
        .get();

    List<Medication> medications = snapshot.docs
        .map(
          (doc) => Medication.fromFirestore(
            doc.data() as Map<String, dynamic>,
            docId: doc.id,
          ),
        )
        .toList();

    print('📋 Found ${medications.length} medications for patient $patientId');
    return medications;
  } catch (e) {
    print('❌ Error fetching medications for patient $patientId: $e');
    return [];
  }
}
