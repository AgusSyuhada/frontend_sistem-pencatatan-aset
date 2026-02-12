class LogoutRequest {
  final String deviceModel;

  LogoutRequest({required this.deviceModel});

  Map<String, dynamic> toJson() {
    return {"device_model": deviceModel};
  }
}
