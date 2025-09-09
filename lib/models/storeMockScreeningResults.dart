// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chw_tb/models/core_models.dart';

/// Store mock screening results data in Firestore
/// This creates sample test results for household members to demonstrate the functionality
Future<void> storeMockScreeningResults() async {
  try {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    
    print('🔬 Starting to store mock screening results...');
    
    // Mock screening results for different household members
    final List<ScreeningResult> mockResults = [
      // Results for Aisha Khan (Wife) - Multiple tests
      ScreeningResult(
        resultId: 'sr_001',
        contactId: 'ct_001',
        contactName: 'Aisha Khan',
        householdId: 'hh_001',
        indexPatientId: 'patient_001',
        testType: 'chest_xray',
        testResult: 'negative',
        testDate: DateTime.now().subtract(const Duration(days: 15)),
        testFacility: 'City General Hospital',
        facilityContact: '+92-300-1234567',
        conductedBy: 'Dr. Sarah Ahmed',
        notes: 'Chest X-ray shows clear lungs with no signs of active TB. Recommended follow-up in 6 months.',
        requiresFollowUp: true,
        nextTestDate: DateTime.now().add(const Duration(days: 180)),
        testDetails: {
          'imageQuality': 'Good',
          'technique': 'PA and Lateral views',
          'findings': 'Normal lung fields, no infiltrates or nodules',
          'recommendation': 'Routine follow-up screening'
        },
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        recordedBy: 'chw_001',
      ),
      
      ScreeningResult(
        resultId: 'sr_002',
        contactId: 'ct_001',
        contactName: 'Aisha Khan',
        householdId: 'hh_001',
        indexPatientId: 'patient_001',
        testType: 'tuberculin_skin_test',
        testResult: 'negative',
        testDate: DateTime.now().subtract(const Duration(days: 10)),
        testFacility: 'Community Health Center',
        facilityContact: '+92-300-9876543',
        conductedBy: 'Nurse Fatima Ali',
        notes: 'TST result: 3mm induration. Negative result indicates no latent TB infection.',
        requiresFollowUp: false,
        testDetails: {
          'injectionDate': DateTime.now().subtract(const Duration(days: 12)).toIso8601String(),
          'readingDate': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
          'indurationSize': '3mm',
          'interpretation': 'Negative - No latent TB'
        },
        createdAt: DateTime.now().subtract(const Duration(days: 9)),
        recordedBy: 'chw_001',
      ),
      
      // Results for Ahmed Khan (Son) - Child screening
      ScreeningResult(
        resultId: 'sr_003',
        contactId: 'ct_002',
        contactName: 'Ahmed Khan',
        householdId: 'hh_001',
        indexPatientId: 'patient_001',
        testType: 'clinical_assessment',
        testResult: 'negative',
        testDate: DateTime.now().subtract(const Duration(days: 7)),
        testFacility: 'Pediatric TB Clinic',
        facilityContact: '+92-300-5555555',
        conductedBy: 'Dr. Zain Hassan (Pediatrician)',
        notes: 'Comprehensive clinical assessment for child contact. No symptoms of active TB. Growth parameters normal.',
        requiresFollowUp: true,
        nextTestDate: DateTime.now().add(const Duration(days: 90)),
        testDetails: {
          'weight': '18kg',
          'height': '110cm',
          'symptoms': 'None reported',
          'appetite': 'Good',
          'activity': 'Normal',
          'schoolAttendance': 'Regular'
        },
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
        recordedBy: 'chw_001',
      ),
      
      // Results for Fatima Khan (Daughter) - Positive case
      ScreeningResult(
        resultId: 'sr_004',
        contactId: 'ct_003',
        contactName: 'Fatima Khan',
        householdId: 'hh_001',
        indexPatientId: 'patient_001',
        testType: 'chest_xray',
        testResult: 'positive',
        testDate: DateTime.now().subtract(const Duration(days: 5)),
        testFacility: 'Provincial TB Hospital',
        facilityContact: '+92-300-7777777',
        conductedBy: 'Dr. Ali Raza (Pulmonologist)',
        notes: 'Chest X-ray shows bilateral upper lobe infiltrates suggestive of pulmonary TB. Immediate treatment initiated.',
        requiresFollowUp: true,
        nextTestDate: DateTime.now().add(const Duration(days: 30)),
        testDetails: {
          'findings': 'Bilateral upper lobe infiltrates with cavitation',
          'severity': 'Moderate',
          'treatmentStarted': true,
          'treatmentDate': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
          'urgency': 'High'
        },
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        recordedBy: 'chw_001',
      ),
      
      ScreeningResult(
        resultId: 'sr_005',
        contactId: 'ct_003',
        contactName: 'Fatima Khan',
        householdId: 'hh_001',
        indexPatientId: 'patient_001',
        testType: 'sputum_microscopy',
        testResult: 'positive',
        testDate: DateTime.now().subtract(const Duration(days: 4)),
        testFacility: 'Provincial TB Hospital',
        facilityContact: '+92-300-7777777',
        conductedBy: 'Lab Technician - Amjad Sheikh',
        notes: 'Sputum microscopy positive for acid-fast bacilli. Confirms active pulmonary tuberculosis.',
        requiresFollowUp: true,
        nextTestDate: DateTime.now().add(const Duration(days: 14)),
        testDetails: {
          'sampleType': '3 morning sputum samples',
          'result': 'AFB Positive (2+)',
          'microscopyGrade': '2+',
          'collectionDate': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
          'processingTime': '24 hours'
        },
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        recordedBy: 'chw_001',
      ),
      
      // Results for Hassan Ali (Brother) - Pending results
      ScreeningResult(
        resultId: 'sr_006',
        contactId: 'ct_004',
        contactName: 'Hassan Ali',
        householdId: 'hh_002',
        indexPatientId: 'patient_001',
        testType: 'interferon_gamma_release',
        testResult: 'pending',
        testDate: DateTime.now().subtract(const Duration(days: 2)),
        testFacility: 'Modern Diagnostic Center',
        facilityContact: '+92-300-8888888',
        conductedBy: 'Dr. Mehreen Qasim',
        notes: 'IGRA test performed. Results expected within 3-5 working days. Patient advised to return for results.',
        requiresFollowUp: true,
        nextTestDate: DateTime.now().add(const Duration(days: 5)),
        testDetails: {
          'testMethod': 'QuantiFERON-TB Gold',
          'bloodDrawnDate': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'expectedResultDate': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
          'testStatus': 'In Progress'
        },
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        recordedBy: 'chw_002',
      ),
      
      // Results for Nadia Bibi (Mother) - Inconclusive
      ScreeningResult(
        resultId: 'sr_007',
        contactId: 'ct_005',
        contactName: 'Nadia Bibi',
        householdId: 'hh_002',
        indexPatientId: 'patient_002',
        testType: 'chest_xray',
        testResult: 'inconclusive',
        testDate: DateTime.now().subtract(const Duration(days: 1)),
        testFacility: 'Regional Hospital',
        facilityContact: '+92-300-9999999',
        conductedBy: 'Dr. Imran Sheikh',
        notes: 'Chest X-ray shows some opacity in right middle lobe. Unable to definitively rule out TB. CT scan recommended.',
        requiresFollowUp: true,
        nextTestDate: DateTime.now().add(const Duration(days: 7)),
        testDetails: {
          'findings': 'Right middle lobe opacity',
          'imageQuality': 'Fair - patient movement',
          'recommendedFollowUp': 'CT chest scan',
          'urgency': 'Medium',
          'additionalTests': 'Sputum culture recommended'
        },
        createdAt: DateTime.now(),
        recordedBy: 'chw_002',
      ),
      
      // Recent results for follow-up cases
      ScreeningResult(
        resultId: 'sr_008',
        contactId: 'ct_006',
        contactName: 'Bilal Ahmed',
        householdId: 'hh_003',
        indexPatientId: 'patient_003',
        testType: 'chest_xray',
        testResult: 'negative',
        testDate: DateTime.now(),
        testFacility: 'District Hospital',
        facilityContact: '+92-300-2222222',
        conductedBy: 'Dr. Rubina Khan',
        notes: 'Follow-up chest X-ray after 3 months of treatment. Significant improvement seen. Continue treatment.',
        requiresFollowUp: true,
        nextTestDate: DateTime.now().add(const Duration(days: 60)),
        testDetails: {
          'comparisonWithPrevious': 'Marked improvement',
          'treatmentResponse': 'Good',
          'treatmentDuration': '3 months',
          'nextMilestone': '6 months completion'
        },
        createdAt: DateTime.now(),
        recordedBy: 'chw_003',
      ),
    ];
    
    // Store each result in Firestore
    for (final result in mockResults) {
      final docRef = firestore.collection('screeningResults').doc(result.resultId);
      batch.set(docRef, result.toFirestore());
      print('📝 Added screening result: ${result.contactName} - ${result.testTypeName} (${result.testResult})');
    }
    
    // Commit the batch
    await batch.commit();
    
    print('✅ Successfully stored ${mockResults.length} mock screening results!');
    print('📊 Results breakdown:');
    print('   • Negative: ${mockResults.where((r) => r.testResult == 'negative').length}');
    print('   • Positive: ${mockResults.where((r) => r.testResult == 'positive').length}');
    print('   • Pending: ${mockResults.where((r) => r.testResult == 'pending').length}');
    print('   • Inconclusive: ${mockResults.where((r) => r.testResult == 'inconclusive').length}');
    
  } catch (e) {
    print('❌ Error storing mock screening results: $e');
    rethrow;
  }
}

/// Clear all mock screening results (useful for testing)
Future<void> clearMockScreeningResults() async {
  try {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    
    final QuerySnapshot snapshot = await firestore.collection('screeningResults').get();
    
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
    print('🗑️ Cleared all mock screening results');
  } catch (e) {
    print('❌ Error clearing mock screening results: $e');
  }
}
