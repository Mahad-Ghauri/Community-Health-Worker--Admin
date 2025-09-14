import 'package:flutter/material.dart';

class ManageFollowupsScreen extends StatelessWidget {
  const ManageFollowupsScreen({super.key});

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
              Colors.purple.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event,
                size: screenWidth < 600 ? 64 : 80,
                color: Colors.purple,
              ),
              const SizedBox(height: 24),
              Text(
                'Manage Follow-ups',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Track and update follow-up appointment statuses',
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
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                ),
                child: Text(
                  'Coming Soon: Calendar View & Status Updates',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.purple.shade700,
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