import 'asset_list_item.dart';

class AssetListResponse {
  final String message;
  final List<AssetListItem> data;

  AssetListResponse({required this.message, required this.data});

  factory AssetListResponse.fromJson(Map<String, dynamic> json) {
    return AssetListResponse(
      message: json['message'] ?? '',
      data:
          (json['data'] as List?)
              ?.map((e) => AssetListItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}