<template>
  <div class="scan-extinguisher">
    <!-- Header -->
    <div class="scan-header">
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
        class="scan-heading"
        data-testid="page-heading"
      >
        Scan Extinguisher
      </h1>
      <div class="header-spacer" />
    </div>

    <!-- Instructions -->
    <div
      v-if="!scannedExtinguisher"
      class="instructions"
    >
      <div class="instruction-icon">
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
        >
          <path d="M9 3v18M15 3v18M3 9h18M3 15h18" />
        </svg>
      </div>
      <p class="instruction-text">
        Scan the extinguisher barcode
      </p>
      <p class="instruction-subtext">
        Position the barcode within the frame
      </p>
    </div>

    <!-- Scanner Component -->
    <div
      v-if="!scannedExtinguisher"
      class="scanner-container"
    >
      <BarcodeScannerComponent
        data-testid="barcode-scanner"
        @scan-success="handleScanSuccess"
        @scan-error="handleScanError"
      />
    </div>

    <!-- Scanned Extinguisher Info -->
    <div
      v-if="scannedExtinguisher"
      class="extinguisher-info"
      data-testid="extinguisher-info"
    >
      <!-- Success Icon -->
      <div class="success-icon">
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
        >
          <path d="M22 11.08V12a10 10 0 11-5.93-9.14" />
          <polyline points="22 4 12 14.01 9 11.01" />
        </svg>
      </div>

      <!-- Extinguisher Details -->
      <div class="info-card">
        <h2 class="info-heading">
          Extinguisher Details
        </h2>
        <div class="info-row">
          <span class="info-label">Type:</span>
          <span
            class="info-value"
            data-testid="extinguisher-type"
          >{{ scannedExtinguisher.type || 'N/A' }}</span>
        </div>
        <div class="info-row">
          <span class="info-label">Serial Number:</span>
          <span
            class="info-value"
            data-testid="extinguisher-serial"
          >{{ scannedExtinguisher.serialNumber || 'N/A' }}</span>
        </div>
        <div class="info-row">
          <span class="info-label">Size:</span>
          <span
            class="info-value"
            data-testid="extinguisher-size"
          >{{ scannedExtinguisher.size || 'N/A' }}</span>
        </div>
        <div class="info-row">
          <span class="info-label">Last Service:</span>
          <span
            class="info-value"
            data-testid="extinguisher-last-service"
          >{{ formatDate(scannedExtinguisher.lastServiceDate) }}</span>
        </div>
      </div>

      <!-- Status Badge -->
      <div
        class="status-badge"
        :class="{
          'status-badge-pass': scannedExtinguisher.status === 'InService',
          'status-badge-warning': scannedExtinguisher.status === 'NeedsInspection',
          'status-badge-fail': scannedExtinguisher.status === 'OutOfService'
        }"
        data-testid="extinguisher-status"
      >
        <svg
          class="status-icon"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
        >
          <circle
            cx="12"
            cy="12"
            r="10"
          />
          <path
            v-if="scannedExtinguisher.status === 'InService'"
            d="M9 12l2 2 4-4"
          />
          <path
            v-else
            d="M12 8v4M12 16h.01"
          />
        </svg>
        <span>{{ getStatusLabel(scannedExtinguisher.status) }}</span>
      </div>

      <!-- Location Context -->
      <div
        v-if="currentLocation"
        class="info-card"
        data-testid="location-context"
      >
        <h2 class="info-heading">
          Location Context
        </h2>
        <div class="info-row">
          <span class="info-label">Location:</span>
          <span
            class="info-value"
            data-testid="context-location"
          >{{ currentLocation.name }}</span>
        </div>
        <div
          v-if="currentLocation.building"
          class="info-row"
        >
          <span class="info-label">Building:</span>
          <span
            class="info-value"
            data-testid="context-building"
          >{{ currentLocation.building }}</span>
        </div>
        <div
          v-if="currentLocation.floor"
          class="info-row"
        >
          <span class="info-label">Floor:</span>
          <span
            class="info-value"
            data-testid="context-floor"
          >{{ currentLocation.floor }}</span>
        </div>
      </div>

      <!-- Continue Button -->
      <button
        class="btn-continue"
        data-testid="continue-button"
        @click="handleContinue"
      >
        <span>Continue to Inspection Checklist</span>
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
        >
          <path d="M5 12h14M12 5l7 7-7 7" />
        </svg>
      </button>
    </div>

    <!-- Scan Error -->
    <div
      v-if="scanError"
      class="alert-error"
      data-testid="scan-error"
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
      <span>{{ scanError }}</span>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useInspectorStore } from '@/stores/useInspectorStore'
import BarcodeScannerComponent from '@/components/BarcodeScannerComponent.vue'

const router = useRouter()
const inspectorStore = useInspectorStore()

// State
const scannedExtinguisher = ref(null)
const scanError = ref('')

// Computed
const currentLocation = computed(() => inspectorStore.currentLocation)

/**
 * Handle successful barcode scan
 */
const handleScanSuccess = async (result) => {
  scanError.value = ''

  try {
    // Parse extinguisher data from barcode
    let extinguisherData

    if (result.format === 'QR_CODE') {
      // Try to parse as JSON for QR codes
      try {
        extinguisherData = JSON.parse(result.text)

        // Validate it's an extinguisher QR code
        if (extinguisherData.type !== 'extinguisher' || !extinguisherData.extinguisherId) {
          throw new Error('Invalid extinguisher QR code')
        }
      } catch (e) {
        throw new Error('Invalid QR code format. Please scan an extinguisher barcode.')
      }
    } else {
      // For other barcode formats, expect extinguisherId only
      // In production, this would call API to fetch extinguisher details
      extinguisherData = {
        type: 'extinguisher',
        extinguisherId: result.text,
        serialNumber: result.text,
        extinguisherType: 'ABC Dry Chemical',
        size: '10 lbs',
        status: 'InService',
        lastServiceDate: '2024-06-15'
      }
    }

    scannedExtinguisher.value = extinguisherData

    // Save to inspector store
    inspectorStore.setCurrentExtinguisher({
      ...extinguisherData,
      scannedAt: new Date().toISOString()
    })
  } catch (error) {
    scanError.value = error.message
    scannedExtinguisher.value = null
  }
}

/**
 * Handle scan error
 */
const handleScanError = (error) => {
  scanError.value = error.message || 'Failed to scan barcode'
}

/**
 * Format date for display
 */
const formatDate = (dateString) => {
  if (!dateString) return 'N/A'

  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
}

/**
 * Get status label for display
 */
const getStatusLabel = (status) => {
  const labels = {
    InService: 'In Service',
    NeedsInspection: 'Needs Inspection',
    OutOfService: 'Out of Service'
  }
  return labels[status] || status
}

/**
 * Handle back button
 */
const handleBack = () => {
  router.push('/inspector/scan-location')
}

/**
 * Handle continue button
 */
const handleContinue = () => {
  if (!scannedExtinguisher.value) {
    scanError.value = 'Please scan an extinguisher first'
    return
  }

  // Navigate to inspection checklist
  // TODO: Implement inspection checklist view
  router.push('/inspector/inspection-checklist')
}
</script>

<style scoped>
/* Container */
.scan-extinguisher {
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

/* Scanner Container */
.scanner-container {
  flex: 1;
  padding: 1rem;
  background: #f9fafb;
}

/* Extinguisher Info */
.extinguisher-info {
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

/* Status Badge */
.status-badge {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 1rem 1.5rem;
  border-radius: 0.5rem;
  font-size: 1rem;
  font-weight: 600;
}

.status-badge-pass {
  background: #d1fae5;
  color: #065f46;
}

.status-badge-warning {
  background: #fef3c7;
  color: #92400e;
}

.status-badge-fail {
  background: #fee2e2;
  color: #991b1b;
}

.status-icon {
  width: 24px;
  height: 24px;
  stroke-width: 2.5;
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

.btn-continue:hover {
  background: #2563eb;
  transform: translateY(-2px);
  box-shadow: 0 4px 6px rgba(59, 130, 246, 0.3);
}

.btn-continue:active {
  background: #1d4ed8;
  transform: translateY(0);
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

  .status-badge {
    padding: 0.875rem 1.25rem;
    font-size: 0.875rem;
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
