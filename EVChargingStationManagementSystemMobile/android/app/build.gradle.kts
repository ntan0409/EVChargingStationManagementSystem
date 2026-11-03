plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val signingEnvironment = mapOf(
    "storeFile" to System.getenv("EV_RELEASE_STORE_FILE"),
    "storePassword" to System.getenv("EV_RELEASE_STORE_PASSWORD"),
    "keyAlias" to System.getenv("EV_RELEASE_KEY_ALIAS"),
    "keyPassword" to System.getenv("EV_RELEASE_KEY_PASSWORD")
)
val hasReleaseSigning = signingEnvironment.values.all { !it.isNullOrBlank() }
val requestsRelease = gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }
if (requestsRelease && !hasReleaseSigning) {
    throw GradleException("Release signing is not configured. Supply EV_RELEASE_* secrets; debug signing is forbidden for release.")
}

android {
    namespace = "com.fptu.prm.ev_charging_station"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.fptu.prm.ev_charging_station"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(signingEnvironment.getValue("storeFile")!!)
                storePassword = signingEnvironment.getValue("storePassword")
                keyAlias = signingEnvironment.getValue("keyAlias")
                keyPassword = signingEnvironment.getValue("keyPassword")
            }
        }
    }
    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) signingConfigs.getByName("release") else null
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
