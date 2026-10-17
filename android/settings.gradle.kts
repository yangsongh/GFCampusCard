pluginManagement {
    repositories {
        // 国内镜像（可选）
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        google()
        mavenCentral()
        gradlePluginPortal()
    }
    val flutterSdkPath = file("local.properties").inputStream().use { 
        java.util.Properties().apply { load(it) }["flutter.sdk"] as String
    }
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
}

dependencyResolutionManagement {
    repositories {
        // 国内镜像（可选）
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        google()
        mavenCentral()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.4.1" apply false
}

include(":app")