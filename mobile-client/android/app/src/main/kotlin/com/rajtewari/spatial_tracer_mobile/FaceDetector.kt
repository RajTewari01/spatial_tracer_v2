package com.rajtewari.spatial_tracer_mobile

import kotlin.math.sqrt

object FaceDetector {
    private var lastAction = "IDLE"
    private var actionCount = 0
    private const val STABLE_FRAMES = 3 // Increased for stability

    data class Point(val x: Double, val y: Double, val z: Double = 0.0)

    private fun dist(a: Point, b: Point): Double {
        return sqrt(Math.pow(a.x - b.x, 2.0) + Math.pow(a.y - b.y, 2.0))
    }

    fun detectAction(lmRaw: List<Map<String, Double>>): String {
        if (lmRaw.size < 400) return "IDLE"

        val lm = lmRaw.map { Point(it["x"] ?: 0.0, it["y"] ?: 0.0, it["z"] ?: 0.0) }

        // Eye Aspect Ratio (EAR) for Blinking
        val leftEyeHeight = dist(lm[159], lm[145])
        val leftEyeWidth = dist(lm[33], lm[133])
        val leftEar = if (leftEyeWidth > 0) leftEyeHeight / leftEyeWidth else 0.0

        val rightEyeHeight = dist(lm[386], lm[374])
        val rightEyeWidth = dist(lm[362], lm[263])
        val rightEar = if (rightEyeWidth > 0) rightEyeHeight / rightEyeWidth else 0.0

        val ear = (leftEar + rightEar) / 2.0

        // Blink Threshold tuned to 0.22
        if (ear < 0.22) {
            return stabilize("BLINK")
        }

        // --- 3D Z-Depth for accurate Tilt (MediaPipe Z is negative when closer to camera) ---
        
        // PITCH (Up/Down)
        val foreheadZ = lm[10].z
        val chinZ = lm[152].z
        val pitchDelta = chinZ - foreheadZ 
        
        // If chin is closer (more negative) than forehead -> Tilt Up
        if (pitchDelta < -0.045) return stabilize("TILT_UP")
        // If forehead is closer (more negative) than chin -> Tilt Down
        if (pitchDelta > 0.045) return stabilize("TILT_DOWN")

        // YAW (Left/Right)
        val leftCheekZ = lm[234].z
        val rightCheekZ = lm[454].z
        val yawDelta = rightCheekZ - leftCheekZ
        
        // When user turns head to their RIGHT, their left cheek comes closer to camera
        if (yawDelta > 0.045) return stabilize("TILT_RIGHT")
        // When user turns head to their LEFT, their right cheek comes closer to camera
        if (yawDelta < -0.045) return stabilize("TILT_LEFT")

        return stabilize("IDLE")
    }

    private fun stabilize(action: String): String {
        if (action == lastAction) {
            actionCount++
        } else {
            actionCount = 1
            lastAction = action
        }
        return if (actionCount >= STABLE_FRAMES) action else "IDLE"
    }

    fun reset() {
        lastAction = "IDLE"
        actionCount = 0
    }
}
