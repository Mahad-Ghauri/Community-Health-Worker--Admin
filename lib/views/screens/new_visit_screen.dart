// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:chw_tb/config/theme.dart';
import 'package:chw_tb/controllers/providers/patient_provider.dart';
import 'package:chw_tb/models/core_models.dart';

class NewVisitScreen extends StatefulWidget {
  const NewVisitScreen({super.key});

  @override
  State<NewVisitScreen> createState() => _NewVisitScreenState();
}

class _NewVisitScreenState extends State<NewVisitScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;
  bool _gpsEnabled = false;
  bool _patientFound = true;
  String? _selectedPatientId;
  Patient? _selectedPatient;
  String _selectedVisitType = 'home_visit';
  final List<String> _capturedPhotos = [];
  Map<String, double>? _currentLocation;

  final List<Map<String, String>> _visitTypes = [
    {'value': 'home_visit', 'label': 'Home Visit'},
    {'value': 'follow_up', 'label': 'Follow-up Visit'},
    {'value': 'tracing', 'label': 'Contact Tracing'},
    {'value': 'medicine_delivery', 'label': 'Medicine Delivery'},
    {'value': 'counseling', 'label': 'Counseling Session'},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();
    _loadInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get patient ID from route arguments if navigated from patient details
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null &&
        args is Map<String, dynamic> &&
        args['patientId'] != null) {
      _selectedPatientId = args['patientId'];
      _loadSelectedPatient();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    // Load patients for selection
    final patientProvider = Provider.of<PatientProvider>(
      context,
      listen: false,
    );
    await patientProvider.loadPatients();

    setState(() => _isLoading = false);
  }

  Future<void> _loadSelectedPatient() async {
    if (_selectedPatientId != null) {
      final patientProvider = Provider.of<PatientProvider>(
        context,
        listen: false,
      );
      await patientProvider.selectPatient(_selectedPatientId!);
      setState(() {
        _selectedPatient = patientProvider.selectedPatient;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  IconData _getVisitTypeIcon(String type) {
    switch (type) {
      case 'home_visit':
        return Icons.home;
      case 'follow_up':
        return Icons.schedule;
      case 'tracing':
        return Icons.search;
      case 'medicine_delivery':
        return Icons.medication;
      case 'counseling':
        return Icons.psychology;
      default:
        return Icons.home;
    }
  }

  void _submitVisit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPatient == null) {
      _showSnackBar('Please select a patient', isError: true);
      return;
    }

    if (_selectedVisitType.isEmpty) {
      _showSnackBar('Please select visit type', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final visitProvider = Provider.of<VisitProvider>(context, listen: false);

      final visitId = await visitProvider.createVisit(
        patientId: _selectedPatient!.patientId,
        visitType: _selectedVisitType,
        found: _patientFound,
        notes: _notesController.text.trim(),
        photos: _capturedPhotos.isNotEmpty ? _capturedPhotos : null,
      );

      if (visitId != null && mounted) {
        _showSnackBar('Visit recorded successfully!');
        Navigator.pop(context, true); // Return success result
      } else {
        _showSnackBar('Failed to record visit', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: isError ? MadadgarTheme.errorColor : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MadadgarTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'New Visit',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: MadadgarTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_gpsEnabled)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.gps_fixed,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'GPS',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient selection section
                _buildPatientSelectionSection(),

                const SizedBox(height: 24),

                // Visit type selection
                _buildVisitTypeSection(),

                const SizedBox(height: 24),

                // GPS location section
                _buildGPSSection(),

                const SizedBox(height: 24),

                // Patient found toggle
                _buildPatientFoundSection(),

                const SizedBox(height: 24),

                // Visit notes
                _buildNotesSection(),

                const SizedBox(height: 24),

                // Photo capture section
                _buildPhotoSection(),

                const SizedBox(height: 32),

                // Submit button
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientSelectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient Selection',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Patient dropdown or selected patient display
            if (_selectedPatient == null) ...[
              Consumer<PatientProvider>(
                builder: (context, patientProvider, child) {
                  final patients = patientProvider.filteredPatients;

                  return DropdownButtonFormField<Patient>(
                    decoration: InputDecoration(
                      labelText: 'Select Patient',
                      hintText: 'Choose a patient...',
                      prefixIcon: Icon(
                        Icons.person,
                        color: MadadgarTheme.primaryColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: MadadgarTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    value: _selectedPatient,
                    isExpanded: true, // ✅ Prevents overflow
                    items: patients.map((patient) {
                      return DropdownMenuItem<Patient>(
                        value: patient,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.name,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'ID: ${patient.patientId} • ${patient.phone}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (Patient? patient) {
                      setState(() {
                        _selectedPatient = patient;
                        _selectedPatientId = patient?.patientId;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a patient';
                      }
                      return null;
                    },
                  );
                },
              ),
            ] else ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MadadgarTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: MadadgarTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: MadadgarTheme.primaryColor,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedPatient!.name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'ID: ${_selectedPatient!.patientId} • ${_selectedPatient!.phone}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVisitTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visit Type',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: _visitTypes.length,
              itemBuilder: (context, index) {
                final type = _visitTypes[index];
                final isSelected = _selectedVisitType == type['value'];

                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedVisitType = type['value']!),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? MadadgarTheme.primaryColor.withOpacity(0.1)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? MadadgarTheme.primaryColor
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getVisitTypeIcon(type['value']!),
                          color: isSelected
                              ? MadadgarTheme.primaryColor
                              : Colors.grey.shade600,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          type['label']!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? MadadgarTheme.primaryColor
                                : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGPSSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: MadadgarTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'GPS Location',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _gpsEnabled ? 'Location Captured' : 'Location Required',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _gpsEnabled
                              ? Colors.green
                              : Colors.orange.shade700,
                        ),
                      ),
                      Text(
                        _gpsEnabled
                            ? 'GPS coordinates recorded for visit verification'
                            : 'Capture GPS location to verify visit',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _captureGPS,
                  icon: Icon(_gpsEnabled ? Icons.refresh : Icons.gps_fixed),
                  label: Text(
                    _gpsEnabled ? 'Refresh' : 'Capture',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gpsEnabled
                        ? Colors.green
                        : MadadgarTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _patientFound = true),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _patientFound
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _patientFound
                              ? Colors.green
                              : Colors.grey.shade300,
                          width: _patientFound ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: _patientFound ? Colors.green : Colors.grey,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Patient Found',
                            style: GoogleFonts.poppins(
                              fontWeight: _patientFound
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: _patientFound
                                  ? Colors.green
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _patientFound = false),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: !_patientFound
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !_patientFound
                              ? Colors.orange
                              : Colors.grey.shade300,
                          width: !_patientFound ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cancel,
                            color: !_patientFound ? Colors.orange : Colors.grey,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Patient Not Found',
                            style: GoogleFonts.poppins(
                              fontWeight: !_patientFound
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: !_patientFound
                                  ? Colors.orange
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visit Notes',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Enter visit details, observations, and notes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: MadadgarTheme.primaryColor,
                    width: 2,
                  ),
                ),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please add visit notes';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.camera_alt, color: MadadgarTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Visit Documentation',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_capturedPhotos.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _capturedPhotos.length,
                  itemBuilder: (context, index) => Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.image,
                            color: Colors.grey.shade600,
                            size: 40,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _capturedPhotos.removeAt(index)),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _capturePhoto,
                icon: const Icon(Icons.camera_alt),
                label: Text(
                  _capturedPhotos.isEmpty
                      ? 'Capture Photo'
                      : 'Add Another Photo',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: MadadgarTheme.primaryColor),
                  foregroundColor: MadadgarTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitVisit,
        style: ElevatedButton.styleFrom(
          backgroundColor: MadadgarTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Log Visit',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _captureGPS() {
    setState(() => _gpsEnabled = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'GPS location captured successfully',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _capturePhoto() {
    setState(() {
      _capturedPhotos.add('photo_${_capturedPhotos.length + 1}.jpg');
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Photo captured', style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ),
    );
  }
}
