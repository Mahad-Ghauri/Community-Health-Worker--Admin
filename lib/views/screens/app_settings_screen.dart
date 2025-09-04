// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chw_tb/config/theme.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Settings state
  bool _darkMode = false;
  bool _notifications = true;
  bool _visitReminders = true;
  bool _medicationAlerts = true;
  bool _followUpAlerts = true;
  bool _systemUpdates = false;
  bool _offlineMode = true;
  bool _autoSync = true;
  bool _wifiOnlySync = false;
  bool _locationServices = true;
  bool _cameraPermission = true;
  bool _storagePermission = true;
  double _syncFrequency = 15; // minutes
  String _defaultLanguage = 'English';
  String _dateFormat = 'DD/MM/YYYY';
  String _timeFormat = '24 Hour';

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
    _loadSettings();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _loadSettings() {
    // Load settings from SharedPreferences or secure storage
    // This will be implemented with actual storage later
  }

  void _saveSettings() {
    // Save settings to SharedPreferences or secure storage
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Settings saved successfully!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MadadgarTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'App Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: MadadgarTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _resetToDefaults,
            icon: const Icon(Icons.restore),
            tooltip: 'Reset to Defaults',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Display Settings
              _buildDisplaySettings(),
              
              const SizedBox(height: 16),
              
              // Notification Settings
              _buildNotificationSettings(),
              
              const SizedBox(height: 16),
              
              // Data & Sync Settings
              _buildDataSyncSettings(),
              
              const SizedBox(height: 16),
              
              // Privacy & Permissions
              _buildPrivacyPermissionsSettings(),
              
              const SizedBox(height: 16),
              
              // Language & Region
              _buildLanguageRegionSettings(),
              
              const SizedBox(height: 16),
              
              // Storage & Cache
              _buildStorageCacheSettings(),
              
              const SizedBox(height: 16),
              
              // About & Support
              _buildAboutSupportSettings(),
              
              const SizedBox(height: 32),
              
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MadadgarTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save Settings',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisplaySettings() {
    return _buildSettingsCard(
      title: 'Display Settings',
      icon: Icons.display_settings,
      children: [
        _buildSwitchTile(
          title: 'Dark Mode',
          subtitle: 'Use dark theme for better night viewing',
          value: _darkMode,
          onChanged: (value) => setState(() => _darkMode = value),
        ),
        
        _buildDropdownTile(
          title: 'Date Format',
          subtitle: 'Choose how dates are displayed',
          value: _dateFormat,
          items: ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'],
          onChanged: (value) => setState(() => _dateFormat = value!),
        ),
        
        _buildDropdownTile(
          title: 'Time Format',
          subtitle: 'Choose 12-hour or 24-hour format',
          value: _timeFormat,
          items: ['12 Hour', '24 Hour'],
          onChanged: (value) => setState(() => _timeFormat = value!),
        ),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    return _buildSettingsCard(
      title: 'Notifications',
      icon: Icons.notifications_outlined,
      children: [
        _buildSwitchTile(
          title: 'Enable Notifications',
          subtitle: 'Receive app notifications',
          value: _notifications,
          onChanged: (value) => setState(() => _notifications = value),
        ),
        
        if (_notifications) ...[
          _buildSwitchTile(
            title: 'Visit Reminders',
            subtitle: 'Upcoming patient visit notifications',
            value: _visitReminders,
            onChanged: (value) => setState(() => _visitReminders = value),
          ),
          
          _buildSwitchTile(
            title: 'Medication Alerts',
            subtitle: 'Patient medication reminders',
            value: _medicationAlerts,
            onChanged: (value) => setState(() => _medicationAlerts = value),
          ),
          
          _buildSwitchTile(
            title: 'Follow-up Alerts',
            subtitle: 'Patient follow-up notifications',
            value: _followUpAlerts,
            onChanged: (value) => setState(() => _followUpAlerts = value),
          ),
          
          _buildSwitchTile(
            title: 'System Updates',
            subtitle: 'App updates and announcements',
            value: _systemUpdates,
            onChanged: (value) => setState(() => _systemUpdates = value),
          ),
        ],
      ],
    );
  }

  Widget _buildDataSyncSettings() {
    return _buildSettingsCard(
      title: 'Data & Sync',
      icon: Icons.sync,
      children: [
        _buildSwitchTile(
          title: 'Offline Mode',
          subtitle: 'Work without internet connection',
          value: _offlineMode,
          onChanged: (value) => setState(() => _offlineMode = value),
        ),
        
        _buildSwitchTile(
          title: 'Auto Sync',
          subtitle: 'Automatically sync data when online',
          value: _autoSync,
          onChanged: (value) => setState(() => _autoSync = value),
        ),
        
        if (_autoSync) ...[
          _buildSwitchTile(
            title: 'WiFi Only Sync',
            subtitle: 'Sync only on WiFi to save mobile data',
            value: _wifiOnlySync,
            onChanged: (value) => setState(() => _wifiOnlySync = value),
          ),
          
          _buildSliderTile(
            title: 'Sync Frequency',
            subtitle: 'How often to sync data (${_syncFrequency.round()} minutes)',
            value: _syncFrequency,
            min: 5,
            max: 60,
            divisions: 11,
            onChanged: (value) => setState(() => _syncFrequency = value),
          ),
        ],
        
        _buildActionTile(
          title: 'Sync Now',
          subtitle: 'Force sync all data immediately',
          icon: Icons.sync,
          onTap: _forceSyncNow,
        ),
      ],
    );
  }

  Widget _buildPrivacyPermissionsSettings() {
    return _buildSettingsCard(
      title: 'Privacy & Permissions',
      icon: Icons.security,
      children: [
        _buildSwitchTile(
          title: 'Location Services',
          subtitle: 'Allow GPS location for patient visits',
          value: _locationServices,
          onChanged: (value) => setState(() => _locationServices = value),
        ),
        
        _buildSwitchTile(
          title: 'Camera Access',
          subtitle: 'Allow camera for photos and documents',
          value: _cameraPermission,
          onChanged: (value) => setState(() => _cameraPermission = value),
        ),
        
        _buildSwitchTile(
          title: 'Storage Access',
          subtitle: 'Allow file storage and downloads',
          value: _storagePermission,
          onChanged: (value) => setState(() => _storagePermission = value),
        ),
        
        _buildActionTile(
          title: 'Privacy Policy',
          subtitle: 'Read our privacy policy',
          icon: Icons.policy,
          onTap: () => _showPrivacyPolicy(),
        ),
        
        _buildActionTile(
          title: 'Data Export',
          subtitle: 'Export your data',
          icon: Icons.download,
          onTap: () => _exportData(),
        ),
      ],
    );
  }

  Widget _buildLanguageRegionSettings() {
    return _buildSettingsCard(
      title: 'Language & Region',
      icon: Icons.language,
      children: [
        _buildDropdownTile(
          title: 'Language',
          subtitle: 'App interface language',
          value: _defaultLanguage,
          items: ['English', 'اردو (Urdu)'],
          onChanged: (value) {
            setState(() => _defaultLanguage = value!);
            if (value == 'اردو (Urdu)') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Urdu language support coming soon!',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              );
            }
          },
        ),
        
        _buildActionTile(
          title: 'Region Settings',
          subtitle: 'Currency, number format, etc.',
          icon: Icons.public,
          onTap: () => _showRegionSettings(),
        ),
      ],
    );
  }

  Widget _buildStorageCacheSettings() {
    return _buildSettingsCard(
      title: 'Storage & Cache',
      icon: Icons.storage,
      children: [
        _buildInfoTile(
          title: 'App Storage Used',
          subtitle: '45.2 MB',
          icon: Icons.folder,
        ),
        
        _buildInfoTile(
          title: 'Cache Size',
          subtitle: '12.8 MB',
          icon: Icons.cached,
        ),
        
        _buildActionTile(
          title: 'Clear Cache',
          subtitle: 'Free up storage space',
          icon: Icons.cleaning_services,
          onTap: () => _clearCache(),
        ),
        
        _buildActionTile(
          title: 'Manage Downloads',
          subtitle: 'View and delete downloaded files',
          icon: Icons.file_download,
          onTap: () => _manageDownloads(),
        ),
      ],
    );
  }

  Widget _buildAboutSupportSettings() {
    return _buildSettingsCard(
      title: 'About & Support',
      icon: Icons.info_outline,
      children: [
        _buildInfoTile(
          title: 'App Version',
          subtitle: '1.0.0 (Build 1)',
          icon: Icons.info,
        ),
        
        _buildActionTile(
          title: 'Help & FAQ',
          subtitle: 'Get help and find answers',
          icon: Icons.help_outline,
          onTap: () => Navigator.pushNamed(context, '/help'),
        ),
        
        _buildActionTile(
          title: 'Contact Support',
          subtitle: 'Get technical support',
          icon: Icons.support_agent,
          onTap: () => _contactSupport(),
        ),
        
        _buildActionTile(
          title: 'Rate This App',
          subtitle: 'Share your feedback',
          icon: Icons.star_outline,
          onTap: () => _rateApp(),
        ),
        
        _buildActionTile(
          title: 'Terms of Service',
          subtitle: 'Read terms and conditions',
          icon: Icons.description,
          onTap: () => _showTermsOfService(),
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: MadadgarTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.black54,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: MadadgarTheme.primaryColor,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: value,
            isExpanded: true,
            items: items.map((item) => DropdownMenuItem(
              value: item,
              child: Text(item, style: GoogleFonts.poppins()),
            )).toList(),
            onChanged: onChanged,
            underline: Container(
              height: 1,
              color: MadadgarTheme.primaryColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required Function(double) onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            activeColor: MadadgarTheme.primaryColor,
          ),
        ],
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: MadadgarTheme.primaryColor),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.black54,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: MadadgarTheme.primaryColor),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.black54,
        ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset to Defaults',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will reset all settings to their default values. Are you sure?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _darkMode = false;
                _notifications = true;
                _visitReminders = true;
                _medicationAlerts = true;
                _followUpAlerts = true;
                _systemUpdates = false;
                _offlineMode = true;
                _autoSync = true;
                _wifiOnlySync = false;
                _locationServices = true;
                _cameraPermission = true;
                _storagePermission = true;
                _syncFrequency = 15;
                _defaultLanguage = 'English';
                _dateFormat = 'DD/MM/YYYY';
                _timeFormat = '24 Hour';
              });
              _saveSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MadadgarTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Reset',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  void _forceSyncNow() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Syncing data... This may take a moment.',
          style: GoogleFonts.poppins(),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Privacy policy will be displayed here or opened in browser.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: MadadgarTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Data export feature coming soon!',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }

  void _showRegionSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Region settings feature coming soon!',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear Cache',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will clear 12.8 MB of cached data. This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Cache cleared successfully!',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MadadgarTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Clear',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  void _manageDownloads() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Download manager feature coming soon!',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Support contact feature coming soon!',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'App rating feature coming soon!',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Terms of Service',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Terms of service will be displayed here or opened in browser.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: MadadgarTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
