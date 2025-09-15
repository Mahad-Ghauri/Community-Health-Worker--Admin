import 'package:flutter/material.dart';
import '../theme/theme.dart';

// Deprecated: Role routing now handled by GoRouter. Keep LoadingScreen for reuse.

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
              style: CHWTheme.bodyStyle.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

// If you need a reusable UnauthorizedScreen, move it to widgets and wire with GoRouter.
