class StatItem {
  final String name;
  final int count;
  final double? percentage;
  final String? date;

  StatItem({
    required this.name,
    required this.count,
    this.percentage,
    this.date,
  });

  factory StatItem.fromJson(Map<String, dynamic> json) {
    return StatItem(
      name: json['name'] ?? json['date'] ?? 'N/A',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble(),
      date: json['date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'count': count,
      'percentage': percentage,
      'date': date,
    };
  }
}
