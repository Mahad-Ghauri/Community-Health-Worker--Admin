

// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

// =================== DATA MODELS ===================

// Patient Model - Created by CHWs
class Patient {
  final String patientId;
  final String name;
  final int age;
  final String phone;
  final String address;
  final String tbStatus;
  final String assignedCHW;
  final String assignedFacility;
  final String treatmentFacility;
  final Map<String, double> gpsLocation;
  final bool consent;
  final String createdBy;
  final String? validatedBy;
  final DateTime createdAt;

  Patient({
    required this.patientId,
    required this.name,
    required this.age,
    required this.phone,
    required this.address,
    required this.tbStatus,
    required this.assignedCHW,
    required this.assignedFacility,
    required this.treatmentFacility,
    required this.gpsLocation,
    required this.consent,
    required this.createdBy,
    this.validatedBy,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'name': name,
      'age': age,
      'phone': phone,
      'address': address,
      'tbStatus': tbStatus,
      'assignedCHW': assignedCHW,
      'assignedFacility': assignedFacility,
      'treatmentFacility': treatmentFacility,
      'gpsLocation': gpsLocation,
      'consent': consent,
      'createdBy': createdBy,
      'validatedBy': validatedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// Visit Model - Created by CHWs
class Visit {
  final String visitId;
  final String patientId;
  final String chwId;
  final String visitType;
  final DateTime date;
  final bool found;
  final String notes;
  final Map<String, double> gpsLocation;

  Visit({
    required this.visitId,
    required this.patientId,
    required this.chwId,
    required this.visitType,
    required this.date,
    required this.found,
    required this.notes,
    required this.gpsLocation,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'visitId': visitId,
      'patientId': patientId,
      'chwId': chwId,
      'visitType': visitType,
      'date': date.toIso8601String(),
      'found': found,
      'notes': notes,
      'gpsLocation': gpsLocation,
    };
  }
}

// Household Model - Created by CHWs
class Household {
  final String householdId;
  final String patientId;
  final String address;
  final int totalMembers;
  final int screenedMembers;
  final List<Map<String, dynamic>> members;

  Household({
    required this.householdId,
    required this.patientId,
    required this.address,
    required this.totalMembers,
    required this.screenedMembers,
    required this.members,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'householdId': householdId,
      'patientId': patientId,
      'address': address,
      'totalMembers': totalMembers,
      'screenedMembers': screenedMembers,
      'members': members,
    };
  }
}

// Treatment Adherence Model - Created by CHWs
class TreatmentAdherence {
  final String adherenceId;
  final String patientId;
  final String visitId;
  final DateTime date;
  final String reportedBy;
  final Map<String, String> dosesToday;
  final List<String> sideEffects;
  final int pillsRemaining;
  final double adherenceScore;
  final bool counselingGiven;
  final String notes;

  TreatmentAdherence({
    required this.adherenceId,
    required this.patientId,
    required this.visitId,
    required this.date,
    required this.reportedBy,
    required this.dosesToday,
    required this.sideEffects,
    required this.pillsRemaining,
    required this.adherenceScore,
    required this.counselingGiven,
    required this.notes,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'adherenceId': adherenceId,
      'patientId': patientId,
      'visitId': visitId,
      'date': date.toIso8601String(),
      'reportedBy': reportedBy,
      'dosesToday': dosesToday,
      'sideEffects': sideEffects,
      'pillsRemaining': pillsRemaining,
      'adherenceScore': adherenceScore,
      'counselingGiven': counselingGiven,
      'notes': notes,
    };
  }
}

// Contact Tracing Model - Created by CHWs
class ContactTracing {
  final String contactId;
  final String householdId;
  final String indexPatientId;
  final String contactName;
  final String relationship;
  final int age;
  final String gender;
  final DateTime screeningDate;
  final String screenedBy;
  final List<String> symptoms;
  final String testResult;
  final bool referralNeeded;
  final String notes;

  ContactTracing({
    required this.contactId,
    required this.householdId,
    required this.indexPatientId,
    required this.contactName,
    required this.relationship,
    required this.age,
    required this.gender,
    required this.screeningDate,
    required this.screenedBy,
    required this.symptoms,
    required this.testResult,
    required this.referralNeeded,
    required this.notes,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'contactId': contactId,
      'householdId': householdId,
      'indexPatientId': indexPatientId,
      'contactName': contactName,
      'relationship': relationship,
      'age': age,
      'gender': gender,
      'screeningDate': screeningDate.toIso8601String(),
      'screenedBy': screenedBy,
      'symptoms': symptoms,
      'testResult': testResult,
      'referralNeeded': referralNeeded,
      'notes': notes,
    };
  }
}

// Audit Log Model - Created by CHWs (for their actions)
class AuditLog {
  final String logId;
  final String action;
  final String who;
  final String what;
  final DateTime when;
  final Map<String, double>? where;

  AuditLog({
    required this.logId,
    required this.action,
    required this.who,
    required this.what,
    required this.when,
    this.where,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'logId': logId,
      'action': action,
      'who': who,
      'what': what,
      'when': when.toIso8601String(),
      'where': where,
    };
  }
}

// =================== DUMMY DATA SERVICE ===================

class DummyDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Dummy Facilities (created by admin but needed for CHW dropdown)
  static Future<void> createDummyFacilities() async {
    final facilities = [
      {
        'facilityId': 'fac001',
        'name': 'District TB Hospital',
        'type': 'hospital',
        'location': {
          'address': 'Main Street, Karachi',
          'district': 'District Central',
          'region': 'Sindh',
          'gps': {'lat': 24.8607, 'lng': 67.0011}
        },
        'contact': {
          'phone': '+92-21-99211234',
          'email': 'info@districthosp.gov.pk'
        },
        'staff': ['staff123', 'staff456'],
        'supervisors': ['sup001'],
        'services': ['tb_treatment', 'xray', 'lab_tests'],
        'isActive': true,
        'createdBy': 'admin123',
        'createdAt': DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
      },
      {
        'facilityId': 'fac002',
        'name': 'Gulshan Health Center',
        'type': 'health_center',
        'location': {
          'address': 'Gulshan-e-Iqbal, Karachi',
          'district': 'District East',
          'region': 'Sindh',
          'gps': {'lat': 24.9056, 'lng': 67.1000}
        },
        'contact': {
          'phone': '+92-21-99225678',
          'email': 'gulshan@health.gov.pk'
        },
        'staff': ['staff789'],
        'supervisors': ['sup002'],
        'services': ['tb_treatment', 'lab_tests'],
        'isActive': true,
        'createdBy': 'admin123',
        'createdAt': DateTime.now().subtract(Duration(days: 25)).toIso8601String(),
      },
      {
        'facilityId': 'fac003',
        'name': 'Clifton Medical Center',
        'type': 'clinic',
        'location': {
          'address': 'Clifton Block 2, Karachi',
          'district': 'District South',
          'region': 'Sindh',
          'gps': {'lat': 24.8138, 'lng': 67.0299}
        },
        'contact': {
          'phone': '+92-21-99234567',
          'email': 'clifton@medical.gov.pk'
        },
        'staff': ['staff101'],
        'supervisors': ['sup003'],
        'services': ['tb_treatment', 'xray'],
        'isActive': true,
        'createdBy': 'admin123',
        'createdAt': DateTime.now().subtract(Duration(days: 20)).toIso8601String(),
      },
    ];

    for (var facility in facilities) {
      await _firestore
          .collection('facilities')
          .doc(facility['facilityId'].toString())
          .set(facility);
    }
    print('✅ Dummy facilities created');
  }

  // Dummy Patients (created by CHWs)
  static Future<void> createDummyPatients() async {
    final patients = [
      Patient(
        patientId: 'p001',
        name: 'Fatima Ahmed',
        age: 35,
        phone: '+92-300-1234567',
        address: 'House 123, Gulshan-e-Iqbal, Karachi',
        tbStatus: 'on_treatment',
        assignedCHW: 'chw123',
        assignedFacility: 'fac001',
        treatmentFacility: 'fac001',
        gpsLocation: {'lat': 24.9056, 'lng': 67.1000},
        consent: true,
        createdBy: 'chw123',
        validatedBy: 'staff123',
        createdAt: DateTime.now().subtract(Duration(days: 15)),
      ),
      Patient(
        patientId: 'p002',
        name: 'Muhammad Ali',
        age: 42,
        phone: '+92-301-2345678',
        address: 'Flat 45, Clifton Block 5, Karachi',
        tbStatus: 'newly_diagnosed',
        assignedCHW: 'chw123',
        assignedFacility: 'fac002',
        treatmentFacility: 'fac002',
        gpsLocation: {'lat': 24.8138, 'lng': 67.0299},
        consent: true,
        createdBy: 'chw123',
        createdAt: DateTime.now().subtract(Duration(days: 10)),
      ),
      Patient(
        patientId: 'p003',
        name: 'Aisha Khan',
        age: 28,
        phone: '+92-302-3456789',
        address: 'Street 15, North Nazimabad, Karachi',
        tbStatus: 'on_treatment',
        assignedCHW: 'chw456',
        assignedFacility: 'fac003',
        treatmentFacility: 'fac003',
        gpsLocation: {'lat': 24.9300, 'lng': 67.0800},
        consent: true,
        createdBy: 'chw456',
        validatedBy: 'staff456',
        createdAt: DateTime.now().subtract(Duration(days: 8)),
      ),
    ];

    for (var patient in patients) {
      await _firestore
          .collection('patients')
          .doc(patient.patientId)
          .set(patient.toFirestore());
    }
    print('✅ Dummy patients created');
  }

  // Dummy Visits (created by CHWs)
  static Future<void> createDummyVisits() async {
    final visits = [
      Visit(
        visitId: 'v001',
        patientId: 'p001',
        chwId: 'chw123',
        visitType: 'home_visit',
        date: DateTime.now().subtract(Duration(days: 5)),
        found: true,
        notes: 'Patient taking medicine regularly. No side effects reported.',
        gpsLocation: {'lat': 24.9056, 'lng': 67.1000},
      ),
      Visit(
        visitId: 'v002',
        patientId: 'p002',
        chwId: 'chw123',
        visitType: 'follow_up',
        date: DateTime.now().subtract(Duration(days: 3)),
        found: false,
        notes: 'Patient not at home. Will try again tomorrow.',
        gpsLocation: {'lat': 24.8138, 'lng': 67.0299},
      ),
      Visit(
        visitId: 'v003',
        patientId: 'p003',
        chwId: 'chw456',
        visitType: 'tracing',
        date: DateTime.now().subtract(Duration(days: 1)),
        found: true,
        notes: 'Found patient. Missed appointment due to work. Counseled about importance.',
        gpsLocation: {'lat': 24.9300, 'lng': 67.0800},
      ),
    ];

    for (var visit in visits) {
      await _firestore
          .collection('visits')
          .doc(visit.visitId)
          .set(visit.toFirestore());
    }
    print('✅ Dummy visits created');
  }

  // Dummy Households (created by CHWs)
  static Future<void> createDummyHouseholds() async {
    final households = [
      Household(
        householdId: 'h001',
        patientId: 'p001',
        address: 'House 123, Gulshan-e-Iqbal, Karachi',
        totalMembers: 4,
        screenedMembers: 3,
        members: [
          {
            'name': 'Ahmed Ali (Husband)',
            'age': 38,
            'screened': true,
            'result': 'negative'
          },
          {
            'name': 'Sara Ahmed (Daughter)',
            'age': 12,
            'screened': true,
            'result': 'negative'
          },
          {
            'name': 'Omar Ahmed (Son)',
            'age': 8,
            'screened': true,
            'result': 'negative'
          },
          {
            'name': 'Baby Zain (Son)',
            'age': 2,
            'screened': false,
            'result': 'not_tested'
          }
        ],
      ),
      Household(
        householdId: 'h002',
        patientId: 'p002',
        address: 'Flat 45, Clifton Block 5, Karachi',
        totalMembers: 3,
        screenedMembers: 2,
        members: [
          {
            'name': 'Khadija Ali (Wife)',
            'age': 35,
            'screened': true,
            'result': 'negative'
          },
          {
            'name': 'Hassan Ali (Son)',
            'age': 15,
            'screened': true,
            'result': 'negative'
          },
          {
            'name': 'Maryam Ali (Daughter)',
            'age': 10,
            'screened': false,
            'result': 'not_tested'
          }
        ],
      ),
    ];

    for (var household in households) {
      await _firestore
          .collection('households')
          .doc(household.householdId)
          .set(household.toFirestore());
    }
    print('✅ Dummy households created');
  }

  // Dummy Treatment Adherence (created by CHWs)
  static Future<void> createDummyAdherence() async {
    final adherenceRecords = [
      TreatmentAdherence(
        adherenceId: 'adh001',
        patientId: 'p001',
        visitId: 'v001',
        date: DateTime.now().subtract(Duration(days: 1)),
        reportedBy: 'chw123',
        dosesToday: {
          'morning': 'taken',
          'evening': 'taken'
        },
        sideEffects: [],
        pillsRemaining: 45,
        adherenceScore: 95.0,
        counselingGiven: true,
        notes: 'Patient very compliant with treatment',
      ),
      TreatmentAdherence(
        adherenceId: 'adh002',
        patientId: 'p003',
        visitId: 'v003',
        date: DateTime.now().subtract(Duration(days: 1)),
        reportedBy: 'chw456',
        dosesToday: {
          'morning': 'taken',
          'evening': 'missed'
        },
        sideEffects: ['nausea'],
        pillsRemaining: 38,
        adherenceScore: 80.0,
        counselingGiven: true,
        notes: 'Patient experiencing mild nausea, advised to take with food',
      ),
    ];

    for (var adherence in adherenceRecords) {
      await _firestore
          .collection('treatmentAdherence')
          .doc(adherence.adherenceId)
          .set(adherence.toFirestore());
    }
    print('✅ Dummy adherence records created');
  }

  // Dummy Contact Tracing (created by CHWs)
  static Future<void> createDummyContactTracing() async {
    final contacts = [
      ContactTracing(
        contactId: 'contact001',
        householdId: 'h001',
        indexPatientId: 'p001',
        contactName: 'Ahmed Ali',
        relationship: 'husband',
        age: 38,
        gender: 'male',
        screeningDate: DateTime.now().subtract(Duration(days: 12)),
        screenedBy: 'chw123',
        symptoms: [],
        testResult: 'negative',
        referralNeeded: false,
        notes: 'No symptoms, chest X-ray normal',
      ),
      ContactTracing(
        contactId: 'contact002',
        householdId: 'h001',
        indexPatientId: 'p001',
        contactName: 'Sara Ahmed',
        relationship: 'daughter',
        age: 12,
        gender: 'female',
        screeningDate: DateTime.now().subtract(Duration(days: 10)),
        screenedBy: 'chw123',
        symptoms: ['cough'],
        testResult: 'negative',
        referralNeeded: false,
        notes: 'Had mild cough but tested negative, advised to return if symptoms persist',
      ),
    ];

    for (var contact in contacts) {
      await _firestore
          .collection('contactTracing')
          .doc(contact.contactId)
          .set(contact.toFirestore());
    }
    print('✅ Dummy contact tracing records created');
  }

  // Dummy Follow-ups (created by admin/staff but CHWs need to see)
  static Future<void> createDummyFollowups() async {
    final followups = [
      {
        'followupId': 'f001',
        'patientId': 'p001',
        'scheduledDate': DateTime.now().add(Duration(days: 7)).toIso8601String(),
        'status': 'scheduled',
        'facility': 'District TB Hospital',
        'notes': 'Monthly check-up and medicine refill'
      },
      {
        'followupId': 'f002',
        'patientId': 'p002',
        'scheduledDate': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
        'status': 'missed',
        'facility': 'Gulshan Health Center',
        'notes': 'Patient missed appointment - needs tracing'
      },
      {
        'followupId': 'f003',
        'patientId': 'p003',
        'scheduledDate': DateTime.now().add(Duration(days: 3)).toIso8601String(),
        'status': 'scheduled',
        'facility': 'Clifton Medical Center',
        'notes': 'Follow-up for side effects monitoring'
      },
    ];

    for (var followup in followups) {
      await _firestore
          .collection('followups')
          .doc(followup['followupId'].toString())
          .set(followup);
    }
    print('✅ Dummy followups created');
  }

  // Dummy Notifications (for CHWs)
  static Future<void> createDummyNotifications() async {
    final notifications = [
      {
        'notificationId': 'notif001',
        'userId': 'chw123',
        'type': 'missed_followup',
        'title': 'Patient Missed Appointment',
        'message': 'Muhammad Ali missed his follow-up at Gulshan Health Center',
        'relatedId': 'p002',
        'priority': 'high',
        'status': 'unread',
        'sentAt': DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
        'readAt': null
      },
      {
        'notificationId': 'notif002',
        'userId': 'chw456',
        'type': 'new_assignment',
        'title': 'New Patient Assigned',
        'message': 'New patient Aisha Khan has been assigned to you',
        'relatedId': 'p003',
        'priority': 'medium',
        'status': 'read',
        'sentAt': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
        'readAt': DateTime.now().subtract(Duration(hours: 20)).toIso8601String()
      },
      {
        'notificationId': 'notif003',
        'userId': 'chw123',
        'type': 'reminder',
        'title': 'Visit Reminder',
        'message': 'Remember to visit Fatima Ahmed today for medicine check',
        'relatedId': 'p001',
        'priority': 'medium',
        'status': 'unread',
        'sentAt': DateTime.now().subtract(Duration(minutes: 30)).toIso8601String(),
        'readAt': null
      },
    ];

    for (var notification in notifications) {
      await _firestore
          .collection('notifications')
          .doc(notification['notificationId'].toString())
          .set(notification);
    }
    print('✅ Dummy notifications created');
  }

  // Dummy Audit Logs (created by CHWs actions)
  static Future<void> createDummyAuditLogs() async {
    final auditLogs = [
      AuditLog(
        logId: 'log001',
        action: 'registered_patient',
        who: 'chw123',
        what: 'p001',
        when: DateTime.now().subtract(Duration(days: 15)),
        where: {'lat': 24.9056, 'lng': 67.1000},
      ),
      AuditLog(
        logId: 'log002',
        action: 'home_visit',
        who: 'chw123',
        what: 'v001',
        when: DateTime.now().subtract(Duration(days: 5)),
        where: {'lat': 24.9056, 'lng': 67.1000},
      ),
      AuditLog(
        logId: 'log003',
        action: 'contact_screening',
        who: 'chw123',
        what: 'contact001',
        when: DateTime.now().subtract(Duration(days: 12)),
        where: {'lat': 24.9056, 'lng': 67.1000},
      ),
    ];

    for (var log in auditLogs) {
      await _firestore
          .collection('auditLogs')
          .doc(log.logId)
          .set(log.toFirestore());
    }
    print('✅ Dummy audit logs created');
  }

  // Master function to create all dummy data
  static Future<void> createAllDummyData() async {
    try {
      print('🚀 Creating dummy data for CHW TB App...');
      
      await createDummyFacilities();
      await createDummyPatients();
      await createDummyVisits();
      await createDummyHouseholds();
      await createDummyAdherence();
      await createDummyContactTracing();
      await createDummyFollowups();
      await createDummyNotifications();
      await createDummyAuditLogs();
      
      print('✅ All dummy data created successfully!');
      print('📱 Ready to test CHW TB App');
      
    } catch (e) {
      print('❌ Error creating dummy data: $e');
    }
  }
}

// =================== USAGE EXAMPLE ===================

// Call this function in your main.dart or wherever you initialize your app
// DummyDataService.createAllDummyData();

// Example of how to call this in main.dart:
/*
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Create dummy data (call only once for testing)
  // await DummyDataService.createAllDummyData();
  
  runApp(MyApp());
}
*/