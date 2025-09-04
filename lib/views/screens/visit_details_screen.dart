// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chw_tb/config/theme.dart';

class VisitDetailsScreen extends StatefulWidget {
  final String? visitId;
  
  const VisitDetailsScreen({super.key, this.visitId});

  @override
  State<VisitDetailsScreen> createState() => _VisitDetailsScreenState();
}

class _VisitDetailsScreenState extends State<VisitDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;
  
  bool _isLoading = false;

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
    
    _loadVisitData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _loadVisitData() {
    // Mock visit data - will be loaded from Firebase later
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
              expandedHeight: 280,
              floating: false,
              pinned: true,
              backgroundColor: MadadgarTheme.primaryColor,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  onPressed: () => _editVisit(),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Visit',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: _handleMenuAction,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          const Icon(Icons.copy),
                          const SizedBox(width: 8),
                          Text('Duplicate Visit', style: GoogleFonts.poppins()),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          const Icon(Icons.download),
                          const SizedBox(width: 8),
                          Text('Export Report', style: GoogleFonts.poppins()),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, color: Colors.red),
                          const SizedBox(width: 8),
                          Text('Delete Visit', style: GoogleFonts.poppins(color: Colors.red)),
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
                  Tab(text: 'Vitals'),
                  Tab(text: 'Notes'),
                  Tab(text: 'Media'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildVitalsTab(),
              _buildNotesTab(),
              _buildMediaTab(),
            ],
          ),
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
              // Visit type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Follow-up Visit',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Patient name
              Text(
                'Ahmad Khan',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Visit date and time
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.white.withOpacity(0.9), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '2 September 2025, 10:30 AM',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Location
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.white.withOpacity(0.9), size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Model Town, Lahore',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Status and duration
              Row(
                children: [
                  _buildStatusChip('Completed', Colors.green),
                  const SizedBox(width: 12),
                  Text(
                    'Duration: 45 minutes',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Visit summary card
          _buildVisitSummaryCard(),
          
          const SizedBox(height: 16),
          
          // Treatment adherence card
          _buildTreatmentAdherenceCard(),
          
          const SizedBox(height: 16),
          
          // Symptoms card
          _buildSymptomsCard(),
          
          const SizedBox(height: 16),
          
          // Medications card
          _buildMedicationsCard(),
          
          const SizedBox(height: 16),
          
          // Next appointment card
          _buildNextAppointmentCard(),
        ],
      ),
    );
  }

  Widget _buildVitalsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Vital signs grid
          _buildVitalSignsGrid(),
          
          const SizedBox(height: 16),
          
          // Vital signs chart
          _buildVitalSignsChart(),
          
          const SizedBox(height: 16),
          
          // Previous readings comparison
          _buildPreviousReadingsCard(),
        ],
      ),
    );
  }

  Widget _buildNotesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // CHW notes
          _buildNotesCard('CHW Notes', 
            'Patient is responding well to treatment. No side effects reported. Patient maintains good adherence to medication schedule. Family support is excellent. Recommended to continue current treatment plan.'),
          
          const SizedBox(height: 16),
          
          // Patient feedback
          _buildNotesCard('Patient Feedback',
            'Feeling much better than last month. No cough or fever. Appetite has improved. Taking medicines on time. Family is helping with reminders.'),
          
          const SizedBox(height: 16),
          
          // Observations
          _buildNotesCard('Clinical Observations',
            'Patient appears healthy and alert. No signs of distress. Weight stable. Good compliance with treatment regimen. Family engagement positive.'),
          
          const SizedBox(height: 16),
          
          // Action items
          _buildActionItemsCard(),
        ],
      ),
    );
  }

  Widget _buildMediaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Photos section
          _buildPhotosSection(),
          
          const SizedBox(height: 16),
          
          // Documents section
          _buildDocumentsSection(),
          
          const SizedBox(height: 16),
          
          // Audio recordings section
          _buildAudioRecordingsSection(),
        ],
      ),
    );
  }

  Widget _buildVisitSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize, color: MadadgarTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Visit Summary',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildSummaryRow('Visit Type', 'Follow-up Visit'),
            _buildSummaryRow('Purpose', 'Routine medication check'),
            _buildSummaryRow('CHW', 'Dr. Sarah Ahmed'),
            _buildSummaryRow('Visit Number', '4th visit'),
            _buildSummaryRow('Patient Found', 'Yes'),
            _buildSummaryRow('Visit Duration', '45 minutes'),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentAdherenceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medication, color: MadadgarTheme.primaryColor),
                const SizedBox(width: 8),
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
            
            // Adherence percentage
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medication Adherence',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: 0.95,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
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
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildSummaryRow('Missed Doses (Last 30 days)', '2'),
            _buildSummaryRow('Side Effects', 'None reported'),
            _buildSummaryRow('Pill Count', '28/30 taken'),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.healing, color: MadadgarTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Symptoms Assessment',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildSymptomItem('Cough', 'Absent', Colors.green),
            _buildSymptomItem('Fever', 'Absent', Colors.green),
            _buildSymptomItem('Weight Loss', 'Stable', Colors.green),
            _buildSymptomItem('Night Sweats', 'Absent', Colors.green),
            _buildSymptomItem('Fatigue', 'Mild', Colors.orange),
            _buildSymptomItem('Appetite', 'Good', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationsCard() {
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
                  'Current Medications',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildMedicationItem('Rifampin', '600mg', 'Once daily', 'Morning'),
            _buildMedicationItem('Isoniazid', '300mg', 'Once daily', 'Morning'),
            _buildMedicationItem('Ethambutol', '1200mg', 'Once daily', 'Morning'),
            _buildMedicationItem('Pyrazinamide', '1500mg', 'Once daily', 'Morning'),
          ],
        ),
      ),
    );
  }

  Widget _buildNextAppointmentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: MadadgarTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Next Appointment',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MadadgarTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: MadadgarTheme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '15 September 2025',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '10:00 AM - Follow-up Visit',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _rescheduleAppointment(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MadadgarTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 36),
                    ),
                    child: Text(
                      'Reschedule',
                      style: GoogleFonts.poppins(fontSize: 12),
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

  Widget _buildVitalSignsGrid() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vital Signs',
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
                _buildVitalCard('Blood Pressure', '120/80', 'mmHg', Colors.green),
                _buildVitalCard('Heart Rate', '72', 'bpm', Colors.green),
                _buildVitalCard('Temperature', '98.6', '°F', Colors.green),
                _buildVitalCard('Weight', '75', 'kg', Colors.blue),
                _buildVitalCard('Oxygen Sat.', '98', '%', Colors.green),
                _buildVitalCard('BMI', '24.2', '', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalCard(String title, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
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
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalSignsChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vital Signs Trend',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'Chart visualization coming soon',
                      style: GoogleFonts.poppins(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviousReadingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Previous Readings',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildReadingComparison('Blood Pressure', '120/80', '118/78', 'Stable'),
            _buildReadingComparison('Weight', '75 kg', '74 kg', '+1 kg'),
            _buildReadingComparison('Heart Rate', '72 bpm', '70 bpm', '+2 bpm'),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(String title, String content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItemsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Action Items',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildActionItem('Continue current medication regimen', true),
            _buildActionItem('Schedule follow-up in 2 weeks', false),
            _buildActionItem('Monitor weight weekly', false),
            _buildActionItem('Blood test in 1 month', false),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Photos',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPhotoThumbnail('Medication', Icons.medication),
                _buildPhotoThumbnail('Patient', Icons.person),
                _buildPhotoThumbnail('Documents', Icons.document_scanner),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Documents',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildDocumentItem('Prescription', 'PDF', '2.3 MB'),
            _buildDocumentItem('Lab Results', 'PDF', '1.8 MB'),
            _buildDocumentItem('Patient Consent', 'PDF', '0.9 MB'),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioRecordingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audio Recordings',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildAudioItem('Visit Summary', '03:42'),
            _buildAudioItem('Patient Interview', '12:15'),
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

  Widget _buildSymptomItem(String symptom, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              symptom,
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

  Widget _buildMedicationItem(String name, String dose, String frequency, String timing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
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
            const SizedBox(height: 4),
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
    );
  }

  Widget _buildReadingComparison(String vital, String current, String previous, String change) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              vital,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              current,
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              previous,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
          ),
          Text(
            change,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: change.contains('+') ? Colors.orange : Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(String action, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: completed ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              action,
              style: GoogleFonts.poppins(
                decoration: completed ? TextDecoration.lineThrough : null,
                color: completed ? Colors.grey : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoThumbnail(String title, IconData icon) {
    return GestureDetector(
      onTap: () => _viewPhoto(title),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey.shade600),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentItem(String name, String type, String size) {
    return ListTile(
      leading: Icon(Icons.description, color: MadadgarTheme.primaryColor),
      title: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      subtitle: Text('$type • $size', style: GoogleFonts.poppins(fontSize: 12)),
      trailing: IconButton(
        onPressed: () => _openDocument(name),
        icon: const Icon(Icons.open_in_new),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildAudioItem(String name, String duration) {
    return ListTile(
      leading: Icon(Icons.audiotrack, color: MadadgarTheme.primaryColor),
      title: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      subtitle: Text(duration, style: GoogleFonts.poppins(fontSize: 12)),
      trailing: IconButton(
        onPressed: () => _playAudio(name),
        icon: const Icon(Icons.play_arrow),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'duplicate':
        _duplicateVisit();
        break;
      case 'export':
        _exportReport();
        break;
      case 'delete':
        _deleteVisit();
        break;
    }
  }

  void _editVisit() {
    Navigator.pushNamed(context, '/edit-visit', arguments: widget.visitId);
  }

  void _duplicateVisit() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Visit duplicated successfully!', style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export feature coming soon!', style: GoogleFonts.poppins()),
      ),
    );
  }

  void _deleteVisit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Visit', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this visit? This action cannot be undone.', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Visit deleted successfully!', style: GoogleFonts.poppins()),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _rescheduleAppointment() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reschedule feature coming soon!', style: GoogleFonts.poppins()),
      ),
    );
  }

  void _viewPhoto(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Photo viewer coming soon!', style: GoogleFonts.poppins()),
      ),
    );
  }

  void _openDocument(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Document viewer coming soon!', style: GoogleFonts.poppins()),
      ),
    );
  }

  void _playAudio(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Audio player coming soon!', style: GoogleFonts.poppins()),
      ),
    );
  }
}
