import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/facility_provider.dart';
import '../../services/auth_provider.dart';
import '../../models/facility.dart';
import '../../widgets/common_widgets.dart' as common;
import '../../utils/responsive_helper.dart';
import '../../constants/app_constants.dart';

class CreateFacilityScreen extends StatefulWidget {
  const CreateFacilityScreen({super.key});

  @override
  State<CreateFacilityScreen> createState() => _CreateFacilityScreenState();
}

class _CreateFacilityScreenState extends State<CreateFacilityScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  // Form state
  String _selectedType = AppConstants.clinicType;
  String _selectedStatus = 'active';
  final List<String> _selectedServices = [];

  // Available options
  final List<String> _facilityTypes = [
    AppConstants.clinicType,
    AppConstants.healthCenterType,
    AppConstants.hospitalType,
  ];

  final List<String> _statusOptions = ['active', 'inactive'];

  final List<String> _availableServices = [
    AppConstants.tbTreatmentService,
    AppConstants.xrayService,
    AppConstants.labTestsService,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _contactPersonController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Create Facility'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: ResponsiveHelper.isTablet(context)
          ? _buildTabletLayout()
          : _buildMobileLayout(),
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Form section
        Expanded(
          flex: 2,
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: _buildForm(),
            ),
          ),
        ),
        // Info section
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
            ),
            child: _buildInfoPanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildForm(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
            ),
            child: _buildInfoPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Facility Information',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Basic Information
          common.CustomTextField(
            label: 'Facility Name',
            controller: _nameController,
            required: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Facility name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          common.CustomDropdownField<String>(
            label: 'Facility Type',
            value: _selectedType,
            required: true,
            items: _facilityTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_getTypeDisplayName(type)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedType = value ?? AppConstants.clinicType;
              });
            },
          ),
          const SizedBox(height: 16),

          common.CustomDropdownField<String>(
            label: 'Status',
            value: _selectedStatus,
            required: true,
            items: _statusOptions.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status == 'active' ? 'Active' : 'Inactive'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedStatus = value ?? 'active';
              });
            },
          ),
          const SizedBox(height: 24),

          // Contact Information
          Text(
            'Contact Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          common.CustomTextField(
            label: 'Address',
            controller: _addressController,
            required: true,
            maxLines: 2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Address is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          common.CustomTextField(
            label: 'Contact Phone',
            controller: _contactPhoneController,
            required: true,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Contact phone is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          common.CustomTextField(
            label: 'Contact Email',
            controller: _contactEmailController,
            required: true,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Contact email is required';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          common.CustomTextField(
            label: 'Contact Person',
            controller: _contactPersonController,
            required: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Contact person is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Location (Optional)
          Text(
            'Location (Optional)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: common.CustomTextField(
                  label: 'Latitude',
                  controller: _latitudeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final lat = double.tryParse(value);
                      if (lat == null || lat < -90 || lat > 90) {
                        return 'Invalid latitude';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: common.CustomTextField(
                  label: 'Longitude',
                  controller: _longitudeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final lng = double.tryParse(value);
                      if (lng == null || lng < -180 || lng > 180) {
                        return 'Invalid longitude';
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Services
          Text(
            'Services Provided',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ..._availableServices.map((service) {
            return CheckboxListTile(
              title: Text(_getServiceDisplayName(service)),
              value: _selectedServices.contains(service),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedServices.add(service);
                  } else {
                    _selectedServices.remove(service);
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            );
          }),

          if (_selectedServices.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Please select at least one service',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),

          const SizedBox(height: 32),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: common.CustomButton(
                  text: 'Cancel',
                  onPressed: _isLoading ? null : () => context.pop(),
                  isSecondary: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: common.CustomButton(
                  text: 'Create Facility',
                  onPressed: _isLoading ? null : _createFacility,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.business,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Create New Facility',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Add a new healthcare facility to the CHW TB Management system. Fill in all required information to ensure proper facility management.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 24),
        _buildInfoItem(
          Icons.info_outline,
          'Required Fields',
          'Name, type, address, contact information, and at least one service are required.',
        ),
        const SizedBox(height: 16),
        _buildInfoItem(
          Icons.location_on_outlined,
          'Location Coordinates',
          'Latitude and longitude are optional but help with mapping and location services.',
        ),
        const SizedBox(height: 16),
        _buildInfoItem(
          Icons.medical_services_outlined,
          'Services',
          'Select all services that this facility provides to patients.',
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case AppConstants.hospitalType:
        return 'Hospital';
      case AppConstants.healthCenterType:
        return 'Health Center';
      case AppConstants.clinicType:
        return 'Clinic';
      default:
        return type;
    }
  }

  String _getServiceDisplayName(String service) {
    switch (service) {
      case AppConstants.tbTreatmentService:
        return 'TB Treatment';
      case AppConstants.xrayService:
        return 'X-ray Services';
      case AppConstants.labTestsService:
        return 'Laboratory Tests';
      default:
        return service.replaceAll('_', ' ').toUpperCase();
    }
  }

  Future<void> _createFacility() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one service'),
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
      final facilityProvider = Provider.of<FacilityProvider>(context, listen: false);

      // Create coordinates map if both lat/lng are provided
      Map<String, double>? coordinates;
      if (_latitudeController.text.isNotEmpty && _longitudeController.text.isNotEmpty) {
        coordinates = {
          'latitude': double.parse(_latitudeController.text),
          'longitude': double.parse(_longitudeController.text),
        };
      }

      final facility = Facility(
        facilityId: '', // Will be set by Firestore
        name: _nameController.text.trim(),
        type: _selectedType,
        address: _addressController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
        contactEmail: _contactEmailController.text.trim(),
        contactPerson: _contactPersonController.text.trim(),
        coordinates: coordinates,
        staff: [], // Empty initially
        supervisors: [], // Empty initially
        services: _selectedServices,
        status: _selectedStatus,
        createdBy: authProvider.currentUser?.userId ?? '',
        createdAt: DateTime.now(),
      );

      await facilityProvider.createFacility(facility);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${facility.name} created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create facility: $e'),
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
}