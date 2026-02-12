import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../data/repositories/user_repository.dart';
import '../../data/models/request/user/user_admin_update_request.dart';
import '../../data/models/response/user/role_response.dart';
import '../../data/models/response/user/user.dart';

enum UserDetailEditState { idle, loading, error }

class UserDetailEditViewModel extends ChangeNotifier {
  final UserRepository _userRepository;

  UserDetailEditViewModel(this._userRepository);

  UserDetailEditState _state = UserDetailEditState.idle;
  UserDetailEditState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Role> _availableRoles = [];
  List<Role> get availableRoles => _availableRoles;

  static final Map<int, User> _userCache = {};
  static final Map<int, DateTime> _lastFetchTime = {};
  static const Duration _cacheDuration = Duration(minutes: 2);

  User? _currentUser;
  User? get currentUser => _currentUser;

  Future<void> initialize(User? initialData) async {
    if (initialData != null) {
      _currentUser = initialData;

      if (!_userCache.containsKey(initialData.userId)) {
        _userCache[initialData.userId] = initialData;
      }
    }

    if (_availableRoles.isEmpty) {
      await _fetchRoles();
    }
  }

  Future<void> loadUserDetail(int userId) async {
    final lifecycleState = SchedulerBinding.instance.lifecycleState;
    if (lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.detached) {
      log(
        "App in background, skipping fetch for user $userId",
        name: 'UserDetailEditViewModel',
      );
      return;
    }

    if (_userCache.containsKey(userId)) {
      _currentUser = _userCache[userId];
      notifyListeners();

      final lastFetch = _lastFetchTime[userId];
      final isStale =
          lastFetch == null ||
          DateTime.now().difference(lastFetch) > _cacheDuration;

      if (!isStale) {
        log(
          "Data user $userId masih segar (Cache Hit). Skip network.",
          name: 'UserDetailEditViewModel',
        );
        return;
      }
    } else {
      _state = UserDetailEditState.loading;
      notifyListeners();
    }

    try {
      log(
        "Fetching fresh data for user $userId...",
        name: 'UserDetailEditViewModel',
      );
      final response = await _userRepository.getUserById(userId);

      _userCache[userId] = response.user;
      _lastFetchTime[userId] = DateTime.now();
      _currentUser = response.user;

      _state = UserDetailEditState.idle;
      notifyListeners();
      log("User data updated from server.", name: 'UserDetailEditViewModel');
    } catch (e) {
      log("Gagal fetch user detail: $e", name: 'UserDetailEditViewModel');
      _errorMessage = e.toString().replaceAll("Exception: ", "");

      if (_currentUser == null) {
        _state = UserDetailEditState.error;
      } else {
        _state = UserDetailEditState.idle;
      }
      notifyListeners();
    }
  }

  Future<void> _fetchRoles() async {
    try {
      final localRoles = await _userRepository.getLocalRoles();
      if (localRoles.isNotEmpty) {
        _availableRoles = localRoles;
        notifyListeners();
      }

      final response = await _userRepository.getRoles();
      _availableRoles = response.data;
      notifyListeners();
    } catch (e) {
      log(
        "Gagal memuat roles di Detail User: $e",
        name: 'UserDetailEditViewModel',
      );
    }
  }

  Future<String?> updateUser(int userId, UserAdminUpdateRequest request) async {
    _state = UserDetailEditState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _userRepository.updateUserByAdmin(userId, request);

      _userCache[userId] = response.user;
      _lastFetchTime[userId] = DateTime.now();
      _currentUser = response.user;

      _state = UserDetailEditState.idle;
      notifyListeners();

      return response.message;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _state = UserDetailEditState.idle;
      notifyListeners();
      return null;
    }
  }

  Future<String?> resetUserPassword(int userId, String newPassword) async {
    try {
      final response = await _userRepository.adminResetPassword(
        userId,
        newPassword,
      );
      return response.message;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  static void clearCache() {
    _userCache.clear();
    _lastFetchTime.clear();
  }
}
