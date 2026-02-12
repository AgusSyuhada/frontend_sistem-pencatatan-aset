import 'asset_cycle_context.dart';
import 'asset_model.dart';

class SingleAssetResponse {
  final String message;
  final AssetModel data;
  final AssetCycleContext? cycleContext;

  SingleAssetResponse({
    required this.message,
    required this.data,
    this.cycleContext,
  });

  factory SingleAssetResponse.fromJson(Map<String, dynamic> json) {
    final context = json['cycle_context'] != null
        ? AssetCycleContext.fromJson(json['cycle_context'])
        : null;

    return SingleAssetResponse(
      message: json['message'] ?? '',
      data: AssetModel.fromJson(json['data'], context: context),
      cycleContext: context,
    );
  }
}