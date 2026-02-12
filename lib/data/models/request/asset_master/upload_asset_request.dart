class UploadAssetRequest {
  final String assetNumber;
  final String photoType;
  final int year;
  final int cycle;

  UploadAssetRequest({
    required this.assetNumber,
    required this.photoType,
    required this.year,
    required this.cycle,
  });

  Map<String, String> toMap() {
    return {
      'asset_number': assetNumber,
      'photo_type': photoType,
      'year': year.toString(),
      'cycle': cycle.toString(),
    };
  }
}
