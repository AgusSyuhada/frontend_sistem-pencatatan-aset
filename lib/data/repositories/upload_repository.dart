import 'dart:io';
import 'dart:developer' as developer;
import '../models/request/asset_master/upload_asset_request.dart';
import '../models/response/message_response.dart';
import '../remote/api_exception.dart';
import '../remote/services/upload_service.dart';
import '../local/preferences/session_manager.dart';
import 'auth_repository.dart';

class UploadRepository {
  final UploadService _uploadService;
  final SessionManager _sessionManager;
  final AuthRepository _authRepository;

  UploadRepository(
    this._uploadService,
    this._sessionManager,
    this._authRepository,
  );

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

  Future<MessageResponse> uploadProfilePicture(File file) {
    return _executeWithRefresh(
      (token) => _uploadService.uploadProfilePicture(file, token),
      functionName: 'uploadProfilePicture',
    );
  }

  Future<MessageResponse> uploadAssetPhoto(File file, UploadAssetRequest data) {
    return _executeWithRefresh(
      (token) => _uploadService.uploadAssetPhoto(file, data, token),
      functionName: 'uploadAssetPhoto',
    );
  }
}
