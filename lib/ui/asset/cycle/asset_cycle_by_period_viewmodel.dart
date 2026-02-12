import 'package:flutter/material.dart';
import '../../../data/models/response/asset_cycle/asset_cycle_simple_data_model.dart';
import '../../../data/repositories/asset_cycle_repository.dart';
import '../../../data/repositories/user_repository.dart';

enum AssetCycleByPeriodState { idle, loading, error }

class AssetCycleByPeriodViewModel extends ChangeNotifier {
  final AssetCycleRepository _repository;
  final UserRepository _userRepository;

  AssetCycleByPeriodViewModel(this._repository, this._userRepository);

  AssetCycleByPeriodState _state = AssetCycleByPeriodState.idle;
  AssetCycleByPeriodState get state => _state;

  List<AssetCycleSimpleDataModel> _allAssets = [];
  List<AssetCycleSimpleDataModel> _displayAssets = [];
  List<AssetCycleSimpleDataModel> get assets => _displayAssets;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _year = 0;
  int _cycle = 0;

  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  String _searchQuery = "";
  Set<String> _selectedConditions = {};
  Set<String> get selectedConditions => _selectedConditions;
  Set<String> _selectedLocations = {};
  Set<String> get selectedLocations => _selectedLocations;
  String _selectedStatus = "Semua";
  String get selectedStatus => _selectedStatus;

  String _sortColumn = 'assetNumber';
  String get sortColumn => _sortColumn;
  bool _isAscending = true;
  bool get isAscending => _isAscending;

  List<String> get statusOptions => [
    "Semua",
    "Sudah Di-cycle",
    "Belum Di-cycle",
  ];
  List<String> get uniqueConditions =>
      _allAssets.map((e) => e.conditionName ?? "Tanpa Kondisi").toSet().toList()
        ..sort();
  List<String> get uniqueLocations =>
      _allAssets.map((e) => e.locationName ?? "Tanpa Lokasi").toSet().toList()
        ..sort();

  Future<void> init(int year, int cycle) async {
    _year = year;
    _cycle = cycle;
    await _checkAdminStatus();
    await fetchAssets();
  }

  void resetState() {
    _searchQuery = "";
    _selectedConditions.clear();
    _selectedLocations.clear();
    _selectedStatus = "Semua";
    _sortColumn = 'assetNumber';
    _isAscending = true;
    _allAssets = [];
    _displayAssets = [];
    _errorMessage = null;
    _state = AssetCycleByPeriodState.idle;
    notifyListeners();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final user = await _userRepository.getMyProfile();

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

  Future<void> fetchAssets() async {
    _state = AssetCycleByPeriodState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.getAssetsByCycle(
        _year,
        _cycle,
        limit: 1000,
      );
      _allAssets = response.data;
      _applyFilters();
      _state = AssetCycleByPeriodState.idle;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _state = AssetCycleByPeriodState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<String?> deleteAsset(String assetNumber) async {
    try {
      final response = await _repository.deleteAssetFromCycle(
        _year,
        _cycle,
        assetNumber,
      );

      _allAssets.removeWhere((a) => a.assetNumber == assetNumber);
      _applyFilters();
      notifyListeners();

      return response.message;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      notifyListeners();
      return null;
    }
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void applyFilters({
    required Set<String> conditions,
    required Set<String> locations,
    required String status,
  }) {
    _selectedConditions = conditions;
    _selectedLocations = locations;
    _selectedStatus = status;
    _applyFilters();
    notifyListeners();
  }

  void resetFilters() {
    _selectedConditions.clear();
    _selectedLocations.clear();
    _selectedStatus = "Semua";
    _applyFilters();
    notifyListeners();
  }

  void sort(String column) {
    if (_sortColumn == column) {
      _isAscending = !_isAscending;
    } else {
      _sortColumn = column;
      _isAscending = true;
    }
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    List<AssetCycleSimpleDataModel> temp = List.from(_allAssets);

    if (_selectedStatus == "Sudah Di-cycle") {
      temp = temp.where((a) => a.isCycled).toList();
    } else if (_selectedStatus == "Belum Di-cycle") {
      temp = temp.where((a) => !a.isCycled).toList();
    }

    if (_selectedConditions.isNotEmpty) {
      temp = temp
          .where(
            (a) => _selectedConditions.contains(
              a.conditionName ?? "Tanpa Kondisi",
            ),
          )
          .toList();
    }

    if (_selectedLocations.isNotEmpty) {
      temp = temp
          .where(
            (a) =>
                _selectedLocations.contains(a.locationName ?? "Tanpa Lokasi"),
          )
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      temp = temp.where((a) {
        return a.assetNumber.toLowerCase().contains(q) ||
            (a.assetName.toLowerCase().contains(q)) ||
            (a.locationName?.toLowerCase().contains(q) ?? false) ||
            (a.conditionName?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    temp.sort((a, b) {
      int cmp = 0;
      switch (_sortColumn) {
        case 'assetNumber':
          cmp = a.assetNumber.compareTo(b.assetNumber);
          break;
        case 'assetName':
          cmp = a.assetName.toLowerCase().compareTo(b.assetName.toLowerCase());
          break;
        case 'location':
          cmp = (a.locationName ?? "").compareTo(b.locationName ?? "");
          break;
        case 'condition':
          cmp = (a.conditionName ?? "").compareTo(b.conditionName ?? "");
          break;
        case 'status':
          if (a.isCycled == b.isCycled) {
            cmp = 0;
          } else {
            cmp = a.isCycled ? 1 : -1;
          }
          break;
        default:
          cmp = 0;
      }
      return _isAscending ? cmp : -cmp;
    });

    _displayAssets = temp;
  }
}
