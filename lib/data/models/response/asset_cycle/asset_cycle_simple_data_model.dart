class AssetCycleSimpleDataModel {
  final String assetNumber;
  final String assetName;
  final String? conditionName;
  final String? locationName;
  final bool isCycled;

  AssetCycleSimpleDataModel({
    required this.assetNumber,
    required this.assetName,
    this.conditionName,
    this.locationName,
    required this.isCycled,
  });

  factory AssetCycleSimpleDataModel.fromJson(Map<String, dynamic> json) {
    return AssetCycleSimpleDataModel(
      assetNumber: json['assetnumber'] ?? '',
      assetName: json['assetname'] ?? '',
      conditionName: json['conditionname'],
      locationName: json['location'],
      isCycled: json['iscycled'] ?? false,
    );
  }
}
