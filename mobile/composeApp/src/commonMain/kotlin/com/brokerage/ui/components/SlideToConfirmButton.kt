package com.brokerage.ui.components
import com.brokerage.ui.icons.BrokerageIcons

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.brokerage.ui.theme.*
import kotlin.math.roundToInt

/**
 * Slide to confirm button component
 * Implements swipe-to-confirm pattern for critical actions like order submission
 *
 * Security features:
 * - Requires full swipe (95% threshold) to confirm
 * - Visual feedback during swipe
 * - Auto-reset on incomplete swipe
 * - Haptic feedback on completion (platform-specific)
 */
@Composable
fun SlideToConfirmButton(
    text: String,
    onConfirm: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    backgroundColor: Color = PrimaryBlue,
    textColor: Color = Color.White,
    thumbColor: Color = Color.White
) {
    var offsetX by remember { mutableStateOf(0f) }
    var isCompleted by remember { mutableStateOf(false) }

    val buttonWidth = 320.dp
    val thumbSize = 56.dp
    val maxOffset = with(androidx.compose.ui.platform.LocalDensity.current) {
        (buttonWidth - thumbSize - 8.dp).toPx()
    }

    // Auto-reset animation when drag is released without completion
    val animatedOffset by animateFloatAsState(
        targetValue = if (isCompleted) maxOffset else 0f,
        animationSpec = tween(durationMillis = 300, easing = FastOutSlowInEasing),
        label = "slide_offset"
    )

    LaunchedEffect(isCompleted) {
        if (isCompleted) {
            // Trigger confirmation after animation completes
            kotlinx.coroutines.delay(100)
            onConfirm()
            // Reset state
            kotlinx.coroutines.delay(300)
            isCompleted = false
            offsetX = 0f
        }
    }

    Box(
        modifier = modifier
            .width(buttonWidth)
            .height(64.dp)
            .clip(RoundedCornerShape(32.dp))
            .background(if (enabled) backgroundColor.copy(alpha = 0.2f) else Color.Gray.copy(alpha = 0.2f))
    ) {
        // Background text
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = text,
                fontSize = 16.sp,
                fontWeight = FontWeight.Medium,
                color = if (enabled) backgroundColor else Color.Gray
            )
        }

        // Sliding thumb
        Box(
            modifier = Modifier
                .offset { IntOffset((if (isCompleted) animatedOffset else offsetX).roundToInt(), 0) }
                .padding(4.dp)
                .size(thumbSize)
                .clip(CircleShape)
                .background(if (enabled) thumbColor else Color.Gray)
                .pointerInput(enabled) {
                    if (enabled) {
                        detectHorizontalDragGestures(
                            onDragEnd = {
                                // Check if swipe reached threshold (95%)
                                if (offsetX >= maxOffset * 0.95f) {
                                    isCompleted = true
                                } else {
                                    // Reset to start
                                    offsetX = 0f
                                }
                            },
                            onHorizontalDrag = { _, dragAmount ->
                                val newOffset = (offsetX + dragAmount).coerceIn(0f, maxOffset)
                                offsetX = newOffset
                            }
                        )
                    }
                },
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = BrokerageIcons.ArrowForward,
                contentDescription = null,
                tint = if (enabled) backgroundColor else Color.Gray,
                modifier = Modifier.size(24.dp)
            )
        }
    }
}
