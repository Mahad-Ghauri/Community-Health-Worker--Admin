// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_constants.dart';
import '../../../models/facility.dart';
import '../../../models/patient.dart';
import '../../../models/medications.dart';
import '../../../providers/facility_provider.dart';
import '../../../services/patient_service.dart';
import '../../../services/medication_service.dart';
import '../../../services/auth_provider.dart';
import '../../../theme/theme.dart';


class ManageMedicationsScreen extends StatefulWidget {
  const ManageMedicationsScreen({super.key});

  @override
  State<ManageMedicationsScreen> createState() => _ManageMedicationsScreenState();
}

class _ManageMedicationsScreenState extends State<ManageMedicationsScreen> {
  final PatientService _patientService = PatientService();
  final MedicationService _medicationService = MedicationService();

  List<Facility> _facilities = [];
  Facility? _selectedFacility;
  List<Patient> _patients = [];
  Patient? _selectedPatient;
  List<Map<String, dynamic>> _medications = [];
  bool _isLoading = false;
  String? _staffFacilityId;

  @override
  void initState() {
    super.initState();
    _initializeStaffFacility();
  }

  Future<void> _initializeStaffFacility() async {
    // Get the current user's facility ID from AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _staffFacilityId = authProvider.currentUser?.facilityId;

    if (_staffFacilityId != null) {
      await _loadStaffFacility();
    } else {
      // If no facility assigned, show error or handle appropriately
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No facility assigned to your account')),
        );
      }
    }
  }

  Future<void> _loadStaffFacility() async {
    setState(() => _isLoading = true);
    try {
      final facilityProvider = Provider.of<FacilityProvider>(context, listen: false);
      facilityProvider.loadFacilities();
      // Wait a brief moment for the stream to potentially emit initial data
      await Future.delayed(const Duration(milliseconds: 100));

      // Filter facilities to only show the staff's assigned facility
      final allFacilities = facilityProvider.facilities;
      final staffFacility = allFacilities.where((facility) => facility.facilityId == _staffFacilityId).toList();

      setState(() {
        _facilities = staffFacility;
        // Auto-select the facility if only one is available
        if (_facilities.length == 1) {
          _selectedFacility = _facilities.first;
          _loadPatientsForFacility(_selectedFacility!.facilityId);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('[DEBUG] Error loading facility: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading facility: $e')),
        );
      }
    }
  }

  Future<void> _loadPatientsForFacility(String facilityId) async {
    setState(() => _isLoading = true);
    try {
      final patients = await _patientService.getFacilityPatientsStream(
        facilityId: facilityId,
        limit: 1000,
      ).first;

      setState(() {
        _patients = patients;
        _selectedPatient = null;
        _medications = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading patients: $e')),
        );
      }
    }
  }

  Future<void> _loadMedicationsForPatient(String patientId) async {
    setState(() => _isLoading = true);
    try {
      debugPrint('[DEBUG] Fetching medications for patientId: $patientId');
      final activeMeds = await _medicationService.getActiveMedicationsOnce(patientId);
      debugPrint('[DEBUG] Active medications: ${activeMeds.length}');
      final historyMeds = await _medicationService.getMedicationHistoryOnce(patientId);
      debugPrint('[DEBUG] History medications: ${historyMeds.length}');
      debugPrint('[DEBUG] Active meds data: $activeMeds');
      debugPrint('[DEBUG] History meds data: $historyMeds');

      // Combine active and history medications, deduplicating by medicationId
      final Map<String, Map<String, dynamic>> uniqueMedsMap = {};

      // First add active medications
      for (final med in activeMeds) {
        final medId = med['medicationId'] as String?;
        if (medId != null) {
          uniqueMedsMap[medId] = med;
        }
      }

      // Then add history medications (only if not already present)
      for (final med in historyMeds) {
        final medId = med['medicationId'] as String?;
        if (medId != null && !uniqueMedsMap.containsKey(medId)) {
          uniqueMedsMap[medId] = med;
        }
      }

      final uniqueMeds = uniqueMedsMap.values.toList();

      setState(() {
        _medications = uniqueMeds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
       debugPrint('[DEBUG] Error loading medications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading medications: $e')),
        );
      }
    }
  }

  void _selectFacility(Facility facility) {
    // Ensure staff can only select their assigned facility
    if (facility.facilityId != _staffFacilityId) {
      return;
    }

    setState(() {
      _selectedFacility = facility;
      _selectedPatient = null;
      _medications = [];
      _patients = [];
    });
    _loadPatientsForFacility(facility.facilityId);
  }

  void _selectPatient(Patient patient) {
    setState(() => _selectedPatient = patient);
    _loadMedicationsForPatient(patient.patientId);
  }

  Future<void> _addMedication() async {
    if (_selectedPatient == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddMedicationDialog(patientId: _selectedPatient!.patientId),
    );

    if (result != null) {
      await _medicationService.addMedication(result);
      _loadMedicationsForPatient(_selectedPatient!.patientId);
    }
  }

  Future<void> _updateMedication(Map<String, dynamic> medication) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => UpdateMedicationDialog(medication: medication),
    );

    if (result != null) {
      await _medicationService.updateMedication(medication['medicationId'], result);
      _loadMedicationsForPatient(_selectedPatient!.patientId);
    }
  }

  Future<void> _deactivateMedication(String medicationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Medication'),
        content: const Text('Are you sure you want to deactivate this medication?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _medicationService.deactivateMedication(medicationId);
      _loadMedicationsForPatient(_selectedPatient!.patientId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CHWTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Manage Medications'),
        backgroundColor: CHWTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppConstants.staffDashboardRoute),
        ),
      ),
      body: _buildContent(),
      floatingActionButton: _selectedPatient != null
          ? FloatingActionButton(
              onPressed: _addMedication,
              backgroundColor: CHWTheme.primaryColor,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildContent() {
    if (_isLoading && _facilities.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Row(
      children: [
        // Facilities List
        Expanded(
          flex: 2,
          child: _buildFacilitiesList(),
        ),
        // Patients List
        if (_selectedFacility != null)
          Expanded(
            flex: 2,
            child: _buildPatientsList(),
          ),
        // Medications List
        if (_selectedPatient != null)
          Expanded(
            flex: 3,
            child: _buildMedicationsList(),
          ),
      ],
    );
  }

  Widget _buildFacilitiesList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Facility',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Access restricted to your assigned facility',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Expanded(
          child: _facilities.isEmpty && !_isLoading
              ? const Center(child: Text('No facility assigned'))
              : ListView.builder(
                  itemCount: _facilities.length,
                  itemBuilder: (context, index) {
                    final facility = _facilities[index];
                    final isSelected = _selectedFacility?.facilityId == facility.facilityId;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: CHWTheme.primaryColor.withOpacity(0.1),
                      title: Text(facility.name),
                      subtitle: Text(facility.type),
                      onTap: () => _selectFacility(facility),
                      enabled: facility.facilityId == _staffFacilityId,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPatientsList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Text(
            'Patients at ${_selectedFacility!.name}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: _patients.isEmpty && !_isLoading
              ? const Center(child: Text('No patients found'))
              : ListView.builder(
                  itemCount: _patients.length,
                  itemBuilder: (context, index) {
                    final patient = _patients[index];
                    final isSelected = _selectedPatient?.patientId == patient.patientId;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: CHWTheme.primaryColor.withOpacity(0.1),
                      title: Text(patient.name),
                      subtitle: Text('${patient.age} years • ${patient.tbStatus.replaceAll('_', ' ')}'),
                      onTap: () => _selectPatient(patient),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMedicationsList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Text(
            'Medications for ${_selectedPatient!.name}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: _medications.isEmpty && !_isLoading
              ? const Center(child: Text('No medications found'))
              : ListView.builder(
                  itemCount: _medications.length,
                  itemBuilder: (context, index) {
                    final med = _medications[index];
                    final medication = Medication.fromFirestore(med, docId: med['medicationId']);
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(medication.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${medication.dosage} • ${medication.frequency}'),
                            Text('Phase: ${medication.tbPhase}'),
                            Text('Active: ${medication.isActive ? 'Yes' : 'No'}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _updateMedication(med),
                            ),
                            if (medication.isActive)
                              IconButton(
                                icon: const Icon(Icons.cancel),
                                onPressed: () => _deactivateMedication(medication.medicationId),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class AddMedicationDialog extends StatefulWidget {
  final String patientId;

  const AddMedicationDialog({super.key, required this.patientId});

  @override
  State<AddMedicationDialog> createState() => _AddMedicationDialogState();
}

class _AddMedicationDialogState extends State<AddMedicationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _dosageController = TextEditingController();
  final _durationController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _pillCountController = TextEditingController(text: '30');
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  String _frequency = 'once_daily';
  String _tbPhase = 'intensive';

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _startDate) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Medication'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medication Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _typeController,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Dosage',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'once_daily', child: Text('Once Daily')),
                  DropdownMenuItem(value: 'twice_daily', child: Text('Twice Daily')),
                  DropdownMenuItem(value: 'thrice_daily', child: Text('Thrice Daily')),
                ],
                onChanged: (value) => setState(() => _frequency = value!),
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duration',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _pillCountController,
                      decoration: const InputDecoration(
                        labelText: 'Pill Count',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectStartDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(DateFormat('yyyy-MM-dd').format(_startDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectEndDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : 'Not set'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _tbPhase,
                decoration: const InputDecoration(
                  labelText: 'TB Phase',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'intensive', child: Text('Intensive')),
                  DropdownMenuItem(value: 'continuation', child: Text('Continuation')),
                ],
                onChanged: (value) => setState(() => _tbPhase = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, {
                'patientId': widget.patientId,
                'name': _nameController.text,
                'type': _typeController.text,
                'dosage': _dosageController.text,
                'frequency': _frequency,
                'duration': _durationController.text,
                'instructions': _instructionsController.text,
                'tbPhase': _tbPhase,
                'startDate': _startDate,
                'endDate': _endDate,
                'isActive': true,
                'createdBy': 'staff', // TODO: get from auth
                'pillCount': int.parse(_pillCountController.text),
                'knownSideEffects': [],
                'contraindications': [],
              });
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class UpdateMedicationDialog extends StatefulWidget {
  final Map<String, dynamic> medication;

  const UpdateMedicationDialog({super.key, required this.medication});

  @override
  State<UpdateMedicationDialog> createState() => _UpdateMedicationDialogState();
}

class _UpdateMedicationDialogState extends State<UpdateMedicationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _typeController;
  late final TextEditingController _dosageController;
  late final TextEditingController _durationController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _pillCountController;
  late DateTime _startDate;
  late DateTime? _endDate;
  late String _frequency;
  late String _tbPhase;

  @override
  void initState() {
    super.initState();
    final med = widget.medication;
    _nameController = TextEditingController(text: med['name']);
    _typeController = TextEditingController(text: med['type']);
    _dosageController = TextEditingController(text: med['dosage']);
    _durationController = TextEditingController(text: med['duration']);
    _instructionsController = TextEditingController(text: med['instructions']);
    _pillCountController = TextEditingController(text: med['pillCount']?.toString() ?? '30');

    // Initialize dates
    _startDate = med['startDate'] is DateTime ? med['startDate'] : DateTime.now();
    _endDate = med['endDate'] is DateTime ? med['endDate'] : null;

    // Ensure frequency is one of the allowed values
    final allowedFrequencies = ['once_daily', 'twice_daily', 'thrice_daily'];
    final frequencyRaw = med['frequency']?.toString().toLowerCase() ?? 'once_daily';
    _frequency = allowedFrequencies.contains(frequencyRaw) ? frequencyRaw : 'once_daily';

    // Ensure tbPhase is always one of the allowed values
    final allowedPhases = ['intensive', 'continuation'];
    final tbPhaseRaw = med['tbPhase']?.toString().toLowerCase() ?? 'intensive';
    _tbPhase = allowedPhases.contains(tbPhaseRaw) ? tbPhaseRaw : 'intensive';
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _startDate) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Medication'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medication Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _typeController,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Dosage',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'once_daily', child: Text('Once Daily')),
                  DropdownMenuItem(value: 'twice_daily', child: Text('Twice Daily')),
                  DropdownMenuItem(value: 'thrice_daily', child: Text('Thrice Daily')),
                ],
                onChanged: (value) => setState(() => _frequency = value!),
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duration',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _pillCountController,
                      decoration: const InputDecoration(
                        labelText: 'Pill Count',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectStartDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(DateFormat('yyyy-MM-dd').format(_startDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectEndDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : 'Not set'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _tbPhase,
                decoration: const InputDecoration(
                  labelText: 'TB Phase',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'intensive', child: Text('Intensive')),
                  DropdownMenuItem(value: 'continuation', child: Text('Continuation')),
                ],
                onChanged: (value) => setState(() => _tbPhase = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, {
                'name': _nameController.text,
                'type': _typeController.text,
                'dosage': _dosageController.text,
                'frequency': _frequency,
                'duration': _durationController.text,
                'instructions': _instructionsController.text,
                'startDate': _startDate,
                'endDate': _endDate,
                'tbPhase': _tbPhase,
                'pillCount': int.parse(_pillCountController.text),
              });
            }
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}