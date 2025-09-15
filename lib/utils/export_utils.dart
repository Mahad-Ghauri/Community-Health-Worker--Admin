import '../models/patient.dart';

class ExportUtils {
  static String generatePatientsCsv(List<Patient> patients) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Patient ID,Name,Age,Gender,Phone,Address,TB Status,Assigned CHW,Treatment Facility,Diagnosis Date,Created At',
    );
    for (final p in patients) {
      final row = [
        _csvEscape(p.patientId),
        _csvEscape(p.name),
        p.age.toString(),
        _csvEscape(p.gender),
        _csvEscape(p.phone),
        _csvEscape(p.address),
        _csvEscape(p.tbStatus),
        _csvEscape(p.assignedCHW),
        _csvEscape(p.treatmentFacility),
        _csvEscape(p.diagnosisDate?.toIso8601String() ?? ''),
        _csvEscape(p.createdAt.toIso8601String()),
      ].join(',');
      buffer.writeln(row);
    }
    return buffer.toString();
  }

  static String _csvEscape(String value) {
    final needsEscaping =
        value.contains(',') || value.contains('"') || value.contains('\n');
    var v = value.replaceAll('"', '""');
    return needsEscaping ? '"$v"' : v;
  }
}
