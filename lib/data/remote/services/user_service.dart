import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../models/request/user/user_create_request.dart';
import '../../models/request/user/user_self_update_request.dart';
import '../../models/request/user/change_password_request.dart';
import '../../models/request/user/admin_reset_password_request.dart';
import '../../models/request/user/user_admin_update_request.dart';
import '../../models/response/user/user_response.dart';
import '../../models/response/user/role_response.dart';
import '../../models/response/user/user_list_response.dart';
import '../../models/response/message_response.dart';

class UserService {
  Map<String, String> _headers(String token) {
    return {...ApiConfig.headers, 'Authorization': 'Bearer $token'};
  }

  String _parseErrorMessage(http.Response response) {
    String finalMessage = 'Terjadi kesalahan (Status: ${response.statusCode})';

    try {
      developer.log(
        "SERVER ERROR (${response.statusCode}): ${response.body}",
        name: 'UserService',
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
      developer.log("PARSING ERROR: $e", name: 'UserService');
    }

    return finalMessage;
  }

  Future<UserResponse> createUser(
    String token,
    UserCreateRequest request,
  ) async {
    final url = Uri.parse(ApiConfig.users);
    try {
      final response = await http.post(
        url,
        headers: _headers(token),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201) {
        return UserResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<UserListResponse> getAllUsers(
    String token, {
    bool includeInactive = false,
    List<int>? roleIds,
    String? query,
    int limit = 20,
    int offset = 0,
  }) async {
    String queryString =
        "include_inactive=$includeInactive&limit=$limit&offset=$offset";

    if (roleIds != null && roleIds.isNotEmpty) {
      for (var id in roleIds) {
        queryString += "&role_ids=$id";
      }
    }

    if (query != null && query.isNotEmpty) queryString += "&q=$query";

    final uri = Uri.parse("${ApiConfig.users}?$queryString");

    try {
      final response = await http.get(uri, headers: _headers(token));

      if (response.statusCode == 200) {
        return UserListResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<RoleListResponse> getRoles(String token) async {
    final url = Uri.parse(ApiConfig.roles);
    try {
      final response = await http.get(url, headers: _headers(token));
      if (response.statusCode == 200) {
        return RoleListResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<UserResponse> getUserById(String token, int userId) async {
    final url = Uri.parse(ApiConfig.userDetail(userId));
    try {
      final response = await http.get(url, headers: _headers(token));

      if (response.statusCode == 200) {
        return UserResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<UserResponse> updateUserByAdmin(
    String token,
    int userId,
    UserAdminUpdateRequest request,
  ) async {
    final url = Uri.parse(ApiConfig.userDetail(userId));
    try {
      final response = await http.patch(
        url,
        headers: _headers(token),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return UserResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<MessageResponse> adminResetPassword(
    String token,
    int userId,
    AdminResetPasswordRequest request,
  ) async {
    final url = Uri.parse(ApiConfig.adminResetPassword(userId));
    try {
      final response = await http.put(
        url,
        headers: _headers(token),
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

  Future<MessageResponse> deactivateUser(String token, int userId) async {
    final url = Uri.parse(ApiConfig.userDeactivate(userId));
    try {
      final response = await http.post(url, headers: _headers(token));

      if (response.statusCode == 200) {
        return MessageResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<MessageResponse> reactivateUser(String token, int userId) async {
    final url = Uri.parse(ApiConfig.userReactivate(userId));
    try {
      final response = await http.post(url, headers: _headers(token));

      if (response.statusCode == 200) {
        return MessageResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<UserResponse> getMyProfile(String token) async {
    final url = Uri.parse(ApiConfig.userMe);
    try {
      final response = await http.get(url, headers: _headers(token));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return UserResponse.fromJson(body);
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<UserResponse> updateMyName(
    String token,
    UserSelfUpdateRequest request,
  ) async {
    final url = Uri.parse(ApiConfig.userMe);
    try {
      final response = await http.patch(
        url,
        headers: _headers(token),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return UserResponse.fromJson(body);
      } else {
        throw Exception(_parseErrorMessage(response));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<MessageResponse> changeMyPassword(
    String token,
    ChangePasswordRequest request,
  ) async {
    final url = Uri.parse(ApiConfig.userMePassword);
    try {
      final response = await http.put(
        url,
        headers: _headers(token),
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
}