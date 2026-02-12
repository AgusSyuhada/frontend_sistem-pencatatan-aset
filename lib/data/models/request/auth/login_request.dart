class LoginRequest {
  final String email;
  final String password;
  final String deviceModel;
  final String geoCoordinates;

  LoginRequest({
    required this.email,
    required this.password,
    required this.deviceModel,
    required this.geoCoordinates,
  });

  Map<String, dynamic> toJson() {
    return {
      "email": email,
      "password": password,
      "device_model": deviceModel,
      "geo_coordinates": geoCoordinates,
    };
  }
}