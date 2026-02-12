class ManufacturerModel {
  final int manufacturerId;
  final String manufacturerName;

  ManufacturerModel({
    required this.manufacturerId,
    required this.manufacturerName,
  });

  factory ManufacturerModel.fromJson(Map<String, dynamic> json) {
    return ManufacturerModel(
      manufacturerId: json['manufacturerid'],
      manufacturerName: json['manufacturername'],
    );
  }
}
