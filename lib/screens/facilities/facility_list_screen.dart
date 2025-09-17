// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/facility_provider.dart';
import '../../models/facility.dart';
import '../../widgets/common_widgets.dart' as common;

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

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context, facilityProvider),
                _buildStatisticsCards(context, facilityProvider),
                _buildFiltersBar(context, facilityProvider),
                _buildFacilitiesList(context, facilityProvider),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Builder(
        builder: (context) {
          final mediaQuery = MediaQuery.of(context);
          final screenWidth = mediaQuery.size.width;
          
          if (screenWidth < 480) {
            // Compact FAB for small screens
            return FloatingActionButton(
              onPressed: () => context.push('/facilities/create'),
              child: const Icon(Icons.add),
            );
          } else {
            // Extended FAB for larger screens
            return FloatingActionButton.extended(
              onPressed: () => context.push('/facilities/create'),
              icon: const Icon(Icons.add),
              label: Text(
                screenWidth < 768 ? 'Add' : 'Add Facility',
                style: TextStyle(
                  fontSize: screenWidth < 768 ? 13.0 : 14.0,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, FacilityProvider provider) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isCompact = screenWidth < 600;
    final isSmallMobile = screenWidth < 480;
    
    // Adaptive font sizes based on screen width
    final titleFontSize = isSmallMobile ? 20.0 : 
                          isCompact ? 24.0 : 
                          screenWidth < 900 ? 28.0 :
                          screenWidth < 1200 ? 32.0 : 36.0;
    
    final subtitleFontSize = isSmallMobile ? 12.0 :
                             isCompact ? 14.0 :
                             screenWidth < 1200 ? 16.0 : 18.0;
    
    // Adaptive padding
    final padding = screenWidth < 480 ? 16.0 :
                   screenWidth < 768 ? 20.0 :
                   screenWidth < 1024 ? 24.0 : 32.0;
    
    // Adaptive button sizing
    final buttonHeight = screenWidth < 480 ? 40.0 :
                        screenWidth < 768 ? 44.0 :
                        screenWidth < 1024 ? 48.0 : 52.0;

    if (isSmallMobile) {
      // Stack vertically for very small screens
      return Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Facilities',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: screenWidth * 0.01),
            Text(
              'Manage healthcare facilities and their information',
              style: TextStyle(
                fontSize: subtitleFontSize,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            if (_selectedFacilities.isNotEmpty) ...[
              SizedBox(height: screenWidth * 0.04),
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: common.CustomButton(
                  text: 'Delete Selected (${_selectedFacilities.length})',
                  onPressed: () => _showDeleteConfirmation(context, provider),
                  isSecondary: true,
                ),
              ),
            ],
          ],
        ),
      );
    }
    
    return Container(
      padding: EdgeInsets.all(padding),
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
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: screenWidth * 0.005),
                Text(
                  'Manage healthcare facilities and their information',
                  style: TextStyle(
                    fontSize: subtitleFontSize,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (_selectedFacilities.isNotEmpty) ...[
            SizedBox(width: screenWidth * 0.02),
            SizedBox(
              height: buttonHeight,
              child: common.CustomButton(
                text: isCompact ? 'Delete (${_selectedFacilities.length})' : 'Delete Selected (${_selectedFacilities.length})',
                onPressed: () => _showDeleteConfirmation(context, provider),
                isSecondary: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(BuildContext context, FacilityProvider provider) {
    final stats = provider.statistics;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    
    // Calculate optimal columns based on screen width
    int columns;
    if (screenWidth < 480) {
      columns = 1;
    } else if (screenWidth < 768) {
      columns = 2;
    } else if (screenWidth < 1024) {
      columns = 3;
    } else if (screenWidth < 1440) {
      columns = 4;
    } else {
      columns = 5;
    }
    
    // Dynamic spacing and padding based on screen width
    final spacing = screenWidth < 600 ? 12.0 :
                   screenWidth < 900 ? 16.0 :
                   screenWidth < 1200 ? 20.0 : 24.0;
    
    final padding = screenWidth < 480 ? 16.0 :
                   screenWidth < 768 ? 20.0 :
                   screenWidth < 1024 ? 24.0 : 32.0;

    return Container(
      padding: EdgeInsets.all(padding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate card width considering constraints and spacing
          final availableWidth = constraints.maxWidth;
          final totalSpacing = (columns - 1) * spacing;
          final cardWidth = (availableWidth - totalSpacing) / columns;
          
          final statsList = [
            {
              'title': 'Total Facilities',
              'value': stats['total']?.toString() ?? '0',
              'icon': Icons.business,
              'color': Theme.of(context).colorScheme.primary,
            },
            {
              'title': 'Active',
              'value': stats['active']?.toString() ?? '0',
              'icon': Icons.check_circle,
              'color': Colors.green,
            },
            {
              'title': 'Hospitals',
              'value': stats['hospital']?.toString() ?? '0',
              'icon': Icons.local_hospital,
              'color': Colors.blue,
            },
            {
              'title': 'Health Centers',
              'value': stats['healthCenter']?.toString() ?? '0',
              'icon': Icons.health_and_safety,
              'color': Colors.orange,
            },
            {
              'title': 'Clinics',
              'value': stats['clinic']?.toString() ?? '0',
              'icon': Icons.medical_services,
              'color': Colors.purple,
            },
          ];

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: statsList.map((stat) {
              return SizedBox(
                width: cardWidth,
                child: _buildAdaptiveStatCard(stat, screenWidth),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildAdaptiveStatCard(Map<String, dynamic> stat, double screenWidth) {
    // Adaptive measurements based on screen width
    final iconSize = screenWidth < 480 ? 20.0 :
                    screenWidth < 768 ? 24.0 :
                    screenWidth < 1024 ? 28.0 : 32.0;
    
    final titleFontSize = screenWidth < 480 ? 10.0 :
                         screenWidth < 768 ? 11.0 :
                         screenWidth < 1024 ? 12.0 : 13.0;
    
    final valueFontSize = screenWidth < 480 ? 16.0 :
                         screenWidth < 768 ? 18.0 :
                         screenWidth < 1024 ? 22.0 : 24.0;
    
    final cardPadding = screenWidth < 480 ? 12.0 :
                       screenWidth < 768 ? 14.0 :
                       screenWidth < 1024 ? 16.0 : 18.0;
    
    final borderRadius = screenWidth < 600 ? 8.0 :
                        screenWidth < 1024 ? 10.0 : 12.0;
    
    final elevation = screenWidth < 600 ? 1.0 :
                     screenWidth < 1024 ? 2.0 : 3.0;

    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Container(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth < 600 ? 6.0 : 8.0),
              decoration: BoxDecoration(
                color: (stat['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(screenWidth < 600 ? 6.0 : 8.0),
              ),
              child: Icon(
                stat['icon'] as IconData,
                size: iconSize,
                color: stat['color'] as Color,
              ),
            ),
            SizedBox(height: screenWidth * 0.012),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                stat['value'] as String,
                style: TextStyle(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.bold,
                  color: stat['color'] as Color,
                ),
              ),
            ),
            SizedBox(height: screenWidth * 0.006),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                stat['title'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: titleFontSize,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersBar(BuildContext context, FacilityProvider provider) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    
    // Adaptive padding
    final padding = screenWidth < 480 ? 16.0 :
                   screenWidth < 768 ? 20.0 :
                   screenWidth < 1024 ? 24.0 : 32.0;
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Determine layout based on available width
          if (screenWidth < 480) {
            return _buildVerticalFilters(context, provider, screenWidth);
          } else if (screenWidth < 768) {
            return _buildMixedFilters(context, provider, screenWidth);
          } else if (screenWidth < 1024) {
            return _buildHorizontalFilters(context, provider, screenWidth, 2);
          } else {
            return _buildFullHorizontalFilters(context, provider, screenWidth);
          }
        },
      ),
    );
  }

  Widget _buildVerticalFilters(BuildContext context, FacilityProvider provider, double screenWidth) {
    final spacing = screenWidth * 0.025;
    
    return Column(
      children: [
        _buildAdaptiveSearchField(context, provider, screenWidth),
        SizedBox(height: spacing),
        _buildAdaptiveTypeFilter(context, provider, screenWidth),
        SizedBox(height: spacing),
        _buildAdaptiveStatusFilter(context, provider, screenWidth),
        if (provider.hasActiveFilters) ...[
          SizedBox(height: spacing),
          SizedBox(
            width: double.infinity,
            child: _buildClearFiltersButton(context, provider, screenWidth),
          ),
        ],
      ],
    );
  }

  Widget _buildMixedFilters(BuildContext context, FacilityProvider provider, double screenWidth) {
    final spacing = screenWidth * 0.02;
    
    return Column(
      children: [
        _buildAdaptiveSearchField(context, provider, screenWidth),
        SizedBox(height: spacing),
        Row(
          children: [
            Expanded(child: _buildAdaptiveTypeFilter(context, provider, screenWidth)),
            SizedBox(width: spacing),
            Expanded(child: _buildAdaptiveStatusFilter(context, provider, screenWidth)),
            if (provider.hasActiveFilters) ...[
              SizedBox(width: spacing),
              _buildClearFiltersButton(context, provider, screenWidth),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildHorizontalFilters(BuildContext context, FacilityProvider provider, double screenWidth, int rows) {
    final spacing = screenWidth * 0.015;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 3, child: _buildAdaptiveSearchField(context, provider, screenWidth)),
            SizedBox(width: spacing),
            Expanded(child: _buildAdaptiveTypeFilter(context, provider, screenWidth)),
          ],
        ),
        SizedBox(height: spacing),
        Row(
          children: [
            Expanded(child: _buildAdaptiveStatusFilter(context, provider, screenWidth)),
            if (provider.hasActiveFilters) ...[
              SizedBox(width: spacing),
              _buildClearFiltersButton(context, provider, screenWidth),
            ] else ...[
              const Spacer(),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildFullHorizontalFilters(BuildContext context, FacilityProvider provider, double screenWidth) {
    final spacing = screenWidth < 1200 ? 16.0 : 
                   screenWidth < 1600 ? 20.0 : 24.0;
    
    return Row(
      children: [
        Expanded(flex: 3, child: _buildAdaptiveSearchField(context, provider, screenWidth)),
        SizedBox(width: spacing),
        Expanded(child: _buildAdaptiveTypeFilter(context, provider, screenWidth)),
        SizedBox(width: spacing),
        Expanded(child: _buildAdaptiveStatusFilter(context, provider, screenWidth)),
        if (provider.hasActiveFilters) ...[
          SizedBox(width: spacing),
          _buildClearFiltersButton(context, provider, screenWidth),
        ],
      ],
    );
  }

  Widget _buildAdaptiveSearchField(BuildContext context, FacilityProvider provider, double screenWidth) {
    return common.CustomTextField(
      label: 'Search',
      hint: screenWidth < 480 ? 'Search...' : 
            screenWidth < 768 ? 'Search facilities...' : 
            'Search facilities by name, type, or location...',
      controller: _searchController,
      prefixIcon: Icon(
        Icons.search,
        size: screenWidth < 480 ? 18.0 : 20.0,
      ),
      onChanged: provider.searchFacilities,
    );
  }

  Widget _buildAdaptiveTypeFilter(BuildContext context, FacilityProvider provider, double screenWidth) {
    return _buildAdaptiveDropdown(
      context: context,
      label: 'Type',
      value: provider.typeFilter.isEmpty ? 'All Types' : provider.typeFilter,
      items: FacilityProvider.typeFilterOptions,
      onChanged: (value) => provider.filterByType(value ?? ''),
      screenWidth: screenWidth,
    );
  }

  Widget _buildAdaptiveStatusFilter(BuildContext context, FacilityProvider provider, double screenWidth) {
    return _buildAdaptiveDropdown(
      context: context,
      label: 'Status',
      value: provider.statusFilter.isEmpty ? 'All Status' : provider.statusFilter,
      items: FacilityProvider.statusFilterOptions,
      onChanged: (value) => provider.filterByStatus(value ?? ''),
      screenWidth: screenWidth,
    );
  }

  Widget _buildAdaptiveDropdown({
    required BuildContext context,
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required double screenWidth,
  }) {
    final fontSize = screenWidth < 480 ? 13.0 :
                    screenWidth < 768 ? 14.0 :
                    screenWidth < 1024 ? 15.0 : 16.0;
    
    final borderRadius = screenWidth < 600 ? 8.0 :
                        screenWidth < 1024 ? 12.0 : 16.0;

    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: fontSize - 1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: screenWidth < 480 ? 12.0 : 16.0,
          vertical: screenWidth < 480 ? 12.0 : 16.0,
        ),
      ),
      style: TextStyle(fontSize: fontSize),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildClearFiltersButton(BuildContext context, FacilityProvider provider, double screenWidth) {
    final buttonHeight = screenWidth < 480 ? 40.0 :
                        screenWidth < 768 ? 44.0 :
                        screenWidth < 1024 ? 48.0 : 52.0;
    
    final buttonWidth = screenWidth < 480 ? double.infinity :
                       screenWidth < 768 ? 60.0 :
                       screenWidth < 1024 ? 80.0 : 100.0;

    Widget button = SizedBox(
      height: buttonHeight,
      width: screenWidth < 480 ? null : buttonWidth,
      child: IconButton(
        onPressed: () {
          _searchController.clear();
          provider.clearFilters();
        },
        icon: const Icon(Icons.clear),
        tooltip: 'Clear filters',
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
    );

    return screenWidth < 480 ? button : button;
  }

  Widget _buildFacilitiesList(BuildContext context, FacilityProvider provider) {
    if (provider.error != null) {
      return SizedBox(
        height: 300,
        child: Center(
          child: common.ErrorWidget(
            message: provider.error!,
            onRetry: () {
              provider.clearError();
              provider.loadFacilities();
            },
          ),
        ),
      );
    }

    final facilities = provider.facilities;
    
    if (facilities.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
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
        ),
      );
    }

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    
    // Adaptive padding
    final padding = screenWidth < 480 ? 16.0 :
                   screenWidth < 768 ? 20.0 :
                   screenWidth < 1024 ? 24.0 : 32.0;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: screenWidth < 768
          ? _buildMobileList(context, facilities, provider)
          : _buildTabletList(context, facilities, provider),
    );
  }

  Widget _buildTabletList(BuildContext context, List<Facility> facilities, FacilityProvider provider) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    
    // Adaptive measurements
    final cardPadding = screenWidth < 1024 ? 12.0 : 16.0;
    final borderRadius = screenWidth < 1024 ? 8.0 : 12.0;
    final headerFontSize = screenWidth < 1024 ? 14.0 : 16.0;
    final elevation = screenWidth < 1024 ? 1.0 : 2.0;
    
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
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
                Expanded(
                  flex: 2,
                  child: Text(
                    'Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: headerFontSize,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Type',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: headerFontSize,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: headerFontSize,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Staff',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: headerFontSize,
                    ),
                  ),
                ),
                if (screenWidth > 1024) ...[
                  Expanded(
                    child: Text(
                      'Services',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: headerFontSize,
                      ),
                    ),
                  ),
                ],
                SizedBox(
                  width: screenWidth < 1024 ? 80 : 100,
                  child: Text(
                    'Actions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: headerFontSize,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Facility rows
          ...facilities.map((facility) => _buildAdaptiveTabletFacilityRow(context, facility, provider, screenWidth)),
        ],
      ),
    );
  }

  Widget _buildAdaptiveTabletFacilityRow(BuildContext context, Facility facility, FacilityProvider provider, double screenWidth) {
    final isSelected = _selectedFacilities.contains(facility.facilityId);
    
    // Adaptive measurements
    final rowPadding = screenWidth < 1024 ? 12.0 : 16.0;
    final fontSize = screenWidth < 1024 ? 13.0 : 14.0;
    final iconSize = screenWidth < 1024 ? 18.0 : 20.0;
    
    return Container(
      padding: EdgeInsets.all(rowPadding),
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
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: fontSize,
                  ),
                ),
                SizedBox(height: screenWidth * 0.002),
                Text(
                  facility.address,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: fontSize - 1,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              facility.typeDisplayName,
              style: TextStyle(fontSize: fontSize),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth < 1024 ? 6.0 : 8.0,
                vertical: screenWidth < 1024 ? 2.0 : 4.0,
              ),
              decoration: BoxDecoration(
                color: facility.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(screenWidth < 1024 ? 8.0 : 12.0),
              ),
              child: Text(
                facility.statusDisplayName,
                style: TextStyle(
                  color: facility.isActive ? Colors.green : Colors.red,
                  fontSize: screenWidth < 1024 ? 10.0 : 12.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${facility.totalPersonnel}',
              style: TextStyle(fontSize: fontSize),
            ),
          ),
          if (screenWidth > 1024) ...[
            Expanded(
              child: Text(
                facility.servicesDisplayText,
                style: TextStyle(
                  fontSize: fontSize - 1,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          SizedBox(
            width: screenWidth < 1024 ? 80 : 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, size: iconSize),
                  onPressed: () => context.push('/facilities/edit/${facility.facilityId}'),
                  tooltip: 'Edit facility',
                ),
                IconButton(
                  icon: Icon(Icons.delete, size: iconSize, color: Colors.red),
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
    return Column(
      children: [
        ...facilities.map((facility) => _buildMobileFacilityCard(context, facility, provider)),
        // Add bottom padding to account for floating action button
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildMobileFacilityCard(BuildContext context, Facility facility, FacilityProvider provider) {
    final isSelected = _selectedFacilities.contains(facility.facilityId);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    
    // Adaptive measurements
    final cardPadding = screenWidth < 480 ? 12.0 :
                       screenWidth < 600 ? 14.0 : 16.0;
    
    final borderRadius = screenWidth < 480 ? 8.0 :
                        screenWidth < 600 ? 10.0 : 12.0;
    
    final titleFontSize = screenWidth < 480 ? 14.0 :
                         screenWidth < 600 ? 15.0 : 16.0;
    
    final bodyFontSize = screenWidth < 480 ? 12.0 :
                        screenWidth < 600 ? 13.0 : 14.0;
    
    final iconSize = screenWidth < 480 ? 14.0 :
                    screenWidth < 600 ? 15.0 : 16.0;
    
    final spacing = screenWidth < 480 ? 6.0 :
                   screenWidth < 600 ? 7.0 : 8.0;
    
    return Card(
      margin: EdgeInsets.only(bottom: screenWidth < 480 ? 8.0 : 12.0),
      elevation: screenWidth < 480 ? 1.0 : 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
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
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                : null,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      facility.name,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth < 480 ? 6.0 : 8.0,
                      vertical: screenWidth < 480 ? 2.0 : 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: facility.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(screenWidth < 480 ? 8.0 : 12.0),
                    ),
                    child: Text(
                      facility.statusDisplayName,
                      style: TextStyle(
                        color: facility.isActive ? Colors.green : Colors.red,
                        fontSize: screenWidth < 480 ? 10.0 : 12.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: iconSize,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  SizedBox(width: spacing * 0.5),
                  Expanded(
                    child: Text(
                      facility.address,
                      style: TextStyle(
                        fontSize: bodyFontSize,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth < 480 ? 6.0 : 8.0,
                      vertical: screenWidth < 480 ? 2.0 : 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(screenWidth < 480 ? 6.0 : 8.0),
                    ),
                    child: Text(
                      facility.typeDisplayName,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: screenWidth < 480 ? 10.0 : 12.0,
                      ),
                    ),
                  ),
                  SizedBox(width: spacing),
                  Icon(
                    Icons.people,
                    size: iconSize,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  SizedBox(width: spacing * 0.5),
                  Text(
                    '${facility.totalPersonnel} staff',
                    style: TextStyle(
                      fontSize: bodyFontSize,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing),
              Text(
                facility.servicesDisplayText,
                style: TextStyle(
                  fontSize: bodyFontSize,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: spacing * 1.5),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => context.push('/facilities/edit/${facility.facilityId}'),
                    icon: Icon(Icons.edit, size: iconSize),
                    label: Text(
                      'Edit',
                      style: TextStyle(fontSize: bodyFontSize),
                    ),
                  ),
                  SizedBox(width: spacing),
                  TextButton.icon(
                    onPressed: () => _showDeleteFacilityDialog(context, facility, provider),
                    icon: Icon(Icons.delete, size: iconSize, color: Colors.red),
                    label: Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: bodyFontSize,
                      ),
                    ),
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