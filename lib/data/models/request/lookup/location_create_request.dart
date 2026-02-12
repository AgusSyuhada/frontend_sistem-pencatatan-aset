class LocationCreateRequest {
  final String sapLocationCode;
  final String area;
  final String location;

  LocationCreateRequest({
    required this.sapLocationCode,
    required this.area,
    required this.location,
  });

  Map<String, dynamic> toJson() => {
    'saplocationcode': sapLocationCode,
    'area': area,
    'location': location,
  };
}