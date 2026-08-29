package com.rajtewari.spatial_tracer_mobile

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Intent
import android.graphics.Path
import android.os.Build
import android.view.accessibility.AccessibilityEvent
import android.util.Log

class SpatialAccessibilityService : AccessibilityService() {
    companion object {
        const val TAG = "SpatialAccessibility"
        var instance: SpatialAccessibilityService? = null
            private set
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d(TAG, "Accessibility Service Connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // We don't necessarily need to respond to UI events,
        // we mainly use this service to perform actions.
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility Service Interrupted")
    }

    override fun onUnbind(intent: Intent?): Boolean {
        instance = null
        Log.d(TAG, "Accessibility Service Unbound")
        return super.onUnbind(intent)
    }

    // --- Action Handlers ---

    fun performBackAction() {
        performGlobalAction(GLOBAL_ACTION_BACK)
    }

    fun performHomeAction() {
        performGlobalAction(GLOBAL_ACTION_HOME)
    }
    
    fun performRecentsAction() {
        performGlobalAction(GLOBAL_ACTION_RECENTS)
    }

    // Taps at a specific screen coordinate (0.0 to 1.0)
    fun performTap(normX: Float, normY: Float, screenWidth: Int, screenHeight: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val px = Math.max(0f, Math.min(1f, normX)) * screenWidth
            val py = Math.max(0f, Math.min(1f, normY)) * screenHeight
            
            val path = Path()
            path.moveTo(px, py)
            
            val builder = GestureDescription.Builder()
            val stroke = GestureDescription.StrokeDescription(path, 0, 100)
            builder.addStroke(stroke)
            
            dispatchGesture(builder.build(), null, null)
            Log.d(TAG, "Dispatched Tap at $px, $py")
        }
    }

    // Swipes from (x1,y1) to (x2,y2) 
    fun performSwipe(nX1: Float, nY1: Float, nX2: Float, nY2: Float, screenWidth: Int, screenHeight: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val px1 = Math.max(0f, Math.min(1f, nX1)) * screenWidth
            val py1 = Math.max(0f, Math.min(1f, nY1)) * screenHeight
            val px2 = Math.max(0f, Math.min(1f, nX2)) * screenWidth
            val py2 = Math.max(0f, Math.min(1f, nY2)) * screenHeight

            val path = Path()
            path.moveTo(px1, py1)
            path.lineTo(px2, py2)

            val builder = GestureDescription.Builder()
            val stroke = GestureDescription.StrokeDescription(path, 0, 300)
            builder.addStroke(stroke)

            dispatchGesture(builder.build(), null, null)
            Log.d(TAG, "Dispatched Swipe from $px1, $py1 to $px2, $py2")
        }
    }
}
