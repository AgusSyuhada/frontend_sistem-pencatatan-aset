import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../data/repositories/asset_master_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../data/repositories/lookup_repository.dart';
import '../../../data/models/request/asset_master/asset_update_request.dart';
import '../../../data/models/request/lookup/location_create_request.dart';
import '../../../data/models/request/lookup/manufacturer_create_request.dart';
import '../../../data/models/request/lookup/team_create_request.dart';
import '../../../data/models/request/lookup/costcenter_create_request.dart';
import '../../../data/models/response/asset_master/asset_model.dart';
import '../../../data/models/response/user/user_response.dart';
import '../../../data/models/response/user/user.dart';
import '../../../data/models/response/lookup/manufacturer_model.dart';
import '../../../data/models/response/lookup/team_model.dart';
import '../../../data/models/response/lookup/condition_model.dart';
import '../../../data/models/response/lookup/location_model.dart';
import '../../../data/models/response/lookup/costcenter_model.dart';
import '../../../utils/helpers/permission_helper.dart';

enum AssetMasterDetailState { idle, loading, success, error }

class AssetMasterDetailViewModel extends ChangeNotifier {
  final AssetMasterRepository _repository;
  final UserRepository _userRepository;
  final LookupRepository _lookupRepository;
  final PermissionHelper _permissionHelper = PermissionHelper();

  AssetMasterDetailViewModel(
    this._repository,
    this._userRepository,
    this._lookupRepository,
  );

  AssetMasterDetailState _state = AssetMasterDetailState.idle;
  AssetMasterDetailState get state => _state;

  AssetModel? _selectedAsset;
  AssetModel? get selectedAsset => _selectedAsset;

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

  final Map<String, TextEditingController> editControllers = {
    'manufacturer': TextEditingController(),
    'team': TextEditingController(),
    'costCenter': TextEditingController(),
    'area': TextEditingController(),
    'sapLocationCode': TextEditingController(),
    'generalLocation': TextEditingController(),
    'specificLocation': TextEditingController(),
    'condition': TextEditingController(),
    'gpsCoordinate': TextEditingController(),
    'inventoryDate': TextEditingController(),
    'inventoryResult': TextEditingController(),
    'assetName': TextEditingController(),
    'description': TextEditingController(),
    'hbm': TextEditingController(),
    'serialNumber': TextEditingController(),
    'modelType': TextEditingController(),
    'assetValue': TextEditingController(),
  };

  List<ConditionModel> conditions = [];

  List<User?> additionalPics = [];
  List<TextEditingController> additionalPicControllers = [];
  final DateFormat _dateFormat = DateFormat("dd-MMM-yyyy", "en_US");

  bool get canEditAsset {
    if (_isAdmin) {
      return true;
    }
    return _selectedAsset?.cycleContext?.isInActiveCycle ?? false;
  }

  bool get canEditMasterInfo => _isAdmin;

  Map<String, dynamic>? get statusInfo {
    if (_selectedAsset == null) {
      return null;
    }

    final cycleCtx = _selectedAsset!.cycleContext;
    final inCycle = cycleCtx?.isInActiveCycle ?? false;

    if (inCycle) {
      const message = "Asset sedang dalam periode cycle aktif";
      if (_isAdmin) {
        return {
          "message": message,
          "color": Colors.orange.shade50,
          "borderColor": Colors.orange.shade200,
          "icon": Icons.warning_amber_rounded,
          "textColor": Colors.orange.shade900,
          "iconColor": Colors.orange,
        };
      } else {
        return {
          "message": message,
          "color": Colors.green.shade50,
          "borderColor": Colors.green.shade200,
          "icon": Icons.check_circle_outline,
          "textColor": Colors.green.shade900,
          "iconColor": Colors.green,
        };
      }
    } else {
      const message = "Asset tidak sedang dalam periode cycle aktif";
      if (_isAdmin) {
        return {
          "message": message,
          "color": Colors.green.shade50,
          "borderColor": Colors.green.shade200,
          "icon": Icons.verified_user,
          "textColor": Colors.green.shade900,
          "iconColor": Colors.green,
        };
      } else {
        return {
          "message": message,
          "color": Colors.orange.shade50,
          "borderColor": Colors.orange.shade200,
          "icon": Icons.lock_outline,
          "textColor": Colors.orange.shade900,
          "iconColor": Colors.orange,
        };
      }
    }
  }

  Future<void> fetchAssetByNumber(String assetNumber) async {
    _state = AssetMasterDetailState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _checkUserRole();

      if (conditions.isEmpty) {
        _fetchConditions();
      }

      final response = await _repository.getOne(assetNumber);
      _selectedAsset = response.data;
      _state = AssetMasterDetailState.success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _state = AssetMasterDetailState.error;
    } finally {
      notifyListeners();
    }
  }

  void initEditMode() {
    if (_selectedAsset == null) {
      return;
    }

    selectedManufacturer = null;
    selectedTeam = null;
    selectedCostCenter = null;
    selectedLocation = null;
    selectedCondition = null;

    final a = _selectedAsset!;
    editControllers['manufacturer']!.text = a.manufacturerName ?? "";
    editControllers['team']!.text = a.teamName ?? "";
    editControllers['costCenter']!.text = a.costCenter ?? "";
    editControllers['area']!.text = a.area ?? "";
    editControllers['sapLocationCode']!.text = a.sapLocationCode ?? "";
    editControllers['generalLocation']!.text = a.locationName ?? "";
    editControllers['specificLocation']!.text = a.specificLocation ?? "";
    editControllers['condition']!.text = a.conditionName ?? "";
    editControllers['gpsCoordinate']!.text = a.gpsCoordinate ?? "";
    editControllers['inventoryResult']!.text = a.inventoryResult ?? "";
    editControllers['assetName']!.text = a.assetName ?? "";
    editControllers['description']!.text = a.description ?? "";
    editControllers['hbm']!.text = a.hbm ?? "";
    editControllers['serialNumber']!.text = a.serialNumber ?? "";
    editControllers['modelType']!.text = a.modelType ?? "";
    editControllers['assetValue']!.text = a.assetValue?.toString() ?? "0";

    if (a.inventoryDate != null) {
      try {
        final date = DateTime.parse(a.inventoryDate!);
        editControllers['inventoryDate']!.text = _dateFormat.format(date);
      } catch (_) {
        editControllers['inventoryDate']!.text = a.inventoryDate!;
      }
    } else {
      editControllers['inventoryDate']!.text = _dateFormat.format(
        DateTime.now(),
      );
    }

    photoCodeFile = null;
    photoAssetFile = null;
    photoLocationFile = null;

    additionalPics.clear();
    for (var c in additionalPicControllers) {
      c.dispose();
    }
    additionalPicControllers.clear();

    notifyListeners();
  }

  void setInventoryDate(DateTime date) {
    if (!_isAdmin) return;

    editControllers['inventoryDate']!.text = _dateFormat.format(date);
    notifyListeners();
  }

  void setTodayDate() => setInventoryDate(DateTime.now());

  void setManufacturerText(String val) {
    if (!_isAdmin) return;
    selectedManufacturer = null;
    editControllers['manufacturer']!.text = val;
    notifyListeners();
  }

  void setTeamText(String val) {
    if (!_isAdmin) return;
    selectedTeam = null;
    editControllers['team']!.text = val;
    notifyListeners();
  }

  void setCostCenterText(String val) {
    if (!_isAdmin) return;
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

  Future<void> _checkUserRole() async {
    try {
      final response = await _userRepository.getMyProfile();
      _user = response;
      _isAdmin = response.user.roleId == 1;
    } catch (e) {
      _log("Gagal cek role user: $e");
      _isAdmin = false;
    }
  }

  Future<void> _fetchConditions() async {
    try {
      final result = await _lookupRepository.getConditions(query: "");
      conditions = result;
      notifyListeners();
    } catch (e) {
      _log("Error fetch conditions: $e");
    }
  }

  Future<String?> deactivateAsset(String assetNumber) async {
    try {
      final response = await _repository.deactivate(assetNumber);
      return response.message;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      return null;
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
      _log("Error picking image: $e");
      _errorMessage = "Gagal mengambil gambar: ${e.toString()}";
      notifyListeners();
    }
  }

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

  int getTotalPics() => (_user != null ? 1 : 0) + additionalPics.length;

  Future<List<User>> searchUsers(String query) async {
    try {
      final response = await _userRepository.getAllUsers(
        query: query,
        includeInactive: false,
      );
      return response.data.where((u) {
        if (u.userId == _user?.user.userId) {
          return false;
        }
        return !additionalPics.any((p) => p?.userId == u.userId);
      }).toList();
    } catch (e) {
      return [];
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
    if (conditions.isEmpty) {
      await _fetchConditions();
    }
    if (query.isEmpty) {
      return conditions;
    }
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
    } catch (e) {
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
    } catch (e) {
      return [];
    }
  }

  Future<List<LocationModel>> searchGeneralLocations(
    String query, {
    String? area,
  }) async {
    return await _lookupRepository.getLocations(location: query, area: area);
  }

  Future<String?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Layanan lokasi tidak aktif");
      }
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

      if (editControllers['gpsCoordinate'] != null) {
        editControllers['gpsCoordinate']!.text = coord;
        notifyListeners();
      }
      return coord;
    } catch (e) {
      _log("Gagal ambil lokasi: $e");
      return null;
    }
  }

  T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
    for (var item in items) {
      if (test(item)) {
        return item;
      }
    }
    return null;
  }

  Future<int?> _resolveOrCrateId<T>({
    required String label,
    required String text,
    required T? selectedItem,
    required String Function(T) getName,
    required int? Function(T) getId,
    required Future<List<T>> Function(String) searchFunc,
    required Future<T> Function(String) createFunc,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      return null;
    }
    if (selectedItem != null) {
      if (getName(selectedItem).toLowerCase() == cleanText.toLowerCase()) {
        return getId(selectedItem);
      }
    }
    final searchResults = await searchFunc(cleanText);
    final exactMatch = _firstWhereOrNull(
      searchResults,
      (item) => getName(item).toLowerCase() == cleanText.toLowerCase(),
    );
    if (exactMatch != null) {
      return getId(exactMatch);
    }
    try {
      final newItem = await createFunc(cleanText);
      return getId(newItem);
    } catch (e) {
      throw Exception("Gagal membuat $label baru: $e");
    }
  }

  Future<int?> _resolveOrCreateLocationId() async {
    final sap = editControllers['sapLocationCode']!.text.trim();
    final area = editControllers['area']!.text.trim();
    final locName = editControllers['generalLocation']!.text.trim();

    if (locName.isEmpty) {
      return null;
    }
    if (selectedLocation != null &&
        (selectedLocation!.sapLocationCode ?? "") == sap &&
        (selectedLocation!.area ?? "") == area &&
        (selectedLocation!.location ?? "") == locName) {
      return selectedLocation!.locationId;
    }
    final results = await _lookupRepository.getLocations(
      location: locName,
      area: area,
    );
    final exactMatch = _firstWhereOrNull(
      results,
      (l) =>
          (l.sapLocationCode ?? "").toLowerCase() == sap.toLowerCase() &&
          (l.area ?? "").toLowerCase() == area.toLowerCase() &&
          (l.location ?? "").toLowerCase() == locName.toLowerCase(),
    );
    if (exactMatch != null) {
      return exactMatch.locationId;
    }
    try {
      final newLoc = await _lookupRepository.createLocation(
        LocationCreateRequest(
          sapLocationCode: sap,
          area: area,
          location: locName,
        ),
      );
      return newLoc.locationId;
    } catch (e) {
      throw Exception("Gagal membuat Lokasi baru: $e");
    }
  }

  Future<bool> saveAssetChanges() async {
    if (_selectedAsset == null) {
      return false;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      int? manufacturerId;
      int? teamId;

      if (_isAdmin) {
        manufacturerId = await _resolveOrCrateId<ManufacturerModel>(
          label: "Manufacturer",
          text: editControllers['manufacturer']!.text,
          selectedItem: selectedManufacturer,
          getName: (m) => m.manufacturerName,
          getId: (m) => m.manufacturerId,
          searchFunc: (q) => _lookupRepository.getManufacturers(query: q),
          createFunc: (name) => _lookupRepository.createManufacturer(
            ManufacturerCreateRequest(manufacturerName: name),
          ),
        );

        teamId = await _resolveOrCrateId<TeamModel>(
          label: "Team",
          text: editControllers['team']!.text,
          selectedItem: selectedTeam,
          getName: (t) => t.teamName,
          getId: (t) => t.teamId,
          searchFunc: (q) => _lookupRepository.getTeams(query: q),
          createFunc: (name) =>
              _lookupRepository.createTeam(TeamCreateRequest(teamName: name)),
        );

        await _resolveOrCrateId<CostCenterModel>(
          label: "Cost Center",
          text: editControllers['costCenter']!.text,
          selectedItem: selectedCostCenter,
          getName: (c) => c.costCenterCode,
          getId: (c) => c.costCenterId,
          searchFunc: (q) => _lookupRepository.getCostCenters(query: q),
          createFunc: (code) => _lookupRepository.createCostCenter(
            CostcenterCreateRequest(costCenter: code),
          ),
        );
      }

      final locationId = await _resolveOrCreateLocationId();

      int? conditionId;
      if (selectedCondition != null) {
        conditionId = selectedCondition!.conditionId;
      } else if (editControllers['condition']!.text.isNotEmpty) {
        final condText = editControllers['condition']!.text;
        final match = _firstWhereOrNull(
          conditions,
          (c) => c.conditionName.toLowerCase() == condText.toLowerCase(),
        );
        conditionId = match?.conditionId;
        if (conditionId == null) {
          throw Exception(
            "Kondisi '$condText' tidak valid. Pilih dari daftar.",
          );
        }
      }

      final old = _selectedAsset!;

      String? getIfChanged(String key, String? oldVal) {
        final newVal = editControllers[key]!.text.trim();
        return newVal != (oldVal ?? "") ? newVal : null;
      }

      int? getIfIdChanged(int? newId, int? oldId) {
        return newId != oldId ? newId : null;
      }

      String? apiDate;

      if (_isAdmin) {
        try {
          final dateText = editControllers['inventoryDate']!.text;
          if (dateText != (old.inventoryDate ?? "")) {
            apiDate = DateFormat(
              "yyyy-MM-dd",
            ).format(_dateFormat.parse(dateText));
          }
        } catch (_) {}
      }

      double? assetVal;

      if (_isAdmin) {
        final valStr = editControllers['assetValue']!.text.replaceAll(',', '');
        final oldVal = old.assetValue ?? 0;
        if ((double.tryParse(valStr) ?? 0) != oldVal) {
          assetVal = double.tryParse(valStr);
        }
      }

      String? picIdsStr;
      List<int> currentIds = [];
      if (_user != null) {
        currentIds.add(_user!.user.userId);
      }
      for (var p in additionalPics) {
        if (p != null) {
          currentIds.add(p.userId);
        }
      }
      currentIds.sort();

      if (currentIds.isNotEmpty) {
        picIdsStr = currentIds.join(",");
      }

      final request = AssetUpdateRequest(
        assetName: _isAdmin ? getIfChanged('assetName', old.assetName) : null,
        hbm: _isAdmin ? getIfChanged('hbm', old.hbm) : null,
        serialNumber: _isAdmin
            ? getIfChanged('serialNumber', old.serialNumber)
            : null,
        modelType: _isAdmin ? getIfChanged('modelType', old.modelType) : null,
        assetValue: assetVal,
        inventoryDate: apiDate,
        costCenter: _isAdmin ? editControllers['costCenter']!.text : null,
        manufacturerId: _isAdmin
            ? getIfIdChanged(manufacturerId, old.manufacturerId)
            : null,
        teamId: _isAdmin ? getIfIdChanged(teamId, old.teamId) : null,

        description: getIfChanged('description', old.description),
        specificLocation: getIfChanged(
          'specificLocation',
          old.specificLocation,
        ),
        inventoryResult: getIfChanged('inventoryResult', old.inventoryResult),
        gpsCoordinate: getIfChanged('gpsCoordinate', old.gpsCoordinate),

        conditionId: getIfIdChanged(conditionId, old.conditionId),
        locationId: getIfIdChanged(locationId, old.locationId),

        picTeamFav: picIdsStr,
        assetPhoto: photoAssetFile,
        codePhoto: photoCodeFile,
        locationPhoto: photoLocationFile,
      );

      await _repository.update(old.assetNumber, request);

      _state = AssetMasterDetailState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _log("ERROR Save: $e");
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      notifyListeners();
      return false;
    }
  }

  void _log(String msg) {
    debugPrint("[DetailVM] $msg");
  }

  @override
  void dispose() {
    for (var c in additionalPicControllers) {
      c.dispose();
    }
    for (var c in editControllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}
