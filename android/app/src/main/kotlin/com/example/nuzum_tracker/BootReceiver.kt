package com.example.nuzum_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * BootReceiver - يبدأ التتبع تلقائياً بعد إعادة تشغيل الجهاز
 * مشابه لتطبيق Life360
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || 
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            intent.action == Intent.ACTION_PACKAGE_REPLACED) {
            
            Log.d("BootReceiver", "Boot completed, starting location service...")
            
            // التحقق من وجود بيانات المستخدم (jobNumber و apiKey)
            // نستخدم SharedPreferences للتحقق
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val jobNumber = prefs.getString("flutter.jobNumber", null)
            val apiKey = prefs.getString("flutter.apiKey", null)
            
            // فقط إذا كان التطبيق مُعدّ بالفعل
            if (jobNumber != null && apiKey != null && jobNumber.isNotEmpty() && apiKey.isNotEmpty()) {
                // بدء Foreground Service
                val serviceIntent = Intent(context, LocationForegroundService::class.java)
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
                
                Log.d("BootReceiver", "Location service started after boot")
            } else {
                Log.d("BootReceiver", "App not configured yet, skipping auto-start")
            }
        }
    }
}

