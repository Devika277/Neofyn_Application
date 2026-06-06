@echo off
echo ========================================
echo FIXING ANDROID CONFIGURATION
echo ========================================

cd /d D:\neofyn-api\my_app

echo Step 1: Cleaning...
cd android 2>nul
gradlew --stop 2>nul
cd ..
rmdir /s /q android 2>nul
rmdir /s /q %USERPROFILE%\.gradle\caches 2>nul
rmdir /s /q build 2>nul
rmdir /s /q .dart_tool 2>nul
flutter clean

echo Step 2: Creating android folders...
mkdir android
mkdir android\app
mkdir android\app\src
mkdir android\app\src\main
mkdir android\app\src\main\java
mkdir android\app\src\main\kotlin
mkdir android\app\src\main\res
mkdir android\gradle
mkdir android\gradle\wrapper

echo Step 3: Creating settings.gradle...
(
echo rootProject.name = "my_app"
echo include ':app'
) > android\settings.gradle

echo Step 4: Creating build.gradle...
(
echo buildscript {
echo     ext.kotlin_version = '1.9.22'
echo     repositories {
echo         google()
echo         mavenCentral()
echo     }
echo.
echo     dependencies {
echo         classpath 'com.android.tools.build:gradle:8.1.0'
echo         classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
echo     }
echo }
echo.
echo allprojects {
echo     repositories {
echo         google()
echo         mavenCentral()
echo     }
echo }
echo.
echo tasks.register('clean', Delete^) {
echo     delete rootProject.buildDir
echo }
) > android\build.gradle

echo Step 5: Creating app/build.gradle...
(
echo def localProperties = new Properties()
echo def localPropertiesFile = rootProject.file('local.properties')
echo if (localPropertiesFile.exists()^) {
echo     localPropertiesFile.withInputStream { stream ->
echo         localProperties.load(stream)
echo     }
echo }
echo.
echo def flutterRoot = localProperties.getProperty('flutter.sdk')
echo if (flutterRoot == null^) {
echo     throw new GradleException("Flutter SDK not found.")
echo }
echo.
echo def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
echo if (flutterVersionCode == null^) {
echo     flutterVersionCode = '1'
echo }
echo.
echo def flutterVersionName = localProperties.getProperty('flutter.versionName')
echo if (flutterVersionName == null^) {
echo     flutterVersionName = '1.0'
echo }
echo.
echo apply plugin: 'com.android.application'
echo apply plugin: 'kotlin-android'
echo apply from: "$flutterRoot/packages/flutter_tools/gradle/flutter.gradle"
echo.
echo android {
echo     namespace "com.example.my_app"
echo     compileSdk 34
echo.
echo     compileOptions {
echo         sourceCompatibility JavaVersion.VERSION_17
echo         targetCompatibility JavaVersion.VERSION_17
echo     }
echo.
echo     kotlinOptions {
echo         jvmTarget = '17'
echo     }
echo.
echo     defaultConfig {
echo         applicationId "com.example.my_app"
echo         minSdk 23
echo         targetSdk 34
echo         versionCode flutterVersionCode.toInteger()
echo         versionName flutterVersionName
echo     }
echo.
echo     buildTypes {
echo         release {
echo             signingConfig signingConfigs.debug
echo         }
echo     }
echo }
echo.
echo flutter {
echo     source '../..'
echo }
echo.
echo dependencies {
echo     implementation "androidx.core:core-ktx:1.12.0"
echo }
) > android\app\build.gradle

echo Step 6: Creating gradle-wrapper.properties...
(
echo distributionBase=GRADLE_USER_HOME
echo distributionPath=wrapper/dists
echo distributionUrl=https\://services.gradle.org/distributions/gradle-8.0-all.zip
echo zipStoreBase=GRADLE_USER_HOME
echo zipStorePath=wrapper/dists
) > android\gradle\wrapper\gradle-wrapper.properties

echo Step 7: Creating local.properties...
echo sdk.dir=C:\\Users\\pc\\AppData\\Local\\Android\\Sdk > android\local.properties
echo flutter.sdk=C:\\Users\\pc\\Downloads\\flutter >> android\local.properties

echo Step 8: Creating AndroidManifest.xml...
(
echo ^<manifest xmlns:android="http://schemas.android.com/apk/res/android"^>
echo     ^<uses-permission android:name="android.permission.INTERNET"/^>
echo     ^<application
echo         android:name="${applicationName}"
echo         android:label="my_app"
echo         android:icon="@mipmap/ic_launcher"^>
echo         ^<activity
echo             android:name=".MainActivity"
echo             android:exported="true"
echo             android:launchMode="singleTop"
echo             android:theme="@style/LaunchTheme"^>
echo             ^<intent-filter^>
echo                 ^<action android:name="android.intent.action.MAIN"/^>
echo                 ^<category android:name="android.intent.category.LAUNCHER"/^>
echo             ^</intent-filter^>
echo         ^</activity^>
echo     ^</application^>
echo ^</manifest^>
) > android\app\src\main\AndroidManifest.xml

echo Step 9: Creating MainActivity.kt...
mkdir android\app\src\main\kotlin\com\example\my_app 2>nul
(
echo package com.example.my_app
echo.
echo import io.flutter.embedding.android.FlutterActivity
echo.
echo class MainActivity: FlutterActivity^(^)
) > android\app\src\main\kotlin\com\example\my_app\MainActivity.kt

echo Step 10: Creating styles.xml...
mkdir android\app\src\main\res\values 2>nul
(
echo ^<?xml version="1.0" encoding="utf-8"?^>
echo ^<resources^>
echo     ^<style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar"^>
echo         ^<item name="android:windowBackground"^>@android:color/white^</item^>
echo     ^</style^>
echo ^</resources^>
) > android\app\src\main\res\values\styles.xml

echo Step 11: Creating launch_background.xml...
mkdir android\app\src\main\res\drawable 2>nul
(
echo ^<?xml version="1.0" encoding="utf-8"?^>
echo ^<layer-list xmlns:android="http://schemas.android.com/apk/res/android"^>
echo     ^<item^>
echo         ^<color android:color="@android:color/white"/^>
echo     ^</item^>
echo ^</layer-list^>
) > android\app\src\main\res\drawable\launch_background.xml

echo Step 12: Getting dependencies...
flutter pub get

echo.
echo ========================================
echo FIX COMPLETE!
echo ========================================
echo.
echo Now run: flutter run
echo.

pause