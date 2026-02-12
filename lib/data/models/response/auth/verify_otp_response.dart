class VerifyOtpResponse {
  final String message;
  final bool isValid;

  VerifyOtpResponse({
    required this.message,
    required this.isValid,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      message: json['message'] ?? 'Verifikasi berhasil',
      isValid: json['valid'] ?? false,
    );
  }
}