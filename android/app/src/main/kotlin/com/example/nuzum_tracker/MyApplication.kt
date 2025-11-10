package com.example.nuzum_tracker

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    "nuzum_tracker_foreground", 
                    "Nuzum Tracker Service",  
                    NotificationManager.IMPORTANCE_DEFAULT
                )
                
                // إضافة وصف للقناة (مطلوب لـ Android 15+)
                channel.description = "This channel is used for location tracking service."
                
                // تعيين الأهمية بشكل صريح
                channel.importance = NotificationManager.IMPORTANCE_DEFAULT
                
                val manager = getSystemService(NotificationManager::class.java)
                manager?.createNotificationChannel(channel)
                
                android.util.Log.d("MyApplication", "Notification channel created successfully")
            }
        } catch (e: Exception) {
            android.util.Log.e("MyApplication", "Error creating notification channel: ${e.message}", e)
        }
    }
}