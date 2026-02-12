import 'user.dart';

class UserListResponse {
  final String message;
  final List<User> data;

  UserListResponse({required this.message, required this.data});

  factory UserListResponse.fromJson(Map<String, dynamic> json) {
    return UserListResponse(
      message: json['message'] ?? '',
      data: (json['data'] as List).map((e) => User.fromJson(e)).toList(),
    );
  }
}
