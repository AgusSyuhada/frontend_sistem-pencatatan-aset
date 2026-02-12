class CyclePeriodInfo {
  final int year;
  final int cycle;

  CyclePeriodInfo({required this.year, required this.cycle});

  factory CyclePeriodInfo.fromJson(Map<String, dynamic> json) {
    return CyclePeriodInfo(
      year: json['year'] ?? json['Year'] ?? 0,
      cycle: json['cycle'] ?? json['Cycle'] ?? 0,
    );
  }
}