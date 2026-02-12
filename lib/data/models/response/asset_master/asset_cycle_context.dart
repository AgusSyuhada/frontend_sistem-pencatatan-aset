import 'cycle_period_info.dart';

class AssetCycleContext {
  final bool isInActiveCycle;
  final CyclePeriodInfo? activePeriod;
  final String? message;

  AssetCycleContext({
    required this.isInActiveCycle,
    this.activePeriod,
    this.message,
  });

  factory AssetCycleContext.fromJson(Map<String, dynamic> json) {
    return AssetCycleContext(
      isInActiveCycle: json['is_in_active_cycle'] ?? false,
      activePeriod: json['active_period'] != null
          ? CyclePeriodInfo.fromJson(json['active_period'])
          : null,
      message: json['message'],
    );
  }
}