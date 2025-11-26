

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.0.0")) // Using 33.0.0 as a recent common version, adjust if needed

    // TODO: Add the dependencies for Firebase products you want to use
    // When using the BoM, don't specify versions in Firebase dependencies
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth") // Assuming you need firebase_auth

    // Add the dependencies for any other desired Firebase products
    // https://firebase.google.com/docs/android/setup#available-libraries
}

android {
    namespace = "com.example.account_flow" // Make sure this is your actual package name
    compileSdk = 34 // It's good practice to use a recent API level, e.g., 34 for Android 14

    // ndkVersion can often be omitted unless you have specific NDK requirements.
    // If you explicitly need it for other plugins or native code:
    // ndkVersion = "27.0.12077973" // Keep if necessary, otherwise consider removing

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8 // Common for broader compatibility
        targetCompatibility = JavaVersion.VERSION_1_8 // Common for broader compatibility
        // If you are using Java 11 features AND all your libraries support it,
        // then VERSION_11 is fine. Otherwise, VERSION_1_8 is safer.
    }

    kotlinOptions {
        jvmTarget = "1.8" // Or your JVM target
        freeCompilerArgs += "-Xlint:deprecation" // Add this line
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.account_flow" // Make sure this is your actual package name
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.

        // --- THIS IS THE KEY CHANGE ---
        minSdk = flutter.minSdkVersion // Set directly to 23 for firebase_auth compatibility

        targetSdk = 34 // Match compileSdk for consistency
        versionCode = 1    // Or use flutter.versionCode
        versionName = "1.0" // Or use flutter.versionName

        // If you use Flutter variables for versionCode and versionName, you can keep them:
        // versionCode = flutter.versionCode
        // versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            // It's good practice to enable shrinking and obfuscation for release builds
            // isMinifyEnabled = true
            // isShrinkResources = true
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

}

flutter {
    source = "../.."
}
