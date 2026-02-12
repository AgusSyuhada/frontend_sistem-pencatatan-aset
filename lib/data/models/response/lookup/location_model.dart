class LocationModel {
  final int locationId;
  final String? sapLocationCode;
  final String? area;
  final String? location;

  LocationModel({
    required this.locationId,
    this.sapLocationCode,
    this.area,
    this.location,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      locationId: json['locationid'],
      sapLocationCode: json['saplocationcode'],
      area: json['area'],
      location: json['location'],
    );
  }

  String get fullLocationName {
    List<String> parts = [];
    if (sapLocationCode != null) parts.add(sapLocationCode!);
    if (area != null) parts.add(area!);
    if (location != null) parts.add(location!);
    return parts.join(" - ");
  }
}
