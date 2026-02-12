import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? "";

  static const int receiveTimeout = 30000;
  static const int connectionTimeout = 30000;

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Auth
  static String login = "$baseUrl/login";
  static String logout = "$baseUrl/logout";
  static String refresh = "$baseUrl/refresh";
  static String forgotPassword = "$baseUrl/forgot-password";
  static String verifyOtp = "$baseUrl/verify-otp";
  static String resetPassword = "$baseUrl/reset-password";

  // Assets Master
  static String assets = "$baseUrl/assets/";
  static String assetDetail(String assetNumber) =>
      "$baseUrl/assets/$assetNumber";
  static String assetReactivate(String assetNumber) =>
      "$baseUrl/assets/$assetNumber/reactivate";
  static String assetDeactivate(String assetNumber) =>
      "$baseUrl/assets/$assetNumber/deactivate";

  // Asset Cycle
  static String cyclePeriods = "$baseUrl/assets/periods";
  static String cyclePeriodUpdate(int year, int cycle) =>
      "$baseUrl/assets/periods/$year/$cycle";
  static String cycleStats(int year, int cycle) =>
      "$baseUrl/assets/periods/$year/$cycle/stats";
  static String cycleData = "$baseUrl/assets/cycle/data";
  static String cycleAssetDetail(int year, int cycle, String assetNumber) =>
      "$baseUrl/assets/cycle/$year/$cycle/$assetNumber";
  static String cycleDownloadReport(int year, int cycle) => '$baseUrl/assets/periods/$year/$cycle/report/excel';

  // OCR & Upload
  static String scanAsset = "$baseUrl/ocr/scan-asset-code";
  static String uploadProfilePicture = "$baseUrl/users/me/profile-picture";
  static String uploadAssetPhoto = "$baseUrl/upload/asset-photo";

  // Users
  static String get users => "$baseUrl/users/";
  static String get userMe => "$baseUrl/users/me";
  static String get userMePassword => "$baseUrl/users/me/password";
  static String userDetail(int userId) => "$baseUrl/users/$userId";
  // static String get roles => "$baseUrl/users/roles";
  static String adminResetPassword(int userId) =>
      "$baseUrl/users/$userId/reset-password";
  static String userDeactivate(int userId) =>
      "$baseUrl/users/$userId/deactivate";
  static String userReactivate(int userId) =>
      "$baseUrl/users/$userId/reactivate";

  // Lookups
  static String get lookups => "$baseUrl/lookups";
  static String get roles => "$lookups/roles";
  static String get lookupTeams => "$lookups/teams";
  static String get lookupManufacturers => "$lookups/manufacturers";
  static String get lookupConditions => "$lookups/conditions";
  static String get lookupLocations => "$lookups/locations";
  static String get lookupCostCenter => "$lookups/costcenters";
}
