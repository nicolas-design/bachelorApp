import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';


class PermissionService {
  static Future<bool> requestCallLogPermission() async {
    var status = await Permission.phone.status; // or Permission.phone for just call-related permissions
    if (!status.isGranted) {
      status = await Permission.phone.request();
    }
    return status.isGranted;
  }
}

class CallLogUtil {
  static final platform = MethodChannel('com.example.ba_app_flutter_1/call_log');

  static Future<int> getOutgoingCallsCount() async {
    if (!await PermissionService.requestCallLogPermission()) {
      print("Call Log permission not granted");
      return 0;
    }
    try {
      final int result = await platform.invokeMethod('getOutgoingCallsCount');
      print('Outgoing calls count: $result');
      return result;
    } catch (e) {
      print('Failed to get outgoing calls count: $e');
      return 0;
    }
  }
}
