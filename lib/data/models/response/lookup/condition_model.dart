class ConditionModel {
  final int conditionId;
  final String conditionName;

  ConditionModel({required this.conditionId, required this.conditionName});

  factory ConditionModel.fromJson(Map<String, dynamic> json) {
    return ConditionModel(
      conditionId: json['conditionid'],
      conditionName: json['conditionname'],
    );
  }
}
