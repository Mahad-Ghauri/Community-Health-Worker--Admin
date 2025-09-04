import 'package:chw_tb/controllers/providers/app_providers.dart';
import 'package:chw_tb/config/router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatefulWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Track last evaluated navigation state to avoid redundant redirects
  String? _lastNavStateKey;

  void _maybeRedirect({
    required bool isAuthed,
    required bool? isFirstTimeSetupComplete,
  }) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    final ctx = navigator.context;
    final currentRoute = ModalRoute.of(ctx)?.settings.name;

    if (!isAuthed) {
      // Not authenticated: keep on auth routes
      if (currentRoute != '/sign-in' && currentRoute != '/sign-up') {
        navigator.pushNamedAndRemoveUntil('/sign-in', (route) => false);
      }
      return;
    }

    // Authenticated
    if (isFirstTimeSetupComplete == false) {
      // New user: go to first-time setup
      if (currentRoute != '/first-time-setup') {
        navigator.pushNamedAndRemoveUntil(
          '/first-time-setup',
          (route) => false,
        );
      }
      return;
    }

    if (isFirstTimeSetupComplete == true) {
      // Existing or completed setup: go to main navigation
      if (currentRoute != '/main-navigation') {
        navigator.pushNamedAndRemoveUntil('/main-navigation', (route) => false);
      }
      return;
    }

    // If isFirstTimeSetupComplete is null, wait until user profile is loaded
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final isAuthed = auth.isAuthenticated;
        final setupComplete = auth.chwUser?.isFirstTimeSetupComplete;

        // Build a key from current auth + setup state to detect changes
        final stateKey =
            '${isAuthed.toString()}|${setupComplete?.toString() ?? 'null'}';
        if (_lastNavStateKey != stateKey) {
          _lastNavStateKey = stateKey;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _maybeRedirect(
              isAuthed: isAuthed,
              isFirstTimeSetupComplete: setupComplete,
            );
          });
        }

        return widget.child;
      },
    );
  }
}
