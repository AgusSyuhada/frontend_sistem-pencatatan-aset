class UserSelfUpdateRequest {
  final String name;

  UserSelfUpdateRequest({required this.name});

  Map<String, dynamic> toJson() {
    return {"name": name};
  }
}