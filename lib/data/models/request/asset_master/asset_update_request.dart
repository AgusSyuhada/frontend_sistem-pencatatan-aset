import 'dart:io';

class AssetUpdateRequest {
  final String? assetName;
  final String? hbm;
  final int? teamId;
  final double? assetValue;
  final String? costCenter;
  final String? serialNumber;
  final String? modelType;
  final int? manufacturerId;
  final String? gpsCoordinate;
  final int? conditionId;
  final int? locationId;
  final String? specificLocation;
  final String? description;
  final String? inventoryResult;
  final String? inventoryDate;
  final String? picTeamFav;
  final File? assetPhoto;
  final File? codePhoto;
  final File? locationPhoto;

  AssetUpdateRequest({
    this.assetName,
    this.hbm,
    this.teamId,
    this.assetValue,
    this.costCenter,
    this.serialNumber,
    this.modelType,
    this.manufacturerId,
    this.gpsCoordinate,
    this.conditionId,
    this.locationId,
    this.specificLocation,
    this.description,
    this.inventoryResult,
    this.inventoryDate,
    this.picTeamFav,
    this.assetPhoto,
    this.codePhoto,
    this.locationPhoto,
  });

  Map<String, String> toFields() {
    final Map<String, String> data = {};
    if (assetName != null) data['assetname'] = assetName!;
    if (hbm != null) data['hbm'] = hbm!;
    if (teamId != null) data['teamid'] = teamId.toString();
    if (assetValue != null) data['assetvalue'] = assetValue.toString();
    if (costCenter != null) data['costcenter'] = costCenter!;
    if (serialNumber != null) data['serialnumber'] = serialNumber!;
    if (modelType != null) data['modeltype'] = modelType!;
    if (manufacturerId != null) {
      data['manufacturerid'] = manufacturerId.toString();
    }
    if (gpsCoordinate != null) data['gpscoordinate'] = gpsCoordinate!;
    if (conditionId != null) data['conditionid'] = conditionId.toString();
    if (locationId != null) data['locationid'] = locationId.toString();
    if (specificLocation != null) data['specificlocation'] = specificLocation!;
    if (description != null) data['description'] = description!;
    if (inventoryResult != null) data['inventoryresult'] = inventoryResult!;
    if (inventoryDate != null) data['inventorydate'] = inventoryDate!;
    if (picTeamFav != null) data['picteamfav'] = picTeamFav!;

    return data;
  }
}