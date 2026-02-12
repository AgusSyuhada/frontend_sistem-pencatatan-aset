import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../data/models/response/user/user_response.dart';
import '../../data/models/response/auth/logout_response.dart';

class HomeViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  HomeViewModel(this._authRepository, this._userRepository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserResponse? _user;
  UserResponse? get user => _user;

  String? _message;
  String? get message => _message;

  UserResponse? _currentUser;
  UserResponse? get currentUser => _currentUser;

  bool get isAdmin => _user?.user.roleId == 1;

  Future<void> init({bool forceRefresh = false}) async {
    _isLoading = true;
    _message = null;
    notifyListeners();

    try {
      _user = await _authRepository.getLocalUserProfile();

      if (_user != null) {
        notifyListeners();
      }

      if (!forceRefresh && _user != null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final freshUserResponse = await _userRepository.getMyProfile();

      _user = freshUserResponse;
      _message = freshUserResponse.message;
    } catch (e) {
      debugPrint("Gagal refresh profil: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCurrentUser() async {
    _currentUser = await _authRepository.getLocalUserProfile();
    notifyListeners();
  }

  Future<LogoutResponse> logout() async {
    try {
      final response = await _authRepository.logout();

      _user = null;
      notifyListeners();

      return response;
    } catch (e) {
      rethrow;
    }
  }
}
