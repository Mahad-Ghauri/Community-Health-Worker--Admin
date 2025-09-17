// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_constants.dart';
import '../../../models/patient.dart';
import '../../../theme/theme.dart';
import '../../../utils/responsive_helper.dart';

class PatientDetailsScreen extends StatefulWidget {
  final String patientId;

  const PatientDetailsScreen({Key? key, required this.patientId})
    : super(key: key);

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  Patient? _patient;
  // Legacy placeholders removed; data is loaded per-tab via streams

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // Load patient data
      final patientDoc = await FirebaseFirestore.instance
          .collection(AppConstants.patientsCollection)
          .doc(widget.patientId)
          .get();

      if (!patientDoc.exists) {
        throw Exception('Patient not found');
      }

      final patient = Patient.fromFirestore(patientDoc);

      // Load treatment history (mock data for now)
      // final treatmentHistory = [
      //   {
      //     'date': DateTime.now().subtract(const Duration(days: 60)),
      //     'type': 'Initial Diagnosis',
      //     'notes': 'Patient diagnosed with TB',
      //     'provider': 'Dr. Smith',
      //   },
      //   {
      //     'date': DateTime.now().subtract(const Duration(days: 45)),
      //     'type': 'Treatment Started',
      //     'notes': 'Started on standard regimen',
      //     'provider': 'Dr. Johnson',
      //   },
      //   {
      //     'date': DateTime.now().subtract(const Duration(days: 30)),
      //     'type': 'Follow-up',
      //     'notes': 'Patient responding well to treatment',
      //     'provider': 'Dr. Smith',
      //   },
      //   {
      //     'date': DateTime.now().subtract(const Duration(days: 15)),
      //     'type': 'Medication Adjustment',
      //     'notes': 'Dosage adjusted due to side effects',
      //     'provider': 'Dr. Johnson',
      //   },
      // ];

      // // Load test results (mock data for now)
      // final testResults = [
      //   {
      //     'date': DateTime.now().subtract(const Duration(days: 60)),
      //     'type': 'Sputum Smear',
      //     'result': 'Positive',
      //     'notes': 'AFB 2+',
      //   },
      //   {
      //     'date': DateTime.now().subtract(const Duration(days: 45)),
      //     'type': 'Chest X-Ray',
      //     'result': 'Abnormal',
      //     'notes': 'Infiltrates in right upper lobe',
      //   },
      //   {
      //     'date': DateTime.now().subtract(const Duration(days: 30)),
      //     'type': 'GeneXpert',
      //     'result': 'MTB Detected, Rif Resistance Not Detected',
      //     'notes': 'Sensitive to first-line drugs',
      //   },
      //   {
      //     'date': DateTime.now().subtract(const Duration(days: 15)),
      //     'type': 'Sputum Culture',
      //     'result': 'Positive',
      //     'notes': 'Growth after 14 days',
      //   },
      // ];

      // // Load upcoming appointments (mock data for now)
      // final appointments = [
      //   {
      //     'date': DateTime.now().add(const Duration(days: 7)),
      //     'type': 'Follow-up',
      //     'provider': 'Dr. Smith',
      //     'location': 'Main Clinic',
      //     'status': 'Scheduled',
      //   },
      //   {
      //     'date': DateTime.now().add(const Duration(days: 14)),
      //     'type': 'Sputum Test',
      //     'provider': 'Lab Technician',
      //     'location': 'Laboratory',
      //     'status': 'Scheduled',
      //   },
      //   {
      //     'date': DateTime.now().add(const Duration(days: 30)),
      //     'type': 'Medication Review',
      //     'provider': 'Dr. Johnson',
      //     'location': 'Main Clinic',
      //     'status': 'Scheduled',
      //   },
      // ];

      setState(() {
        _patient = patient;
        // _treatmentHistory = treatmentHistory;
        // _testResults = testResults;
        // _appointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load patient data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CHWTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_patient?.name ?? 'Patient Details'),
        backgroundColor: CHWTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatientData,
            tooltip: 'Refresh Data',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  // Navigate to edit patient screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Edit Patient functionality coming soon'),
                    ),
                  );
                  break;
                case 'delete':
                  _showDeleteConfirmation();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit Patient'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: CHWTheme.errorColor),
                  title: Text(
                    'Delete Patient',
                    style: TextStyle(color: CHWTheme.errorColor),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to add appointment/note screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add Appointment functionality coming soon'),
            ),
          );
        },
        backgroundColor: CHWTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Add Appointment'),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: CHWTheme.errorColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Patient Data',
              style: CHWTheme.headingStyle.copyWith(color: CHWTheme.errorColor),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: CHWTheme.bodyStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPatientData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CHWTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_patient == null) {
      return const Center(child: Text('Patient not found'));
    }

    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient summary card
          _buildPatientSummaryCard(),

          const SizedBox(height: 24),

          // Treatment status
          _buildTreatmentStatusCard(),

          const SizedBox(height: 24),

          // Tabs for different sections (expanded to 6)
          DefaultTabController(
            length: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    labelColor: CHWTheme.primaryColor,
                    unselectedLabelColor: Colors.grey.shade700,
                    indicatorColor: CHWTheme.primaryColor,
                    tabs: const [
                      Tab(text: 'Details'),
                      Tab(text: 'Visits'),
                      Tab(text: 'Medications'),
                      Tab(text: 'Adherence'),
                      Tab(text: 'Follow-ups'),
                      Tab(text: 'Contacts'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 500, // Fixed height for tab content
                  child: TabBarView(
                    children: [
                      _buildDetailsTab(),
                      _buildVisitsTab(),
                      _buildMedicationsTab(),
                      _buildAdherenceTab(),
                      _buildFollowupsTab(),
                      _buildContactsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tab: Details (editable placeholders)
  Widget _buildDetailsTab() {
    final p = _patient!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Personal Information', style: CHWTheme.subheadingStyle),
            const SizedBox(height: 12),
            _buildDetailItem(
              icon: Icons.person,
              label: 'Full Name',
              value: p.name,
            ),
            _buildDetailItem(icon: Icons.cake, label: 'Age', value: '${p.age}'),
            _buildDetailItem(icon: Icons.wc, label: 'Gender', value: p.gender),
            _buildDetailItem(icon: Icons.phone, label: 'Phone', value: p.phone),
            _buildDetailItem(
              icon: Icons.home,
              label: 'Address',
              value: p.address,
            ),
            const SizedBox(height: 16),
            Text('Medical Information', style: CHWTheme.subheadingStyle),
            const SizedBox(height: 12),
            _buildDetailItem(
              icon: Icons.badge,
              label: 'Patient ID',
              value: p.patientId,
            ),
            _buildDetailItem(
              icon: Icons.verified,
              label: 'TB Status',
              value: p.statusDisplayName,
            ),
            if (p.diagnosisDate != null)
              _buildDetailItem(
                icon: Icons.event,
                label: 'Diagnosis Date',
                value: DateFormat('MMM d, y').format(p.diagnosisDate!),
              ),
            _buildDetailItem(
              icon: Icons.local_hospital,
              label: 'Facility',
              value: p.treatmentFacility,
            ),
            _buildDetailItem(
              icon: Icons.support_agent,
              label: 'Assigned CHW',
              value: p.assignedCHW,
            ),
          ],
        ),
      ),
    );
  }

  // Tab: Visits
  Widget _buildVisitsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.visitsCollection)
          .where('patientId', isEqualTo: _patient!.patientId)
          .orderBy('visitDate', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildEmptyListMessage('Failed to load visits');
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptyListMessage('No visits recorded');
        }
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final v = docs[i].data();
            final date = (v['visitDate'] as Timestamp).toDate();
            return ListTile(
              leading: Icon(Icons.route, color: CHWTheme.primaryColor),
              title: Text(
                '${v['visitType'] ?? 'visit'} — ${DateFormat('MMM d, y').format(date)}',
              ),
              subtitle: Text(v['notes'] ?? ''),
              trailing: v['found'] == true
                  ? const Icon(Icons.check, color: Colors.green)
                  : const Icon(Icons.close, color: Colors.red),
            );
          },
        );
      },
    );
  }

  // Tab: Medications
  Widget _buildMedicationsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('medications')
          .where('patientId', isEqualTo: _patient!.patientId)
          .orderBy('startDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildEmptyListMessage('Failed to load medications');
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptyListMessage('No medications');
        }
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final m = docs[i].data();
            final start = (m['startDate'] as Timestamp?)?.toDate();
            final end = (m['endDate'] as Timestamp?)?.toDate();
            return ListTile(
              leading: Icon(
                m['isActive'] == true
                    ? Icons.medication
                    : Icons.medication_outlined,
                color: CHWTheme.primaryColor,
              ),
              title: Text(m['drugName'] ?? m['genericName'] ?? 'Medication'),
              subtitle: Text(
                '${m['dosage'] ?? ''} ${m['frequency'] ?? ''}\n${start != null ? 'Start: ${DateFormat('MMM d, y').format(start)}' : ''} ${end != null ? ' End: ${DateFormat('MMM d, y').format(end)}' : ''}',
              ),
              isThreeLine: true,
            );
          },
        );
      },
    );
  }

  // Tab: Adherence
  Widget _buildAdherenceTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('adherence')
          .where('patientId', isEqualTo: _patient!.patientId)
          .orderBy('date')
          .limit(120)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptyListMessage('No adherence records');
        }
        // Simple summary list; charts can be added later
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final a = docs[i].data();
            final date = (a['date'] as Timestamp).toDate();
            final planned = (a['dosesPlanned'] ?? 0) as int;
            final taken = (a['dosesTaken'] ?? 0) as int;
            final pct = planned == 0
                ? 0
                : (taken / planned * 100).clamp(0, 100).round();
            return ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(DateFormat('MMM d, y').format(date)),
              subtitle: Text('Taken $taken / $planned ($pct%)'),
            );
          },
        );
      },
    );
  }

  // Tab: Follow-ups
  Widget _buildFollowupsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('followups')
          .where('patientId', isEqualTo: _patient!.patientId)
          .orderBy('scheduledAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptyListMessage('No follow-ups');
        }
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final f = docs[i].data();
            final at = (f['scheduledAt'] as Timestamp?)?.toDate();
            return ListTile(
              leading: const Icon(Icons.event_note),
              title: Text(f['type'] ?? 'Follow-up'),
              subtitle: Text(
                '${f['purpose'] ?? ''}\n${at != null ? DateFormat('MMM d, y – h:mm a').format(at) : ''}',
              ),
              isThreeLine: true,
              trailing: Text(f['status'] ?? ''),
            );
          },
        );
      },
    );
  }

  // Tab: Contacts
  Widget _buildContactsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('contacts')
          .where('indexPatientId', isEqualTo: _patient!.patientId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptyListMessage('No contacts');
        }
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final c = docs[i].data();
            return ListTile(
              leading: const Icon(Icons.group),
              title: Text(c['name'] ?? 'Household member'),
              subtitle: Text(
                'Relation: ${c['relationship'] ?? ''} • Screening: ${c['screeningStatus'] ?? ''} • Test: ${c['testResult'] ?? ''}',
              ),
              trailing: Text(c['referralStatus'] ?? ''),
            );
          },
        );
      },
    );
  }

  Widget _buildPatientSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient avatar
                CircleAvatar(
                  radius: 40,
                  backgroundColor: _getStatusColor(
                    _patient!.tbStatus,
                  ).withOpacity(0.2),
                  child: Text(
                    _patient!.name.isNotEmpty
                        ? _patient!.name.substring(0, 1).toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: _getStatusColor(_patient!.tbStatus),
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Patient basic info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _patient!.name,
                        style: CHWTheme.headingStyle.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${_patient!.patientId}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                _patient!.tbStatus,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getStatusColor(
                                  _patient!.tbStatus,
                                ).withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _patient!.statusDisplayName,
                              style: TextStyle(
                                color: _getStatusColor(_patient!.tbStatus),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_patient!.diagnosisDate != null)
                            Text(
                              'Diagnosed: ${DateFormat('MMM d, y').format(_patient!.diagnosisDate!)}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Patient details in grid
            ResponsiveWidget(
              mobile: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildPatientDetailsItems(),
              ),
              tablet: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 4,
                children: _buildPatientDetailsItems(),
              ),
              desktop: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 4,
                children: _buildPatientDetailsItems(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPatientDetailsItems() {
    return [
      _buildDetailItem(
        icon: Icons.person,
        label: 'Age',
        value: '${_patient!.age} years',
      ),
      _buildDetailItem(
        icon: Icons.wc,
        label: 'Gender',
        value: _patient!.gender,
      ),
      _buildDetailItem(
        icon: Icons.phone,
        label: 'Phone',
        value: _patient!.phone,
      ),
      _buildDetailItem(
        icon: Icons.location_on,
        label: 'Address',
        value: _patient!.address,
      ),
      _buildDetailItem(
        icon: Icons.local_hospital,
        label: 'Treatment Facility',
        value: _patient!.treatmentFacility,
      ),
      _buildDetailItem(
        icon: Icons.person_pin,
        label: 'Assigned CHW',
        value: _patient!.assignedCHW,
      ),
      _buildDetailItem(
        icon: Icons.calendar_today,
        label: 'Registered',
        value: DateFormat('MMM d, y').format(_patient!.createdAt),
      ),
      _buildDetailItem(
        icon: Icons.verified_user,
        label: 'Consent',
        value: _patient!.consent ? 'Provided' : 'Not Provided',
      ),
      _buildDetailItem(
        icon: Icons.check_circle,
        label: 'Validated',
        value: _patient!.isValidated ? 'Yes' : 'No',
      ),
    ];
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: CHWTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentStatusCard() {
    // Calculate treatment progress based on TB status
    double progressValue = 0.0;
    String progressText = '';

    switch (_patient!.tbStatus) {
      case AppConstants.newlyDiagnosedStatus:
        progressValue = 0.1;
        progressText = 'Treatment not yet started';
        break;
      case AppConstants.onTreatmentStatus:
        // Assuming 6 months treatment duration
        if (_patient!.diagnosisDate != null) {
          final daysSinceDiagnosis = _patient!.daysSinceDiagnosis ?? 0;
          progressValue = daysSinceDiagnosis / 180; // 180 days = 6 months
          progressValue = progressValue.clamp(0.0, 1.0);
          final daysRemaining = 180 - daysSinceDiagnosis;
          progressText = daysRemaining > 0
              ? 'Approximately ${daysRemaining.round()} days remaining'
              : 'Treatment should be completed';
        } else {
          progressValue = 0.5; // Default if diagnosis date is unknown
          progressText = 'Treatment in progress';
        }
        break;
      case AppConstants.treatmentCompletedStatus:
        progressValue = 1.0;
        progressText = 'Treatment completed';
        break;
      case AppConstants.lostToFollowUpStatus:
        progressValue = 0.0;
        progressText = 'Patient lost to follow-up';
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Treatment Status',
              style: CHWTheme.subheadingStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getStatusColor(_patient!.tbStatus),
              ),
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8),
            Text(
              progressText,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            const SizedBox(height: 16),
            // Quick action buttons
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.update,
                    label: 'Update Status',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Update Status functionality coming soon',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.note_add,
                    label: 'Add Note',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Add Note functionality coming soon'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.phone,
                    label: 'Contact',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Contact functionality coming soon'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: CHWTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: CHWTheme.primaryColor, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: CHWTheme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyListMessage(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.newlyDiagnosedStatus:
        return Colors.blue;
      case AppConstants.onTreatmentStatus:
        return Colors.green;
      case AppConstants.treatmentCompletedStatus:
        return Colors.purple;
      case AppConstants.lostToFollowUpStatus:
        return CHWTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  // Result color helper was used in legacy tab; removed

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Patient'),
        content: const Text(
          'Are you sure you want to delete this patient? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete functionality coming soon'),
                ),
              );
            },
            child: Text('Delete', style: TextStyle(color: CHWTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}
