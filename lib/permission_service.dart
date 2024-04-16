import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestPhonePermission() async {
    var status = await Permission.phone.status;
    if (!status.isGranted) {
      status = await Permission.phone.request();
    }
    return status.isGranted;
  }
}
