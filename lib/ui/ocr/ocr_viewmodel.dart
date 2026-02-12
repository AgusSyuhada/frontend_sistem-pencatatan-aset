import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../data/repositories/ocr_repository.dart';
import '../../../../data/models/response/ocr_response.dart';

enum OcrState { idle, loading, successFound, successNotFound, error }

class OcrViewModel extends ChangeNotifier {
  final OcrRepository _repository;

  OcrViewModel(this._repository);

  OcrState _state = OcrState.idle;
  OcrState get state => _state;

  String? _foundAssetNumber;
  String? get foundAssetNumber => _foundAssetNumber;

  String? _message;
  String? get message => _message;

  OcrResponse? _lastResponse;
  OcrResponse? get lastResponse => _lastResponse;

  Future<bool> checkCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      status = await Permission.camera.request();
    }
    return status.isGranted;
  }

  void resetState() {
    _state = OcrState.idle;
    _foundAssetNumber = null;
    _message = null;
    _lastResponse = null;
    notifyListeners();
  }

  Future<void> scanImage(Uint8List imageBytes) async {
    _state = OcrState.loading;
    _message = null;
    notifyListeners();

    try {
      final response = await _repository.scanImage(imageBytes);
      _lastResponse = response;

      _message = response.message;

      if (response.found && response.assetNumber != null) {
        _foundAssetNumber = response.assetNumber;
        _state = OcrState.successFound;
      } else {
        _foundAssetNumber = null;
        _state = OcrState.successNotFound;
      }
    } catch (e) {
      _message = e.toString().replaceAll("Exception: ", "");
      _state = OcrState.error;
    } finally {
      notifyListeners();
    }
  }
}
