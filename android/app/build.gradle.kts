plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.change.app.change"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.change.app.change"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Release signing: create key.properties file with:
            //   storeFile=<path-to-keystore>
            //   storePassword=<password>
            //   keyAlias=<alias>
            //   keyPassword=<password>
            // Then uncomment the lines below and comment out the debug fallback.

            // val keystoreProperties = java.util.Properties()
            // keystoreProperties.load(java.io.FileInputStream(rootProject.file("key.properties")))
            // storeFile = file(keystoreProperties["storeFile"] as String)
            // storePassword = keystoreProperties["storePassword"] as String
            // keyAlias = keystoreProperties["keyAlias"] as String
            // keyPassword = keystoreProperties["keyPassword"] as String
        }
    }

    buildTypes {
        release {
            // For release build: switch to signingConfigs.getByName("release")
            // after configuring key.properties above
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
