import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../../config/api_config.dart';
import '../../models/request/asset_master/upload_asset_request.dart';
import '../../models/response/message_response.dart';

class UploadService {
  String _parseErrorMessage(http.Response response) {
    String finalMessage = 'Terjadi kesalahan (Status: ${response.statusCode})';

    try {
      developer.log(
        "UPLOAD ERROR (${response.statusCode}): ${response.body}",
        name: 'UploadService',
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
      developer.log("PARSING ERROR: $e", name: 'UploadService');
    }

    return finalMessage;
  }

  Future<MessageResponse> uploadProfilePicture(File file, String token) async {
    final url = Uri.parse(ApiConfig.uploadProfilePicture);

    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';

    final mimeTypeData = lookupMimeType(file.path)?.split('/');

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: mimeTypeData != null
            ? MediaType(mimeTypeData[0], mimeTypeData[1])
            : null,
      ),
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return MessageResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<MessageResponse> uploadAssetPhoto(
    File file,
    UploadAssetRequest data,
    String token,
  ) async {
    final url = Uri.parse(ApiConfig.uploadAssetPhoto);

    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields.addAll(data.toMap());

    final mimeTypeData = lookupMimeType(file.path)?.split('/');
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: mimeTypeData != null
            ? MediaType(mimeTypeData[0], mimeTypeData[1])
            : null,
      ),
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return MessageResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }
}