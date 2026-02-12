import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../data/local/preferences/session_manager.dart';
import '../../../utils/helpers/permission_helper.dart';

enum PermissionResult { granted, denied, permanentlyDenied, error }

class TermsViewModel extends ChangeNotifier {
  final SessionManager _sessionManager;
  final PermissionHelper _permissionHelper = PermissionHelper();

  TermsViewModel(this._sessionManager);

  final ScrollController scrollController = ScrollController();

  bool _isScrolledToEnd = false;
  bool get isScrolledToEnd => _isScrolledToEnd;

  bool _isAgreed = false;
  bool get isAgreed => _isAgreed;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  PermissionResult? _permissionResult;
  PermissionResult? get permissionResult => _permissionResult;

  String _permissionMessage = '';
  String get permissionMessage => _permissionMessage;

  void initialize() {
    scrollController.addListener(() {
      if (!scrollController.hasClients) return;
      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.position.pixels;

      if (currentScroll >= (maxScroll - 20)) {
        if (!_isScrolledToEnd) {
          _isScrolledToEnd = true;
          notifyListeners();
        }
      } else {
        if (_isScrolledToEnd) {
          _isScrolledToEnd = false;
          notifyListeners();
        }
      }
    });
  }

  void setAgreement(bool? value) {
    if (value != null) {
      _isAgreed = value;
      notifyListeners();
    }
  }

  Future<void> openSettings() async {
    await _permissionHelper.openSettings();
  }

  Future<void> proceed() async {
    _isLoading = true;
    _errorMessage = null;
    _permissionResult = null;
    notifyListeners();

    try {
      await _sessionManager.setAgreedToTerms();

      final statuses = await _permissionHelper.requestNecessaryPermissions();

      final locationStatus =
          statuses[Permission.location] ?? PermissionStatus.denied;
      final cameraStatus =
          statuses[Permission.camera] ?? PermissionStatus.denied;

      bool isLocationOk = _permissionHelper.isGranted(locationStatus);
      bool isCameraOk = _permissionHelper.isGranted(cameraStatus);

      bool isStorageOk = true;
      if (statuses.containsKey(Permission.storage)) {
        isStorageOk = _permissionHelper.isGranted(
          statuses[Permission.storage]!,
        );
      } else if (statuses.containsKey(Permission.photos)) {
        isStorageOk = _permissionHelper.isGranted(statuses[Permission.photos]!);
      }

      _isLoading = false;

      if (isLocationOk && isCameraOk && isStorageOk) {
        _permissionResult = PermissionResult.granted;
      } else if (_permissionHelper.isPermanentlyDenied(locationStatus) ||
          _permissionHelper.isPermanentlyDenied(cameraStatus) ||
          (statuses.containsKey(Permission.storage) &&
              _permissionHelper.isPermanentlyDenied(
                statuses[Permission.storage]!,
              )) ||
          (statuses.containsKey(Permission.photos) &&
              _permissionHelper.isPermanentlyDenied(
                statuses[Permission.photos]!,
              ))) {
        _permissionResult = PermissionResult.permanentlyDenied;
        _permissionMessage =
            'Aplikasi memerlukan izin Lokasi, Kamera, dan Penyimpanan. Mohon aktifkan di pengaturan aplikasi.';
      } else {
        _permissionResult = PermissionResult.denied;
        _permissionMessage =
            'Izin Lokasi, Kamera, dan Penyimpanan diperlukan untuk melanjutkan.';
      }

      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Terjadi kesalahan: $e";
      _permissionResult = PermissionResult.error;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
