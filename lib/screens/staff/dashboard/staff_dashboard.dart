import 'package:flutter/material.dart';

class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    
    // Responsive breakpoints
    final isMobile = screenWidth < 600;
    final titleFontSize = isMobile ? 24.0 : 32.0;
    final subtitleFontSize = isMobile ? 14.0 : 16.0;
    final cardPadding = isMobile ? 16.0 : 24.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(cardPadding),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.dashboard,
                        color: Theme.of(context).colorScheme.primary,
                        size: titleFontSize,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Staff Dashboard',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'TB Management System',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontSize: subtitleFontSize,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Quick Stats Grid
                Expanded(
                  child: GridView.count(
                    crossAxisCount: isMobile ? 2 : 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildStatsCard(
                        context,
                        'Active Patients',
                        '127',
                        Icons.people,
                        Colors.blue,
                        cardPadding,
                      ),
                      _buildStatsCard(
                        context,
                        'Pending Referrals',
                        '23',
                        Icons.assignment,
                        Colors.orange,
                        cardPadding,
                      ),
                      _buildStatsCard(
                        context,
                        'Follow-ups Today',
                        '18',
                        Icons.event,
                        Colors.green,
                        cardPadding,
                      ),
                      _buildStatsCard(
                        context,
                        'Alerts',
                        '5',
                        Icons.warning,
                        Colors.red,
                        cardPadding,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    double padding,
  ) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}