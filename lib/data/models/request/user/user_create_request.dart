class UserCreateRequest {
  final int userId;
  final String name;
  final String email;
  final String password;
  final int roleId;

  UserCreateRequest({
    required this.userId,
    required this.name,
    required this.email,
    required this.password,
    required this.roleId,
  });

  Map<String, dynamic> toJson() {
    return {
      "userid": userId,
      "name": name,
      "email": email,
      "password": password,
      "roleid": roleId,
    };
  }
}