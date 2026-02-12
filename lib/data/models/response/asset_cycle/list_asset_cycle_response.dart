import 'asset_cycle_simple_data_model.dart';

class ListAssetCycleResponse {
  final String message;
  final List<AssetCycleSimpleDataModel> data;

  ListAssetCycleResponse({required this.message, required this.data});

  factory ListAssetCycleResponse.fromJson(Map<String, dynamic> json) {
    return ListAssetCycleResponse(
      message: json['message'] ?? '',
      data:
          (json['data'] as List?)
              ?.map((e) => AssetCycleSimpleDataModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}