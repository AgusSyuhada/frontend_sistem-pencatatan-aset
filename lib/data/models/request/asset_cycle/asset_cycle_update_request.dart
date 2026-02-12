class AssetCycleUpdate {
  final String? inventoryResult;
  final String? inventoryDate;
  final int? conditionId;
  final int? locationId;
  final String? specificLocation;
  final String? picTeamFav;
  final String? gpsCoordinate;
  final String? note;

  AssetCycleUpdate({
    this.inventoryResult,
    this.inventoryDate,
    this.conditionId,
    this.locationId,
    this.specificLocation,
    this.picTeamFav,
    this.gpsCoordinate,
    this.note,
  });

  Map<String, String> toFormDataMap() {
    final Map<String, String> data = {};
    if (inventoryResult != null) data['inventoryresult'] = inventoryResult!;
    if (inventoryDate != null) data['inventorydate'] = inventoryDate!;
    if (conditionId != null) data['conditionid'] = conditionId.toString();
    if (locationId != null) data['locationid'] = locationId.toString();
    if (specificLocation != null) data['specificlocation'] = specificLocation!;
    if (picTeamFav != null) data['picteamfav'] = picTeamFav!;
    if (gpsCoordinate != null) data['gpscoordinate'] = gpsCoordinate!;
    if (note != null) data['description'] = note!;
    return data;
  }
}
