import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../../../models/contacttracing.dart';
import '../../../models/screeningresults.dart';

class ContactScreeningScreen extends StatefulWidget {
  const ContactScreeningScreen({super.key});

  @override
  State<ContactScreeningScreen> createState() => _ContactScreeningScreenState();
}

class _ContactScreeningScreenState extends State<ContactScreeningScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ContactTracing> _contacts = [];
  List<ScreeningResult> _screeningResults = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      setState(() => _isLoading = true);

      // Load contact tracing records
      final contactQuery = await _firestore
          .collection('contactTracing')
          .orderBy('screeningDate', descending: true)
          .get();

      _contacts = contactQuery.docs
          .map((doc) => ContactTracing.fromFirestore(doc.data()))
          .toList();

      // Load screening results
      final screeningQuery = await _firestore
          .collection('screeningResults')
          .get();

      _screeningResults = screeningQuery.docs
          .map((doc) => ScreeningResult.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading contacts: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<ContactTracing> get _filteredContacts {
    var filtered = _contacts.where((contact) {
      final matchesSearch =
          contact.contactName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          contact.householdId.contains(_searchQuery) ||
          contact.indexPatientId.contains(_searchQuery);

      final matchesStatus =
          _filterStatus == 'all' ||
          (_filterStatus == 'pending' && contact.testResult == 'pending') ||
          (_filterStatus == 'completed' &&
              (contact.testResult == 'negative' ||
                  contact.testResult == 'positive')) ||
          (_filterStatus == 'referred' && contact.referralNeeded);

      return matchesSearch && matchesStatus;
    }).toList();

    return filtered;
  }

  Future<void> _markTestCompleted(ContactTracing contact) async {
    // Show dialog to select test result (negative or positive)
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Test as Completed'),
        content: const Text('Please select the test result:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('negative'),
            child: const Text('Negative'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('positive'),
            child: const Text('Positive'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await _firestore
            .collection('contactTracing')
            .doc(contact.contactId)
            .update({
              'testResult': result,
              'screeningDate': Timestamp.fromDate(DateTime.now()),
            });

        await _loadContacts();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Test marked as $result')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error updating test: $e')));
        }
      }
    }
  }

  Future<void> _cancelScreening(ContactTracing contact) async {
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Screening'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please provide a reason for cancelling this screening:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm Cancellation'),
          ),
        ],
      ),
    );

    if (result == true && reasonController.text.isNotEmpty) {
      try {
        // Update contact tracing record
        await _firestore
            .collection('contactTracing')
            .doc(contact.contactId)
            .update({
              'testResult': 'cancelled',
              'notes':
                  '${contact.notes}\n\nCancelled: ${reasonController.text}',
            });

        // Create CHW notification
        await _firestore.collection('chwNotifications').add({
          'notificationId': DateTime.now().millisecondsSinceEpoch.toString(),
          'chwId': contact.screenedBy,
          'title': 'Screening Cancelled',
          'message':
              'Screening for ${contact.contactName} has been cancelled. Reason: ${reasonController.text}',
          'type': 'screening_cancelled',
          'isRead': false,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'patientDetails': {
            'contactId': contact.contactId,
            'contactName': contact.contactName,
            'householdId': contact.householdId,
            'indexPatientId': contact.indexPatientId,
          },
          'reason': reasonController.text,
        });

        await _loadContacts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Screening cancelled and CHW notified'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cancelling screening: $e')),
          );
        }
      }
    }
  }

  Future<void> _uploadScreeningResult(ContactTracing contact) async {
    // Show upload dialog with test details first
    await _showUploadDialog(contact, '');
  }

  Future<void> _showUploadDialog(
    ContactTracing contact,
    String fileName,
  ) async {
    final testTypeController = TextEditingController();
    final testResultController = TextEditingController();
    final testFacilityController = TextEditingController();
    final conductedByController = TextEditingController();
    final notesController = TextEditingController();
    bool requiresFollowUp = false;
    String selectedFileName = fileName;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Upload Screening Result'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // File selection section (optional)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.attach_file),
                          const SizedBox(width: 8),
                          const Text(
                            'Supporting Documents (Optional)',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.attach_file),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedFileName.isEmpty
                                  ? 'No file selected'
                                  : 'File: $selectedFileName',
                              style: TextStyle(
                                color: selectedFileName.isEmpty
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                FilePickerResult? result = await FilePicker
                                    .platform
                                    .pickFiles(
                                      type: FileType.custom,
                                      allowedExtensions: [
                                        'pdf',
                                        'jpg',
                                        'jpeg',
                                        'png',
                                        'doc',
                                        'docx',
                                      ],
                                      allowMultiple: false,
                                    );

                                if (result != null &&
                                    result.files.single.path != null) {
                                  setState(() {
                                    selectedFileName = result.files.single.name;
                                  });
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error selecting file: $e'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Select File'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          if (selectedFileName.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  selectedFileName = '';
                                });
                              },
                              icon: const Icon(Icons.clear),
                              label: const Text('Remove'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: testTypeController.text.isEmpty
                      ? null
                      : testTypeController.text,
                  decoration: const InputDecoration(
                    labelText: 'Test Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'chest_xray',
                      child: Text('Chest X-Ray'),
                    ),
                    DropdownMenuItem(
                      value: 'sputum_microscopy',
                      child: Text('Sputum Microscopy'),
                    ),
                    DropdownMenuItem(
                      value: 'tuberculin_skin_test',
                      child: Text('Tuberculin Skin Test (TST)'),
                    ),
                    DropdownMenuItem(
                      value: 'interferon_gamma_release',
                      child: Text('Interferon Gamma Release Assay (IGRA)'),
                    ),
                    DropdownMenuItem(
                      value: 'clinical_assessment',
                      child: Text('Clinical Assessment'),
                    ),
                  ],
                  onChanged: (value) => testTypeController.text = value ?? '',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: testResultController.text.isEmpty
                      ? null
                      : testResultController.text,
                  decoration: const InputDecoration(
                    labelText: 'Test Result',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'negative',
                      child: Text('Negative'),
                    ),
                    DropdownMenuItem(
                      value: 'positive',
                      child: Text('Positive'),
                    ),
                    DropdownMenuItem(
                      value: 'inconclusive',
                      child: Text('Inconclusive'),
                    ),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  ],
                  onChanged: (value) => testResultController.text = value ?? '',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: testFacilityController,
                  decoration: const InputDecoration(
                    labelText: 'Test Facility',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: conductedByController,
                  decoration: const InputDecoration(
                    labelText: 'Conducted By',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Requires Follow-up'),
                  value: requiresFollowUp,
                  onChanged: (value) =>
                      setState(() => requiresFollowUp = value ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Upload Result'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        // Validate required fields
        if (testTypeController.text.isEmpty ||
            testResultController.text.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please fill in all required fields'),
              ),
            );
          }
          return;
        }

        // Create screening result record
        final screeningResult = ScreeningResult(
          resultId: DateTime.now().millisecondsSinceEpoch.toString(),
          contactId: contact.contactId,
          contactName: contact.contactName,
          householdId: contact.householdId,
          indexPatientId: contact.indexPatientId,
          testType: testTypeController.text,
          testResult: testResultController.text,
          testDate: DateTime.now(),
          testFacility: testFacilityController.text,
          facilityContact: '', // This could be filled from facility data
          conductedBy: conductedByController.text,
          notes: notesController.text,
          requiresFollowUp: requiresFollowUp,
          testDetails: {
            'fileName': selectedFileName.isEmpty
                ? 'No file attached'
                : selectedFileName,
            'uploadedAt': DateTime.now().toIso8601String(),
            'hasFile': selectedFileName.isNotEmpty,
            'originalContactData': {
              'symptoms': contact.symptoms,
              'relationship': contact.relationship,
              'age': contact.age,
              'gender': contact.gender,
            },
          },
          createdAt: DateTime.now(),
          recordedBy: 'Staff', // This should be the current user
        );

        // Save screening result to Firestore
        await _firestore
            .collection('screeningResults')
            .doc(screeningResult.resultId)
            .set(screeningResult.toFirestore());

        // Update contact tracing record with the test result
        await _firestore
            .collection('contactTracing')
            .doc(contact.contactId)
            .update({
              'testResult': testResultController.text,
              'screeningDate': Timestamp.fromDate(DateTime.now()),
              'notes':
                  '${contact.notes}\n\nScreening result uploaded: ${testResultController.text} (${testTypeController.text})',
            });

        await _loadContacts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Screening result uploaded successfully'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error uploading result: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Screening'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search contacts...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Filter by status: '),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _filterStatus,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text('Pending'),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('Completed'),
                        ),
                        DropdownMenuItem(
                          value: 'referred',
                          child: Text('Referred'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _filterStatus = value ?? 'all'),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _loadContacts,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Contacts List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredContacts.isEmpty
                ? const Center(child: Text('No contacts found'))
                : ListView.builder(
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      return _buildContactCard(contact);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(ContactTracing contact) {
    final hasScreeningResult = _screeningResults.any(
      (result) => result.contactId == contact.contactId,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.contactName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Household ID: ${contact.householdId}'),
                      Text('Index Patient: ${contact.indexPatientId}'),
                      Text('Age: ${contact.age}, Gender: ${contact.gender}'),
                      Text('Relationship: ${contact.relationship}'),
                    ],
                  ),
                ),
                _buildStatusChip(contact.testResult),
              ],
            ),
            const SizedBox(height: 12),
            if (contact.symptoms.isNotEmpty) ...[
              Text(
                'Symptoms: ${contact.symptoms.join(', ')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
            ],
            if (contact.notes.isNotEmpty) ...[
              Text(
                'Notes: ${contact.notes}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Text(
                  'Screened: ${_formatDate(contact.screeningDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                if (contact.testResult == 'pending') ...[
                  ElevatedButton.icon(
                    onPressed: () => _markTestCompleted(contact),
                    icon: const Icon(Icons.check),
                    label: const Text('Mark Completed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _uploadScreeningResult(contact),
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload Result'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _cancelScreening(contact),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ] else if (contact.testResult == 'negative' ||
                    contact.testResult == 'positive') ...[
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Test Result: ${contact.testResult.toUpperCase()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: contact.testResult == 'positive'
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ] else if (hasScreeningResult) ...[
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text('Result Available'),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'completed':
        color = Colors.blue;
        label = 'Completed';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Cancelled';
        break;
      case 'positive':
        color = Colors.red;
        label = 'Positive';
        break;
      case 'negative':
        color = Colors.green;
        label = 'Negative';
        break;
      case 'inconclusive':
        color = Colors.amber;
        label = 'Inconclusive';
        break;
      default:
        color = Colors.grey;
        label = status.toUpperCase();
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
