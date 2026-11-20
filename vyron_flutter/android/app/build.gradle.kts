import java.io.File
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("keystore.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

val releaseStorePath: String? = System.getenv("VYRON_KEYSTORE_PATH")
    ?: keystoreProperties.getProperty("storeFile")
val releaseStorePassword: String? = System.getenv("VYRON_KEYSTORE_PASSWORD")
    ?: keystoreProperties.getProperty("storePassword")
val releaseKeyAlias: String? = System.getenv("VYRON_KEY_ALIAS")
    ?: System.getenv("VYRON_KEYSTORE_ALIAS")
    ?: keystoreProperties.getProperty("keyAlias")
val releaseKeyPassword: String? = System.getenv("VYRON_KEY_PASSWORD")
    ?: keystoreProperties.getProperty("keyPassword")

val hasReleaseSigning = !releaseStorePath.isNullOrBlank() &&
    !releaseStorePassword.isNullOrBlank() &&
    !releaseKeyAlias.isNullOrBlank() &&
    !releaseKeyPassword.isNullOrBlank()

android {
    namespace = "com.marcuszorzetti.vyron"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.marcuszorzetti.vyron"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "env"

    productFlavors {
        create("official") {
            dimension = "env"
            applicationId = "com.marcuszorzetti.vyron"
            resValue("string", "app_name", "Vyron")
        }
        create("preview") {
            dimension = "env"
            applicationId = "com.marcuszorzetti.vyron"
            applicationIdSuffix = ".preview"
            resValue("string", "app_name", "Vyron Preview")
        }
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                val candidate = File(releaseStorePath!!)
                storeFile = if (candidate.isAbsolute) candidate else rootProject.file(releaseStorePath)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        getByName("debug") {
            isMinifyEnabled = false
        }
        getByName("release") {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
            // Never fall back to debug keystore for release builds.
            isMinifyEnabled = false
            isShrinkResources = false
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
