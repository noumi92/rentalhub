import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}
val releaseStoreFilePath: String? =
    (keystoreProperties.getProperty("storeFile") ?: System.getenv("KEYSTORE_PATH"))
        ?.takeIf { it.isNotBlank() }
val hasReleaseSigning = releaseStoreFilePath != null &&
    file(releaseStoreFilePath).exists()

android {
    namespace = "pk.rentalhub.rentalhub"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Application ID
        applicationId = "pk.rentalhub.rentalhub"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        getByName("debug") {
            storeFile = file("rentalhub-debug.keystore")
            storePassword = "android"
            keyAlias = "rentalhubdebug"
            keyPassword = "android"
        }
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseStoreFilePath!!)
                storePassword = keystoreProperties.getProperty("storePassword")
                    ?: System.getenv("KEYSTORE_PASSWORD")
                    ?: ""
                keyAlias = keystoreProperties.getProperty("keyAlias")
                    ?: System.getenv("KEY_ALIAS")
                    ?: ""
                keyPassword = keystoreProperties.getProperty("keyPassword")
                    ?: System.getenv("KEY_PASSWORD")
                    ?: ""
            }
        }
    }

    buildTypes {
        release {
            // Play Store release builds use android/key.properties (or CI env
            // vars). Falls back to debug only for local/internal APK builds
            // when no release keystore is configured.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Release builds run R8 minification & resource shrinking. Keep the
            // ML Kit text-recognition classes used by CNIC OCR (see
            // proguard-rules.pro) — without these rules the release build
            // fails on the unbundled Chinese/Japanese/Korean script models.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
