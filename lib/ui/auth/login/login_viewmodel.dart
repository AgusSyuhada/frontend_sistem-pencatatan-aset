import 'dart:developer';
import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/user_repository.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  LoginViewModel(this._authRepository, this._userRepository);

  Future<String> login(String email, String password) async {
    log('--- LOGIN STARTED ---', name: 'LoginViewModel');
    log('Attempting login for email: $email', name: 'LoginViewModel');

    try {
      final response = await _authRepository.login(email, password);

      log(
        'Auth API success. Message: ${response.message}',
        name: 'LoginViewModel',
      );

      log('Fetching and saving user profile...', name: 'LoginViewModel');
      await _userRepository.fetchAndSaveMyProfile();

      log(
        'User profile fetched and saved successfully.',
        name: 'LoginViewModel',
      );
      log('--- LOGIN COMPLETED ---', name: 'LoginViewModel');

      return response.message;
    } catch (e, stackTrace) {
      log(
        'Login Failed!',
        name: 'LoginViewModel',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
