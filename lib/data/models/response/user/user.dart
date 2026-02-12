class User {
  final int userId;
  final String name;
  final String email;
  final int roleId;
  final String? roleName;
  final bool isActive;
  final String? profilePictureUrl;

  User({
    required this.userId,
    required this.name,
    required this.email,
    required this.roleId,
    this.roleName,
    required this.isActive,
    this.profilePictureUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userid'],
      name: json['name'],
      email: json['email'],
      roleId: json['roleid'],
      roleName: json['rolename'],
      isActive: json['isactive'] ?? true,
      profilePictureUrl: json['profilepictureurl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userid': userId,
      'name': name,
      'email': email,
      'roleid': roleId,
      'isactive': isActive,
      'profilepictureurl': profilePictureUrl,
    };
  }

  User copyWith({
    int? userId,
    String? name,
    String? email,
    int? roleId,
    String? roleName,
    bool? isActive,
    String? profilePictureUrl,
  }) {
    return User(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      roleId: roleId ?? this.roleId,
      roleName: roleName ?? this.roleName,
      isActive: isActive ?? this.isActive,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    );
  }
}
