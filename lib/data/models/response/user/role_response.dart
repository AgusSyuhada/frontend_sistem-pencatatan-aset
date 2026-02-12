class Role {
  final int roleId;
  final String roleName;

  Role({required this.roleId, required this.roleName});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(roleId: json['roleid'], roleName: json['rolename']);
  }

  Map<String, dynamic> toJson() {
    return {'roleid': roleId, 'rolename': roleName};
  }
}

class RoleListResponse {
  final String message;
  final List<Role> data;

  RoleListResponse({required this.message, required this.data});

  factory RoleListResponse.fromJson(Map<String, dynamic> json) {
    return RoleListResponse(
      message: json['message'] ?? '',
      data: (json['data'] as List).map((e) => Role.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'message': message, 'data': data.map((e) => e.toJson()).toList()};
  }
}
