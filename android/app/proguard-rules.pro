# ProGuard / R8 規則 — 全面保留所有 plugin native 端類別，避免 release 版被混掉而 crash

# ===== Flutter Engine =====
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# 本 App 自己的 Activity / Receiver（widget reflection 會用到）
-keep class com.example.expense_tracker.MainActivity { *; }
-keep class com.example.expense_tracker.ExpenseWidgetProvider { *; }

# ===== 各 plugin =====
# sqflite
-keep class com.tekartik.sqflite.** { *; }

# flutter_local_notifications — 需要 gson 反序列化排程資料
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepattributes Signature
-keepattributes *Annotation*

# home_widget
-keep class es.antonborri.home_widget.** { *; }

# image_picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# mobile_scanner (Google ML Kit Barcode)
-keep class dev.steenbakker.mobile_scanner.** { *; }
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }
-keepclassmembers class * {
    @com.google.android.gms.common.annotation.KeepName *;
}

# geolocator / geocoding
-keep class com.baseflow.geolocator.** { *; }
-keep class com.baseflow.geocoding.** { *; }
-keep class com.baseflow.permissionhandler.** { *; }

# local_auth (生物辨識)
-keep class io.flutter.plugins.localauth.** { *; }
-keep class androidx.biometric.** { *; }
-keep class androidx.fragment.app.** { *; }

# wakelock_plus
-keep class dev.fluttercommunity.plus.wakelock.** { *; }

# screen_brightness
-keep class com.aaassseee.screen_brightness_android.** { *; }

# share_plus / file_picker / open_filex
-keep class dev.fluttercommunity.plus.share.** { *; }
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-keep class com.crazecoder.openfile.** { *; }

# package_info_plus / shared_preferences / path_provider
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }

# timezone
-keep class org.threeten.** { *; }

# barcode_widget
-keep class com.barcode_widget.** { *; }

# flutter_map / latlong2 — 純 Dart，不需 native keep
# Flutter 引用 Play Core (deferred components) 但我們沒用，忽略缺少的類別
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# ===== 通用保護 =====
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes SourceFile,LineNumberTable

# 保留 enum 與 reflection-friendly classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

-keepclassmembers class * {
    public <init>(...);
}

# 保留 Parcelable 的 CREATOR
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# Kotlin 反射、coroutines
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.**

# AndroidX 與 Material 常見保留
-keep class androidx.** { *; }
-dontwarn androidx.**
