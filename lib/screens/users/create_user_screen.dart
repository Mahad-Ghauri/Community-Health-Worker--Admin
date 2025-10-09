import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../services/auth_provider.dart';
import '../../widgets/custom_form_widgets.dart';
import '../../widgets/facility_search_widget.dart';
import '../../theme/theme.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dateOfBirthController = TextEditingController();

  String? _selectedRole;
  String? _selectedGender;
  String? _selectedFacilityId;
  String? _selectedFacilityName;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 6570),
      ), // 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: CHWTheme.primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateOfBirthController.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate password is provided
    if (_passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password is required for user creation'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Create user with Firebase Authentication
      final success = await authProvider.createUserAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _selectedRole!,
        facilityId: _selectedFacilityId,
        dateOfBirth: _dateOfBirthController.text.isNotEmpty
            ? _dateOfBirthController.text
            : null,
        gender: _selectedGender,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'User created successfully! The user can now log in with their email and password.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );

          // Clear form
          _clearForm();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.errorMessage ?? 'Failed to create user',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _passwordController.clear();
    _dateOfBirthController.clear();
    setState(() {
      _selectedRole = null;
      _selectedGender = null;
      _selectedFacilityId = null;
      _selectedFacilityName = null;
    });
  }



  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (value.length < 10) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create User',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Information',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: CHWTheme.primaryColor,
                                ),
                          ),
                          const SizedBox(height: 24),

                          // Name Field
                          CustomTextField(
                            label: 'Full Name',
                            hint: 'Enter full name',
                            controller: _nameController,
                            validator: (value) =>
                                _validateRequired(value, 'Full name'),
                          ),
                          const SizedBox(height: 16),

                          // Email Field
                          CustomTextField(
                            label: 'Email Address',
                            hint: 'Enter email address',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 16),

                          // Phone Field
                          CustomTextField(
                            label: 'Phone Number',
                            hint: 'Enter phone number',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            validator: _validatePhone,
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          CustomTextField(
                            label: 'Password',
                            hint: 'Enter password for the user',
                            controller: _passwordController,
                            obscureText: true,
                            validator: (value) => _validatePassword(value),
                          ),
                          const SizedBox(height: 16),

                          // Role Dropdown
                          CustomDropdown(
                            label: 'Role',
                            value: _selectedRole,
                            items: UserRole.all
                                .where((role) => role != UserRole.admin)
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedRole = value;
                              });
                            },
                            validator: (value) =>
                                _validateRequired(value, 'Role'),
                          ),
                          const SizedBox(height: 16),

                          // Facility Search Widget
                          FacilitySearchWidget(
                            label: 'Facility (Optional)',
                            selectedFacilityId: _selectedFacilityId,
                            selectedFacilityName: _selectedFacilityName,
                            onFacilitySelected: (facilityId, facilityName) {
                              setState(() {
                                _selectedFacilityId = facilityId;
                                _selectedFacilityName = facilityName;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Date of Birth Field
                          CustomTextField(
                            label: 'Date of Birth (Optional)',
                            hint: 'Select date of birth',
                            controller: _dateOfBirthController,
                            onTap: _selectDateOfBirth,
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          const SizedBox(height: 16),

                          // Gender Dropdown
                          CustomDropdown(
                            label: 'Gender (Optional)',
                            value: _selectedGender,
                            items: const ['Male', 'Female', 'Other'],
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value;
                              });
                            },
                          ),
                          const SizedBox(height: 32),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  text: 'Clear Form',
                                  onPressed: _isLoading ? null : _clearForm,
                                  isOutlined: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: CustomButton(
                                  text: 'Create User',
                                  onPressed: _isLoading ? null : _createUser,
                                  isLoading: _isLoading,
                                ),
                              ),
                            ],
                          ),

                          // Error Display
                          if (authProvider.errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      authProvider.errorMessage!,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
