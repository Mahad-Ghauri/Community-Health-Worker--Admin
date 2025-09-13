import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/audit_log_provider.dart';
import '../../models/audit_log.dart';
import '../../widgets/common_widgets.dart' as common;
import '../../utils/responsive_helper.dart';

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
          return Column(
            children: [
              _buildHeader(context, auditLogProvider),
              _buildStatisticsCards(context, auditLogProvider),
              _buildFiltersBar(context, auditLogProvider),
              Expanded(
                child: _buildAuditLogsList(context, auditLogProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuditLogProvider provider) {
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
                  'Audit Logs',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track all system activities and user actions',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (provider.hasActiveFilters) ...[
                common.CustomButton(
                  text: 'Clear Filters',
                  onPressed: () {
                    _searchController.clear();
                    provider.clearFilters();
                  },
                  isSecondary: true,
                ),
                const SizedBox(width: 16),
              ],
              common.CustomButton(
                text: 'Export',
                onPressed: () => _showExportDialog(context, provider),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: provider.refresh,
                icon: Icon(
                  Icons.refresh,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(BuildContext context, AuditLogProvider provider) {
    final stats = provider.statistics;
    final isTablet = ResponsiveHelper.isTablet(context);
    
    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: isTablet ? 4 : 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: isTablet ? 2.5 : 2.0,
        children: [
          _buildStatCard(
            context,
            'Total Logs',
            stats['totalLogs']?.toString() ?? '0',
            Icons.list_alt,
            Theme.of(context).colorScheme.primary,
          ),
          _buildStatCard(
            context,
            'High Severity',
            stats['severityBreakdown']?['high']?.toString() ?? '0',
            Icons.warning,
            Colors.red,
          ),
          _buildStatCard(
            context,
            'Users Active',
            (stats['userBreakdown'] as Map?)?.length.toString() ?? '0',
            Icons.people,
            Colors.green,
          ),
          _buildStatCard(
            context,
            'Today\'s Activity',
            _getTodayActivity(stats).toString(),
            Icons.today,
            Colors.blue,
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

  Widget _buildFiltersBar(BuildContext context, AuditLogProvider provider) {
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

  Widget _buildTabletFilters(BuildContext context, AuditLogProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: common.CustomTextField(
                label: 'Search',
                hint: 'Search audit logs...',
                controller: _searchController,
                prefixIcon: const Icon(Icons.search),
                onChanged: provider.searchAuditLogs,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: provider.actionFilter.isEmpty ? 'All Actions' : provider.actionFilter,
                decoration: const InputDecoration(
                  labelText: 'Action',
                  border: OutlineInputBorder(),
                ),
                items: AuditLogProvider.actionFilterOptions.map((action) {
                  return DropdownMenuItem(value: action, child: Text(action));
                }).toList(),
                onChanged: (value) => provider.filterByAction(value ?? ''),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: provider.entityFilter.isEmpty ? 'All Entities' : provider.entityFilter,
                decoration: const InputDecoration(
                  labelText: 'Entity',
                  border: OutlineInputBorder(),
                ),
                items: AuditLogProvider.entityFilterOptions.map((entity) {
                  return DropdownMenuItem(value: entity, child: Text(entity));
                }).toList(),
                onChanged: (value) => provider.filterByEntity(value ?? ''),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: () => _showDateRangePicker(context, provider),
              icon: const Icon(Icons.date_range),
              label: Text(provider.startDate != null || provider.endDate != null
                  ? 'Date Range Set'
                  : 'Date Range'),
            ),
          ],
        ),
        if (provider.hasActiveFilters) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Active filters: ${provider.filtersDescription}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMobileFilters(BuildContext context, AuditLogProvider provider) {
    return Column(
      children: [
        common.CustomTextField(
          label: 'Search',
          hint: 'Search audit logs...',
          controller: _searchController,
          prefixIcon: const Icon(Icons.search),
          onChanged: provider.searchAuditLogs,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: provider.actionFilter.isEmpty ? 'All Actions' : provider.actionFilter,
                decoration: const InputDecoration(
                  labelText: 'Action',
                  border: OutlineInputBorder(),
                ),
                items: AuditLogProvider.actionFilterOptions.map((action) {
                  return DropdownMenuItem(value: action, child: Text(action));
                }).toList(),
                onChanged: (value) => provider.filterByAction(value ?? ''),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: provider.entityFilter.isEmpty ? 'All Entities' : provider.entityFilter,
                decoration: const InputDecoration(
                  labelText: 'Entity',
                  border: OutlineInputBorder(),
                ),
                items: AuditLogProvider.entityFilterOptions.map((entity) {
                  return DropdownMenuItem(value: entity, child: Text(entity));
                }).toList(),
                onChanged: (value) => provider.filterByEntity(value ?? ''),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showDateRangePicker(context, provider),
                icon: const Icon(Icons.date_range),
                label: Text(provider.startDate != null || provider.endDate != null
                    ? 'Date Range Set'
                    : 'Set Date Range'),
              ),
            ),
          ],
        ),
        if (provider.hasActiveFilters) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Filters: ${provider.filtersDescription}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAuditLogsList(BuildContext context, AuditLogProvider provider) {
    if (provider.isLoading && provider.auditLogs.isEmpty) {
      return const Center(child: common.LoadingWidget());
    }

    if (provider.error != null) {
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
    
    if (auditLogs.isEmpty) {
      return Center(
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
      );
    }

    final isTablet = ResponsiveHelper.isTablet(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: isTablet
          ? _buildTabletList(context, auditLogs, provider)
          : _buildMobileList(context, auditLogs, provider),
    );
  }

  Widget _buildTabletList(BuildContext context, List<AuditLog> auditLogs, AuditLogProvider provider) {
    return SingleChildScrollView(
      controller: _scrollController,
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
              child: const Row(
                children: [
                  Expanded(flex: 2, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('User', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Entity', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Time', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Severity', style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 60, child: Text('Details', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            // Audit log rows
            ...auditLogs.map((auditLog) => _buildTabletAuditLogRow(context, auditLog)),
            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletAuditLogRow(BuildContext context, AuditLog auditLog) {
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
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auditLog.actionDisplayName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (auditLog.description != null)
                  Text(
                    auditLog.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    auditLog.userRole,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(auditLog.entityDisplayName),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auditLog.formattedTime,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  auditLog.timeAgo,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getSeverityColor(auditLog.severity).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                auditLog.severity.name.toUpperCase(),
                style: TextStyle(
                  color: _getSeverityColor(auditLog.severity),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showAuditLogDetails(context, auditLog),
              tooltip: 'View details',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, List<AuditLog> auditLogs, AuditLogProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: auditLogs.length + (provider.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == auditLogs.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        final auditLog = auditLogs[index];
        return _buildMobileAuditLogCard(context, auditLog);
      },
    );
  }

  Widget _buildMobileAuditLogCard(BuildContext context, AuditLog auditLog) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showAuditLogDetails(context, auditLog),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      auditLog.actionDisplayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(auditLog.severity).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      auditLog.severity.name.toUpperCase(),
                      style: TextStyle(
                        color: _getSeverityColor(auditLog.severity),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(
                    '${auditLog.userName} (${auditLog.userRole})',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(
                    auditLog.entityDisplayName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(
                    '${auditLog.formattedDateTime} (${auditLog.timeAgo})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              if (auditLog.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  auditLog.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
                await provider.exportAuditLogs();
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
}