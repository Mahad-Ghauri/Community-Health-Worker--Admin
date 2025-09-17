// ignore_for_file: deprecated_member_use

import 'package:chw_admin/screens/staff/patients/patient_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_constants.dart';
import '../../../models/patient.dart';
import '../../../services/auth_provider.dart';
import '../../../theme/theme.dart';
import '../../../utils/responsive_helper.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  List<Patient> _patients = [];
  String? _facilityId;
  String _searchQuery = '';
  String _statusFilter = 'all';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // Get current user's facility ID
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      _facilityId = user.facilityId ?? 'fac001';

      // Query patients for this facility
      Query query = FirebaseFirestore.instance
          .collection(AppConstants.patientsCollection)
          .where('treatmentFacility', isEqualTo: _facilityId);

      // Apply status filter if not 'all'
      if (_statusFilter != 'all') {
        query = query.where('tbStatus', isEqualTo: _statusFilter);
      }

      final patientsSnapshot = await query.get();

      // Convert to Patient objects
      final patients = patientsSnapshot.docs
          .map((doc) => Patient.fromFirestore(doc))
          .toList();

      // Apply search filter if any
      final filteredPatients = _searchQuery.isEmpty
          ? patients
          : patients.where((patient) {
              final searchLower = _searchQuery.toLowerCase();
              return patient.name.toLowerCase().contains(searchLower) ||
                  patient.patientId.toLowerCase().contains(searchLower) ||
                  patient.phone.toLowerCase().contains(searchLower);
            }).toList();

      // Sort by creation date (newest first)
      filteredPatients.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _patients = filteredPatients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load patients: $e';
        _isLoading = false;
      });
    }
  }

  void _applySearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadPatients();
  }

  void _applyStatusFilter(String status) {
    setState(() {
      _statusFilter = status;
    });
    _loadPatients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CHWTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Patient List'),
        backgroundColor: CHWTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatients,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add patient screen
          // Navigator.pushNamed(context, '/add-patient');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add Patient functionality coming soon'),
            ),
          );
        },
        backgroundColor: CHWTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: CHWTheme.errorColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Patients',
              style: CHWTheme.headingStyle.copyWith(color: CHWTheme.errorColor),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: CHWTheme.bodyStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPatients,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CHWTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: _patients.isEmpty ? _buildEmptyState() : _buildPatientList(),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search patients by name, ID or phone',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _applySearch('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onSubmitted: _applySearch,
          ),
          const SizedBox(height: 16),
          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Newly Diagnosed',
                  AppConstants.newlyDiagnosedStatus,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'On Treatment',
                  AppConstants.onTreatmentStatus,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Completed',
                  AppConstants.treatmentCompletedStatus,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Lost to Follow-up',
                  AppConstants.lostToFollowUpStatus,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        _applyStatusFilter(value);
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: CHWTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: CHWTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? CHWTheme.primaryColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No patients found',
            style: CHWTheme.headingStyle.copyWith(
              color: Colors.grey.shade700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _statusFilter != 'all'
                ? 'Try changing your search or filter criteria'
                : 'Add patients to get started',
            style: CHWTheme.bodyStyle.copyWith(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_searchQuery.isNotEmpty || _statusFilter != 'all')
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _statusFilter = 'all';
                });
                _loadPatients();
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CHWTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPatientList() {
    return ResponsiveWidget(
      mobile: ListView.builder(
        itemCount: _patients.length,
        itemBuilder: (context, index) => _buildPatientCard(_patients[index]),
      ),
      tablet: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        padding: const EdgeInsets.all(16),
        itemCount: _patients.length,
        itemBuilder: (context, index) => _buildPatientCard(_patients[index]),
      ),
      desktop: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        padding: const EdgeInsets.all(16),
        itemCount: _patients.length,
        itemBuilder: (context, index) => _buildPatientCard(_patients[index]),
      ),
    );
  }

  Widget _buildPatientCard(Patient patient) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PatientDetailsScreen(patientId: patient.patientId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with status indicator
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: _getStatusColor(
                          patient.tbStatus,
                        ).withOpacity(0.2),
                        child: Text(
                          patient.name.isNotEmpty
                              ? patient.name.substring(0, 1).toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: _getStatusColor(patient.tbStatus),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _getStatusColor(patient.tbStatus),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Patient info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style: CHWTheme.subheadingStyle.copyWith(
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${patient.patientId}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${patient.age} years • ${patient.gender}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(patient.tbStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(
                          patient.tbStatus,
                        ).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      patient.statusDisplayName,
                      style: TextStyle(
                        color: _getStatusColor(patient.tbStatus),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Contact info and address
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          patient.phone,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            patient.address,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Registration date
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Registered: ${DateFormat('MMM d, y').format(patient.createdAt)}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
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
        return Colors.blue;
      case AppConstants.onTreatmentStatus:
        return Colors.green;
      case AppConstants.treatmentCompletedStatus:
        return Colors.purple;
      case AppConstants.lostToFollowUpStatus:
        return CHWTheme.errorColor;
      default:
        return Colors.grey;
    }
  }
}
