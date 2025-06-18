# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep MainActivity
-keep class com.granthakatha.app.MainActivity { *; }
-keepclassmembers class com.granthakatha.app.MainActivity { *; }

# Keep all activities and their methods
-keep public class * extends android.app.Activity {
    public protected *;
}

# Keep all Flutter embedding classes
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }

# Plugins
-keep class com.ryanheise.** { *; }
-keep class xyz.luan.** { *; }
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep all classes in the app package
-keep class com.granthakatha.app.** { *; }

# Keep GeneratedPluginRegistrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }