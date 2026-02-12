import 'dart:developer' as developer;
import '../models/request/asset_master/asset_create_request.dart';
import '../models/request/asset_master/asset_update_request.dart';
import '../models/response/asset_master/asset_list_response.dart';
import '../models/response/asset_master/single_asset_respone.dart';
import '../remote/api_exception.dart';
import '../remote/services/asset_master_service.dart';
import '../local/preferences/session_manager.dart';
import '../models/response/message_response.dart';
import 'auth_repository.dart';

class AssetMasterRepository {
  final AssetMasterService _service;
  final SessionManager _sessionManager;
  final AuthRepository _authRepository;

  AssetMasterRepository(
    this._service,
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

  Future<AssetListResponse> getAll({
    String? query,
    bool includeInactive = false,
    List<int>? locationIds,
    List<int>? conditionIds,
    int limit = 20,
    int offset = 0,
  }) {
    return _executeWithRefresh(
      (token) => _service.getAll(
        token,
        query: query,
        includeInactive: includeInactive,
        locationIds: locationIds,
        conditionIds: conditionIds,
        limit: limit,
        offset: offset,
      ),
      functionName: 'getAll',
    );
  }

  Future<SingleAssetResponse> getOne(String assetNumber) {
    return _executeWithRefresh(
      (token) => _service.getOne(token, assetNumber),
      functionName: 'getOne',
    );
  }

  Future<SingleAssetResponse> create(AssetCreateRequest request) {
    return _executeWithRefresh(
      (token) => _service.create(token, request),
      functionName: 'create',
    );
  }

  Future<SingleAssetResponse> update(
    String assetNumber,
    AssetUpdateRequest request,
  ) {
    return _executeWithRefresh(
      (token) => _service.update(token, assetNumber, request),
      functionName: 'update',
    );
  }

  Future<MessageResponse> reactivate(String assetNumber) {
    return _executeWithRefresh(
      (token) => _service.reactivate(token, assetNumber),
      functionName: 'reactivate',
    );
  }

  Future<MessageResponse> deactivate(String assetNumber) {
    return _executeWithRefresh(
      (token) => _service.deactivate(token, assetNumber),
      functionName: 'deactivate',
    );
  }
}
