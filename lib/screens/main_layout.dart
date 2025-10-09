// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../services/auth_provider.dart';
import '../utils/responsive_helper.dart';
import '../theme/theme.dart';

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: _buildAppBar(context, authProvider),
      drawer: isDesktop ? null : _buildDrawer(context, authProvider),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(context, authProvider),
          Expanded(
            child: Container(
              color: CHWTheme.backgroundColor,
              padding: EdgeInsets.all(
                ResponsiveHelper.isMobile(context) ? 16 : 24,
              ),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return AppBar(
      elevation: 0,
      backgroundColor: CHWTheme.primaryColor,
      foregroundColor: Colors.white,
      title: Row(
        children: [
          if (isDesktop) ...[
            const Icon(Icons.health_and_safety),
            const SizedBox(width: 12),
          ],
          Text(
            isDesktop ? AppConstants.appName : 'CHW Admin',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        if (isDesktop) ...[
          _buildUserProfileDropdown(context, authProvider),
          const SizedBox(width: 16),
        ],
      ],
    );
  }

  Widget _buildUserProfileDropdown(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    return PopupMenuButton<String>(
      icon: CircleAvatar(
        backgroundColor: Colors.white.withOpacity(0.2),
        child: Text(
          authProvider.currentUser?.name.substring(0, 1).toUpperCase() ?? 'U',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onSelected: (value) {
        switch (value) {
          case 'profile':
            _showProfileDialog(context, authProvider);
            break;
          case 'settings':
            context.goNamed('settings');
            break;
          case 'logout':
            _handleLogout(context, authProvider);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.person),
              const SizedBox(width: 8),
              Text(authProvider.currentUser?.name ?? 'User'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings),
              SizedBox(width: 8),
              Text('Settings'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 8),
              Text('Logout', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar(BuildContext context, AuthProvider authProvider) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSidebarHeader(authProvider),
          Expanded(child: _buildNavigationMenu(context)),
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    return Drawer(
      child: Column(
        children: [
          _buildSidebarHeader(authProvider),
          Expanded(child: _buildNavigationMenu(context)),
          _buildDrawerLogout(context, authProvider),
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildDrawerLogout(BuildContext context, AuthProvider authProvider) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: const Icon(
          Icons.logout,
          color: Colors.red,
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: () {
          Navigator.of(context).pop(); // Close drawer first
          _handleLogout(context, authProvider);
        },
      ),
    );
  }

  Widget _buildSidebarHeader(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: CHWTheme.primaryColor),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              authProvider.currentUser?.name.substring(0, 1).toUpperCase() ??
                  'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            authProvider.currentUser?.name ?? 'User',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            UserRoles.getDisplayName(authProvider.currentUser?.role ?? ''),
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationMenu(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.currentUser?.role;

    // Filter menu items based on user role
    final allMenuItems = [
      NavigationItem(
        icon: Icons.dashboard,
        label: 'Dashboard',
        route: AppConstants.dashboardRoute,
        requiredRole: null, // Available to all roles
      ),
      NavigationItem(
        icon: Icons.people,
        label: 'User Management',
        route: AppConstants.usersRoute,
        requiredRole: AppConstants.adminRole, // Admin only
      ),
      NavigationItem(
        icon: Icons.business,
        label: 'Facilities',
        route: AppConstants.facilitiesRoute,
        requiredRole: AppConstants.adminRole, // Admin only
      ),
      NavigationItem(
        icon: Icons.history,
        label: 'Audit Logs',
        route: AppConstants.auditLogsRoute,
        requiredRole: AppConstants.adminRole, // Admin only
      ),
      NavigationItem(
        icon: Icons.settings,
        label: 'Settings',
        route: AppConstants.settingsRoute,
        requiredRole: null, // Available to all roles
      ),
    ];

    // Filter menu items based on user role
    final menuItems = allMenuItems.where((item) {
      if (item.requiredRole == null) return true;
      return userRole == item.requiredRole;
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        final isSelected = currentLocation.startsWith(item.route);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: ListTile(
            leading: Icon(
              item.icon,
              color: isSelected ? CHWTheme.primaryColor : Colors.grey[600],
            ),
            title: Text(
              item.label,
              style: TextStyle(
                color: isSelected ? CHWTheme.primaryColor : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            selectedTileColor: CHWTheme.primaryColor.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onTap: () {
              context.go(item.route);
              if (!ResponsiveHelper.isDesktop(context)) {
                Navigator.of(context).pop();
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(
            '${AppConstants.appName} v${AppConstants.appVersion}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileRow('Name', authProvider.currentUser?.name ?? ''),
            _buildProfileRow('Email', authProvider.currentUser?.email ?? ''),
            _buildProfileRow(
              'Role',
              UserRoles.getDisplayName(authProvider.currentUser?.role ?? ''),
            ),
            _buildProfileRow('Phone', authProvider.currentUser?.phone ?? ''),
          ],
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

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value.isNotEmpty ? value : 'Not provided')),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await authProvider.signOut();
              if (context.mounted) {
                context.goNamed('login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;
  final String? requiredRole;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
    this.requiredRole,
  });
}
