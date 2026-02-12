import '../asset_master/cycle_period_info.dart';

class CycleStatusInfo {
  final bool isInCycle;
  final CyclePeriodInfo? cyclePeriod;
  final bool canEdit;
  final String? warningMessage;

  CycleStatusInfo({
    required this.isInCycle,
    this.cyclePeriod,
    required this.canEdit,
    this.warningMessage,
  });

  factory CycleStatusInfo.fromJson(Map<String, dynamic> json) {
    return CycleStatusInfo(
      isInCycle: json['is_in_cycle'] ?? false,
      cyclePeriod: json['cycle_period'] != null
          ? CyclePeriodInfo.fromJson(json['cycle_period'])
          : null,
      canEdit: json['can_edit'] ?? false,
      warningMessage: json['warning_message'],
    );
  }
}