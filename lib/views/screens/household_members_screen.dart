// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chw_tb/config/theme.dart';

class HouseholdMembersScreen extends StatefulWidget {
  final String? patientId;
  
  const HouseholdMembersScreen({super.key, this.patientId});

  @override
  State<HouseholdMembersScreen> createState() => _HouseholdMembersScreenState();
}

class _HouseholdMembersScreenState extends State<HouseholdMembersScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = false;
  String _selectedFilter = 'all';
  
  // Patient and household data
  Map<String, dynamic> _patientData = {};
  List<Map<String, dynamic>> _householdMembers = [];
  Map<String, dynamic> _householdStats = {};

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
    
    _loadHouseholdData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _loadHouseholdData() {
    setState(() => _isLoading = true);
    
    // Mock patient data
    _patientData = {
      'id': widget.patientId ?? 'PAT001',
      'name': 'Ahmad Khan',
      'age': 35,
      'gender': 'Male',
      'householdId': 'HH001',
      'address': 'House 123, Street 5, Lahore',
      'isIndexCase': true,
    };
    
    // Mock household members
    _householdMembers = [
      {
        'id': 'HM001',
        'name': 'Fatima Khan',
        'age': 32,
        'gender': 'Female',
        'relationship': 'Spouse',
        'phone': '+92 300 7654321',
        'screeningStatus': 'completed',
        'screeningDate': DateTime(2025, 8, 15),
        'riskLevel': 'high',
        'tbStatus': 'negative',
        'nextScreeningDue': DateTime(2025, 11, 15),
        'isIndexCase': false,
        'symptoms': [],
        'testResults': {
          'xray': 'normal',
          'sputum': 'negative',
          'skinTest': 'negative',
        },
      },
      {
        'id': 'HM002',
        'name': 'Ali Khan',
        'age': 8,
        'gender': 'Male',
        'relationship': 'Son',
        'phone': null,
        'screeningStatus': 'pending',
        'screeningDate': null,
        'riskLevel': 'high',
        'tbStatus': 'unknown',
        'nextScreeningDue': DateTime(2025, 9, 10),
        'isIndexCase': false,
        'symptoms': ['persistent_cough'],
        'testResults': {},
      },
      {
        'id': 'HM003',
        'name': 'Aisha Khan',
        'age': 12,
        'gender': 'Female',
        'relationship': 'Daughter',
        'phone': null,
        'screeningStatus': 'completed',
        'screeningDate': DateTime(2025, 8, 20),
        'riskLevel': 'medium',
        'tbStatus': 'negative',
        'nextScreeningDue': DateTime(2025, 12, 20),
        'isIndexCase': false,
        'symptoms': [],
        'testResults': {
          'xray': 'normal',
          'skinTest': 'negative',
        },
      },
      {
        'id': 'HM004',
        'name': 'Muhammad Khan',
        'age': 65,
        'gender': 'Male',
        'relationship': 'Father',
        'phone': '+92 301 9876543',
        'screeningStatus': 'overdue',
        'screeningDate': null,
        'riskLevel': 'high',
        'tbStatus': 'unknown',
        'nextScreeningDue': DateTime(2025, 8, 30),
        'isIndexCase': false,
        'symptoms': ['weight_loss', 'fatigue'],
        'testResults': {},
      },
      {
        'id': 'HM005',
        'name': 'Khadija Khan',
        'age': 60,
        'gender': 'Female',
        'relationship': 'Mother',
        'phone': '+92 302 1234567',
        'screeningStatus': 'scheduled',
        'screeningDate': DateTime(2025, 9, 8),
        'riskLevel': 'medium',
        'tbStatus': 'unknown',
        'nextScreeningDue': DateTime(2025, 9, 8),
        'isIndexCase': false,
        'symptoms': [],
        'testResults': {},
      },
    ];
    
    // Calculate household statistics
    _householdStats = {
      'totalMembers': _householdMembers.length + 1, // +1 for index case
      'screenedMembers': _householdMembers.where((m) => m['screeningStatus'] == 'completed').length,
      'pendingScreening': _householdMembers.where((m) => m['screeningStatus'] == 'pending' || m['screeningStatus'] == 'scheduled').length,
      'overdueScreening': _householdMembers.where((m) => m['screeningStatus'] == 'overdue').length,
      'highRiskMembers': _householdMembers.where((m) => m['riskLevel'] == 'high').length,
      'symptomatic': _householdMembers.where((m) => (m['symptoms'] as List).isNotEmpty).length,
    };
    
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
          'Household Members',
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
            onPressed: () => _showHouseholdInfo(),
            icon: const Icon(Icons.info_outline),
            tooltip: 'Household Information',
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
                    Text('Export List', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    const Icon(Icons.print),
                    const SizedBox(width: 8),
                    Text('Print Report', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'schedule_all',
                child: Row(
                  children: [
                    const Icon(Icons.schedule),
                    const SizedBox(width: 8),
                    Text('Schedule All Screening', style: GoogleFonts.poppins()),
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
                  _buildIndexCaseHeader(),
                  _buildHouseholdStats(),
                  _buildFilterTabs(),
                  Expanded(
                    child: _buildMembersList(),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addHouseholdMember(),
        backgroundColor: MadadgarTheme.primaryColor,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text(
          'Add Member',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildIndexCaseHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade700, Colors.red.shade500],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.coronavirus,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'INDEX CASE',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'TB POSITIVE',
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _patientData['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_patientData['age']} years • ${_patientData['gender']} • Patient ID: ${_patientData['id']}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.home, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _patientData['address'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseholdStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics, color: MadadgarTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Household Screening Status',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.2,
                children: [
                  _buildStatCard(
                    'Total Members',
                    '${_householdStats['totalMembers']}',
                    Icons.group,
                    MadadgarTheme.primaryColor,
                  ),
                  _buildStatCard(
                    'Screened',
                    '${_householdStats['screenedMembers']}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Pending',
                    '${_householdStats['pendingScreening']}',
                    Icons.schedule,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'Overdue',
                    '${_householdStats['overdueScreening']}',
                    Icons.warning,
                    Colors.red,
                  ),
                  _buildStatCard(
                    'High Risk',
                    '${_householdStats['highRiskMembers']}',
                    Icons.priority_high,
                    Colors.deepOrange,
                  ),
                  _buildStatCard(
                    'Symptomatic',
                    '${_householdStats['symptomatic']}',
                    Icons.sick,
                    Colors.red.shade600,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      {'key': 'all', 'label': 'All Members'},
      {'key': 'pending', 'label': 'Pending'},
      {'key': 'overdue', 'label': 'Overdue'},
      {'key': 'completed', 'label': 'Completed'},
      {'key': 'high_risk', 'label': 'High Risk'},
      {'key': 'symptomatic', 'label': 'Symptomatic'},
    ];
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            bool isSelected = _selectedFilter == filter['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text(
                  filter['label']!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isSelected ? Colors.white : MadadgarTheme.primaryColor,
                  ),
                ),
                selectedColor: MadadgarTheme.primaryColor,
                backgroundColor: Colors.white,
                side: BorderSide(color: MadadgarTheme.primaryColor),
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter['key']!;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    List<Map<String, dynamic>> filteredMembers = _getFilteredMembers();
    
    if (filteredMembers.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredMembers.length,
      itemBuilder: (context, index) {
        return _buildMemberCard(filteredMembers[index]);
      },
    );
  }

  List<Map<String, dynamic>> _getFilteredMembers() {
    switch (_selectedFilter) {
      case 'pending':
        return _householdMembers.where((m) => m['screeningStatus'] == 'pending' || m['screeningStatus'] == 'scheduled').toList();
      case 'overdue':
        return _householdMembers.where((m) => m['screeningStatus'] == 'overdue').toList();
      case 'completed':
        return _householdMembers.where((m) => m['screeningStatus'] == 'completed').toList();
      case 'high_risk':
        return _householdMembers.where((m) => m['riskLevel'] == 'high').toList();
      case 'symptomatic':
        return _householdMembers.where((m) => (m['symptoms'] as List).isNotEmpty).toList();
      default:
        return _householdMembers;
    }
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    Color statusColor = _getStatusColor(member['screeningStatus']);
    Color riskColor = _getRiskColor(member['riskLevel']);
    bool hasSymptoms = (member['symptoms'] as List).isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () => _viewMemberDetails(member),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: _getGenderColor(member['gender']).withOpacity(0.1),
                      child: Icon(
                        member['gender'] == 'Male' ? Icons.man : Icons.woman,
                        color: _getGenderColor(member['gender']),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  member['name'],
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              if (hasSymptoms)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.sick, color: Colors.red, size: 12),
                                      const SizedBox(width: 2),
                                      Text(
                                        'SYMPTOMS',
                                        style: GoogleFonts.poppins(
                                          fontSize: 8,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            '${member['age']} years • ${member['relationship']}',
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            member['screeningStatus'].toString().toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${member['riskLevel']} RISK',
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              color: riskColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Contact and screening info
                Row(
                  children: [
                    if (member['phone'] != null) ...[
                      Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        member['phone'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ] else ...[
                      Icon(Icons.phone_disabled, size: 16, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'No phone',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (member['screeningDate'] != null) ...[
                      Icon(Icons.event, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Screened: ${_formatDate(member['screeningDate'])}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Next screening due
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: statusColor),
                      const SizedBox(width: 8),
                      Text(
                        'Next screening: ${_formatDate(member['nextScreeningDue'])}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _getDaysUntilDue(member['nextScreeningDue']),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Symptoms list
                if (hasSymptoms) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Reported Symptoms:',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: (member['symptoms'] as List).map<Widget>((symptom) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getSymptomDisplayName(symptom),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.red,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // Action buttons
                Row(
                  children: [
                    if (member['screeningStatus'] == 'pending' || member['screeningStatus'] == 'overdue') ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _startScreening(member),
                          icon: Icon(Icons.medical_services, size: 16),
                          label: Text(
                            'Start Screening',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ] else if (member['screeningStatus'] == 'scheduled') ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _viewSchedule(member),
                          icon: Icon(Icons.schedule, size: 16),
                          label: Text(
                            'View Schedule',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    
                    if (member['phone'] != null)
                      OutlinedButton.icon(
                        onPressed: () => _callMember(member),
                        icon: Icon(Icons.phone, size: 16),
                        label: Text(
                          'Call',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        ),
                      ),
                    
                    const SizedBox(width: 8),
                    
                    PopupMenuButton<String>(
                      onSelected: (action) => _handleMemberAction(action, member),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit, size: 16),
                              const SizedBox(width: 8),
                              Text('Edit Details', style: GoogleFonts.poppins(fontSize: 12)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'history',
                          child: Row(
                            children: [
                              const Icon(Icons.history, size: 16),
                              const SizedBox(width: 8),
                              Text('Screening History', style: GoogleFonts.poppins(fontSize: 12)),
                            ],
                          ),
                        ),
                        if (member['screeningStatus'] != 'overdue')
                          PopupMenuItem(
                            value: 'reschedule',
                            child: Row(
                              children: [
                                const Icon(Icons.schedule, size: 16),
                                const SizedBox(width: 8),
                                Text('Reschedule', style: GoogleFonts.poppins(fontSize: 12)),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              const Icon(Icons.delete, size: 16, color: Colors.red),
                              const SizedBox(width: 8),
                              Text('Remove', style: GoogleFonts.poppins(fontSize: 12, color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No household members found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            'Add family members to start contact tracing',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _addHouseholdMember(),
            icon: const Icon(Icons.person_add),
            label: Text(
              'Add First Member',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: MadadgarTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'scheduled':
        return Colors.blue;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getRiskColor(String risk) {
    switch (risk) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getGenderColor(String gender) {
    return gender == 'Male' ? Colors.blue : Colors.pink;
  }

  String _getSymptomDisplayName(String symptom) {
    switch (symptom) {
      case 'persistent_cough':
        return 'Persistent Cough';
      case 'weight_loss':
        return 'Weight Loss';
      case 'night_sweats':
        return 'Night Sweats';
      case 'fever':
        return 'Fever';
      case 'fatigue':
        return 'Fatigue';
      case 'loss_of_appetite':
        return 'Loss of Appetite';
      default:
        return symptom;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getDaysUntilDue(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    
    if (difference < 0) {
      return '${difference.abs()} days overdue';
    } else if (difference == 0) {
      return 'Due today';
    } else if (difference == 1) {
      return 'Due tomorrow';
    } else {
      return 'Due in $difference days';
    }
  }

  void _addHouseholdMember() {
    Navigator.pushNamed(context, '/add-household-member', arguments: {
      'patientId': widget.patientId,
      'householdId': _patientData['householdId'],
    });
  }

  void _viewMemberDetails(Map<String, dynamic> member) {
    Navigator.pushNamed(context, '/household-member-details', arguments: member);
  }

  void _startScreening(Map<String, dynamic> member) {
    Navigator.pushNamed(context, '/contact-screening', arguments: member);
  }

  void _viewSchedule(Map<String, dynamic> member) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View schedule feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _callMember(Map<String, dynamic> member) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling ${member['name']}...', style: GoogleFonts.poppins())),
    );
  }

  void _handleMemberAction(String action, Map<String, dynamic> member) {
    switch (action) {
      case 'edit':
        _editMember(member);
        break;
      case 'history':
        _viewHistory(member);
        break;
      case 'reschedule':
        _rescheduleScreening(member);
        break;
      case 'remove':
        _removeMember(member);
        break;
    }
  }

  void _editMember(Map<String, dynamic> member) {
    Navigator.pushNamed(context, '/edit-household-member', arguments: member);
  }

  void _viewHistory(Map<String, dynamic> member) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Screening history feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _rescheduleScreening(Map<String, dynamic> member) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reschedule screening feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _removeMember(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Member', style: GoogleFonts.poppins()),
        content: Text(
          'Are you sure you want to remove ${member['name']} from the household?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _householdMembers.removeWhere((m) => m['id'] == member['id']);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Member removed', style: GoogleFonts.poppins())),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Remove', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showHouseholdInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Household info feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportList();
        break;
      case 'print':
        _printReport();
        break;
      case 'schedule_all':
        _scheduleAllScreening();
        break;
    }
  }

  void _exportList() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export list feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _printReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Print report feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _scheduleAllScreening() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Schedule all screening feature coming soon!', style: GoogleFonts.poppins())),
    );
  }
}
