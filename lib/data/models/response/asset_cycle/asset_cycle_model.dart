class AssetCycleModel {
  final int backupId;
  final int year;
  final int cycle;
  final String assetNumber;
  final String assetName;

  final String? hbm;
  final String? serialNumber;
  final String? modelType;
  final int? teamId;
  final String? teamName;
  final int? manufacturerId;
  final String? manufacturerName;
  final String? costCenter;
  final num? assetValue;

  final String? inventoryResult;
  final String? description;
  final String? gpsCoordinate;
  final int? conditionId;
  final String? conditionName;
  final int? locationId;
  final String? locationName;
  final String? area;
  final String? specificLocation;
  final String? picTeamFav;

  final String? assetPhoto;
  final String? assetCodePhoto;
  final String? assetLocationPhoto;

  final String? inventoryDate;
  final String? backupTimestamp;
  final String? sapLocationCode;
  final bool isCycled;

  AssetCycleModel({
    required this.backupId,
    required this.year,
    required this.cycle,
    required this.assetNumber,
    required this.assetName,
    this.hbm,
    this.serialNumber,
    this.modelType,
    this.teamId,
    this.teamName,
    this.manufacturerId,
    this.manufacturerName,
    this.costCenter,
    this.assetValue,
    this.inventoryResult,
    this.description,
    this.gpsCoordinate,
    this.conditionId,
    this.conditionName,
    this.locationId,
    this.locationName,
    this.area,
    this.specificLocation,
    this.picTeamFav,
    this.assetPhoto,
    this.assetCodePhoto,
    this.assetLocationPhoto,
    this.inventoryDate,
    this.backupTimestamp,
    this.sapLocationCode,
    this.isCycled = false,
  });

  factory AssetCycleModel.fromJson(Map<String, dynamic> json) {
    return AssetCycleModel(
      backupId: json['backupid'] ?? 0,
      year: json['year'] ?? 0,
      cycle: json['cycle'] ?? 0,
      assetNumber: json['assetnumber'] ?? '',
      assetName: json['assetname'] ?? '',
      hbm: json['hbm'],
      serialNumber: json['serialnumber'],
      modelType: json['modeltype'],
      teamId: json['teamid'],
      teamName: json['teamname'],
      manufacturerId: json['manufacturerid'],
      manufacturerName: json['manufacturername'],
      costCenter: json['costcenter'],
      assetValue: json['assetvalue'],
      inventoryResult: json['inventoryresult'],
      description: json['description'],
      gpsCoordinate: json['gpscoordinate'],
      conditionId: json['conditionid'],
      conditionName: json['conditionname'],
      locationId: json['locationid'],
      locationName: json['location'],
      area: json['area'],
      specificLocation: json['specificlocation'],
      picTeamFav: json['picteamfav'],
      assetPhoto: json['assetphoto'],
      assetCodePhoto: json['assetcodephoto'],
      assetLocationPhoto: json['assetlocationphoto'],

      inventoryDate: json['inventorydate'],
      backupTimestamp: json['backuptimestamp'],
      sapLocationCode: json['saplocationcode'],
      isCycled: json['iscycled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'backupid': backupId,
      'year': year,
      'cycle': cycle,
      'assetnumber': assetNumber,
      'assetname': assetName,
      'hbm': hbm,
      'serialnumber': serialNumber,
      'modeltype': modelType,
      'teamid': teamId,
      'teamname': teamName,
      'manufacturerid': manufacturerId,
      'manufacturername': manufacturerName,
      'costcenter': costCenter,
      'assetvalue': assetValue,
      'inventoryresult': inventoryResult,
      'description': description,
      'gpscoordinate': gpsCoordinate,
      'conditionid': conditionId,
      'conditionname': conditionName,
      'locationid': locationId,
      'location': locationName,
      'area': area,
      'specificlocation': specificLocation,
      'picteamfav': picTeamFav,
      'assetphoto': assetPhoto,
      'assetcodephoto': assetCodePhoto,
      'assetlocationphoto': assetLocationPhoto,
      'inventorydate': inventoryDate,
      'backuptimestamp': backupTimestamp,
      'saplocationcode': sapLocationCode,
      'iscycled': isCycled,
    };
  }
}
