class ManufacturerCreateRequest {
  final String manufacturerName;

  ManufacturerCreateRequest({required this.manufacturerName});

  Map<String, dynamic> toJson() => {'manufacturername': manufacturerName};
}