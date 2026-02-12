import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../../utils/helpers/permission_helper.dart';
import '../../../data/models/request/asset_master/asset_create_request.dart';
import '../../../data/models/request/lookup/location_create_request.dart';
import '../../../data/models/request/lookup/manufacturer_create_request.dart';
import '../../../data/models/request/lookup/team_create_request.dart';
import '../../../data/models/request/lookup/costcenter_create_request.dart';
import '../../../data/models/response/lookup/team_model.dart';
import '../../../data/models/response/lookup/manufacturer_model.dart';
import '../../../data/models/response/lookup/condition_model.dart';
import '../../../data/models/response/lookup/location_model.dart';
import '../../../data/models/response/lookup/costcenter_model.dart';
import '../../../data/repositories/asset_master_repository.dart';
import '../../../data/repositories/lookup_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/models/response/user/user.dart';

enum AssetState { idle, loading, success, error }

class AssetMasterAddViewModel extends ChangeNotifier {
  final AssetMasterRepository _assetRepository;
  final LookupRepository _lookupRepository;
  final UserRepository _userRepository;
  final PermissionHelper _permissionHelper = PermissionHelper();

  AssetMasterAddViewModel(
    this._assetRepository,
    this._lookupRepository,
    this._userRepository,
  );

  AssetState _state = AssetState.idle;
  AssetState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  File? photoCodeFile;
  File? photoAssetFile;
  File? photoLocationFile;

  final ImagePicker _picker = ImagePicker();

  TeamModel? selectedTeam;
  ManufacturerModel? selectedManufacturer;
  LocationModel? selectedLocation;
  CostCenterModel? selectedCostCenter;
  ConditionModel? selectedCondition;

  User? currentUser;
  List<User?> additionalPics = [];
  List<TextEditingController> additionalPicControllers = [];

  List<ConditionModel> conditions = [];
  final DateFormat _dateFormat = DateFormat("dd-MMM-yyyy", "en_US");

  final Map<String, TextEditingController> controllers = {
    'assetNumber': TextEditingController(),
    'assetName': TextEditingController(),
    'hbm': TextEditingController(),
    'serialNumber': TextEditingController(),
    'modelType': TextEditingController(),
    'assetValue': TextEditingController(),
    'costCenter': TextEditingController(),
    'gpsCoordinate': TextEditingController(),
    'inventoryResult': TextEditingController(),
    'inventoryDate': TextEditingController(),
    'description': TextEditingController(),
    'picTeamFav': TextEditingController(),
    'manufacturer': TextEditingController(),
    'team': TextEditingController(),
    'condition': TextEditingController(),
    'sapLocationCode': TextEditingController(),
    'area': TextEditingController(),
    'generalLocation': TextEditingController(),
    'specificLocation': TextEditingController(),
  };

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    for (var controller in additionalPicControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void resetState() {
    _log("Resetting State...");
    _state = AssetState.idle;
    _errorMessage = null;

    controllers.forEach((key, controller) {
      controller.clear();
    });

    photoCodeFile = null;
    photoAssetFile = null;
    photoLocationFile = null;

    selectedTeam = null;
    selectedManufacturer = null;
    selectedLocation = null;
    selectedCostCenter = null;
    selectedCondition = null;

    for (var c in additionalPicControllers) {
      c.dispose();
    }
    additionalPicControllers.clear();
    additionalPics.clear();
  }

  Future<void> initData() async {
    try {
      _log("Initializing Data...");

      await Future.wait([_fetchConditions(), _fetchCurrentUser()]);

      if (controllers['inventoryDate']!.text.isEmpty) {
        setTodayDate();
      }

      notifyListeners();
    } catch (e) {
      _log("Error init data: $e");
    }
  }

  Future<void> _fetchConditions() async {
    try {
      final result = await _lookupRepository.getConditions(query: "");
      conditions = result;
    } catch (e) {
      _log("Error fetch conditions: $e");
    }
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final userResponse = await _userRepository.getMyProfile();
      currentUser = userResponse.user;

      if (currentUser != null) {
        controllers['picTeamFav']!.text = currentUser!.name;
      }
    } catch (e) {
      _log("Error fetch user: $e");
      controllers['picTeamFav']!.text = "Gagal memuat";
    }
  }

  void _log(String message) {
    developer.log("[AssetVM] $message", name: 'AssetMasterLogic');
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

  int getTotalPics() => (currentUser != null ? 1 : 0) + additionalPics.length;

  void setInventoryDate(DateTime date) {
    controllers['inventoryDate']!.text = _dateFormat.format(date);
    notifyListeners();
  }

  void setTodayDate() => setInventoryDate(DateTime.now());

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

  Future<void> getCurrentLocation() async {
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
      controllers['gpsCoordinate']!.text =
          "${position.latitude.abs().toStringAsFixed(3)}$latDir ${position.longitude.abs().toStringAsFixed(3)}$lonDir";
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<List<User>> searchUsers(String query) async {
    try {
      final response = await _userRepository.getAllUsers(
        query: query,
        includeInactive: false,
      );
      return response.data.where((u) {
        if (u.userId == currentUser?.userId) return false;
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

  Future<List<LocationModel>> searchGeneralLocations(String query) async {
    String? areaFilter = controllers['area']!.text.trim();
    if (areaFilter.isEmpty) areaFilter = null;
    return await _lookupRepository.getLocations(
      location: query,
      area: areaFilter,
    );
  }

  T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
    for (var item in items) {
      if (test(item)) return item;
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
    if (cleanText.isEmpty) return null;

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

    if (exactMatch != null) return getId(exactMatch);

    try {
      final newItem = await createFunc(cleanText);
      return getId(newItem);
    } catch (e) {
      throw Exception("Gagal membuat $label baru: $e");
    }
  }

  Future<int?> _resolveOrCreateLocationId() async {
    final sap = controllers['sapLocationCode']!.text.trim();
    final area = controllers['area']!.text.trim();
    final locName = controllers['generalLocation']!.text.trim();

    if (locName.isEmpty) return null;

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

    if (exactMatch != null) return exactMatch.locationId;

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

  Future<bool> submitAsset() async {
    _log("=== START SUBMIT ASSET (UNIFIED) ===");
    _errorMessage = null;

    List<String> emptyFields = [];

    if (controllers['assetNumber']!.text.trim().isEmpty) {
      emptyFields.add("Nomor Aset");
    }

    if (controllers['assetName']!.text.trim().isEmpty) {
      emptyFields.add("Nama Aset");
    }

    if (controllers['condition']!.text.trim().isEmpty) {
      emptyFields.add("Kondisi");
    }

    if (controllers['generalLocation']!.text.trim().isEmpty) {
      emptyFields.add("Lokasi");
    }

    if (controllers['inventoryDate']!.text.trim().isEmpty) {
      emptyFields.add("Tanggal Inventaris");
    }

    if (emptyFields.isNotEmpty) {
      _errorMessage = "Harap lengkapi kolom wajib: ${emptyFields.join(', ')}";
      notifyListeners();
      return false;
    }

    _state = AssetState.loading;
    notifyListeners();

    try {
      final manufacturerId = await _resolveOrCrateId<ManufacturerModel>(
        label: "Manufacturer",
        text: controllers['manufacturer']!.text,
        selectedItem: selectedManufacturer,
        getName: (m) => m.manufacturerName,
        getId: (m) => m.manufacturerId,
        searchFunc: (q) => _lookupRepository.getManufacturers(query: q),
        createFunc: (name) => _lookupRepository.createManufacturer(
          ManufacturerCreateRequest(manufacturerName: name),
        ),
      );

      final teamId = await _resolveOrCrateId<TeamModel>(
        label: "Team",
        text: controllers['team']!.text,
        selectedItem: selectedTeam,
        getName: (t) => t.teamName,
        getId: (t) => t.teamId,
        searchFunc: (q) => _lookupRepository.getTeams(query: q),
        createFunc: (name) =>
            _lookupRepository.createTeam(TeamCreateRequest(teamName: name)),
      );

      await _resolveOrCrateId<CostCenterModel>(
        label: "Cost Center",
        text: controllers['costCenter']!.text,
        selectedItem: selectedCostCenter,
        getName: (c) => c.costCenterCode,
        getId: (c) => c.costCenterId,
        searchFunc: (q) => _lookupRepository.getCostCenters(query: q),
        createFunc: (code) => _lookupRepository.createCostCenter(
          CostcenterCreateRequest(costCenter: code),
        ),
      );

      int? conditionId = selectedCondition?.conditionId;
      if (conditionId == null) {
        final condMatch = _firstWhereOrNull(
          conditions,
          (c) =>
              c.conditionName.toLowerCase() ==
              controllers['condition']!.text.toLowerCase(),
        );
        conditionId = condMatch?.conditionId;
      }
      if (conditionId == null) throw Exception("Kondisi Aset tidak valid.");

      final locationId = await _resolveOrCreateLocationId();
      if (locationId == null) throw Exception("Lokasi tidak valid.");

      String apiDate = "";
      try {
        apiDate = DateFormat(
          "yyyy-MM-dd",
        ).format(_dateFormat.parse(controllers['inventoryDate']!.text));
      } catch (_) {
        apiDate = DateTime.now().toIso8601String();
      }

      List<int> picIds = [];
      if (currentUser != null) picIds.add(currentUser!.userId);
      for (var pic in additionalPics) {
        if (pic != null) picIds.add(pic.userId);
      }

      final request = AssetCreateRequest(
        assetNumber: controllers['assetNumber']!.text,
        assetName: controllers['assetName']!.text,
        hbm: controllers['hbm']!.text,
        serialNumber: controllers['serialNumber']!.text,
        modelType: controllers['modelType']!.text,
        assetValue:
            double.tryParse(
              controllers['assetValue']!.text.replaceAll(',', ''),
            ) ??
            0,
        costCenter: controllers['costCenter']!.text,
        teamId: teamId,
        manufacturerId: manufacturerId,
        conditionId: conditionId,
        locationId: locationId,
        inventoryDate: apiDate,
        gpsCoordinate: controllers['gpsCoordinate']!.text,
        description: controllers['description']!.text,
        inventoryResult: controllers['inventoryResult']!.text,
        specificLocation: controllers['specificLocation']!.text,
        picTeamFav: picIds.join(","),

        assetPhoto: photoAssetFile,
        codePhoto: photoCodeFile,
        locationPhoto: photoLocationFile,
      );

      _log("Sending Create Asset Request (Multipart)...");

      await _assetRepository.create(request);

      _log("Asset Created Successfully.");

      _state = AssetState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _log("ERROR OCCURRED: $e");
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _state = AssetState.error;
      notifyListeners();
      return false;
    }
  }
}
