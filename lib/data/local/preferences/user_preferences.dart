import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/storage_keys.dart';
import '../../models/response/user/role_response.dart';

class UserPreferences {

  Future<void> saveRoles(List<Role> roles) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(
      roles.map((e) => e.toJson()).toList(),
    );
    await prefs.setString(StorageKeys.keyRolesCache, encodedData);
  }

  Future<List<Role>> getRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString(StorageKeys.keyRolesCache);

    if (cachedData != null) {
      final List<dynamic> decodedList = jsonDecode(cachedData);
      return decodedList.map((e) => Role.fromJson(e)).toList();
    }
    return [];
  }
}
