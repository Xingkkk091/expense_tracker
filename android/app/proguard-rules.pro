# ProGuard / R8 規則 (v1.0.6)
# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# sqflite
-keep class com.tekartik.sqflite.** { *; }

# mobile_scanner (Google ML Kit)
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }
-keepclassmembers class * {
    @com.google.android.gms.common.annotation.KeepName *;
}

# geolocator / geocoding
-keep class com.baseflow.geolocator.** { *; }
-keep class com.baseflow.geocoding.** { *; }

# local_auth
-keep class io.flutter.plugins.localauth.** { *; }

# permission_handler
-keep class com.baseflow.permissionhandler.** { *; }

# 一般 JSON / Map operations - keep model classes used by sqflite
-keepclassmembers class * {
    public <init>(...);
}

# 不要混淆會被 reflection 用到的 enum
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# 保留 Annotation
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses

# Flutter 引用 Play Core (deferred components) 但我們沒用，忽略缺少的類別
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
