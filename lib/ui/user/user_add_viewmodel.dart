import 'dart:developer';
import 'package:flutter/material.dart';
import '../../../data/repositories/user_repository.dart';
import '../../data/models/request/user/user_create_request.dart';
import '../../data/models/response/user/role_response.dart';

enum UserAddState { idle, loading, error }

class UserAddViewModel extends ChangeNotifier {
  final UserRepository _userRepository;

  UserAddViewModel(this._userRepository);

  UserAddState _state = UserAddState.idle;
  UserAddState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Role> _availableRoles = [];
  List<Role> get availableRoles => _availableRoles;

  bool _isLoadingRoles = false;
  bool get isLoadingRoles => _isLoadingRoles;

  Future<void> initialize() async {
    await _fetchRoles();
  }

  Future<void> _fetchRoles() async {
    _isLoadingRoles = true;
    notifyListeners();

    try {
      final localRoles = await _userRepository.getLocalRoles();
      if (localRoles.isNotEmpty) {
        _availableRoles = localRoles;
      }

      final response = await _userRepository.getRoles();
      _availableRoles = response.data;
    } catch (e) {
      log("Gagal memuat roles di Add User: $e", name: 'UserAddViewModel');
    } finally {
      _isLoadingRoles = false;
      notifyListeners();
    }
  }

  Future<String?> addUser(UserCreateRequest request) async {
    _state = UserAddState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _userRepository.createUser(request);

      _state = UserAddState.idle;
      notifyListeners();

      return response.message;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _state = UserAddState.error;
      notifyListeners();
      return null;
    }
  }
}
