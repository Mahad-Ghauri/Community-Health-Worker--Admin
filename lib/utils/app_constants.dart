class AppConstants {
  // App Information
  static const String appName = 'CHW Admin';
  static const String appVersion = '1.0.0';
  
  // Validation Constants
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
  static const int maxEmailLength = 100;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const double defaultElevation = 2.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
  
  // Breakpoints for responsive design
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1200;
  
  // Error Messages
  static const String internetError = 'Please check your internet connection';
  static const String genericError = 'Something went wrong. Please try again.';
  static const String unauthorizedError = 'You are not authorized to perform this action';
  
  // Success Messages
  static const String loginSuccess = 'Welcome back!';
  static const String signupSuccess = 'Account created successfully!';
  static const String logoutSuccess = 'You have been logged out';
  
  // Firebase Collection Names
  static const String accountsCollection = 'accounts';
  static const String facilitiesCollection = 'facilities';
  static const String reportsCollection = 'reports';
}

class AppHelpers {
  // Format date to readable string
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  // Format time to readable string
  static String formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  // Get time ago string
  static String getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
  
  // Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
  
  // Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }
  
  // Validate phone format (basic)
  static bool isValidPhone(String phone) {
    return RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(phone);
  }
  
  // Generate initials from name
  static String getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[words.length - 1][0]}'.toUpperCase();
  }
}