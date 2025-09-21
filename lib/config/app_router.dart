import 'package:chw_admin/screens/staff/patients/patient_details_screen.dart';
import 'package:chw_admin/screens/staff/patients/patient_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import '../services/auth_provider.dart';
import '../screens/auth/login_screen.dart';
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
import '../screens/staff/staff_layout.dart';
import '../screens/staff/dashboard/staff_dashboard.dart';
import '../screens/staff/patients/assign_patients_screen.dart';
import '../screens/staff/patients/facility_patients_screen.dart';
import '../screens/staff/referrals/referrals_screen.dart';
import '../screens/staff/followups/create_followups_screen.dart';
import '../screens/staff/followups/manage_followups_screen.dart';
import '../screens/staff/medications/manage_medications_screen.dart';

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

        if (isLoggedIn) {
          final role = authProvider.currentUser?.role;

          // If logged in and on login page, redirect by role
          if (currentLocation == AppConstants.loginRoute) {
            if (role == AppConstants.staffRole) {
              return AppConstants.staffDashboardRoute;
            }
            // Default to admin-style dashboard for other roles
            return AppConstants.dashboardRoute;
          }

          // Prevent staff from landing on admin dashboard route
          if (role == AppConstants.staffRole &&
              currentLocation == AppConstants.dashboardRoute) {
            return AppConstants.staffDashboardRoute;
          }
        }

        return null; // No redirect needed
      },
      routes: [
        // Auth Routes
        GoRoute(
          name: 'login',
          path: AppConstants.loginRoute,
          builder: (context, state) => const LoginScreen(),
        ),
        // GoRoute(
        //   name: 'signup',
        //   path: AppConstants.signupRoute,
        //   builder: (context, state) => const SignupScreen(),
        // ),
        GoRoute(
          name: 'forgotPassword',
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),

        // Main App Shell
        ShellRoute(
          builder: (context, state, child) => MainLayout(child: child),
          routes: [
            // Dashboard
            GoRoute(
              name: 'dashboard',
              path: AppConstants.dashboardRoute,
              builder: (context, state) => const MainDashboard(),
            ),

            // User Management
            GoRoute(
              name: 'users',
              path: AppConstants.usersRoute,
              builder: (context, state) => const UserListScreen(),
            ),
            GoRoute(
              name: 'createUser',
              path: AppConstants.createUserRoute,
              builder: (context, state) => const CreateUserScreen(),
            ),
            GoRoute(
              name: 'editUser',
              path: '${AppConstants.editUserRoute}/:userId',
              builder: (context, state) {
                final userId = state.pathParameters['userId']!;
                return EditUserScreen(userId: userId);
              },
            ),
            GoRoute(
              name: 'userDetails',
              path: '${AppConstants.userDetailsRoute}/:userId',
              builder: (context, state) {
                final userId = state.pathParameters['userId']!;
                return UserDetailsScreen(userId: userId);
              },
            ),

            // Facility Management
            GoRoute(
              name: 'facilities',
              path: AppConstants.facilitiesRoute,
              builder: (context, state) => const FacilityListScreen(),
            ),
            GoRoute(
              name: 'createFacility',
              path: AppConstants.createFacilityRoute,
              builder: (context, state) => const CreateFacilityScreen(),
            ),
            GoRoute(
              name: 'editFacility',
              path: '${AppConstants.editFacilityRoute}/:facilityId',
              builder: (context, state) {
                final facilityId = state.pathParameters['facilityId']!;
                return EditFacilityScreen(facilityId: facilityId);
              },
            ),
            GoRoute(
              name: 'facilityDetails',
              path: '${AppConstants.facilityDetailsRoute}/:facilityId',
              builder: (context, state) {
                final facilityId = state.pathParameters['facilityId']!;
                return FacilityDetailsScreen(facilityId: facilityId);
              },
            ),

            // Audit Logs
            GoRoute(
              name: 'auditLogs',
              path: AppConstants.auditLogsRoute,
              builder: (context, state) => const AuditLogsScreen(),
            ),

            // Settings
            GoRoute(
              name: 'settings',
              path: AppConstants.settingsRoute,
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),

        // Staff App Shell
        ShellRoute(
          builder: (context, state, child) => StaffLayout(child: child),
          routes: [
            // Staff Dashboard
            GoRoute(
              name: 'staffDashboard',
              path: AppConstants.staffDashboardRoute,
              builder: (context, state) => const StaffDashboard(),
            ),

            // Patient Management
            GoRoute(
              name: 'assignPatients',
              path: AppConstants.assignPatientsRoute,
              builder: (context, state) => const AssignPatientsScreen(),
            ),

            GoRoute(name: 'patients', path: AppConstants.patientsRoute, builder: (context, state) {
              return const PatientListScreen();
            }),

            GoRoute(name: 'patientDetails', path: '${AppConstants.patientDetailsRoute}/:patientId', builder: (context, state) {
              final patientId = state.pathParameters['patientId']!;
              return PatientDetailsScreen(patientId: patientId);
            }),

            GoRoute(
              name: 'facilityPatients',
              path: AppConstants.facilityPatientsRoute,
              builder: (context, state) => const FacilityPatientsScreen(),
            ),

            // Referrals
            GoRoute(
              name: 'referrals',
              path: AppConstants.referralsRoute,
              builder: (context, state) => const ReferralsScreen(),
            ),

            // Follow-ups
            GoRoute(
              name: 'createFollowups',
              path: AppConstants.createFollowupsRoute,
              builder: (context, state) => const CreateFollowupsScreen(),
            ),
            GoRoute(
              name: 'manageFollowups',
              path: AppConstants.manageFollowupsRoute,
              builder: (context, state) => const ManageFollowupsScreen(),
            ),

            // Medication Management
            GoRoute(
              name: 'manageMedications',
              path: AppConstants.manageMedicationsRoute,
              builder: (context, state) => const ManageMedicationsScreen(),
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
                onPressed: () => context.goNamed('dashboard'),
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
      AppConstants.signupRoute,
      AppConstants.forgotPasswordRoute,
    ];
    return publicRoutes.contains(route);
  }
}
