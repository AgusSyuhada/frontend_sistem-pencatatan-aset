import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../api_exception.dart';
import '../../models/request/auth/login_request.dart';
import '../../models/request/auth/logout_request.dart';
import '../../models/request/auth/refresh_token_request.dart';
import '../../models/request/auth/forgot_password_request.dart';
import '../../models/request/auth/verify_otp_request.dart';
import '../../models/request/auth/reset_password_request.dart';
import '../../models/response/auth/auth_response.dart';
import '../../models/response/auth/logout_response.dart';
import '../../models/response/message_response.dart';
import '../../models/response/auth/verify_otp_response.dart';

class AuthService {
  String _parseErrorMessage(http.Response response) {
    String finalMessage = 'Terjadi kesalahan (Status: ${response.statusCode})';

    try {
      developer.log(
        "SERVER ERROR (${response.statusCode}): ${response.body}",
        name: 'AuthService',
      );

      final body = jsonDecode(response.body);

      if (body is Map<String, dynamic>) {
        if (body.containsKey('detail') && body['detail'] != null) {
          final detail = body['detail'];

          if (detail is List && detail.isNotEmpty) {
            if (detail[0] is Map && detail[0].containsKey('msg')) {
              finalMessage = detail[0]['msg'];
            } else {
              finalMessage = detail.toString();
            }
          } else {
            finalMessage = detail.toString();
          }
        } else if (body.containsKey('message') && body['message'] != null) {
          finalMessage = body['message'].toString();
        }
      }
    } catch (e) {
      developer.log("PARSING ERROR: $e", name: 'AuthService');
    }

    return finalMessage;
  }

  Future<AuthResponse> login(LoginRequest request) async {
    final url = Uri.parse(ApiConfig.login);

    try {
      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(jsonDecode(response.body));
      } else {
        final errorMessage = _parseErrorMessage(response);
        throw errorMessage;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<LogoutResponse> logout(String token, LogoutRequest request) async {
    final url = Uri.parse(ApiConfig.logout);
    try {
      final response = await http.post(
        url,
        headers: {...ApiConfig.headers, 'Authorization': 'Bearer $token'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return LogoutResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      throw Exception('Logout Gagal: $e');
    }
  }

  Future<AuthResponse> refreshToken(RefreshTokenRequest request) async {
    final url = Uri.parse(ApiConfig.refresh);
    try {
      developer.log("Mencoba refresh token...", name: 'AuthService');

      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode(request.toJson()),
      );

      developer.log(
        "Response Refresh: ${response.statusCode} - ${response.body}",
        name: 'AuthService',
      );

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(jsonDecode(response.body));
      } else {
        throw ApiException(response.statusCode, _parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<MessageResponse> forgotPassword(ForgotPasswordRequest request) async {
    final url = Uri.parse(ApiConfig.forgotPassword);

    try {
      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        return MessageResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<VerifyOtpResponse> verifyOtp(VerifyOtpRequest request) async {
    final url = Uri.parse(ApiConfig.verifyOtp);

    try {
      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return VerifyOtpResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<MessageResponse> resetPassword(ResetPasswordRequest request) async {
    final url = Uri.parse(ApiConfig.resetPassword);
    try {
      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return MessageResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }
}
