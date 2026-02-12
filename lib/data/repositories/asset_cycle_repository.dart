import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import '../models/request/asset_cycle/asset_cycle_update_request.dart';
import '../models/request/asset_cycle/create_period_request.dart';
import '../models/request/asset_cycle/update_period_request.dart';
import '../models/response/asset_cycle/asset_cycle_list_response.dart';
import '../models/response/asset_cycle/list_asset_cycle_response.dart';
import '../models/response/asset_cycle/period_stats_response.dart';
import '../models/response/asset_cycle/single_asset_cycle_response.dart';
import '../remote/api_exception.dart';
import '../remote/services/asset_cycle_service.dart';
import '../local/preferences/session_manager.dart';
import '../models/response/message_response.dart';
import 'auth_repository.dart';

class AssetCycleRepository {
  final AssetCycleService _service;
  final SessionManager _sessionManager;
  final AuthRepository _authRepository;

  AssetCycleRepository(
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
    String functionName = 'AssetCycleRepository',
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
          name: 'AssetCycleRepository',
        );

        try {
          final newToken = await _authRepository.performRefreshToken();

          developer.log(
            "Refresh berhasil di $functionName. Melakukan Retry request...",
            name: 'AssetCycleRepository',
          );

          return await apiCall(newToken);
        } catch (refreshError) {
          developer.log(
            "Gagal Refresh Token di $functionName: $refreshError",
            name: 'AssetCycleRepository',
          );

          rethrow;
        }
      }

      rethrow;
    }
  }

  Future<PeriodStatsResponse> getPeriodStats(int year, int cycle) {
    return _executeWithRefresh(
      (token) => _service.getPeriodStats(token, year, cycle),
      functionName: 'getPeriodStats',
    );
  }

  Future<AssetCycleListResponse> getPeriods({
    String? query,
    int limit = 20,
    int offset = 0,
  }) {
    return _executeWithRefresh(
      (token) => _service.getPeriods(
        token,
        query: query,
        limit: limit,
        offset: offset,
      ),
      functionName: 'getPeriods',
    );
  }

  Future<MessageResponse> createPeriod(CreatePeriodRequest request) {
    return _executeWithRefresh(
      (token) => _service.createPeriod(token, request),
      functionName: 'createPeriod',
    );
  }

  Future<MessageResponse> updatePeriodAssets(
    int year,
    int cycle,
    UpdatePeriodRequest request,
  ) {
    return _executeWithRefresh(
      (token) => _service.updatePeriodAssets(token, year, cycle, request),
      functionName: 'updatePeriodAssets',
    );
  }

  Future<MessageResponse> deletePeriod(int year, int cycle) {
    return _executeWithRefresh(
      (token) => _service.deletePeriod(token, year, cycle),
      functionName: 'deletePeriod',
    );
  }

  Future<ListAssetCycleResponse> getAssetsByCycle(
    int year,
    int cycle, {
    String? query,
    List<int>? locationIds,
    List<int>? conditionIds,
    int limit = 20,
    int offset = 0,
  }) {
    return _executeWithRefresh(
      (token) => _service.getAssetsByCycle(
        token,
        year,
        cycle,
        query: query,
        locationIds: locationIds,
        conditionIds: conditionIds,
        limit: limit,
        offset: offset,
      ),
      functionName: 'getAssetsByCycle',
    );
  }

  Future<SingleAssetCycleResponse> getAssetDetail(
    int year,
    int cycle,
    String assetNumber,
  ) {
    return _executeWithRefresh(
      (token) => _service.getAssetDetail(token, year, cycle, assetNumber),
      functionName: 'getAssetDetail',
    );
  }

  Future<SingleAssetCycleResponse> updateAsset(
    int year,
    int cycle,
    String assetNumber,
    AssetCycleUpdate request, {
    File? assetPhoto,
    File? codePhoto,
    File? locationPhoto,
  }) {
    return _executeWithRefresh(
      (token) => _service.updateAssetCycle(
        token,
        year,
        cycle,
        assetNumber,
        request,
        assetPhoto: assetPhoto,
        codePhoto: codePhoto,
        locationPhoto: locationPhoto,
      ),
      functionName: 'updateAsset',
    );
  }

  Future<MessageResponse> deleteAssetFromCycle(
    int year,
    int cycle,
    String assetNumber,
  ) {
    return _executeWithRefresh(
      (token) => _service.deleteAssetFromCycle(token, year, cycle, assetNumber),
      functionName: 'deleteAssetFromCycle',
    );
  }

  Future<Uint8List> downloadReport(int year, int cycle) {
    return _executeWithRefresh(
      (token) => _service.downloadCycleReport(token, year, cycle),
      functionName: 'downloadReport',
    );
  }
}
