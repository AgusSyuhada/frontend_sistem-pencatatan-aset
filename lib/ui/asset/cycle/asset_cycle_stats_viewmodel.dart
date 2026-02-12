import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../../data/repositories/asset_cycle_repository.dart';
import '../../../data/models/response/asset_cycle/period_stats_response.dart';
import '../../../data/repositories/user_repository.dart';

enum AssetCycleStatsState { idle, loading, error }

class AssetCycleStatsViewModel extends ChangeNotifier {
  final AssetCycleRepository _repository;
  final UserRepository _userRepository;

  AssetCycleStatsViewModel(this._repository, this._userRepository);

  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  AssetCycleStatsState _state = AssetCycleStatsState.idle;
  AssetCycleStatsState get state => _state;

  PeriodStatsResponse? _stats;
  PeriodStatsResponse? get stats => _stats;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUser() async {
    try {
      final response = await _userRepository.getMyProfile();
      _isAdmin = response.user.roleId == 1;
      notifyListeners();
    } catch (_) {
      _isAdmin = false;
    }
  }

  Future<void> fetchStats(int year, int cycle) async {
    _state = AssetCycleStatsState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.getPeriodStats(year, cycle);
      _stats = response;
      _state = AssetCycleStatsState.idle;
    } catch (e) {
      _state = AssetCycleStatsState.error;
      _errorMessage = e.toString().replaceAll("Exception:", "").trim();
    }
    notifyListeners();
  }

  Future<String?> downloadReport(int year, int cycle) async {
    try {
      final Uint8List bytes = await _repository.downloadReport(year, cycle);

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isWindows) {
        directory = await getDownloadsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception("Gagal mengakses folder penyimpanan perangkat.");
      }

      final String baseName = "Laporan_Siklus_${cycle}_$year";
      final String extension = ".xlsx";

      String fileName = "$baseName$extension";
      File file = File("${directory.path}/$fileName");

      int counter = 1;

      while (await file.exists()) {
        fileName = "$baseName ($counter)$extension";
        file = File("${directory.path}/$fileName");
        counter++;
      }

      await file.writeAsBytes(bytes);

      return file.path;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception:", "").trim();
      return null;
    }
  }

  Future<void> openDownloadedFile(String filePath) async {
    final result = await OpenFilex.open(filePath);
    if (result.type != ResultType.done) {
      debugPrint("Gagal membuka file: ${result.message}");
    }
  }
}
