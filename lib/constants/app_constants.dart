class AppConstants {
  // Firestore Collections
  static const String usersCollection = 'accounts';
  static const String chwUsersCollection = 'chw_users';
  static const String patientsCollection = 'patients';
  static const String visitsCollection = 'visits';
  static const String facilitiesCollection = 'facilities';
  static const String auditLogsCollection = 'auditLogs';

  // User Roles
  static const String adminRole = 'admin';
  static const String staffRole = 'staff';
  static const String supervisorRole = 'supervisor';
  static const String chwRole = 'chw';

  // App Routes
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String dashboardRoute = '/dashboard';
  static const String usersRoute = '/users';
  static const String createUserRoute = '/users/create';
  static const String editUserRoute = '/users/edit';
  static const String userDetailsRoute = '/users/details';
  static const String facilitiesRoute = '/facilities';
  static const String createFacilityRoute = '/facilities/create';
  static const String editFacilityRoute = '/facilities/edit';
  static const String facilityDetailsRoute = '/facilities/details';
  static const String auditLogsRoute = '/audit-logs';
  static const String settingsRoute = '/settings';

  // Staff-side Routes
  static const String staffDashboardRoute = '/staff/dashboard';
  static const String assignPatientsRoute = '/staff/assign-patients';
  static const String facilityPatientsRoute = '/staff/facility-patients';
  static const String referralsRoute = '/staff/referrals';
  static const String createFollowupsRoute = '/staff/create-followups';
  static const String manageFollowupsRoute = '/staff/manage-followups';
  static const String patientDetailsRoute = '/staff/patient-details';
  static const String patientsRoute = '/staff/patient-list';
  static const String manageMedicationsRoute = '/staff/manage-medications';
  static const String contactScreeningRoute = '/staff/contact-screening';

  // Supervisor Routes
  static const String supervisorDashboardRoute = '/supervisor/dashboard';

  // Facility Types
  static const String hospitalType = 'hospital';
  static const String healthCenterType = 'health_center';
  static const String clinicType = 'clinic';

  // Visit Types
  static const String homeVisitType = 'home_visit';
  static const String followUpType = 'follow_up';
  static const String tracingType = 'tracing';
  static const String medicineDeliveryType = 'medicine_delivery';
  static const String counselingType = 'counseling';

  // TB Status Types
  static const String newlyDiagnosedStatus = 'newly_diagnosed';
  static const String onTreatmentStatus = 'on_treatment';
  static const String treatmentCompletedStatus = 'treatment_completed';
  static const String lostToFollowUpStatus = 'lost_to_followup';

  // CHW Status
  static const String activeStatus = 'active';
  static const String inactiveStatus = 'inactive';

  // Gender Options
  static const String maleGender = 'male';
  static const String femaleGender = 'female';
  static const String otherGender = 'other';

  // Services
  static const String tbTreatmentService = 'tb_treatment';
  static const String xrayService = 'xray';
  static const String labTestsService = 'lab_tests';

  // Performance Settings
  static const int defaultPageSize = 20;
  static const int maxRetryAttempts = 3;
  static const Duration cacheTimeout = Duration(minutes: 5);
  static const Duration debounceDelay = Duration(milliseconds: 500);

  // Responsive Breakpoints
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  // App Info
  static const String appName = 'CHW TB Management Admin';
  static const String appVersion = '1.0.0';
}

class UserRoles {
  static const String admin = AppConstants.adminRole;
  static const String staff = AppConstants.staffRole;
  static const String supervisor = AppConstants.supervisorRole;
  static const String chw = AppConstants.chwRole;

  static const Map<String, String> displayNames = {
    admin: 'Administrator',
    staff: 'Staff Member',
    supervisor: 'Supervisor',
    chw: 'Community Health Worker',
  };

  static String getDisplayName(String role) {
    return displayNames[role] ?? role.toUpperCase();
  }

  static List<String> get all => [admin, staff, supervisor];
  static List<String> get adminRoles => [admin, staff, supervisor];
}
