package com.example.ba_app_flutter_1

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.provider.CallLog
import android.provider.ContactsContract
import android.Manifest
import androidx.core.content.ContextCompat
import android.content.pm.PackageManager


class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.ba_app_flutter_1/call_log"
    private val REQUEST_CONTACTS = 1

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
    call, result ->
    when (call.method) {
        "getOutgoingCallsCount" -> {
            val count = getOutgoingCallsCount()
            result.success(count)
        }
        "getContactCount" -> {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CONTACTS) == PackageManager.PERMISSION_GRANTED) {
                val count = getContactCount()
                result.success(count)
            } else {
                result.error("PERMISSION_DENIED", "Access to contacts was denied", null)
            }
        }
        else -> {
            result.notImplemented()
        }
    }
}

    }

    private fun getContactCount(): Int {
    val cursor = contentResolver.query(
        ContactsContract.Contacts.CONTENT_URI,
        null,   // projection (null to return all columns)
        null,   // selection clause
        null,   // selection arguments
        null    // sort order
    )
    val count = cursor?.count ?: 0
    cursor?.close()
    return count
}


    private fun getOutgoingCallsCount(): Int {
    // Calculate the timestamp for 24 hours ago
    val oneDayAgoMillis = System.currentTimeMillis() - (24*60*60 * 1000)
    

    // Define the selection criteria for the query to get only outgoing calls from the last 24 hours
    val selection = "${CallLog.Calls.TYPE} = ? AND ${CallLog.Calls.DATE} >= ?"
    val selectionArgs = arrayOf(CallLog.Calls.OUTGOING_TYPE.toString(), oneDayAgoMillis.toString())

    // Query the call log with the specified selection criteria
    val cursor = contentResolver.query(
        CallLog.Calls.CONTENT_URI,
        null,   // You can specify specific columns you need here
        selection,
        selectionArgs,
        null
    )

    // Count the number of records in the cursor
    val count = cursor?.count ?: 0
    cursor?.close()
    return count
}
}
