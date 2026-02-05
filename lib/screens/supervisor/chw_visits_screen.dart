import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/visit_service.dart';
import '../../theme/theme.dart';
import '../../constants/app_constants.dart';
import 'package:go_router/go_router.dart';

class CHWVisitsScreen extends StatefulWidget {
  const CHWVisitsScreen({super.key});

  @override
  State<CHWVisitsScreen> createState() => _CHWVisitsScreenState();
}

class _CHWVisitsScreenState extends State<CHWVisitsScreen> {
  final VisitService _visitService = VisitService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedVisitType = '';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Note: facilityId filtering disabled because visits don't have facilityId field
    // final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // final facilityId = authProvider.currentUser?.facilityId;

    return Scaffold(
      backgroundColor: CHWTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('CHW Field Visits'),
        backgroundColor: CHWTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppConstants.supervisorDashboardRoute),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by CHW, patient, or notes...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),
                const SizedBox(height: 12),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', ''),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Home Visits',
                        AppConstants.homeVisitType,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip('Follow-ups', AppConstants.followUpType),
                      const SizedBox(width: 8),
                      _buildFilterChip('Tracing', AppConstants.tracingType),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Medicine Delivery',
                        AppConstants.medicineDeliveryType,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Counseling',
                        AppConstants.counselingType,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Visits list
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _visitService.getAllVisits(
                limit: 200,
                facilityId: null, // Don't filter - visits don't have facilityId yet
              ),
              builder: (context, snapshot) {
                // Debug logging
                print('🔍 CHW Visits Stream State:');
                print('  Connection: ${snapshot.connectionState}');
                print('  Has Error: ${snapshot.hasError}');
                print('  Has Data: ${snapshot.hasData}');
                if (snapshot.hasData) {
                  print('  Data Count: ${snapshot.data?.length ?? 0}');
                  if (snapshot.data!.isNotEmpty) {
                    print('  First visit: ${snapshot.data!.first}');
                  }
                }
                if (snapshot.hasError) {
                  print('  ❌ Error: ${snapshot.error}');
                  print('  Stack: ${snapshot.stackTrace}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: CHWTheme.errorColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading visits',
                          style: CHWTheme.bodyStyle.copyWith(
                            color: CHWTheme.errorColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            snapshot.error.toString(),
                            style: CHWTheme.bodyStyle.copyWith(
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {}); // Trigger rebuild
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final allVisits = snapshot.data ?? [];

                if (allVisits.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No visits recorded yet',
                          style: CHWTheme.subheadingStyle.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'CHW field visits will appear here',
                          style: CHWTheme.bodyStyle.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Apply filters
                final filteredVisits = allVisits.where((visit) {
                  // Filter by visit type
                  if (_selectedVisitType.isNotEmpty &&
                      visit['visitType'] != _selectedVisitType) {
                    return false;
                  }

                  // Filter by search query
                  if (_searchQuery.isNotEmpty) {
                    final chwId = (visit['chwId'] ?? '')
                        .toString()
                        .toLowerCase();
                    final patientId = (visit['patientId'] ?? '')
                        .toString()
                        .toLowerCase();
                    final notes = (visit['notes'] ?? '')
                        .toString()
                        .toLowerCase();
                    final chwName = (visit['chwName'] ?? '')
                        .toString()
                        .toLowerCase();
                    final patientName = (visit['patientName'] ?? '')
                        .toString()
                        .toLowerCase();

                    if (!chwId.contains(_searchQuery) &&
                        !patientId.contains(_searchQuery) &&
                        !notes.contains(_searchQuery) &&
                        !chwName.contains(_searchQuery) &&
                        !patientName.contains(_searchQuery)) {
                      return false;
                    }
                  }

                  return true;
                }).toList();

                if (filteredVisits.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No visits found',
                          style: CHWTheme.subheadingStyle.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: CHWTheme.bodyStyle.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredVisits.length,
                  itemBuilder: (context, index) {
                    return _buildVisitCard(filteredVisits[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedVisitType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedVisitType = selected ? value : '';
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: CHWTheme.primaryColor.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? CHWTheme.primaryColor : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildVisitCard(Map<String, dynamic> visit) {
    final visitDate =
        (visit['visitDate'] as Timestamp?)?.toDate() ??
        (visit['date'] as Timestamp?)?.toDate() ??
        DateTime.now();
    final visitType = visit['visitType'] ?? 'Unknown';
    final found = visit['found'] ?? false;
    final notes = visit['notes'] ?? 'No notes';
    final chwId = visit['chwId'] ?? 'Unknown CHW';
    final patientId = visit['patientId'] ?? 'Unknown Patient';
    final chwName = visit['chwName'] ?? chwId;
    final patientName = visit['patientName'] ?? patientId;

    // Determine visit type icon and color
    IconData visitIcon;
    Color visitColor;
    String visitTypeLabel;

    switch (visitType) {
      case AppConstants.homeVisitType:
        visitIcon = Icons.home;
        visitColor = Colors.blue;
        visitTypeLabel = 'Home Visit';
        break;
      case AppConstants.followUpType:
        visitIcon = Icons.event_note;
        visitColor = Colors.green;
        visitTypeLabel = 'Follow-up';
        break;
      case AppConstants.tracingType:
        visitIcon = Icons.search;
        visitColor = Colors.orange;
        visitTypeLabel = 'Tracing';
        break;
      case AppConstants.medicineDeliveryType:
        visitIcon = Icons.local_pharmacy;
        visitColor = Colors.purple;
        visitTypeLabel = 'Medicine Delivery';
        break;
      case AppConstants.counselingType:
        visitIcon = Icons.psychology;
        visitColor = Colors.teal;
        visitTypeLabel = 'Counseling';
        break;
      default:
        visitIcon = Icons.assignment;
        visitColor = Colors.grey;
        visitTypeLabel = visitType;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: found
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showVisitDetails(visit),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: visitColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(visitIcon, color: visitColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visitTypeLabel,
                          style: CHWTheme.subheadingStyle.copyWith(
                            color: CHWTheme.primaryColor,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, y - h:mm a').format(visitDate),
                          style: CHWTheme.bodyStyle.copyWith(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: found
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          found ? Icons.check_circle : Icons.cancel,
                          color: found ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          found ? 'Found' : 'Not Found',
                          style: CHWTheme.bodyStyle.copyWith(
                            color: found ? Colors.green[700] : Colors.red[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'CHW: ',
                    style: CHWTheme.bodyStyle.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      chwName,
                      style: CHWTheme.bodyStyle.copyWith(
                        color: CHWTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.medical_information_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Patient: ',
                    style: CHWTheme.bodyStyle.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      patientName,
                      style: CHWTheme.bodyStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (notes.isNotEmpty && notes != 'No notes') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notes,
                          style: CHWTheme.bodyStyle.copyWith(
                            color: Colors.grey[800],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showVisitDetails(Map<String, dynamic> visit) {
    final visitDate =
        (visit['visitDate'] as Timestamp?)?.toDate() ??
        (visit['date'] as Timestamp?)?.toDate() ??
        DateTime.now();
    final visitType = visit['visitType'] ?? 'Unknown';
    final found = visit['found'] ?? false;
    final notes = visit['notes'] ?? 'No notes';
    final chwId = visit['chwId'] ?? 'Unknown CHW';
    final patientId = visit['patientId'] ?? 'Unknown Patient';
    final chwName = visit['chwName'] ?? chwId;
    final patientName = visit['patientName'] ?? patientId;
    final gpsLocation = visit['gpsLocation'] as Map<String, dynamic>?;
    final photos = visit['photos'] as List?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Visit Details',
                        style: CHWTheme.headingStyle.copyWith(
                          color: CHWTheme.primaryColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow('Visit Type', _formatVisitType(visitType)),
                  _buildDetailRow(
                    'Date & Time',
                    DateFormat('MMM d, y - h:mm a').format(visitDate),
                  ),
                  _buildDetailRow(
                    'Status',
                    found ? 'Patient Found' : 'Patient Not Found',
                  ),
                  const Divider(height: 32),
                  _buildDetailRow('CHW', chwName),
                  _buildDetailRow('CHW ID', chwId),
                  _buildDetailRow('Patient', patientName),
                  _buildDetailRow('Patient ID', patientId),
                  const Divider(height: 32),
                  Text(
                    'Notes',
                    style: CHWTheme.subheadingStyle.copyWith(
                      color: CHWTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(notes, style: CHWTheme.bodyStyle),
                  ),
                  if (gpsLocation != null && gpsLocation.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'GPS Location',
                      style: CHWTheme.subheadingStyle.copyWith(
                        color: CHWTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Latitude',
                      gpsLocation['latitude']?.toString() ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Longitude',
                      gpsLocation['longitude']?.toString() ?? 'N/A',
                    ),
                  ],
                  if (photos != null && photos.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Photos (${photos.length})',
                      style: CHWTheme.subheadingStyle.copyWith(
                        color: CHWTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Photos attached',
                      style: CHWTheme.bodyStyle.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: CHWTheme.bodyStyle.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: CHWTheme.bodyStyle.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatVisitType(String type) {
    switch (type) {
      case AppConstants.homeVisitType:
        return 'Home Visit';
      case AppConstants.followUpType:
        return 'Follow-up Visit';
      case AppConstants.tracingType:
        return 'Patient Tracing';
      case AppConstants.medicineDeliveryType:
        return 'Medicine Delivery';
      case AppConstants.counselingType:
        return 'Counseling Session';
      default:
        return type;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter Visits'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Use the filter chips below the search bar to filter by visit type.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
