package com.rajtewari.spatial_tracer_mobile

import kotlin.math.sqrt

object GestureDetector {
    // Landmark Constants
    const val WRIST = 0
    const val THUMB_CMC = 1
    const val THUMB_MCP = 2
    const val THUMB_IP = 3
    const val THUMB_TIP = 4
    const val INDEX_MCP = 5
    const val INDEX_PIP = 6
    const val INDEX_DIP = 7
    const val INDEX_TIP = 8
    const val MIDDLE_MCP = 9
    const val MIDDLE_PIP = 10
    const val MIDDLE_DIP = 11
    const val MIDDLE_TIP = 12
    const val RING_MCP = 13
    const val RING_PIP = 14
    const val RING_DIP = 15
    const val RING_TIP = 16
    const val PINKY_MCP = 17
    const val PINKY_PIP = 18
    const val PINKY_DIP = 19
    const val PINKY_TIP = 20

    val TIP = intArrayOf(THUMB_TIP, INDEX_TIP, MIDDLE_TIP, RING_TIP, PINKY_TIP)
    val PIP = intArrayOf(THUMB_IP, INDEX_PIP, MIDDLE_PIP, RING_PIP, PINKY_PIP)
    val MCP = intArrayOf(THUMB_MCP, INDEX_MCP, MIDDLE_MCP, RING_MCP, PINKY_MCP)

    private var lastGesture = "IDLE"
    private var gestureCount = 0
    // Decreasing stable frames to 2 for ultra-snappiness as requested
    private const val STABLE_FRAMES = 2

    // Simple point structure
    data class Point(val x: Double, val y: Double)

    private fun isExtended(lm: List<Point>, f: Int): Boolean {
        if (f == 0) {
            val refX = lm[INDEX_MCP].x
            return Math.abs(lm[THUMB_TIP].x - refX) > Math.abs(lm[THUMB_IP].x - refX)
        }
        return lm[TIP[f]].y < lm[MCP[f]].y
    }

    private fun isFolded(lm: List<Point>, f: Int): Boolean {
        if (f == 0) {
            val refX = lm[INDEX_MCP].x
            return Math.abs(lm[THUMB_TIP].x - refX) < Math.abs(lm[THUMB_IP].x - refX)
        }
        return lm[TIP[f]].y > lm[PIP[f]].y
    }

    private fun dist(a: Point, b: Point): Double {
        return sqrt(Math.pow(a.x - b.x, 2.0) + Math.pow(a.y - b.y, 2.0))
    }

    fun detectGesture(lmRaw: List<Map<String, Double>>): String {
        if (lmRaw.size < 21) return "IDLE"

        // Convert to list of points for easier typing
        val lm = lmRaw.map { Point(it["x"] ?: 0.0, it["y"] ?: 0.0) }

        val ext = BooleanArray(5) { isExtended(lm, it) }
        val fold = BooleanArray(5) { isFolded(lm, it) }

        val thuE = ext[0]; val idxE = ext[1]; val midE = ext[2]; val rngE = ext[3]; val pnkE = ext[4]
        val thuF = fold[0]; val idxF = fold[1]; val midF = fold[2]; val rngF = fold[3]; val pnkF = fold[4]

        val palmY = (lm[WRIST].y + lm[INDEX_MCP].y + lm[PINKY_MCP].y) / 3.0

        // FIST: All fingers rigidly folded
        if (thuF && idxF && midF && rngF && pnkF) {
            return stabilize("FIST")
        }

        // Pinch: thumb + index very close, others ideally folded or out of the way
        val pinchDist = dist(lm[THUMB_TIP], lm[INDEX_TIP])
        if (pinchDist < 0.05) return stabilize("PINCH") // tightened threshold

        // Thumbs UP/DOWN
        if (thuE && idxF && midF && rngF && pnkF) {
            if (lm[THUMB_TIP].y < palmY - 0.04) return stabilize("THUMBS_UP")
            if (lm[THUMB_TIP].y > palmY + 0.04) return stabilize("THUMBS_DOWN")
        }

        // Middle finger
        if (midE && idxF && rngF && pnkF) return stabilize("MIDDLE_FINGER")

        // Peace - ensure index and middle are distinctly separated
        if (idxE && midE && rngF && pnkF) {
             val peaceDist = dist(lm[INDEX_TIP], lm[MIDDLE_TIP])
             if (peaceDist > 0.05) {
                 return stabilize("PEACE")
             }
        }

        // Pointing: Only index extended, others rigidly folded
        if (idxE && midF && rngF && pnkF) return stabilize("POINTING")

        // Spider-man
        if (idxE && pnkE && midF && rngF) return stabilize("ROCK")

        // Three
        if (idxE && midE && rngE && pnkF) return stabilize("THREE")

        // Open Palm
        if (thuE && idxE && midE && rngE && pnkE) return stabilize("OPEN_PALM")

        return stabilize("IDLE")
    }

    private fun stabilize(gesture: String): String {
        if (gesture == lastGesture) {
            gestureCount++
        } else {
            gestureCount = 1
            lastGesture = gesture
        }
        
        return if (gestureCount >= STABLE_FRAMES) gesture else "IDLE"
    }

    fun reset() {
        lastGesture = "IDLE"
        gestureCount = 0
    }
}
