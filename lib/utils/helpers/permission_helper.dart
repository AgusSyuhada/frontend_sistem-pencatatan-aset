import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  Future<Map<Permission, PermissionStatus>>
  requestNecessaryPermissions() async {
    if (Platform.isWindows) {
      return {
        Permission.location: PermissionStatus.granted,
        Permission.camera: PermissionStatus.granted,
        Permission.storage: PermissionStatus.granted,
        Permission.photos: PermissionStatus.granted,
      };
    }

    List<Permission> permissions = [Permission.location, Permission.camera];

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        permissions.add(Permission.photos);
      } else {
        permissions.add(Permission.storage);
      }
    } else if (Platform.isIOS) {
      permissions.add(Permission.photos);
    }

    final statuses = await permissions.request();
    return statuses;
  }

  Future<bool> requestStoragePermission() async {
    if (Platform.isWindows) return true;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        final status = await Permission.photos.request();
        return status.isGranted;
      } else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }

    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted || status.isLimited;
    }

    return false;
  }

  Future<bool> requestCameraPermission() async {
    if (Platform.isWindows) return true;
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  bool isGranted(PermissionStatus status) {
    return status.isGranted || status.isLimited;
  }

  bool isPermanentlyDenied(PermissionStatus status) {
    return status.isPermanentlyDenied;
  }
}
