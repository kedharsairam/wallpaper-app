# WallKraft ProGuard / R8 Rules
# Prevents model classes from being stripped during release builds.

# Keep all data model classes (used for JSON serialization)
-keep class com.wallkraft.app.models.** { *; }

# Keep all app classes (catch-all for safety)
-keep class com.wallkraft.app.** { *; }

# Keep annotations (for any future annotation-based processing)
-keepattributes *Annotation*

# Keep Gson/JSON serialization fields (if used)
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
