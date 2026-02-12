import 'asset_cycle_context.dart';

class AssetModel {
  final String assetNumber;
  final String? hbm;
  final String? serialNumber;
  final String? assetName;
  final String? modelType;
  final String? gpsCoordinate;
  final String? description;
  final String? inventoryResult;
  final String? costCenter;
  final String? sapLocationCode;
  final double? assetValue;
  final String? inventoryDate;
  final bool isActive;
  final int? teamId;
  final String? teamName;
  final int? manufacturerId;
  final String? manufacturerName;
  final int? conditionId;
  final String? conditionName;
  final int? locationId;
  final String? area;
  final String? locationName;
  final String? specificLocation;
  final String? picTeamFav;
  final String? assetPhoto;
  final String? assetCodePhoto;
  final String? assetLocationPhoto;

  final AssetCycleContext? cycleContext;

  AssetModel({
    required this.assetNumber,
    this.hbm,
    this.serialNumber,
    this.assetName,
    this.modelType,
    this.gpsCoordinate,
    this.description,
    this.inventoryResult,
    this.costCenter,
    this.sapLocationCode,
    this.assetValue,
    this.inventoryDate,
    required this.isActive,
    this.teamId,
    this.teamName,
    this.manufacturerId,
    this.manufacturerName,
    this.conditionId,
    this.conditionName,
    this.locationId,
    this.area,
    this.locationName,
    this.specificLocation,
    this.picTeamFav,
    this.assetPhoto,
    this.assetCodePhoto,
    this.assetLocationPhoto,
    this.cycleContext,
  });

  factory AssetModel.fromJson(
    Map<String, dynamic> json, {
    AssetCycleContext? context,
  }) {
    return AssetModel(
      assetNumber: json['assetnumber'] ?? '',
      hbm: json['hbm'],
      serialNumber: json['serialnumber'],
      assetName: json['assetname'],
      modelType: json['modeltype'],
      gpsCoordinate: json['gpscoordinate'],
      description: json['description'],
      inventoryResult: json['inventoryresult'],
      costCenter: json['costcenter'],
      sapLocationCode: json['saplocationcode'],
      assetValue: json['assetvalue'] != null
          ? double.tryParse(json['assetvalue'].toString())
          : null,
      inventoryDate: json['inventorydate'],
      isActive: json['isactive'] ?? false,
      teamId: json['teamid'],
      teamName: json['teamname'],
      manufacturerId: json['manufacturerid'],
      manufacturerName: json['manufacturername'],
      conditionId: json['conditionid'],
      conditionName: json['conditionname'],
      locationId: json['locationid'],
      area: json['area'],
      locationName: json['location'],
      specificLocation: json['specificlocation'],
      picTeamFav: json['picteamfav'],
      assetPhoto: json['assetphoto'],
      assetCodePhoto: json['assetcodephoto'],
      assetLocationPhoto: json['assetlocationphoto'],
      cycleContext: context,
    );
  }

  AssetModel copyWith({
    String? assetNumber,
    String? hbm,
    String? serialNumber,
    String? assetName,
    String? modelType,
    String? gpsCoordinate,
    String? description,
    String? inventoryResult,
    String? costCenter,
    String? sapLocationCode,
    double? assetValue,
    String? inventoryDate,
    bool? isActive,
    int? teamId,
    String? teamName,
    int? manufacturerId,
    String? manufacturerName,
    int? conditionId,
    String? conditionName,
    int? locationId,
    String? area,
    String? locationName,
    String? specificLocation,
    String? picTeamFav,
    String? assetPhoto,
    String? assetCodePhoto,
    String? assetLocationPhoto,
    AssetCycleContext? cycleContext,
  }) {
    return AssetModel(
      assetNumber: assetNumber ?? this.assetNumber,
      hbm: hbm ?? this.hbm,
      serialNumber: serialNumber ?? this.serialNumber,
      assetName: assetName ?? this.assetName,
      modelType: modelType ?? this.modelType,
      gpsCoordinate: gpsCoordinate ?? this.gpsCoordinate,
      description: description ?? this.description,
      inventoryResult: inventoryResult ?? this.inventoryResult,
      costCenter: costCenter ?? this.costCenter,
      sapLocationCode: sapLocationCode ?? this.sapLocationCode,
      assetValue: assetValue ?? this.assetValue,
      inventoryDate: inventoryDate ?? this.inventoryDate,
      isActive: isActive ?? this.isActive,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      manufacturerId: manufacturerId ?? this.manufacturerId,
      manufacturerName: manufacturerName ?? this.manufacturerName,
      conditionId: conditionId ?? this.conditionId,
      conditionName: conditionName ?? this.conditionName,
      locationId: locationId ?? this.locationId,
      area: area ?? this.area,
      locationName: locationName ?? this.locationName,
      specificLocation: specificLocation ?? this.specificLocation,
      picTeamFav: picTeamFav ?? this.picTeamFav,
      assetPhoto: assetPhoto ?? this.assetPhoto,
      assetCodePhoto: assetCodePhoto ?? this.assetCodePhoto,
      assetLocationPhoto: assetLocationPhoto ?? this.assetLocationPhoto,
      cycleContext: cycleContext ?? this.cycleContext,
    );
  }
}
