package com.rajtewari.spatial_tracer_mobile

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PixelFormat
import android.os.Build
import android.view.View
import android.view.WindowManager

class CursorOverlay(context: Context) {
    private val windowManager: WindowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val cursorView: CursorView = CursorView(context)
    
    private var isAdded = false

    private val layoutParams = WindowManager.LayoutParams(
        WindowManager.LayoutParams.MATCH_PARENT,
        WindowManager.LayoutParams.MATCH_PARENT,
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            WindowManager.LayoutParams.TYPE_PHONE,
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
        PixelFormat.TRANSLUCENT
    )

    fun show() {
        if (!isAdded) {
            windowManager.addView(cursorView, layoutParams)
            isAdded = true
        }
    }

    fun hide() {
        if (isAdded) {
            windowManager.removeView(cursorView)
            isAdded = false
        }
    }

    fun updatePosition(normX: Float, normY: Float, gesture: String) {
        cursorView.updateState(normX, normY, gesture)
    }

    private class CursorView(context: Context) : View(context) {
        private var nX: Float = 0.5f
        private var nY: Float = 0.5f
        private var currentGesture: String = "IDLE"

        private val cursorPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
            color = Color.parseColor("#34D399") // Green
        }

        private val highlightPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
            color = Color.parseColor("#7c6aff") // Purple
            alpha = 100
        }

        fun updateState(normX: Float, normY: Float, gesture: String) {
            nX = normX
            nY = normY
            currentGesture = gesture
            postInvalidate()
        }

        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)

            if (currentGesture == "NONE") {
                return
            }

            // ---------------------------------------------------------
            // REDESIGNED PROFESSIONAL CORSOR OVERLAY
            // ---------------------------------------------------------
            val px = Math.max(0f, Math.min(1f, nX)) * width
            val py = Math.max(0f, Math.min(1f, nY)) * height

            val isTap = currentGesture == "PEACE"
            
            // Outer semi-transparent ring for visibility
            highlightPaint.color = Color.parseColor("#1c1917") // Dark border
            highlightPaint.alpha = 150
            canvas.drawCircle(px, py, if (isTap) 30f else 24f, highlightPaint)
            
            // Sleek inner cursor (white standard, electric blue on tap)
            cursorPaint.color = if (isTap) Color.parseColor("#0ea5e9") else Color.WHITE
            canvas.drawCircle(px, py, if (isTap) 22f else 18f, cursorPaint)
            
            // Precise minimal dot
            highlightPaint.color = Color.BLACK
            highlightPaint.alpha = 255
            canvas.drawCircle(px, py, 4f, highlightPaint)
        }
    }
}
