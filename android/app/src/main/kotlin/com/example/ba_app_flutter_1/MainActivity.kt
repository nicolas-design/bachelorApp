package com.example.ba_app_flutter_1

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.ba_app_flutter_1/call_log"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "getOutgoingCallsCount") {
                val count = getOutgoingCallsCount()
                result.success(count)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getOutgoingCallsCount(): Int {
        val cursor = contentResolver.query(android.provider.CallLog.Calls.CONTENT_URI, null, android.provider.CallLog.Calls.TYPE + " = ?", arrayOf(android.provider.CallLog.Calls.OUTGOING_TYPE.toString()), null)
        val count = cursor?.count ?: 0
        cursor?.close()
        return count
    }
}
