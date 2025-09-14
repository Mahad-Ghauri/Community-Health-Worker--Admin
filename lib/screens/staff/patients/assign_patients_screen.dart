import 'package:flutter/material.dart';

class AssignPatientsScreen extends StatelessWidget {
  const AssignPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    
    // Responsive text sizing
    final titleFontSize = screenWidth < 600 ? 24.0 : 
                         screenWidth < 1024 ? 28.0 : 32.0;
    final subtitleFontSize = screenWidth < 600 ? 14.0 : 
                            screenWidth < 1024 ? 16.0 : 18.0;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_add,
                size: screenWidth < 600 ? 64 : 80,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 24),
              Text(
                'Assign Patients to CHW',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Assign new or existing patients to Community Health Workers',
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Coming Soon: Patient Form & CHW Selector',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}