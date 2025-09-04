// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chw_tb/config/theme.dart';

class TreatmentPlanScreen extends StatefulWidget {
  final String? patientId;
  
  const TreatmentPlanScreen({super.key, this.patientId});

  @override
  State<TreatmentPlanScreen> createState() => _TreatmentPlanScreenState();
}

class _TreatmentPlanScreenState extends State<TreatmentPlanScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;
  
  bool _isLoading = false;
  final String _treatmentPhase = 'Intensive';
  DateTime? _treatmentStartDate;
  DateTime? _expectedCompletionDate;

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
    _tabController = TabController(length: 4, vsync: this);
    _fadeController.forward();
    
    _loadTreatmentPlan();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _loadTreatmentPlan() {
    setState(() => _isLoading = true);
    
    // Mock treatment plan data
    _treatmentStartDate = DateTime(2025, 1, 10);
    _expectedCompletionDate = DateTime(2025, 7, 10);
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MadadgarTheme.backgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 250,
              floating: false,
              pinned: true,
              backgroundColor: MadadgarTheme.primaryColor,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  onPressed: () => _editTreatmentPlan(),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Treatment Plan',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: _handleMenuAction,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          const Icon(Icons.download),
                          const SizedBox(width: 8),
                          Text('Export Plan', style: GoogleFonts.poppins()),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          const Icon(Icons.share),
                          const SizedBox(width: 8),
                          Text('Share with Doctor', style: GoogleFonts.poppins()),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'history',
                      child: Row(
                        children: [
                          const Icon(Icons.history),
                          const SizedBox(width: 8),
                          Text('Plan History', style: GoogleFonts.poppins()),
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
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Medications'),
                  Tab(text: 'Schedule'),
                  Tab(text: 'Progress'),
                ],
              ),
            ),
          ],
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildMedicationsTab(),
                    _buildScheduleTab(),
                    _buildProgressTab(),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addMedication(),
        backgroundColor: MadadgarTheme.secondaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Medication',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
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
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient name and ID
              Text(
                'Ahmad Khan',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 4),
              
              Text(
                'Patient ID: PAT001',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Treatment phase badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$_treatmentPhase Phase',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Treatment duration info
              Row(
                children: [
                  _buildInfoChip('Started', '10 Jan 2025'),
                  const SizedBox(width: 12),
                  _buildInfoChip('Duration', '6 months'),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Treatment Progress: 45%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: 0.45,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w500,
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
        children: [
          // Treatment summary card
          _buildTreatmentSummaryCard(),
          
          const SizedBox(height: 16),
          
          // Treatment phases card
          _buildTreatmentPhasesCard(),
          
          const SizedBox(height: 16),
          
          // Key milestones card
          _buildMilestonesCard(),
          
          const SizedBox(height: 16),
          
          // Treatment team card
          _buildTreatmentTeamCard(),
        ],
      ),
    );
  }

  Widget _buildMedicationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Current medications card
          _buildCurrentMedicationsCard(),
          
          const SizedBox(height: 16),
          
          // Medication schedule card
          _buildMedicationScheduleCard(),
          
          const SizedBox(height: 16),
          
          // Side effects monitoring card
          _buildSideEffectsCard(),
          
          const SizedBox(height: 16),
          
          // Adherence tracking card
          _buildAdherenceTrackingCard(),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Weekly schedule card
          _buildWeeklyScheduleCard(),
          
          const SizedBox(height: 16),
          
          // Upcoming appointments card
          _buildUpcomingAppointmentsCard(),
          
          const SizedBox(height: 16),
          
          // Reminders card
          _buildRemindersCard(),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progress overview card
          _buildProgressOverviewCard(),
          
          const SizedBox(height: 16),
          
          // Clinical markers card
          _buildClinicalMarkersCard(),
          
          const SizedBox(height: 16),
          
          // Treatment response card
          _buildTreatmentResponseCard(),
          
          const SizedBox(height: 16),
          
          // Goals and targets card
          _buildGoalsTargetsCard(),
        ],
      ),
    );
  }

  Widget _buildTreatmentSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services, color: MadadgarTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Treatment Summary',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildSummaryRow('Diagnosis', 'Pulmonary Tuberculosis'),
            _buildSummaryRow('Treatment Type', 'DOTS (Directly Observed Treatment)'),
            _buildSummaryRow('Current Phase', '$_treatmentPhase Phase'),
            _buildSummaryRow('Start Date', '10 January 2025'),
            _buildSummaryRow('Expected Completion', '10 July 2025'),
            _buildSummaryRow('Total Duration', '6 months'),
            _buildSummaryRow('Drug Resistance', 'Drug-sensitive'),
            _buildSummaryRow('Treatment Category', 'Category I'),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentPhasesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Treatment Phases',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildPhaseItem('Intensive Phase', '2 months', 'Completed', Colors.green, true),
            _buildPhaseItem('Continuation Phase', '4 months', 'In Progress', Colors.orange, false),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestonesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Milestones',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildMilestoneItem('Treatment Started', '10 Jan 2025', true),
            _buildMilestoneItem('First Sputum Test', '10 Mar 2025', true),
            _buildMilestoneItem('Phase Transition', '10 Mar 2025', true),
            _buildMilestoneItem('Mid-treatment Review', '10 May 2025', false),
            _buildMilestoneItem('Final Sputum Test', '10 Jul 2025', false),
            _buildMilestoneItem('Treatment Completion', '10 Jul 2025', false),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentTeamCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Treatment Team',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildTeamMember('Dr. Sarah Ahmed', 'Primary CHW', Icons.person, '+92 300 1234567'),
            _buildTeamMember('Dr. Muhammad Ali', 'Supervising Doctor', Icons.medical_services, '+92 300 2345678'),
            _buildTeamMember('Fatima Khan', 'Family Supporter', Icons.family_restroom, '+92 300 3456789'),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentMedicationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Medications',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildMedicationItem('Rifampin', '600mg', 'Once daily', 'Morning', 'Good'),
            _buildMedicationItem('Isoniazid', '300mg', 'Once daily', 'Morning', 'Good'),
            _buildMedicationItem('Ethambutol', '1200mg', 'Once daily', 'Morning', 'Fair'),
            _buildMedicationItem('Pyrazinamide', '1500mg', 'Once daily', 'Morning', 'Good'),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationScheduleCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Daily Medication Schedule',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Icon(Icons.schedule, color: MadadgarTheme.primaryColor),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MadadgarTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MadadgarTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, color: MadadgarTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        '8:00 AM - Morning Dose',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Take all 4 medications together with food',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.restaurant, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'With breakfast',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideEffectsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Side Effects Monitoring',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildSideEffectItem('Nausea', 'Not Reported', Colors.green),
            _buildSideEffectItem('Skin Rash', 'Not Reported', Colors.green),
            _buildSideEffectItem('Joint Pain', 'Mild', Colors.orange),
            _buildSideEffectItem('Vision Changes', 'Not Reported', Colors.green),
            _buildSideEffectItem('Hearing Changes', 'Not Reported', Colors.green),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Report any new symptoms immediately to your CHW',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceTrackingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adherence Tracking',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Adherence',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: 0.95,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '95% (Excellent)',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '28',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Days',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildAdherenceRow('This Week', '7/7 doses', '100%', Colors.green),
            _buildAdherenceRow('This Month', '28/30 doses', '93%', Colors.green),
            _buildAdherenceRow('Total Missed', '5 doses', '95%', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyScheduleCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Schedule',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildScheduleDay('Monday', '8:00 AM', 'Medication + CHW Visit', true),
            _buildScheduleDay('Tuesday', '8:00 AM', 'Medication Only', true),
            _buildScheduleDay('Wednesday', '8:00 AM', 'Medication + Weight Check', true),
            _buildScheduleDay('Thursday', '8:00 AM', 'Medication Only', false),
            _buildScheduleDay('Friday', '8:00 AM', 'Medication + CHW Visit', false),
            _buildScheduleDay('Saturday', '8:00 AM', 'Medication Only', false),
            _buildScheduleDay('Sunday', '8:00 AM', 'Medication Only', false),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointmentsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            
            _buildAppointmentItem('CHW Visit', '15 Sep 2025', '10:00 AM', 'Dr. Sarah Ahmed'),
            _buildAppointmentItem('Lab Test', '20 Sep 2025', '9:00 AM', 'District Hospital'),
            _buildAppointmentItem('Doctor Review', '25 Sep 2025', '2:00 PM', 'Dr. Muhammad Ali'),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Reminders',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildReminderItem(Icons.medication, 'Daily Medication', '8:00 AM daily'),
            _buildReminderItem(Icons.monitor_weight, 'Weekly Weight Check', 'Every Wednesday'),
            _buildReminderItem(Icons.calendar_today, 'CHW Visit', 'Twice weekly'),
            _buildReminderItem(Icons.science, 'Lab Test Due', 'In 10 days'),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressOverviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress Overview',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildProgressCard('Treatment Days', '65/180', Colors.blue),
                _buildProgressCard('Adherence Rate', '95%', Colors.green),
                _buildProgressCard('Weight Gain', '+3 kg', Colors.orange),
                _buildProgressCard('Symptoms', 'Improved', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicalMarkersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clinical Markers',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildMarkerItem('Sputum Conversion', 'Achieved', 'Month 2', Colors.green),
            _buildMarkerItem('Weight Trend', 'Improving', '+3kg gained', Colors.green),
            _buildMarkerItem('Symptom Resolution', 'Good', 'No cough/fever', Colors.green),
            _buildMarkerItem('Chest X-Ray', 'Improving', 'Lesions healing', Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentResponseCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Treatment Response',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Excellent Response',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Patient is responding very well to treatment. All clinical indicators show positive improvement.',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsTargetsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goals & Targets',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildGoalItem('Complete 6-month treatment', '65/180 days', 0.36, Colors.blue),
            _buildGoalItem('Maintain >90% adherence', '95% current', 1.0, Colors.green),
            _buildGoalItem('Achieve sputum conversion', 'Achieved', 1.0, Colors.green),
            _buildGoalItem('Gain 5kg weight', '3kg gained', 0.6, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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

  Widget _buildPhaseItem(String phase, String duration, String status, Color color, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phase,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '$duration • $status',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isCompleted ? Icons.check_circle : Icons.access_time,
            color: color,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneItem(String milestone, String date, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              milestone,
              style: GoogleFonts.poppins(
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color: isCompleted ? Colors.grey : Colors.black87,
              ),
            ),
          ),
          Text(
            date,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMember(String name, String role, IconData icon, String contact) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: MadadgarTheme.primaryColor.withOpacity(0.1),
        child: Icon(icon, color: MadadgarTheme.primaryColor),
      ),
      title: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      subtitle: Text('$role • $contact', style: GoogleFonts.poppins(fontSize: 12)),
      trailing: IconButton(
        onPressed: () => _contactTeamMember(name),
        icon: const Icon(Icons.phone),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildMedicationItem(String name, String dose, String frequency, String timing, String adherence) {
    Color adherenceColor = adherence == 'Good' ? Colors.green : 
                          adherence == 'Fair' ? Colors.orange : Colors.red;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '$dose • $frequency • $timing',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: adherenceColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              adherence,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: adherenceColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideEffectItem(String effect, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              effect,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdherenceRow(String period, String doses, String percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(period, style: GoogleFonts.poppins(fontWeight: FontWeight.w500))),
          Expanded(child: Text(doses, style: GoogleFonts.poppins(fontSize: 12))),
          Text(percentage, style: GoogleFonts.poppins(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildScheduleDay(String day, String time, String activity, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              day,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              time,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              activity,
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ),
          Icon(
            isCompleted ? Icons.check_circle : Icons.schedule,
            color: isCompleted ? Colors.green : Colors.grey,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentItem(String type, String date, String time, String provider) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MadadgarTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MadadgarTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.event, color: MadadgarTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$date at $time',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  provider,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _rescheduleAppointment(type),
            icon: const Icon(Icons.edit_calendar),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderItem(IconData icon, String title, String schedule) {
    return ListTile(
      leading: Icon(icon, color: MadadgarTheme.primaryColor),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      subtitle: Text(schedule, style: GoogleFonts.poppins(fontSize: 12)),
      trailing: Switch(
        value: true,
        onChanged: (value) {},
        activeColor: MadadgarTheme.primaryColor,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildProgressCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMarkerItem(String marker, String status, String details, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              marker,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: Text(
              details,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(String goal, String progress, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                progress,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportTreatmentPlan();
        break;
      case 'share':
        _shareWithDoctor();
        break;
      case 'history':
        _viewPlanHistory();
        break;
    }
  }

  void _editTreatmentPlan() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit treatment plan feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _addMedication() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Add medication feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _exportTreatmentPlan() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _shareWithDoctor() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share with doctor feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _viewPlanHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Plan history feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _contactTeamMember(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Contacting $name...', style: GoogleFonts.poppins())),
    );
  }

  void _rescheduleAppointment(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reschedule $type feature coming soon!', style: GoogleFonts.poppins())),
    );
  }
}
