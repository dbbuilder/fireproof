<template>
  <div
    class="signature-pad"
    data-testid="signature-pad"
  >
    <!-- Canvas Container -->
    <div class="canvas-container">
      <canvas
        ref="canvasElement"
        class="signature-canvas"
        data-testid="signature-canvas"
        @touchstart="handleTouchStart"
        @touchmove="handleTouchMove"
        @touchend="handleTouchEnd"
        @mousedown="handleMouseDown"
        @mousemove="handleMouseMove"
        @mouseup="handleMouseUp"
        @mouseleave="handleMouseLeave"
      />

      <!-- Placeholder Text -->
      <div
        v-if="!hasSignature && !isDrawing"
        class="placeholder-text"
        data-testid="placeholder-text"
      >
        Sign here
      </div>
    </div>

    <!-- Controls -->
    <div class="controls">
      <button
        class="btn-control btn-clear"
        data-testid="btn-clear"
        :disabled="!hasSignature"
        @click="handleClear"
      >
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
        >
          <polyline points="3 6 5 6 21 6" />
          <path d="M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2" />
        </svg>
        <span>Clear</span>
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, watch, defineEmits, defineExpose } from 'vue'

// Emits
const emit = defineEmits(['signature-updated'])

// State
const canvasElement = ref(null)
const isDrawing = ref(false)
const hasSignature = ref(false)
const lastPoint = ref(null)

// Drawing context
let ctx = null

/**
 * Initialize canvas
 */
const initCanvas = () => {
  if (!canvasElement.value) return

  const canvas = canvasElement.value
  const container = canvas.parentElement

  // Set canvas size to match container
  canvas.width = container.clientWidth
  canvas.height = container.clientHeight

  // Get context
  ctx = canvas.getContext('2d')

  // Set drawing style
  ctx.strokeStyle = '#111827'
  ctx.lineWidth = 2
  ctx.lineCap = 'round'
  ctx.lineJoin = 'round'
}

/**
 * Get point coordinates from event
 */
const getPointFromEvent = (event) => {
  const canvas = canvasElement.value
  if (!canvas) return null

  const rect = canvas.getBoundingClientRect()
  const scaleX = canvas.width / rect.width
  const scaleY = canvas.height / rect.height

  let clientX, clientY

  if (event.touches && event.touches.length > 0) {
    clientX = event.touches[0].clientX
    clientY = event.touches[0].clientY
  } else {
    clientX = event.clientX
    clientY = event.clientY
  }

  return {
    x: (clientX - rect.left) * scaleX,
    y: (clientY - rect.top) * scaleY
  }
}

/**
 * Draw line from last point to current point
 */
const drawLine = (fromPoint, toPoint) => {
  if (!ctx || !fromPoint || !toPoint) return

  ctx.beginPath()
  ctx.moveTo(fromPoint.x, fromPoint.y)
  ctx.lineTo(toPoint.x, toPoint.y)
  ctx.stroke()
}

/**
 * Touch start handler
 */
const handleTouchStart = (event) => {
  event.preventDefault()
  isDrawing.value = true
  lastPoint.value = getPointFromEvent(event)
  hasSignature.value = true
}

/**
 * Touch move handler
 */
const handleTouchMove = (event) => {
  event.preventDefault()

  if (!isDrawing.value) return

  const currentPoint = getPointFromEvent(event)
  drawLine(lastPoint.value, currentPoint)
  lastPoint.value = currentPoint

  emitSignature()
}

/**
 * Touch end handler
 */
const handleTouchEnd = (event) => {
  event.preventDefault()
  isDrawing.value = false
  lastPoint.value = null
}

/**
 * Mouse down handler
 */
const handleMouseDown = (event) => {
  isDrawing.value = true
  lastPoint.value = getPointFromEvent(event)
  hasSignature.value = true
}

/**
 * Mouse move handler
 */
const handleMouseMove = (event) => {
  if (!isDrawing.value) return

  const currentPoint = getPointFromEvent(event)
  drawLine(lastPoint.value, currentPoint)
  lastPoint.value = currentPoint

  emitSignature()
}

/**
 * Mouse up handler
 */
const handleMouseUp = () => {
  isDrawing.value = false
  lastPoint.value = null
}

/**
 * Mouse leave handler
 */
const handleMouseLeave = () => {
  if (isDrawing.value) {
    isDrawing.value = false
    lastPoint.value = null
  }
}

/**
 * Clear signature
 */
const handleClear = () => {
  if (!ctx || !canvasElement.value) return

  ctx.clearRect(0, 0, canvasElement.value.width, canvasElement.value.height)
  hasSignature.value = false
  emit('signature-updated', null)
}

/**
 * Get signature as data URL
 */
const getSignatureDataURL = () => {
  if (!canvasElement.value || !hasSignature.value) return null
  return canvasElement.value.toDataURL('image/png')
}

/**
 * Emit signature update
 */
const emitSignature = () => {
  if (hasSignature.value) {
    emit('signature-updated', getSignatureDataURL())
  }
}

/**
 * Handle window resize
 */
const handleResize = () => {
  // Save current signature
  const imageData = hasSignature.value ? canvasElement.value.toDataURL() : null

  // Reinitialize canvas
  initCanvas()

  // Restore signature if exists
  if (imageData && hasSignature.value) {
    const img = new Image()
    img.onload = () => {
      ctx.drawImage(img, 0, 0)
    }
    img.src = imageData
  }
}

// Expose methods to parent
defineExpose({
  getSignatureDataURL,
  clear: handleClear
})

// Initialize on mount
onMounted(() => {
  initCanvas()
  window.addEventListener('resize', handleResize)
})

// Cleanup on unmount
onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
})
</script>

<style scoped>
/* Container */
.signature-pad {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

/* Canvas Container */
.canvas-container {
  position: relative;
  width: 100%;
  height: 200px;
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 0.5rem;
  overflow: hidden;
}

.signature-canvas {
  width: 100%;
  height: 100%;
  touch-action: none;
  cursor: crosshair;
}

.placeholder-text {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-size: 1.125rem;
  font-weight: 500;
  color: #d1d5db;
  pointer-events: none;
  user-select: none;
}

/* Controls */
.controls {
  display: flex;
  justify-content: flex-end;
}

.btn-control {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1.25rem;
  background: transparent;
  border: 2px solid #e5e7eb;
  border-radius: 0.375rem;
  color: #6b7280;
  font-size: 0.875rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-control svg {
  width: 18px;
  height: 18px;
  stroke-width: 2;
}

.btn-control:hover:not(:disabled) {
  border-color: #d1d5db;
  background: #f9fafb;
}

.btn-control:active:not(:disabled) {
  transform: scale(0.98);
}

.btn-control:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-clear {
  border-color: #fecaca;
  color: #dc2626;
}

.btn-clear:hover:not(:disabled) {
  border-color: #f87171;
  background: #fef2f2;
}

/* Mobile Optimization */
@media (max-width: 640px) {
  .canvas-container {
    height: 180px;
  }

  .placeholder-text {
    font-size: 1rem;
  }

  .btn-control {
    padding: 0.625rem 1rem;
    font-size: 0.8125rem;
  }

  .btn-control svg {
    width: 16px;
    height: 16px;
  }
}

/* Touch target assurance */
@media (pointer: coarse) {
  .btn-control {
    min-height: 44px;
  }
}
</style>
