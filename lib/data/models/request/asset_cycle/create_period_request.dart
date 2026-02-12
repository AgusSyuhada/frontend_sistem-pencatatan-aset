class CreatePeriodRequest {
  final int year;
  final int cycle;
  final List<String> assetNumbers;

  CreatePeriodRequest({
    required this.year,
    required this.cycle,
    required this.assetNumbers,
  });

  Map<String, dynamic> toJson() => {
    'year': year,
    'cycle': cycle,
    'asset_numbers': assetNumbers,
  };
}
