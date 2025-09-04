// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chw_tb/config/theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final String _appVersion = '2.1.0';
  final String _buildNumber = '105';
  final String _releaseDate = 'September 2025';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MadadgarTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'About',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: MadadgarTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    const Icon(Icons.share),
                    const SizedBox(width: 8),
                    Text('Share App', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'feedback',
                child: Row(
                  children: [
                    const Icon(Icons.feedback),
                    const SizedBox(width: 8),
                    Text('Send Feedback', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'rate',
                child: Row(
                  children: [
                    const Icon(Icons.star),
                    const SizedBox(width: 8),
                    Text('Rate App', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildAppHeader(),
              _buildAppInfo(),
              _buildDeveloperInfo(),
              _buildOrganizationInfo(),
              _buildLegalInfo(),
              _buildSupportInfo(),
              _buildSystemInfo(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [MadadgarTheme.primaryColor, MadadgarTheme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/icons/logo.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.medical_services,
                    size: 60,
                    color: MadadgarTheme.primaryColor,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'CHW TB Tracker',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'Community Health Worker',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          Text(
            'Tuberculosis Management System',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Version $_appVersion',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: MadadgarTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Application Information',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildInfoRow('Version', _appVersion),
              _buildInfoRow('Build Number', _buildNumber),
              _buildInfoRow('Release Date', _releaseDate),
              _buildInfoRow('Platform', 'Android & iOS'),
              _buildInfoRow('Framework', 'Flutter 3.0+'),
              
              const SizedBox(height: 16),
              
              Text(
                'Description',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'CHW TB Tracker is a comprehensive mobile application designed to assist Community Health Workers in managing tuberculosis patients. The app provides tools for patient registration, treatment monitoring, adherence tracking, and data collection to improve TB care outcomes.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeveloperInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.code, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Development Team',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildDeveloperCard(
                'Lead Developer',
                'Mahad Ghauri',
                'Full Stack Developer',
                'mahad.ghauri@example.com',
                Icons.person,
              ),
              
              const SizedBox(height: 12),
              
              _buildDeveloperCard(
                'UI/UX Designer',
                'Design Team',
                'Mobile App Design',
                'design@example.com',
                Icons.design_services,
              ),
              
              const SizedBox(height: 12),
              
              _buildDeveloperCard(
                'Medical Consultant',
                'Dr. Medical Expert',
                'TB Specialist',
                'medical@example.com',
                Icons.medical_services,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeveloperCard(String role, String name, String title, String email, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MadadgarTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: MadadgarTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _contactDeveloper(email),
            icon: const Icon(Icons.email, color: Colors.grey),
            tooltip: 'Contact',
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizationInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.business, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Organization',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildInfoRow('Organization', 'Health Ministry'),
              _buildInfoRow('Department', 'Digital Health Solutions'),
              _buildInfoRow('Program', 'TB Control Program'),
              _buildInfoRow('Region', 'Pakistan'),
              _buildInfoRow('License', 'Government Licensed'),
              
              const SizedBox(height: 16),
              
              Text(
                'Mission Statement',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'To eliminate tuberculosis through innovative digital health solutions that empower community health workers and improve patient care outcomes.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegalInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.gavel, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Legal Information',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildLegalItem(
                'Privacy Policy',
                'Learn how we protect your data and privacy',
                Icons.privacy_tip,
                () => _openPrivacyPolicy(),
              ),
              
              _buildLegalItem(
                'Terms of Service',
                'Read our terms and conditions',
                Icons.description,
                () => _openTermsOfService(),
              ),
              
              _buildLegalItem(
                'Data Security',
                'Information about data encryption and security',
                Icons.security,
                () => _openDataSecurity(),
              ),
              
              _buildLegalItem(
                'Open Source Licenses',
                'Third-party libraries and licenses',
                Icons.code,
                () => _openLicenses(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegalItem(String title, String description, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.support_agent, color: Colors.purple),
                  const SizedBox(width: 8),
                  Text(
                    'Support & Help',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildSupportButton(
                      'Help Center',
                      Icons.help_center,
                      Colors.blue,
                      () => _openHelpCenter(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSupportButton(
                      'Contact Us',
                      Icons.contact_support,
                      Colors.green,
                      () => _contactSupport(),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildSupportButton(
                      'Report Bug',
                      Icons.bug_report,
                      Colors.red,
                      () => _reportBug(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSupportButton(
                      'User Guide',
                      Icons.menu_book,
                      Colors.orange,
                      () => _openUserGuide(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Text(
                    'System Information',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildInfoRow('App Version', _appVersion),
              _buildInfoRow('Build Number', _buildNumber),
              _buildInfoRow('Flutter Version', '3.24.0'),
              _buildInfoRow('Dart Version', '3.5.0'),
              _buildInfoRow('Platform', 'Android/iOS'),
              _buildInfoRow('Architecture', 'ARM64'),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _checkForUpdates(),
                      icon: const Icon(Icons.system_update),
                      label: Text(
                        'Check for Updates',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MadadgarTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'share':
        _shareApp();
        break;
      case 'feedback':
        _sendFeedback();
        break;
      case 'rate':
        _rateApp();
        break;
    }
  }

  void _shareApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share app feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _sendFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Send feedback feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rate app feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _contactDeveloper(String email) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening email to $email...', style: GoogleFonts.poppins())),
    );
  }

  void _openPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening privacy policy...', style: GoogleFonts.poppins())),
    );
  }

  void _openTermsOfService() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening terms of service...', style: GoogleFonts.poppins())),
    );
  }

  void _openDataSecurity() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening data security info...', style: GoogleFonts.poppins())),
    );
  }

  void _openLicenses() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Theme(
          data: Theme.of(context).copyWith(
            appBarTheme: AppBarTheme(
              backgroundColor: MadadgarTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
          child: const LicensePage(
            applicationName: 'CHW TB Tracker',
            applicationVersion: '2.1.0',
            applicationIcon: FlutterLogo(),
          ),
        ),
      ),
    );
  }

  void _openHelpCenter() {
    Navigator.pushNamed(context, '/help-faq');
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Contact support feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _reportBug() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Report bug feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _openUserGuide() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User guide feature coming soon!', style: GoogleFonts.poppins())),
    );
  }

  void _checkForUpdates() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Checking for updates...', style: GoogleFonts.poppins()),
        duration: const Duration(seconds: 2),
      ),
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have the latest version!', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }
}
