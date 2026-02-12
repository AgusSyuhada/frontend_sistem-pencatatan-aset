import 'asset_cycle_model.dart';
import 'cycle_status_info.dart';

class SingleAssetCycleResponse {
  final String message;
  final AssetCycleModel data;
  final CycleStatusInfo? status;

  SingleAssetCycleResponse({
    required this.message,
    required this.data,
    this.status,
  });

  factory SingleAssetCycleResponse.fromJson(Map<String, dynamic> json) {
    return SingleAssetCycleResponse(
      message: json['message'] ?? '',
      data: AssetCycleModel.fromJson(json['data']),
      status: json['status'] != null
          ? CycleStatusInfo.fromJson(json['status'])
          : null,
    );
  }
}