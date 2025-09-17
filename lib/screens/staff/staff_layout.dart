// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_constants.dart';

class StaffLayout extends StatefulWidget {
  final Widget child;
  
  const StaffLayout({
    super.key,
    required this.child,
  });

  @override
  State<StaffLayout> createState() => _StaffLayoutState();
}

class _StaffLayoutState extends State<StaffLayout> {
  int _selectedIndex = 0;

  final List<StaffNavigationItem> _navigationItems = [
    StaffNavigationItem(
      id: 'dashboard',
      label: 'Dashboard',
      icon: Icons.dashboard,
      route: AppConstants.staffDashboardRoute,
    ),
    StaffNavigationItem(
      id: 'assign_patients',
      label: 'Assign Patients',
      icon: Icons.person_add,
      route: AppConstants.assignPatientsRoute,
    ),
    StaffNavigationItem(
      id: 'facility_patients',
      label: 'Facility Patients',
      icon: Icons.people,
      route: AppConstants.facilityPatientsRoute,
    ),
    StaffNavigationItem(
      id: 'referrals',
      label: 'Referrals',
      icon: Icons.assignment,
      route: AppConstants.referralsRoute,
    ),
    StaffNavigationItem(
      id: 'create_followups',
      label: 'Schedule Follow-ups',
      icon: Icons.event_available,
      route: AppConstants.createFollowupsRoute,
    ),
    StaffNavigationItem(
      id: 'manage_followups',
      label: 'Manage Follow-ups',
      icon: Icons.event,
      route: AppConstants.manageFollowupsRoute,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    
    // Responsive breakpoints
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    if (isMobile) {
      return _buildMobileLayout();
    } else if (isTablet) {
      return _buildTabletLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  Widget _buildMobileLayout() {
    // Bottom navigation for mobile
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onNavigationTap,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          BottomNavigationBarItem(
            icon: Icon(_navigationItems[0].icon),
            label: _navigationItems[0].label,
          ),
          BottomNavigationBarItem(
            icon: Icon(_navigationItems[2].icon),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(_navigationItems[3].icon),
            label: _navigationItems[3].label,
          ),
          BottomNavigationBarItem(
            icon: Icon(_navigationItems[5].icon),
            label: 'Follow-ups',
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    // Side navigation rail for tablet
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onNavigationTap,
            labelType: NavigationRailLabelType.selected,
            backgroundColor: Theme.of(context).colorScheme.surface,
            destinations: _navigationItems.map((item) => NavigationRailDestination(
              icon: Icon(item.icon),
              label: Text(item.label),
            )).toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    // Side navigation drawer for desktop
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 250,
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_hospital,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'TB Staff Portal',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Navigation items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _navigationItems.length,
                    itemBuilder: (context, index) {
                      final item = _navigationItems[index];
                      final isSelected = index == _selectedIndex;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: ListTile(
                          leading: Icon(
                            item.icon,
                            color: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              color: isSelected 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onTap: () => _onNavigationTap(index),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  void _onNavigationTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Navigate to the selected route
    final route = _navigationItems[index].route;
    if (mounted) {
      context.go(route);
    }
  }
}

class StaffNavigationItem {
  final String id;
  final String label;
  final IconData icon;
  final String route;

  const StaffNavigationItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
  });
}