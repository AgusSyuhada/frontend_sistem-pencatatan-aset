import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../../config/api_config.dart';
import '../../models/request/asset_master/asset_create_request.dart';
import '../../models/request/asset_master/asset_update_request.dart';
import '../../models/response/asset_master/asset_list_response.dart';
import '../../models/response/asset_master/single_asset_respone.dart';
import '../../models/response/message_response.dart';

class AssetMasterService {
  String _parseErrorMessage(http.Response response) {
    String finalMessage = 'Terjadi kesalahan (Status: ${response.statusCode})';

    try {
      developer.log(
        "SERVER ERROR (${response.statusCode}): ${response.body}",
        name: 'AssetMasterService',
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
      developer.log("PARSING ERROR: $e", name: 'AssetMasterService');
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

  Future<AssetListResponse> getAll(
    String token, {
    String? query,
    bool includeInactive = false,
    List<int>? locationIds,
    List<int>? conditionIds,
    int limit = 20,
    int offset = 0,
  }) async {
    final Map<String, dynamic> queryParams = {
      'include_inactive': includeInactive.toString(),
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
      ApiConfig.assets,
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {...ApiConfig.headers, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return AssetListResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<SingleAssetResponse> getOne(String token, String assetNumber) async {
    final url = Uri.parse(ApiConfig.assetDetail(assetNumber));
    try {
      final response = await http.get(
        url,
        headers: {...ApiConfig.headers, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return SingleAssetResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<SingleAssetResponse> create(
    String token,
    AssetCreateRequest requestData,
  ) async {
    final url = Uri.parse(ApiConfig.assets);
    final request = http.MultipartRequest('POST', url);

    request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(requestData.toFields());

    await _attachFile(request, 'asset_photo', requestData.assetPhoto);
    await _attachFile(request, 'code_photo', requestData.codePhoto);
    await _attachFile(request, 'location_photo', requestData.locationPhoto);

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return SingleAssetResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<SingleAssetResponse> update(
    String token,
    String assetNumber,
    AssetUpdateRequest requestData,
  ) async {
    final url = Uri.parse(ApiConfig.assetDetail(assetNumber));
    final request = http.MultipartRequest('PATCH', url);

    request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(requestData.toFields());

    await _attachFile(request, 'asset_photo', requestData.assetPhoto);
    await _attachFile(request, 'code_photo', requestData.codePhoto);
    await _attachFile(request, 'location_photo', requestData.locationPhoto);

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return SingleAssetResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<MessageResponse> reactivate(String token, String assetNumber) async {
    final url = Uri.parse(ApiConfig.assetReactivate(assetNumber));
    try {
      final response = await http.post(
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

  Future<MessageResponse> deactivate(String token, String assetNumber) async {
    final url = Uri.parse(ApiConfig.assetDeactivate(assetNumber));
    try {
      final response = await http.post(
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
}
