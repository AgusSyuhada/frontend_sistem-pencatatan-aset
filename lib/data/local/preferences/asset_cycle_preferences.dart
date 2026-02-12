import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/storage_keys.dart';
import '../../models/response/asset_cycle/asset_cycle_list_response.dart';

class AssetCyclePreferences {
  Future<void> savePeriods(AssetCycleListResponse data) async {
    final prefs = await SharedPreferences.getInstance();

    String jsonString = jsonEncode(data.toJson());
    await prefs.setString(StorageKeys.assetCyclePeriods, jsonString);

    await prefs.setInt(
      StorageKeys.assetCycleLastFetch,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<AssetCycleListResponse?> getPeriods() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString(StorageKeys.assetCyclePeriods);

    if (jsonString != null) {
      try {
        return AssetCycleListResponse.fromJson(jsonDecode(jsonString));
      } catch (e) {
        await clearPeriods();
        return null;
      }
    }
    return null;
  }

  Future<bool> isCacheValid({int durationInMinutes = 5}) async {
    final prefs = await SharedPreferences.getInstance();
    int? lastTime = prefs.getInt(StorageKeys.assetCycleLastFetch);

    if (lastTime == null) return false;

    final lastFetch = DateTime.fromMillisecondsSinceEpoch(lastTime);
    final diff = DateTime.now().difference(lastFetch);

    return diff.inMinutes < durationInMinutes;
  }

  Future<void> clearPeriods() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.assetCyclePeriods);
    await prefs.remove(StorageKeys.assetCycleLastFetch);
  }
}
