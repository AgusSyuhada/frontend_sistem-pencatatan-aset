import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/app_constants.dart';
import '../../models/response/user/user_response.dart';

class SessionManager {
  
  Future<void> saveDeviceModel(String deviceModel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyDeviceModel, deviceModel);
  }

  Future<String?> getDeviceModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyDeviceModel);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyToken, token);
    await prefs.setBool(AppConstants.keyIsLoggedIn, true);
  }

  Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyRefreshToken, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyToken);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyRefreshToken);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyToken);
    await prefs.remove(AppConstants.keyRefreshToken);
    await prefs.remove(AppConstants.keyIsLoggedIn);
    await prefs.remove(AppConstants.keyUserRaw);
  }

  Future<bool> haveAgreedToTerms() async {
    final prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool(AppConstants.keyIsFirstTime) ?? true;
    return !isFirstTime;
  }

  Future<void> setAgreedToTerms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsFirstTime, false);
  }

  Future<void> saveUser(UserResponse user) async {
    final prefs = await SharedPreferences.getInstance();
    String userJson = jsonEncode(user.toJson());
    await prefs.setString(AppConstants.keyUserRaw, userJson);
  }

  Future<UserResponse?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString(AppConstants.keyUserRaw);
    if (userJson != null) {
      return UserResponse.fromJson(jsonDecode(userJson));
    }
    return null;
  }
}
