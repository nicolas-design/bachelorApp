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
            val startTime = call.argument<Long>("startTime") ?: System.currentTimeMillis() - 24 * 60 * 60 * 1000  // Default to 24 hours ago if not specified
            val endTime = call.argument<Long>("endTime") ?: System.currentTimeMillis()
            val count = getOutgoingCallsCount(startTime, endTime)
            result.success(count)
        }
        "getIncomingCallsCount" -> {
                    val startTime = call.argument<Long>("startTime") ?: System.currentTimeMillis() - 24 * 60 * 60 * 1000  // Default to 24 hours ago if not specified
                    val endTime = call.argument<Long>("endTime") ?: System.currentTimeMillis()
                    val count = getIncomingCallsCount(startTime, endTime)
                    result.success(count)
        }
         "getOutgoingCallsAverageDuration" -> {
                    val startTime = call.argument<Long>("startTime") ?: System.currentTimeMillis() - 24 * 60 * 60 * 1000
                    val endTime = call.argument<Long>("endTime") ?: System.currentTimeMillis()
                    val avgDuration = getOutgoingCallsAverageDuration(startTime, endTime)
                    result.success(avgDuration)
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
            "getMeanSessionTimeForApps" -> {
                    val startTime = call.argument<Long>("startTime") ?: System.currentTimeMillis() - 24 * 60 * 60 * 1000
                    val endTime = call.argument<Long>("endTime") ?: System.currentTimeMillis()
                    val appNames = call.argument<List<String>>("appNames") ?: listOf("com.instagram.android", "com.snapchat.android", "com.facebook.katana")
                    val meanSessionTime = getMeanSessionTimeForApps(startTime, endTime, appNames)
                    result.success(meanSessionTime)
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


    private fun getOutgoingCallsCount(startTime: Long, endTime: Long): Double {

    // Define the selection criteria for the query to get only outgoing calls from the last 24 hours
    val selection = "${CallLog.Calls.TYPE} = ? AND ${CallLog.Calls.DATE} >= ? AND ${CallLog.Calls.DATE} <= ?"
    val selectionArgs = arrayOf(CallLog.Calls.OUTGOING_TYPE.toString(), startTime.toString(), endTime.toString())

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

    val days = (endTime - startTime) / (24 * 60 * 60 * 1000.0)  // milliseconds to days
    if (days == 0.0) return 0.0  // Avoid division by zero

    // Calculate the daily average
    return count / days

}

  private fun getIncomingCallsCount(startTime: Long, endTime: Long): Double {
        val selection = "${CallLog.Calls.TYPE} = ? AND ${CallLog.Calls.DATE} >= ? AND ${CallLog.Calls.DATE} <= ?"
        val selectionArgs = arrayOf(CallLog.Calls.INCOMING_TYPE.toString(), startTime.toString(), endTime.toString())

        val cursor = contentResolver.query(
            CallLog.Calls.CONTENT_URI,
            null,
            selection,
            selectionArgs,
            null
        )

        val count = cursor?.count ?: 0
        cursor?.close()

        val days = (endTime - startTime) / (24 * 60 * 60 * 1000.0)
        if (days == 0.0) return 0.0

        return count / days
    }

    private fun getOutgoingCallsAverageDuration(startTime: Long, endTime: Long): Double {
        val selection = "${CallLog.Calls.TYPE} = ? AND ${CallLog.Calls.DATE} >= ? AND ${CallLog.Calls.DATE} <= ?"
        val selectionArgs = arrayOf(CallLog.Calls.OUTGOING_TYPE.toString(), startTime.toString(), endTime.toString())

        val cursor = contentResolver.query(
            CallLog.Calls.CONTENT_URI,
            arrayOf(CallLog.Calls.DURATION),
            selection,
            selectionArgs,
            null
        )

        var totalDuration = 0L
        var count = 0

        if (cursor != null) {
            while (cursor.moveToNext()) {
                totalDuration += cursor.getLong(cursor.getColumnIndex(CallLog.Calls.DURATION))
                count++
            }
            cursor.close()
        }

        Log.d("OutgoingCalls", "Total duration: $totalDuration, Count: $count")

        return if (count == 0) 0.0 else totalDuration.toDouble() / count
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

private fun getMeanSessionTimeForApps(startTime: Long, endTime: Long, appNames: List<String>): Double {
    Log.d("SessionTimeApps", "StartTime: $startTime, EndTime: $endTime, Apps: $appNames")
    val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

    val events = usageStatsManager.queryEvents(startTime, endTime)
    val event = UsageEvents.Event()
    val sessionTimes = mutableListOf<Long>()

    var lastStartTime = 0L
    var currentPackageName: String? = null

    while (events.hasNextEvent()) {
        events.getNextEvent(event)

        if (appNames.any { event.packageName.contains(it, ignoreCase = true) }) {
            when (event.eventType) {
                UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                    Log.d("SessionTimeApps", "Move to foreground: ${event.packageName} at ${event.timeStamp}")
                    lastStartTime = event.timeStamp
                    currentPackageName = event.packageName
                }
                UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                    if (lastStartTime != 0L && currentPackageName == event.packageName) {
                        val sessionLength = event.timeStamp - lastStartTime
                        Log.d("SessionTimeApps", "Move to background: ${event.packageName} at ${event.timeStamp} - Session length: $sessionLength")
                        sessionTimes.add(sessionLength)
                        lastStartTime = 0L // Reset last start time
                        currentPackageName = null
                    }
                }
            }
        }
    }

    Log.d("SessionTimeApps", "SessionTimes: $sessionTimes")
    return if (sessionTimes.isNotEmpty()) {
        sessionTimes.average() 
    } else {
        0.0
    }
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
