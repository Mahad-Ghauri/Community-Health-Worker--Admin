// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chw_tb/config/theme.dart';

class FirstTimeSetupScreen extends StatefulWidget {
  const FirstTimeSetupScreen({super.key});

  @override
  State<FirstTimeSetupScreen> createState() => _FirstTimeSetupScreenState();
}

class _FirstTimeSetupScreenState extends State<FirstTimeSetupScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  int _currentStep = 0;
  bool _isLoading = false;
  
  final List<PermissionSetupStep> _steps = [
    PermissionSetupStep(
      title: 'Location Access',
      description: 'We need GPS access to track your visits and automatically capture location data for patient registrations.',
      icon: Icons.location_on_outlined,
      permission: Permission.location,
    ),
    PermissionSetupStep(
      title: 'Camera Access',
      description: 'Camera permission is required to capture patient photos and visit documentation.',
      icon: Icons.camera_alt_outlined,
      permission: Permission.camera,
    ),
    PermissionSetupStep(
      title: 'Storage Access',
      description: 'Storage access is needed to save photos and offline data for sync when connected.',
      icon: Icons.storage_outlined,
      permission: Permission.storage,
    ),
    PermissionSetupStep(
      title: 'Notifications',
      description: 'Stay updated with visit reminders, patient alerts, and important notifications.',
      icon: Icons.notifications_outlined,
      permission: Permission.notification,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    setState(() => _isLoading = true);
    
    try {
      final permission = _steps[_currentStep].permission;
      await permission.request();
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (_currentStep < _steps.length - 1) {
        setState(() {
          _currentStep++;
          _isLoading = false;
        });
      } else {
        // All permissions requested, navigate to main navigation
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/main-navigation');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Permission request failed: $e'),
          backgroundColor: MadadgarTheme.errorColor,
        ),
      );
    }
  }

  void _skipSetup() {
    Navigator.pushReplacementNamed(context, '/main-navigation');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MadadgarTheme.backgroundColor,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  MadadgarTheme.backgroundColor,
                  MadadgarTheme.primaryColor.withOpacity(0.05),
                  MadadgarTheme.secondaryColor.withOpacity(0.03),
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
          ),
          
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Header
                    _buildHeader(),
                    
                    const SizedBox(height: 40),
                    
                    // Progress indicator
                    _buildProgressIndicator(),
                    
                    const SizedBox(height: 40),
                    
                    // Current step content
                    Expanded(child: _buildStepContent()),
                    
                    // Action buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [MadadgarTheme.primaryColor, MadadgarTheme.secondaryColor],
            ),
            boxShadow: [
              BoxShadow(
                color: MadadgarTheme.primaryColor.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.settings_outlined,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Setup Permissions',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Grant necessary permissions for optimal app experience',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Step ${_currentStep + 1} of ${_steps.length}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: MadadgarTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: (_currentStep + 1) / _steps.length,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(MadadgarTheme.primaryColor),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    final step = _steps[_currentStep];
    
    return Center(
      child: Card(
        elevation: 8,
        shadowColor: MadadgarTheme.primaryColor.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MadadgarTheme.primaryColor.withOpacity(0.1),
                ),
                child: Icon(
                  step.icon,
                  size: 50,
                  color: MadadgarTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                step.title,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                step.description,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _requestPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: MadadgarTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _currentStep == _steps.length - 1 ? 'Complete Setup' : 'Grant Permission',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _skipSetup,
          child: Text(
            'Skip for now',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}

class PermissionSetupStep {
  final String title;
  final String description;
  final IconData icon;
  final Permission permission;

  PermissionSetupStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.permission,
  });
}
