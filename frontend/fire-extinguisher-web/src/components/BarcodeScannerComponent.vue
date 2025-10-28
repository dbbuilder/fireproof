<template>
  <div class="barcode-scanner">
    <!-- Scanner Viewport -->
    <div
      id="reader"
      class="scanner-viewport"
      :class="{ 'scanner-active': isScanning }"
    ></div>

    <!-- Format Badge (shows detected format) -->
    <transition name="fade">
      <div v-if="lastFormat" class="format-badge" data-testid="format-badge">
        {{ formatDisplayName(lastFormat) }}
      </div>
    </transition>

    <!-- Scanning Status -->
    <div class="scanning-status">
      <div v-if="isScanning && !lastScanSuccess" class="status-scanning">
        <div class="scanning-animation"></div>
        <p>{{ scanType === 'location' ? 'Scan Location QR Code' : 'Scan Extinguisher Barcode' }}</p>
      </div>
      <div v-if="lastScanSuccess" class="status-success" data-testid="scan-success">
        <svg class="icon-success" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <polyline points="20 6 9 17 4 12"></polyline>
        </svg>
        <p>Scan Successful!</p>
      </div>
      <div v-if="scanError" class="status-error" data-testid="scan-error">
        <svg class="icon-error" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <circle cx="12" cy="12" r="10"></circle>
          <line x1="15" y1="9" x2="9" y2="15"></line>
          <line x1="9" y1="9" x2="15" y2="15"></line>
        </svg>
        <p>{{ scanError }}</p>
      </div>
    </div>

    <!-- Manual Entry Fallback -->
    <div class="manual-entry" data-testid="manual-entry">
      <details>
        <summary class="manual-entry-toggle">Enter barcode manually</summary>
        <div class="manual-entry-content">
          <input
            v-model="manualCode"
            type="text"
            placeholder="Enter barcode code"
            class="manual-input"
            data-testid="manual-code-input"
            @keyup.enter="submitManualCode"
          />
          <select v-model="manualFormat" class="format-select" data-testid="manual-format-select">
            <option value="CODE_39">Code 39 (3 of 9)</option>
            <option value="CODE_128">Code 128</option>
            <option value="QR_CODE">QR Code</option>
            <option value="EAN_13">EAN-13</option>
            <option value="UPC_A">UPC-A</option>
            <option value="OTHER">Other</option>
          </select>
          <button
            @click="submitManualCode"
            class="btn-manual-submit"
            data-testid="manual-submit-button"
            :disabled="!manualCode"
          >
            Submit
          </button>
        </div>
      </details>
    </div>

    <!-- Help Text -->
    <div class="help-text">
      <p>Position the barcode within the frame. Scanner supports:</p>
      <ul>
        <li>QR Codes</li>
        <li>Code 39 (3 of 9)</li>
        <li>Code 128</li>
        <li>EAN/UPC barcodes</li>
      </ul>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { Html5Qrcode, Html5QrcodeSupportedFormats } from 'html5-qrcode'

const props = defineProps({
  scanType: {
    type: String,
    default: 'extinguisher', // 'location' | 'extinguisher'
    validator: (value) => ['location', 'extinguisher'].includes(value)
  },
  autoStart: {
    type: Boolean,
    default: true
  }
})

const emit = defineEmits(['scan-success', 'scan-error'])

// Scanner state
const scanner = ref(null)
const isScanning = ref(false)
const lastFormat = ref('')
const lastScanSuccess = ref(false)
const scanError = ref('')

// Manual entry state
const manualCode = ref('')
const manualFormat = ref('CODE_39')

/**
 * Format display names for UI
 */
const formatDisplayName = (format) => {
  const names = {
    'CODE_39': 'Code 39 (3 of 9)',
    'CODE_128': 'Code 128',
    'CODE_93': 'Code 93',
    'QR_CODE': 'QR Code',
    'EAN_13': 'EAN-13',
    'EAN_8': 'EAN-8',
    'UPC_A': 'UPC-A',
    'UPC_E': 'UPC-E',
    'CODABAR': 'Codabar',
    'ITF': 'ITF (Interleaved 2 of 5)',
    'DATA_MATRIX': 'Data Matrix',
    'PDF_417': 'PDF-417',
    'AZTEC': 'Aztec'
  }
  return names[format] || format
}

/**
 * Clean barcode data based on format
 */
const cleanBarcodeData = (code, format) => {
  // Remove Code 39 start/stop characters (*)
  if (format === 'CODE_39') {
    code = code.replace(/\*/g, '')
  }

  // Trim whitespace
  code = code.trim()

  // Convert to uppercase for consistency
  code = code.toUpperCase()

  return code
}

/**
 * Start the barcode scanner
 */
const startScanner = async () => {
  try {
    scanner.value = new Html5Qrcode("reader")
    isScanning.value = true
    scanError.value = ''

    await scanner.value.start(
      { facingMode: "environment" }, // Rear camera
      {
        fps: 10, // Frames per second
        qrbox: { width: 250, height: 250 }, // Scanning box
        // Enable ALL supported formats - auto-detection
        formatsToSupport: [
          Html5QrcodeSupportedFormats.QR_CODE,
          Html5QrcodeSupportedFormats.CODE_128,
          Html5QrcodeSupportedFormats.CODE_39,
          Html5QrcodeSupportedFormats.CODE_93,
          Html5QrcodeSupportedFormats.EAN_13,
          Html5QrcodeSupportedFormats.EAN_8,
          Html5QrcodeSupportedFormats.UPC_A,
          Html5QrcodeSupportedFormats.UPC_E,
          Html5QrcodeSupportedFormats.CODABAR,
          Html5QrcodeSupportedFormats.ITF,
        ]
      },
      (decodedText, decodedResult) => {
        // Success! Barcode detected and decoded
        handleScanSuccess(decodedText, decodedResult)
      },
      (errorMessage) => {
        // Scanning error (no barcode detected yet)
        // This fires continuously while scanning, don't show as error
      }
    )
  } catch (error) {
    console.error('Camera access error:', error)
    isScanning.value = false

    if (error.name === 'NotAllowedError') {
      scanError.value = 'Camera access denied. Please enable camera permissions.'
    } else if (error.name === 'NotFoundError') {
      scanError.value = 'No camera found on this device.'
    } else {
      scanError.value = 'Failed to start camera. Please try manual entry.'
    }

    emit('scan-error', { error: error.message, type: 'camera' })
  }
}

/**
 * Handle successful scan
 */
const handleScanSuccess = (decodedText, decodedResult) => {
  const format = decodedResult.result.format
  lastFormat.value = format

  // Clean barcode data
  let cleanedCode = cleanBarcodeData(decodedText, format)

  // Handle QR codes with JSON data
  if (format === 'QR_CODE') {
    try {
      const data = JSON.parse(decodedText)
      // Example: {"type":"extinguisher","id":"EXT-12345","tenant":"DEMO001"}
      if (data.id) {
        cleanedCode = data.id
      }
    } catch {
      // Plain text QR code, use as-is
    }
  }

  // Show success feedback
  lastScanSuccess.value = true

  // Haptic feedback (if supported)
  if (navigator.vibrate) {
    navigator.vibrate(200)
  }

  // Stop scanning
  stopScanner()

  // Emit success event
  emit('scan-success', {
    code: cleanedCode,
    rawCode: decodedText,
    format: format,
    manual: false
  })

  // Reset success indicator after 2 seconds
  setTimeout(() => {
    lastScanSuccess.value = false
    lastFormat.value = ''
  }, 2000)
}

/**
 * Stop the scanner
 */
const stopScanner = async () => {
  if (scanner.value && isScanning.value) {
    try {
      await scanner.value.stop()
      isScanning.value = false
    } catch (error) {
      console.error('Error stopping scanner:', error)
    }
  }
}

/**
 * Submit manual barcode entry
 */
const submitManualCode = () => {
  if (!manualCode.value) return

  const cleanedCode = cleanBarcodeData(manualCode.value, manualFormat.value)

  // Show success feedback
  lastScanSuccess.value = true
  lastFormat.value = manualFormat.value

  // Emit success event
  emit('scan-success', {
    code: cleanedCode,
    rawCode: manualCode.value,
    format: manualFormat.value,
    manual: true
  })

  // Reset
  manualCode.value = ''

  // Reset success indicator
  setTimeout(() => {
    lastScanSuccess.value = false
    lastFormat.value = ''
  }, 2000)
}

// Lifecycle hooks
onMounted(() => {
  if (props.autoStart) {
    startScanner()
  }
})

onUnmounted(() => {
  stopScanner()
})

// Expose methods for parent components
defineExpose({
  startScanner,
  stopScanner
})
</script>

<style scoped>
.barcode-scanner {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  width: 100%;
  max-width: 500px;
  margin: 0 auto;
}

.scanner-viewport {
  width: 100%;
  min-height: 300px;
  border-radius: 0.5rem;
  overflow: hidden;
  background: #000;
  position: relative;
}

.scanner-active {
  box-shadow: 0 0 0 3px #3b82f6;
}

.format-badge {
  position: absolute;
  top: 1rem;
  right: 1rem;
  background: rgba(59, 130, 246, 0.9);
  color: white;
  padding: 0.5rem 1rem;
  border-radius: 0.5rem;
  font-size: 0.875rem;
  font-weight: 600;
  z-index: 10;
}

.scanning-status {
  text-align: center;
  padding: 1rem;
}

.status-scanning {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
}

.scanning-animation {
  width: 40px;
  height: 40px;
  border: 3px solid #3b82f6;
  border-top-color: transparent;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.status-success {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  justify-content: center;
  color: #10b981;
  font-weight: 600;
}

.status-error {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  justify-content: center;
  color: #ef4444;
  font-weight: 600;
}

.icon-success,
.icon-error {
  width: 24px;
  height: 24px;
  stroke-width: 3;
}

.manual-entry {
  margin-top: 1rem;
}

.manual-entry-toggle {
  cursor: pointer;
  padding: 0.75rem;
  background: #f3f4f6;
  border-radius: 0.5rem;
  text-align: center;
  font-weight: 500;
  color: #6b7280;
}

.manual-entry-toggle:hover {
  background: #e5e7eb;
}

.manual-entry-content {
  margin-top: 1rem;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.manual-input {
  padding: 0.75rem;
  border: 2px solid #d1d5db;
  border-radius: 0.5rem;
  font-size: 1rem;
}

.manual-input:focus {
  outline: none;
  border-color: #3b82f6;
}

.format-select {
  padding: 0.75rem;
  border: 2px solid #d1d5db;
  border-radius: 0.5rem;
  font-size: 1rem;
  background: white;
}

.format-select:focus {
  outline: none;
  border-color: #3b82f6;
}

.btn-manual-submit {
  padding: 0.75rem 1.5rem;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 0.5rem;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-manual-submit:hover:not(:disabled) {
  background: #2563eb;
}

.btn-manual-submit:disabled {
  background: #9ca3af;
  cursor: not-allowed;
}

.help-text {
  padding: 1rem;
  background: #f9fafb;
  border-radius: 0.5rem;
  font-size: 0.875rem;
  color: #6b7280;
}

.help-text ul {
  margin: 0.5rem 0 0 1.5rem;
  padding: 0;
}

.help-text li {
  margin: 0.25rem 0;
}

/* Fade transition */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* Mobile optimizations */
@media (max-width: 768px) {
  .barcode-scanner {
    max-width: 100%;
  }

  .scanner-viewport {
    min-height: 250px;
  }

  .format-badge {
    font-size: 0.75rem;
    padding: 0.375rem 0.75rem;
  }

  .manual-input,
  .format-select,
  .btn-manual-submit {
    font-size: 16px; /* Prevent zoom on iOS */
  }

  /* Larger touch targets for mobile */
  .manual-entry-toggle,
  .btn-manual-submit {
    min-height: 44px; /* Apple HIG minimum */
  }
}
</style>
