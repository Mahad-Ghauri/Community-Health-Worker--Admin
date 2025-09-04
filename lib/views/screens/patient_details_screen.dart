// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:chw_tb/config/theme.dart';
import 'package:chw_tb/controllers/providers/patient_provider.dart';
import 'package:chw_tb/models/core_models.dart';

class PatientDetailsScreen extends StatefulWidget {
  const PatientDetailsScreen({super.key});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;
  String? patientId;
  Patient? patient;

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
    _tabController = TabController(length: 5, vsync: this);
    _fadeController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (patientId == null) {
      // Get patient ID from route arguments
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null) {
        if (args is String) {
          patientId = args;
        } else if (args is Map<String, dynamic> && args['patientId'] != null) {
          patientId = args['patientId'];
        }
        if (patientId != null) {
          _loadPatientData();
        }
      }
    }
  }

  Future<void> _loadPatientData() async {
    if (patientId != null) {
      final patientProvider = Provider.of<PatientProvider>(context, listen: false);
      await patientProvider.selectPatient(patientId!);
      setState(() {
        patient = patientProvider.selectedPatient;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PatientProvider>(
      builder: (context, patientProvider, child) {
        patient = patientProvider.selectedPatient;
        
        return Scaffold(
          backgroundColor: MadadgarTheme.backgroundColor,
          body: patientProvider.isLoading 
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: _fadeAnimation,
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverAppBar(
                      expandedHeight: 300,
                      floating: false,
                      pinned: true,
                      backgroundColor: MadadgarTheme.primaryColor,
                      iconTheme: const IconThemeData(color: Colors.white),
                      actions: [
                        IconButton(
                          onPressed: () => Navigator.pushNamed(
                            context, 
                            '/edit-patient',
                            arguments: {'patientId': patientId},
                          ),
                          icon: const Icon(Icons.edit),
                        ),
                        PopupMenuButton<String>(
                          onSelected: _handleMenuAction,
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'new_visit',
                              child: Row(
                                children: [
                                  Icon(Icons.add_location),
                                  SizedBox(width: 8),
                                  Text('New Visit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'add_family',
                              child: Row(
                                children: [
                                  Icon(Icons.group_add),
                                  SizedBox(width: 8),
                                  Text('Add Family Member'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'call_patient',
                              child: Row(
                                children: [
                                  Icon(Icons.phone),
                                  SizedBox(width: 8),
                                  Text('Call Patient'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: _buildHeaderContent(),
                      ),
                      bottom: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withOpacity(0.7),
                        indicatorColor: Colors.white,
                        labelStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'Visits'),
                          Tab(text: 'Treatment'),
                          Tab(text: 'Family'),
                          Tab(text: 'Appointments'),
                        ],
                      ),
                    ),
                  ],
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildVisitsTab(),
                      _buildTreatmentTab(),
                      _buildFamilyTab(),
                      _buildAppointmentsTab(),
                    ],
                  ),
                ),
              ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.pushNamed(
              context, 
              '/new-visit',
              arguments: {'patientId': patientId},
            ),
            backgroundColor: MadadgarTheme.secondaryColor,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_location),
            label: Text(
              'New Visit',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            MadadgarTheme.primaryColor,
            MadadgarTheme.primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60), // Space for app bar
              
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient?.name ?? 'Loading...',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(patient?.tbStatus ?? '').withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusLabel(patient?.tbStatus ?? ''),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${patient?.patientId ?? 'N/A'}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Quick stats
              Row(
                children: [
                  _buildQuickStat('Age', '${patient?.age ?? 0}'),
                  _buildQuickStat('Gender', patient?.gender ?? 'N/A'),
                  _buildQuickStat('Phone', patient?.phone ?? 'N/A'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Information Card
          _buildInfoCard(
            title: 'Personal Information',
            icon: Icons.person_outline,
            children: [
              _buildInfoRow('Full Name', patient?.name ?? 'N/A'),
              _buildInfoRow('Age', '${patient?.age ?? 0} years'),
              _buildInfoRow('Gender', patient?.gender ?? 'N/A'),
              _buildInfoRow('Phone', patient?.phone ?? 'N/A'),
              _buildInfoRow('Address', patient?.address ?? 'N/A'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Medical Information Card
          _buildInfoCard(
            title: 'Medical Information',
            icon: Icons.medical_information_outlined,
            children: [
              _buildInfoRow('TB Status', _getStatusLabel(patient?.tbStatus ?? '')),
              _buildInfoRow('Diagnosis Date', patient?.diagnosisDate != null ? _formatDate(patient!.diagnosisDate!) : 'N/A'),
              _buildInfoRow('Treatment Facility', patient?.treatmentFacility ?? 'N/A'),
              _buildInfoRow('Registration Date', patient?.createdAt != null ? _formatDate(patient!.createdAt) : 'N/A'),
              _buildInfoRow('Consent Given', patient?.consent == true ? 'Yes' : 'No'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Adherence Score Card
          _buildAdherenceCard(),
          
          const SizedBox(height: 16),
          
          // Quick Actions
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildVisitsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Visit History',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MadadgarTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Total: 0',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: MadadgarTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.home_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Visits Recorded',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start visiting this patient to see visit history here',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Treatment Adherence',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildAdherenceCard(),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medication,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Adherence Data',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adherence data will appear here when visits are logged',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Family Members',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/add-household-member'),
                icon: const Icon(Icons.group_add, size: 16),
                label: Text(
                  'Add Member',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MadadgarTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.family_restroom,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Family Members Added',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add family members for contact tracing and screening',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Upcoming Appointments',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Appointments Scheduled',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hospital appointments will appear here when scheduled',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: MadadgarTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdherenceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: MadadgarTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Treatment Adherence',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'N/A',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      Text(
                        'Adherence Score',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '0',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      Text(
                        'Days on Treatment',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.add_location,
                    label: 'New Visit',
                    onTap: () => Navigator.pushNamed(
                      context, 
                      '/new-visit',
                      arguments: {'patientId': patientId},
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.phone,
                    label: 'Call Patient',
                    onTap: () => _callPatient(),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.edit,
                    label: 'Edit Info',
                    onTap: () => Navigator.pushNamed(
                      context, 
                      '/edit-patient',
                      arguments: {'patientId': patientId},
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.medication,
                    label: 'Log Adherence',
                    onTap: () => Navigator.pushNamed(
                      context, 
                      '/adherence-tracking',
                      arguments: {'patientId': patientId},
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: MadadgarTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: MadadgarTheme.primaryColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: MadadgarTheme.primaryColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: MadadgarTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'new_visit':
        Navigator.pushNamed(
          context, 
          '/new-visit',
          arguments: {'patientId': patientId},
        );
        break;
      case 'add_family':
        Navigator.pushNamed(
          context, 
          '/add-household-member',
          arguments: {'patientId': patientId},
        );
        break;
      case 'call_patient':
        _callPatient();
        break;
    }
  }

  void _callPatient() {
    if (patient?.phone != null && patient!.phone.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Calling ${patient!.phone}...',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No phone number available',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'on_treatment':
        return 'On Treatment';
      case 'treatment_completed':
        return 'Treatment Completed';
      case 'treatment_failed':
        return 'Treatment Failed';
      case 'lost_to_followup':
        return 'Lost to Follow-up';
      case 'died':
        return 'Died';
      case 'not_evaluated':
        return 'Not Evaluated';
      case 'transferred_out':
        return 'Transferred Out';
      default:
        return 'Unknown Status';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'on_treatment':
        return Colors.blue;
      case 'treatment_completed':
        return Colors.green;
      case 'treatment_failed':
        return Colors.red;
      case 'lost_to_followup':
        return Colors.orange;
      case 'died':
        return Colors.black;
      case 'not_evaluated':
        return Colors.grey;
      case 'transferred_out':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
