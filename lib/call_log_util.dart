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

  static Future<bool> requestContactPermission() async {
    var status = await Permission.contacts.status;
    if (!status.isGranted) {
      status = await Permission.contacts.request();
    }
    return status.isGranted;
  }
}

class UsageStats2 {
  static final platform = MethodChannel('com.example.ba_app_flutter_1/call_log');

  Future<void> getTotalScreenTime() async {
    try {
      final int totalScreenTime = await platform.invokeMethod('getTotalScreenTime');
      print("Total screen time in ms: $totalScreenTime");
    } on PlatformException catch (e) {
      print("Failed to get total screen time: '${e.message}'");
    }
  }

  Future<double> getMeanSessionTime() async {
    try {
      final double meanSessionTime = await platform.invokeMethod('getMeanSessionTime');
      print("Mean session time in ms: $meanSessionTime");
      return meanSessionTime; // Return the mean session time
    } on PlatformException catch (e) {
      print("Failed to get mean session time: '${e.message}'");
      return 0.0; // Return zero or handle accordingly
    }
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

  static Future<int> getContactCount() async {
    if (!await PermissionService.requestContactPermission()) {
      print("Contacts permission not granted");
      return 0;
    }
    try {
      final int result = await platform.invokeMethod('getContactCount');
      print('Contact count: $result');
      return result;
    } catch (e) {
      print('Failed to get contact count: $e');
      return 0;
    }
  }
}
