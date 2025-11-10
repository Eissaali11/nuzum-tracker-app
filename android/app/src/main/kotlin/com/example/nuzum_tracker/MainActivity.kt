package com.example.nuzum_tracker

import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.provider.Settings
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    private val WAKELOCK_CHANNEL = "com.nuzum.tracker/wakelock"
    private val BATTERY_CHANNEL = "com.nuzum.tracker/battery"
    private var wakeLock: PowerManager.WakeLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        GeneratedPluginRegistrant.registerWith(flutterEngine)

        // إعداد MethodChannel لـ Wake Lock
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WAKELOCK_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "acquireWakeLock" -> {
                    try {
                        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                        wakeLock = powerManager.newWakeLock(
                            PowerManager.PARTIAL_WAKE_LOCK,
                            "NuzumTracker::LocationWakeLock"
                        )
                        wakeLock?.acquire(10 * 60 * 60 * 1000L) // 10 ساعات
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WAKELOCK_ERROR", e.message, null)
                    }
                }
                "releaseWakeLock" -> {
                    try {
                        wakeLock?.let {
                            if (it.isHeld) {
                                it.release()
                            }
                        }
                        wakeLock = null
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WAKELOCK_ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // إعداد MethodChannel لـ Battery Optimization
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestIgnoreBatteryOptimizations" -> {
                    try {
                        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                            data = Uri.parse("package:$packageName")
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("BATTERY_ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        wakeLock = null
    }
}