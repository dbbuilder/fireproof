<template>
  <div class="inspection-photos">
    <!-- Header -->
    <div class="photos-header">
      <button
        class="btn-back"
        data-testid="back-button"
        @click="handleBack"
      >
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
        >
          <path d="M19 12H5M12 19l-7-7 7-7" />
        </svg>
      </button>
      <h1
        class="photos-heading"
        data-testid="page-heading"
      >
        Add Photos
      </h1>
      <div class="header-spacer" />
    </div>

    <!-- Instructions -->
    <div class="instructions">
      <div class="instruction-icon">
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
        >
          <rect
            x="3"
            y="3"
            width="18"
            height="18"
            rx="2"
            ry="2"
          />
          <circle
            cx="8.5"
            cy="8.5"
            r="1.5"
          />
          <path d="M21 15l-5-5L5 21" />
        </svg>
      </div>
      <p class="instruction-text">
        Add inspection photos
      </p>
      <p class="instruction-subtext">
        Take photos of the extinguisher and any deficiencies (optional but recommended)
      </p>
    </div>

    <!-- Photo Grid with Add Photo Button -->
    <div class="photos-content">
      <div
        class="photo-grid"
        data-testid="photo-grid"
      >
        <!-- Existing Photos -->
        <div
          v-for="(photo, index) in photos"
          :key="index"
          class="photo-item"
          :data-testid="`photo-item-${index}`"
        >
          <img
            :src="photo.dataUrl || photo.url"
            :alt="`Photo ${index + 1}`"
            class="photo-thumbnail"
          >
          <button
            class="btn-delete-photo"
            :data-testid="`btn-delete-${index}`"
            @click="handleDeletePhoto(index)"
          >
            <svg
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
            >
              <line
                x1="18"
                y1="6"
                x2="6"
                y2="18"
              />
              <line
                x1="6"
                y1="6"
                x2="18"
                y2="18"
              />
            </svg>
          </button>
          <div class="photo-label">
            Photo {{ index + 1 }}
          </div>
        </div>

        <!-- Add Photo Button -->
        <button
          v-if="photos.length < maxPhotos"
          class="btn-add-photo"
          data-testid="btn-add-photo"
          @click="showCamera = true"
        >
          <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
          >
            <rect
              x="3"
              y="3"
              width="18"
              height="18"
              rx="2"
              ry="2"
            />
            <circle
              cx="8.5"
              cy="8.5"
              r="1.5"
            />
            <path d="M21 15l-5-5L5 21" />
          </svg>
          <span>Add Photo</span>
        </button>
      </div>

      <!-- Photo Count Info -->
      <div
        class="photo-info"
        data-testid="photo-info"
      >
        <span>{{ photos.length }} of {{ maxPhotos }} photos added</span>
        <span class="info-optional">(Optional)</span>
      </div>
    </div>

    <!-- Skip/Continue Buttons -->
    <div class="action-buttons">
      <button
        class="btn-skip"
        data-testid="btn-skip"
        @click="handleSkip"
      >
        <span>Skip Photos</span>
      </button>
      <button
        class="btn-continue"
        data-testid="btn-continue"
        :disabled="photos.length === 0"
        @click="handleContinue"
      >
        <span>Continue</span>
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
        >
          <path d="M5 12h14M12 5l7 7-7 7" />
        </svg>
      </button>
    </div>

    <!-- Camera Modal -->
    <div
      v-if="showCamera"
      class="camera-modal"
    >
      <div class="camera-container">
        <video
          ref="videoElement"
          autoplay
          playsinline
          class="camera-video"
          data-testid="camera-video"
        />

        <!-- Camera Controls -->
        <div class="camera-controls">
          <button
            class="btn-camera-cancel"
            data-testid="btn-cancel-camera"
            @click="handleCancelCamera"
          >
            <svg
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
            >
              <line
                x1="18"
                y1="6"
                x2="6"
                y2="18"
              />
              <line
                x1="6"
                y1="6"
                x2="18"
                y2="18"
              />
            </svg>
            <span>Cancel</span>
          </button>

          <button
            class="btn-camera-capture"
            data-testid="btn-capture-photo"
            @click="handleCapture"
          >
            <div class="capture-ring">
              <div class="capture-button" />
            </div>
          </button>

          <button
            class="btn-camera-switch"
            data-testid="btn-switch-camera"
            @click="handleSwitchCamera"
          >
            <svg
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
            >
              <path d="M15 3h6v6M9 21H3v-6M21 3l-7 7M3 21l7-7" />
            </svg>
            <span>Flip</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Camera Error -->
    <div
      v-if="cameraError"
      class="alert-error"
      data-testid="camera-error"
    >
      <svg
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
      >
        <circle
          cx="12"
          cy="12"
          r="10"
        />
        <line
          x1="15"
          y1="9"
          x2="9"
          y2="15"
        />
        <line
          x1="9"
          y1="9"
          x2="15"
          y2="15"
        />
      </svg>
      <span>{{ cameraError }}</span>
    </div>
  </div>
</template>

<script setup>
import { ref, onUnmounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useInspectorStore } from '@/stores/useInspectorStore'

const router = useRouter()
const inspectorStore = useInspectorStore()

// State
const photos = ref([])
const showCamera = ref(false)
const videoElement = ref(null)
const cameraStream = ref(null)
const cameraError = ref('')
const facingMode = ref('environment') // 'environment' (rear camera) or 'user' (front camera)
const maxPhotos = 5

// Computed
const currentLocation = computed(() => inspectorStore.currentLocation)
const currentExtinguisher = computed(() => inspectorStore.currentExtinguisher)
const currentInspection = computed(() => inspectorStore.currentInspection)

/**
 * Start camera
 */
const startCamera = async () => {
  cameraError.value = ''

  try {
    // Request camera access
    const stream = await navigator.mediaDevices.getUserMedia({
      video: {
        facingMode: facingMode.value,
        width: { ideal: 1920 },
        height: { ideal: 1080 }
      },
      audio: false
    })

    cameraStream.value = stream

    // Set video source
    if (videoElement.value) {
      videoElement.value.srcObject = stream
    }
  } catch (error) {
    console.error('Camera error:', error)

    let errorMessage = 'Failed to access camera'

    if (error.name === 'NotAllowedError' || error.name === 'PermissionDeniedError') {
      errorMessage = 'Camera permission denied. Please allow camera access in your browser settings.'
    } else if (error.name === 'NotFoundError' || error.name === 'DevicesNotFoundError') {
      errorMessage = 'No camera found on this device.'
    } else if (error.name === 'NotReadableError' || error.name === 'TrackStartError') {
      errorMessage = 'Camera is already in use by another application.'
    }

    cameraError.value = errorMessage
    showCamera.value = false
  }
}

/**
 * Capture photo from video stream
 */
const handleCapture = () => {
  if (!videoElement.value || !cameraStream.value) {
    cameraError.value = 'Camera not available'
    return
  }

  // Create canvas to capture frame
  const canvas = document.createElement('canvas')
  const video = videoElement.value

  canvas.width = video.videoWidth
  canvas.height = video.videoHeight

  const context = canvas.getContext('2d')
  context.drawImage(video, 0, 0, canvas.width, canvas.height)

  // Convert to data URL
  const dataUrl = canvas.toDataURL('image/jpeg', 0.85)

  // Add photo to array
  photos.value.push({
    dataUrl,
    timestamp: Date.now(),
    facingMode: facingMode.value
  })

  // Stop camera
  stopCamera()
  showCamera.value = false
}

/**
 * Cancel camera
 */
const handleCancelCamera = () => {
  stopCamera()
  showCamera.value = false
}

/**
 * Switch camera (front/rear)
 */
const handleSwitchCamera = async () => {
  // Toggle facing mode
  facingMode.value = facingMode.value === 'environment' ? 'user' : 'environment'

  // Restart camera with new facing mode
  stopCamera()
  await startCamera()
}

/**
 * Delete photo
 */
const handleDeletePhoto = (index) => {
  if (confirm('Delete this photo?')) {
    photos.value.splice(index, 1)
  }
}

/**
 * Stop camera stream
 */
const stopCamera = () => {
  if (cameraStream.value) {
    cameraStream.value.getTracks().forEach(track => track.stop())
    cameraStream.value = null
  }

  if (videoElement.value) {
    videoElement.value.srcObject = null
  }
}

/**
 * Handle back button
 */
const handleBack = () => {
  if (photos.value.length > 0) {
    if (confirm('Are you sure? Your photos will be lost.')) {
      router.push('/inspector/inspection-checklist')
    }
  } else {
    router.push('/inspector/inspection-checklist')
  }
}

/**
 * Handle skip button
 */
const handleSkip = () => {
  // Continue without photos
  router.push('/inspector/inspection-signature')
}

/**
 * Handle continue button
 */
const handleContinue = () => {
  if (photos.value.length === 0) {
    cameraError.value = 'Please add at least one photo or click Skip'
    return
  }

  // Save photos to inspection (in production, these would be uploaded)
  // For now, just navigate to signature
  router.push('/inspector/inspection-signature')
}

// Watch for showCamera changes to start/stop camera
import { watch } from 'vue'

watch(showCamera, async (newValue) => {
  if (newValue) {
    await startCamera()
  } else {
    stopCamera()
  }
})

// Cleanup on unmount
onUnmounted(() => {
  stopCamera()
})
</script>

<style scoped>
/* Container */
.inspection-photos {
  max-width: 600px;
  margin: 0 auto;
  padding: 0 0 1rem 0;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

/* Header */
.photos-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1rem;
  background: white;
  border-bottom: 1px solid #e5e7eb;
  position: sticky;
  top: 0;
  z-index: 10;
}

.btn-back {
  width: 44px;
  height: 44px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  color: #3b82f6;
  cursor: pointer;
  border-radius: 0.375rem;
  transition: all 0.2s;
}

.btn-back svg {
  width: 24px;
  height: 24px;
  stroke-width: 2.5;
}

.btn-back:hover {
  background: #eff6ff;
}

.btn-back:active {
  transform: scale(0.95);
}

.photos-heading {
  font-size: 1.125rem;
  font-weight: 700;
  color: #111827;
  margin: 0;
}

.header-spacer {
  width: 44px;
}

/* Instructions */
.instructions {
  text-align: center;
  padding: 2rem 1rem 1rem;
  background: #f9fafb;
}

.instruction-icon {
  width: 64px;
  height: 64px;
  margin: 0 auto 1rem;
  background: #eff6ff;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #3b82f6;
}

.instruction-icon svg {
  width: 32px;
  height: 32px;
  stroke-width: 2;
}

.instruction-text {
  font-size: 1.125rem;
  font-weight: 600;
  color: #111827;
  margin: 0 0 0.5rem 0;
}

.instruction-subtext {
  font-size: 0.875rem;
  color: #6b7280;
  margin: 0;
}

/* Photos Content */
.photos-content {
  flex: 1;
  padding: 1rem;
}

/* Photo Grid */
.photo-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  gap: 1rem;
  margin-bottom: 1rem;
}

.photo-item {
  position: relative;
  aspect-ratio: 1;
  border-radius: 0.5rem;
  overflow: hidden;
  background: #f3f4f6;
}

.photo-thumbnail {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.btn-delete-photo {
  position: absolute;
  top: 0.5rem;
  right: 0.5rem;
  width: 32px;
  height: 32px;
  background: rgba(239, 68, 68, 0.9);
  border: none;
  border-radius: 50%;
  color: white;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.btn-delete-photo svg {
  width: 18px;
  height: 18px;
  stroke-width: 2.5;
}

.btn-delete-photo:hover {
  background: rgba(220, 38, 38, 0.95);
  transform: scale(1.1);
}

.btn-delete-photo:active {
  transform: scale(0.95);
}

.photo-label {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  background: rgba(0, 0, 0, 0.7);
  color: white;
  font-size: 0.75rem;
  font-weight: 600;
  padding: 0.5rem;
  text-align: center;
}

.btn-add-photo {
  aspect-ratio: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  background: #eff6ff;
  border: 2px dashed #3b82f6;
  border-radius: 0.5rem;
  color: #3b82f6;
  font-size: 0.875rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-add-photo svg {
  width: 32px;
  height: 32px;
  stroke-width: 2;
}

.btn-add-photo:hover {
  background: #dbeafe;
  border-color: #2563eb;
  color: #2563eb;
}

.btn-add-photo:active {
  transform: scale(0.98);
}

/* Photo Info */
.photo-info {
  text-align: center;
  font-size: 0.875rem;
  font-weight: 600;
  color: #6b7280;
  padding: 0.5rem;
}

.info-optional {
  color: #9ca3af;
  margin-left: 0.5rem;
}

/* Action Buttons */
.action-buttons {
  display: grid;
  grid-template-columns: 1fr 2fr;
  gap: 0.75rem;
  padding: 1rem;
  background: white;
  border-top: 1px solid #e5e7eb;
}

.btn-skip {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
  background: transparent;
  border: 2px solid #e5e7eb;
  border-radius: 0.5rem;
  color: #6b7280;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  min-height: 56px;
}

.btn-skip:hover {
  border-color: #d1d5db;
  background: #f9fafb;
}

.btn-skip:active {
  transform: scale(0.98);
}

.btn-continue {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  padding: 1rem 1.5rem;
  background: #3b82f6;
  border: none;
  border-radius: 0.5rem;
  color: white;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  min-height: 56px;
}

.btn-continue:hover:not(:disabled) {
  background: #2563eb;
  transform: translateY(-2px);
  box-shadow: 0 4px 6px rgba(59, 130, 246, 0.3);
}

.btn-continue:active:not(:disabled) {
  background: #1d4ed8;
  transform: translateY(0);
}

.btn-continue:disabled {
  background: #9ca3af;
  cursor: not-allowed;
}

.btn-continue svg {
  width: 20px;
  height: 20px;
  stroke-width: 2.5;
}

/* Camera Modal */
.camera-modal {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 1000;
  background: #000;
}

.camera-container {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
}

.camera-video {
  flex: 1;
  width: 100%;
  object-fit: cover;
}

.camera-controls {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 2rem 1.5rem;
  background: rgba(0, 0, 0, 0.8);
}

.btn-camera-cancel,
.btn-camera-switch {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.25rem;
  background: transparent;
  border: none;
  color: white;
  font-size: 0.75rem;
  font-weight: 600;
  cursor: pointer;
  padding: 0.5rem;
  min-width: 64px;
}

.btn-camera-cancel svg,
.btn-camera-switch svg {
  width: 28px;
  height: 28px;
  stroke-width: 2;
}

.btn-camera-cancel:active,
.btn-camera-switch:active {
  transform: scale(0.95);
}

.btn-camera-capture {
  background: transparent;
  border: none;
  cursor: pointer;
  padding: 0;
}

.btn-camera-capture:active {
  transform: scale(0.95);
}

.capture-ring {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  border: 4px solid white;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 4px;
}

.capture-button {
  width: 100%;
  height: 100%;
  background: white;
  border-radius: 50%;
}

/* Alert Error */
.alert-error {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1rem;
  margin: 0 1rem;
  background: #fef2f2;
  border: 1px solid #fecaca;
  border-radius: 0.375rem;
  color: #dc2626;
  font-size: 0.875rem;
}

.alert-error svg {
  width: 20px;
  height: 20px;
  flex-shrink: 0;
  stroke-width: 2;
}

/* Mobile Optimization */
@media (max-width: 640px) {
  .photos-header {
    padding: 0.75rem;
  }

  .photos-heading {
    font-size: 1rem;
  }

  .instructions {
    padding: 1.5rem 1rem 1rem;
  }

  .instruction-icon {
    width: 56px;
    height: 56px;
  }

  .instruction-icon svg {
    width: 28px;
    height: 28px;
  }

  .instruction-text {
    font-size: 1rem;
  }

  .photo-grid {
    grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
    gap: 0.75rem;
  }

  .btn-delete-photo {
    width: 28px;
    height: 28px;
    top: 0.375rem;
    right: 0.375rem;
  }

  .btn-delete-photo svg {
    width: 16px;
    height: 16px;
  }

  .btn-add-photo svg {
    width: 28px;
    height: 28px;
  }

  .action-buttons {
    padding: 0.75rem;
  }

  .btn-skip,
  .btn-continue {
    font-size: 0.9375rem;
    min-height: 52px;
  }

  .camera-controls {
    padding: 1.5rem 1rem;
  }

  .btn-camera-cancel,
  .btn-camera-switch {
    min-width: 56px;
  }

  .btn-camera-cancel svg,
  .btn-camera-switch svg {
    width: 24px;
    height: 24px;
  }

  .capture-ring {
    width: 72px;
    height: 72px;
  }
}

/* Touch target assurance */
@media (pointer: coarse) {
  .btn-back {
    min-width: 44px;
    min-height: 44px;
  }

  .btn-delete-photo {
    min-width: 44px;
    min-height: 44px;
  }

  .btn-skip,
  .btn-continue {
    min-height: 56px;
  }

  .btn-camera-cancel,
  .btn-camera-switch {
    min-width: 64px;
    min-height: 64px;
  }

  .btn-camera-capture {
    min-width: 80px;
    min-height: 80px;
  }
}
</style>
