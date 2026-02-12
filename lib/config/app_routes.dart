class AppRoutes {
  // Auth
  static const String splash = '/';
  static const String terms = '/terms';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerification = '/otp-verification';
  static const String resetPassword = '/reset-password';

  // Main
  static const String home = '/home';
  
  // Asset Master
  static const String assetList = '/asset-list';
  static const String assetDetail = '/asset-detail';
  static const String assetForm = '/asset-form';

  // Cycle / Opname
  static const String cycleList = '/cycle-list';
  static const String cycleCheck = '/cycle-check';
  static const String createPeriod = '/create-period';
  static const String assetCycleDetail = '/cycle-detail'; 
  static const String cycleStats = '/cycle-stats';

  // User Management
  static const String userList = '/user-list';
  static const String userDetail = '/user-detail';
  static const String userAdd = '/user-add';

  // Scan & Camera
  static const String scanCamera = '/scan-camera';
  static const String scanResult = '/scan-result';

  // Profile
  static const String profile = '/profile';
  static const String changePassword = '/change-password';
}