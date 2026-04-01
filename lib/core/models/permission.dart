import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestStoragePermissions() async {
    final storage = await Permission.storage.request();
    final manageStorage = await Permission.manageExternalStorage.request();

    return storage.isGranted || manageStorage.isGranted;
  }
}
