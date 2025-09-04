// ignore_for_file: deprecated_member_use, unnecessary_to_list_in_spreads
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chw_tb/config/theme.dart';

class SideEffectsLogScreen extends StatefulWidget {
  final String? patientId;
  
  const SideEffectsLogScreen({super.key, this.patientId});

  @override
  State<SideEffectsLogScreen> createState() => _SideEffectsLogScreenState();
}

class _SideEffectsLogScreenState extends State<SideEffectsLogScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;
  
  bool _isLoading = false;
  
  // Current side effects
  final Map<String, Map<String, dynamic>> _currentSideEffects = {};
  String _additionalNotes = '';
  bool _doctorReferralRequired = false;
  final DateTime _onsetDate = DateTime.now();
  
  // Side effects list with details
  final List<Map<String, dynamic>> _sideEffectsList = [
    {
      'id': 'nausea',
      'name': 'Nausea',
      'icon': Icons.sick,
      'color': Colors.orange,
      'description': 'Feeling of wanting to vomit',
    },
    {
      'id': 'vomiting',
      'name': 'Vomiting',
      'icon': Icons.warning,
      'color': Colors.red,
      'description': 'Actually throwing up',
    },
    {
      'id': 'rash',
      'name': 'Skin Rash',
      'icon': Icons.healing,
      'color': Colors.pink,
      'description': 'Red, itchy, or bumpy skin',
    },
    {
      'id': 'dizziness',
      'name': 'Dizziness',
      'icon': Icons.rotate_left,
      'color': Colors.purple,
      'description': 'Feeling lightheaded or unsteady',
    },
    {
      'id': 'hearing_problems',
      'name': 'Hearing Problems',
      'icon': Icons.hearing_disabled,
      'color': Colors.indigo,
      'description': 'Reduced hearing or ringing in ears',
    },
    {
      'id': 'joint_pain',
      'name': 'Joint Pain',
      'icon': Icons.accessible,
      'color': Colors.brown,
      'description': 'Pain in joints or muscles',
    },
    {
      'id': 'vision_changes',
      'name': 'Vision Changes',
      'icon': Icons.visibility_off,
      'color': Colors.grey,
      'description': 'Blurry vision or color vision problems',
    },
  ];
  
  final List<String> _severityLevels = ['Mild', 'Moderate', 'Severe'];
  final List<String> _actionsTaken = [
    'No action needed',
    'Reduced medication dose',
    'Stopped medication temporarily',
    'Changed medication timing',
    'Added supportive medication',
    'Referred to doctor',
    'Emergency referral'
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
    
    _loadSideEffectsData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _loadSideEffectsData() {
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
              backgroundColor: Colors.orange,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  onPressed: () => _viewHistory(),
                  icon: const Icon(Icons.history),
                  tooltip: 'View History',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: _handleMenuAction,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'emergency',
                      child: Row(
                        children: [
                          const Icon(Icons.emergency, color: Colors.red),
                          const SizedBox(width: 8),
                          Text('Emergency Call', style: GoogleFonts.poppins()),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          const Icon(Icons.download),
                          const SizedBox(width: 8),
                          Text('Export Log', style: GoogleFonts.poppins()),
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
                  Tab(text: 'Current'),
                  Tab(text: 'History'),
                  Tab(text: 'Actions'),
                ],
              ),
            ),
          ],
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCurrentSideEffectsTab(),
                    _buildHistoryTab(),
                    _buildActionsTab(),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _saveSideEffectsLog(),
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.save, color: Colors.white),
        label: Text(
          'Save Log',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildHeaderContent() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.orange,
            Color(0xFFFF8A50),
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
                  _buildHeaderStat('Active', '2'),
                  const SizedBox(width: 16),
                  _buildHeaderStat('This Week', '3'),
                  const SizedBox(width: 16),
                  _buildHeaderStat('Severity', 'Mild'),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Last Updated: ${_formatDate(DateTime.now())}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.9),
                ),
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

  Widget _buildCurrentSideEffectsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSideEffectsChecklistCard(),
          const SizedBox(height: 16),
          _buildSeverityAssessmentCard(),
          const SizedBox(height: 16),
          _buildAdditionalNotesCard(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHistoryFilterCard(),
          const SizedBox(height: 16),
          _buildHistoryTimelineCard(),
        ],
      ),
    );
  }

  Widget _buildActionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildActionsTakenCard(),
          const SizedBox(height: 16),
          _buildReferralCard(),
          const SizedBox(height: 16),
          _buildEmergencyContactCard(),
        ],
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
                const Icon(Icons.checklist, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Side Effects Checklist',
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
              'Select all side effects currently experienced:',
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            
            ..._sideEffectsList.map((sideEffect) {
              bool isSelected = _currentSideEffects.containsKey(sideEffect['id']);
              return _buildSideEffectItem(sideEffect, isSelected);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSideEffectItem(Map<String, dynamic> sideEffect, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? sideEffect['color'].withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: sideEffect['color'].withOpacity(0.3)) : null,
      ),
      child: CheckboxListTile(
        title: Row(
          children: [
            Icon(sideEffect['icon'], color: sideEffect['color'], size: 20),
            const SizedBox(width: 8),
            Text(
              sideEffect['name'],
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        subtitle: Text(
          sideEffect['description'],
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _currentSideEffects[sideEffect['id']] = {
                'name': sideEffect['name'],
                'severity': 'Mild',
                'duration': '1 day',
                'onsetDate': DateTime.now(),
                'actionTaken': 'No action needed',
              };
            } else {
              _currentSideEffects.remove(sideEffect['id']);
            }
          });
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _buildSeverityAssessmentCard() {
    if (_currentSideEffects.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.speed, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Severity Assessment',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ..._currentSideEffects.entries.map((entry) {
              return _buildSeverityItem(entry.key, entry.value);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityItem(String effectId, Map<String, dynamic> effectData) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            effectData['name'],
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          
          // Severity Selection
          Text(
            'Severity:',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: _severityLevels.map((level) {
              bool isSelected = effectData['severity'] == level;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentSideEffects[effectId]!['severity'] = level;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected
                          ? _getSeverityColor(level)
                          : Colors.grey.shade200,
                      foregroundColor: isSelected
                          ? Colors.white
                          : Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      level,
                      style: GoogleFonts.poppins(fontSize: 10),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 12),
          
          // Duration
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Duration',
                    labelStyle: GoogleFonts.poppins(fontSize: 12),
                    hintText: 'e.g., 2 days',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  style: GoogleFonts.poppins(fontSize: 12),
                  onChanged: (value) {
                    _currentSideEffects[effectId]!['duration'] = value;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: effectData['actionTaken'],
                  decoration: InputDecoration(
                    labelText: 'Action Taken',
                    labelStyle: GoogleFonts.poppins(fontSize: 12),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _actionsTaken.map((action) {
                    return DropdownMenuItem(
                      value: action,
                      child: Text(
                        action,
                        style: GoogleFonts.poppins(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _currentSideEffects[effectId]!['actionTaken'] = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notes, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Additional Notes',
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
                labelText: 'Detailed description of side effects',
                labelStyle: GoogleFonts.poppins(),
                hintText: 'Include timing, triggers, severity changes, etc.',
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                border: const OutlineInputBorder(),
              ),
              style: GoogleFonts.poppins(),
              maxLines: 4,
              onChanged: (value) => _additionalNotes = value,
            ),
            
            const SizedBox(height: 16),
            
            CheckboxListTile(
              title: Text(
                'Doctor referral required',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade700,
                ),
              ),
              subtitle: Text(
                'Check if side effects require immediate medical attention',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.red.shade500,
                ),
              ),
              value: _doctorReferralRequired,
              onChanged: (value) {
                setState(() => _doctorReferralRequired = value ?? false);
              },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryFilterCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter History',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Time Period',
                      labelStyle: GoogleFonts.poppins(),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: ['Last 7 days', 'Last 30 days', 'Last 3 months', 'All time']
                        .map((period) => DropdownMenuItem(
                              value: period,
                              child: Text(period, style: GoogleFonts.poppins(fontSize: 12)),
                            ))
                        .toList(),
                    onChanged: (value) {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Side Effect',
                      labelStyle: GoogleFonts.poppins(),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: ['All', ..._sideEffectsList.map((e) => e['name'] as String)]
                        .map((effect) => DropdownMenuItem<String>(
                              value: effect,
                              child: Text(effect, style: GoogleFonts.poppins(fontSize: 12)),
                            ))
                        .toList(),
                    onChanged: (value) {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTimelineCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Side Effects Timeline',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildHistoryItem('Yesterday', ['nausea'], 'Mild', 'No action needed'),
            _buildHistoryItem('3 days ago', ['joint_pain'], 'Moderate', 'Reduced dose'),
            _buildHistoryItem('1 week ago', ['rash'], 'Mild', 'Added antihistamine'),
            _buildHistoryItem('2 weeks ago', ['dizziness'], 'Mild', 'No action needed'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsTakenCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_services, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Actions Taken',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildActionItem(
              Icons.medication,
              'Medication Adjustment',
              'Reduced Ethambutol dose by 25%',
              DateTime.now().subtract(const Duration(days: 3)),
            ),
            _buildActionItem(
              Icons.schedule,
              'Timing Change',
              'Moved medications to evening with food',
              DateTime.now().subtract(const Duration(days: 7)),
            ),
            _buildActionItem(
              Icons.local_hospital,
              'Doctor Consultation',
              'Referred to TB specialist for rash evaluation',
              DateTime.now().subtract(const Duration(days: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.send, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Doctor Referral',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_doctorReferralRequired) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Referral Required',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Patient requires immediate medical evaluation for current side effects.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _contactDoctor(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              'Contact Doctor',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _scheduleAppointment(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red),
                            ),
                            child: Text(
                              'Schedule Visit',
                              style: GoogleFonts.poppins(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'No immediate referral required',
                      style: GoogleFonts.poppins(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emergency, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Emergency Contacts',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildEmergencyContactItem(
              'TB Specialist',
              'Dr. Muhammad Ali',
              '+92 300 1234567',
              Icons.medical_services,
            ),
            _buildEmergencyContactItem(
              'Emergency Hotline',
              '24/7 TB Emergency',
              '1122',
              Icons.phone,
            ),
            _buildEmergencyContactItem(
              'Primary CHW',
              'Dr. Sarah Ahmed',
              '+92 300 2345678',
              Icons.person,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String date, List<String> effects, String severity, String action) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  effects.join(', '),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                Text(
                  action,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getSeverityColor(severity).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
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

  Widget _buildActionItem(IconData icon, String title, String description, DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(date),
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactItem(String role, String name, String phone, IconData icon) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.red.withOpacity(0.1),
        child: Icon(icon, color: Colors.red, size: 20),
      ),
      title: Text(
        name,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        '$role • $phone',
        style: GoogleFonts.poppins(fontSize: 12),
      ),
      trailing: IconButton(
        onPressed: () => _makeEmergencyCall(phone),
        icon: const Icon(Icons.call, color: Colors.red),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'mild':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'severe':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'emergency':
        _makeEmergencyCall('1122');
        break;
      case 'export':
        _exportSideEffectsLog();
        break;
    }
  }

  void _viewHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Detailed history view coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _contactDoctor() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contacting doctor...', style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _scheduleAppointment() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Schedule appointment feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _makeEmergencyCall(String phone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $phone...', style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _exportSideEffectsLog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _saveSideEffectsLog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Side effects log saved successfully!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
}
