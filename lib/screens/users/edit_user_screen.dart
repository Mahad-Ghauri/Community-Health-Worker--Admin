import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/user_provider.dart';
import '../../providers/facility_provider.dart';
import '../../widgets/custom_form_widgets.dart';
import '../../widgets/facility_search_widget.dart';
import '../../theme/theme.dart';

class EditUserScreen extends StatefulWidget {
  final String userId;

  const EditUserScreen({super.key, required this.userId});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  
  String? _selectedRole;
  String? _selectedGender;
  String? _selectedFacilityId;
  String? _selectedFacilityName;
  bool _isLoading = false;
  bool _isLoadingUser = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadUserById(widget.userId);
      
      final user = userProvider.selectedUser;
      if (user != null) {
        setState(() {
          _currentUser = user;
          _nameController.text = user.name;
          _emailController.text = user.email;
          _phoneController.text = user.phone;
          _selectedRole = user.role;
          _selectedGender = user.gender;
          _selectedFacilityId = user.facilityId;
          _dateOfBirthController.text = user.dateOfBirth ?? '';
          _isLoadingUser = false;
        });

        // Load facility name if facilityId exists
        if (user.facilityId != null) {
          _loadFacilityName(user.facilityId!);
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingUser = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadFacilityName(String facilityId) async {
    try {
      final facilityProvider = Provider.of<FacilityProvider>(context, listen: false);
      final facility = await facilityProvider.getFacilityById(facilityId);
      if (facility != null && mounted) {
        setState(() {
          _selectedFacilityName = facility.name;
        });
      }
    } catch (e) {
      // Ignore facility loading errors
    }
  }

  Future<void> _selectDateOfBirth() async {
    DateTime? initialDate;
    if (_dateOfBirthController.text.isNotEmpty) {
      try {
        final parts = _dateOfBirthController.text.split('/');
        if (parts.length == 3) {
          initialDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      } catch (e) {
        // Use default if parsing fails
      }
    }
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: CHWTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      final updateData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _selectedRole!,
        'facilityId': _selectedFacilityId,
        'dateOfBirth': _dateOfBirthController.text.isNotEmpty 
            ? _dateOfBirthController.text 
            : null,
        'gender': _selectedGender,
      };

      final success = await userProvider.updateUser(widget.userId, updateData);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(userProvider.error ?? 'Failed to update user'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
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

  void _resetForm() {
    if (_currentUser != null) {
      setState(() {
        _nameController.text = _currentUser!.name;
        _emailController.text = _currentUser!.email;
        _phoneController.text = _currentUser!.phone;
        _selectedRole = _currentUser!.role;
        _selectedGender = _currentUser!.gender;
        _selectedFacilityId = _currentUser!.facilityId;
        _dateOfBirthController.text = _currentUser!.dateOfBirth ?? '';
      });

      // Reload facility name if needed
      if (_currentUser!.facilityId != null) {
        _loadFacilityName(_currentUser!.facilityId!);
      } else {
        setState(() {
          _selectedFacilityName = null;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit User',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),
          Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    if (_currentUser == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit User',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          const Expanded(
            child: Center(
              child: Text(
                'User not found',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
          ),
        ],
      );
    }

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit User',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                          Row(
                            children: [
                              Text(
                                'User Information',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: CHWTheme.primaryColor,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: CHWTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'ID: ${widget.userId}',
                                  style: TextStyle(
                                    color: CHWTheme.primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Name Field
                          CustomTextField(
                            label: 'Full Name',
                            hint: 'Enter full name',
                            controller: _nameController,
                            validator: (value) => _validateRequired(value, 'Full name'),
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
                          
                          // Role Dropdown
                          CustomDropdown(
                            label: 'Role',
                            value: _selectedRole,
                            items: UserRole.all,
                            onChanged: (value) {
                              setState(() {
                                _selectedRole = value;
                              });
                            },
                            validator: (value) => _validateRequired(value, 'Role'),
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
                                  text: 'Reset Changes',
                                  onPressed: _isLoading ? null : _resetForm,
                                  isOutlined: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: CustomButton(
                                  text: 'Update User',
                                  onPressed: _isLoading ? null : _updateUser,
                                  isLoading: _isLoading,
                                ),
                              ),
                            ],
                          ),
                          
                          // Error Display
                          if (userProvider.error != null) ...[
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
                                  Icon(Icons.error_outline, color: Colors.red.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      userProvider.error!,
                                      style: TextStyle(color: Colors.red.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          // User Creation Info
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'User Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Created: ${_currentUser!.createdAt.day}/${_currentUser!.createdAt.month}/${_currentUser!.createdAt.year}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'User ID: ${_currentUser!.userId}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
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