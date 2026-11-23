import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.tsudev.sounddb"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.tsudev.sounddb"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // API 24: nguồn thu AudioSource.UNPROCESSED (không AGC/khử ồn) cần Android 7.0.
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Khóa ký phát hành KHÔNG nằm trong repo (GITIGNORE_POLICY.md nhóm 2): đọc từ android/key.properties do CI
    // giải mã từ secret, hoặc do chủ dự án đặt ở máy. Thiếu tệp ⇒ bản release ký bằng khóa debug và chỉ dùng thử
    // cục bộ; workflow phát hành chặn trường hợp đó (SOUNDDB_REQUIRE_RELEASE_KEY=1).
    val keyFile = rootProject.file("key.properties")
    if (keyFile.exists()) {
        // Phải import: trong khối android {} chữ `java` là extension JavaPluginExtension, không phải package.
        val props = Properties().apply { keyFile.inputStream().use { load(it) } }
        signingConfigs {
            create("release") {
                storeFile = file(props.getProperty("storeFile"))
                storePassword = props.getProperty("storePassword")
                keyAlias = props.getProperty("keyAlias")
                keyPassword = props.getProperty("keyPassword")
            }
        }
    } else if (System.getenv("SOUNDDB_REQUIRE_RELEASE_KEY") == "1") {
        throw GradleException("Thiếu android/key.properties - không phát hành APK ký bằng khóa debug.")
    }

    buildTypes {
        release {
            signingConfig = if (keyFile.exists()) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
        }
        // Bản profile (đo hiệu năng, integration_test/perf_test.dart) ký khoá debug ⇒ cài đè bản release sẽ lỗi chữ
        // ký và `flutter drive` tự GỠ app, mất dữ liệu thật trên máy thử. Tách applicationId để cài song song.
        maybeCreate("profile").applicationIdSuffix = ".profile"
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
