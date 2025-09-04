// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chw_tb/config/theme.dart';

class EditPatientScreen extends StatefulWidget {
  final String? patientId;
  
  const EditPatientScreen({super.key, this.patientId});

  @override
  State<EditPatientScreen> createState() => _EditPatientScreenState();
}

class _EditPatientScreenState extends State<EditPatientScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditing = false;
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cnicController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emergencyContactController = TextEditingController();
  final TextEditingController _emergencyPhoneController = TextEditingController();
  final TextEditingController _medicalHistoryController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _currentMedicationsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  String _selectedGender = 'Male';
  String _selectedBloodGroup = 'O+';
  String _selectedTreatmentStatus = 'Active';
  DateTime? _selectedDateOfBirth;
  DateTime? _selectedDiagnosisDate;

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
    _tabController = TabController(length: 3, vsync: this);
    _fadeController.forward();
    
    _loadPatientData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    _medicalHistoryController.dispose();
    _allergiesController.dispose();
    _currentMedicationsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadPatientData() {
    // Mock patient data - will be loaded from Firebase later
    _nameController.text = 'Ahmad Khan';
    _phoneController.text = '+92 300 1234567';
    _cnicController.text = '42101-1234567-1';
    _addressController.text = 'House 123, Street 45, Model Town, Lahore';
    _emergencyContactController.text = 'Fatima Khan (Wife)';
    _emergencyPhoneController.text = '+92 301 7654321';
    _medicalHistoryController.text = 'Diabetes Type 2, Hypertension';
    _allergiesController.text = 'Penicillin';
    _currentMedicationsController.text = 'Metformin 500mg, Amlodipine 5mg';
    _notesController.text = 'Patient is compliant with treatment. Lives with family.';
    _selectedDateOfBirth = DateTime(1985, 3, 15);
    _selectedDiagnosisDate = DateTime(2025, 1, 10);
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Cancel editing - reload original data
        _loadPatientData();
      }
    });
  }

  void _savePatient() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    // Simulate save operation
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
      _isEditing = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Patient updated successfully!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MadadgarTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Patient',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: MadadgarTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: _toggleEditMode,
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Patient',
            ),
          if (_isEditing) ...[
            IconButton(
              onPressed: _toggleEditMode,
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
            ),
            IconButton(
              onPressed: _isLoading ? null : _savePatient,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check),
              tooltip: 'Save Changes',
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Personal', icon: Icon(Icons.person)),
            Tab(text: 'Medical', icon: Icon(Icons.medical_services)),
            Tab(text: 'Notes', icon: Icon(Icons.note)),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Form(
          key: _formKey,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPersonalTab(),
              _buildMedicalTab(),
              _buildNotesTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile photo section
          _buildProfilePhotoSection(),
          
          const SizedBox(height: 24),
          
          // Personal information
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person,
            enabled: _isEditing,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Phone number is required';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _cnicController,
            label: 'CNIC Number',
            icon: Icons.credit_card,
            enabled: _isEditing,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'CNIC is required';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Date of Birth
          _buildDateField(
            label: 'Date of Birth',
            icon: Icons.cake,
            selectedDate: _selectedDateOfBirth,
            enabled: _isEditing,
            onTap: () => _selectDate(context, true),
          ),
          
          const SizedBox(height: 16),
          
          // Gender dropdown
          _buildDropdownField(
            label: 'Gender',
            icon: Icons.person_outline,
            value: _selectedGender,
            items: ['Male', 'Female', 'Other'],
            enabled: _isEditing,
            onChanged: (value) => setState(() => _selectedGender = value!),
          ),
          
          const SizedBox(height: 16),
          
          // Blood Group dropdown
          _buildDropdownField(
            label: 'Blood Group',
            icon: Icons.bloodtype,
            value: _selectedBloodGroup,
            items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
            enabled: _isEditing,
            onChanged: (value) => setState(() => _selectedBloodGroup = value!),
          ),
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _addressController,
            label: 'Address',
            icon: Icons.location_on,
            enabled: _isEditing,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Address is required';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _emergencyContactController,
            label: 'Emergency Contact Name',
            icon: Icons.emergency,
            enabled: _isEditing,
          ),
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _emergencyPhoneController,
            label: 'Emergency Contact Phone',
            icon: Icons.phone_in_talk,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Treatment Status
          _buildDropdownField(
            label: 'Treatment Status',
            icon: Icons.medical_services,
            value: _selectedTreatmentStatus,
            items: ['Active', 'Completed', 'Interrupted', 'On Hold'],
            enabled: _isEditing,
            onChanged: (value) => setState(() => _selectedTreatmentStatus = value!),
          ),
          
          const SizedBox(height: 16),
          
          // Diagnosis Date
          _buildDateField(
            label: 'Diagnosis Date',
            icon: Icons.calendar_month,
            selectedDate: _selectedDiagnosisDate,
            enabled: _isEditing,
            onTap: () => _selectDate(context, false),
          ),
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _medicalHistoryController,
            label: 'Medical History',
            icon: Icons.history,
            enabled: _isEditing,
            maxLines: 4,
          ),
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _allergiesController,
            label: 'Known Allergies',
            icon: Icons.warning,
            enabled: _isEditing,
            maxLines: 2,
          ),
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _currentMedicationsController,
            label: 'Current Medications',
            icon: Icons.medication,
            enabled: _isEditing,
            maxLines: 4,
          ),
          
          const SizedBox(height: 24),
          
          // Medical records section
          if (!_isEditing) _buildMedicalRecordsSection(),
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
            label: 'Additional Notes',
            icon: Icons.note,
            enabled: _isEditing,
            maxLines: 10,
          ),
          
          const SizedBox(height: 24),
          
          // Activity log (read-only)
          if (!_isEditing) _buildActivityLogSection(),
        ],
      ),
    );
  }

  Widget _buildProfilePhotoSection() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
              border: Border.all(color: MadadgarTheme.primaryColor, width: 3),
            ),
            child: Icon(
              Icons.person,
              color: Colors.grey.shade600,
              size: 60,
            ),
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _changeProfilePhoto,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: MadadgarTheme.secondaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
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
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.shade50,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required bool enabled,
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
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.shade50,
      ),
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(item, style: GoogleFonts.poppins()),
      )).toList(),
      onChanged: enabled ? onChanged : null,
    );
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime? selectedDate,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AbsorbPointer(
        child: TextFormField(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: MadadgarTheme.primaryColor),
            suffixIcon: enabled ? const Icon(Icons.calendar_today) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: MadadgarTheme.primaryColor, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: !enabled,
            fillColor: enabled ? null : Colors.grey.shade50,
          ),
          controller: TextEditingController(
            text: selectedDate != null 
                ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
                : '',
          ),
        ),
      ),
    );
  }

  Widget _buildMedicalRecordsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medical Records',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildRecordItem('Blood Test', '2025-01-15', 'Normal'),
            _buildRecordItem('X-Ray', '2025-01-10', 'Clear'),
            _buildRecordItem('Weight Check', '2025-01-20', '75 kg'),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _viewAllRecords(),
                icon: const Icon(Icons.visibility),
                label: Text(
                  'View All Records',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MadadgarTheme.primaryColor,
                  side: BorderSide(color: MadadgarTheme.primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordItem(String type, String date, String result) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              type,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              date,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              result,
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLogSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildActivityItem('Patient registered', '2025-01-10 10:30 AM'),
            _buildActivityItem('First visit completed', '2025-01-12 2:15 PM'),
            _buildActivityItem('Medication updated', '2025-01-15 11:00 AM'),
            _buildActivityItem('Follow-up scheduled', '2025-01-18 9:45 AM'),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String activity, String timestamp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: MadadgarTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                Text(
                  timestamp,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selectDate(BuildContext context, bool isDateOfBirth) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDateOfBirth 
          ? _selectedDateOfBirth ?? DateTime(1990) 
          : _selectedDiagnosisDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isDateOfBirth) {
          _selectedDateOfBirth = picked;
        } else {
          _selectedDiagnosisDate = picked;
        }
      });
    }
  }

  void _changeProfilePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Photo upload feature coming soon!',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }

  void _viewAllRecords() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Medical records viewer coming soon!',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }
}
