// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chw_tb/config/theme.dart';

class EditVisitScreen extends StatefulWidget {
  final String? visitId;
  
  const EditVisitScreen({super.key, this.visitId});

  @override
  State<EditVisitScreen> createState() => _EditVisitScreenState();
}

class _EditVisitScreenState extends State<EditVisitScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;
  
  // Form controllers
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _treatmentNotesController = TextEditingController();
  final TextEditingController _nextActionController = TextEditingController();
  final TextEditingController _bloodPressureController = TextEditingController();
  final TextEditingController _heartRateController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _oxygenSatController = TextEditingController();
  
  String _selectedVisitType = 'Follow-up';
  String _selectedPatientStatus = 'Found';
  DateTime? _selectedVisitDate;
  TimeOfDay? _selectedVisitTime;
  bool _patientFound = true;
  
  // Symptoms checklist
  final Map<String, bool> _symptoms = {
    'Cough': false,
    'Fever': false,
    'Night Sweats': false,
    'Weight Loss': false,
    'Fatigue': false,
    'Loss of Appetite': false,
    'Chest Pain': false,
    'Shortness of Breath': false,
  };
  
  // Medication adherence
  final Map<String, String> _medicationAdherence = {
    'Rifampin': 'Good',
    'Isoniazid': 'Good',
    'Ethambutol': 'Good',
    'Pyrazinamide': 'Good',
  };

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
    _notesController.dispose();
    _symptomsController.dispose();
    _treatmentNotesController.dispose();
    _nextActionController.dispose();
    _bloodPressureController.dispose();
    _heartRateController.dispose();
    _temperatureController.dispose();
    _weightController.dispose();
    _oxygenSatController.dispose();
    super.dispose();
  }

  void _loadVisitData() {
    setState(() => _isLoading = true);
    
    // Mock visit data - will be loaded from Firebase later
    _notesController.text = 'Patient is responding well to treatment. No side effects reported.';
    _symptomsController.text = 'No cough or fever. Appetite has improved.';
    _treatmentNotesController.text = 'Continue current medication regimen. Good adherence noted.';
    _nextActionController.text = 'Schedule follow-up in 2 weeks. Monitor weight weekly.';
    _bloodPressureController.text = '120/80';
    _heartRateController.text = '72';
    _temperatureController.text = '98.6';
    _weightController.text = '75';
    _oxygenSatController.text = '98';
    _selectedVisitDate = DateTime(2025, 9, 2);
    _selectedVisitTime = const TimeOfDay(hour: 10, minute: 30);
    
    setState(() => _isLoading = false);
  }

  void _saveVisit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in all required fields',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isSaving = true);
    
    // Simulate save operation
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    setState(() => _isSaving = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Visit updated successfully!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
      ),
    );
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MadadgarTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Visit',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: MadadgarTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveVisit,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Save',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
          tabs: const [
            Tab(text: 'Basic Info'),
            Tab(text: 'Symptoms'),
            Tab(text: 'Vitals'),
            Tab(text: 'Notes'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBasicInfoTab(),
                    _buildSymptomsTab(),
                    _buildVitalsTab(),
                    _buildNotesTab(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Visit type selection
          _buildDropdownField(
            label: 'Visit Type',
            icon: Icons.medical_services,
            value: _selectedVisitType,
            items: ['Follow-up', 'Treatment', 'Emergency', 'Routine Check', 'Consultation'],
            onChanged: (value) => setState(() => _selectedVisitType = value!),
          ),
          
          const SizedBox(height: 16),
          
          // Visit date
          _buildDateTimeFields(),
          
          const SizedBox(height: 16),
          
          // Patient found toggle
          _buildPatientFoundSection(),
          
          const SizedBox(height: 16),
          
          // Location verification
          _buildLocationSection(),
          
          const SizedBox(height: 16),
          
          // Visit duration
          _buildVisitDurationSection(),
        ],
      ),
    );
  }

  Widget _buildSymptomsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Symptoms checklist
          _buildSymptomsChecklist(),
          
          const SizedBox(height: 16),
          
          // Additional symptoms notes
          _buildTextField(
            controller: _symptomsController,
            label: 'Additional Symptoms Notes',
            icon: Icons.note,
            maxLines: 4,
            validator: null,
          ),
          
          const SizedBox(height: 16),
          
          // Medication adherence
          _buildMedicationAdherenceSection(),
          
          const SizedBox(height: 16),
          
          // Side effects
          _buildSideEffectsSection(),
        ],
      ),
    );
  }

  Widget _buildVitalsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Vital signs input
          _buildVitalSignsInputs(),
          
          const SizedBox(height: 16),
          
          // Weight tracking
          _buildWeightTrackingSection(),
          
          const SizedBox(height: 16),
          
          // Previous vitals comparison
          _buildPreviousVitalsComparison(),
        ],
      ),
    );
  }

  Widget _buildNotesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTextField(
            controller: _notesController,
            label: 'Visit Notes',
            icon: Icons.note,
            maxLines: 6,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Visit notes are required';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _treatmentNotesController,
            label: 'Treatment Notes',
            icon: Icons.medical_services,
            maxLines: 4,
            validator: null,
          ),
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _nextActionController,
            label: 'Next Actions / Follow-up',
            icon: Icons.assignment,
            maxLines: 4,
            validator: null,
          ),
          
          const SizedBox(height: 16),
          
          // Photos section
          _buildPhotosSection(),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: MadadgarTheme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MadadgarTheme.primaryColor, width: 2),
        ),
      ),
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(item, style: GoogleFonts.poppins()),
      )).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: MadadgarTheme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MadadgarTheme.primaryColor, width: 2),
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDateTimeFields() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _selectDate,
            child: AbsorbPointer(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Visit Date',
                  prefixIcon: Icon(Icons.calendar_today, color: MadadgarTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                controller: TextEditingController(
                  text: _selectedVisitDate != null
                      ? '${_selectedVisitDate!.day}/${_selectedVisitDate!.month}/${_selectedVisitDate!.year}'
                      : '',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: _selectTime,
            child: AbsorbPointer(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Visit Time',
                  prefixIcon: Icon(Icons.access_time, color: MadadgarTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                controller: TextEditingController(
                  text: _selectedVisitTime != null
                      ? _selectedVisitTime!.format(context)
                      : '',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientFoundSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient Status',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            SwitchListTile(
              title: Text(
                'Patient Found',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                _patientFound ? 'Patient was available during visit' : 'Patient was not available',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              value: _patientFound,
              onChanged: (value) => setState(() => _patientFound = value),
              activeColor: MadadgarTheme.primaryColor,
            ),
            
            if (!_patientFound) ...[
              const SizedBox(height: 12),
              _buildDropdownField(
                label: 'Reason Not Found',
                icon: Icons.info,
                value: _selectedPatientStatus,
                items: ['Not at Home', 'Moved', 'Hospitalized', 'Traveling', 'Other'],
                onChanged: (value) => setState(() => _selectedPatientStatus = value!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location Verification',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(Icons.location_on, color: MadadgarTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'GPS Location: 31.5204° N, 74.3587° E',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
                ElevatedButton(
                  onPressed: _updateLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MadadgarTheme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(80, 36),
                  ),
                  child: Text(
                    'Update',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitDurationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.timer, color: MadadgarTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visit Duration',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '45 minutes',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _editDuration,
              style: ElevatedButton.styleFrom(
                backgroundColor: MadadgarTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(80, 36),
              ),
              child: Text(
                'Edit',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomsChecklist() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Symptoms Assessment',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            ...(_symptoms.keys.map((symptom) => CheckboxListTile(
              title: Text(symptom, style: GoogleFonts.poppins()),
              value: _symptoms[symptom],
              onChanged: (value) => setState(() => _symptoms[symptom] = value!),
              activeColor: MadadgarTheme.primaryColor,
              contentPadding: EdgeInsets.zero,
            )).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationAdherenceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medication Adherence',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            ...(_medicationAdherence.keys.map((medication) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      medication,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ),
                  DropdownButton<String>(
                    value: _medicationAdherence[medication],
                    items: ['Excellent', 'Good', 'Fair', 'Poor'].map((adherence) =>
                      DropdownMenuItem(
                        value: adherence,
                        child: Text(adherence, style: GoogleFonts.poppins(fontSize: 12)),
                      ),
                    ).toList(),
                    onChanged: (value) => setState(() => _medicationAdherence[medication] = value!),
                    underline: Container(height: 1, color: MadadgarTheme.primaryColor.withOpacity(0.3)),
                  ),
                ],
              ),
            )).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSideEffectsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Side Effects',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Any side effects reported?',
                    style: GoogleFonts.poppins(),
                  ),
                ),
                Switch(
                  value: false,
                  onChanged: (value) {},
                  activeColor: MadadgarTheme.primaryColor,
                ),
              ],
            ),
            
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Describe side effects (if any)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalSignsInputs() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vital Signs',
              style: GoogleFonts.poppins(
                fontSize: 16,
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
              childAspectRatio: 2.5,
              children: [
                _buildVitalInput('Blood Pressure', _bloodPressureController, 'mmHg'),
                _buildVitalInput('Heart Rate', _heartRateController, 'bpm'),
                _buildVitalInput('Temperature', _temperatureController, '°F'),
                _buildVitalInput('Weight', _weightController, 'kg'),
                _buildVitalInput('Oxygen Sat.', _oxygenSatController, '%'),
                _buildVitalInput('BMI', TextEditingController(text: '24.2'), ''),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalInput(String label, TextEditingController controller, String unit) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildWeightTrackingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weight Tracking',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current: 75 kg', style: GoogleFonts.poppins()),
                      Text('Previous: 74 kg', style: GoogleFonts.poppins(color: Colors.grey)),
                      Text('Change: +1 kg', style: GoogleFonts.poppins(color: Colors.green)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.trending_up, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviousVitalsComparison() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Previous Vitals Comparison',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildComparisonRow('Blood Pressure', '120/80', '118/78'),
            _buildComparisonRow('Heart Rate', '72 bpm', '70 bpm'),
            _buildComparisonRow('Temperature', '98.6°F', '98.4°F'),
            _buildComparisonRow('Weight', '75 kg', '74 kg'),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(String vital, String current, String previous) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(vital, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(current, style: GoogleFonts.poppins())),
          Expanded(child: Text(previous, style: GoogleFonts.poppins(color: Colors.grey))),
        ],
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
              'Photos & Documents',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addPhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: Text('Add Photo', style: GoogleFonts.poppins()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MadadgarTheme.primaryColor,
                      side: BorderSide(color: MadadgarTheme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addDocument,
                    icon: const Icon(Icons.attach_file),
                    label: Text('Add Document', style: GoogleFonts.poppins()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MadadgarTheme.primaryColor,
                      side: BorderSide(color: MadadgarTheme.primaryColor),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Existing photos/documents list
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Center(
                child: Text('No photos or documents added yet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedVisitDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() => _selectedVisitDate = picked);
    }
  }

  void _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedVisitTime ?? TimeOfDay.now(),
    );
    
    if (picked != null) {
      setState(() => _selectedVisitTime = picked);
    }
  }

  void _updateLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('GPS location updated!', style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _editDuration() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Visit Duration', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextFormField(
          decoration: const InputDecoration(
            labelText: 'Duration (minutes)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          initialValue: '45',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Save', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _addPhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Photo capture feature coming soon!', style: GoogleFonts.poppins()),
      ),
    );
  }

  void _addDocument() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Document upload feature coming soon!', style: GoogleFonts.poppins()),
      ),
    );
  }
}
