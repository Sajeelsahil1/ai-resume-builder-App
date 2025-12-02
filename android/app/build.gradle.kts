plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase Google Services plugin MUST be applied in app module
    id("com.google.gms.google-services")
}

android {
    namespace = "com.production.airesumebuilder"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.production.airesumebuilder"
        minSdk = 23
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Temporary: using debug signing for dev mode
            signingConfig = signingConfigs.getByName("debug")
            // Optional but recommended:
            // isMinifyEnabled = true
            // isShrinkResources = true
        }
    }
}

flutter {
    source = "../.."
}

// Required for Firebase to run correctly with Kotlin DSL
dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.5.1"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
}
