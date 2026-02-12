class AdminResetPasswordRequest {
  final String newPassword;

  AdminResetPasswordRequest({required this.newPassword});

  Map<String, dynamic> toJson() {
    return {"new_password": newPassword};
  }
}
