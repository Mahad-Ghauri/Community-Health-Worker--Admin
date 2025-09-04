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
  bool? _lastIsAuthed;

  void _maybeRedirect(bool isAuthed) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    final ctx = navigator.context;
    final currentRoute = ModalRoute.of(ctx)?.settings.name;

    if (isAuthed) {
      if (currentRoute != '/main-navigation') {
        // User is authenticated, navigate to main navigation
        navigator.pushNamedAndRemoveUntil('/main-navigation', (route) => false);
      }
    } else {
      if (currentRoute != '/sign-in' && currentRoute != '/sign-up') {
        navigator.pushNamedAndRemoveUntil('/sign-in', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final isAuthed = auth.isAuthenticated;

        // Only navigate when auth state actually changes
        if (_lastIsAuthed != isAuthed) {
          _lastIsAuthed = isAuthed;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _maybeRedirect(isAuthed);
          });
        }

        return widget.child;
      },
    );
  }
}
