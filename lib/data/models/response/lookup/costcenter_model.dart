class CostCenterModel {
  final int costCenterId;
  final String costCenterCode;

  CostCenterModel({required this.costCenterId, required this.costCenterCode});

  factory CostCenterModel.fromJson(Map<String, dynamic> json) {
    return CostCenterModel(
      costCenterId: json['costcenterid'],
      costCenterCode: json['costcentercode'],
    );
  }
}
