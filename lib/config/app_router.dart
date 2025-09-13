import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../services/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/main_layout.dart';
import '../screens/dashboard/main_dashboard.dart';
import '../screens/users/user_list_screen.dart';
import '../screens/users/create_user_screen.dart';
import '../screens/users/edit_user_screen.dart';
import '../screens/users/user_details_screen.dart';
import '../screens/facilities/facility_list_screen.dart';
import '../screens/facilities/create_facility_screen.dart';
import '../screens/facilities/edit_facility_screen.dart';
import '../screens/facilities/facility_details_screen.dart';
import '../screens/audit_logs/audit_logs_screen.dart';
import '../screens/settings/settings_screen.dart';

class AppRouter {
  static GoRouter getRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: AppConstants.loginRoute,
      refreshListenable: authProvider, // Listen to auth changes
      redirect: (BuildContext context, GoRouterState state) {
        final bool isLoggedIn = authProvider.isAuthenticated;
        final String currentLocation = state.uri.toString();

        // If not logged in and trying to access protected routes
        if (!isLoggedIn && !_isPublicRoute(currentLocation)) {
          return AppConstants.loginRoute;
        }

        // If logged in and on login page, redirect to dashboard
        if (isLoggedIn && currentLocation == AppConstants.loginRoute) {
          return AppConstants.dashboardRoute;
        }

        return null; // No redirect needed
      },
      routes: [
        // Auth Routes
        GoRoute(
          path: AppConstants.loginRoute,
          builder: (context, state) => const LoginScreen(),
        ),
        // GoRoute(
        //   path: '/signup',
        //   builder: (context, state) => const SignupScreen(),
        // ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),

        // Main App Shell
        ShellRoute(
          builder: (context, state, child) => MainLayout(child: child),
          routes: [
            // Dashboard
            GoRoute(
              path: AppConstants.dashboardRoute,
              builder: (context, state) => const MainDashboard(),
            ),

            // User Management
            GoRoute(
              path: AppConstants.usersRoute,
              builder: (context, state) => const UserListScreen(),
            ),
            GoRoute(
              path: AppConstants.createUserRoute,
              builder: (context, state) => const CreateUserScreen(),
            ),
            GoRoute(
              path: '${AppConstants.editUserRoute}/:userId',
              builder: (context, state) {
                final userId = state.pathParameters['userId']!;
                return EditUserScreen(userId: userId);
              },
            ),
            GoRoute(
              path: '${AppConstants.userDetailsRoute}/:userId',
              builder: (context, state) {
                final userId = state.pathParameters['userId']!;
                return UserDetailsScreen(userId: userId);
              },
            ),

            // Facility Management
            GoRoute(
              path: AppConstants.facilitiesRoute,
              builder: (context, state) => const FacilityListScreen(),
            ),
            GoRoute(
              path: AppConstants.createFacilityRoute,
              builder: (context, state) => const CreateFacilityScreen(),
            ),
            GoRoute(
              path: '${AppConstants.editFacilityRoute}/:facilityId',
              builder: (context, state) {
                final facilityId = state.pathParameters['facilityId']!;
                return EditFacilityScreen(facilityId: facilityId);
              },
            ),
            GoRoute(
              path: '${AppConstants.facilityDetailsRoute}/:facilityId',
              builder: (context, state) {
                final facilityId = state.pathParameters['facilityId']!;
                return FacilityDetailsScreen(facilityId: facilityId);
              },
            ),

            // Audit Logs
            GoRoute(
              path: AppConstants.auditLogsRoute,
              builder: (context, state) => const AuditLogsScreen(),
            ),

            // Settings
            GoRoute(
              path: AppConstants.settingsRoute,
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Page Not Found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'The page you\'re looking for doesn\'t exist.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(AppConstants.dashboardRoute),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static bool _isPublicRoute(String route) {
    const publicRoutes = [
      AppConstants.loginRoute,
      '/signup',
      '/forgot-password',
    ];
    return publicRoutes.contains(route);
  }
}