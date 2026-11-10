import java.util.Properties
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}
val keyFile = rootProject.file("key.properties")
val keys = Properties()
if (keyFile.exists()) keyFile.inputStream().use { keys.load(it) }
val releaseRequested = gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }
if (releaseRequested && !keyFile.exists()) {
    throw GradleException("Release signing is missing. Copy key.properties.example to key.properties and configure your existing release key.")
}
android {
    namespace = "com.example.unity_flutter"
    compileSdk = 36
    ndkVersion = "28.2.13676358"
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
    // Unity's NativeLoader receives ApplicationInfo.nativeLibraryDir.
    // Apply extraction at the host level; library-module packaging does not propagate.
    packaging { jniLibs { useLegacyPackaging = true } }
    defaultConfig {
        applicationId = "com.example.unity_flutter"
        minSdk = 29
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        ndk { abiFilters.clear(); abiFilters += "arm64-v8a" }
    }
    if (keyFile.exists()) signingConfigs {
        create("release") {
            keyAlias = keys.getProperty("keyAlias")
            keyPassword = keys.getProperty("keyPassword")
            storeFile = file(keys.getProperty("storeFile"))
            storePassword = keys.getProperty("storePassword")
        }
    }
    buildTypes {
        configureEach {
            ndk.abiFilters.clear()
            ndk.abiFilters.add("arm64-v8a")
        }
        release {
            if (keyFile.exists()) signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}
dependencies { implementation(project(":unityLibrary")) }
flutter { source = "../.." }
