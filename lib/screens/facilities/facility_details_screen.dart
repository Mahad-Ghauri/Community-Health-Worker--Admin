// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/facility_provider.dart';
import '../../models/facility.dart';
import 'facility_dashboard.dart';

class FacilityDetailsScreen extends StatefulWidget {
  final String facilityId;

  const FacilityDetailsScreen({super.key, required this.facilityId});

  @override
  State<FacilityDetailsScreen> createState() => _FacilityDetailsScreenState();
}

class _FacilityDetailsScreenState extends State<FacilityDetailsScreen> {
  bool _isLoading = true;
  Facility? _facility;
  String? _error;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadFacility();
  }

  Future<void> _loadFacility() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final facilityProvider = Provider.of<FacilityProvider>(
        context,
        listen: false,
      );
      final facility = await facilityProvider.getFacilityById(
        widget.facilityId,
      );

      setState(() {
        _facility = facility;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load facility: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_facility?.name ?? 'Facility Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFacility,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorMessage()
          : _facility == null
          ? _buildNotFoundMessage()
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildTabBar(),
        Expanded(child: _buildTabContent()),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        onTap: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        tabs: const [
          Tab(text: 'Dashboard'),
          Tab(text: 'Details'),
          Tab(text: 'Staff'),
          Tab(text: 'Patients'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return FacilityDashboard(facilityId: widget.facilityId);
      case 1:
        return _buildFacilityDetails();
      case 2:
        return _buildFacilityStaff();
      case 3:
        return _buildFacilityPatients();
      default:
        return const Center(child: Text('Tab not implemented'));
    }
  }

  Widget _buildFacilityDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Facility Information',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Name', _facility!.name),
                  const Divider(),
                  _buildInfoRow('Type', _facility!.typeDisplayName),
                  const Divider(),
                  _buildInfoRow('Status', _facility!.statusDisplayName),
                  const Divider(),
                  _buildInfoRow('Address', _facility!.address),
                  const Divider(),
                  _buildInfoRow('Contact Phone', _facility!.contactPhone),
                  const Divider(),
                  _buildInfoRow('Contact Email', _facility!.contactEmail),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityStaff() {
    return const Center(
      child: Text('Facility staff list will be displayed here'),
    );
  }

  Widget _buildFacilityPatients() {
    return const Center(
      child: Text('Facility patients list will be displayed here'),
    );
  }

  Widget _buildErrorMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error Loading Facility',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.red),
          ),
          const SizedBox(height: 8),
          Text(_error ?? 'Unknown error occurred', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadFacility, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildNotFoundMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Facility Not Found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'The facility with ID ${widget.facilityId} could not be found.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
