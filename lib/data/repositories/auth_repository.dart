import 'dart:io';
import 'dart:developer' as developer;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../models/request/auth/login_request.dart';
import '../models/request/auth/logout_request.dart';
import '../models/request/auth/forgot_password_request.dart';
import '../models/request/auth/verify_otp_request.dart';
import '../models/request/auth/reset_password_request.dart';
import '../models/request/auth/refresh_token_request.dart';
import '../models/response/auth/auth_response.dart';
import '../models/response/user/user_response.dart';
import '../models/response/auth/logout_response.dart';
import '../models/response/message_response.dart';
import '../models/response/auth/verify_otp_response.dart';
import '../remote/api_exception.dart';
import '../remote/services/auth_service.dart';
import '../local/preferences/session_manager.dart';

class AuthRepository {
  final AuthService _authService;
  final SessionManager _sessionManager;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  AuthRepository(this._authService, this._sessionManager);

  Future<String> _getRealDeviceModel() async {
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        return "${androidInfo.manufacturer} ${androidInfo.model}";
      } else if (Platform.isWindows) {
        WindowsDeviceInfo windowsInfo = await _deviceInfo.windowsInfo;
        return windowsInfo.productName;
      }
      return 'Unknown Platform';
    } catch (e) {
      return 'Generic Device';
    }
  }

  Future<String> _getRealLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('GPS tidak aktif. Mohon aktifkan lokasi.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen. Buka pengaturan.');
    }

    try {
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      return "${position.latitude},${position.longitude}";
    } catch (e) {
      throw Exception("Gagal mengambil titik koordinat: $e");
    }
  }

  Future<AuthResponse> login(String email, String password) async {
    final String deviceModel = await _getRealDeviceModel();
    final String coords = await _getRealLocation();

    await _sessionManager.saveDeviceModel(deviceModel);

    final request = LoginRequest(
      email: email,
      password: password,
      deviceModel: deviceModel,
      geoCoordinates: coords,
    );

    final response = await _authService.login(request);

    if (response.token.isNotEmpty) {
      await _sessionManager.saveToken(response.token);

      if (response.refreshToken != null && response.refreshToken!.isNotEmpty) {
        await _sessionManager.saveRefreshToken(response.refreshToken!);
      }
    }

    return response;
  }

  Future<LogoutResponse> logout() async {
    final token = await _sessionManager.getToken();
    final String currentDeviceModel = await _getRealDeviceModel();
    final request = LogoutRequest(deviceModel: currentDeviceModel);

    if (token == null) {
      await _sessionManager.clearSession();
      return LogoutResponse(message: "Sesi lokal sudah tidak ada.");
    }

    try {
      final response = await _authService.logout(token, request);
      await _sessionManager.clearSession();
      return response;
    } catch (e) {
      bool isUnauthorized = false;
      if (e is ApiException) {
        if (e.statusCode == 401) isUnauthorized = true;
      } else {
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains("401") ||
            errorMsg.contains("unauthorized") ||
            errorMsg.contains("expired")) {
          isUnauthorized = true;
        }
      }

      if (isUnauthorized) {
        developer.log(
          "Token expired saat logout, mencoba refresh...",
          name: 'AuthRepository',
        );

        try {
          final newToken = await performRefreshToken();

          final response = await _authService.logout(newToken, request);
          await _sessionManager.clearSession();
          return response;
        } catch (refreshError) {
          developer.log(
            "Gagal refresh saat logout: $refreshError",
            name: 'AuthRepository',
          );
          await _sessionManager.clearSession();
          return LogoutResponse(message: "Sesi server sudah berakhir.");
        }
      }

      rethrow;
    }
  }

  Future<UserResponse?> getLocalUserProfile() async {
    return await _sessionManager.getUser();
  }

  Future<String> performRefreshToken() async {
    final refreshToken = await _sessionManager.getRefreshToken();

    developer.log("Mencoba Refresh Token...", name: 'AuthRepository');

    if (refreshToken == null) {
      throw Exception("Tidak ada refresh token. Silakan login kembali.");
    }

    try {
      final request = RefreshTokenRequest(refreshToken: refreshToken);
      final newAuthData = await _authService.refreshToken(request);

      await _sessionManager.saveToken(newAuthData.token);
      developer.log("Access Token baru disimpan.", name: 'AuthRepository');

      if (newAuthData.refreshToken != null &&
          newAuthData.refreshToken!.isNotEmpty) {
        await _sessionManager.saveRefreshToken(newAuthData.refreshToken!);
        developer.log("Refresh Token dirotasi.", name: 'AuthRepository');
      }

      return newAuthData.token;
    } catch (e) {
      developer.log("Gagal Refresh Token: $e", name: 'AuthRepository');

      await _sessionManager.clearSession();
      throw Exception("Sesi Anda telah kedaluwarsa. Silakan login kembali.");
    }
  }

  Future<MessageResponse> requestForgotPassword(String email) async {
    final request = ForgotPasswordRequest(email: email);
    return await _authService.forgotPassword(request);
  }

  Future<VerifyOtpResponse> verifyOtp(String email, String otp) async {
    final request = VerifyOtpRequest(email: email, otp: otp);
    return await _authService.verifyOtp(request);
  }

  Future<MessageResponse> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    final request = ResetPasswordRequest(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );
    return await _authService.resetPassword(request);
  }
}