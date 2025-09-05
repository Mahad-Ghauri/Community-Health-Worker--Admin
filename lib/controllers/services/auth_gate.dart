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
  String? _lastNavStateKey;

  void _maybeRedirect({
    required bool isAuthed,
  }) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    final ctx = navigator.context;
    final currentRoute = ModalRoute.of(ctx)?.settings.name;

    if (!isAuthed) {
      // Not signed in → go to sign-in
      if (currentRoute != '/sign-in') {
        navigator.pushNamedAndRemoveUntil('/sign-in', (route) => false);
      }
      return;
    }

    // Already signed in → go to main-navigation
    if (currentRoute != '/main-navigation') {
      navigator.pushNamedAndRemoveUntil('/main-navigation', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final isAuthed = auth.isAuthenticated;

        final stateKey = isAuthed.toString();
        if (_lastNavStateKey != stateKey) {
          _lastNavStateKey = stateKey;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _maybeRedirect(isAuthed: isAuthed);
          });
        }

        return widget.child;
      },
    );
  }
}
