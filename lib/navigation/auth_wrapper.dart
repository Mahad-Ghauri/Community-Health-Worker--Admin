import 'package:chw_admin/screens/staff/dashboard/staff_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/admin_dashboard.dart';
import '../screens/dashboard/supervisor_dashboard.dart';
import '../theme/theme.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading screen while checking auth state
        if (authProvider.isLoading) {
          return const LoadingScreen();
        }

        // If user is not authenticated, show login screen
        if (!authProvider.isAuthenticated || authProvider.currentUser == null) {
          return const LoginScreen();
        }

        // Route to appropriate dashboard based on user role
        final user = authProvider.currentUser!;
        
        switch (user.role) {
          case 'admin':
            return const AdminDashboard();
          case 'staff':
            return const StaffDashboard();
          case 'supervisor':
            return const SupervisorDashboard();
          default:
            // If role is unknown, sign out and return to login
            WidgetsBinding.instance.addPostFrameCallback((_) {
              authProvider.signOut();
            });
            return const LoginScreen();
        }
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CHWTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: CHWTheme.primaryColor,
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.health_and_safety,
                color: Colors.white,
                size: 60,
              ),
            ),
            
            const SizedBox(height: 32),
            
            Text(
              'CHW Admin',
              style: CHWTheme.headingStyle.copyWith(
                color: CHWTheme.primaryColor,
                fontSize: 32,
              ),
            ),
            
            const SizedBox(height: 24),
            
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00796B)),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Loading...',
              style: CHWTheme.bodyStyle.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Route guard for protected screens
class ProtectedRoute extends StatelessWidget {
  final Widget child;
  final String requiredPermission;
  final Widget? fallback;

  const ProtectedRoute({
    super.key,
    required this.child,
    required this.requiredPermission,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        if (!authProvider.hasPermission(requiredPermission)) {
          return fallback ?? const UnauthorizedScreen();
        }

        return child;
      },
    );
  }
}

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CHWTheme.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: Color(0xFFE57373),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Access Denied',
                style: CHWTheme.headingStyle.copyWith(
                  color: CHWTheme.errorColor,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'You do not have permission to access this page.',
                style: CHWTheme.bodyStyle.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: () {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final dashboardRoute = authProvider.getDashboardRoute();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    dashboardRoute,
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CHWTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}