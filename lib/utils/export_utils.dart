import '../models/patient.dart';
import '../models/audit_log.dart';

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

  static String generateAuditLogsCsv(List<AuditLog> auditLogs) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Log ID,Action,Who (CHW ID),What (Entity ID),When,Where (GPS),User Name,User Role,Entity Type,Description,Severity,IP Address',
    );
    for (final log in auditLogs) {
      final whereLocation = log.where != null
          ? '${log.where!['latitude']},${log.where!['longitude']}'
          : '';
      
      final row = [
        _csvEscape(log.logId),
        _csvEscape(log.action),
        _csvEscape(log.who),
        _csvEscape(log.what),
        _csvEscape(log.when.toIso8601String()),
        _csvEscape(whereLocation),
        _csvEscape(log.userName),
        _csvEscape(log.userRole),
        _csvEscape(log.entityDisplayName),
        _csvEscape(log.description ?? ''),
        _csvEscape(log.severity.name.toUpperCase()),
        _csvEscape(log.ipAddress ?? ''),
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
