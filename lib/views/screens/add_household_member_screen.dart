// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chw_tb/config/theme.dart';

class AddHouseholdMemberScreen extends StatefulWidget {
  final String? patientId;
  final String? householdId;
  
  const AddHouseholdMemberScreen({super.key, this.patientId, this.householdId});

  @override
  State<AddHouseholdMemberScreen> createState() => _AddHouseholdMemberScreenState();
}

class _AddHouseholdMemberScreenState extends State<AddHouseholdMemberScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _formController;
  late Animation<Offset> _slideAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _occupationController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedGender = '';
  String _selectedRelationship = '';
  String _selectedEducation = '';
  bool _hasKnownAllergies = false;
  bool _hasPreviousTbHistory = false;
  bool _isCurrentlySick = false;
  bool _isPregnant = false;
  bool _wantsImmediateScreening = false;
  bool _isSaving = false;
  
  DateTime? _selectedDateOfBirth;
  DateTime? _preferredScreeningDate;
  
  // Form validation flags
  Map<String, bool> _fieldErrors = {};
  
  final List<String> _relationships = [
    'Spouse',
    'Son',
    'Daughter',
    'Father',
    'Mother',
    'Brother',
    'Sister',
    'Grandfather',
    'Grandmother',
    'Uncle',
    'Aunt',
    'Cousin',
    'Other relative',
    'Non-relative',
  ];
  
  final List<String> _educationLevels = [
    'No formal education',
    'Primary school',
    'Secondary school',
    'High school',
    'College/University',
    'Graduate degree',
    'Postgraduate',
  ];

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
    
    _formController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _formController, curve: Curves.easeOut));
    
    _fadeController.forward();
    _formController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _formController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _occupationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MadadgarTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Add Household Member',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: MadadgarTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _saveAndContinue,
            child: Text(
              'SAVE',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildProgressHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPersonalInfoSection(),
                        const SizedBox(height: 24),
                        _buildContactInfoSection(),
                        const SizedBox(height: 24),
                        _buildHealthInfoSection(),
                        const SizedBox(height: 24),
                        _buildScreeningPreferencesSection(),
                        const SizedBox(height: 32),
                        _buildActionButtons(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MadadgarTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.person_add,
                  color: MadadgarTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adding New Household Member',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Patient: ${widget.patientId ?? 'PAT001'} • Household: ${widget.householdId ?? 'HH001'}',
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
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Family members living with TB patients need regular screening for early detection and treatment.',
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
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildSection(
      title: 'Personal Information',
      icon: Icons.person,
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'Enter full name as per official documents',
          isRequired: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Name is required';
            }
            if (value.trim().length < 2) {
              return 'Name must be at least 2 characters';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _ageController,
                label: 'Age',
                hint: 'Years',
                keyboardType: TextInputType.number,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Age is required';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 0 || age > 120) {
                    return 'Enter valid age (0-120)';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdown(
                value: _selectedGender,
                label: 'Gender',
                hint: 'Select gender',
                items: ['Male', 'Female'],
                isRequired: true,
                onChanged: (value) => setState(() => _selectedGender = value!),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        _buildDateField(
          label: 'Date of Birth (Optional)',
          selectedDate: _selectedDateOfBirth,
          onTap: () => _selectDateOfBirth(),
        ),
        
        const SizedBox(height: 16),
        
        _buildDropdown(
          value: _selectedRelationship,
          label: 'Relationship to Patient',
          hint: 'Select relationship',
          items: _relationships,
          isRequired: true,
          onChanged: (value) => setState(() => _selectedRelationship = value!),
        ),
        
        const SizedBox(height: 16),
        
        _buildDropdown(
          value: _selectedEducation,
          label: 'Education Level',
          hint: 'Select education level',
          items: _educationLevels,
          onChanged: (value) => setState(() => _selectedEducation = value!),
        ),
      ],
    );
  }

  Widget _buildContactInfoSection() {
    return _buildSection(
      title: 'Contact Information',
      icon: Icons.contact_phone,
      children: [
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: '+92 300 1234567',
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (value.length < 10) {
                return 'Enter valid phone number';
              }
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _occupationController,
          label: 'Occupation',
          hint: 'Current job or profession',
        ),
      ],
    );
  }

  Widget _buildHealthInfoSection() {
    return _buildSection(
      title: 'Health Information',
      icon: Icons.health_and_safety,
      children: [
        _buildSwitchTile(
          title: 'Known Allergies',
          subtitle: 'Has any known allergies to medications',
          value: _hasKnownAllergies,
          onChanged: (value) => setState(() => _hasKnownAllergies = value),
        ),
        
        _buildSwitchTile(
          title: 'Previous TB History',
          subtitle: 'Previously diagnosed or treated for TB',
          value: _hasPreviousTbHistory,
          onChanged: (value) => setState(() => _hasPreviousTbHistory = value),
        ),
        
        _buildSwitchTile(
          title: 'Currently Sick',
          subtitle: 'Experiencing any symptoms or illness',
          value: _isCurrentlySick,
          onChanged: (value) => setState(() => _isCurrentlySick = value),
        ),
        
        if (_selectedGender == 'Female')
          _buildSwitchTile(
            title: 'Pregnant',
            subtitle: 'Currently pregnant',
            value: _isPregnant,
            onChanged: (value) => setState(() => _isPregnant = value),
          ),
        
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _notesController,
          label: 'Medical Notes',
          hint: 'Any additional health information',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildScreeningPreferencesSection() {
    return _buildSection(
      title: 'Screening Preferences',
      icon: Icons.medical_services,
      children: [
        _buildSwitchTile(
          title: 'Schedule Immediate Screening',
          subtitle: 'Start TB screening process immediately',
          value: _wantsImmediateScreening,
          onChanged: (value) => setState(() => _wantsImmediateScreening = value),
        ),
        
        if (!_wantsImmediateScreening) ...[
          const SizedBox(height: 16),
          
          _buildDateField(
            label: 'Preferred Screening Date',
            selectedDate: _preferredScreeningDate,
            onTap: () => _selectPreferredScreeningDate(),
          ),
        ],
        
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, color: Colors.amber.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Screening Guidelines',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '• Household contacts should be screened within 2 weeks\n'
                '• Children under 5 and elderly are priority groups\n'
                '• Symptomatic contacts need immediate evaluation',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
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
                    fontSize: 18,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    bool isRequired = false,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    bool hasError = _fieldErrors[label] ?? false;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            children: isRequired
                ? [
                    TextSpan(
                      text: ' *',
                      style: GoogleFonts.poppins(color: Colors.red),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.poppins(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: hasError ? Colors.red : Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: hasError ? Colors.red : Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: hasError ? Colors.red : MadadgarTheme.primaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) {
            if (hasError && value.isNotEmpty) {
              setState(() {
                _fieldErrors[label] = false;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required String hint,
    required List<String> items,
    bool isRequired = false,
    required void Function(String?) onChanged,
  }) {
    bool hasError = _fieldErrors[label] ?? false;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            children: isRequired
                ? [
                    TextSpan(
                      text: ' *',
                      style: GoogleFonts.poppins(color: Colors.red),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value.isEmpty ? null : value,
          hint: Text(
            hint,
            style: GoogleFonts.poppins(color: Colors.grey.shade500),
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item, style: GoogleFonts.poppins()),
            );
          }).toList(),
          onChanged: onChanged,
          validator: isRequired
              ? (value) => value == null || value.isEmpty ? '$label is required' : null
              : null,
          style: GoogleFonts.poppins(),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: hasError ? Colors.red : Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: hasError ? Colors.red : Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: hasError ? Colors.red : MadadgarTheme.primaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 12),
                Text(
                  selectedDate != null
                      ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
                      : 'Select date',
                  style: GoogleFonts.poppins(
                    color: selectedDate != null ? Colors.black87 : Colors.grey.shade500,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: MadadgarTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveAndContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: MadadgarTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSaving
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Saving...',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Text(
                    _wantsImmediateScreening ? 'Save & Start Screening' : 'Save Member',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
        // Calculate age from date of birth
        final age = DateTime.now().year - picked.year;
        _ageController.text = age.toString();
      });
    }
  }

  void _selectPreferredScreeningDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _preferredScreeningDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _preferredScreeningDate) {
      setState(() {
        _preferredScreeningDate = picked;
      });
    }
  }

  void _saveAndContinue() async {
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

    // Additional validation
    if (_selectedGender.isEmpty) {
      _showError('Gender is required');
      return;
    }

    if (_selectedRelationship.isEmpty) {
      _showError('Relationship to patient is required');
      return;
    }

    setState(() => _isSaving = true);

    // Mock save operation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Create member data
    final memberData = {
      'id': 'HM${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      'name': _nameController.text.trim(),
      'age': int.parse(_ageController.text),
      'gender': _selectedGender,
      'relationship': _selectedRelationship,
      'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      'occupation': _occupationController.text.trim(),
      'education': _selectedEducation,
      'hasKnownAllergies': _hasKnownAllergies,
      'hasPreviousTbHistory': _hasPreviousTbHistory,
      'isCurrentlySick': _isCurrentlySick,
      'isPregnant': _isPregnant,
      'notes': _notesController.text.trim(),
      'dateOfBirth': _selectedDateOfBirth,
      'patientId': widget.patientId,
      'householdId': widget.householdId,
      'registeredOn': DateTime.now(),
      'screeningStatus': _wantsImmediateScreening ? 'scheduled' : 'pending',
      'nextScreeningDue': _wantsImmediateScreening 
          ? DateTime.now().add(const Duration(days: 1))
          : _preferredScreeningDate ?? DateTime.now().add(const Duration(days: 14)),
      'riskLevel': _calculateRiskLevel(),
    };

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Household member added successfully!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
      ),
    );

    if (_wantsImmediateScreening) {
      // Navigate to screening
      Navigator.pushReplacementNamed(context, '/contact-screening', arguments: memberData);
    } else {
      // Return to household members list
      Navigator.pop(context, memberData);
    }
  }

  String _calculateRiskLevel() {
    int riskScore = 0;
    
    // Age-based risk
    final age = int.tryParse(_ageController.text) ?? 0;
    if (age < 5 || age > 65) riskScore += 2;
    else if (age < 15) riskScore += 1;
    
    // Health conditions
    if (_hasPreviousTbHistory) riskScore += 3;
    if (_isCurrentlySick) riskScore += 2;
    if (_isPregnant) riskScore += 1;
    if (_hasKnownAllergies) riskScore += 1;
    
    // Relationship risk (closer contact = higher risk)
    if (_selectedRelationship == 'Spouse') riskScore += 2;
    else if (['Son', 'Daughter', 'Father', 'Mother'].contains(_selectedRelationship)) riskScore += 1;
    
    if (riskScore >= 4) return 'high';
    if (riskScore >= 2) return 'medium';
    return 'low';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
      ),
    );
  }
}
