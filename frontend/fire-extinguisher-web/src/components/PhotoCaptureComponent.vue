<template>
  <div class="fixed inset-0 bg-black z-50 flex flex-col">
    <!-- Header -->
    <div class="bg-black bg-opacity-75 text-white px-4 py-3 flex items-center justify-between">
      <button
        class="flex items-center text-white hover:text-gray-300 transition-colors"
        @click="cancel"
      >
        <svg
          class="h-6 w-6 mr-1"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M6 18L18 6M6 6l12 12"
          />
        </svg>
        Cancel
      </button>
      <h2 class="text-lg font-medium">
        {{ photoType }}
      </h2>
      <div class="w-20" /> <!-- Spacer for center alignment -->
    </div>

    <!-- Camera View or Captured Photo -->
    <div class="flex-1 relative bg-black overflow-hidden">
      <!-- Live Camera Feed -->
      <video
        v-show="!capturedPhoto && !uploading"
        ref="videoElement"
        autoplay
        playsinline
        class="w-full h-full object-cover"
      />

      <!-- Captured Photo Preview -->
      <img
        v-if="capturedPhoto"
        :src="capturedPhoto"
        alt="Captured photo"
        class="w-full h-full object-contain"
      >

      <!-- Upload Progress Overlay -->
      <div
        v-if="uploading"
        class="absolute inset-0 flex items-center justify-center bg-black bg-opacity-75"
      >
        <div class="text-center">
          <svg
            class="animate-spin h-16 w-16 text-white mx-auto mb-4"
            fill="none"
            viewBox="0 0 24 24"
          >
            <circle
              class="opacity-25"
              cx="12"
              cy="12"
              r="10"
              stroke="currentColor"
              stroke-width="4"
            />
            <path
              class="opacity-75"
              fill="currentColor"
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
            />
          </svg>
          <p class="text-white text-lg font-medium">
            Uploading...
          </p>
          <p class="text-gray-300 text-sm mt-2">
            {{ uploadProgress }}%
          </p>
        </div>
      </div>

      <!-- Error Message -->
      <div
        v-if="error"
        class="absolute inset-x-4 top-4 bg-red-600 text-white px-4 py-3 rounded-lg shadow-lg"
      >
        <div class="flex items-start">
          <svg
            class="h-5 w-5 mr-2 flex-shrink-0 mt-0.5"
            fill="currentColor"
            viewBox="0 0 20 20"
          >
            <path
              fill-rule="evenodd"
              d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
              clip-rule="evenodd"
            />
          </svg>
          <div class="flex-1">
            <p class="font-medium">
              {{ error }}
            </p>
            <button
              v-if="error.includes('permission')"
              class="mt-2 text-sm underline hover:text-red-100"
              @click="requestPermissions"
            >
              Request Permission Again
            </button>
          </div>
        </div>
      </div>

      <!-- Camera Controls Overlay -->
      <div
        v-if="!capturedPhoto && !uploading"
        class="absolute inset-x-0 bottom-0 pb-8 px-4"
      >
        <div class="flex items-center justify-center space-x-8">
          <!-- Flash Toggle (if supported) -->
          <button
            v-if="hasFlash"
            class="w-14 h-14 rounded-full bg-black bg-opacity-50 text-white flex items-center justify-center hover:bg-opacity-75 transition-all"
            @click="toggleFlash"
          >
            <svg
              v-if="flashEnabled"
              class="h-7 w-7"
              fill="currentColor"
              viewBox="0 0 20 20"
            >
              <path
                fill-rule="evenodd"
                d="M11.3 1.046A1 1 0 0112 2v5h4a1 1 0 01.82 1.573l-7 10A1 1 0 018 18v-5H4a1 1 0 01-.82-1.573l7-10a1 1 0 011.12-.38z"
                clip-rule="evenodd"
              />
            </svg>
            <svg
              v-else
              class="h-7 w-7"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M13 10V3L4 14h7v7l9-11h-7z"
              />
            </svg>
          </button>

          <!-- Capture Button -->
          <button
            class="w-20 h-20 rounded-full bg-white border-4 border-gray-300 hover:border-primary-500 transition-all shadow-lg flex items-center justify-center"
            @click="capturePhoto"
          >
            <div class="w-16 h-16 rounded-full bg-white" />
          </button>

          <!-- Switch Camera -->
          <button
            class="w-14 h-14 rounded-full bg-black bg-opacity-50 text-white flex items-center justify-center hover:bg-opacity-75 transition-all"
            @click="switchCamera"
          >
            <svg
              class="h-7 w-7"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
              />
            </svg>
          </button>
        </div>
      </div>

      <!-- Captured Photo Actions -->
      <div
        v-if="capturedPhoto && !uploading"
        class="absolute inset-x-0 bottom-0 pb-8 px-4"
      >
        <div class="flex items-center justify-center space-x-4">
          <button
            class="flex-1 max-w-xs px-6 py-3 bg-gray-700 text-white rounded-lg font-medium hover:bg-gray-600 transition-colors shadow-lg"
            @click="retake"
          >
            Retake
          </button>
          <button
            class="flex-1 max-w-xs px-6 py-3 bg-primary-600 text-white rounded-lg font-medium hover:bg-primary-700 transition-colors shadow-lg"
            @click="usePhoto"
          >
            Use Photo
          </button>
        </div>
      </div>
    </div>

    <!-- Hidden Canvas for Photo Processing -->
    <canvas
      ref="canvasElement"
      style="display: none;"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { usePhotoStore } from '@/stores/photos'
import photoService from '@/services/photoService'

interface Props {
  inspectionId: string
  photoType: string
}

interface Emits {
  (e: 'photo-captured', photoId: string): void
  (e: 'cancel'): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

const photoStore = usePhotoStore()

// Refs
const videoElement = ref<HTMLVideoElement | null>(null)
const canvasElement = ref<HTMLCanvasElement | null>(null)
const mediaStream = ref<MediaStream | null>(null)
const capturedPhoto = ref<string | null>(null)
const uploading = ref(false)
const uploadProgress = ref(0)
const error = ref<string | null>(null)
const facingMode = ref<'user' | 'environment'>('environment') // Default to rear camera
const flashEnabled = ref(false)
const hasFlash = ref(false)

// Methods
const initializeCamera = async () => {
  error.value = null

  try {
    // Stop existing stream if any
    if (mediaStream.value) {
      mediaStream.value.getTracks().forEach(track => track.stop())
    }

    // Get camera constraints optimized for inspections
    const constraints: MediaStreamConstraints = {
      video: {
        facingMode: { ideal: facingMode.value },
        width: { ideal: 1920 },
        height: { ideal: 1080 },
        aspectRatio: { ideal: 16 / 9 }
      },
      audio: false
    }

    const stream = await navigator.mediaDevices.getUserMedia(constraints)
    mediaStream.value = stream

    if (videoElement.value) {
      videoElement.value.srcObject = stream
    }

    // Check if flash is supported
    const videoTrack = stream.getVideoTracks()[0]
    const capabilities = videoTrack.getCapabilities() as any
    hasFlash.value = capabilities.torch === true

  } catch (err: any) {
    if (err.name === 'NotAllowedError' || err.name === 'PermissionDeniedError') {
      error.value = 'Camera permission denied. Please enable camera access in your device settings.'
    } else if (err.name === 'NotFoundError' || err.name === 'DevicesNotFoundError') {
      error.value = 'No camera found on this device.'
    } else {
      error.value = `Failed to access camera: ${err.message}`
    }
    console.error('Camera initialization error:', err)
  }
}

const requestPermissions = async () => {
  await initializeCamera()
}

const switchCamera = async () => {
  facingMode.value = facingMode.value === 'user' ? 'environment' : 'user'
  await initializeCamera()
}

const toggleFlash = async () => {
  if (!mediaStream.value || !hasFlash.value) return

  try {
    const videoTrack = mediaStream.value.getVideoTracks()[0]
    await videoTrack.applyConstraints({
      advanced: [{ torch: !flashEnabled.value } as any]
    })
    flashEnabled.value = !flashEnabled.value
  } catch (err) {
    console.error('Failed to toggle flash:', err)
  }
}

const capturePhoto = () => {
  if (!videoElement.value || !canvasElement.value) {
    error.value = 'Camera not ready'
    return
  }

  error.value = null

  const video = videoElement.value
  const canvas = canvasElement.value

  // Set canvas dimensions to match video
  canvas.width = video.videoWidth
  canvas.height = video.videoHeight

  // Draw video frame to canvas
  const context = canvas.getContext('2d')
  if (!context) {
    error.value = 'Failed to get canvas context'
    return
  }

  context.drawImage(video, 0, 0, canvas.width, canvas.height)

  // Convert to data URL for preview
  capturedPhoto.value = canvas.toDataURL('image/jpeg', 0.9)

  // Stop camera stream to save battery
  if (mediaStream.value) {
    mediaStream.value.getTracks().forEach(track => track.stop())
    mediaStream.value = null
  }
}

const retake = async () => {
  capturedPhoto.value = null
  await initializeCamera()
}

const usePhoto = async () => {
  if (!capturedPhoto.value || !canvasElement.value) {
    error.value = 'No photo captured'
    return
  }

  uploading.value = true
  uploadProgress.value = 0
  error.value = null

  try {
    // Convert canvas to Blob
    const blob = await photoService.canvasToBlob(canvasElement.value!, 0.9)

    // Create File from Blob
    const file = new File([blob], `photo-${Date.now()}.jpg`, { type: 'image/jpeg' })

    // Simulate upload progress (for better UX)
    const progressInterval = setInterval(() => {
      uploadProgress.value = Math.min(uploadProgress.value + 10, 90)
    }, 200)

    // Upload photo
    const response = await photoStore.uploadPhoto(
      props.inspectionId,
      props.photoType,
      file,
      new Date().toISOString()
    )

    clearInterval(progressInterval)
    uploadProgress.value = 100

    // Wait a moment to show 100%
    setTimeout(() => {
      emit('photo-captured', response.photoId)
    }, 300)

  } catch (err: any) {
    error.value = err.response?.data?.message || 'Failed to upload photo'
    uploading.value = false
    console.error('Photo upload error:', err)
  }
}

const cancel = () => {
  if (mediaStream.value) {
    mediaStream.value.getTracks().forEach(track => track.stop())
    mediaStream.value = null
  }
  emit('cancel')
}

// Lifecycle
onMounted(() => {
  initializeCamera()
})

onUnmounted(() => {
  if (mediaStream.value) {
    mediaStream.value.getTracks().forEach(track => track.stop())
  }
})
</script>
