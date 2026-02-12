class AssetListItem {
  final String assetNumber;
  final String assetName;
  final String? conditionName;
  final String? locationName;
  final bool isActive;

  AssetListItem({
    required this.assetNumber,
    required this.assetName,
    this.conditionName,
    this.locationName,
    required this.isActive,
  });

  factory AssetListItem.fromJson(Map<String, dynamic> json) {
    return AssetListItem(
      assetNumber: json['assetnumber'] ?? '',
      assetName: json['assetname'] ?? '',
      conditionName: json['conditionname'],
      locationName: json['location'],
      isActive: json['isactive'] ?? false,
    );
  }

  AssetListItem copyWith({
    String? assetNumber,
    String? assetName,
    String? conditionName,
    String? locationName,
    bool? isActive,
  }) {
    return AssetListItem(
      assetNumber: assetNumber ?? this.assetNumber,
      assetName: assetName ?? this.assetName,
      conditionName: conditionName ?? this.conditionName,
      locationName: locationName ?? this.locationName,
      isActive: isActive ?? this.isActive,
    );
  }
}
