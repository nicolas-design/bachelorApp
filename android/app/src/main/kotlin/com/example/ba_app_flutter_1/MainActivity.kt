package com.example.ba_app_flutter_1

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat.startActivityForResult
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log
import android.app.usage.UsageStatsManager


class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.usagestats"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "getUsageStats" -> {
                    val usageStats = getUsageStats()
                    if (usageStats != null) {
                        result.success(usageStats)
                    } else {
                        result.error("UNAVAILABLE", "Usage stats not available.", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getUsageStats(): String? {
        Log.d("MainActivity", "getUsageStats called")
        
        if (!hasUsageStatsPermission()) {
            // If permission not granted, guide user to settings
            startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
            return null
        }
        // Implement your logic to fetch usage stats here
        // This is a placeholder for your usage stats logic
        return "Usage Stats Here"
    }

    private fun hasUsageStatsPermission(): Boolean {
    val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
    val mode = appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, 
                                     android.os.Process.myUid(), packageName)
    Log.d("UsageStatsPermission", "AppOps Check: $mode")
    
    if (mode == AppOpsManager.MODE_ALLOWED) {
        return true
    }

    val now = System.currentTimeMillis()
    val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    val queryUsageStats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, now - 1000*3600, now)
    val hasStats = queryUsageStats != null && queryUsageStats.isNotEmpty()
    
    Log.d("UsageStatsPermission", "UsageStats Check: $hasStats")

    return hasStats
}

}
