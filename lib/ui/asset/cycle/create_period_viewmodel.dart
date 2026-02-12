import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../../../data/models/request/asset_cycle/create_period_request.dart';
import '../../../data/models/request/asset_cycle/update_period_request.dart';
import '../../../data/models/response/asset_master/asset_list_item.dart';
import '../../../data/repositories/asset_cycle_repository.dart';
import '../../../data/repositories/asset_master_repository.dart';

enum CreatePeriodStep { formInput, selectAssets, review }

enum CreatePeriodState { idle, loading, error, loadingMore, submitting }

class CreatePeriodViewModel extends ChangeNotifier {
  final AssetCycleRepository _cycleRepository;
  final AssetMasterRepository _assetMasterRepository;

  CreatePeriodViewModel(this._cycleRepository, this._assetMasterRepository);

  CreatePeriodStep _currentStep = CreatePeriodStep.formInput;
  CreatePeriodStep get currentStep => _currentStep;

  bool _isEditMode = false;
  bool get isEditMode => _isEditMode;

  int? _selectedYear;
  int? _selectedCycle;

  int? get selectedYear => _selectedYear;
  int? get selectedCycle => _selectedCycle;

  List<int> get yearList {
    int current = DateTime.now().year;
    return List.generate(11, (index) => (current - 5) + index);
  }

  CreatePeriodState _state = CreatePeriodState.idle;
  CreatePeriodState get state => _state;

  final List<AssetListItem> _availableAssets = [];
  List<AssetListItem> get availableAssets => _availableAssets;

  final List<AssetListItem> _priorityAssets = [];
  int _priorityIndex = 0;

  final Set<String> _selectedAssetNumbers = {};
  Set<String> get selectedAssetNumbers => _selectedAssetNumbers;

  final Set<String> _initialAssetNumbers = {};

  bool get hasChanges {
    if (!_isEditMode) return true;
    return !const SetEquality().equals(
      _initialAssetNumbers,
      _selectedAssetNumbers,
    );
  }

  final List<AssetListItem> _previewSelectedAssets = [];
  List<AssetListItem> get previewSelectedAssets => _previewSelectedAssets;

  String _searchQuery = "";
  final int _limit = 20;
  int _apiOffset = 0;
  bool _hasMoreData = true;
  bool get hasMoreData => _hasMoreData;
  bool get isLoadingMore => _state == CreatePeriodState.loadingMore;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> init({int? year, int? cycle}) async {
    _resetAll();
    if (year != null && cycle != null) {
      _isEditMode = true;
      _selectedYear = year;
      _selectedCycle = cycle;
      await _fetchExistingPeriodAssets();
    }
  }

  Future<void> _fetchExistingPeriodAssets() async {
    if (_selectedYear == null || _selectedCycle == null) return;

    _state = CreatePeriodState.loading;
    notifyListeners();

    try {
      final response = await _cycleRepository.getAssetsByCycle(
        _selectedYear!,
        _selectedCycle!,
        limit: 1000,
      );

      _initialAssetNumbers.clear();
      _priorityAssets.clear();

      for (var item in response.data) {
        _selectedAssetNumbers.add(item.assetNumber);
        _initialAssetNumbers.add(item.assetNumber);

        _priorityAssets.add(
          AssetListItem(
            assetNumber: item.assetNumber,
            assetName: item.assetName,
            locationName: item.locationName,
            conditionName: item.conditionName,
            isActive: true,
          ),
        );
      }

      _state = CreatePeriodState.idle;
    } catch (e) {
      _errorMessage = "Gagal memuat data aset siklus: $e";
      _state = CreatePeriodState.error;
    } finally {
      notifyListeners();
    }
  }

  void setYear(int? year) {
    if (_isEditMode) return;
    _selectedYear = year;
    notifyListeners();
  }

  void setCycle(int? cycle) {
    if (_isEditMode) return;
    _selectedCycle = cycle;
    notifyListeners();
  }

  Future<void> nextStep() async {
    if (_currentStep == CreatePeriodStep.formInput) {
      if (_selectedYear == null || _selectedCycle == null) return;
      _currentStep = CreatePeriodStep.selectAssets;
      fetchAssets(isRefresh: true);
    } else if (_currentStep == CreatePeriodStep.selectAssets) {
      if (_selectedAssetNumbers.isEmpty) return;
      _preparePreviewData();
      _currentStep = CreatePeriodStep.review;
    }
    notifyListeners();
  }

  void prevStep() {
    _errorMessage = null;
    if (_currentStep == CreatePeriodStep.review) {
      _currentStep = CreatePeriodStep.selectAssets;
    } else if (_currentStep == CreatePeriodStep.selectAssets) {
      _currentStep = CreatePeriodStep.formInput;
    }
    notifyListeners();
  }

  void toggleAssetSelection(AssetListItem asset) {
    if (_selectedAssetNumbers.contains(asset.assetNumber)) {
      _selectedAssetNumbers.remove(asset.assetNumber);
    } else {
      _selectedAssetNumbers.add(asset.assetNumber);
    }
    notifyListeners();
  }

  void resetSelection() {
    _selectedAssetNumbers.clear();
    notifyListeners();
  }

  void resetSearch() {
    _searchQuery = "";
    fetchAssets(isRefresh: true);
  }

  Future<void> fetchAssets({bool isRefresh = false}) async {
    if (isRefresh) {
      _apiOffset = 0;
      _priorityIndex = 0;
      _hasMoreData = true;
      _availableAssets.clear();

      _state = CreatePeriodState.loading;
      _errorMessage = null;
    } else {
      if (!_hasMoreData || _state == CreatePeriodState.loadingMore) return;
      _state = CreatePeriodState.loadingMore;
    }
    notifyListeners();

    try {
      if (_searchQuery.isNotEmpty) {
        await _fetchAssetsWithSearch();
      } else {
        await _fetchAssetsHybrid();
      }

      _state = CreatePeriodState.idle;
    } catch (e) {
      _state = CreatePeriodState.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> _fetchAssetsWithSearch() async {
    final response = await _assetMasterRepository.getAll(
      query: _searchQuery,
      includeInactive: false,
      limit: _limit,
      offset: _apiOffset,
    );

    final List<AssetListItem> newAssets = response.data;
    if (newAssets.length < _limit) {
      _hasMoreData = false;
    }

    _availableAssets.addAll(newAssets);
    _apiOffset += _limit;
  }

  Future<void> _fetchAssetsHybrid() async {
    int needed = _limit;

    int remainingInPriority = _priorityAssets.length - _priorityIndex;
    if (remainingInPriority > 0) {
      int take = remainingInPriority > needed ? needed : remainingInPriority;

      final batch = _priorityAssets.getRange(
        _priorityIndex,
        _priorityIndex + take,
      );
      _availableAssets.addAll(batch);

      _priorityIndex += take;
      needed -= take;
    }

    if (needed > 0 && _hasMoreData) {
      final response = await _assetMasterRepository.getAll(
        query: "",
        includeInactive: false,
        limit: needed,
        offset: _apiOffset,
      );

      final List<AssetListItem> apiAssets = response.data;

      if (apiAssets.length < needed) {
        _hasMoreData = false;
      }

      for (var asset in apiAssets) {
        bool isAlreadyInPriority = _priorityAssets.any(
          (p) => p.assetNumber == asset.assetNumber,
        );

        if (!isAlreadyInPriority) {
          _availableAssets.add(asset);
        }
      }

      _apiOffset += needed;
    } else if (remainingInPriority <= 0) {}
  }

  void searchAssets(String query) {
    _searchQuery = query;
    fetchAssets(isRefresh: true);
  }

  void loadMoreAssets() {
    if (!_hasMoreData) {
      if (_priorityIndex < _priorityAssets.length) {
        fetchAssets(isRefresh: false);
      }
      return;
    }
    fetchAssets(isRefresh: false);
  }

  void _preparePreviewData() {
    _previewSelectedAssets.clear();

    final Map<String, AssetListItem> finalMap = {};

    for (var p in _priorityAssets) {
      if (_selectedAssetNumbers.contains(p.assetNumber)) {
        finalMap[p.assetNumber] = p;
      }
    }

    for (var a in _availableAssets) {
      if (_selectedAssetNumbers.contains(a.assetNumber)) {
        finalMap[a.assetNumber] = a;
      }
    }

    _previewSelectedAssets.addAll(finalMap.values);
  }

  Future<bool> submitPeriod() async {
    if (_selectedYear == null || _selectedCycle == null) return false;

    _state = CreatePeriodState.submitting;
    notifyListeners();

    try {
      if (_isEditMode) {
        final request = UpdatePeriodRequest(
          assetNumbers: _selectedAssetNumbers.toList(),
        );
        await _cycleRepository.updatePeriodAssets(
          _selectedYear!,
          _selectedCycle!,
          request,
        );
      } else {
        final request = CreatePeriodRequest(
          year: _selectedYear!,
          cycle: _selectedCycle!,
          assetNumbers: _selectedAssetNumbers.toList(),
        );
        await _cycleRepository.createPeriod(request);
      }

      _state = CreatePeriodState.idle;
      notifyListeners();
      return true;
    } catch (e) {
      _state = CreatePeriodState.error;
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      notifyListeners();
      return false;
    }
  }

  void _resetAll() {
    _isEditMode = false;
    _currentStep = CreatePeriodStep.formInput;
    _selectedYear = null;
    _selectedCycle = null;
    _selectedAssetNumbers.clear();
    _initialAssetNumbers.clear();
    _priorityAssets.clear();
    _priorityIndex = 0;
    _availableAssets.clear();
    _apiOffset = 0;
    _searchQuery = "";
    _state = CreatePeriodState.idle;
    _previewSelectedAssets.clear();
    _errorMessage = null;
    notifyListeners();
  }
}
