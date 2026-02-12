class PeriodModel {
  final int year;
  final int cycle;
  final int totalAssets;
  final int cycledAssets;
  final double percentage;

  PeriodModel({
    required this.year,
    required this.cycle,
    this.totalAssets = 0,
    this.cycledAssets = 0,
    this.percentage = 0.0,
  });

  factory PeriodModel.fromJson(Map<String, dynamic> json) {
    return PeriodModel(
      year: json['Year'] ?? json['year'] ?? 0,
      cycle: json['Cycle'] ?? json['cycle'] ?? 0,
      totalAssets: json['total_assets'] ?? 0,
      cycledAssets: json['cycled_assets'] ?? 0,
      percentage: (json['percentage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'cycle': cycle,
      'total_assets': totalAssets,
      'cycled_assets': cycledAssets,
      'percentage': percentage,
    };
  }
}
