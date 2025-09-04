// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chw_tb/config/theme.dart';

class PatientSearchScreen extends StatefulWidget {
  const PatientSearchScreen({super.key});

  @override
  State<PatientSearchScreen> createState() => _PatientSearchScreenState();
}

class _PatientSearchScreenState extends State<PatientSearchScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  String _searchType = 'name';
  bool _isSearching = false;
  
  final List<String> _searchTypes = [
    'name',
    'phone',
    'address',
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
    _fadeController.forward();
    
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _getSearchTypeDisplayName(String type) {
    switch (type) {
      case 'name':
        return 'Patient Name';
      case 'phone':
        return 'Phone Number';
      case 'address':
        return 'Address';
      default:
        return 'Patient Name';
    }
  }

  String _getSearchHint(String type) {
    switch (type) {
      case 'name':
        return 'Enter patient name...';
      case 'phone':
        return 'Enter phone number...';
      case 'address':
        return 'Enter address...';
      default:
        return 'Enter search term...';
    }
  }

  void _performSearch() {
    if (_searchController.text.trim().isEmpty) return;
    
    setState(() => _isSearching = true);
    
    // Simulate search delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MadadgarTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Search Patients',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: MadadgarTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
              icon: const Icon(Icons.clear),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Search section
            Container(
              color: MadadgarTheme.primaryColor,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search type selector
                  Text(
                    'Search by:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: _searchTypes.map((type) {
                      final isSelected = _searchType == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _searchType = type),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              _getSearchTypeDisplayName(type),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: isSelected 
                                    ? FontWeight.w600 
                                    : FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Search input
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: _getSearchHint(_searchType),
                      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                      prefixIcon: Icon(
                        _getSearchIcon(_searchType),
                        color: Colors.grey,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                ),
                                IconButton(
                                  onPressed: _performSearch,
                                  icon: Icon(
                                    Icons.search,
                                    color: MadadgarTheme.primaryColor,
                                  ),
                                ),
                              ],
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    keyboardType: _searchType == 'phone' 
                        ? TextInputType.phone 
                        : TextInputType.text,
                    onChanged: (value) => setState(() {}),
                    onSubmitted: (value) => _performSearch(),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Voice search button
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Voice search coming soon!',
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.mic, color: Colors.white),
                      label: Text(
                        'Voice Search',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Search results
            Expanded(
              child: _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSearchIcon(String type) {
    switch (type) {
      case 'name':
        return Icons.person_search;
      case 'phone':
        return Icons.phone;
      case 'address':
        return Icons.location_on;
      default:
        return Icons.search;
    }
  }

  Widget _buildSearchResults() {
    if (_searchController.text.trim().isEmpty) {
      return _buildInitialState();
    }
    
    if (_isSearching) {
      return _buildLoadingState();
    }
    
    return _buildNoResultsState();
  }

  Widget _buildInitialState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Recent searches section
          if (_hasRecentSearches()) ...[
            Row(
              children: [
                Text(
                  'Recent Searches',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearRecentSearches,
                  child: Text(
                    'Clear All',
                    style: GoogleFonts.poppins(
                      color: MadadgarTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRecentSearchesList(),
            const SizedBox(height: 32),
          ],
          
          // Search tips
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Search for Patients',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter patient name, phone number, or address to find them',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildSearchTips(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(MadadgarTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Searching patients...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Patients Found',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No patients match your search criteria.\nTry a different search term.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/register-patient'),
            icon: const Icon(Icons.person_add),
            label: Text(
              'Register New Patient',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: MadadgarTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTips() {
    final tips = [
      'Use full name for better results',
      'Include area code for phone search',
      'Try partial address or landmarks',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Tips',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ...tips.map((tip) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: MadadgarTheme.secondaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  bool _hasRecentSearches() {
    // Placeholder - will be implemented with actual storage
    return false;
  }

  Widget _buildRecentSearchesList() {
    // Placeholder for recent searches
    return const SizedBox.shrink();
  }

  void _clearRecentSearches() {
    // Placeholder for clearing recent searches
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Recent searches cleared',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }
}
