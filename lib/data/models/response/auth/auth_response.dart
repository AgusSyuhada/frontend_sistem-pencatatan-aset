class AuthResponse {
  final String token;
  final String? refreshToken;
  final String message;

  AuthResponse({
    required this.token,
    this.refreshToken,
    required this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? json['refreshToken'],
      message: json['message'] ?? 'Login berhasil.', 
    );
  }
}