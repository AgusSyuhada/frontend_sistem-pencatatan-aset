import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  ForgotPasswordViewModel(this._authRepository);

  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  Timer? _timer;
  int _remainingTime = 0;
  bool get isTimerRunning => _remainingTime > 0;
  int get remainingTime => _remainingTime;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void startTimer() {
    _timer?.cancel();

    _remainingTime = 60;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        _remainingTime--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
    _remainingTime = 0;
    notifyListeners();
  }

  void _resetMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  Future<bool> requestOtp() async {
    if (emailController.text.trim().isEmpty) {
      _errorMessage = "Email tidak boleh kosong.";
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _resetMessages();

    try {
      final response = await _authRepository.requestForgotPassword(
        emailController.text.trim(),
      );
      _successMessage = response.message;

      _setLoading(false);
      startTimer();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyOtpAction() async {
    final email = emailController.text.trim();
    final otp = otpController.text.trim();

    if (otp.length < 4) {
      _errorMessage = "Masukkan kode OTP dengan benar.";
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _resetMessages();

    try {
      final response = await _authRepository.verifyOtp(email, otp);
      _successMessage = response.message;

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _setLoading(false);
      return false;
    }
  }

  Future<bool> submitResetPassword() async {
    final email = emailController.text.trim();
    final otp = otpController.text.trim();
    final newPass = newPasswordController.text;
    final confirmPass = confirmPasswordController.text;

    if (newPass.isEmpty || confirmPass.isEmpty) {
      _errorMessage = "Password tidak boleh kosong.";
      notifyListeners();
      return false;
    }

    if (newPass != confirmPass) {
      _errorMessage = "Konfirmasi password tidak cocok.";
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _resetMessages();

    try {
      final response = await _authRepository.resetPassword(email, otp, newPass);
      _successMessage = response.message;

      _setLoading(false);
      stopTimer();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearState() {
    emailController.clear();
    otpController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    _resetMessages();
    _isLoading = false;
    stopTimer();
  }

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }
}
