package com.rajtewari.spatial_tracer_mobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleService
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarkerResult
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

import android.os.Handler
import android.os.Looper
import android.widget.Toast
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.EventChannel

import android.content.pm.ServiceInfo

class TrackerService : LifecycleService() {

    private lateinit var cameraExecutor: ExecutorService
    private var handLandmarker: HandLandmarker? = null
    private var faceLandmarker: FaceLandmarker? = null
    private var cursorOverlay: CursorOverlay? = null
    
    // Frame alternator
    private var frameCounter = 0

    // Track which streams to process
    private var useHandTracking = true
    private var useFaceTracking = false

    // Smoothing state
    private var smoothedX = -1f
    private var smoothedY = -1f
    private val SMOOTHING_FACTOR = 0.45f // Increased from 0.25 to make cursor tracking snappier

    companion object {
        const val TAG = "TrackerService"
        const val NOTIFICATION_ID = 12345
        const val CHANNEL_ID = "SpatialTracerChannel"
        
        // EventSink for pushing live gestures to Flutter
        var gestureEventSink: EventChannel.EventSink? = null
    }

    override fun onCreate() {
        super.onCreate()
        cameraExecutor = Executors.newSingleThreadExecutor()
        createNotificationChannel()
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, buildNotification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA)
        } else {
            startForeground(NOTIFICATION_ID, buildNotification())
        }
        
        cursorOverlay = CursorOverlay(this)
        cursorOverlay?.show()

        initHandLandmarker()
        initFaceLandmarker()
        startCamera()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        super.onStartCommand(intent, flags, startId)
        if (intent?.action == "STOP_SERVICE") {
            stopSelf()
            return START_NOT_STICKY
        }
        
        // Update active trackers based on UI toggles
        useHandTracking = intent?.getBooleanExtra("USE_HAND", true) ?: true
        useFaceTracking = intent?.getBooleanExtra("USE_FACE", false) ?: false

        // Check if Accessibility Service is bound
        if (SpatialAccessibilityService.instance == null) {
            Log.w(TAG, "Accessibility Service is not bound but tracker started.")
        }
        
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        cursorOverlay?.hide()
        cameraExecutor.shutdown()
        handLandmarker?.close()
        faceLandmarker?.close()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Spatial Tracer Active",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Spatial Tracer")
            .setContentText("Air gestures are active in the background")
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .build()
    }

    private fun initHandLandmarker() {
        val modelFile = File(cacheDir, "hand_landmarker.task")
        if (!modelFile.exists() || modelFile.length() < 1000L) {
            assets.open("hand_landmarker.task").use { input ->
                FileOutputStream(modelFile).use { output ->
                    input.copyTo(output)
                }
            }
        }

        val baseOptions = BaseOptions.builder()
            .setModelAssetPath(modelFile.absolutePath)
            .build()

        val options = HandLandmarker.HandLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setRunningMode(RunningMode.LIVE_STREAM)
            .setNumHands(1)
            .setMinHandDetectionConfidence(0.5f)
            .setMinTrackingConfidence(0.5f)
            .setResultListener(this::onHandLandmarkerResult)
            .setErrorListener { error ->
                Log.e(TAG, "MediaPipe error: ${error.message}")
            }
            .build()

        handLandmarker = HandLandmarker.createFromOptions(this, options)
    }

    private fun initFaceLandmarker() {
        val modelFile = File(cacheDir, "face_landmarker.task")
        if (!modelFile.exists() || modelFile.length() < 1000L) {
            assets.open("face_landmarker.task").use { input ->
                FileOutputStream(modelFile).use { output ->
                    input.copyTo(output)
                }
            }
        }

        val baseOptions = BaseOptions.builder()
            .setModelAssetPath(modelFile.absolutePath)
            .build()

        val options = FaceLandmarker.FaceLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setRunningMode(RunningMode.LIVE_STREAM)
            .setNumFaces(1)
            .setMinFaceDetectionConfidence(0.5f)
            .setMinTrackingConfidence(0.5f)
            .setResultListener(this::onFaceLandmarkerResult)
            .setErrorListener { error ->
                Log.e(TAG, "MediaPipe face error: ${error.message}")
            }
            .build()

        faceLandmarker = FaceLandmarker.createFromOptions(this, options)
    }

    private fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(this)

        cameraProviderFuture.addListener({
            val cameraProvider = cameraProviderFuture.get()

            val imageAnalyzer = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
                .build()
                .also {
                    it.setAnalyzer(cameraExecutor) { imageProxy ->
                        try {
                            val bitmap = android.graphics.Bitmap.createBitmap(
                                imageProxy.width, imageProxy.height, android.graphics.Bitmap.Config.ARGB_8888
                            )
                            imageProxy.planes[0].buffer.rewind()
                            bitmap.copyPixelsFromBuffer(imageProxy.planes[0].buffer)
                            
                            val mpImage = BitmapImageBuilder(bitmap).build()
                            // Force strict monotonically increasing timestamp to prevent silent MediaPipe crashes
                            val timestampMs = android.os.SystemClock.uptimeMillis()
                            
                            frameCounter++
                            
                            if (useHandTracking && useFaceTracking) {
                                // Alternate frames to prevent overwhelming the device and causing massive lag
                                if (frameCounter % 2 == 0) {
                                    handLandmarker?.detectAsync(mpImage, timestampMs)
                                } else {
                                    faceLandmarker?.detectAsync(mpImage, timestampMs)
                                }
                            } else if (useHandTracking) {
                                handLandmarker?.detectAsync(mpImage, timestampMs)
                            } else if (useFaceTracking) {
                                faceLandmarker?.detectAsync(mpImage, timestampMs)
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Frame processing error: ${e.message}")
                        } finally {
                            // CRITICAL: Always close the image proxy to prevent CameraX from freezing forever
                            imageProxy.close()
                        }
                    }
                }

            val cameraSelector = CameraSelector.DEFAULT_FRONT_CAMERA

            try {
                cameraProvider.unbindAll()
                cameraProvider.bindToLifecycle(this, cameraSelector, imageAnalyzer)
            } catch (exc: Exception) {
                Log.e(TAG, "Use case binding failed", exc)
            }

        }, ContextCompat.getMainExecutor(this))
    }

    private fun onFaceLandmarkerResult(result: FaceLandmarkerResult, mpImage: MPImage) {
        if (!useFaceTracking || result.faceLandmarks().isEmpty()) {
            FaceDetector.reset()
            return
        }

        val lmRaw = mutableListOf<Map<String, Double>>()
        result.faceLandmarks()[0].forEach { lm ->
            lmRaw.add(mapOf("x" to lm.x().toDouble(), "y" to lm.y().toDouble(), "z" to lm.z().toDouble()))
        }

        val action = FaceDetector.detectAction(lmRaw)
        
        val accService = SpatialAccessibilityService.instance
        if (accService != null && action != "IDLE") {
            handleFaceAction(accService, action)
        }
    }

    private fun onHandLandmarkerResult(result: HandLandmarkerResult, mpImage: MPImage) {
        if (!useHandTracking || result.landmarks().isEmpty()) {
            GestureDetector.reset()
            smoothedX = -1f
            smoothedY = -1f
            cursorOverlay?.updatePosition(0.5f, 0.5f, "NONE")
            return
        }

        val lmRaw = mutableListOf<Map<String, Double>>()
        result.landmarks()[0].forEachIndexed { idx, lm ->
            lmRaw.add(mapOf("x" to lm.x().toDouble(), "y" to lm.y().toDouble()))
        }

        val gesture = GestureDetector.detectGesture(lmRaw)
        
        val idx = lmRaw[8]
        val thumb = lmRaw[4]
        
        // Calculate pointing coordinate (mirrored X)
        val midX = ((idx["x"]!! + thumb["x"]!!) / 2).toFloat()
        val midY = ((idx["y"]!! + thumb["y"]!!) / 2).toFloat()
        
        val targetX = if (gesture == "PINCH") 1f - midX else 1f - idx["x"]!!.toFloat()
        val targetY = if (gesture == "PINCH") midY else idx["y"]!!.toFloat()

        // Apply Exponential Moving Average (EMA) Smoothing
        if (smoothedX == -1f && smoothedY == -1f) {
            // First frame tracking, snap directly
            smoothedX = targetX
            smoothedY = targetY
        } else {
            // Interpolate for smooth glide
            smoothedX = smoothedX + SMOOTHING_FACTOR * (targetX - smoothedX)
            smoothedY = smoothedY + SMOOTHING_FACTOR * (targetY - smoothedY)
        }

        cursorOverlay?.updatePosition(smoothedX, smoothedY, gesture)

        // Dispatch to Accessibility Service
        val accService = SpatialAccessibilityService.instance
        if (accService != null && gesture != "IDLE" && gesture != "NONE") {
            handleGestureAction(accService, gesture, lmRaw, smoothedX, smoothedY)
        }
    }

    // Cooldown state
    private var lastActionTime = 0L
    private var lastFaceActionTime = 0L

    private fun handleFaceAction(acc: SpatialAccessibilityService, action: String) {
        val now = System.currentTimeMillis()
        
        // Broadcast the active face state back to the Flutter UI layer if needed
        Handler(Looper.getMainLooper()).post {
            gestureEventSink?.success(action)
        }

        when (action) {
            "BLINK" -> {
                if (now - lastFaceActionTime > 1500) {
                    // BLINK -> Opens Recent Apps menu to close apps
                    Handler(Looper.getMainLooper()).post { acc.performRecentsAction() }
                    lastFaceActionTime = now
                }
            }
            "TILT_UP", "TILT_DOWN" -> {
                if (now - lastFaceActionTime > 1000) {
                    val resources = resources
                    val sw = resources.displayMetrics.widthPixels
                    val sh = resources.displayMetrics.heightPixels
                    Handler(Looper.getMainLooper()).post {
                        if (action == "TILT_UP") {
                            // Scroll up (Swipe down)
                            acc.performSwipe(0.5f, 0.3f, 0.5f, 0.7f, sw, sh)
                        } else {
                            // Scroll down (Swipe up)
                            acc.performSwipe(0.5f, 0.7f, 0.5f, 0.3f, sw, sh)
                        }
                    }
                    lastFaceActionTime = now
                }
            }
            "TILT_LEFT", "TILT_RIGHT" -> {
                if (now - lastFaceActionTime > 1000) {
                    val resources = resources
                    val sw = resources.displayMetrics.widthPixels
                    val sh = resources.displayMetrics.heightPixels
                    Handler(Looper.getMainLooper()).post {
                        if (action == "TILT_LEFT") {
                            // Swipe Right
                            acc.performSwipe(0.2f, 0.5f, 0.8f, 0.5f, sw, sh)
                        } else {
                            // Swipe Left
                            acc.performSwipe(0.8f, 0.5f, 0.2f, 0.5f, sw, sh)
                        }
                    }
                    lastFaceActionTime = now
                }
            }
        }
    }

    private fun handleGestureAction(acc: SpatialAccessibilityService, gesture: String, lm: List<Map<String, Double>>, px: Float, py: Float) {
        val now = System.currentTimeMillis()
        
        // Broadcast the active gesture state back to the Flutter UI layer
        Handler(Looper.getMainLooper()).post {
            gestureEventSink?.success(gesture)
        }
        
        when (gesture) {
            "POINTING" -> {
                // Overlay updates automatically above
            }
            "PEACE" -> {
                if (now - lastActionTime > 600) { // Reduced tap cooldown from 1000
                    val resources = resources
                    val displayMetrics = resources.displayMetrics
                    val sw = displayMetrics.widthPixels
                    val sh = displayMetrics.heightPixels
                    
                    // PEACE -> Taps the screen at pointer location
                    Handler(Looper.getMainLooper()).post { acc.performTap(px, py, sw, sh) }
                    lastActionTime = now
                }
            }
            "PINCH" -> {
                if (now - lastActionTime > 1000) { // Reduced from 1500
                    // PINCH -> Goes Back
                    Handler(Looper.getMainLooper()).post { acc.performBackAction() }
                    lastActionTime = now
                }
            }
            "FIST" -> {
                if (now - lastActionTime > 1000) {
                    // FIST -> Opens Recent Apps menu
                    Handler(Looper.getMainLooper()).post { acc.performRecentsAction() }
                    lastActionTime = now
                }
            }
            "THREE" -> {
                if (now - lastActionTime > 1000) {
                    // THREE fingers -> Go Home
                    Handler(Looper.getMainLooper()).post { acc.performHomeAction() }
                    lastActionTime = now
                }
            }
            "THUMBS_UP", "THUMBS_DOWN" -> {
                if (now - lastActionTime > 500) {
                    // Quick Swipe mapping
                    val resources = resources
                    val sw = resources.displayMetrics.widthPixels
                    val sh = resources.displayMetrics.heightPixels
                    Handler(Looper.getMainLooper()).post {
                        if (gesture == "THUMBS_UP") {
                            // Scroll down (Swipe up)
                            acc.performSwipe(0.5f, 0.7f, 0.5f, 0.3f, sw, sh)
                        } else {
                            // Scroll up (Swipe down)
                            acc.performSwipe(0.5f, 0.3f, 0.5f, 0.7f, sw, sh)
                        }
                    }
                    lastActionTime = now
                }
            }
        }
    }
}
