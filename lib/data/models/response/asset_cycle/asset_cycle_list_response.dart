import 'period_model.dart';

class AssetCycleListResponse {
  final String message;
  final List<PeriodModel> data;

  AssetCycleListResponse({required this.message, required this.data});

  factory AssetCycleListResponse.fromJson(Map<String, dynamic> json) {
    return AssetCycleListResponse(
      message: json['message'] ?? '',
      data:
          (json['data'] as List?)
              ?.map((e) => PeriodModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}