import 'stat_item.dart';

class PeriodStatsResponse {
  final String message;
  final int year;
  final int cycle;
  final PeriodSummary summary;
  final PeriodDistributions distributions;
  final List<StatItem> timeline;

  PeriodStatsResponse({
    required this.message,
    required this.year,
    required this.cycle,
    required this.summary,
    required this.distributions,
    required this.timeline,
  });

  factory PeriodStatsResponse.fromJson(Map<String, dynamic> json) {
    return PeriodStatsResponse(
      message: json['message'] ?? '',
      year: json['year'] ?? 0,
      cycle: json['cycle'] ?? 0,
      summary: PeriodSummary.fromJson(json['summary'] ?? {}),
      distributions: PeriodDistributions.fromJson(json['distributions'] ?? {}),
      timeline: (json['timeline'] as List? ?? [])
          .map((item) => StatItem.fromJson(item))
          .toList(),
    );
  }
}

class PeriodSummary {
  final int totalAssets;
  final int cycledAssets;
  final int pendingAssets;
  final double completionPercentage;
  final double totalAssetValue;

  PeriodSummary({
    required this.totalAssets,
    required this.cycledAssets,
    required this.pendingAssets,
    required this.completionPercentage,
    required this.totalAssetValue,
  });

  factory PeriodSummary.fromJson(Map<String, dynamic> json) {
    return PeriodSummary(
      totalAssets: json['total_assets'] ?? 0,
      cycledAssets: json['cycled_assets'] ?? 0,
      pendingAssets: json['pending_assets'] ?? 0,
      completionPercentage:
          (json['completion_percentage'] as num?)?.toDouble() ?? 0.0,
      totalAssetValue: (json['total_asset_value'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PeriodDistributions {
  final List<StatItem> condition;
  final List<StatItem> team;
  final List<StatItem> area;
  final List<StatItem> inventoryResult;
  final List<StatItem> manufacturer;
  final List<StatItem> costCenter;

  PeriodDistributions({
    required this.condition,
    required this.team,
    required this.area,
    required this.inventoryResult,
    required this.manufacturer,
    required this.costCenter,
  });

  factory PeriodDistributions.fromJson(Map<String, dynamic> json) {
    return PeriodDistributions(
      condition: _mapList(json['condition']),
      team: _mapList(json['team']),
      area: _mapList(json['area']),
      inventoryResult: _mapList(json['inventory_result']),
      manufacturer: _mapList(json['manufacturer']),
      costCenter: _mapList(json['cost_center']),
    );
  }

  static List<StatItem> _mapList(dynamic list) {
    if (list == null || list is! List) return [];
    return list.map((item) => StatItem.fromJson(item)).toList();
  }
}
