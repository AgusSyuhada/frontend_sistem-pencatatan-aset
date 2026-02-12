class ConditionCreateRequest {
  final String conditionName;

  ConditionCreateRequest({required this.conditionName});

  Map<String, dynamic> toJson() => {'conditionname': conditionName};
}