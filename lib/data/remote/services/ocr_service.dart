import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';
import '../../../config/api_config.dart';
import '../../models/response/ocr_response.dart';

class OcrService {
  String _parseErrorMessage(http.Response response) {
    String finalMessage =
        'Terjadi kesalahan OCR (Status: ${response.statusCode})';

    try {
      developer.log(
        "OCR ERROR (${response.statusCode}): ${response.body}",
        name: 'OcrService',
      );

      final body = jsonDecode(response.body);

      if (body is Map<String, dynamic>) {
        if (body.containsKey('detail') && body['detail'] != null) {
          final detail = body['detail'];

          if (detail is List && detail.isNotEmpty) {
            finalMessage = detail[0].toString();
          } else {
            finalMessage = detail.toString();
          }
        } else if (body.containsKey('message') && body['message'] != null) {
          finalMessage = body['message'].toString();
        }
      }
    } catch (e) {
      developer.log("PARSING ERROR: $e", name: 'OcrService');
    }

    return finalMessage;
  }

  Future<OcrResponse> scanAsset(Uint8List imageBytes, String token) async {
    final url = Uri.parse(ApiConfig.scanAsset);

    final request = http.MultipartRequest('POST', url);

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'scan_image.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return OcrResponse.fromJson(body);
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      if (e.toString().contains("Terjadi kesalahan") ||
          e.toString().contains("detail")) {
        rethrow;
      }
      throw Exception('Gagal terhubung ke layanan OCR: $e');
    }
  }
}