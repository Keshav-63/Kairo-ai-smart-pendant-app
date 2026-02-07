plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}
subprojects {
    afterEvaluate {
        if (project.name == "flutter_web_auth_2") {
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                kotlinOptions {
                    jvmTarget = "17"
                }
            }
        }
    }
}


android {
    namespace = "com.example.smart_pendant_app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.smart_pendant_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Rename APK outputs to include version name and code (e.g. app-release-v1.0.0+2.apk)
    applicationVariants.all {
        val variant = this
        variant.outputs.all {
            try {
                val vName = variant.versionName ?: defaultConfig.versionName
                val vCode = variant.versionCode ?: defaultConfig.versionCode
                val newName = "app-${variant.name}-v${vName}+${vCode}.apk"
                (this as? com.android.build.gradle.internal.api.BaseVariantOutputImpl)?.outputFileName = newName
            } catch (e: Exception) {
                // ignore on older AGP where internal API isn't present
            }
        }
    }
}

flutter {
    source = "../.."
}
