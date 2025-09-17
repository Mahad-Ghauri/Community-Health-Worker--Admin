// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import '../../providers/audit_log_provider.dart';
import '../../models/audit_log.dart';
import '../../widgets/common_widgets.dart' as common;

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AuditLogProvider>(context, listen: false);
      provider.loadAuditLogs(refresh: true);
      provider.loadStatistics();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      final provider = Provider.of<AuditLogProvider>(context, listen: false);
      provider.loadMoreAuditLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Consumer<AuditLogProvider>(
        builder: (context, auditLogProvider, child) {
          // DEBUG: Print audit log provider state
         
          return Column(
            children: [
              _buildHeader(context, auditLogProvider),
              _buildStatisticsCards(context, auditLogProvider),
              _buildFiltersBar(context, auditLogProvider),
              Flexible(
                child: _buildAuditLogsList(context, auditLogProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuditLogProvider provider) {
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
    
    // Capped spacing to prevent excessive height
    final titleSpacing = (screenWidth * 0.01).clamp(4.0, 8.0);
    final sectionSpacing = (screenWidth * 0.04).clamp(16.0, 32.0);
    final buttonSpacing = (screenWidth * 0.02).clamp(8.0, 16.0);

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
              'Audit Logs',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: titleSpacing),
            Text(
              'Track all system activities and user actions',
              style: TextStyle(
                fontSize: subtitleFontSize,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            SizedBox(height: sectionSpacing),
            // Stack buttons vertically on small screens
            Column(
              children: [
                if (provider.hasActiveFilters) ...[
                  SizedBox(
                    width: double.infinity,
                    height: buttonHeight,
                    child: common.CustomButton(
                      text: 'Clear Filters',
                      onPressed: () {
                        _searchController.clear();
                        provider.clearFilters();
                      },
                      isSecondary: true,
                    ),
                  ),
                  SizedBox(height: buttonSpacing),
                ],
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: buttonHeight,
                        child: common.CustomButton(
                          text: 'Export',
                          onPressed: () => _showExportDialog(context, provider),
                        ),
                      ),
                    ),
                    SizedBox(width: buttonSpacing),
                    SizedBox(
                      height: buttonHeight,
                      width: buttonHeight,
                      child: IconButton(
                        onPressed: provider.refresh,
                        icon: Icon(
                          Icons.refresh,
                          color: Theme.of(context).colorScheme.primary,
                          size: screenWidth < 480 ? 18.0 : 20.0,
                        ),
                        tooltip: 'Refresh',
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          foregroundColor: Theme.of(context).colorScheme.onSurface,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
                  'Audit Logs',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: titleSpacing / 2),
                Text(
                  'Track all system activities and user actions',
                  style: TextStyle(
                    fontSize: subtitleFontSize,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (provider.hasActiveFilters) ...[
                SizedBox(
                  height: buttonHeight,
                  child: common.CustomButton(
                    text: isCompact ? 'Clear' : 'Clear Filters',
                    onPressed: () {
                      _searchController.clear();
                      provider.clearFilters();
                    },
                    isSecondary: true,
                  ),
                ),
                SizedBox(width: buttonSpacing),
              ],
              SizedBox(
                height: buttonHeight,
                child: common.CustomButton(
                  text: 'Export',
                  onPressed: () => _showExportDialog(context, provider),
                ),
              ),
              SizedBox(width: buttonSpacing),
              SizedBox(
                height: buttonHeight,
                width: buttonHeight,
                child: IconButton(
                  onPressed: provider.refresh,
                  icon: Icon(
                    Icons.refresh,
                    color: Theme.of(context).colorScheme.primary,
                    size: screenWidth < 768 ? 18.0 : 20.0,
                  ),
                  tooltip: 'Refresh',
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(BuildContext context, AuditLogProvider provider) {
    final stats = provider.statistics;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    
    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }
    
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
      columns = 4;
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
              'title': 'Total Logs',
              'value': stats['totalLogs']?.toString() ?? '0',
              'icon': Icons.list_alt,
              'color': Theme.of(context).colorScheme.primary,
            },
            {
              'title': 'High Severity',
              'value': stats['severityBreakdown']?['high']?.toString() ?? '0',
              'icon': Icons.warning,
              'color': Colors.red,
            },
            {
              'title': 'Users Active',
              'value': (stats['userBreakdown'] as Map?)?.length.toString() ?? '0',
              'icon': Icons.people,
              'color': Colors.green,
            },
            {
              'title': 'Today\'s Activity',
              'value': _getTodayActivity(stats).toString(),
              'icon': Icons.today,
              'color': Colors.blue,
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

  Widget _buildFiltersBar(BuildContext context, AuditLogProvider provider) {
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

  Widget _buildVerticalFilters(BuildContext context, AuditLogProvider provider, double screenWidth) {
    final spacing = (screenWidth * 0.025).clamp(12.0, 20.0);
    
    return Column(
      children: [
        _buildAdaptiveSearchField(context, provider, screenWidth),
        SizedBox(height: spacing),
        _buildAdaptiveActionFilter(context, provider, screenWidth),
        SizedBox(height: spacing),
        _buildAdaptiveEntityFilter(context, provider, screenWidth),
        SizedBox(height: spacing),
        SizedBox(
          width: double.infinity,
          child: _buildDateRangeButton(context, provider, screenWidth),
        ),
        if (provider.hasActiveFilters) ...[
          SizedBox(height: spacing),
          _buildActiveFiltersIndicator(context, provider, screenWidth),
        ],
      ],
    );
  }

  Widget _buildMixedFilters(BuildContext context, AuditLogProvider provider, double screenWidth) {
    final spacing = (screenWidth * 0.02).clamp(8.0, 16.0);
    
    return Column(
      children: [
        _buildAdaptiveSearchField(context, provider, screenWidth),
        SizedBox(height: spacing),
        Row(
          children: [
            Expanded(child: _buildAdaptiveActionFilter(context, provider, screenWidth)),
            SizedBox(width: spacing),
            Expanded(child: _buildAdaptiveEntityFilter(context, provider, screenWidth)),
          ],
        ),
        SizedBox(height: spacing),
        Row(
          children: [
            Expanded(child: _buildDateRangeButton(context, provider, screenWidth)),
          ],
        ),
        if (provider.hasActiveFilters) ...[
          SizedBox(height: spacing),
          _buildActiveFiltersIndicator(context, provider, screenWidth),
        ],
      ],
    );
  }

  Widget _buildHorizontalFilters(BuildContext context, AuditLogProvider provider, double screenWidth, int rows) {
    final spacing = (screenWidth * 0.015).clamp(6.0, 12.0);
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 2, child: _buildAdaptiveSearchField(context, provider, screenWidth)),
            SizedBox(width: spacing),
            Expanded(child: _buildAdaptiveActionFilter(context, provider, screenWidth)),
          ],
        ),
        SizedBox(height: spacing),
        Row(
          children: [
            Expanded(child: _buildAdaptiveEntityFilter(context, provider, screenWidth)),
            SizedBox(width: spacing),
            Expanded(child: _buildDateRangeButton(context, provider, screenWidth)),
          ],
        ),
        if (provider.hasActiveFilters) ...[
          SizedBox(height: spacing),
          _buildActiveFiltersIndicator(context, provider, screenWidth),
        ],
      ],
    );
  }

  Widget _buildFullHorizontalFilters(BuildContext context, AuditLogProvider provider, double screenWidth) {
    final spacing = screenWidth < 1200 ? 16.0 : 
                   screenWidth < 1600 ? 20.0 : 24.0;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 2, child: _buildAdaptiveSearchField(context, provider, screenWidth)),
            SizedBox(width: spacing),
            Expanded(child: _buildAdaptiveActionFilter(context, provider, screenWidth)),
            SizedBox(width: spacing),
            Expanded(child: _buildAdaptiveEntityFilter(context, provider, screenWidth)),
            SizedBox(width: spacing),
            _buildDateRangeButton(context, provider, screenWidth),
          ],
        ),
        if (provider.hasActiveFilters) ...[
          SizedBox(height: spacing * 0.75),
          _buildActiveFiltersIndicator(context, provider, screenWidth),
        ],
      ],
    );
  }

  Widget _buildAdaptiveSearchField(BuildContext context, AuditLogProvider provider, double screenWidth) {
    return common.CustomTextField(
      label: 'Search',
      hint: screenWidth < 480 ? 'Search...' : 
            screenWidth < 768 ? 'Search logs...' : 
            'Search audit logs...',
      controller: _searchController,
      prefixIcon: Icon(
        Icons.search,
        size: screenWidth < 480 ? 18.0 : 20.0,
      ),
      onChanged: provider.searchAuditLogs,
    );
  }

  Widget _buildAdaptiveActionFilter(BuildContext context, AuditLogProvider provider, double screenWidth) {
    return _buildAdaptiveDropdown(
      context: context,
      label: 'Action',
      value: provider.actionFilter.isEmpty ? 'All Actions' : provider.actionFilter,
      items: AuditLogProvider.actionFilterOptions,
      onChanged: (value) => provider.filterByAction(value ?? ''),
      screenWidth: screenWidth,
    );
  }

  Widget _buildAdaptiveEntityFilter(BuildContext context, AuditLogProvider provider, double screenWidth) {
    return _buildAdaptiveDropdown(
      context: context,
      label: 'Entity',
      value: provider.entityFilter.isEmpty ? 'All Entities' : provider.entityFilter,
      items: AuditLogProvider.entityFilterOptions,
      onChanged: (value) => provider.filterByEntity(value ?? ''),
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

  Widget _buildDateRangeButton(BuildContext context, AuditLogProvider provider, double screenWidth) {
    final buttonHeight = screenWidth < 480 ? 52.0 :
                        screenWidth < 768 ? 56.0 :
                        screenWidth < 1024 ? 60.0 : 64.0;
    
    final fontSize = screenWidth < 480 ? 13.0 :
                    screenWidth < 768 ? 14.0 :
                    screenWidth < 1024 ? 15.0 : 16.0;
    
    final borderRadius = screenWidth < 600 ? 8.0 :
                        screenWidth < 1024 ? 12.0 : 16.0;

    return SizedBox(
      height: buttonHeight,
      child: OutlinedButton.icon(
        onPressed: () => _showDateRangePicker(context, provider),
        icon: Icon(
          Icons.date_range,
          size: screenWidth < 480 ? 18.0 : 20.0,
        ),
        label: Text(
          provider.startDate != null || provider.endDate != null
              ? (screenWidth < 600 ? 'Date Set' : 'Date Range Set')
              : (screenWidth < 600 ? 'Date' : 'Date Range'),
          style: TextStyle(fontSize: fontSize),
        ),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth < 480 ? 12.0 : 16.0,
            vertical: screenWidth < 480 ? 12.0 : 16.0,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFiltersIndicator(BuildContext context, AuditLogProvider provider, double screenWidth) {
    final fontSize = screenWidth < 480 ? 11.0 :
                    screenWidth < 768 ? 12.0 : 13.0;
    
    final iconSize = screenWidth < 480 ? 14.0 :
                    screenWidth < 768 ? 16.0 : 18.0;
    
    final padding = screenWidth < 480 ? 8.0 :
                   screenWidth < 768 ? 10.0 : 12.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(screenWidth < 600 ? 6.0 : 8.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            size: iconSize,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: screenWidth * 0.01),
          Expanded(
            child: Text(
              screenWidth < 600 
                  ? 'Filters: ${provider.filtersDescription}'
                  : 'Active filters: ${provider.filtersDescription}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: fontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogsList(BuildContext context, AuditLogProvider provider) {
    // DEBUG: Print audit log list state
    print('[DEBUG] _buildAuditLogsList: isLoading=${provider.isLoading}, error=${provider.error}, auditLogs.length=${provider.auditLogs.length}');
    if (provider.isLoading && provider.auditLogs.isEmpty) {
      print('[DEBUG] Showing loading widget');
      return const Center(child: common.LoadingWidget());
    }

    if (provider.error != null) {
      print('[DEBUG] Showing error widget: ${provider.error}');
      return Center(
        child: common.ErrorWidget(
          message: provider.error!,
          onRetry: () {
            provider.clearError();
            provider.loadAuditLogs(refresh: true);
          },
        ),
      );
    }

    final auditLogs = provider.auditLogs;
    print('[DEBUG] auditLogs in _buildAuditLogsList: ${auditLogs.length}');
    if (auditLogs.isEmpty) {
      print('[DEBUG] No audit logs found. Filters: ${provider.filtersDescription}');
      return Container(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                provider.hasActiveFilters
                    ? 'No audit logs found matching your filters'
                    : 'No audit logs found',
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
          ? _buildMobileList(context, auditLogs, provider)
          : _buildTabletList(context, auditLogs, provider),
    );
  }

  Widget _buildTabletList(BuildContext context, List<AuditLog> auditLogs, AuditLogProvider provider) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    
    // Adaptive measurements
    final cardPadding = screenWidth < 1024 ? 12.0 : 16.0;
    final borderRadius = screenWidth < 1024 ? 8.0 : 12.0;
    final headerFontSize = screenWidth < 1024 ? 14.0 : 16.0;
    final fontSize = screenWidth < 1024 ? 13.0 : 14.0;
    final elevation = screenWidth < 1024 ? 1.0 : 2.0;
    
    return ListView.builder(
      controller: _scrollController,
      itemCount: auditLogs.length + 2 + (provider.isLoading ? 1 : 0), // +2 for header and potential loading
      itemBuilder: (context, index) {
        if (index == 0) {
          // Header card
          return Card(
            elevation: elevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Container(
              padding: EdgeInsets.all(cardPadding),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Action',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: headerFontSize,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'User',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: headerFontSize,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Entity',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: headerFontSize,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Time',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: headerFontSize,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Severity',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: headerFontSize,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: screenWidth < 1024 ? 50 : 60,
                    child: Text(
                      'Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: headerFontSize,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (index <= auditLogs.length) {
          // Audit log row
          final auditLog = auditLogs[index - 1];
          return Card(
            elevation: elevation,
            margin: EdgeInsets.only(top: cardPadding / 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: _buildAdaptiveTabletAuditLogRow(context, auditLog, screenWidth, fontSize),
          );
        } else {
          // Loading indicator
          return Padding(
            padding: EdgeInsets.all(cardPadding),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }

  Widget _buildAdaptiveTabletAuditLogRow(BuildContext context, AuditLog auditLog, double screenWidth, double fontSize) {
    final rowPadding = screenWidth < 1024 ? 12.0 : 16.0;
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
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auditLog.actionDisplayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: fontSize,
                  ),
                ),
                if (auditLog.description != null)
                  Text(
                    auditLog.description!,
                    style: TextStyle(
                      fontSize: fontSize - 1,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auditLog.userName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: fontSize,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth < 1024 ? 4.0 : 6.0,
                    vertical: screenWidth < 1024 ? 1.0 : 2.0,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(screenWidth < 1024 ? 6.0 : 8.0),
                  ),
                  child: Text(
                    auditLog.userRole,
                    style: TextStyle(
                      fontSize: screenWidth < 1024 ? 9.0 : 10.0,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              auditLog.entityDisplayName,
              style: TextStyle(fontSize: fontSize),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auditLog.formattedTime,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: fontSize,
                  ),
                ),
                Text(
                  auditLog.timeAgo,
                  style: TextStyle(
                    fontSize: fontSize - 1,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth < 1024 ? 6.0 : 8.0,
                vertical: screenWidth < 1024 ? 2.0 : 4.0,
              ),
              decoration: BoxDecoration(
                color: _getSeverityColor(auditLog.severity).withOpacity(0.1),
                borderRadius: BorderRadius.circular(screenWidth < 1024 ? 8.0 : 12.0),
              ),
              child: Text(
                auditLog.severity.name.toUpperCase(),
                style: TextStyle(
                  color: _getSeverityColor(auditLog.severity),
                  fontSize: screenWidth < 1024 ? 9.0 : 10.0,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: screenWidth < 1024 ? 50 : 60,
            child: IconButton(
              icon: Icon(Icons.info_outline, size: iconSize),
              onPressed: () => _showAuditLogDetails(context, auditLog),
              tooltip: 'View details',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, List<AuditLog> auditLogs, AuditLogProvider provider) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    
    // Adaptive spacing and sizing
    final cardSpacing = screenWidth < 480 ? 8.0 : 12.0;
    final cardPadding = screenWidth < 480 ? 12.0 : 16.0;
    final borderRadius = screenWidth < 480 ? 8.0 : 12.0;
    final titleFontSize = screenWidth < 480 ? 14.0 : 16.0;
    final bodyFontSize = screenWidth < 480 ? 12.0 : 14.0;
    final smallFontSize = screenWidth < 480 ? 10.0 : 12.0;
    final avatarRadius = screenWidth < 480 ? 16.0 : 20.0;
    final iconSize = screenWidth < 480 ? 18.0 : 20.0;
    
    return ListView.separated(
      controller: _scrollController,
      itemCount: auditLogs.length + (provider.isLoading ? 1 : 0),
      separatorBuilder: (context, index) => SizedBox(height: cardSpacing),
      itemBuilder: (context, index) {
        if (index >= auditLogs.length) {
          return Padding(
            padding: EdgeInsets.all(cardPadding),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final auditLog = auditLogs[index];
        return Card(
          elevation: screenWidth < 480 ? 1.0 : 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: () => _showAuditLogDetails(context, auditLog),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: avatarRadius,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Icon(
                          _getActionIcon(auditLog.action),
                          size: iconSize,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(width: cardPadding),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auditLog.actionDisplayName,
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (auditLog.description != null) ...[
                              SizedBox(height: cardSpacing / 2),
                              Text(
                                auditLog.description!,
                                style: TextStyle(
                                  fontSize: bodyFontSize,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Severity badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth < 480 ? 6.0 : 8.0,
                          vertical: screenWidth < 480 ? 2.0 : 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(auditLog.severity).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(borderRadius / 2),
                        ),
                        child: Text(
                          auditLog.severity.name.toUpperCase(),
                          style: TextStyle(
                            color: _getSeverityColor(auditLog.severity),
                            fontSize: screenWidth < 480 ? 8.0 : 10.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: cardSpacing),
                  
                  // User Information
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: iconSize,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      SizedBox(width: cardSpacing),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auditLog.userName,
                              style: TextStyle(
                                fontSize: bodyFontSize,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: cardSpacing / 2),
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth < 480 ? 4.0 : 6.0,
                                vertical: screenWidth < 480 ? 1.0 : 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(borderRadius / 2),
                              ),
                              child: Text(
                                auditLog.userRole,
                                style: TextStyle(
                                  fontSize: smallFontSize,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: cardSpacing),
                  
                  // Entity and Time Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.account_tree_outlined,
                                  size: iconSize,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                                SizedBox(width: cardSpacing),
                                Text(
                                  'Entity',
                                  style: TextStyle(
                                    fontSize: smallFontSize,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: iconSize + cardSpacing),
                              child: Text(
                                auditLog.entityDisplayName,
                                style: TextStyle(fontSize: bodyFontSize),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: iconSize,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                                SizedBox(width: cardSpacing),
                                Text(
                                  'Time',
                                  style: TextStyle(
                                    fontSize: smallFontSize,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: iconSize + cardSpacing),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    auditLog.formattedTime,
                                    style: TextStyle(
                                      fontSize: bodyFontSize,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    auditLog.timeAgo,
                                    style: TextStyle(
                                      fontSize: smallFontSize,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'create':
        return Icons.add_circle;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'view':
        return Icons.visibility;
      case 'export':
        return Icons.download;
      case 'import':
        return Icons.upload;
      default:
        return Icons.info;
    }
  }

  Color _getSeverityColor(AuditLogSeverity severity) {
    switch (severity) {
      case AuditLogSeverity.low:
        return Colors.green;
      case AuditLogSeverity.medium:
        return Colors.orange;
      case AuditLogSeverity.high:
        return Colors.red;
    }
  }

  void _showAuditLogDetails(BuildContext context, AuditLog auditLog) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Audit Log Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Action', auditLog.actionDisplayName),
              _buildDetailRow('Entity', auditLog.entityDisplayName),
              _buildDetailRow('User', '${auditLog.userName} (${auditLog.userRole})'),
              _buildDetailRow('Date/Time', auditLog.formattedDateTime),
              _buildDetailRow('Severity', auditLog.severity.name.toUpperCase()),
              if (auditLog.description != null)
                _buildDetailRow('Description', auditLog.description!),
              if (auditLog.ipAddress != null)
                _buildDetailRow('IP Address', auditLog.ipAddress!),
              if (auditLog.hasDataChanges) ...[
                const SizedBox(height: 16),
                Text(
                  'Data Changes:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...auditLog.dataChanges.map((change) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${change.fieldDisplayName}: ${change.changeDescription}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showDateRangePicker(BuildContext context, AuditLogProvider provider) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: provider.startDate != null && provider.endDate != null
          ? DateTimeRange(start: provider.startDate!, end: provider.endDate!)
          : null,
    );

    if (picked != null) {
      provider.filterByDateRange(picked.start, picked.end);
    }
  }

  void _showExportDialog(BuildContext context, AuditLogProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Audit Logs'),
        content: const Text('This feature will export the current audit logs to a CSV file.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final csvData = await provider.exportAuditLogs();
                _downloadCsv(csvData, 'audit_logs_${DateTime.now().millisecondsSinceEpoch}.csv');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Audit logs exported successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to export audit logs: $e')),
                  );
                }
              }
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  int _getTodayActivity(Map<String, dynamic> stats) {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return (stats['dailyActivity'] as Map?)?[todayKey] ?? 0;
  }

  void _downloadCsv(String csvData, String filename) {
    if (kIsWeb) {
      // Web download
      final bytes = utf8.encode(csvData);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = filename;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } else {
      // For mobile/desktop, you would typically use path_provider and file system
      // For now, we'll just show the CSV data in a dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('CSV Export'),
          content: SingleChildScrollView(
            child: SelectableText(
              csvData,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}