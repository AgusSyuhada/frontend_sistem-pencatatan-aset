import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import '../../../data/models/response/asset_master/asset_list_item.dart';
import '../../../data/models/response/lookup/condition_model.dart';
import '../../../data/models/response/lookup/location_model.dart';
import '../../../data/repositories/asset_master_repository.dart';
import '../../../data/repositories/lookup_repository.dart';
import '../../../data/repositories/user_repository.dart';

enum AssetMasterListState { idle, loading, error, loadingMore }

class AssetMasterListViewModel extends ChangeNotifier {
  final AssetMasterRepository _assetRepository;
  final LookupRepository _lookupRepository;
  final UserRepository _userRepository;

  AssetMasterListViewModel(
    this._assetRepository,
    this._lookupRepository,
    this._userRepository,
  );

  AssetMasterListState _state = AssetMasterListState.idle;
  AssetMasterListState get state => _state;

  final List<AssetListItem> _allAssets = [];
  List<AssetListItem> get assets => _allAssets;

  List<ConditionModel> _lookupConditions = [];
  List<ConditionModel> get lookupConditions => _lookupConditions;

  List<LocationModel> _lookupLocations = [];
  List<LocationModel> get lookupLocations => _lookupLocations;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _searchQuery = "";

  Set<int> _selectedConditionIds = {};
  Set<int> get selectedConditionIds => _selectedConditionIds;

  Set<int> _selectedLocationIds = {};
  Set<int> get selectedLocationIds => _selectedLocationIds;

  final int _limit = 20;
  int _offset = 0;
  bool _hasMoreData = true;
  bool get hasMoreData => _hasMoreData;
  bool get isLoadingMore => _state == AssetMasterListState.loadingMore;

  String _sortColumn = "assetNumber";
  bool _isAscending = true;
  String get sortColumn => _sortColumn;
  bool get isAscending => _isAscending;

  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  Future<void> init() async {
    log('Initializing AssetMasterListViewModel...', name: 'AssetMasterListVM');
    await _checkUserRole();
    await _loadLookups();
    await fetchAssets(isRefresh: true);
  }

  Future<void> _checkUserRole() async {
    try {
      final response = await _userRepository.getMyProfile();
      _isAdmin = response.user.roleId == 1;
      notifyListeners();
    } catch (e) {
      log("Gagal cek role user: $e", name: 'AssetMasterListVM');
      _isAdmin = false;
    }
  }

  Future<void> _loadLookups() async {
    try {
      final conditions = await _lookupRepository.getConditions();
      final locations = await _lookupRepository.getLocations();

      _lookupConditions = conditions;
      _lookupLocations = locations;
      notifyListeners();
    } catch (e) {
      log("Gagal memuat lookup: $e", name: 'AssetMasterListVM');
    }
  }

  Future<void> fetchAssets({bool isRefresh = false}) async {
    if (isRefresh) {
      _offset = 0;
      _hasMoreData = true;
      _allAssets.clear();
      _state = AssetMasterListState.loading;
      _errorMessage = null;
    } else {
      if (!_hasMoreData || _state == AssetMasterListState.loadingMore) return;
      _state = AssetMasterListState.loadingMore;
    }
    notifyListeners();

    try {
      final response = await _assetRepository.getAll(
        query: _searchQuery,
        includeInactive: false,
        locationIds: _selectedLocationIds.isNotEmpty
            ? _selectedLocationIds.toList()
            : null,
        conditionIds: _selectedConditionIds.isNotEmpty
            ? _selectedConditionIds.toList()
            : null,
        limit: _limit,
        offset: _offset,
      );

      final List<AssetListItem> fetchedData = response.data;

      if (fetchedData.length < _limit) {
        _hasMoreData = false;
      }

      _allAssets.addAll(fetchedData);
      _offset += _limit;

      _applyLocalSort();

      if (_state != AssetMasterListState.error) {
        _state = AssetMasterListState.idle;
      }
    } catch (e) {
      log('Fetch failed: $e', name: 'AssetMasterListVM');
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _state = AssetMasterListState.error;
    } finally {
      notifyListeners();
    }
  }

  void loadMore() {
    fetchAssets(isRefresh: false);
  }

  Future<void> refreshManual() async {
    await fetchAssets(isRefresh: true);
  }

  void search(String query) {
    _searchQuery = query;
    fetchAssets(isRefresh: true);
  }

  void applyFilters({
    required Set<int> conditionIds,
    required Set<int> locationIds,
  }) {
    _selectedConditionIds = Set.from(conditionIds);
    _selectedLocationIds = Set.from(locationIds);
    fetchAssets(isRefresh: true);
  }

  void resetFilters() {
    _selectedConditionIds.clear();
    _selectedLocationIds.clear();
    fetchAssets(isRefresh: true);
  }

  void sort(String column) {
    if (_sortColumn == column) {
      _isAscending = !_isAscending;
    } else {
      _sortColumn = column;
      _isAscending = true;
    }
    _applyLocalSort();
    notifyListeners();
  }

  void _applyLocalSort() {
    _allAssets.sort((a, b) {
      int cmp = 0;
      if (_sortColumn == 'assetNumber') {
        cmp = a.assetNumber.compareTo(b.assetNumber);
      } else if (_sortColumn == 'assetName') {
        cmp = a.assetName.toLowerCase().compareTo(b.assetName.toLowerCase());
      } else if (_sortColumn == 'location') {
        cmp = (a.locationName ?? "").toLowerCase().compareTo(
          (b.locationName ?? "").toLowerCase(),
        );
      } else if (_sortColumn == 'condition') {
        cmp = (a.conditionName ?? "").toLowerCase().compareTo(
          (b.conditionName ?? "").toLowerCase(),
        );
      }
      return _isAscending ? cmp : -cmp;
    });
  }

  Future<String?> deactivateAsset(String assetNumber) async {
    try {
      final response = await _assetRepository.deactivate(assetNumber);
      _allAssets.removeWhere((a) => a.assetNumber == assetNumber);
      notifyListeners();
      return response.message;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  void resetState() {
    _allAssets.clear();
    _offset = 0;
    _searchQuery = "";
    _selectedConditionIds.clear();
    _selectedLocationIds.clear();
    _state = AssetMasterListState.idle;
    _hasMoreData = true;
    _errorMessage = null;
    _sortColumn = "assetNumber";
    _isAscending = true;
    _isAdmin = false;
  }
}
