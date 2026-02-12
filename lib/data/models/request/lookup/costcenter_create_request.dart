class CostcenterCreateRequest {
  final String costCenter;

  CostcenterCreateRequest({required this.costCenter});

  Map<String, dynamic> toJson() => {'costcentercode': costCenter};
}