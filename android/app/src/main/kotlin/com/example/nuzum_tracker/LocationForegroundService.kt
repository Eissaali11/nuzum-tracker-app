package com.example.nuzum_tracker

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.location.Location
import android.os.Build
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*
import java.io.OutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.Executors

/**
 * خدمة الخلفية لتتبع الموقع - تعمل حتى عند إغلاق التطبيق
 * مشابهة لتطبيق Life360
 */
class LocationForegroundService : Service() {
    private var fusedLocationClient: FusedLocationProviderClient? = null
    private var locationCallback: LocationCallback? = null
    private val CHANNEL_ID = "nuzum_tracker_foreground"
    private val NOTIFICATION_ID = 1
    private val executor = Executors.newSingleThreadExecutor()
    private val API_URL = "https://eissahr.replit.app/api/external/employee-location"
    private val API_BACKUP_URL = "https://d72f2aef-918c-4148-9723-15870f8c7cf6-00-2c1ygyxvqoldk.riker.replit.dev/api/external/employee-location"
    private val API_KEY = "test_location_key_2025"
    
    // فلترة المسافة - تحديث فقط عند التحرك 10 أمتار أو أكثر
    private var lastSentLocation: Location? = null
    private val MIN_DISTANCE_METERS = 10f // 10 أمتار

    override fun onCreate() {
        super.onCreate()
        android.util.Log.d("LocationService", "Service created")

        // تهيئة FusedLocationProviderClient
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        
        // إنشاء LocationCallback مع فلترة المسافة
        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                locationResult.lastLocation?.let { location ->
                    // فلترة المسافة - تحديث فقط عند التحرك 10 أمتار أو أكثر
                    val shouldUpdate = shouldUpdateLocation(location)
                    
                    if (shouldUpdate) {
                        lastSentLocation = location
                        updateNotificationWithLocation(location)
                        // إرسال الموقع مباشرة للسيرفر (يعمل حتى عند إغلاق التطبيق)
                        sendLocationToServer(location)
                        // أيضاً إرسال عبر Broadcast (للتحديث في Flutter إذا كان مفتوحاً)
                        sendLocationBroadcast(location)
                    } else {
                        // تحديث الإشعار فقط بدون إرسال للسيرفر (توفير البطارية والبيانات)
                        updateNotificationWithLocation(location)
                    }
                }
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        android.util.Log.d("LocationService", "Service started")
        
        // إنشاء الإشعار وبدء Foreground Service
        val notification = createNotification(
            "تتبع الموقع نشط",
            "جاري تتبع موقعك..."
        )
        startForeground(NOTIFICATION_ID, notification)

        // بدء تتبع الموقع
        startLocationTracking()

        // إرجاع START_STICKY لضمان إعادة تشغيل الخدمة عند إيقافها
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        android.util.Log.d("LocationService", "Service destroyed")
        stopLocationTracking()
    }

    /**
     * التحقق من ضرورة تحديث الموقع (فلترة حسب المسافة)
     */
    private fun shouldUpdateLocation(newLocation: Location): Boolean {
        val lastLocation = lastSentLocation
        
        // إذا لم يكن هناك موقع سابق، أرسل فوراً
        if (lastLocation == null) {
            return true
        }
        
        // حساب المسافة بين الموقع السابق والجديد
        val distance = lastLocation.distanceTo(newLocation)
        
        // تحديث فقط إذا تحرك 10 أمتار أو أكثر
        return distance >= MIN_DISTANCE_METERS
    }
    
    /**
     * بدء تتبع الموقع
     */
    private fun startLocationTracking() {
        try {
            // استخدام LocationRequest.Builder مع أحدث API
            val locationRequest = LocationRequest.Builder(
                Priority.PRIORITY_HIGH_ACCURACY,
                10000L // 10 ثواني - الفترة الأساسية للتحديث
            ).apply {
                setMinUpdateIntervalMillis(5000L) // 5 ثواني كحد أدنى
                setMaxUpdateDelayMillis(15000L) // 15 ثانية كحد أقصى
                // فلترة المسافة تتم يدوياً في shouldUpdateLocation()
                // هذا يوفر مرونة أكبر وضمان التوافق مع جميع الإصدارات
            }.build()

            val locationSettingsRequest = LocationSettingsRequest.Builder()
                .addLocationRequest(locationRequest)
                .build()

            val settingsClient = LocationServices.getSettingsClient(this)
            settingsClient.checkLocationSettings(locationSettingsRequest)
                .addOnSuccessListener {
                    // الأذونات متوفرة، بدء التتبع
                    fusedLocationClient?.requestLocationUpdates(
                        locationRequest,
                        locationCallback!!,
                        Looper.getMainLooper()
                    )
                    android.util.Log.d("LocationService", "Location tracking started")
                }
                .addOnFailureListener { exception ->
                    android.util.Log.e("LocationService", "Location settings check failed: ${exception.message}", exception)
                }
        } catch (e: SecurityException) {
            android.util.Log.e("LocationService", "Location permission denied", e)
        } catch (e: Exception) {
            android.util.Log.e("LocationService", "Error starting location tracking: ${e.message}", e)
        }
    }

    /**
     * إيقاف تتبع الموقع
     */
    private fun stopLocationTracking() {
        locationCallback?.let {
            fusedLocationClient?.removeLocationUpdates(it)
            android.util.Log.d("LocationService", "Location tracking stopped")
        }
        // إعادة تعيين آخر موقع مرسل
        lastSentLocation = null
    }

    /**
     * إرسال الموقع مباشرة للسيرفر (يعمل حتى عند إغلاق التطبيق)
     */
    private fun sendLocationToServer(location: Location) {
        executor.execute {
            try {
                // الحصول على jobNumber و apiKey من SharedPreferences
                val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val jobNumber = prefs.getString("flutter.jobNumber", null)
                val apiKey = prefs.getString("flutter.apiKey", null) ?: API_KEY

                if (jobNumber == null || jobNumber.isEmpty()) {
                    android.util.Log.w("LocationService", "No jobNumber found, skipping server update")
                    return@execute
                }

                // تنسيق التاريخ
                val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
                sdf.timeZone = TimeZone.getTimeZone("UTC")
                val recordedAt = sdf.format(Date())

                // إنشاء JSON body
                val jsonBody = """
                {
                    "api_key": "$apiKey",
                    "job_number": "$jobNumber",
                    "latitude": ${location.latitude},
                    "longitude": ${location.longitude},
                    "accuracy": ${location.accuracy},
                    "recorded_at": "$recordedAt"
                }
                """.trimIndent()

                // محاولة الإرسال للسيرفر الأساسي
                var success = sendHttpRequest(API_URL, jsonBody)
                
                // إذا فشل، جرب السيرفر البديل
                if (!success) {
                    android.util.Log.w("LocationService", "Primary server failed, trying backup...")
                    success = sendHttpRequest(API_BACKUP_URL, jsonBody)
                }

                if (success) {
                    android.util.Log.d("LocationService", "✅ Location sent to server successfully")
                } else {
                    android.util.Log.w("LocationService", "⚠️ Failed to send location to server")
                    // يمكن حفظ محلياً هنا للتحقق لاحقاً
                }
            } catch (e: Exception) {
                android.util.Log.e("LocationService", "❌ Error sending location to server: ${e.message}", e)
            }
        }
    }

    /**
     * إرسال HTTP request
     */
    private fun sendHttpRequest(urlString: String, jsonBody: String): Boolean {
        var connection: HttpURLConnection? = null
        try {
            val url = URL(urlString)
            connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "POST"
            connection.setRequestProperty("Content-Type", "application/json; charset=UTF-8")
            connection.setRequestProperty("Accept", "application/json")
            connection.connectTimeout = 30000 // 30 ثانية
            connection.readTimeout = 30000
            connection.doOutput = true

            // إرسال البيانات
            val outputStream: OutputStream = connection.outputStream
            outputStream.write(jsonBody.toByteArray(Charsets.UTF_8))
            outputStream.flush()
            outputStream.close()

            // قراءة الاستجابة
            val responseCode = connection.responseCode
            if (responseCode == HttpURLConnection.HTTP_OK || responseCode == HttpURLConnection.HTTP_CREATED) {
                return true
            } else {
                android.util.Log.w("LocationService", "Server returned code: $responseCode")
                return false
            }
        } catch (e: Exception) {
            android.util.Log.e("LocationService", "HTTP request error: ${e.message}", e)
            return false
        } finally {
            connection?.disconnect()
        }
    }

    /**
     * إرسال الموقع عبر Broadcast (سيتم استقباله في Flutter)
     */
    private fun sendLocationBroadcast(location: Location) {
        try {
            val intent = Intent("com.nuzum.tracker.LOCATION_UPDATE").apply {
                putExtra("latitude", location.latitude)
                putExtra("longitude", location.longitude)
                putExtra("accuracy", location.accuracy)
                putExtra("speed", location.speed * 3.6) // km/h
                putExtra("heading", location.bearing)
                putExtra("timestamp", location.time)
            }
            sendBroadcast(intent)
            android.util.Log.d("LocationService", "Location broadcast sent")
        } catch (e: Exception) {
            android.util.Log.e("LocationService", "Error sending location broadcast: ${e.message}", e)
        }
    }

    /**
     * تحديث الإشعار بالموقع
     */
    private fun updateNotificationWithLocation(location: Location) {
        val locationText = String.format(
            "%.6f, %.6f",
            location.latitude,
            location.longitude
        )
        val speedText = if (location.speed > 0) {
            String.format("%.1f km/h", location.speed * 3.6)
        } else {
            "متوقف"
        }
        updateNotification(locationText, speedText)
    }

    /**
     * إنشاء إشعار دائم
     */
    private fun createNotification(title: String, content: String): Notification {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(R.drawable.ic_bg_service_small)
            .setContentIntent(pendingIntent)
            .setOngoing(true) // إشعار دائم لا يمكن إزالته
            .setPriority(NotificationCompat.PRIORITY_LOW) // أولوية منخفضة لتقليل الإزعاج
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()
    }

    /**
     * تحديث الإشعار
     */
    private fun updateNotification(location: String?, speed: String?) {
        val title = "تتبع الموقع نشط"
        val content = buildString {
            if (location != null) {
                append("الموقع: $location")
            }
            if (speed != null) {
                if (location != null) append(" | ")
                append("السرعة: $speed")
            }
            if (location == null && speed == null) {
                append("جاري تتبع موقعك...")
            }
        }
        
        val notification = createNotification(title, content)
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
    }
}

