// ignore_for_file: deprecated_member_use, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:chw_tb/config/theme.dart';
import 'package:chw_tb/controllers/providers/secondary_providers.dart';

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
  
  String _selectedGender = '';
  String _selectedRelationship = '';
  bool _wantsImmediateScreening = false;
  bool _isSaving = false;
  
  // HouseholdMember collection schema aligned fields:
  // - name (required)
  // - age (required) 
  // - gender (required)
  // - relationship (required)
  // - phone (optional)
  // - screened (default: false)
  // - screeningStatus (default: 'not_screened')
  // - lastScreeningDate (default: null)
  
  final List<String> _genderOptions = ['Male', 'Female'];
  
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HouseholdProvider>(
      builder: (context, householdProvider, child) {
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
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      _buildHeaderCard(),
                      const SizedBox(height: 24),
                      
                      // Form Fields Card
                      _buildFormCard(),
                      const SizedBox(height: 24),
                      
                      // Screening Option Card
                      _buildScreeningCard(),
                      const SizedBox(height: 32),
                      
                      // Save Button
                      _buildSaveButton(householdProvider),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              MadadgarTheme.primaryColor.withOpacity(0.1),
              MadadgarTheme.primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.person_add,
              size: 48,
              color: MadadgarTheme.primaryColor,
            ),
            const SizedBox(height: 12),
            Text(
              'Add New Household Member',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: MadadgarTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a family member to enable TB contact screening',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Basic Information', Icons.person),
            const SizedBox(height: 20),
            
            // Name Field (Required - aligns with HouseholdMember.name)
            _buildTextField(
              controller: _nameController,
              label: 'Full Name *',
              hint: 'Enter member\'s full name',
              icon: Icons.person_outline,
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
            
            // Age and Gender Row
            Row(
              children: [
                // Age Field (Required - aligns with HouseholdMember.age)
                Expanded(
                  flex: 1,
                  child: _buildTextField(
                    controller: _ageController,
                    label: 'Age *',
                    hint: 'Age',
                    icon: Icons.cake,
                    keyboardType: TextInputType.number,
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
                // Gender Field (Required - aligns with HouseholdMember.gender)
                Expanded(
                  flex: 1,
                  child: _buildDropdown(
                    label: 'Gender *',
                    hint: 'Select gender',
                    value: _selectedGender.isEmpty ? null : _selectedGender,
                    items: _genderOptions,
                    icon: Icons.person,
                    onChanged: (value) => setState(() => _selectedGender = value!),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Gender is required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Relationship Field (Required - aligns with HouseholdMember.relationship)
            _buildDropdown(
              label: 'Relationship to Patient *',
              hint: 'Select relationship',
              value: _selectedRelationship.isEmpty ? null : _selectedRelationship,
              items: _relationships,
              icon: Icons.family_restroom,
              onChanged: (value) => setState(() => _selectedRelationship = value!),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Relationship is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Phone Field (Optional - aligns with HouseholdMember.phone)
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number (Optional)',
              hint: 'Enter phone number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (value.trim().length < 10) {
                    return 'Phone number must be at least 10 digits';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreeningCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('TB Screening', Icons.medical_services),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Household members should be screened for TB. You can screen them immediately after adding.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: Text(
                'Screen for TB immediately after adding',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Recommended for all household members',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
              ),
              value: _wantsImmediateScreening,
              onChanged: (value) => setState(() => _wantsImmediateScreening = value ?? false),
              activeColor: MadadgarTheme.primaryColor,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(HouseholdProvider householdProvider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : () => _saveMember(householdProvider),
        style: ElevatedButton.styleFrom(
          backgroundColor: MadadgarTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.save),
        label: Text(
          _isSaving ? 'Adding Member...' : 'Add Household Member',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: MadadgarTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: MadadgarTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.poppins(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
            prefixIcon: Icon(icon, color: MadadgarTheme.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: MadadgarTheme.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          validator: validator,
          style: GoogleFonts.poppins(color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
            prefixIcon: Icon(icon, color: MadadgarTheme.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: MadadgarTheme.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: GoogleFonts.poppins()),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _saveMember(HouseholdProvider householdProvider) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in all required fields correctly',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Auto-generate patient ID if not provided
      final patientId = widget.patientId ?? 'patient_${DateTime.now().millisecondsSinceEpoch}';
      
      // Auto-generate household ID if not provided
      final householdId = widget.householdId ?? 'household_${DateTime.now().millisecondsSinceEpoch}';
      
      // Add member using HouseholdProvider with fields matching HouseholdMember schema
      final success = await householdProvider.addHouseholdMember(
        patientId: patientId,
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text),
        gender: _selectedGender,
        relationship: _selectedRelationship,
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        // Note: screened, screeningStatus, lastScreeningDate are set by default in HouseholdMember constructor
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Household member added successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to screening if requested
        if (_wantsImmediateScreening) {
          // Create member data for navigation
          final memberData = {
            'name': _nameController.text.trim(),
            'age': int.parse(_ageController.text),
            'gender': _selectedGender,
            'relationship': _selectedRelationship,
            'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          };

          Navigator.pushReplacementNamed(
            context,
            '/contact-screening',
            arguments: {
              'patientId': patientId,
              'householdId': householdId,
              'memberInfo': memberData,
              'fromAddMember': true,
            },
          );
        } else {
          // Go back to household members list
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              householdProvider.error ?? 'Failed to add household member',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString()}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}