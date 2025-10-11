import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../theme/theme.dart';
import '../../constants/app_constants.dart';
import 'package:go_router/go_router.dart';

class SupervisorPatientsScreen extends StatefulWidget {
  const SupervisorPatientsScreen({super.key});

  @override
  State<SupervisorPatientsScreen> createState() =>
      _SupervisorPatientsScreenState();
}

class _SupervisorPatientsScreenState extends State<SupervisorPatientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedTbStatus = '';
  String _selectedGender = '';

  @override
  void initState() {
    super.initState();
    // Initialize with all patients (no facility filter for supervisor)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllPatients();
    });
  }

  void _loadAllPatients() {
    // For supervisor, we'll load all patients without facility filter
    // This is a simplified approach - in production you might want a different service method
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CHWTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('All Patients'),
        backgroundColor: CHWTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppConstants.supervisorDashboardRoute),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filters bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search patients by name, phone, or ID...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    // Implement search logic here
                  },
                ),
                const SizedBox(height: 12),
                // Quick filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _selectedTbStatus.isEmpty,
                        onTap: () => setState(() => _selectedTbStatus = ''),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Newly Diagnosed',
                        selected:
                            _selectedTbStatus ==
                            AppConstants.newlyDiagnosedStatus,
                        onTap: () => setState(
                          () => _selectedTbStatus =
                              AppConstants.newlyDiagnosedStatus,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'On Treatment',
                        selected:
                            _selectedTbStatus == AppConstants.onTreatmentStatus,
                        onTap: () => setState(
                          () => _selectedTbStatus =
                              AppConstants.onTreatmentStatus,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Completed',
                        selected:
                            _selectedTbStatus ==
                            AppConstants.treatmentCompletedStatus,
                        onTap: () => setState(
                          () => _selectedTbStatus =
                              AppConstants.treatmentCompletedStatus,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Lost to Follow-up',
                        selected:
                            _selectedTbStatus ==
                            AppConstants.lostToFollowUpStatus,
                        onTap: () => setState(
                          () => _selectedTbStatus =
                              AppConstants.lostToFollowUpStatus,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Patients list
          Expanded(child: _buildPatientsList()),
        ],
      ),
    );
  }

  Widget _buildPatientsList() {
    // This would be replaced with actual data from a provider
    // For now, showing a placeholder with sample data structure
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10, // Placeholder count
      itemBuilder: (context, index) {
        return _buildPatientCard(
          Patient(
            patientId: 'PAT$index',
            name: 'Patient $index',
            age: 25 + index,
            phone: '+123456789$index',
            address: 'Address $index',
            gender: index % 2 == 0 ? 'male' : 'female',
            tbStatus: _getRandomTbStatus(index),
            assignedCHW: 'CHW$index',
            assignedFacility: 'Facility $index',
            treatmentFacility: 'Treatment Facility $index',
            gpsLocation: {'latitude': 0.0, 'longitude': 0.0},
            consent: true,
            createdBy: 'supervisor',
            createdAt: DateTime.now().subtract(Duration(days: index)),
          ),
        );
      },
    );
  }

  String _getRandomTbStatus(int index) {
    final statuses = [
      AppConstants.newlyDiagnosedStatus,
      AppConstants.onTreatmentStatus,
      AppConstants.treatmentCompletedStatus,
      AppConstants.lostToFollowUpStatus,
    ];
    return statuses[index % statuses.length];
  }

  Widget _buildPatientCard(Patient patient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showPatientDetails(patient),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      patient.name,
                      style: CHWTheme.subheadingStyle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(patient.tbStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      patient.statusDisplayName,
                      style: CHWTheme.bodyStyle.copyWith(
                        color: _getStatusColor(patient.tbStatus),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '${patient.age} years • ${patient.gender}',
                    style: CHWTheme.bodyStyle.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    patient.phone,
                    style: CHWTheme.bodyStyle.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      patient.address,
                      style: CHWTheme.bodyStyle.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CHW: ${patient.assignedCHW}',
                    style: CHWTheme.bodyStyle.copyWith(
                      color: CHWTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Added ${patient.daysSinceCreation} days ago',
                    style: CHWTheme.bodyStyle.copyWith(
                      color: Colors.grey.shade500,
                      fontSize: 12,
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

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.newlyDiagnosedStatus:
        return const Color(0xFF42A5F5);
      case AppConstants.onTreatmentStatus:
        return const Color(0xFF66BB6A);
      case AppConstants.treatmentCompletedStatus:
        return const Color(0xFFFFB300);
      case AppConstants.lostToFollowUpStatus:
        return const Color(0xFFEF5350);
      default:
        return Colors.grey;
    }
  }

  void _showPatientDetails(Patient patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Patient Details',
                      style: CHWTheme.headingStyle.copyWith(
                        color: CHWTheme.primaryColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Patient ID', patient.patientId),
                _buildDetailRow('Name', patient.name),
                _buildDetailRow('Age', '${patient.age} years'),
                _buildDetailRow('Gender', patient.gender),
                _buildDetailRow('Phone', patient.phone),
                _buildDetailRow('Address', patient.address),
                _buildDetailRow('TB Status', patient.statusDisplayName),
                _buildDetailRow('Assigned CHW', patient.assignedCHW),
                _buildDetailRow('Assigned Facility', patient.assignedFacility),
                _buildDetailRow(
                  'Treatment Facility',
                  patient.treatmentFacility,
                ),
                _buildDetailRow('Consent', patient.consent ? 'Yes' : 'No'),
                if (patient.validatedBy != null)
                  _buildDetailRow('Validated By', patient.validatedBy!),
                _buildDetailRow('Created At', _formatDate(patient.createdAt)),
                if (patient.diagnosisDate != null)
                  _buildDetailRow(
                    'Diagnosis Date',
                    _formatDate(patient.diagnosisDate!),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Navigate to edit patient or other actions
                        },
                        child: const Text('Edit Patient'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Navigate to patient visits or other actions
                        },
                        child: const Text('View Visits'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: CHWTheme.bodyStyle.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(value, style: CHWTheme.bodyStyle)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Patients'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedTbStatus.isEmpty ? null : _selectedTbStatus,
              decoration: const InputDecoration(labelText: 'TB Status'),
              items: [
                const DropdownMenuItem(value: '', child: Text('All Statuses')),
                const DropdownMenuItem(
                  value: AppConstants.newlyDiagnosedStatus,
                  child: Text('Newly Diagnosed'),
                ),
                const DropdownMenuItem(
                  value: AppConstants.onTreatmentStatus,
                  child: Text('On Treatment'),
                ),
                const DropdownMenuItem(
                  value: AppConstants.treatmentCompletedStatus,
                  child: Text('Treatment Completed'),
                ),
                const DropdownMenuItem(
                  value: AppConstants.lostToFollowUpStatus,
                  child: Text('Lost to Follow-up'),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _selectedTbStatus = value ?? ''),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedGender.isEmpty ? null : _selectedGender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: [
                const DropdownMenuItem(value: '', child: Text('All Genders')),
                const DropdownMenuItem(value: 'male', child: Text('Male')),
                const DropdownMenuItem(value: 'female', child: Text('Female')),
              ],
              onChanged: (value) =>
                  setState(() => _selectedGender = value ?? ''),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedTbStatus = '';
                _selectedGender = '';
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Apply filters
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: CHWTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: CHWTheme.primaryColor,
    );
  }
}
