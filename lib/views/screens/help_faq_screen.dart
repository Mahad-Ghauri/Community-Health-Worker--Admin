// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chw_tb/config/theme.dart';

class HelpFaqScreen extends StatefulWidget {
  const HelpFaqScreen({super.key});

  @override
  State<HelpFaqScreen> createState() => _HelpFaqScreenState();
}

class _HelpFaqScreenState extends State<HelpFaqScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // FAQ categories and items
  final List<FAQCategory> _faqCategories = [
    FAQCategory(
      title: 'Getting Started',
      icon: Icons.play_circle_outline,
      faqs: [
        FAQ(
          question: 'How do I register a new patient?',
          answer: 'To register a new patient:\n\n1. Go to the main dashboard\n2. Tap on "Register Patient" button\n3. Fill in all required information\n4. Take a photo of the patient\n5. Capture GPS location\n6. Save the patient record\n\nMake sure all mandatory fields are completed before saving.',
        ),
        FAQ(
          question: 'How do I conduct a patient visit?',
          answer: 'To conduct a patient visit:\n\n1. Open the "Visits" section\n2. Tap "New Visit" button\n3. Select the patient from the dropdown\n4. Choose visit type (Follow-up, Treatment, etc.)\n5. Capture GPS location\n6. Add visit notes and observations\n7. Take photos if needed\n8. Save the visit record',
        ),
        FAQ(
          question: 'How do I sync my data?',
          answer: 'Data syncing happens automatically when you have internet connection. You can also manually sync by:\n\n1. Go to Settings\n2. Tap "Data & Sync"\n3. Tap "Sync Now"\n\nNote: Large files sync only on WiFi by default to save mobile data.',
        ),
      ],
    ),
    FAQCategory(
      title: 'Patient Management',
      icon: Icons.people_outline,
      faqs: [
        FAQ(
          question: 'How do I search for a patient?',
          answer: 'You can search for patients using:\n\n• Patient name\n• Phone number\n• National ID\n• Address\n\nUse the search bar on the Patient List screen or tap the search icon for advanced search options.',
        ),
        FAQ(
          question: 'How do I update patient information?',
          answer: 'To update patient information:\n\n1. Find the patient in the Patient List\n2. Tap on the patient name\n3. In Patient Details, tap the edit icon\n4. Make necessary changes\n5. Save the updates\n\nChanges will sync automatically when online.',
        ),
        FAQ(
          question: 'What if a patient is not available during visit?',
          answer: 'If a patient is not available:\n\n1. In New Visit screen, toggle "Patient Found" to OFF\n2. Select the reason (Not at home, Moved, etc.)\n3. Add notes about the situation\n4. Capture GPS location to verify visit attempt\n5. Save the visit record\n\nThis helps track visit attempts and patient availability patterns.',
        ),
      ],
    ),
    FAQCategory(
      title: 'Data & Security',
      icon: Icons.security,
      faqs: [
        FAQ(
          question: 'Is my data secure?',
          answer: 'Yes, your data is protected with:\n\n• End-to-end encryption\n• Secure cloud storage\n• Regular backups\n• Access controls\n• HIPAA compliance\n\nAll patient data is handled according to healthcare privacy standards.',
        ),
        FAQ(
          question: 'Can I work without internet?',
          answer: 'Yes! The app works offline:\n\n• All features work without internet\n• Data is stored locally on your device\n• Automatic sync when connection is restored\n• Offline indicators show sync status\n\nEnable "Offline Mode" in settings for extended offline work.',
        ),
        FAQ(
          question: 'How do I backup my data?',
          answer: 'Data backup happens automatically:\n\n• Real-time cloud backup when online\n• Local device storage as backup\n• Export options in Settings\n• Recovery options available\n\nContact support if you need to restore data.',
        ),
      ],
    ),
    FAQCategory(
      title: 'Technical Issues',
      icon: Icons.build_outlined,
      faqs: [
        FAQ(
          question: 'The app is running slowly',
          answer: 'To improve app performance:\n\n1. Clear app cache in Settings\n2. Close other apps running in background\n3. Restart the app\n4. Check available storage space\n5. Update to latest app version\n\nIf issues persist, contact technical support.',
        ),
        FAQ(
          question: 'GPS location is not working',
          answer: 'To fix GPS issues:\n\n1. Check location permissions in device settings\n2. Enable high accuracy location mode\n3. Go outside for better signal\n4. Restart location services\n5. Restart the app\n\nLocation is required for visit verification.',
        ),
        FAQ(
          question: 'Photos are not saving',
          answer: 'To fix photo issues:\n\n1. Check camera permissions\n2. Check storage permissions\n3. Ensure sufficient storage space\n4. Try restarting the app\n5. Check if camera is working in other apps\n\nContact support if camera issues continue.',
        ),
      ],
    ),
  ];

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
    _tabController = TabController(length: 2, vsync: this);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<FAQ> _getFilteredFAQs() {
    if (_searchQuery.isEmpty) return [];
    
    List<FAQ> filteredFAQs = [];
    for (var category in _faqCategories) {
      for (var faq in category.faqs) {
        if (faq.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            faq.answer.toLowerCase().contains(_searchQuery.toLowerCase())) {
          filteredFAQs.add(faq);
        }
      }
    }
    return filteredFAQs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MadadgarTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Help & FAQ',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: MadadgarTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'FAQ', icon: Icon(Icons.help_outline)),
            Tab(text: 'Contact', icon: Icon(Icons.support_agent)),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildFAQTab(),
            _buildContactTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQTab() {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search FAQs...',
              hintStyle: GoogleFonts.poppins(color: Colors.grey),
              prefixIcon: Icon(Icons.search, color: MadadgarTheme.primaryColor),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: MadadgarTheme.primaryColor, width: 2),
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        
        // FAQ content
        Expanded(
          child: _searchQuery.isNotEmpty 
              ? _buildSearchResults()
              : _buildFAQCategories(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    final filteredFAQs = _getFilteredFAQs();
    
    if (filteredFAQs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No FAQs found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or browse categories',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredFAQs.length,
      itemBuilder: (context, index) {
        return _buildFAQItem(filteredFAQs[index]);
      },
    );
  }

  Widget _buildFAQCategories() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _faqCategories.length,
      itemBuilder: (context, index) {
        return _buildFAQCategoryCard(_faqCategories[index]);
      },
    );
  }

  Widget _buildFAQCategoryCard(FAQCategory category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Icon(category.icon, color: MadadgarTheme.primaryColor),
        title: Text(
          category.title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          '${category.faqs.length} questions',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        children: category.faqs.map((faq) => _buildFAQItem(faq)).toList(),
      ),
    );
  }

  Widget _buildFAQItem(FAQ faq) {
    return ExpansionTile(
      title: Text(
        faq.question,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            faq.answer,
            style: GoogleFonts.poppins(
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Emergency contact card
          _buildEmergencyContactCard(),
          
          const SizedBox(height: 16),
          
          // Support contact card
          _buildSupportContactCard(),
          
          const SizedBox(height: 16),
          
          // Quick actions card
          _buildQuickActionsCard(),
          
          const SizedBox(height: 16),
          
          // Feedback card
          _buildFeedbackCard(),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.emergency, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  'Emergency Support',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(
              'For urgent technical issues or critical patient cases:',
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 12),
            
            _buildContactButton(
              icon: Icons.phone,
              label: 'Emergency Hotline',
              value: '+92 111 123 456',
              color: Colors.red.shade700,
              onTap: () => _makePhoneCall('+92 111 123 456'),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              '24/7 Emergency Support Available',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportContactCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.support_agent, color: MadadgarTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Technical Support',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildContactButton(
              icon: Icons.phone,
              label: 'Support Phone',
              value: '+92 42 123 4567',
              color: MadadgarTheme.primaryColor,
              onTap: () => _makePhoneCall('+92 42 123 4567'),
            ),
            
            const SizedBox(height: 12),
            
            _buildContactButton(
              icon: Icons.email,
              label: 'Support Email',
              value: 'support@chwapp.org',
              color: MadadgarTheme.primaryColor,
              onTap: () => _sendEmail('support@chwapp.org'),
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MadadgarTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support Hours:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monday - Friday: 9:00 AM - 6:00 PM\nSaturday: 10:00 AM - 2:00 PM\nSunday: Closed',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: MadadgarTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildQuickActionButton(
              icon: Icons.bug_report,
              title: 'Report a Bug',
              subtitle: 'Found an issue? Let us know',
              onTap: () => _reportBug(),
            ),
            
            _buildQuickActionButton(
              icon: Icons.lightbulb_outline,
              title: 'Feature Request',
              subtitle: 'Suggest new features',
              onTap: () => _requestFeature(),
            ),
            
            _buildQuickActionButton(
              icon: Icons.download,
              title: 'Download User Manual',
              subtitle: 'Complete app guide (PDF)',
              onTap: () => _downloadManual(),
            ),
            
            _buildQuickActionButton(
              icon: Icons.video_library,
              title: 'Video Tutorials',
              subtitle: 'Watch how-to videos',
              onTap: () => _openVideoTutorials(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.feedback, color: MadadgarTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Feedback',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Help us improve the app by sharing your feedback',
              style: GoogleFonts.poppins(
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rateFiveStars(),
                    icon: const Icon(Icons.star, color: Colors.amber),
                    label: Text(
                      'Rate 5 Stars',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _provideFeedback(),
                    icon: const Icon(Icons.comment),
                    label: Text(
                      'Send Feedback',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MadadgarTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(color: MadadgarTheme.primaryColor),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.launch, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
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

  // Action methods
  void _makePhoneCall(String phoneNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Would dial: $phoneNumber',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }

  void _sendEmail(String email) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Would open email to: $email',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }

  void _reportBug() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Bug reporting feature coming soon!',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }

  void _requestFeature() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Feature request form coming soon!',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }

  void _downloadManual() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'User manual download coming soon!',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }

  void _openVideoTutorials() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Video tutorials coming soon!',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }

  void _rateFiveStars() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Thank You!',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Thank you for your 5-star rating! Your feedback helps us improve.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: MadadgarTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  void _provideFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Feedback form coming soon!',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }
}

// Data models
class FAQCategory {
  final String title;
  final IconData icon;
  final List<FAQ> faqs;

  FAQCategory({
    required this.title,
    required this.icon,
    required this.faqs,
  });
}

class FAQ {
  final String question;
  final String answer;

  FAQ({
    required this.question,
    required this.answer,
  });
}
