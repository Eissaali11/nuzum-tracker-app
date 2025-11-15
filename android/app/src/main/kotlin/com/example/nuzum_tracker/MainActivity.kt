package com.example.nuzum_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.PowerManager
import android.provider.Settings
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    private val WAKELOCK_CHANNEL = "com.nuzum.tracker/wakelock"
    private val BATTERY_CHANNEL = "com.nuzum.tracker/battery"
    private val SERVICE_CHANNEL = "com.nuzum.tracker/service"
    private val LOCATION_EVENT_CHANNEL = "com.nuzum.tracker/location_events"
    private var wakeLock: PowerManager.WakeLock? = null
    private var locationEventSink: EventChannel.EventSink? = null
    private var locationReceiver: BroadcastReceiver? = null

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

        // إعداد MethodChannel لـ Foreground Service
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SERVICE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundService" -> {
                    try {
                        val serviceIntent = Intent(this, LocationForegroundService::class.java)
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                            startForegroundService(serviceIntent)
                        } else {
                            startService(serviceIntent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_ERROR", e.message, null)
                    }
                }
                "stopForegroundService" -> {
                    try {
                        val serviceIntent = Intent(this, LocationForegroundService::class.java)
                        stopService(serviceIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // إعداد EventChannel لاستقبال تحديثات الموقع من Foreground Service
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    locationEventSink = events
                    // تسجيل BroadcastReceiver
                    locationReceiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            if (intent?.action == "com.nuzum.tracker.LOCATION_UPDATE") {
                                val data = mapOf(
                                    "latitude" to (intent.getDoubleExtra("latitude", 0.0)),
                                    "longitude" to (intent.getDoubleExtra("longitude", 0.0)),
                                    "accuracy" to (intent.getDoubleExtra("accuracy", 0.0)),
                                    "speed" to (intent.getDoubleExtra("speed", 0.0)),
                                    "heading" to (intent.getDoubleExtra("heading", 0.0)),
                                    "timestamp" to (intent.getLongExtra("timestamp", 0L))
                                )
                                locationEventSink?.success(data)
                            }
                        }
                    }
                    registerReceiver(locationReceiver, IntentFilter("com.nuzum.tracker.LOCATION_UPDATE"))
                }

                override fun onCancel(arguments: Any?) {
                    locationReceiver?.let { unregisterReceiver(it) }
                    locationReceiver = null
                    locationEventSink = null
                }
            }
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        locationReceiver?.let { unregisterReceiver(it) }
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        wakeLock = null
    }
}