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
import android.app.usage.UsageStatsManager
import android.content.Intent
import android.provider.Settings
import android.os.Bundle
import android.app.AppOpsManager
import android.content.Context
import android.app.usage.UsageEvents
import android.util.Log




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
        "getTotalScreenTime" -> {
                if (checkUsageStatsPermission()) {
                    val totalScreenTime = getTotalScreenTime()
                    result.success(totalScreenTime)
                } else {
                    result.error("PERMISSION_DENIED", "Usage stats permission not granted", null)
                }
            }
            "getMeanSessionTime" -> {
                if (checkUsageStatsPermission()) {
                    val startTime = call.argument<Long>("startTime") ?: return@setMethodCallHandler
                    val endTime = call.argument<Long>("endTime") ?: return@setMethodCallHandler
                    val meanSessionTime = getMeanSessionTime(startTime, endTime)
                    result.success(meanSessionTime)
                } else {
                    result.error("PERMISSION_DENIED", "Usage stats permission not granted", null)
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
private fun checkUsageStatsPermission(): Boolean {
    val appOps = getSystemService(APP_OPS_SERVICE) as AppOpsManager
    val mode = appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS,
                                     android.os.Process.myUid(), packageName)
    return mode == AppOpsManager.MODE_ALLOWED
}
private fun requestUsageStatsPermission() {
    if (!checkUsageStatsPermission()) {
        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
    }
}

override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    requestUsageStatsPermission()
}

private fun getTotalScreenTime(): Long {
    val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    val endTime = System.currentTimeMillis()
    val startTime = endTime - 24 * 60 * 60 * 1000 // 24 hours ago

    val queryUsageStats = usageStatsManager.queryAndAggregateUsageStats(startTime, endTime)
    var totalScreenTime = 0L

    queryUsageStats.forEach { _, usageStats ->
        totalScreenTime += usageStats.totalTimeInForeground
    }

    return totalScreenTime
}

private fun getMeanSessionTime(startTime: Long, endTime: Long): Double {
    Log.d("SessionTime", "StartTime: $startTime, EndTime: $endTime")
    val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    

    // Get the usage events within the last 24 hours
    val events = usageStatsManager.queryEvents(startTime, endTime)
    val event = UsageEvents.Event()
    val sessionTimes = mutableListOf<Long>()

    var lastStartTime = 0L

    while (events.hasNextEvent()) {
        events.getNextEvent(event)
        when (event.eventType) {
            UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                lastStartTime = event.timeStamp
            }
            UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                if (lastStartTime != 0L) {
                    val sessionLength = event.timeStamp - lastStartTime
                    sessionTimes.add(sessionLength)
                    lastStartTime = 0L // Reset last start time
                }
            }
        }
    }

    // Calculate the mean session time
    return if (sessionTimes.isNotEmpty()) {
        sessionTimes.average()
    } else {
        0.0 // No sessions were found
    }
}


}
