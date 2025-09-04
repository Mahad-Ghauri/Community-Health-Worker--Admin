// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chw_tb/config/theme.dart';

class ScreeningResultsScreen extends StatefulWidget {
  final String? contactId;
  final String? householdId;
  
  const ScreeningResultsScreen({super.key, this.contactId, this.householdId});

  @override
  State<ScreeningResultsScreen> createState() => _ScreeningResultsScreenState();
}

class _ScreeningResultsScreenState extends State<ScreeningResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Test Results
  String _testType = 'chest_xray';
  String _testResult = '';
  String _testFacility = '';
  DateTime? _testDate;
  String _testNotes = '';
  
  // Follow-up Actions
  List<String> _followUpActions = [];
  String _referralStatus = '';
  DateTime? _nextScreeningDate;
  String _recommendations = '';
  
  final List<String> _testTypes = [
    'chest_xray',
    'sputum_microscopy',
    'tuberculin_skin_test',
    'interferon_gamma_release',
    'clinical_assessment'
  ];
  
  final List<String> _testResults = [
    'negative',
    'positive',
    'inconclusive',
    'pending'
  ];
  
  final List<String> _availableActions = [
    'Continue monitoring',
    'Start treatment',
    'Refer to specialist',
    'Repeat test in 3 months',
    'Repeat test in 6 months',
    'No further action needed'
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
    _fadeController.forward();
    
    _loadScreeningData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _loadScreeningData() {
    setState(() => _isLoading = true);
    
    // Mock data loading
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MadadgarTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Screening Results',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: MadadgarTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => _saveAsDraft(),
            icon: const Icon(Icons.save),
            tooltip: 'Save as Draft',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Contact info header
                  _buildContactHeader(),
                  
                  // Form content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTestResultsSection(),
                            const SizedBox(height: 24),
                            _buildFollowUpSection(),
                            const SizedBox(height: 24),
                            _buildRecommendationsSection(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: MadadgarTheme.primaryColor),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: MadadgarTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveResults,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MadadgarTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Save Results',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MadadgarTheme.primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: MadadgarTheme.primaryColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: MadadgarTheme.primaryColor.withOpacity(0.2),
            child: Icon(
              Icons.person,
              color: MadadgarTheme.primaryColor,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fatima Khan',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Sister of Ahmad Khan (PAT001)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  'Age: 25 • Female',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Text(
              'Screening',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResultsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: MadadgarTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Test Results',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Test Type Selection
            DropdownButtonFormField<String>(
              value: _testType.isEmpty ? null : _testType,
              decoration: InputDecoration(
                labelText: 'Test Type',
                labelStyle: GoogleFonts.poppins(),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.medical_services),
              ),
              items: _testTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    _formatTestType(type),
                    style: GoogleFonts.poppins(),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _testType = value ?? '');
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select test type';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Test Result Selection
            DropdownButtonFormField<String>(
              value: _testResult.isEmpty ? null : _testResult,
              decoration: InputDecoration(
                labelText: 'Test Result',
                labelStyle: GoogleFonts.poppins(),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.assignment_turned_in),
              ),
              items: _testResults.map((result) {
                return DropdownMenuItem(
                  value: result,
                  child: Row(
                    children: [
                      Icon(
                        _getResultIcon(result),
                        color: _getResultColor(result),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        result.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: _getResultColor(result),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _testResult = value ?? '');
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select test result';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Test Facility
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Test Facility',
                labelStyle: GoogleFonts.poppins(),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.local_hospital),
              ),
              style: GoogleFonts.poppins(),
              onChanged: (value) => _testFacility = value,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter test facility';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Test Date
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Test Date',
                labelStyle: GoogleFonts.poppins(),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.calendar_today),
                suffixIcon: IconButton(
                  onPressed: _selectTestDate,
                  icon: const Icon(Icons.date_range),
                ),
              ),
              style: GoogleFonts.poppins(),
              readOnly: true,
              controller: TextEditingController(
                text: _testDate != null ? _formatDate(_testDate!) : '',
              ),
              validator: (value) {
                if (_testDate == null) {
                  return 'Please select test date';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Test Notes
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Test Notes (Optional)',
                labelStyle: GoogleFonts.poppins(),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.notes),
              ),
              style: GoogleFonts.poppins(),
              maxLines: 3,
              onChanged: (value) => _testNotes = value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, color: MadadgarTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Follow-up Actions',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(
              'Select required follow-up actions:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            // Follow-up Actions Checkboxes
            ..._availableActions.map((action) {
              return CheckboxListTile(
                title: Text(
                  action,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                value: _followUpActions.contains(action),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _followUpActions.add(action);
                    } else {
                      _followUpActions.remove(action);
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              );
            }).toList(),
            
            const SizedBox(height: 16),
            
            // Referral Status
            DropdownButtonFormField<String>(
              value: _referralStatus.isEmpty ? null : _referralStatus,
              decoration: InputDecoration(
                labelText: 'Referral Status',
                labelStyle: GoogleFonts.poppins(),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.send),
              ),
              items: [
                'Not Required',
                'Referred to Doctor',
                'Referred to Specialist',
                'Referred to Lab',
                'Emergency Referral'
              ].map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status, style: GoogleFonts.poppins()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _referralStatus = value ?? '');
              },
            ),
            
            const SizedBox(height: 16),
            
            // Next Screening Date
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Next Screening Date',
                labelStyle: GoogleFonts.poppins(),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.schedule),
                suffixIcon: IconButton(
                  onPressed: _selectNextScreeningDate,
                  icon: const Icon(Icons.date_range),
                ),
              ),
              style: GoogleFonts.poppins(),
              readOnly: true,
              controller: TextEditingController(
                text: _nextScreeningDate != null ? _formatDate(_nextScreeningDate!) : '',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.recommend, color: MadadgarTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Recommendations',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Clinical Recommendations',
                labelStyle: GoogleFonts.poppins(),
                hintText: 'Enter recommendations for patient care...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.description),
              ),
              style: GoogleFonts.poppins(),
              maxLines: 4,
              onChanged: (value) => _recommendations = value,
            ),
            
            const SizedBox(height: 16),
            
            // Quick recommendation buttons
            Text(
              'Quick Recommendations:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Continue regular screening',
                'Maintain hygiene practices',
                'Complete prescribed treatment',
                'Report symptoms immediately',
                'Follow medication schedule'
              ].map((recommendation) {
                return ActionChip(
                  label: Text(
                    recommendation,
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  onPressed: () {
                    setState(() {
                      if (_recommendations.isEmpty) {
                        _recommendations = recommendation;
                      } else {
                        _recommendations += '\n• $recommendation';
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTestType(String type) {
    switch (type) {
      case 'chest_xray':
        return 'Chest X-Ray';
      case 'sputum_microscopy':
        return 'Sputum Microscopy';
      case 'tuberculin_skin_test':
        return 'Tuberculin Skin Test';
      case 'interferon_gamma_release':
        return 'Interferon Gamma Release';
      case 'clinical_assessment':
        return 'Clinical Assessment';
      default:
        return type;
    }
  }

  IconData _getResultIcon(String result) {
    switch (result) {
      case 'positive':
        return Icons.warning;
      case 'negative':
        return Icons.check_circle;
      case 'inconclusive':
        return Icons.help;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }

  Color _getResultColor(String result) {
    switch (result) {
      case 'positive':
        return Colors.red;
      case 'negative':
        return Colors.green;
      case 'inconclusive':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _selectTestDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _testDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _testDate = date);
    }
  }

  void _selectNextScreeningDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _nextScreeningDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _nextScreeningDate = date);
    }
  }

  void _saveAsDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Results saved as draft',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _saveResults() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      
      // Mock save operation
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Screening results saved successfully!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      });
    }
  }
}
