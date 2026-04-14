# Flutter default rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# audioplayers
-keep class xyz.luan.audioplayers.** { *; }

# Play Core (deferred components)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# permission_handler
-keep class com.baseflow.permissionhandler.** { *; }

# flutter_local_notifications
-keep class com.dexterous.** { *; }

# timezone
-keep class org.threeten.** { *; }

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
