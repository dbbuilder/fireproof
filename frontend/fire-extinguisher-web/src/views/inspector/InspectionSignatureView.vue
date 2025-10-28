<template>
  <div class="inspection-signature">
    <!-- Header -->
    <div class="signature-header">
      <button @click="handleBack" class="btn-back" data-testid="back-button">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path d="M19 12H5M12 19l-7-7 7-7"/>
        </svg>
      </button>
      <h1 class="signature-heading" data-testid="page-heading">Sign & Submit</h1>
      <div class="header-spacer"></div>
    </div>

    <!-- Inspection Summary -->
    <div class="inspection-summary">
      <h2 class="summary-heading">Inspection Summary</h2>

      <!-- Location & Extinguisher -->
      <div class="summary-card">
        <div class="summary-row">
          <span class="summary-label">Location:</span>
          <span class="summary-value" data-testid="summary-location">{{ currentLocation?.name || 'N/A' }}</span>
        </div>
        <div class="summary-row">
          <span class="summary-label">Extinguisher:</span>
          <span class="summary-value" data-testid="summary-extinguisher">{{ currentExtinguisher?.serialNumber || 'N/A' }}</span>
        </div>
      </div>

      <!-- Inspection Result -->
      <div
        class="result-badge"
        :class="{
          'result-badge-pass': currentInspection?.overallPass === true,
          'result-badge-fail': currentInspection?.overallPass === false
        }"
        data-testid="result-badge"
      >
        <svg class="result-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path v-if="currentInspection?.overallPass === true" d="M22 11.08V12a10 10 0 11-5.93-9.14"/>
          <polyline v-if="currentInspection?.overallPass === true" points="22 4 12 14.01 9 11.01"/>
          <circle v-if="currentInspection?.overallPass === false" cx="12" cy="12" r="10"/>
          <line v-if="currentInspection?.overallPass === false" x1="15" y1="9" x2="9" y2="15"/>
          <line v-if="currentInspection?.overallPass === false" x1="9" y1="9" x2="15" y2="15"/>
        </svg>
        <span>{{ currentInspection?.overallPass ? 'Inspection Passed' : 'Inspection Failed' }}</span>
      </div>

      <!-- Checklist Summary -->
      <div class="summary-card">
        <h3 class="card-heading">Checklist Results</h3>
        <div class="checklist-stats">
          <div class="stat-item">
            <div class="stat-value pass" data-testid="pass-count">{{ passCount }}</div>
            <div class="stat-label">Passed</div>
          </div>
          <div class="stat-item">
            <div class="stat-value fail" data-testid="fail-count">{{ failCount }}</div>
            <div class="stat-label">Failed</div>
          </div>
          <div class="stat-item">
            <div class="stat-value na" data-testid="na-count">{{ naCount }}</div>
            <div class="stat-label">N/A</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Signature Section -->
    <div class="signature-section">
      <h2 class="section-heading">Inspector Signature</h2>
      <p class="section-description">Please sign below to certify this inspection</p>

      <SignaturePadComponent
        ref="signaturePadRef"
        @signature-updated="handleSignatureUpdate"
      />

      <!-- Inspector Info -->
      <div class="inspector-info" data-testid="inspector-info">
        <div class="info-row">
          <span class="info-label">Inspector:</span>
          <span class="info-value" data-testid="inspector-name">{{ user?.firstName }} {{ user?.lastName }}</span>
        </div>
        <div class="info-row">
          <span class="info-label">Date:</span>
          <span class="info-value" data-testid="inspection-date">{{ currentDate }}</span>
        </div>
        <div class="info-row">
          <span class="info-label">Time:</span>
          <span class="info-value" data-testid="inspection-time">{{ currentTime }}</span>
        </div>
      </div>
    </div>

    <!-- Validation Error -->
    <div v-if="validationError" class="alert-error" data-testid="validation-error">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
        <circle cx="12" cy="12" r="10"/>
        <line x1="15" y1="9" x2="9" y2="15"/>
        <line x1="9" y1="9" x2="15" y2="15"/>
      </svg>
      <span>{{ validationError }}</span>
    </div>

    <!-- Submit Button -->
    <button
      @click="handleSubmit"
      class="btn-submit"
      data-testid="btn-submit"
      :disabled="isSubmitting"
    >
      <svg v-if="!isSubmitting" viewBox="0 0 24 24" fill="none" stroke="currentColor">
        <path d="M22 11.08V12a10 10 0 11-5.93-9.14"/>
        <polyline points="22 4 12 14.01 9 11.01"/>
      </svg>
      <svg v-else class="loading-spinner" viewBox="0 0 24 24">
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
      <span>{{ isSubmitting ? 'Submitting...' : 'Submit Inspection' }}</span>
    </button>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useInspectorStore } from '@/stores/useInspectorStore'
import SignaturePadComponent from '@/components/SignaturePadComponent.vue'

const router = useRouter()
const inspectorStore = useInspectorStore()

// Refs
const signaturePadRef = ref(null)

// State
const signatureDataURL = ref(null)
const validationError = ref('')
const isSubmitting = ref(false)

// Computed
const user = computed(() => inspectorStore.user)
const currentLocation = computed(() => inspectorStore.currentLocation)
const currentExtinguisher = computed(() => inspectorStore.currentExtinguisher)
const currentInspection = computed(() => inspectorStore.currentInspection)
const checklistResponses = computed(() => inspectorStore.checklistResponses)

const passCount = computed(() => {
  return checklistResponses.value.filter(r => r.response === 'pass').length
})

const failCount = computed(() => {
  return checklistResponses.value.filter(r => r.response === 'fail').length
})

const naCount = computed(() => {
  return checklistResponses.value.filter(r => r.response === 'na').length
})

const currentDate = computed(() => {
  return new Date().toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
})

const currentTime = computed(() => {
  return new Date().toLocaleTimeString('en-US', {
    hour: '2-digit',
    minute: '2-digit'
  })
})

/**
 * Handle signature update
 */
const handleSignatureUpdate = (dataURL) => {
  signatureDataURL.value = dataURL
  validationError.value = ''
}

/**
 * Handle back button
 */
const handleBack = () => {
  if (confirm('Are you sure? Your signature will be lost.')) {
    router.push('/inspector/inspection-photos')
  }
}

/**
 * Validate inspection before submission
 */
const validateInspection = () => {
  // Check for signature
  if (!signatureDataURL.value) {
    validationError.value = 'Please sign the inspection before submitting'
    return false
  }

  // Check for inspection context
  if (!currentLocation.value || !currentExtinguisher.value || !currentInspection.value) {
    validationError.value = 'Missing inspection context. Please restart the inspection.'
    return false
  }

  // Check for checklist responses
  if (checklistResponses.value.length === 0) {
    validationError.value = 'No checklist responses found. Please complete the checklist.'
    return false
  }

  return true
}

/**
 * Handle submit button
 */
const handleSubmit = async () => {
  validationError.value = ''

  if (!validateInspection()) {
    return
  }

  isSubmitting.value = true

  try {
    // In production, this would submit to the API
    // For now, simulate network delay and save to offline queue
    await new Promise(resolve => setTimeout(resolve, 1500))

    // Create inspection data
    const inspectionData = {
      location: currentLocation.value,
      extinguisher: currentExtinguisher.value,
      inspection: {
        ...currentInspection.value,
        signature: signatureDataURL.value,
        signedBy: `${user.value?.firstName} ${user.value?.lastName}`,
        signedAt: new Date().toISOString(),
        completedAt: new Date().toISOString()
      },
      checklist: checklistResponses.value,
      photos: [], // TODO: Add photos from previous step
      inspector: {
        id: user.value?.userId,
        name: `${user.value?.firstName} ${user.value?.lastName}`,
        email: user.value?.email
      }
    }

    // Save to offline queue (will sync when online)
    inspectorStore.saveDraft()

    // Clear inspection context
    inspectorStore.clearInspectionContext()

    // Navigate to success screen
    router.push({
      name: 'inspector-inspection-success',
      params: { message: 'Inspection submitted successfully!' }
    })
  } catch (error) {
    console.error('Submission error:', error)
    validationError.value = error.message || 'Failed to submit inspection. Please try again.'
  } finally {
    isSubmitting.value = false
  }
}

// Check for inspection context on mount
onMounted(() => {
  if (!currentLocation.value || !currentExtinguisher.value || !currentInspection.value) {
    validationError.value = 'Missing inspection context. Redirecting to dashboard...'
    setTimeout(() => {
      router.push('/inspector/dashboard')
    }, 3000)
  }
})
</script>

<style scoped>
/* Container */
.inspection-signature {
  max-width: 600px;
  margin: 0 auto;
  padding: 0 0 1rem 0;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

/* Header */
.signature-header {
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

.signature-heading {
  font-size: 1.125rem;
  font-weight: 700;
  color: #111827;
  margin: 0;
}

.header-spacer {
  width: 44px;
}

/* Inspection Summary */
.inspection-summary {
  padding: 1rem;
  background: #f9fafb;
}

.summary-heading {
  font-size: 1rem;
  font-weight: 700;
  color: #111827;
  margin: 0 0 1rem 0;
}

.summary-card {
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 0.5rem;
  padding: 1rem;
  margin-bottom: 1rem;
}

.summary-row {
  display: flex;
  justify-content: space-between;
  padding: 0.5rem 0;
  border-bottom: 1px solid #f3f4f6;
}

.summary-row:last-child {
  border-bottom: none;
}

.summary-label {
  font-size: 0.875rem;
  font-weight: 600;
  color: #6b7280;
}

.summary-value {
  font-size: 0.875rem;
  font-weight: 600;
  color: #111827;
}

/* Result Badge */
.result-badge {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  padding: 1.25rem;
  border-radius: 0.5rem;
  font-size: 1.125rem;
  font-weight: 700;
  margin-bottom: 1rem;
}

.result-badge-pass {
  background: #d1fae5;
  color: #065f46;
}

.result-badge-fail {
  background: #fee2e2;
  color: #991b1b;
}

.result-icon {
  width: 32px;
  height: 32px;
  stroke-width: 2.5;
}

/* Card Heading */
.card-heading {
  font-size: 0.875rem;
  font-weight: 700;
  color: #111827;
  margin: 0 0 1rem 0;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

/* Checklist Stats */
.checklist-stats {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1rem;
}

.stat-item {
  text-align: center;
}

.stat-value {
  font-size: 2rem;
  font-weight: 700;
  line-height: 1;
  margin-bottom: 0.5rem;
}

.stat-value.pass {
  color: #10b981;
}

.stat-value.fail {
  color: #ef4444;
}

.stat-value.na {
  color: #9ca3af;
}

.stat-label {
  font-size: 0.75rem;
  font-weight: 600;
  color: #6b7280;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

/* Signature Section */
.signature-section {
  padding: 1rem;
  flex: 1;
}

.section-heading {
  font-size: 1rem;
  font-weight: 700;
  color: #111827;
  margin: 0 0 0.5rem 0;
}

.section-description {
  font-size: 0.875rem;
  color: #6b7280;
  margin: 0 0 1rem 0;
}

/* Inspector Info */
.inspector-info {
  margin-top: 1rem;
  padding: 1rem;
  background: #f9fafb;
  border-radius: 0.375rem;
}

.info-row {
  display: flex;
  justify-content: space-between;
  padding: 0.5rem 0;
  border-bottom: 1px solid #e5e7eb;
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

/* Submit Button */
.btn-submit {
  width: calc(100% - 2rem);
  margin: 1rem 1rem 0 1rem;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  padding: 1.25rem 1.5rem;
  background: #10b981;
  border: none;
  border-radius: 0.5rem;
  color: white;
  font-size: 1.125rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  min-height: 68px;
}

.btn-submit svg {
  width: 24px;
  height: 24px;
  stroke-width: 2.5;
}

.btn-submit:hover:not(:disabled) {
  background: #059669;
  transform: translateY(-2px);
  box-shadow: 0 4px 6px rgba(16, 185, 129, 0.3);
}

.btn-submit:active:not(:disabled) {
  background: #047857;
  transform: translateY(0);
}

.btn-submit:disabled {
  background: #9ca3af;
  cursor: not-allowed;
}

.loading-spinner {
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

/* Mobile Optimization */
@media (max-width: 640px) {
  .signature-header {
    padding: 0.75rem;
  }

  .signature-heading {
    font-size: 1rem;
  }

  .inspection-summary {
    padding: 0.75rem;
  }

  .summary-heading {
    font-size: 0.9375rem;
  }

  .summary-card {
    padding: 0.875rem;
  }

  .result-badge {
    padding: 1rem;
    font-size: 1rem;
  }

  .result-icon {
    width: 28px;
    height: 28px;
  }

  .checklist-stats {
    gap: 0.75rem;
  }

  .stat-value {
    font-size: 1.75rem;
  }

  .signature-section {
    padding: 0.75rem;
  }

  .btn-submit {
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

  .btn-submit {
    min-height: 68px;
  }
}
</style>
