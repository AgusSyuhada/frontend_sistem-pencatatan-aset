import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../../config/api_config.dart';
import '../../models/request/asset_cycle/asset_cycle_update_request.dart';
import '../../models/request/asset_cycle/create_period_request.dart';
import '../../models/request/asset_cycle/update_period_request.dart';
import '../../models/response/asset_cycle/asset_cycle_list_response.dart';
import '../../models/response/asset_cycle/list_asset_cycle_response.dart';
import '../../models/response/asset_cycle/single_asset_cycle_response.dart';
import '../../models/response/asset_cycle/period_stats_response.dart';
import '../../models/response/message_response.dart';

class AssetCycleService {
  String _parseErrorMessage(http.Response response) {
    String finalMessage = 'Terjadi kesalahan (Status: ${response.statusCode})';

    try {
      developer.log(
        "SERVER ERROR (${response.statusCode}): ${response.body}",
        name: 'AssetCycleService',
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
      developer.log("PARSING ERROR: $e", name: 'AssetCycleService');
    }

    return finalMessage;
  }

  Future<void> _attachFile(
    http.MultipartRequest request,
    String fieldName,
    File? file,
  ) async {
    if (file != null && await file.exists()) {
      final mimeTypeData = lookupMimeType(file.path)?.split('/');
      request.files.add(
        await http.MultipartFile.fromPath(
          fieldName,
          file.path,
          contentType: mimeTypeData != null
              ? MediaType(mimeTypeData[0], mimeTypeData[1])
              : null,
        ),
      );
    }
  }

  Future<PeriodStatsResponse> getPeriodStats(
    String token,
    int year,
    int cycle,
  ) async {
    final url = Uri.parse(ApiConfig.cycleStats(year, cycle));

    try {
      final response = await http.get(
        url,
        headers: {...ApiConfig.headers, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return PeriodStatsResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<AssetCycleListResponse> getPeriods(
    String token, {
    String? query,
    int limit = 20,
    int offset = 0,
  }) async {
    final Map<String, dynamic> queryParams = {
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (query != null && query.isNotEmpty) queryParams['q'] = query;

    final uri = Uri.parse(
      ApiConfig.cyclePeriods,
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {...ApiConfig.headers, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return AssetCycleListResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<MessageResponse> createPeriod(
    String token,
    CreatePeriodRequest request,
  ) async {
    final url = Uri.parse(ApiConfig.cyclePeriods);
    try {
      final response = await http.post(
        url,
        headers: {...ApiConfig.headers, 'Authorization': 'Bearer $token'},
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

  Future<MessageResponse> updatePeriodAssets(
    String token,
    int year,
    int cycle,
    UpdatePeriodRequest request,
  ) async {
    final url = Uri.parse(ApiConfig.cyclePeriodUpdate(year, cycle));
    try {
      final response = await http.patch(
        url,
        headers: {...ApiConfig.headers, 'Authorization': 'Bearer $token'},
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

  Future<MessageResponse> deletePeriod(
    String token,
    int year,
    int cycle,
  ) async {
    final url = Uri.parse(ApiConfig.cyclePeriodUpdate(year, cycle));
    try {
      final response = await http.delete(
        url,
        headers: {...ApiConfig.headers, 'Authorization': 'Bearer $token'},
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

  Future<ListAssetCycleResponse> getAssetsByCycle(
    String token,
    int year,
    int cycle, {
    String? query,
    List<int>? locationIds,
    List<int>? conditionIds,
    int limit = 20,
    int offset = 0,
  }) async {
    final Map<String, dynamic> queryParams = {
      'year': year.toString(),
      'cycle': cycle.toString(),
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    if (query != null && query.isNotEmpty) queryParams['q'] = query;

    if (locationIds != null && locationIds.isNotEmpty) {
      queryParams['location_ids'] = locationIds
          .map((e) => e.toString())
          .toList();
    }

    if (conditionIds != null && conditionIds.isNotEmpty) {
      queryParams['condition_ids'] = conditionIds
          .map((e) => e.toString())
          .toList();
    }

    final uri = Uri.parse(
      ApiConfig.cycleData,
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {...ApiConfig.headers, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return ListAssetCycleResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<SingleAssetCycleResponse> getAssetDetail(
    String token,
    int year,
    int cycle,
    String assetNumber,
  ) async {
    final url = Uri.parse(ApiConfig.cycleAssetDetail(year, cycle, assetNumber));
    try {
      final response = await http.get(
        url,
        headers: {...ApiConfig.headers, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return SingleAssetCycleResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<SingleAssetCycleResponse> updateAssetCycle(
    String token,
    int year,
    int cycle,
    String assetNumber,
    AssetCycleUpdate request, {
    File? assetPhoto,
    File? codePhoto,
    File? locationPhoto,
  }) async {
    final url = Uri.parse(ApiConfig.cycleAssetDetail(year, cycle, assetNumber));

    final multipartRequest = http.MultipartRequest('PATCH', url);

    multipartRequest.headers['Authorization'] = 'Bearer $token';

    multipartRequest.fields.addAll(request.toFormDataMap());

    await _attachFile(multipartRequest, 'asset_photo', assetPhoto);
    await _attachFile(multipartRequest, 'code_photo', codePhoto);
    await _attachFile(multipartRequest, 'location_photo', locationPhoto);

    try {
      final streamedResponse = await multipartRequest.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return SingleAssetCycleResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<MessageResponse> deleteAssetFromCycle(
    String token,
    int year,
    int cycle,
    String assetNumber,
  ) async {
    final url = Uri.parse(ApiConfig.cycleAssetDetail(year, cycle, assetNumber));

    try {
      final response = await http.delete(
        url,
        headers: {...ApiConfig.headers, 'Authorization': 'Bearer $token'},
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

  Future<Uint8List> downloadCycleReport(
    String token,
    int year,
    int cycle,
  ) async {
    final url = Uri.parse(ApiConfig.cycleDownloadReport(year, cycle));

    try {
      final response = await http.get(
        url,
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf',
        },
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }
}
