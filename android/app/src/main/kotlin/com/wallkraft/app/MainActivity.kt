package com.wallkraft.app

import android.app.WallpaperManager
import android.content.ComponentName
import android.graphics.BitmapFactory
import android.os.Build
import android.os.ParcelFileDescriptor
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.wallkraft.app/wallpaper"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "setWallpaper") {
                val path = call.argument<String>("path")
                val which = call.argument<String>("which") ?: "both"

                if (path == null) {
                    result.error("INVALID_PATH", "File path is null", null)
                    return@setMethodCallHandler
                }

                val file = File(path)
                if (!file.exists()) {
                    result.error("FILE_NOT_FOUND", "Wallpaper file not found", null)
                    return@setMethodCallHandler
                }

                try {
                    val wallpaperManager = WallpaperManager.getInstance(this)
                    val bitmap = BitmapFactory.decodeFile(path)

                    if (bitmap == null) {
                        result.error("DECODE_FAILED", "Failed to decode image", null)
                        return@setMethodCallHandler
                    }

                    when (which) {
                        "home" -> {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_SYSTEM)
                            } else {
                                wallpaperManager.setBitmap(bitmap)
                            }
                        }
                        "lock" -> {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_LOCK)
                            } else {
                                wallpaperManager.setBitmap(bitmap)
                            }
                        }
                        else -> { // "both"
                            wallpaperManager.setBitmap(bitmap)
                        }
                    }

                    bitmap.recycle()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("SET_FAILED", "Failed to set wallpaper: ${e.message}", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
