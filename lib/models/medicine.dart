// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

// =================== MEDICATIONS COLLECTION ===================

class Medication {
  final String medicationId;
  final String patientId;
  final String name;
  final String type;
  final String dosage;
  final String frequency;
  final String duration;
  final String instructions;
  final List<String> knownSideEffects;
  final List<String> contraindications;
  final String tbPhase;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;
  final int pillCount; // Add pill count for adherence tracking

  // Convenience getter for ID
  String get id => medicationId;

  Medication({
    required this.medicationId,
    required this.patientId,
    required this.name,
    required this.type,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.instructions,
    required this.knownSideEffects,
    required this.contraindications,
    required this.tbPhase,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
    this.pillCount = 30, // Default pill count
  });

  Map<String, dynamic> toFirestore() {
    return {
      'medicationId': medicationId,
      'patientId': patientId,
      'name': name,
      'type': type,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
      'knownSideEffects': knownSideEffects,
      'contraindications': contraindications,
      'tbPhase': tbPhase,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'pillCount': pillCount,
    };
  }

  factory Medication.fromFirestore(Map<String, dynamic> data, {String? docId}) {
    return Medication(
      medicationId: data['medicationId'] ?? docId ?? '',
      patientId: data['patientId'] ?? '',
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      dosage: data['dosage'] ?? '',
      frequency: data['frequency'] ?? '',
      duration: data['duration'] ?? '',
      instructions: data['instructions'] ?? '',
      knownSideEffects: List<String>.from(data['knownSideEffects'] ?? []),
      contraindications: List<String>.from(data['contraindications'] ?? []),
      tbPhase: data['tbPhase'] ?? '',
      startDate: _parseDateTime(data['startDate']) ?? DateTime.now(),
      endDate: data['endDate'] != null ? _parseDateTime(data['endDate']) : null,
      isActive: data['isActive'] ?? true,
      createdBy: data['createdBy'] ?? '',
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      pillCount: data['pillCount'] ?? 30, // Default to 30 if not specified
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date string: $value, error: $e');
        return null;
      }
    } else if (value is DateTime) {
      return value;
    }
    
    print('Unknown date format: $value (${value.runtimeType})');
    return null;
  }
}

