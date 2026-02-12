import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../utils/helpers/permission_helper.dart';
import '../../../../data/models/response/asset_cycle/asset_cycle_model.dart';
import '../../../../data/models/response/asset_cycle/cycle_status_info.dart';
import '../../../../data/repositories/asset_cycle_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../data/repositories/lookup_repository.dart';
import '../../../../data/models/response/user/user_response.dart';
import '../../../../data/models/response/user/user.dart';
import '../../../../data/models/response/lookup/manufacturer_model.dart';
import '../../../../data/models/response/lookup/team_model.dart';
import '../../../../data/models/response/lookup/condition_model.dart';
import '../../../../data/models/response/lookup/location_model.dart';
import '../../../../data/models/response/lookup/costcenter_model.dart';
import '../../../../data/models/request/lookup/location_create_request.dart';
import '../../../../data/models/request/asset_cycle/asset_cycle_update_request.dart';

enum AssetCycleDetailState { idle, loading, success, error }

class AssetCycleDetailViewModel extends ChangeNotifier {
  final AssetCycleRepository _repository;
  final UserRepository _userRepository;
  final LookupRepository _lookupRepository;
  final PermissionHelper _permissionHelper = PermissionHelper();

  AssetCycleDetailViewModel(
    this._repository,
    this._userRepository,
    this._lookupRepository,
  );

  AssetCycleDetailState _state = AssetCycleDetailState.idle;
  AssetCycleDetailState get state => _state;

  AssetCycleModel? _selectedAsset;
  AssetCycleModel? get selectedAsset => _selectedAsset;

  CycleStatusInfo? _statusInfo;
  CycleStatusInfo? get statusInfo => _statusInfo;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserResponse? _user;
  UserResponse? get user => _user;

  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  final ImagePicker _picker = ImagePicker();
  File? photoCodeFile;
  File? photoAssetFile;
  File? photoLocationFile;

  ManufacturerModel? selectedManufacturer;
  TeamModel? selectedTeam;
  CostCenterModel? selectedCostCenter;
  LocationModel? selectedLocation;
  ConditionModel? selectedCondition;

  List<ConditionModel> conditions = [];

  List<User?> additionalPics = [];
  List<TextEditingController> additionalPicControllers = [];

  final DateFormat _dateFormat = DateFormat("dd-MMM-yyyy", "en_US");

  final Map<String, TextEditingController> editControllers = {
    'assetNumber': TextEditingController(),
    'assetName': TextEditingController(),
    'hbm': TextEditingController(),
    'serialNumber': TextEditingController(),
    'modelType': TextEditingController(),
    'manufacturer': TextEditingController(),
    'assetValue': TextEditingController(),
    'costCenter': TextEditingController(),
    'team': TextEditingController(),
    'condition': TextEditingController(),
    'sapLocationCode': TextEditingController(),
    'area': TextEditingController(),
    'generalLocation': TextEditingController(),
    'specificLocation': TextEditingController(),
    'gpsCoordinate': TextEditingController(),
    'inventoryResult': TextEditingController(),
    'inventoryDate': TextEditingController(),
    'description': TextEditingController(),
  };

  bool get canEdit {
    if (_statusInfo != null) {
      return _statusInfo!.canEdit;
    }
    return false;
  }

  Future<void> fetchAssetDetail(int year, int cycle, String assetNumber) async {
    if (_selectedAsset == null) {
      _state = AssetCycleDetailState.loading;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      await _checkAdminStatus();

      if (conditions.isEmpty) await _fetchConditions();

      final response = await _repository.getAssetDetail(
        year,
        cycle,
        assetNumber,
      );

      _selectedAsset = response.data;
      _statusInfo = response.status;

      _populateControllers();

      _state = AssetCycleDetailState.success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _state = AssetCycleDetailState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _checkAdminStatus() async {
    try {
      final user = await _userRepository.getMyProfile();
      _user = user;

      if (user.user.roleId == 1) {
        _isAdmin = true;
      } else {
        _isAdmin = false;
      }
      notifyListeners();
    } catch (_) {
      _isAdmin = false;
    }
  }

  Future<void> _fetchConditions() async {
    try {
      conditions = await _lookupRepository.getConditions();
    } catch (e) {
      debugPrint("Gagal load conditions: $e");
    }
  }

  void initEditMode() {
    selectedManufacturer = null;
    selectedTeam = null;
    selectedCostCenter = null;
    selectedLocation = null;
    selectedCondition = null;

    photoCodeFile = null;
    photoAssetFile = null;
    photoLocationFile = null;

    _populateControllers();

    additionalPics.clear();
    for (var c in additionalPicControllers) {
      c.dispose();
    }
    additionalPicControllers.clear();

    notifyListeners();
  }

  void _populateControllers() {
    if (_selectedAsset == null) return;
    final a = _selectedAsset!;

    editControllers['assetNumber']!.text = a.assetNumber;
    editControllers['assetName']!.text = a.assetName;
    editControllers['hbm']!.text = a.hbm ?? "";
    editControllers['serialNumber']!.text = a.serialNumber ?? "";
    editControllers['modelType']!.text = a.modelType ?? "";
    editControllers['manufacturer']!.text = a.manufacturerName ?? "";
    editControllers['assetValue']!.text = a.assetValue?.toString() ?? "";
    editControllers['costCenter']!.text = a.costCenter ?? "";
    editControllers['team']!.text = a.teamName ?? "";
    editControllers['condition']!.text = a.conditionName ?? "";
    editControllers['sapLocationCode']!.text = a.sapLocationCode ?? "";
    editControllers['area']!.text = a.area ?? "";
    editControllers['generalLocation']!.text = a.locationName ?? "";
    editControllers['specificLocation']!.text = a.specificLocation ?? "";
    editControllers['gpsCoordinate']!.text = a.gpsCoordinate ?? "";
    editControllers['inventoryResult']!.text = a.inventoryResult ?? "";
    editControllers['description']!.text = a.description ?? "";

    if (a.inventoryDate != null && a.inventoryDate!.isNotEmpty) {
      try {
        final date = DateTime.parse(a.inventoryDate!);
        editControllers['inventoryDate']!.text = _dateFormat.format(date);
      } catch (_) {
        editControllers['inventoryDate']!.text = a.inventoryDate!;
      }
    } else {
      editControllers['inventoryDate']!.text = "";
    }
  }

  Future<bool> saveAsset(int year, int cycle) async {
    _errorMessage = null;

    try {
      await _createLocationIfNeeded();

      List<String> picIds = [];
      if (_user != null) picIds.add(_user!.user.userId.toString());
      for (var pic in additionalPics) {
        if (pic != null) picIds.add(pic.userId.toString());
      }
      String picIdsStr = picIds.join(",");

      String? apiDate;
      if (editControllers['inventoryDate']!.text.isNotEmpty) {
        try {
          final date = _dateFormat.parse(
            editControllers['inventoryDate']!.text,
          );
          apiDate = DateFormat("yyyy-MM-dd").format(date);
        } catch (_) {
          apiDate = null;
        }
      }

      int? finalConditionId = selectedCondition?.conditionId;
      if (finalConditionId == null && _selectedAsset != null) {
        if (editControllers['condition']!.text ==
            (_selectedAsset!.conditionName ?? "")) {
          finalConditionId = _selectedAsset!.conditionId;
        } else {
          final match = conditions
              .where(
                (c) =>
                    c.conditionName.toLowerCase() ==
                    editControllers['condition']!.text.toLowerCase(),
              )
              .firstOrNull;
          if (match != null) finalConditionId = match.conditionId;
        }
      }

      int? finalLocationId = selectedLocation?.locationId;
      if (finalLocationId == null && _selectedAsset != null) {
        final currentLoc = editControllers['generalLocation']!.text;
        final currentArea = editControllers['area']!.text;
        final currentSap = editControllers['sapLocationCode']!.text;

        if (currentLoc == (_selectedAsset!.locationName ?? "") &&
            currentArea == (_selectedAsset!.area ?? "") &&
            currentSap == (_selectedAsset!.sapLocationCode ?? "")) {
          finalLocationId = _selectedAsset!.locationId;
        }
      }

      final request = AssetCycleUpdate(
        conditionId: finalConditionId,
        locationId: finalLocationId,
        specificLocation: editControllers['specificLocation']!.text,
        gpsCoordinate: editControllers['gpsCoordinate']!.text,
        inventoryResult: editControllers['inventoryResult']!.text,
        inventoryDate: apiDate,
        note: editControllers['description']!.text,
        picTeamFav: picIdsStr,
      );

      await _repository.updateAsset(
        year,
        cycle,
        _selectedAsset!.assetNumber,
        request,
        assetPhoto: photoAssetFile,
        codePhoto: photoCodeFile,
        locationPhoto: photoLocationFile,
      );

      return true;
    } catch (e) {
      debugPrint("ERROR Save Cycle Asset: $e");
      _errorMessage = e.toString().replaceAll("Exception: ", "");

      notifyListeners();
      return false;
    }
  }

  Future<String?> deleteAsset(int year, int cycle, String assetNumber) async {
    try {
      final response = await _repository.deleteAssetFromCycle(
        year,
        cycle,
        assetNumber,
      );
      return response.message;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      return null;
    }
  }

  Future<void> _createLocationIfNeeded() async {
    final locationName = editControllers['generalLocation']!.text.trim();
    final area = editControllers['area']!.text.trim();
    final sapCode = editControllers['sapLocationCode']!.text.trim();

    if (locationName.isEmpty) return;

    if (selectedLocation != null) {
      if (selectedLocation!.location == locationName &&
          (selectedLocation!.area ?? "") == area &&
          (selectedLocation!.sapLocationCode ?? "") == sapCode) {
        return;
      }
    }

    if (_selectedAsset != null) {
      final oldLoc = _selectedAsset!.locationName ?? "";
      final oldArea = _selectedAsset!.area ?? "";
      final oldSap = _selectedAsset!.sapLocationCode ?? "";

      if (locationName == oldLoc && area == oldArea && sapCode == oldSap) {
        return;
      }
    }

    try {
      final existingLocs = await _lookupRepository.getLocations(
        location: locationName,
        area: area,
      );

      for (var loc in existingLocs) {
        if (loc.location == locationName &&
            (loc.area ?? "") == area &&
            (loc.sapLocationCode ?? "") == sapCode) {
          selectedLocation = loc;
          return;
        }
      }
    } catch (e) {
      debugPrint("Gagal search location existing: $e");
    }

    try {
      final req = LocationCreateRequest(
        location: locationName,
        area: area,
        sapLocationCode: sapCode,
      );

      final newLocation = await _lookupRepository.createLocation(req);
      selectedLocation = newLocation;
      debugPrint(
        "Lokasi baru dibuat: ${newLocation.location} (ID: ${newLocation.locationId})",
      );
    } catch (e) {
      throw Exception("Gagal memvalidasi Lokasi Baru: $e");
    }
  }

  Future<void> pickImage(String type, ImageSource source) async {
    _errorMessage = null;
    try {
      bool hasPermission = false;
      if (source == ImageSource.camera) {
        hasPermission = await _permissionHelper.requestCameraPermission();
      } else {
        hasPermission = await _permissionHelper.requestStoragePermission();
      }

      if (!hasPermission) {
        _errorMessage =
            "Izin akses ${source == ImageSource.camera ? 'Kamera' : 'Galeri'} ditolak. Harap aktifkan di pengaturan.";
        notifyListeners();
        return;
      }

      ImageSource finalSource = source;
      if (Platform.isWindows && source == ImageSource.camera) {
        finalSource = ImageSource.gallery;
        debugPrint(
          "Windows: Mengalihkan Kamera ke Galeri (Keterbatasan Platform)",
        );
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: finalSource,
        imageQuality: 50,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        if (type == 'code') {
          photoCodeFile = file;
        } else if (type == 'asset') {
          photoAssetFile = file;
        } else if (type == 'location') {
          photoLocationFile = file;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      _errorMessage = "Gagal mengambil gambar: ${e.toString()}";
      notifyListeners();
    }
  }

  Future<List<ManufacturerModel>> searchManufacturers(String query) async {
    return await _lookupRepository.getManufacturers(query: query);
  }

  Future<List<TeamModel>> searchTeams(String query) async {
    return await _lookupRepository.getTeams(query: query);
  }

  Future<List<CostCenterModel>> searchCostCenters(String query) async {
    return await _lookupRepository.getCostCenters(query: query);
  }

  Future<List<ConditionModel>> searchConditions(String query) async {
    if (conditions.isEmpty) await _fetchConditions();
    if (query.isEmpty) return conditions;
    return conditions
        .where(
          (c) => c.conditionName.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  Future<List<String>> searchAreas(String query) async {
    try {
      var locs = await _lookupRepository.getLocations(area: query);
      return locs
          .map((e) => e.area ?? "")
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> searchSapCodes(String query) async {
    try {
      var locs = await _lookupRepository.getLocations();
      var filtered = locs;
      if (query.isNotEmpty) {
        filtered = locs
            .where(
              (l) => (l.sapLocationCode ?? "").toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .toList();
      }
      return filtered
          .map((e) => e.sapLocationCode ?? "")
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<LocationModel>> searchGeneralLocations(
    String query, {
    String? area,
  }) async {
    return await _lookupRepository.getLocations(location: query, area: area);
  }

  Future<List<User>> searchUsers(String query) async {
    try {
      final response = await _userRepository.getAllUsers(
        query: query,
        includeInactive: false,
      );
      return response.data.where((u) {
        if (u.userId == _user?.user.userId) return false;
        return !additionalPics.any((p) => p?.userId == u.userId);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  void setManufacturerText(String val) {
    selectedManufacturer = null;
    editControllers['manufacturer']!.text = val;
    notifyListeners();
  }

  void setTeamText(String val) {
    selectedTeam = null;
    editControllers['team']!.text = val;
    notifyListeners();
  }

  void setCostCenterText(String val) {
    selectedCostCenter = null;
    editControllers['costCenter']!.text = val;
    notifyListeners();
  }

  void setLocationText(String val) {
    selectedLocation = null;
    editControllers['generalLocation']!.text = val;
    notifyListeners();
  }

  void setAreaText(String val) {
    selectedLocation = null;
    editControllers['area']!.text = val;
    notifyListeners();
  }

  void setSapText(String val) {
    selectedLocation = null;
    editControllers['sapLocationCode']!.text = val;
    notifyListeners();
  }

  void setInventoryDate(DateTime date) {
    editControllers['inventoryDate']!.text = _dateFormat.format(date);
    notifyListeners();
  }

  void setTodayDate() => setInventoryDate(DateTime.now());

  Future<String?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("Layanan lokasi tidak aktif");

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      String latDir = position.latitude >= 0 ? "N" : "S";
      String lonDir = position.longitude >= 0 ? "E" : "W";
      final coord =
          "${position.latitude.abs().toStringAsFixed(3)}$latDir ${position.longitude.abs().toStringAsFixed(3)}$lonDir";

      editControllers['gpsCoordinate']!.text = coord;
      notifyListeners();
      return coord;
    } catch (e) {
      return null;
    }
  }

  int getTotalPics() => (_user != null ? 1 : 0) + additionalPics.length;

  void addPicSlot() {
    if (getTotalPics() < 5) {
      additionalPics.add(null);
      additionalPicControllers.add(TextEditingController());
      notifyListeners();
    }
  }

  void removePicSlot(int index) {
    if (index >= 0 && index < additionalPics.length) {
      additionalPics.removeAt(index);
      additionalPicControllers[index].dispose();
      additionalPicControllers.removeAt(index);
      notifyListeners();
    }
  }

  void updatePicSlot(int index, User user) {
    if (index >= 0 && index < additionalPics.length) {
      additionalPics[index] = user;
      additionalPicControllers[index].text = user.name;
      notifyListeners();
    }
  }

  Map<String, dynamic>? get statusBannerInfo {
    if (_statusInfo == null) return null;

    if (_statusInfo!.canEdit) {
      return {
        "message": "Periode aktif. Data dapat diperbarui.",
        "color": Colors.green.shade50,
        "borderColor": Colors.green.shade200,
        "icon": Icons.check_circle_outline,
        "textColor": Colors.green.shade900,
        "iconColor": Colors.green,
      };
    } else {
      return {
        "message":
            _statusInfo!.warningMessage ??
            "Periode siklus telah berakhir.",
        "color": Colors.orange.shade50,
        "borderColor": Colors.orange.shade200,
        "icon": Icons.lock_outline,
        "textColor": Colors.orange.shade900,
        "iconColor": Colors.orange,
      };
    }
  }

  @override
  void dispose() {
    for (var controller in editControllers.values) {
      controller.dispose();
    }
    for (var c in additionalPicControllers) {
      c.dispose();
    }
    super.dispose();
  }
}
