// ignore_for_file: deprecated_member_use, unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chw_tb/config/theme.dart';

class AdherenceTrackingScreen extends StatefulWidget {
  final String? patientId;
  
  const AdherenceTrackingScreen({super.key, this.patientId});

  @override
  State<AdherenceTrackingScreen> createState() => _AdherenceTrackingScreenState();
}

class _AdherenceTrackingScreenState extends State<AdherenceTrackingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;
  
  bool _isLoading = false;
  
  // Dose tracking for current day
  final Map<String, String> _morningDoses = {};
  final Map<String, String> _eveningDoses = {};
  
  // Side effects tracking
  final List<String> _reportedSideEffects = [];
  // ignore: unused_field
  String _sideEffectNotes = '';
  
  // Pill count
  final Map<String, int> _pillCounts = {};
  
  final List<String> _doseOptions = ['taken', 'missed', 'late', 'vomited'];
  
  final List<Map<String, dynamic>> _medications = [
    {
      'name': 'Rifampin',
      'dose': '600mg',
      'frequency': 'Once daily',
      'timing': 'Morning',
      'color': Colors.red,
      'pillCount': 45,
    },
    {
      'name': 'Isoniazid', 
      'dose': '300mg',
      'frequency': 'Once daily',
      'timing': 'Morning',
      'color': Colors.blue,
      'pillCount': 42,
    },
    {
      'name': 'Ethambutol',
      'dose': '1200mg',
      'frequency': 'Once daily',
      'timing': 'Morning',
      'color': Colors.green,
      'pillCount': 38,
    },
    {
      'name': 'Pyrazinamide',
      'dose': '1500mg',
      'frequency': 'Once daily',
      'timing': 'Morning',
      'color': Colors.orange,
      'pillCount': 40,
    },
  ];
  
  final List<String> _sideEffectsList = [
    'nausea',
    'vomiting',
    'rash',
    'dizziness',
    'hearing_problems',
    'joint_pain',
    'vision_changes'
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
    _tabController = TabController(length: 3, vsync: this);
    _fadeController.forward();
    
    _initializeDoseTracking();
    _loadAdherenceData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _initializeDoseTracking() {
    for (var medication in _medications) {
      _morningDoses[medication['name']] = '';
      _eveningDoses[medication['name']] = '';
      _pillCounts[medication['name']] = medication['pillCount'];
    }
  }

  void _loadAdherenceData() {
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: MadadgarTheme.primaryColor,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  onPressed: () => _viewAdherenceHistory(),
                  icon: const Icon(Icons.history),
                  tooltip: 'View History',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: _handleMenuAction,
                  itemBuilder: (context) => [
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
                      value: 'reminders',
                      child: Row(
                        children: [
                          const Icon(Icons.notifications),
                          const SizedBox(width: 8),
                          Text('Set Reminders', style: GoogleFonts.poppins()),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeaderContent(),
              ),
              bottom: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
                tabs: const [
                  Tab(text: 'Daily Doses'),
                  Tab(text: 'Side Effects'),
                  Tab(text: 'Pill Count'),
                ],
              ),
            ),
          ],
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDailyDosesTab(),
                    _buildSideEffectsTab(),
                    _buildPillCountTab(),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _saveAdherenceData(),
        backgroundColor: MadadgarTheme.secondaryColor,
        icon: const Icon(Icons.save, color: Colors.white),
        label: Text(
          'Save Today',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildHeaderContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            MadadgarTheme.primaryColor,
            MadadgarTheme.primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ahmad Khan',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 4),
              
              Text(
                'Patient ID: PAT001',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  _buildHeaderStat('Today', '4/4 doses'),
                  const SizedBox(width: 16),
                  _buildHeaderStat('This Week', '95%'),
                  const SizedBox(width: 16),
                  _buildHeaderStat('Overall', '92%'),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Today: ${_getCurrentDate()}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Today's progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Progress: ${_getTodayProgress()}%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: _getTodayProgress() / 100,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyDosesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMorningDosesCard(),
          const SizedBox(height: 16),
          _buildEveningDosesCard(),
          const SizedBox(height: 16),
          _buildDoseInstructionsCard(),
        ],
      ),
    );
  }

  Widget _buildSideEffectsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSideEffectsChecklistCard(),
          const SizedBox(height: 16),
          _buildSideEffectNotesCard(),
          const SizedBox(height: 16),
          _buildSideEffectsHistoryCard(),
        ],
      ),
    );
  }

  Widget _buildPillCountTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPillCountCard(),
          const SizedBox(height: 16),
          _buildRefillAlertsCard(),
          const SizedBox(height: 16),
          _buildPillCountHistoryCard(),
        ],
      ),
    );
  }

  Widget _buildMorningDosesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wb_sunny, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Morning Doses (8:00 AM)',
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
              if (medication['timing'] == 'Morning') {
                return _buildDoseTrackingItem(
                  medication,
                  _morningDoses[medication['name']] ?? '',
                  (value) {
                    setState(() {
                      _morningDoses[medication['name']] = value;
                    });
                  },
                );
              }
              return const SizedBox.shrink();
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEveningDosesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.nights_stay, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  'Evening Doses (8:00 PM)',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Show message if no evening medications
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'No evening medications scheduled',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoseTrackingItem(
    Map<String, dynamic> medication,
    String selectedStatus,
    Function(String) onStatusChanged,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication['name'],
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
              if (selectedStatus.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDoseStatusColor(selectedStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    selectedStatus.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: _getDoseStatusColor(selectedStatus),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Dose status buttons
          Row(
            children: _doseOptions.map((option) {
              bool isSelected = selectedStatus == option;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ElevatedButton(
                    onPressed: () => onStatusChanged(option),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected
                          ? _getDoseStatusColor(option)
                          : Colors.grey.shade200,
                      foregroundColor: isSelected
                          ? Colors.white
                          : Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getDoseStatusIcon(option),
                          size: 16,
                        ),
                        Text(
                          _formatDoseOption(option),
                          style: GoogleFonts.poppins(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDoseInstructionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: MadadgarTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Dosing Instructions',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInstructionItem(
              Icons.restaurant,
              'Take with food',
              'All medications should be taken with breakfast',
            ),
            _buildInstructionItem(
              Icons.schedule,
              'Same time daily',
              'Take at 8:00 AM every day for best results',
            ),
            _buildInstructionItem(
              Icons.warning,
              'If you vomit',
              'Contact your CHW immediately if you vomit within 1 hour',
            ),
            _buildInstructionItem(
              Icons.help,
              'Missed dose',
              'Take as soon as you remember, but don\'t double dose',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideEffectsChecklistCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Side Effects Today',
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
              'Check any side effects you experienced today:',
              style: GoogleFonts.poppins(
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            ..._sideEffectsList.map((effect) {
              return CheckboxListTile(
                title: Text(
                  _formatSideEffect(effect),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                value: _reportedSideEffects.contains(effect),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _reportedSideEffects.add(effect);
                    } else {
                      _reportedSideEffects.remove(effect);
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSideEffectNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Notes',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Describe any side effects in detail',
                labelStyle: GoogleFonts.poppins(),
                hintText: 'How severe? When did it start? Any other details...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                border: const OutlineInputBorder(),
              ),
              style: GoogleFonts.poppins(),
              maxLines: 3,
              onChanged: (value) => _sideEffectNotes = value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideEffectsHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Side Effects',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildSideEffectHistoryItem('Yesterday', ['nausea'], 'Mild'),
            _buildSideEffectHistoryItem('2 days ago', [], 'None'),
            _buildSideEffectHistoryItem('3 days ago', ['joint_pain'], 'Mild'),
          ],
        ),
      ),
    );
  }

  Widget _buildPillCountCard() {
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
              return _buildPillCountItem(medication);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRefillAlertsCard() {
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ethambutol needs refill in 8 days',
                      style: GoogleFonts.poppins(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _requestRefill('Ethambutol'),
                    child: Text(
                      'Request',
                      style: GoogleFonts.poppins(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillCountHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pill Count History',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildPillCountHistoryItem('Yesterday', '39 pills', 'On track'),
            _buildPillCountHistoryItem('2 days ago', '40 pills', 'On track'),
            _buildPillCountHistoryItem('3 days ago', '42 pills', 'Missed dose'),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: MadadgarTheme.primaryColor, size: 20),
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

  Widget _buildSideEffectHistoryItem(String date, List<String> effects, String severity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              date,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              effects.isEmpty ? 'No side effects' : effects.map(_formatSideEffect).join(', '),
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getSeverityColor(severity).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              severity,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: _getSeverityColor(severity),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillCountItem(Map<String, dynamic> medication) {
    int currentCount = _pillCounts[medication['name']] ?? 0;
    int daysRemaining = currentCount;
    bool needsRefill = daysRemaining <= 10;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: needsRefill ? Colors.orange.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: needsRefill ? Colors.orange.withOpacity(0.3) : Colors.grey.shade300,
        ),
      ),
      child: Row(
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
                  medication['name'],
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$currentCount pills remaining ($daysRemaining days)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: needsRefill ? Colors.orange.shade700 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _adjustPillCount(medication['name'], -1),
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 20,
              ),
              SizedBox(
                width: 40,
                child: TextFormField(
                  initialValue: currentCount.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    int? newCount = int.tryParse(value);
                    if (newCount != null) {
                      setState(() {
                        _pillCounts[medication['name']] = newCount;
                      });
                    }
                  },
                ),
              ),
              IconButton(
                onPressed: () => _adjustPillCount(medication['name'], 1),
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillCountHistoryItem(String date, String count, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              date,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              count,
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              status,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: _getStatusColor(status),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  double _getTodayProgress() {
    int totalDoses = _medications.length;
    int completedDoses = _morningDoses.values.where((status) => status == 'taken').length;
    return totalDoses > 0 ? (completedDoses / totalDoses) * 100 : 0;
  }

  Color _getDoseStatusColor(String status) {
    switch (status) {
      case 'taken':
        return Colors.green;
      case 'missed':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'vomited':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getDoseStatusIcon(String status) {
    switch (status) {
      case 'taken':
        return Icons.check_circle;
      case 'missed':
        return Icons.cancel;
      case 'late':
        return Icons.access_time;
      case 'vomited':
        return Icons.warning;
      default:
        return Icons.help;
    }
  }

  String _formatDoseOption(String option) {
    switch (option) {
      case 'taken':
        return 'Taken';
      case 'missed':
        return 'Missed';
      case 'late':
        return 'Late';
      case 'vomited':
        return 'Vomited';
      default:
        return option;
    }
  }

  String _formatSideEffect(String effect) {
    switch (effect) {
      case 'nausea':
        return 'Nausea';
      case 'vomiting':
        return 'Vomiting';
      case 'rash':
        return 'Skin Rash';
      case 'dizziness':
        return 'Dizziness';
      case 'hearing_problems':
        return 'Hearing Problems';
      case 'joint_pain':
        return 'Joint Pain';
      case 'vision_changes':
        return 'Vision Changes';
      default:
        return effect;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'mild':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'severe':
        return Colors.red;
      case 'none':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'on track':
        return Colors.green;
      case 'missed dose':
        return Colors.orange;
      case 'refill needed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _adjustPillCount(String medicationName, int adjustment) {
    setState(() {
      int currentCount = _pillCounts[medicationName] ?? 0;
      int newCount = currentCount + adjustment;
      if (newCount >= 0) {
        _pillCounts[medicationName] = newCount;
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

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportAdherenceData();
        break;
      case 'reminders':
        _setReminders();
        break;
    }
  }

  void _viewAdherenceHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Adherence history feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _exportAdherenceData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _setReminders() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminder settings feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _saveAdherenceData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Today\'s adherence data saved successfully!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
}
