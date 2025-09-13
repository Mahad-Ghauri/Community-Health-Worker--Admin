import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/facility_provider.dart';
import '../../models/facility.dart';
import '../../widgets/common_widgets.dart' as common;
import '../../utils/responsive_helper.dart';

class FacilityListScreen extends StatefulWidget {
  const FacilityListScreen({super.key});

  @override
  State<FacilityListScreen> createState() => _FacilityListScreenState();
}

class _FacilityListScreenState extends State<FacilityListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedFacilities = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<FacilityProvider>(context, listen: false);
      provider.loadFacilities();
      provider.loadStatistics();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Consumer<FacilityProvider>(
        builder: (context, facilityProvider, child) {
          if (facilityProvider.isLoading && facilityProvider.facilities.isEmpty) {
            return const Center(child: common.LoadingWidget());
          }

          return Column(
            children: [
              _buildHeader(context, facilityProvider),
              _buildStatisticsCards(context, facilityProvider),
              _buildFiltersBar(context, facilityProvider),
              Expanded(
                child: _buildFacilitiesList(context, facilityProvider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/facilities/create'),
        icon: const Icon(Icons.add),
        label: const Text('Add Facility'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, FacilityProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Facilities',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage healthcare facilities and their information',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (_selectedFacilities.isNotEmpty) ...[
            common.CustomButton(
              text: 'Delete Selected (${_selectedFacilities.length})',
              onPressed: () => _showDeleteConfirmation(context, provider),
              isSecondary: true,
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(BuildContext context, FacilityProvider provider) {
    final stats = provider.statistics;
    final isTablet = ResponsiveHelper.isTablet(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: isTablet ? 5 : 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: isTablet ? 2.5 : 2.0,
        children: [
          _buildStatCard(
            context,
            'Total Facilities',
            stats['total']?.toString() ?? '0',
            Icons.business,
            Theme.of(context).colorScheme.primary,
          ),
          _buildStatCard(
            context,
            'Active',
            stats['active']?.toString() ?? '0',
            Icons.check_circle,
            Colors.green,
          ),
          _buildStatCard(
            context,
            'Hospitals',
            stats['hospital']?.toString() ?? '0',
            Icons.local_hospital,
            Colors.blue,
          ),
          _buildStatCard(
            context,
            'Health Centers',
            stats['healthCenter']?.toString() ?? '0',
            Icons.health_and_safety,
            Colors.orange,
          ),
          _buildStatCard(
            context,
            'Clinics',
            stats['clinic']?.toString() ?? '0',
            Icons.medical_services,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersBar(BuildContext context, FacilityProvider provider) {
    final isTablet = ResponsiveHelper.isTablet(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: isTablet ? _buildTabletFilters(context, provider) : _buildMobileFilters(context, provider),
    );
  }

  Widget _buildTabletFilters(BuildContext context, FacilityProvider provider) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: common.CustomTextField(
            label: 'Search',
            hint: 'Search facilities...',
            controller: _searchController,
            prefixIcon: const Icon(Icons.search),
            onChanged: provider.searchFacilities,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: provider.typeFilter.isEmpty ? 'All Types' : provider.typeFilter,
            decoration: const InputDecoration(
              labelText: 'Type',
              border: OutlineInputBorder(),
            ),
            items: FacilityProvider.typeFilterOptions.map((type) {
              return DropdownMenuItem(value: type, child: Text(type));
            }).toList(),
            onChanged: (value) => provider.filterByType(value ?? ''),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: provider.statusFilter.isEmpty ? 'All Status' : provider.statusFilter,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: FacilityProvider.statusFilterOptions.map((status) {
              return DropdownMenuItem(value: status, child: Text(status));
            }).toList(),
            onChanged: (value) => provider.filterByStatus(value ?? ''),
          ),
        ),
        if (provider.hasActiveFilters) ...[
          const SizedBox(width: 16),
          IconButton(
            onPressed: () {
              _searchController.clear();
              provider.clearFilters();
            },
            icon: const Icon(Icons.clear),
            tooltip: 'Clear filters',
          ),
        ],
      ],
    );
  }

  Widget _buildMobileFilters(BuildContext context, FacilityProvider provider) {
    return Column(
      children: [
        common.CustomTextField(
          label: 'Search',
          hint: 'Search facilities...',
          controller: _searchController,
          prefixIcon: const Icon(Icons.search),
          onChanged: provider.searchFacilities,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: provider.typeFilter.isEmpty ? 'All Types' : provider.typeFilter,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: FacilityProvider.typeFilterOptions.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) => provider.filterByType(value ?? ''),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: provider.statusFilter.isEmpty ? 'All Status' : provider.statusFilter,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: FacilityProvider.statusFilterOptions.map((status) {
                  return DropdownMenuItem(value: status, child: Text(status));
                }).toList(),
                onChanged: (value) => provider.filterByStatus(value ?? ''),
              ),
            ),
            if (provider.hasActiveFilters) ...[
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  _searchController.clear();
                  provider.clearFilters();
                },
                icon: const Icon(Icons.clear),
                tooltip: 'Clear filters',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildFacilitiesList(BuildContext context, FacilityProvider provider) {
    if (provider.error != null) {
      return Center(
        child: common.ErrorWidget(
          message: provider.error!,
          onRetry: () {
            provider.clearError();
            provider.loadFacilities();
          },
        ),
      );
    }

    final facilities = provider.facilities;
    
    if (facilities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              provider.hasActiveFilters
                  ? 'No facilities found matching your filters'
                  : 'No facilities found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (provider.hasActiveFilters) ...[
              Text(
                provider.filtersDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              common.CustomButton(
                text: 'Clear Filters',
                onPressed: () {
                  _searchController.clear();
                  provider.clearFilters();
                },
                isSecondary: true,
              ),
            ] else ...[
              Text(
                'Start by creating your first facility',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              common.CustomButton(
                text: 'Create Facility',
                onPressed: () => context.push('/facilities/create'),
              ),
            ],
          ],
        ),
      );
    }

    final isTablet = ResponsiveHelper.isTablet(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: isTablet
          ? _buildTabletList(context, facilities, provider)
          : _buildMobileList(context, facilities, provider),
    );
  }

  Widget _buildTabletList(BuildContext context, List<Facility> facilities, FacilityProvider provider) {
    return SingleChildScrollView(
      child: Card(
        elevation: 2,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _selectedFacilities.length == facilities.length && facilities.isNotEmpty,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedFacilities.addAll(facilities.map((f) => f.facilityId));
                        } else {
                          _selectedFacilities.clear();
                        }
                      });
                    },
                  ),
                  const Expanded(flex: 2, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  const Expanded(child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                  const Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  const Expanded(child: Text('Staff', style: TextStyle(fontWeight: FontWeight.bold))),
                  const Expanded(child: Text('Services', style: TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(width: 100, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            // Facility rows
            ...facilities.map((facility) => _buildTabletFacilityRow(context, facility, provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletFacilityRow(BuildContext context, Facility facility, FacilityProvider provider) {
    final isSelected = _selectedFacilities.contains(facility.facilityId);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedFacilities.add(facility.facilityId);
                } else {
                  _selectedFacilities.remove(facility.facilityId);
                }
              });
            },
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  facility.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  facility.address,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(facility.typeDisplayName),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: facility.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                facility.statusDisplayName,
                style: TextStyle(
                  color: facility.isActive ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text('${facility.totalPersonnel}'),
          ),
          Expanded(
            child: Text(
              facility.servicesDisplayText,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 100,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.push('/facilities/edit/${facility.facilityId}'),
                  tooltip: 'Edit facility',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteFacilityDialog(context, facility, provider),
                  tooltip: 'Delete facility',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, List<Facility> facilities, FacilityProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: facilities.length,
      itemBuilder: (context, index) {
        final facility = facilities[index];
        return _buildMobileFacilityCard(context, facility, provider);
      },
    );
  }

  Widget _buildMobileFacilityCard(BuildContext context, Facility facility, FacilityProvider provider) {
    final isSelected = _selectedFacilities.contains(facility.facilityId);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/facilities/details/${facility.facilityId}'),
        onLongPress: () {
          setState(() {
            if (isSelected) {
              _selectedFacilities.remove(facility.facilityId);
            } else {
              _selectedFacilities.add(facility.facilityId);
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      facility.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: facility.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      facility.statusDisplayName,
                      style: TextStyle(
                        color: facility.isActive ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      facility.address,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      facility.typeDisplayName,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.people, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(
                    '${facility.totalPersonnel} staff',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                facility.servicesDisplayText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => context.push('/facilities/edit/${facility.facilityId}'),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: () => _showDeleteFacilityDialog(context, facility, provider),
                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteFacilityDialog(BuildContext context, Facility facility, FacilityProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Facility'),
        content: Text('Are you sure you want to delete "${facility.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await provider.deleteFacility(facility.facilityId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${facility.name} deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete facility: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, FacilityProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Facilities'),
        content: Text('Are you sure you want to delete ${_selectedFacilities.length} selected facilities? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await provider.deleteFacilities(_selectedFacilities.toList());
                setState(() {
                  _selectedFacilities.clear();
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Selected facilities deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete facilities: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}