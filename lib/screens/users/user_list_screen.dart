import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/user.dart';
import '../../providers/user_provider.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/common_widgets.dart' as common;

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUsers();
      context.read<UserProvider>().loadStatistics();
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildFiltersAndSearch(context),
          const SizedBox(height: 16),
          _buildStatistics(context),
          const SizedBox(height: 16),
          Expanded(
            child: _buildUsersList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
    
    // Adaptive button sizing
    final buttonWidth = isSmallMobile ? 120.0 :
                        isCompact ? 140.0 :
                        screenWidth < 1200 ? 160.0 : 180.0;
    
    if (isSmallMobile) {
      // Stack vertically for very small screens
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Management',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: screenWidth * 0.01),
          Text(
            'Manage system users and their permissions',
            style: TextStyle(
              fontSize: subtitleFontSize,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: screenWidth * 0.04),
          SizedBox(
            width: double.infinity,
            child: common.CustomButton(
              text: 'Create User',
              icon: Icon(Icons.add, size: 16),
              onPressed: () => context.go(AppConstants.createUserRoute),
            ),
          ),
        ],
      );
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User Management',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: screenWidth * 0.005),
              Text(
                'Manage system users and their permissions',
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: screenWidth * 0.02),
        SizedBox(
          width: buttonWidth,
          child: common.CustomButton(
            text: isCompact ? 'Create' : 'Create User',
            icon: Icon(Icons.add, size: isCompact ? 18 : 20),
            onPressed: () => context.go(AppConstants.createUserRoute),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersAndSearch(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        
        return LayoutBuilder(
          builder: (context, constraints) {
            // Determine layout based on available width
            if (screenWidth < 480) {
              return _buildVerticalFiltersLayout(userProvider, screenWidth);
            } else if (screenWidth < 768) {
              return _buildMixedFiltersLayout(userProvider, screenWidth);
            } else if (screenWidth < 1024) {
              return _buildHorizontalFiltersLayout(userProvider, screenWidth, 2);
            } else {
              return _buildFullHorizontalFiltersLayout(userProvider, screenWidth);
            }
          },
        );
      },
    );
  }

  Widget _buildVerticalFiltersLayout(UserProvider userProvider, double screenWidth) {
    final spacing = screenWidth * 0.03;
    
    return Column(
      children: [
        _buildAdaptiveSearchField(userProvider, screenWidth),
        SizedBox(height: spacing),
        _buildAdaptiveRoleFilter(userProvider, screenWidth),
        SizedBox(height: spacing),
        _buildAdaptiveFacilityFilter(userProvider, screenWidth),
        SizedBox(height: spacing),
        SizedBox(
          width: double.infinity,
          child: _buildClearFiltersButton(userProvider, screenWidth),
        ),
      ],
    );
  }

  Widget _buildMixedFiltersLayout(UserProvider userProvider, double screenWidth) {
    final spacing = screenWidth * 0.025;
    
    return Column(
      children: [
        _buildAdaptiveSearchField(userProvider, screenWidth),
        SizedBox(height: spacing),
        Row(
          children: [
            Expanded(child: _buildAdaptiveRoleFilter(userProvider, screenWidth)),
            SizedBox(width: spacing),
            Expanded(child: _buildAdaptiveFacilityFilter(userProvider, screenWidth)),
          ],
        ),
        SizedBox(height: spacing),
        Row(
          children: [
            const Spacer(),
            _buildClearFiltersButton(userProvider, screenWidth),
          ],
        ),
      ],
    );
  }

  Widget _buildHorizontalFiltersLayout(UserProvider userProvider, double screenWidth, int rows) {
    final spacing = screenWidth * 0.02;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 3, child: _buildAdaptiveSearchField(userProvider, screenWidth)),
            SizedBox(width: spacing),
            Expanded(child: _buildAdaptiveRoleFilter(userProvider, screenWidth)),
          ],
        ),
        SizedBox(height: spacing),
        Row(
          children: [
            Expanded(child: _buildAdaptiveFacilityFilter(userProvider, screenWidth)),
            SizedBox(width: spacing),
            _buildClearFiltersButton(userProvider, screenWidth),
          ],
        ),
      ],
    );
  }

  Widget _buildFullHorizontalFiltersLayout(UserProvider userProvider, double screenWidth) {
    final spacing = screenWidth < 1200 ? 16.0 : 
                   screenWidth < 1600 ? 20.0 : 24.0;
    
    return Row(
      children: [
        Expanded(flex: 3, child: _buildAdaptiveSearchField(userProvider, screenWidth)),
        SizedBox(width: spacing),
        Expanded(child: _buildAdaptiveRoleFilter(userProvider, screenWidth)),
        SizedBox(width: spacing),
        Expanded(child: _buildAdaptiveFacilityFilter(userProvider, screenWidth)),
        SizedBox(width: spacing),
        _buildClearFiltersButton(userProvider, screenWidth),
      ],
    );
  }

  Widget _buildAdaptiveSearchField(UserProvider userProvider, double screenWidth) {
    // Dynamic measurements based on screen width
    final height = screenWidth < 480 ? 44.0 :
                  screenWidth < 768 ? 48.0 :
                  screenWidth < 1024 ? 52.0 : 56.0;
    
    final iconSize = screenWidth < 480 ? 18.0 :
                    screenWidth < 768 ? 20.0 :
                    screenWidth < 1024 ? 22.0 : 24.0;
    
    final fontSize = screenWidth < 480 ? 13.0 :
                    screenWidth < 768 ? 14.0 :
                    screenWidth < 1024 ? 15.0 : 16.0;
    
    final borderRadius = screenWidth < 600 ? 8.0 :
                        screenWidth < 1024 ? 12.0 : 16.0;
    
    final horizontalPadding = screenWidth < 480 ? 12.0 :
                             screenWidth < 768 ? 16.0 :
                             screenWidth < 1024 ? 20.0 : 24.0;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.grey[300]!),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: userProvider.searchUsers,
        style: TextStyle(fontSize: fontSize),
        decoration: InputDecoration(
          hintText: screenWidth < 480 ? 'Search...' : 'Search users by name, email, or phone...',
          hintStyle: TextStyle(
            fontSize: fontSize - 1,
            color: Colors.grey[500],
          ),
          prefixIcon: Icon(
            Icons.search,
            size: iconSize,
            color: Colors.grey[500],
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: iconSize),
                  onPressed: () {
                    _searchController.clear();
                    userProvider.searchUsers('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: height * 0.25,
          ),
        ),
      ),
    );
  }

  Widget _buildAdaptiveRoleFilter(UserProvider userProvider, double screenWidth) {
    return _buildAdaptiveDropdown(
      value: userProvider.selectedRole,
      hint: 'Role',
      items: ['All', 'Admin', 'Staff', 'Supervisor'],
      onChanged: (value) => userProvider.filterByRole(value == 'All' ? null : value),
      screenWidth: screenWidth,
    );
  }

  Widget _buildAdaptiveFacilityFilter(UserProvider userProvider, double screenWidth) {
    return _buildAdaptiveDropdown(
      value: userProvider.selectedFacility,
      hint: 'Facility',
      items: ['All', 'Main Hospital', 'Branch Clinic', 'Community Center'],
      onChanged: (value) => userProvider.filterByFacility(value == 'All' ? null : value),
      screenWidth: screenWidth,
    );
  }

  Widget _buildAdaptiveDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
    required double screenWidth,
  }) {
    final height = screenWidth < 480 ? 44.0 :
                  screenWidth < 768 ? 48.0 :
                  screenWidth < 1024 ? 52.0 : 56.0;
    
    final fontSize = screenWidth < 480 ? 13.0 :
                    screenWidth < 768 ? 14.0 :
                    screenWidth < 1024 ? 15.0 : 16.0;
    
    final borderRadius = screenWidth < 600 ? 8.0 :
                        screenWidth < 1024 ? 12.0 : 16.0;
    
    final iconSize = screenWidth < 480 ? 18.0 :
                    screenWidth < 768 ? 20.0 :
                    screenWidth < 1024 ? 22.0 : 24.0;

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: screenWidth < 480 ? 12.0 : 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.grey[300]!),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.grey[500],
            ),
          ),
          icon: Icon(Icons.arrow_drop_down, size: iconSize),
          isExpanded: true,
          style: TextStyle(
            fontSize: fontSize,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildClearFiltersButton(UserProvider userProvider, double screenWidth) {
    final isCompact = screenWidth < 768;
    final buttonWidth = screenWidth < 480 ? double.infinity :
                       screenWidth < 768 ? 120.0 :
                       screenWidth < 1024 ? 140.0 : 160.0;
    
    final widget = common.CustomButton(
      text: isCompact ? 'Clear' : 'Clear Filters',
      isSecondary: true,
      onPressed: () {
        _searchController.clear();
        userProvider.clearFilters();
      },
    );

    return screenWidth < 480 
        ? widget 
        : SizedBox(width: buttonWidth, child: widget);
  }

  Widget _buildSearchField(UserProvider userProvider) {
    final screenWidth = ResponsiveHelper.getScreenWidth(context);
    final isExtraSmall = ResponsiveHelper.isExtraSmall(context);
    final borderRadius = ResponsiveHelper.getResponsiveBorderRadius(context, 12);
    
    // Ultra-adaptive height and padding
    final height = isExtraSmall ? 44.0 : 
                  screenWidth < 600 ? 48.0 : 
                  screenWidth < 1200 ? 52.0 : 56.0;
    
    final iconSize = isExtraSmall ? 18.0 : 
                    screenWidth < 600 ? 20.0 : 
                    screenWidth < 1200 ? 22.0 : 24.0;
    
    return SizedBox(
      height: height,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: _getAdaptiveHintText(screenWidth),
          hintStyle: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            color: Colors.grey[500],
          ),
          prefixIcon: Icon(
            Icons.search,
            size: iconSize,
            color: Colors.grey[600],
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    size: iconSize,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    userProvider.searchUsers('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isExtraSmall ? 12 : screenWidth < 600 ? 16 : 20,
            vertical: isExtraSmall ? 10 : screenWidth < 600 ? 12 : 16,
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        style: TextStyle(
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
        ),
        onChanged: (value) => userProvider.searchUsers(value),
      ),
    );
  }

  String _getAdaptiveHintText(double screenWidth) {
    if (screenWidth < 480) {
      return 'Search users...';
    } else if (screenWidth < 600) {
      return 'Search by name or email...';
    } else if (screenWidth < 900) {
      return 'Search users by name or email...';
    } else {
      return 'Search users by name, email, phone, or role...';
    }
  }

  Widget _buildRoleFilter(UserProvider userProvider) {
    return common.CustomDropdownField<String>(
      label: 'Role',
      hint: 'All Roles',
      value: userProvider.selectedRole,
      items: [
        const DropdownMenuItem(value: null, child: Text('All Roles')),
        ...UserRole.all.map((role) => DropdownMenuItem(
          value: role,
          child: Text(UserRole.getDisplayName(role)),
        )),
      ],
      onChanged: userProvider.filterByRole,
    );
  }

  Widget _buildFacilityFilter(UserProvider userProvider) {
    return common.CustomDropdownField<String>(
      label: 'Facility',
      hint: 'All Facilities',
      value: userProvider.selectedFacility,
      items: const [
        DropdownMenuItem(value: null, child: Text('All Facilities')),
        // TODO: Load from FacilityProvider
      ],
      onChanged: userProvider.filterByFacility,
    );
  }

  Widget _buildStatistics(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final stats = userProvider.statistics;
        if (stats.isEmpty) return const SizedBox.shrink();

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
        } else {
          columns = 4;
        }
        
        // Dynamic spacing based on screen width
        final spacing = screenWidth < 600 ? 12.0 :
                       screenWidth < 900 ? 16.0 :
                       screenWidth < 1200 ? 20.0 : 24.0;
        
        // Adaptive aspect ratio for cards
        final aspectRatio = screenWidth < 480 ? 4.5 :
                           screenWidth < 768 ? 3.8 :
                           screenWidth < 1024 ? 3.2 : 3.0;

        return _buildFluidStatsGrid(stats, columns, spacing, aspectRatio);
      },
    );
  }

  Widget _buildFluidStatsGrid(Map<String, int> stats, int columns, double spacing, double aspectRatio) {
    final statsList = [
      {'title': 'Total Users', 'value': stats['total'] ?? 0, 'icon': Icons.people, 'color': Colors.blue},
      {'title': 'Administrators', 'value': stats['admin'] ?? 0, 'icon': Icons.admin_panel_settings, 'color': Colors.purple},
      {'title': 'Staff Members', 'value': stats['staff'] ?? 0, 'icon': Icons.person, 'color': Colors.green},
      {'title': 'Supervisors', 'value': stats['supervisor'] ?? 0, 'icon': Icons.supervisor_account, 'color': Colors.orange},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        
        // Calculate card width considering constraints and spacing
        final availableWidth = constraints.maxWidth;
        final totalSpacing = (columns - 1) * spacing;
        final cardWidth = (availableWidth - totalSpacing) / columns;
        
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
    );
  }

  Widget _buildAdaptiveStatCard(Map<String, dynamic> stat, double screenWidth) {
    // Adaptive measurements based on screen width
    final iconSize = screenWidth < 480 ? 24.0 :
                    screenWidth < 768 ? 32.0 :
                    screenWidth < 1024 ? 36.0 : 40.0;
    
    final titleFontSize = screenWidth < 480 ? 11.0 :
                         screenWidth < 768 ? 12.0 :
                         screenWidth < 1024 ? 13.0 : 14.0;
    
    final valueFontSize = screenWidth < 480 ? 18.0 :
                         screenWidth < 768 ? 22.0 :
                         screenWidth < 1024 ? 26.0 : 28.0;
    
    final cardPadding = screenWidth < 480 ? 12.0 :
                       screenWidth < 768 ? 16.0 :
                       screenWidth < 1024 ? 20.0 : 24.0;
    
    final borderRadius = screenWidth < 600 ? 8.0 :
                        screenWidth < 1024 ? 12.0 : 16.0;
    
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
              padding: EdgeInsets.all(screenWidth < 600 ? 8.0 : 12.0),
              decoration: BoxDecoration(
                color: (stat['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(screenWidth < 600 ? 8.0 : 12.0),
              ),
              child: Icon(
                stat['icon'] as IconData,
                size: iconSize,
                color: stat['color'] as Color,
              ),
            ),
            SizedBox(height: screenWidth * 0.015),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${stat['value']}',
                style: TextStyle(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            SizedBox(height: screenWidth * 0.008),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoading) {
          return const common.LoadingWidget(message: 'Loading users...');
        }

        if (userProvider.error != null) {
          return common.ErrorWidget(
            message: userProvider.error!,
            onRetry: () {
              userProvider.clearError();
              userProvider.loadUsers();
            },
          );
        }

        final users = userProvider.filteredUsers;

        if (users.isEmpty) {
          return common.EmptyStateWidget(
            title: 'No Users Found',
            message: userProvider.searchTerm.isNotEmpty || 
                     userProvider.selectedRole != null || 
                     userProvider.selectedFacility != null
                ? 'No users match your current filters'
                : 'No users have been created yet',
            icon: const Icon(Icons.people_outline, size: 64),
            action: common.CustomButton(
              text: 'Create First User',
              icon: const Icon(Icons.add),
              onPressed: () => context.go(AppConstants.createUserRoute),
            ),
          );
        }

        return ResponsiveWidget(
          mobile: _buildUserCards(users),
          tabletSmall: ResponsiveHelper.isTabletSmall(context) && users.length > 10 
              ? _buildTabletCards(users) 
              : _buildUsersTable(users),
          tabletLarge: _buildUsersTable(users),
          desktop: _buildUsersTable(users),
          desktopLarge: _buildEnhancedDesktopTable(users),
        );
      },
    );
  }

  Widget _buildTabletCards(List<User> users) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          elevation: 2,
          child: InkWell(
            onTap: () => context.go('${AppConstants.userDetailsRoute}/${user.userId}'),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.2),
                    child: Text(
                      user.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: _getRoleColor(user.role),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getRoleColor(user.role).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            UserRole.getDisplayName(user.role),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getRoleColor(user.role),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleUserAction(context, value, user),
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 18),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
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

  Widget _buildEnhancedDesktopTable(List<User> users) {
    return Card(
      elevation: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 64,
            ),
            child: DataTable(
              columnSpacing: 32,
              headingRowHeight: 64,
              dataRowHeight: 72,
              headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
              columns: const [
                DataColumn(
                  label: Text(
                    'User',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Contact',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Role & Status',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Created',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Actions',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ],
              rows: users.map((user) {
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.2),
                            child: Text(
                              user.name.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: _getRoleColor(user.role),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'ID: ${user.userId}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.email, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(user.email),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (user.phone.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(user.phone),
                              ],
                            ),
                        ],
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(user.role).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              UserRole.getDisplayName(user.role),
                              style: TextStyle(
                                fontSize: 13,
                                color: _getRoleColor(user.role),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('MMM dd, yyyy').format(user.createdAt),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            DateFormat('hh:mm a').format(user.createdAt),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility, color: Colors.blue),
                            onPressed: () => context.go('${AppConstants.userDetailsRoute}/${user.userId}'),
                            tooltip: 'View Details',
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () => context.go('${AppConstants.editUserRoute}/${user.userId}'),
                            tooltip: 'Edit User',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _handleUserAction(context, 'delete', user),
                            tooltip: 'Delete User',
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCards(List<User> users) {
    return ListView.builder(
      padding: EdgeInsets.all(ResponsiveHelper.isMobile(context) ? 8 : 16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: EdgeInsets.only(
            bottom: ResponsiveHelper.isMobile(context) ? 8 : 12,
          ),
          elevation: 2,
          child: InkWell(
            onTap: () => context.go('${AppConstants.userDetailsRoute}/${user.userId}'),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.all(ResponsiveHelper.isMobile(context) ? 12 : 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: ResponsiveHelper.isMobile(context) ? 20 : 24,
                        backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.2),
                        child: Text(
                          user.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: _getRoleColor(user.role),
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveHelper.isMobile(context) ? 16 : 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (ResponsiveHelper.isMobile(context) && user.phone.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                user.phone,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) => _handleUserAction(context, value, user),
                        icon: Icon(
                          Icons.more_vert,
                          size: ResponsiveHelper.isMobile(context) ? 20 : 24,
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility, size: 18),
                                SizedBox(width: 8),
                                Text('View Details'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 18),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveHelper.isMobile(context) ? 8 : 10,
                          vertical: ResponsiveHelper.isMobile(context) ? 4 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user.role).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          UserRole.getDisplayName(user.role),
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                            color: _getRoleColor(user.role),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Created: ${DateFormat('MMM dd, yyyy').format(user.createdAt)}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                          color: Colors.grey[600],
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

  Widget _buildUsersTable(List<User> users) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 32,
          ),
          child: DataTable(
            columnSpacing: ResponsiveHelper.isMobile(context) ? 16 : 24,
            headingRowHeight: ResponsiveHelper.isMobile(context) ? 56 : 64,
            dataRowMinHeight: ResponsiveHelper.isMobile(context) ? 48 : 56,
            dataRowMaxHeight: ResponsiveHelper.isMobile(context) ? 72 : 80,
            columns: ResponsiveHelper.isMobile(context) 
                ? const [
                    DataColumn(label: Text('User', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Role', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                  ]
                : const [
                    DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Created', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
                  ],
            rows: users.map((user) {
              if (ResponsiveHelper.isMobile(context)) {
                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user.role).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          UserRole.getDisplayName(user.role),
                          style: TextStyle(
                            fontSize: 11,
                            color: _getRoleColor(user.role),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      PopupMenuButton<String>(
                        onSelected: (value) => _handleUserAction(context, value, user),
                        icon: const Icon(Icons.more_vert, size: 20),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility, size: 18),
                                SizedBox(width: 8),
                                Text('View'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 18),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.2),
                            child: Text(
                              user.name.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: _getRoleColor(user.role),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            user.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(user.email)),
                    DataCell(Text(user.phone)),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user.role).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          UserRole.getDisplayName(user.role),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getRoleColor(user.role),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(DateFormat('MMM dd, yyyy').format(user.createdAt)),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () => context.go('${AppConstants.userDetailsRoute}/${user.userId}'),
                            tooltip: 'View Details',
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => context.go('${AppConstants.editUserRoute}/${user.userId}'),
                            tooltip: 'Edit User',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _handleUserAction(context, 'delete', user),
                            tooltip: 'Delete User',
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
            }).toList(),
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'staff':
        return Colors.green;
      case 'supervisor':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _handleUserAction(BuildContext context, String action, User user) {
    switch (action) {
      case 'view':
        context.go('${AppConstants.userDetailsRoute}/${user.userId}');
        break;
      case 'edit':
        context.go('${AppConstants.editUserRoute}/${user.userId}');
        break;
      case 'delete':
        _showDeleteConfirmation(context, user);
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await context.read<UserProvider>().deleteUser(user.userId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                        ? 'User deleted successfully' 
                        : 'Failed to delete user',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}