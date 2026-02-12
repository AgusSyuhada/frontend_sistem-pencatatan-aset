class UserAdminUpdateRequest {
  final String? name;
  final String? email;
  final int? roleId;
  final bool? isActive;

  UserAdminUpdateRequest({this.name, this.email, this.roleId, this.isActive});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    if (roleId != null) data['roleid'] = roleId;
    if (isActive != null) data['isactive'] = isActive;
    return data;
  }
}