import 'dart:developer' as developer;
import '../local/preferences/user_preferences.dart';
import '../models/response/user/role_response.dart';
import '../remote/api_exception.dart';
import '../remote/services/user_service.dart';
import '../local/preferences/session_manager.dart';
import '../models/request/user/user_create_request.dart';
import '../models/request/user/user_self_update_request.dart';
import '../models/request/user/change_password_request.dart';
import '../models/request/user/admin_reset_password_request.dart';
import '../models/request/user/user_admin_update_request.dart';
import '../models/response/user/user_response.dart';
import '../models/response/user/user_list_response.dart';
import '../models/response/message_response.dart';
import 'auth_repository.dart';

class UserRepository {
  final UserService _userService;
  final SessionManager _sessionManager;
  final UserPreferences _userPreferences;
  final AuthRepository _authRepository;

  UserRepository(
    this._userService,
    this._sessionManager,
    this._userPreferences,
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

  Future<UserResponse> fetchAndSaveMyProfile() {
    return _executeWithRefresh((token) async {
      final response = await _userService.getMyProfile(token);
      await _sessionManager.saveUser(response);
      return response;
    }, functionName: 'fetchAndSaveMyProfile');
  }

  Future<UserResponse> getUserById(int userId) {
    return _executeWithRefresh(
      (token) => _userService.getUserById(token, userId),
      functionName: 'getUserById',
    );
  }

  Future<UserResponse> getMyProfile() {
    return _executeWithRefresh(
      (token) => _userService.getMyProfile(token),
      functionName: 'getMyProfile',
    );
  }

  Future<UserResponse> createUser(UserCreateRequest request) {
    return _executeWithRefresh(
      (token) => _userService.createUser(token, request),
      functionName: 'createUser',
    );
  }

  Future<UserListResponse> getAllUsers({
    bool includeInactive = false,
    List<int>? roleIds,
    String? query,
    int limit = 20,
    int offset = 0,
  }) {
    return _executeWithRefresh((token) async {
      final response = await _userService.getAllUsers(
        token,
        includeInactive: includeInactive,
        roleIds: roleIds,
        query: query,
        limit: limit,
        offset: offset,
      );
      return response;
    }, functionName: 'getAllUsers');
  }

  Future<RoleListResponse> getRoles() {
    return _executeWithRefresh((token) async {
      final response = await _userService.getRoles(token);
      await _userPreferences.saveRoles(response.data);
      return response;
    }, functionName: 'getRoles');
  }

  Future<List<Role>> getLocalRoles() async {
    return await _userPreferences.getRoles();
  }

  Future<UserResponse> updateUserByAdmin(
    int userId,
    UserAdminUpdateRequest request,
  ) {
    return _executeWithRefresh(
      (token) => _userService.updateUserByAdmin(token, userId, request),
      functionName: 'updateUserByAdmin',
    );
  }

  Future<MessageResponse> adminResetPassword(int userId, String newPassword) {
    final request = AdminResetPasswordRequest(newPassword: newPassword);
    return _executeWithRefresh(
      (token) => _userService.adminResetPassword(token, userId, request),
      functionName: 'adminResetPassword',
    );
  }

  Future<MessageResponse> deactivateUser(int userId) {
    return _executeWithRefresh(
      (token) => _userService.deactivateUser(token, userId),
      functionName: 'deactivateUser',
    );
  }

  Future<MessageResponse> reactivateUser(int userId) {
    return _executeWithRefresh(
      (token) => _userService.reactivateUser(token, userId),
      functionName: 'reactivateUser',
    );
  }

  Future<UserResponse> updateMyName(String name) {
    final request = UserSelfUpdateRequest(name: name);
    return _executeWithRefresh((token) async {
      final updatedUser = await _userService.updateMyName(token, request);
      await _sessionManager.saveUser(updatedUser);
      return updatedUser;
    }, functionName: 'updateMyName');
  }

  Future<MessageResponse> changeMyPassword(
    String currentPassword,
    String newPassword,
  ) {
    final request = ChangePasswordRequest(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    return _executeWithRefresh(
      (token) => _userService.changeMyPassword(token, request),
      functionName: 'changeMyPassword',
    );
  }
}
