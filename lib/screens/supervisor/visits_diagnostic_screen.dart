import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_constants.dart';
import '../../theme/theme.dart';

class VisitsDiagnosticScreen extends StatefulWidget {
  const VisitsDiagnosticScreen({super.key});

  @override
  State<VisitsDiagnosticScreen> createState() => _VisitsDiagnosticScreenState();
}

class _VisitsDiagnosticScreenState extends State<VisitsDiagnosticScreen> {
  String _status = 'Ready to test...';
  List<String> _logs = [];
  int _visitCount = 0;
  Map<String, dynamic>? _sampleVisit;

  void _addLog(String message) {
    setState(() {
      _logs.add(
        '${DateTime.now().toIso8601String().substring(11, 19)} - $message',
      );
    });
    print(message);
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _status = 'Running diagnostics...';
      _logs.clear();
      _visitCount = 0;
      _sampleVisit = null;
    });

    try {
      _addLog('🔍 Starting Firestore diagnostics...');

      // Test 1: Check if collection exists
      _addLog('Test 1: Checking visits collection...');
      final collection = FirebaseFirestore.instance.collection(
        AppConstants.visitsCollection,
      );
      _addLog('✅ Collection reference created');

      // Test 2: Count documents
      _addLog('Test 2: Counting documents...');
      final countQuery = await collection.count().get();
      _visitCount = countQuery.count ?? 0;
      _addLog('✅ Found $_visitCount documents in visits collection');

      if (_visitCount == 0) {
        _addLog('⚠️  No visits found in database!');
        _addLog('   Please ensure CHWs have recorded visits.');
        setState(() {
          _status = 'No visits in database';
        });
        return;
      }

      // Test 3: Fetch first 5 documents
      _addLog('Test 3: Fetching sample documents...');
      final snapshot = await collection.limit(5).get();
      _addLog('✅ Retrieved ${snapshot.docs.length} sample documents');

      if (snapshot.docs.isNotEmpty) {
        _sampleVisit = snapshot.docs.first.data();
        _sampleVisit!['id'] = snapshot.docs.first.id;
        _addLog('Sample visit data:');
        _sampleVisit!.forEach((key, value) {
          _addLog('   $key: $value');
        });
      }

      // Test 4: Check required fields
      _addLog('Test 4: Checking required fields...');
      bool hasVisitDate = false;
      bool hasDate = false;
      bool hasCHWId = false;
      bool hasPatientId = false;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('visitDate')) hasVisitDate = true;
        if (data.containsKey('date')) hasDate = true;
        if (data.containsKey('chwId')) hasCHWId = true;
        if (data.containsKey('patientId')) hasPatientId = true;
      }

      _addLog('Field check results:');
      _addLog('   visitDate field: ${hasVisitDate ? "✅" : "❌"}');
      _addLog('   date field: ${hasDate ? "✅" : "❌"}');
      _addLog('   chwId field: ${hasCHWId ? "✅" : "❌"}');
      _addLog('   patientId field: ${hasPatientId ? "✅" : "❌"}');

      if (!hasVisitDate && !hasDate) {
        _addLog('⚠️  WARNING: No date fields found!');
        _addLog('   Visits must have either "visitDate" or "date" field');
      }

      if (!hasCHWId) {
        _addLog('⚠️  WARNING: No chwId field found!');
      }

      // Test 5: Try streaming
      _addLog('Test 5: Testing real-time stream...');
      final stream = collection.limit(5).snapshots();
      await for (var snapshot in stream.take(1)) {
        _addLog('✅ Stream working! Received ${snapshot.docs.length} docs');
        break;
      }

      setState(() {
        _status = 'Diagnostics complete ✅';
      });
      _addLog('🎉 All diagnostics completed successfully!');
    } catch (e, stackTrace) {
      _addLog('❌ ERROR: $e');
      _addLog('Stack trace: $stackTrace');
      setState(() {
        _status = 'Error occurred ❌';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visits Diagnostic'),
        backgroundColor: CHWTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: $_status', style: CHWTheme.subheadingStyle),
                    const SizedBox(height: 8),
                    Text('Total Visits: $_visitCount'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _runDiagnostics,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Run Diagnostics'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CHWTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Diagnostic Logs:', style: CHWTheme.subheadingStyle),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _logs.isEmpty
                    ? Center(
                        child: Text(
                          'Click "Run Diagnostics" to start',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              _logs[index],
                              style: TextStyle(
                                color: _logs[index].contains('❌')
                                    ? Colors.red[300]
                                    : _logs[index].contains('⚠️')
                                    ? Colors.orange[300]
                                    : _logs[index].contains('✅')
                                    ? Colors.green[300]
                                    : Colors.white,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            if (_sampleVisit != null) ...[
              const SizedBox(height: 16),
              Text('Sample Visit Data:', style: CHWTheme.subheadingStyle),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _sampleVisit.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
