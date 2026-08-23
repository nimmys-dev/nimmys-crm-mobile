import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")

    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration

    // The Flutter Gradle Plugin must be applied after the Android and Kotlin
    // Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

/*
 * Load release keystore properties.
 *
 * key.properties should be located at:
 * android/key.properties
 */
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.nimmyscrm.app"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications 22.
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    /*
     * Release signing configuration.
     *
     * This uses:
     * nimmys-crm-upload-keystore.jks
     *
     * Expected Play Console SHA-1:
     * 26:EC:FB:31:83:60:7D:EC:92:18:84:A1:C8:33:68:C2:64:71:BC:66
     */
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    defaultConfig {
        applicationId = "com.nimmyscrm.app"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            /*
             * IMPORTANT:
             *
             * Do NOT use the debug signing key here.
             *
             * The release AAB must be signed using the upload key
             * registered in Google Play Console.
             */
            signingConfig = signingConfigs.getByName("release")
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

dependencies {
    // Ships the backported java.time implementation the desugaring above
    // rewrites calls to.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
