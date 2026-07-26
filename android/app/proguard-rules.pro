# Flutter ProGuard Rules for WallKraft
# Keep all model/serialization classes (used with jsonEncode/jsonDecode).
-keep class com.wallkraft.app.** { *; }
-keep class com.wallkraft.app.models.** { *; }

# Keep Kotlin serialization.
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

# Keep Flutter engine classes.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
