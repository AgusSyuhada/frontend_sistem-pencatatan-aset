import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../models/request/lookup/team_create_request.dart';
import '../../models/request/lookup/manufacturer_create_request.dart';
import '../../models/request/lookup/location_create_request.dart';
import '../../models/request/lookup/costcenter_create_request.dart';
import '../../models/response/lookup/team_model.dart';
import '../../models/response/lookup/manufacturer_model.dart';
import '../../models/response/lookup/condition_model.dart';
import '../../models/response/lookup/location_model.dart';
import '../../models/response/lookup/costcenter_model.dart';

class LookupService {
  Map<String, String> _headers(String token) {
    return {...ApiConfig.headers, 'Authorization': 'Bearer $token'};
  }

  void _handleError(http.Response response) {
    if (response.statusCode == 401) {
      throw Exception("401 Unauthorized");
    } else if (response.statusCode == 409) {
      final body = jsonDecode(response.body);
      throw Exception(body['detail'] ?? "Data sudah ada.");
    }
    try {
      final body = jsonDecode(response.body);
      throw Exception(body['detail'] ?? 'Error: ${response.statusCode}');
    } catch (e) {
      throw Exception('Server Error: ${response.statusCode}');
    }
  }

  Future<List<TeamModel>> getTeams(String token, {String? query}) async {
    Uri uri = Uri.parse(ApiConfig.lookupTeams);
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: {'q': query});
    }

    final response = await http.get(uri, headers: _headers(token));

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => TeamModel.fromJson(e)).toList();
    } else {
      _handleError(response);
      throw Exception("Unknown Error");
    }
  }

  Future<TeamModel> createTeam(String token, TeamCreateRequest request) async {
    final response = await http.post(
      Uri.parse(ApiConfig.lookupTeams),
      headers: _headers(token),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 201) {
      return TeamModel.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception("Unknown Error");
    }
  }

  Future<List<ManufacturerModel>> getManufacturers(
    String token, {
    String? query,
  }) async {
    Uri uri = Uri.parse(ApiConfig.lookupManufacturers);
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: {'q': query});
    }

    final response = await http.get(uri, headers: _headers(token));

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => ManufacturerModel.fromJson(e)).toList();
    } else {
      _handleError(response);
      throw Exception("Unknown Error");
    }
  }

  Future<ManufacturerModel> createManufacturer(
    String token,
    ManufacturerCreateRequest request,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConfig.lookupManufacturers),
      headers: _headers(token),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 201) {
      return ManufacturerModel.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception("Unknown Error");
    }
  }

  Future<List<ConditionModel>> getConditions(
    String token, {
    String? query,
  }) async {
    Uri uri = Uri.parse(ApiConfig.lookupConditions);
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: {'q': query});
    }

    final response = await http.get(uri, headers: _headers(token));

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => ConditionModel.fromJson(e)).toList();
    } else {
      _handleError(response);
      throw Exception("Unknown Error");
    }
  }

  Future<List<CostCenterModel>> getCostCenters(
    String token, {
    String? query,
  }) async {
    Uri uri = Uri.parse(ApiConfig.lookupCostCenter);
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: {'q': query});
    }

    final response = await http.get(uri, headers: _headers(token));

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => CostCenterModel.fromJson(e)).toList();
    } else {
      _handleError(response);
      throw Exception("Unknown Error");
    }
  }

  Future<CostCenterModel> createCostCenter(
    String token,
    CostcenterCreateRequest request,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConfig.lookupCostCenter),
      headers: _headers(token),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 201) {
      return CostCenterModel.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception("Unknown Error");
    }
  }

  Future<List<LocationModel>> getLocations(
    String token, {
    String? area,
    String? location,
  }) async {
    Uri uri = Uri.parse(ApiConfig.lookupLocations);

    final Map<String, String> queryParams = {};
    if (area != null && area.isNotEmpty) queryParams['area'] = area;
    if (location != null && location.isNotEmpty) {
      queryParams['location'] = location;
    }

    if (queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final response = await http.get(uri, headers: _headers(token));

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => LocationModel.fromJson(e)).toList();
    } else {
      _handleError(response);
      throw Exception("Unknown Error");
    }
  }

  Future<LocationModel> createLocation(
    String token,
    LocationCreateRequest request,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConfig.lookupLocations),
      headers: _headers(token),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 201) {
      return LocationModel.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception("Unknown Error");
    }
  }
}
