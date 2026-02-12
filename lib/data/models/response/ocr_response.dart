class CyclePeriodInfo {
  final int year;
  final int cycle;

  CyclePeriodInfo({required this.year, required this.cycle});

  factory CyclePeriodInfo.fromJson(Map<String, dynamic> json) {
    return CyclePeriodInfo(year: json['year'] ?? 0, cycle: json['cycle'] ?? 0);
  }
}

class CycleStatusInfo {
  final bool isInCycle;
  final CyclePeriodInfo? cyclePeriod;
  final bool canEdit;
  final String? warningMessage;

  CycleStatusInfo({
    required this.isInCycle,
    this.cyclePeriod,
    required this.canEdit,
    this.warningMessage,
  });

  factory CycleStatusInfo.fromJson(Map<String, dynamic> json) {
    return CycleStatusInfo(
      isInCycle: json['is_in_cycle'] ?? false,
      cyclePeriod: json['cycle_period'] != null
          ? CyclePeriodInfo.fromJson(json['cycle_period'])
          : null,
      canEdit: json['can_edit'] ?? false,
      warningMessage: json['warning_message'],
    );
  }
}

class OcrResponse {
  final String message;
  final bool found;
  final String? assetNumber;
  final String? assetName;
  final List<String> rawText;
  final CycleStatusInfo? status;

  OcrResponse({
    required this.message,
    required this.found,
    this.assetNumber,
    this.assetName,
    required this.rawText,
    this.status,
  });

  factory OcrResponse.fromJson(Map<String, dynamic> json) {
    return OcrResponse(
      message: json['message'] ?? '',
      found: json['found'] ?? false,
      assetNumber: json['asset_number'],
      assetName: json['asset_name'],
      rawText: json['raw_text'] != null
          ? List<String>.from(json['raw_text'])
          : [],
      status: json['status'] != null
          ? CycleStatusInfo.fromJson(json['status'])
          : null,
    );
  }
}
