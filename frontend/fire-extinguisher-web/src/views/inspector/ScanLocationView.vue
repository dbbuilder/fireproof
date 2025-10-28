<template>
  <div class="scan-location">
    <!-- Header -->
    <div class="scan-header">
      <button @click="handleBack" class="btn-back" data-testid="back-button">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path d="M19 12H5M12 19l-7-7 7-7"/>
        </svg>
      </button>
      <h1 class="scan-heading" data-testid="page-heading">Scan Location</h1>
      <div class="header-spacer"></div>
    </div>

    <!-- Instructions -->
    <div v-if="!scannedLocation" class="instructions">
      <div class="instruction-icon">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
          <path d="M7 11V7a5 5 0 0110 0v4"/>
        </svg>
      </div>
      <p class="instruction-text">Scan the location QR code</p>
      <p class="instruction-subtext">Position the QR code within the frame</p>
    </div>

    <!-- Scanner Component -->
    <div v-if="!scannedLocation" class="scanner-container">
      <BarcodeScannerComponent
        @scan-success="handleScanSuccess"
        @scan-error="handleScanError"
        data-testid="barcode-scanner"
      />
    </div>

    <!-- Scanned Location Info -->
    <div v-if="scannedLocation" class="location-info" data-testid="location-info">
      <!-- Success Icon -->
      <div class="success-icon">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path d="M22 11.08V12a10 10 0 11-5.93-9.14"/>
          <polyline points="22 4 12 14.01 9 11.01"/>
        </svg>
      </div>

      <!-- Location Details -->
      <div class="info-card">
        <h2 class="info-heading">Location Scanned</h2>
        <div class="info-row">
          <span class="info-label">Name:</span>
          <span class="info-value" data-testid="location-name">{{ scannedLocation.name }}</span>
        </div>
        <div class="info-row">
          <span class="info-label">Building:</span>
          <span class="info-value" data-testid="location-building">{{ scannedLocation.building || 'N/A' }}</span>
        </div>
        <div class="info-row">
          <span class="info-label">Floor:</span>
          <span class="info-value" data-testid="location-floor">{{ scannedLocation.floor || 'N/A' }}</span>
        </div>
      </div>

      <!-- GPS Coordinates -->
      <div v-if="gpsCoordinates" class="info-card" data-testid="gps-info">
        <h2 class="info-heading">GPS Location</h2>
        <div class="info-row">
          <span class="info-label">Latitude:</span>
          <span class="info-value" data-testid="gps-latitude">{{ gpsCoordinates.latitude.toFixed(6) }}</span>
        </div>
        <div class="info-row">
          <span class="info-label">Longitude:</span>
          <span class="info-value" data-testid="gps-longitude">{{ gpsCoordinates.longitude.toFixed(6) }}</span>
        </div>
        <div class="info-row">
          <span class="info-label">Accuracy:</span>
          <span class="info-value" data-testid="gps-accuracy">± {{ gpsCoordinates.accuracy.toFixed(0) }}m</span>
        </div>
      </div>

      <!-- GPS Loading -->
      <div v-if="isCapturingGPS" class="gps-loading" data-testid="gps-loading">
        <svg class="loading-spinner" viewBox="0 0 24 24">
          <circle
            cx="12"
            cy="12"
            r="10"
            stroke="currentColor"
            stroke-width="4"
            fill="none"
            stroke-dasharray="32"
            stroke-dashoffset="32"
          />
        </svg>
        <span>Capturing GPS location...</span>
      </div>

      <!-- GPS Error -->
      <div v-if="gpsError" class="alert-error" data-testid="gps-error">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <circle cx="12" cy="12" r="10"/>
          <line x1="15" y1="9" x2="9" y2="15"/>
          <line x1="9" y1="9" x2="15" y2="15"/>
        </svg>
        <span>{{ gpsError }}</span>
      </div>

      <!-- Continue Button -->
      <button
        @click="handleContinue"
        class="btn-continue"
        data-testid="continue-button"
        :disabled="isCapturingGPS"
      >
        <span>Continue to Extinguisher Scan</span>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path d="M5 12h14M12 5l7 7-7 7"/>
        </svg>
      </button>
    </div>

    <!-- Scan Error -->
    <div v-if="scanError" class="alert-error" data-testid="scan-error">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
        <circle cx="12" cy="12" r="10"/>
        <line x1="15" y1="9" x2="9" y2="15"/>
        <line x1="9" y1="9" x2="15" y2="15"/>
      </svg>
      <span>{{ scanError }}</span>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useInspectorStore } from '@/stores/useInspectorStore'
import BarcodeScannerComponent from '@/components/BarcodeScannerComponent.vue'

const router = useRouter()
const inspectorStore = useInspectorStore()

// State
const scannedLocation = ref(null)
const gpsCoordinates = ref(null)
const isCapturingGPS = ref(false)
const gpsError = ref('')
const scanError = ref('')

/**
 * Handle successful barcode scan
 */
const handleScanSuccess = async (result) => {
  scanError.value = ''

  try {
    // Parse location data from QR code
    let locationData

    if (result.format === 'QR_CODE') {
      // Try to parse as JSON
      try {
        locationData = JSON.parse(result.text)

        // Validate it's a location QR code
        if (locationData.type !== 'location' || !locationData.locationId) {
          throw new Error('Invalid location QR code')
        }
      } catch (e) {
        throw new Error('Invalid QR code format. Please scan a location QR code.')
      }
    } else {
      // For other barcode formats, expect locationId only
      locationData = {
        type: 'location',
        locationId: result.text,
        name: `Location ${result.text}`,
        building: null,
        floor: null
      }
    }

    scannedLocation.value = locationData

    // Capture GPS coordinates
    await captureGPSLocation()

    // Save to inspector store
    inspectorStore.setCurrentLocation({
      ...locationData,
      gps: gpsCoordinates.value,
      scannedAt: new Date().toISOString()
    })
  } catch (error) {
    scanError.value = error.message
    scannedLocation.value = null
  }
}

/**
 * Handle scan error
 */
const handleScanError = (error) => {
  scanError.value = error.message || 'Failed to scan barcode'
}

/**
 * Capture GPS location
 */
const captureGPSLocation = async () => {
  isCapturingGPS.value = true
  gpsError.value = ''

  try {
    // Check if geolocation is available
    if (!navigator.geolocation) {
      throw new Error('GPS not supported on this device')
    }

    // Request GPS coordinates with high accuracy
    const position = await new Promise((resolve, reject) => {
      navigator.geolocation.getCurrentPosition(
        resolve,
        reject,
        {
          enableHighAccuracy: true,
          timeout: 10000, // 10 seconds
          maximumAge: 0 // No cached position
        }
      )
    })

    gpsCoordinates.value = {
      latitude: position.coords.latitude,
      longitude: position.coords.longitude,
      accuracy: position.coords.accuracy,
      timestamp: position.timestamp
    }
  } catch (error) {
    // Handle GPS errors
    let errorMessage = 'Failed to capture GPS location'

    if (error.code === 1) {
      errorMessage = 'GPS permission denied. Please allow location access.'
    } else if (error.code === 2) {
      errorMessage = 'GPS position unavailable. Please try again.'
    } else if (error.code === 3) {
      errorMessage = 'GPS timeout. Please try again.'
    }

    gpsError.value = errorMessage
    console.error('GPS Error:', error)
  } finally {
    isCapturingGPS.value = false
  }
}

/**
 * Handle back button
 */
const handleBack = () => {
  router.push('/inspector/dashboard')
}

/**
 * Handle continue button
 */
const handleContinue = () => {
  if (!scannedLocation.value) {
    scanError.value = 'Please scan a location first'
    return
  }

  router.push('/inspector/scan-extinguisher')
}

// Request GPS permission on mount (for iOS Safari)
onMounted(async () => {
  // Pre-request GPS permission for better UX
  if (navigator.geolocation) {
    try {
      await new Promise((resolve, reject) => {
        navigator.geolocation.getCurrentPosition(resolve, reject, {
          enableHighAccuracy: false,
          timeout: 5000,
          maximumAge: Infinity
        })
      })
    } catch (error) {
      // Ignore permission errors on mount
      console.log('GPS permission not granted yet')
    }
  }
})
</script>

<style scoped>
/* Container */
.scan-location {
  max-width: 600px;
  margin: 0 auto;
  padding: 0;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

/* Header */
.scan-header {
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

.scan-heading {
  font-size: 1.125rem;
  font-weight: 700;
  color: #111827;
  margin: 0;
}

.header-spacer {
  width: 44px; /* Balance the back button */
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

/* Scanner Container */
.scanner-container {
  flex: 1;
  padding: 1rem;
  background: #f9fafb;
}

/* Location Info */
.location-info {
  flex: 1;
  padding: 1rem;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.success-icon {
  width: 80px;
  height: 80px;
  margin: 1rem auto;
  background: #d1fae5;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #10b981;
}

.success-icon svg {
  width: 48px;
  height: 48px;
  stroke-width: 2.5;
}

.info-card {
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 0.5rem;
  padding: 1.25rem;
}

.info-heading {
  font-size: 1rem;
  font-weight: 700;
  color: #111827;
  margin: 0 0 1rem 0;
}

.info-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 0;
  border-bottom: 1px solid #f3f4f6;
}

.info-row:last-child {
  border-bottom: none;
}

.info-label {
  font-size: 0.875rem;
  font-weight: 600;
  color: #6b7280;
}

.info-value {
  font-size: 0.875rem;
  font-weight: 600;
  color: #111827;
  text-align: right;
}

/* GPS Loading */
.gps-loading {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  padding: 1rem;
  background: #eff6ff;
  border: 1px solid #bfdbfe;
  border-radius: 0.375rem;
  color: #1e40af;
  font-size: 0.875rem;
  font-weight: 500;
}

.loading-spinner {
  width: 20px;
  height: 20px;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
    stroke-dashoffset: 32;
  }
  to {
    transform: rotate(360deg);
    stroke-dashoffset: 0;
  }
}

/* Alert Error */
.alert-error {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1rem;
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

/* Continue Button */
.btn-continue {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  padding: 1.25rem 1.5rem;
  background: #3b82f6;
  border: none;
  border-radius: 0.5rem;
  color: white;
  font-size: 1.125rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  margin-top: auto;
  min-height: 68px;
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
  width: 24px;
  height: 24px;
  stroke-width: 2.5;
}

/* Mobile Optimization */
@media (max-width: 640px) {
  .scan-header {
    padding: 0.75rem;
  }

  .scan-heading {
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

  .success-icon {
    width: 64px;
    height: 64px;
  }

  .success-icon svg {
    width: 40px;
    height: 40px;
  }

  .info-card {
    padding: 1rem;
  }

  .info-row {
    padding: 0.625rem 0;
  }

  .btn-continue {
    font-size: 1rem;
    padding: 1rem 1.25rem;
    min-height: 56px;
  }
}

/* Touch target assurance */
@media (pointer: coarse) {
  .btn-back {
    min-width: 44px;
    min-height: 44px;
  }

  .btn-continue {
    min-height: 68px;
  }
}
</style>
