plugins {
    id("com.android.application") version "8.5.1" // Flutter uses AGP from classpath
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.gmail_enhancer_final"
    compileSdk = 36 // This is fine

    defaultConfig {
        applicationId = "com.example.gmail_enhancer_final"
        // This 'flutter.minSdkVersion' is set in the *other* build.gradle file.
        // We will check that in Step 2.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    // This block you added is correct.
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// ✅ BINGO: THIS IS THE MISSING BLOCK
// You must add this dependencies block to include the desugaring library.
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

