package com.rajtewari.spatial_tracer_mobile

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import android.util.Log
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.rajtewari/hand_tracker"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        startActivityForResult(intent, 1234)
                        result.error("PERMISSION_DENIED", "Please grant overlay permission", null)
                        return@setMethodCallHandler
                    }

                    val useHand = call.argument<Boolean>("useHand") ?: true
                    val useFace = call.argument<Boolean>("useFace") ?: false

                    val serviceIntent = Intent(this, TrackerService::class.java).apply {
                        putExtra("USE_HAND", useHand)
                        putExtra("USE_FACE", useFace)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }
                    result.success(true)
                }
                "stopService" -> {
                    val serviceIntent = Intent(this, TrackerService::class.java).apply {
                        action = "STOP_SERVICE"
                    }
                    startService(serviceIntent)
                    result.success(true)
                }
                "checkOverlayPermission" -> {
                    val hasPerm = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        Settings.canDrawOverlays(this)
                    } else true
                    result.success(hasPerm)
                }

                "openAccessibilitySettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // --- NEW: Register EventChannel for live gesture streaming to Flutter ---
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.rajtewari/gesture_stream").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    TrackerService.gestureEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    TrackerService.gestureEventSink = null
                }
            }
        )

    }
}

