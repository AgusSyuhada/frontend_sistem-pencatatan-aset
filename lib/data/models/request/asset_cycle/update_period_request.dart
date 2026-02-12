class UpdatePeriodRequest {
  final List<String> assetNumbers;

  UpdatePeriodRequest({required this.assetNumbers});

  Map<String, dynamic> toJson() => {'asset_numbers': assetNumbers};
}
