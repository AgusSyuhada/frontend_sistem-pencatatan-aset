import 'dart:developer' as developer;
import '../local/preferences/session_manager.dart';
import '../models/request/lookup/team_create_request.dart';
import '../models/request/lookup/manufacturer_create_request.dart';
import '../models/request/lookup/location_create_request.dart';
import '../models/request/lookup/costcenter_create_request.dart';
import '../models/response/lookup/team_model.dart';
import '../models/response/lookup/manufacturer_model.dart';
import '../models/response/lookup/condition_model.dart';
import '../models/response/lookup/location_model.dart';
import '../models/response/lookup/costcenter_model.dart';
import '../remote/api_exception.dart';
import '../remote/services/lookup_service.dart';
import 'auth_repository.dart';

class LookupRepository {
  final LookupService _service;
  final SessionManager _sessionManager;
  final AuthRepository _authRepository;

  LookupRepository(this._service, this._sessionManager, this._authRepository);

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

  Future<List<TeamModel>> getTeams({String? query}) {
    return _executeWithRefresh(
      (token) => _service.getTeams(token, query: query),
      functionName: 'getTeams',
    );
  }

  Future<TeamModel> createTeam(TeamCreateRequest request) {
    return _executeWithRefresh(
      (token) => _service.createTeam(token, request),
      functionName: 'createTeam',
    );
  }

  Future<List<ManufacturerModel>> getManufacturers({String? query}) {
    return _executeWithRefresh(
      (token) => _service.getManufacturers(token, query: query),
      functionName: 'getManufacturers',
    );
  }

  Future<ManufacturerModel> createManufacturer(
    ManufacturerCreateRequest request,
  ) {
    return _executeWithRefresh(
      (token) => _service.createManufacturer(token, request),
      functionName: 'createManufacturer',
    );
  }

  Future<List<ConditionModel>> getConditions({String? query}) {
    return _executeWithRefresh(
      (token) => _service.getConditions(token, query: query),
      functionName: 'getConditions',
    );
  }

  Future<List<CostCenterModel>> getCostCenters({String? query}) {
    return _executeWithRefresh(
      (token) => _service.getCostCenters(token, query: query),
      functionName: 'getCostCenters',
    );
  }

  Future<CostCenterModel> createCostCenter(CostcenterCreateRequest request) {
    return _executeWithRefresh(
      (token) => _service.createCostCenter(token, request),
      functionName: 'createCostCenter',
    );
  }

  Future<List<LocationModel>> getLocations({String? area, String? location}) {
    return _executeWithRefresh(
      (token) => _service.getLocations(token, area: area, location: location),
      functionName: 'getLocations',
    );
  }

  Future<LocationModel> createLocation(LocationCreateRequest request) {
    return _executeWithRefresh(
      (token) => _service.createLocation(token, request),
      functionName: 'createLocation',
    );
  }
}
