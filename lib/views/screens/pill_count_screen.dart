// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chw_tb/config/theme.dart';

class PillCountScreen extends StatefulWidget {
  final String? patientId;
  
  const PillCountScreen({super.key, this.patientId});

  @override
  State<PillCountScreen> createState() => _PillCountScreenState();
}

class _PillCountScreenState extends State<PillCountScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = false;
  
  // Current pill counts
  Map<String, int> _currentPillCounts = {};
  Map<String, int> _initialPillCounts = {};
  
  // Refill information
  Map<String, DateTime> _lastRefillDates = {};
  Map<String, DateTime> _nextRefillDates = {};
  
  final List<Map<String, dynamic>> _medications = [
    {
      'name': 'Rifampin',
      'dose': '600mg',
      'frequency': 'Once daily',
      'color': Colors.red,
      'pillsPerStrip': 10,
      'currentCount': 45,
      'initialCount': 60,
      'lastRefill': DateTime(2025, 8, 15),
      'daysSupply': 45,
    },
    {
      'name': 'Isoniazid',
      'dose': '300mg', 
      'frequency': 'Once daily',
      'color': Colors.blue,
      'pillsPerStrip': 10,
      'currentCount': 42,
      'initialCount': 60,
      'lastRefill': DateTime(2025, 8, 15),
      'daysSupply': 42,
    },
    {
      'name': 'Ethambutol',
      'dose': '1200mg',
      'frequency': 'Once daily',
      'color': Colors.green,
      'pillsPerStrip': 10,
      'currentCount': 38,
      'initialCount': 60,
      'lastRefill': DateTime(2025, 8, 15),
      'daysSupply': 38,
    },
    {
      'name': 'Pyrazinamide',
      'dose': '1500mg',
      'frequency': 'Once daily',
      'color': Colors.orange,
      'pillsPerStrip': 10,
      'currentCount': 40,
      'initialCount': 60,
      'lastRefill': DateTime(2025, 8, 15),
      'daysSupply': 40,
    },
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
    
    _initializePillCounts();
    _loadPillCountData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _initializePillCounts() {
    for (var medication in _medications) {
      _currentPillCounts[medication['name']] = medication['currentCount'];
      _initialPillCounts[medication['name']] = medication['initialCount'];
      _lastRefillDates[medication['name']] = medication['lastRefill'];
      _nextRefillDates[medication['name']] = medication['lastRefill'].add(Duration(days: medication['daysSupply']));
    }
  }

  void _loadPillCountData() {
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
          'Pill Count Tracker',
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
            onPressed: () => _viewPillCountHistory(),
            icon: const Icon(Icons.history),
            tooltip: 'View History',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'camera',
                child: Row(
                  children: [
                    const Icon(Icons.camera_alt),
                    const SizedBox(width: 8),
                    Text('Photo Count', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.download),
                    const SizedBox(width: 8),
                    Text('Export Data', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'refill',
                child: Row(
                  children: [
                    const Icon(Icons.add_shopping_cart),
                    const SizedBox(width: 8),
                    Text('Request Refill', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Patient info header
                  _buildPatientHeader(),
                  
                  // Current status summary
                  _buildStatusSummary(),
                  
                  // Medication list
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildMedicationsCard(),
                          const SizedBox(height: 16),
                          _buildRefillAlertsCard(),
                          const SizedBox(height: 16),
                          _buildUsageCalculatorCard(),
                          const SizedBox(height: 16),
                          _buildPillCountTipsCard(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _savePillCount(),
        backgroundColor: MadadgarTheme.secondaryColor,
        icon: const Icon(Icons.save, color: Colors.white),
        label: Text(
          'Save Count',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildPatientHeader() {
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
            radius: 25,
            backgroundColor: MadadgarTheme.primaryColor.withOpacity(0.2),
            child: Icon(
              Icons.person,
              color: MadadgarTheme.primaryColor,
              size: 25,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ahmad Khan',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Patient ID: PAT001',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Last Count',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              Text(
                _formatDate(DateTime.now().subtract(const Duration(days: 1))),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSummary() {
    int totalMedications = _medications.length;
    int lowStockCount = _medications.where((med) => 
      _currentPillCounts[med['name']] != null && 
      _currentPillCounts[med['name']]! <= 10
    ).length;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MadadgarTheme.primaryColor,
            MadadgarTheme.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem('Total\nMedications', totalMedications.toString()),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _buildSummaryItem('Low Stock\nAlerts', lowStockCount.toString()),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _buildSummaryItem('Days Until\nRefill', _getMinDaysUntilRefill().toString()),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMedicationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medication, color: MadadgarTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Current Pill Count',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ..._medications.map((medication) {
              return _buildMedicationCountItem(medication);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationCountItem(Map<String, dynamic> medication) {
    String medicationName = medication['name'];
    int currentCount = _currentPillCounts[medicationName] ?? 0;
    int daysRemaining = currentCount;
    bool isLowStock = currentCount <= 10;
    bool isCriticalStock = currentCount <= 5;
    
    Color statusColor = isCriticalStock ? Colors.red : 
                       isLowStock ? Colors.orange : Colors.green;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLowStock ? statusColor.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLowStock ? statusColor.withOpacity(0.3) : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          // Medication info and status
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: medication['color'],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicationName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${medication['dose']} • ${medication['frequency']}',
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
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  _getStockStatus(currentCount),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Pill count input
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Count:',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _adjustPillCount(medicationName, -1),
                          icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade400),
                        ),
                        Expanded(
                          child: TextFormField(
                            initialValue: currentCount.toString(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              suffix: Text(
                                'pills',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              int? newCount = int.tryParse(value);
                              if (newCount != null && newCount >= 0) {
                                setState(() {
                                  _currentPillCounts[medicationName] = newCount;
                                });
                              }
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: () => _adjustPillCount(medicationName, 1),
                          icon: Icon(Icons.add_circle_outline, color: Colors.green.shade400),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Days Supply:',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$daysRemaining',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                          Text(
                            'days',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Stock Level',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${((currentCount / medication['initialCount']) * 100).round()}%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: currentCount / medication['initialCount'],
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ],
          ),
          
          // Quick action buttons
          if (isLowStock) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _requestRefill(medicationName),
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: Text(
                      'Request Refill',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _setReminder(medicationName),
                    icon: const Icon(Icons.alarm, size: 16),
                    label: Text(
                      'Set Reminder',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: statusColor),
                      foregroundColor: statusColor,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRefillAlertsCard() {
    List<Map<String, dynamic>> lowStockMeds = _medications.where((med) =>
      _currentPillCounts[med['name']] != null &&
      _currentPillCounts[med['name']]! <= 10
    ).toList();
    
    if (lowStockMeds.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              Text(
                'All medications have adequate stock',
                style: GoogleFonts.poppins(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notification_important, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Refill Alerts',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ...lowStockMeds.map((medication) {
              int currentCount = _currentPillCounts[medication['name']] ?? 0;
              bool isCritical = currentCount <= 5;
              
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCritical ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCritical ? Colors.red.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCritical ? Icons.error : Icons.warning,
                      color: isCritical ? Colors.red : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medication['name'],
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '$currentCount pills remaining${isCritical ? ' - CRITICAL' : ' - Low Stock'}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isCritical ? Colors.red.shade700 : Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _requestRefill(medication['name']),
                      child: Text(
                        'Refill',
                        style: GoogleFonts.poppins(
                          color: isCritical ? Colors.red.shade700 : Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageCalculatorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate, color: MadadgarTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Medicine Usage Calculator',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MadadgarTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildCalculatorRow('Daily consumption:', '4 pills'),
                  _buildCalculatorRow('Weekly consumption:', '28 pills'),
                  _buildCalculatorRow('Monthly consumption:', '120 pills'),
                  const Divider(),
                  _buildCalculatorRow('Average adherence:', '95%', isHighlight: true),
                  _buildCalculatorRow('Pills saved by adherence:', '6 pills/month', isHighlight: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillCountTipsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Pill Counting Tips',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildTipItem(
              Icons.schedule,
              'Count at the same time daily',
              'Best time is before taking morning dose',
            ),
            _buildTipItem(
              Icons.photo_camera,
              'Take photos for verification',
              'Document pill count with date and time',
            ),
            _buildTipItem(
              Icons.inventory,
              'Organize by medication type',
              'Keep different medications separate',
            ),
            _buildTipItem(
              Icons.notification_important,
              'Set low stock alerts',
              'Request refill when 10 days supply remains',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isHighlight ? MadadgarTheme.primaryColor : Colors.black87,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isHighlight ? MadadgarTheme.primaryColor : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getStockStatus(int count) {
    if (count <= 5) return 'CRITICAL';
    if (count <= 10) return 'LOW';
    if (count <= 20) return 'MODERATE';
    return 'GOOD';
  }

  int _getMinDaysUntilRefill() {
    int minDays = 999;
    for (var medication in _medications) {
      int currentCount = _currentPillCounts[medication['name']] ?? 0;
      if (currentCount < minDays) {
        minDays = currentCount;
      }
    }
    return minDays == 999 ? 0 : minDays;
  }

  void _adjustPillCount(String medicationName, int adjustment) {
    setState(() {
      int currentCount = _currentPillCounts[medicationName] ?? 0;
      int newCount = currentCount + adjustment;
      if (newCount >= 0) {
        _currentPillCounts[medicationName] = newCount;
      }
    });
  }

  void _requestRefill(String medicationName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Refill request sent for $medicationName',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _setReminder(String medicationName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reminder set for $medicationName refill',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'camera':
        _takePhotoCount();
        break;
      case 'export':
        _exportPillCountData();
        break;
      case 'refill':
        _requestAllRefills();
        break;
    }
  }

  void _viewPillCountHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pill count history feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _takePhotoCount() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Photo pill count feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _exportPillCountData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _requestAllRefills() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bulk refill request feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _savePillCount() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pill count saved successfully!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
}
