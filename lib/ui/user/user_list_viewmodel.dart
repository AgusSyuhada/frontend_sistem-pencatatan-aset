import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import '../../../data/repositories/user_repository.dart';
import '../../data/models/response/user/user.dart';
import '../../data/models/response/user/role_response.dart';

enum UserListState { idle, loading, error, loadingMore }

class UserListViewModel extends ChangeNotifier {
  final UserRepository _userRepository;

  UserListViewModel(this._userRepository);

  UserListState _state = UserListState.idle;
  UserListState get state => _state;

  final List<User> _allUsers = [];
  List<User> get users => _allUsers;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _searchQuery = "";
  List<Role> _availableRoles = [];
  List<Role> get availableRoles => _availableRoles;

  Set<int> _selectedRoles = {1, 2};
  Set<int> get selectedRoles => _selectedRoles;

  final int _currentLimit = 20;
  int _currentOffset = 0;
  bool _hasMoreData = true;
  bool get hasMoreData => _hasMoreData;
  bool get isLoadingMore => _state == UserListState.loadingMore;

  String _sortColumn = "id";
  bool _isAscending = true;
  String get sortColumn => _sortColumn;
  bool get isAscending => _isAscending;

  Future<void> initialize() async {
    log('Initializing UserListViewModel...', name: 'UserListViewModel');
    await _loadLocalRoles();
    await fetchUsers(isRefresh: true);
  }

  Future<void> _loadLocalRoles() async {
    try {
      final localRoles = await _userRepository.getLocalRoles();
      if (localRoles.isNotEmpty) {
        _availableRoles = localRoles;
        notifyListeners();
      }
    } catch (e) {
      log("Failed to load local roles: $e", name: 'UserListViewModel');
    }
  }

  Future<void> fetchUsers({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentOffset = 0;
      _hasMoreData = true;
      _allUsers.clear();
      _state = UserListState.loading;
      _errorMessage = null;
    } else {
      if (!_hasMoreData || _state == UserListState.loadingMore) return;
      _state = UserListState.loadingMore;
    }
    notifyListeners();

    try {
      if (_availableRoles.isEmpty) {
        try {
          final roleResp = await _userRepository.getRoles();
          _availableRoles = roleResp.data;
        } catch (e) {
          log("Failed to fetch roles: $e", name: 'UserListViewModel');
        }
      }

      final response = await _userRepository.getAllUsers(
        includeInactive: false,
        query: _searchQuery,
        limit: _currentLimit,
        offset: _currentOffset,
        roleIds: _selectedRoles.toList(),
      );

      List<User> fetchedUsers = response.data;

      fetchedUsers = _enrichUsersWithRoleNames(fetchedUsers);

      if (fetchedUsers.length < _currentLimit) {
        _hasMoreData = false;
      }

      _allUsers.addAll(fetchedUsers);
      _currentOffset += _currentLimit;

      if (_state != UserListState.error) {
        _state = UserListState.idle;
      }
    } catch (e) {
      log('Fetch failed: $e', name: 'UserListViewModel');
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _state = UserListState.error;
    } finally {
      notifyListeners();
    }
  }

  List<User> _enrichUsersWithRoleNames(List<User> inputUsers) {
    if (_availableRoles.isEmpty) return inputUsers;
    final roleMap = {for (var r in _availableRoles) r.roleId: r.roleName};

    return inputUsers.map((user) {
      if (user.roleName == null || user.roleName!.isEmpty) {
        return user.copyWith(roleName: roleMap[user.roleId]);
      }
      return user;
    }).toList();
  }

  Future<void> refreshManual() async {
    await fetchUsers(isRefresh: true);
  }

  void loadMore() {
    fetchUsers(isRefresh: false);
  }

  void search(String query) {
    _searchQuery = query;
    fetchUsers(isRefresh: true);
  }

  void applyFilters({required Set<int> roles}) {
    _selectedRoles = Set.from(roles);
    fetchUsers(isRefresh: true);
  }

  void resetFilters() {
    _selectedRoles = {1, 2};
    fetchUsers(isRefresh: true);
  }

  void resetState() {
    _allUsers.clear();
    _currentOffset = 0;
    _searchQuery = "";
    _selectedRoles = {1, 2};
    _state = UserListState.idle;
    _hasMoreData = true;
    _errorMessage = null;
    _sortColumn = "id";
    _isAscending = true;
  }

  void sort(String column) {
    if (_sortColumn == column) {
      _isAscending = !_isAscending;
    } else {
      _sortColumn = column;
      _isAscending = true;
    }

    _allUsers.sort((a, b) {
      int cmp = 0;
      if (_sortColumn == 'id') {
        cmp = a.userId.compareTo(b.userId);
      } else if (_sortColumn == 'name') {
        cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      return _isAscending ? cmp : -cmp;
    });
    notifyListeners();
  }

  Future<String?> deactivateUser(int userId) async {
    try {
      final response = await _userRepository.deactivateUser(userId);
      _allUsers.removeWhere((u) => u.userId == userId);
      notifyListeners();
      return response.message;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
}