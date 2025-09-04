// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chw_tb/config/theme.dart';

class MissedFollowupAlertScreen extends StatefulWidget {
  final Map<String, dynamic>? notificationData;
  
  const MissedFollowupAlertScreen({super.key, this.notificationData});

  @override
  State<MissedFollowupAlertScreen> createState() => _MissedFollowupAlertScreenState();
}

class _MissedFollowupAlertScreenState extends State<MissedFollowupAlertScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = false;
  String _tracingStatus = '';
  String _contactMethod = '';
  String _contactNotes = '';
  DateTime? _nextFollowupDate;
  
  // Patient data
  Map<String, dynamic> _patientData = {};
  List<Map<String, dynamic>> _missedAppointments = [];
  List<Map<String, dynamic>> _contactAttempts = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();
    
    _loadPatientData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _loadPatientData() {
    setState(() => _isLoading = true);
    
    // Mock patient data for missed follow-up
    _patientData = {
      'id': 'PAT001',
      'name': 'Ahmad Khan',
      'age': 35,
      'gender': 'Male',
      'phone': '+92 300 1234567',
      'address': 'House 123, Street 5, Lahore',
      'emergencyContact': '+92 300 7654321',
      'emergencyContactName': 'Fatima Khan (Wife)',
      'treatmentPhase': 'Continuation',
      'lastVisitDate': DateTime(2025, 8, 28),
      'nextAppointmentDate': DateTime(2025, 9, 2),
      'missedVisitsCount': 2,
      'adherenceRate': 85,
    };
    
    _missedAppointments = [
      {
        'date': DateTime(2025, 9, 2),
        'type': 'Regular Follow-up',
        'reason': 'Patient not found at home',
        'attempts': 2,
      },
      {
        'date': DateTime(2025, 8, 30),
        'type': 'Medication Check',
        'reason': 'Phone not reachable',
        'attempts': 3,
      },
    ];
    
    _contactAttempts = [
      {
        'date': DateTime(2025, 9, 3),
        'method': 'Phone Call',
        'status': 'No Answer',
        'notes': 'Phone rings but no one answers',
        'chw': 'Dr. Sarah Ahmed',
      },
      {
        'date': DateTime(2025, 9, 3),
        'method': 'Home Visit',
        'status': 'Not Found',
        'notes': 'Neighbors said family went to village',
        'chw': 'Dr. Sarah Ahmed',
      },
      {
        'date': DateTime(2025, 9, 2),
        'method': 'SMS',
        'status': 'Sent',
        'notes': 'Appointment reminder sent',
        'chw': 'System',
      },
    ];
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MadadgarTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Missed Follow-up Alert',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.red,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => _callEmergencyContact(),
            icon: const Icon(Icons.phone),
            tooltip: 'Call Emergency Contact',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'escalate',
                child: Row(
                  children: [
                    const Icon(Icons.arrow_upward, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('Escalate to Supervisor', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    const Icon(Icons.report),
                    const SizedBox(width: 8),
                    Text('Generate Report', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildPatientHeader(),
                    _buildAlertSummary(),
                    _buildMissedAppointments(),
                    _buildContactAttempts(),
                    _buildTracingActions(),
                    const SizedBox(height: 100), // Space for floating button
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _markAsTraced(),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.check, color: Colors.white),
        label: Text(
          'Mark as Traced',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildPatientHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red, Colors.red.shade400],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _patientData['name'] ?? 'Unknown Patient',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'ID: ${_patientData['id']} • ${_patientData['age']} years • ${_patientData['gender']}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      '${_patientData['treatmentPhase']} Phase',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(Icons.warning, color: Colors.white, size: 20),
                    Text(
                      'URGENT',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildHeaderStat('Missed Visits', '${_patientData['missedVisitsCount']}'),
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildHeaderStat('Days Overdue', '${DateTime.now().difference(_patientData['nextAppointmentDate']).inDays}'),
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildHeaderStat('Adherence', '${_patientData['adherenceRate']}%'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAlertSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    'Alert Summary',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildSummaryRow('Last Visit', _formatDate(_patientData['lastVisitDate'])),
              _buildSummaryRow('Missed Appointment', _formatDate(_patientData['nextAppointmentDate'])),
              _buildSummaryRow('Phone Number', _patientData['phone']),
              _buildSummaryRow('Address', _patientData['address']),
              _buildSummaryRow('Emergency Contact', '${_patientData['emergencyContactName']}\n${_patientData['emergencyContact']}'),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.priority_high, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Patient has missed ${_patientData['missedVisitsCount']} consecutive appointments. Immediate tracing required.',
                        style: GoogleFonts.poppins(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissedAppointments() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event_busy, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Missed Appointments',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              ..._missedAppointments.map((appointment) {
                return _buildMissedAppointmentItem(appointment);
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissedAppointmentItem(Map<String, dynamic> appointment) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  appointment['type'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                _formatDate(appointment['date']),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Reason: ${appointment['reason']}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.orange.shade700,
            ),
          ),
          Text(
            'Contact Attempts: ${appointment['attempts']}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactAttempts() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.contact_phone, color: MadadgarTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Contact Attempts',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              ..._contactAttempts.map((attempt) {
                return _buildContactAttemptItem(attempt);
              }).toList(),
              
              const SizedBox(height: 16),
              
              ElevatedButton.icon(
                onPressed: () => _addContactAttempt(),
                icon: const Icon(Icons.add),
                label: Text(
                  'Add New Contact Attempt',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MadadgarTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactAttemptItem(Map<String, dynamic> attempt) {
    IconData methodIcon = _getContactMethodIcon(attempt['method']);
    Color statusColor = _getContactStatusColor(attempt['status']);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(methodIcon, color: MadadgarTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  attempt['method'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  attempt['status'],
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            attempt['notes'],
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'By: ${attempt['chw']}',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.black54,
                ),
              ),
              const Spacer(),
              Text(
                _formatDateTime(attempt['date']),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTracingActions() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.track_changes, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Tracing Actions',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Quick action buttons
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.5,
                children: [
                  _buildActionButton(
                    'Call Patient',
                    Icons.phone,
                    Colors.green,
                    () => _callPatient(),
                  ),
                  _buildActionButton(
                    'Send SMS',
                    Icons.message,
                    Colors.blue,
                    () => _sendSMS(),
                  ),
                  _buildActionButton(
                    'Home Visit',
                    Icons.home,
                    Colors.orange,
                    () => _scheduleHomeVisit(),
                  ),
                  _buildActionButton(
                    'Emergency Call',
                    Icons.emergency,
                    Colors.red,
                    () => _callEmergencyContact(),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Tracing form
              _buildTracingForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTracingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Record Tracing Outcome',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        
        // Tracing Status
        DropdownButtonFormField<String>(
          value: _tracingStatus.isEmpty ? null : _tracingStatus,
          decoration: InputDecoration(
            labelText: 'Tracing Status',
            labelStyle: GoogleFonts.poppins(),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.assignment_turned_in),
          ),
          items: [
            'Patient Located - Willing to Continue',
            'Patient Located - Refuses Treatment',
            'Patient Not Found',
            'Moved to Unknown Address',
            'Patient Deceased',
            'Transferred to Another Facility'
          ].map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(status, style: GoogleFonts.poppins(fontSize: 12)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _tracingStatus = value ?? '');
          },
        ),
        
        const SizedBox(height: 16),
        
        // Contact Method
        DropdownButtonFormField<String>(
          value: _contactMethod.isEmpty ? null : _contactMethod,
          decoration: InputDecoration(
            labelText: 'Contact Method Used',
            labelStyle: GoogleFonts.poppins(),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.contact_phone),
          ),
          items: [
            'Phone Call',
            'SMS',
            'Home Visit',
            'Emergency Contact',
            'Community Health Worker',
            'Family Member'
          ].map((method) {
            return DropdownMenuItem(
              value: method,
              child: Text(method, style: GoogleFonts.poppins()),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _contactMethod = value ?? '');
          },
        ),
        
        const SizedBox(height: 16),
        
        // Contact Notes
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Notes',
            labelStyle: GoogleFonts.poppins(),
            hintText: 'Describe the contact attempt and outcome...',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.notes),
          ),
          style: GoogleFonts.poppins(),
          maxLines: 3,
          onChanged: (value) => _contactNotes = value,
        ),
        
        const SizedBox(height: 16),
        
        // Next Follow-up Date
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Next Follow-up Date',
            labelStyle: GoogleFonts.poppins(),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.calendar_today),
            suffixIcon: IconButton(
              onPressed: _selectNextFollowupDate,
              icon: const Icon(Icons.date_range),
            ),
          ),
          style: GoogleFonts.poppins(),
          readOnly: true,
          controller: TextEditingController(
            text: _nextFollowupDate != null ? _formatDate(_nextFollowupDate!) : '',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getContactMethodIcon(String method) {
    switch (method) {
      case 'Phone Call':
        return Icons.phone;
      case 'SMS':
        return Icons.message;
      case 'Home Visit':
        return Icons.home;
      default:
        return Icons.contact_phone;
    }
  }

  Color _getContactStatusColor(String status) {
    switch (status) {
      case 'Success':
        return Colors.green;
      case 'No Answer':
        return Colors.orange;
      case 'Not Found':
        return Colors.red;
      case 'Sent':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _selectNextFollowupDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _nextFollowupDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _nextFollowupDate = date);
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'escalate':
        _escalateToSupervisor();
        break;
      case 'report':
        _generateReport();
        break;
    }
  }

  void _callPatient() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${_patientData['phone']}...', style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _sendSMS() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('SMS sent to patient', style: GoogleFonts.poppins()),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _scheduleHomeVisit() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Home visit scheduled', style: GoogleFonts.poppins())),
    );
  }

  void _callEmergencyContact() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling emergency contact...', style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _addContactAttempt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Add contact attempt feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _escalateToSupervisor() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Case escalated to supervisor', style: GoogleFonts.poppins()),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _generateReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generate report feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _markAsTraced() {
    if (_tracingStatus.isEmpty || _contactMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in tracing details', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Use the _contactNotes field
    print('Tracing completed with notes: $_contactNotes');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Patient tracing completed successfully!', style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ),
    );
    
    Navigator.pop(context);
  }
}
