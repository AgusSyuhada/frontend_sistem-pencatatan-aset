import 'package:flutter/material.dart';
import '../../../data/local/preferences/session_manager.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../config/app_routes.dart';
import '../../data/remote/api_exception.dart';
import '../common/app_dialogs.dart';
import 'dart:developer' as developer;

class SplashViewModel extends ChangeNotifier {
  final SessionManager _sessionManager;
  final UserRepository _userRepository;
  final AuthRepository _authRepository;

  SplashViewModel(
    this._sessionManager,
    this._userRepository,
    this._authRepository,
  );

  Future<void> checkSessionAndNavigate(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 1));
    if (!context.mounted) return;

    final isLoggedIn = await _sessionManager.isLoggedIn();
    final hasAgreed = await _sessionManager.haveAgreedToTerms();

    developer.log(
      "Check Session: IsLoggedIn = $isLoggedIn",
      name: 'SplashViewModel',
    );

    if (!context.mounted) return;

    if (isLoggedIn) {
      try {
        developer.log(
          "Mencoba getMyProfile dengan token lama...",
          name: 'SplashViewModel',
        );
        await _userRepository.getMyProfile();

        if (context.mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      } catch (e) {
        developer.log("Error saat getMyProfile: $e", name: 'SplashViewModel');

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
            "Token Expired terdeteksi (401). Memulai Refresh Token...",
            name: 'SplashViewModel',
          );

          try {
            final newToken = await _authRepository.performRefreshToken();
            developer.log(
              "Refresh Berhasil. Token baru: ${newToken.substring(0, 10)}...",
              name: 'SplashViewModel',
            );

            await _userRepository.getMyProfile();

            developer.log(
              "Retry getMyProfile Berhasil. Masuk ke Home.",
              name: 'SplashViewModel',
            );

            if (context.mounted) {
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            }
            return;
          } catch (refreshError) {
            developer.log(
              "Gagal Refresh Token atau Retry Profile: $refreshError",
              name: 'SplashViewModel',
            );
          }
        }

        await _sessionManager.clearSession();
        developer.log(
          "Session dibersihkan. Kembali ke Login.",
          name: 'SplashViewModel',
        );

        if (context.mounted) {
          showErrorDialog(
            context,
            "Sesi telah berakhir. Silakan login kembali.",
            onOkPressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          );
        }
      }
    } else if (hasAgreed) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.terms);
    }
  }
}
