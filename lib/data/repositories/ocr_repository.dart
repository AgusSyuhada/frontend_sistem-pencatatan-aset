import 'dart:typed_data';
import 'dart:developer' as developer;
import '../remote/api_exception.dart';
import '../remote/services/ocr_service.dart';
import '../local/preferences/session_manager.dart';
import '../models/response/ocr_response.dart';
import 'auth_repository.dart';

class OcrRepository {
  final OcrService _service;
  final SessionManager _sessionManager;
  final AuthRepository _authRepository;

  OcrRepository(this._service, this._sessionManager, this._authRepository);

  Future<String> _getToken() async {
    final token = await _sessionManager.getToken();
    if (token == null) {
      throw Exception("Token tidak ditemukan. Silakan login kembali.");
    }
    return token;
  }

  Future<T> _executeWithRefresh<T>(
    Future<T> Function(String token) apiCall, {
    String functionName = 'UserRepository',
  }) async {
    try {
      final token = await _getToken();

      return await apiCall(token);
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
          "Token Expired (401/Unauthorized/Expired) di $functionName. Mencoba refresh...",
          name: 'UserRepository',
        );

        try {
          final newToken = await _authRepository.performRefreshToken();

          developer.log(
            "Refresh berhasil di $functionName. Melakukan Retry request...",
            name: 'UserRepository',
          );

          return await apiCall(newToken);
        } catch (refreshError) {
          developer.log(
            "Gagal Refresh Token di $functionName: $refreshError",
            name: 'UserRepository',
          );

          rethrow;
        }
      }

      rethrow;
    }
  }

  Future<OcrResponse> scanImage(Uint8List imageBytes) {
    return _executeWithRefresh(
      (token) => _service.scanAsset(imageBytes, token),
      functionName: 'scanImage',
    );
  }
}
