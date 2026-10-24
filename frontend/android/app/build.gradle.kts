plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.tenseitech.khakhidiary"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required for flutter_local_notifications (Java 8+ APIs)
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.tenseitech.khakhidiary"
        // Domain 6: Explicit minSdk 23 required for flutter_secure_storage AES-256 encryption.
        // Do NOT lower this — it will disable hardware-backed keystore encryption.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        getByName("debug") {
            // Debug key is fine for development only.
        }
        // Release key: CI decodes it from the ANDROID_KEYSTORE_BASE64 secret and
        // sets these variables (see .github/workflows/build-apk.yml). Every build
        // must use the same key, or Android refuses to install it as an update.
        // Generate once with:
        //   keytool -genkey -v -keystore khakhidiary.jks -keyalg RSA -keysize 4096 -validity 10000 -alias khakhidiary
        // Never commit the keystore or its passwords to git.
        val releaseStoreFile = System.getenv("KHAKHI_STORE_FILE")
        if (!releaseStoreFile.isNullOrBlank()) {
            create("release") {
                storeFile = file(releaseStoreFile)
                storePassword = System.getenv("KHAKHI_STORE_PASSWORD")
                keyAlias = System.getenv("KHAKHI_KEY_ALIAS")
                keyPassword = System.getenv("KHAKHI_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // Domain 6: R8 shrinking + full obfuscation in release builds.
            // Makes reverse engineering extremely difficult.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // Local builds without KHAKHI_STORE_FILE fall back to the debug key.
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required for flutter_local_notifications core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
