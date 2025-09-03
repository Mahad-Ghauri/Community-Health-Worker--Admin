import 'package:chw_tb/controllers/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatelessWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // ✅ FIX: use GoRouterState instead of router.location
          final currentLocation = GoRouterState.of(context).matchedLocation;

          if (auth.isAuthenticated) {
            if (currentLocation != '/home') {
              context.go('/home');
            }
          } else {
            if (currentLocation != '/sign-in' &&
                currentLocation != '/sign-up') {
              context.go('/sign-in');
            }
          }
        });
        return child;
      },
    );
  }
}
