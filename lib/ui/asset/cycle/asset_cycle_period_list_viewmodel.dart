import 'package:flutter/material.dart';
import '../../../data/local/preferences/session_manager.dart';
import '../../../data/models/response/asset_cycle/period_model.dart';
import '../../../data/repositories/asset_cycle_repository.dart';
import '../../../data/models/response/user/user_response.dart';

enum AssetCyclePeriodListState { idle, loading, error }

class AssetCyclePeriodListViewModel extends ChangeNotifier {
  final AssetCycleRepository _repository;
  final SessionManager _sessionManager;

  AssetCyclePeriodListViewModel(this._repository, this._sessionManager);

  AssetCyclePeriodListState _state = AssetCyclePeriodListState.idle;
  AssetCyclePeriodListState get state => _state;

  List<PeriodModel> _allPeriods = [];

  List<PeriodModel> _displayPeriods = [];
  List<PeriodModel> get periods => _displayPeriods;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  UserResponse? _user;
  UserResponse? get user => _user;

  Set<int> _selectedYears = {};
  Set<int> get selectedYears => _selectedYears;

  Set<int> _selectedCycles = {};
  Set<int> get selectedCycles => _selectedCycles;

  String _searchQuery = "";

  bool get isAdmin => _user?.user.roleId == 1;

  void _resetMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  void resetState() {
    _searchQuery = "";
    _selectedYears.clear();
    _selectedCycles.clear();
    _displayPeriods = [];
    _state = AssetCyclePeriodListState.idle;
    _resetMessages();
    notifyListeners();
  }

  List<int> get uniqueYears {
    return _allPeriods.map((e) => e.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
  }

  List<String> get uniqueCycleLabels {
    return _allPeriods.map((e) => "Siklus ${e.cycle}").toSet().toList()..sort();
  }

  int getCycleFromLabel(String label) {
    return int.tryParse(label.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  Future<void> loadUserFromSession() async {
    try {
      final userProfile = await _sessionManager.getUser();
      if (userProfile != null) {
        _user = userProfile;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Gagal memuat sesi pengguna: $e");
    }
  }

  Future<void> fetchPeriods({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      _state = AssetCyclePeriodListState.loading;
    }
    _resetMessages();
    notifyListeners();

    try {
      if (_user == null) {
        await loadUserFromSession();
      }

      final response = await _repository.getPeriods(query: "");

      _allPeriods = response.data;
      _applyLocalFilter();
      _state = AssetCyclePeriodListState.idle;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _state = AssetCyclePeriodListState.error;
    } finally {
      notifyListeners();
    }
  }

  void search(String query) {
    _searchQuery = query;
    _applyLocalFilter();
    notifyListeners();
  }

  void applyFilters({required Set<int> years, required Set<int> cycles}) {
    _selectedYears = years;
    _selectedCycles = cycles;
    _applyLocalFilter();
    notifyListeners();
  }

  void resetFilters() {
    _selectedYears.clear();
    _selectedCycles.clear();
    _searchQuery = "";
    _applyLocalFilter();
    notifyListeners();
  }

  void _applyLocalFilter() {
    List<PeriodModel> temp = List.from(_allPeriods);

    if (_selectedYears.isNotEmpty) {
      temp = temp.where((p) => _selectedYears.contains(p.year)).toList();
    }

    if (_selectedCycles.isNotEmpty) {
      temp = temp.where((p) => _selectedCycles.contains(p.cycle)).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      temp = temp.where((p) {
        final yearStr = p.year.toString();
        final cycleStr = p.cycle.toString();
        final monthRange = getMonthRange(p.cycle).toLowerCase();

        bool basicMatch = yearStr.contains(q) || "siklus $cycleStr".contains(q);

        bool monthMatch = monthRange.contains(q);

        return basicMatch || monthMatch;
      }).toList();
    }

    _displayPeriods = temp;
  }

  Future<bool> deletePeriod(int year, int cycle) async {
    _resetMessages();
    if (_user == null) await loadUserFromSession();

    if (!isAdmin) {
      _errorMessage = "Akses ditolak. Hanya Admin.";
      notifyListeners();
      return false;
    }

    try {
      final response = await _repository.deletePeriod(year, cycle);
      _successMessage = response.message;
      await fetchPeriods(forceRefresh: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      notifyListeners();
      return false;
    }
  }

  String getPeriodCode(int year, int cycle) {
    String yearShort = year.toString().substring(2);
    return "P$cycle$yearShort";
  }

  String getMonthRange(int cycle) {
    switch (cycle) {
      case 1:
        return "Januari - April";
      case 2:
        return "Mei - Agustus";
      case 3:
        return "September - Desember";
      default:
        return "Lainnya";
    }
  }
}
