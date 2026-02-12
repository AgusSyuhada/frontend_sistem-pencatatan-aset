import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../data/repositories/upload_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../data/models/response/user/user_response.dart';

enum ProfileState { idle, loading, success, error }

class ProfileViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final UploadRepository _uploadRepository;

  ProfileViewModel(
    this._authRepository,
    this._userRepository,
    this._uploadRepository,
  );

  ProfileState _state = ProfileState.idle;
  ProfileState get state => _state;

  Timer? _autoRefreshTimer;

  UserResponse? _user;
  UserResponse? get user => _user;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  Future<void> initialize() async {
    try {
      final cachedUser = await _authRepository.getLocalUserProfile();
      if (cachedUser != null) {
        _user = cachedUser;
        notifyListeners();
      }
    } catch (_) {}

    if (_user == null) {
      _state = ProfileState.loading;
      notifyListeners();
    }

    await _fetchLatestProfile();

    _startAutoRefresh();
  }

  Future<void> _fetchLatestProfile() async {
    try {
      final freshUser = await _userRepository.getMyProfile();

      _user = freshUser;
      _state = ProfileState.idle;
    } catch (e) {
      if (_user == null) {
        _errorMessage = "Gagal memuat profil.";
        _state = ProfileState.error;
      }
      log("Gagal refresh profil: $e");
    } finally {
      notifyListeners();
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      log("Auto-fetching profile data...");
      _fetchLatestProfile();
    });
  }

  Future<String?> updateName(String newName) async {
    _state = ProfileState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _userRepository.updateMyName(newName);
      _user = updatedUser;
      _state = ProfileState.success;
      return updatedUser.message;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _state = ProfileState.error;
      return null;
    } finally {
      if (_state != ProfileState.success) _state = ProfileState.idle;
      notifyListeners();
    }
  }

  Future<String?> changePassword(String currentPass, String newPass) async {
    _state = ProfileState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _userRepository.changeMyPassword(
        currentPass,
        newPass,
      );
      _state = ProfileState.success;
      return response.message;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _state = ProfileState.error;
      return null;
    } finally {
      if (_state != ProfileState.success) _state = ProfileState.idle;
      notifyListeners();
    }
  }

  void resetMessage() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> updateProfilePicture(File imageFile) async {
    _state = ProfileState.loading;
    _successMessage = null;
    notifyListeners();

    try {
      final response = await _uploadRepository.uploadProfilePicture(imageFile);
      await initialize();
      _successMessage = response.message;

      _state = ProfileState.success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _state = ProfileState.error;
    } finally {
      if (_state != ProfileState.success) _state = ProfileState.idle;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}
