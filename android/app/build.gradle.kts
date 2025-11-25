plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.nuzum_tracker"
    // Android SDK 36 support (required by plugins)
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // تفعيل core library desugaring (مطلوب لـ flutter_local_notifications)
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.nuzum_tracker"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion // Android 5.0 (Lollipop) - minimum supported
        targetSdk = 36 // Android SDK 36 support
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // قمع تحذيرات Java unchecked/unsafe operations
    lint {
        disable += "UnsafeNativeCodeLocation"
        checkReleaseBuilds = false
        abortOnError = false
    }
}

// قمع تحذيرات Java compiler (unchecked/unsafe operations)
tasks.withType<org.gradle.api.tasks.compile.JavaCompile>().configureEach {
    options.compilerArgs.add("-Xlint:-unchecked")
    options.compilerArgs.add("-Xlint:-deprecation")
}

dependencies {
   implementation("androidx.multidex:multidex:2.0.1")
   // Google Play Services Location for FusedLocationProviderClient
   // أحدث إصدار يدعم جميع الميزات الحديثة
   implementation("com.google.android.gms:play-services-location:21.3.0")
   // Core library desugaring (مطلوب لـ flutter_local_notifications)
   coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
