<template>
  <div class="inspection-checklist">
    <!-- Header -->
    <div class="checklist-header">
      <button @click="handleBack" class="btn-back" data-testid="back-button">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path d="M19 12H5M12 19l-7-7 7-7"/>
        </svg>
      </button>
      <h1 class="checklist-heading" data-testid="page-heading">Inspection Checklist</h1>
      <div class="header-spacer"></div>
    </div>

    <!-- Context Summary -->
    <div class="context-summary" data-testid="context-summary">
      <div class="context-row">
        <span class="context-label">Location:</span>
        <span class="context-value" data-testid="context-location">{{ currentLocation?.name || 'N/A' }}</span>
      </div>
      <div class="context-row">
        <span class="context-label">Extinguisher:</span>
        <span class="context-value" data-testid="context-extinguisher">{{ currentExtinguisher?.serialNumber || 'N/A' }}</span>
      </div>
    </div>

    <!-- Progress Indicator -->
    <div class="progress-section">
      <div class="progress-bar-container">
        <div class="progress-bar" :style="{ width: `${progressPercentage}%` }" data-testid="progress-bar"></div>
      </div>
      <div class="progress-text" data-testid="progress-text">
        {{ completedItems }} of {{ checklistItems.length }} completed
      </div>
    </div>

    <!-- Checklist Items -->
    <div class="checklist-items">
      <div
        v-for="(item, index) in checklistItems"
        :key="item.id"
        class="checklist-item"
        :class="{ 'checklist-item-completed': item.response !== null }"
        :data-testid="`checklist-item-${index}`"
      >
        <!-- Item Number & Description -->
        <div class="item-header">
          <div class="item-number">{{ index + 1 }}</div>
          <div class="item-description" :data-testid="`item-description-${index}`">
            {{ item.description }}
          </div>
        </div>

        <!-- Response Buttons -->
        <div class="item-responses">
          <button
            @click="handleResponse(item.id, 'pass')"
            class="btn-response btn-pass"
            :class="{ active: item.response === 'pass' }"
            :data-testid="`btn-pass-${index}`"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
              <path d="M20 6L9 17l-5-5"/>
            </svg>
            <span>Pass</span>
          </button>
          <button
            @click="handleResponse(item.id, 'fail')"
            class="btn-response btn-fail"
            :class="{ active: item.response === 'fail' }"
            :data-testid="`btn-fail-${index}`"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
              <line x1="18" y1="6" x2="6" y2="18"/>
              <line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
            <span>Fail</span>
          </button>
          <button
            @click="handleResponse(item.id, 'na')"
            class="btn-response btn-na"
            :class="{ active: item.response === 'na' }"
            :data-testid="`btn-na-${index}`"
          >
            <span>N/A</span>
          </button>
        </div>

        <!-- Notes (shown when fail or when notes exist) -->
        <div v-if="item.response === 'fail' || item.notes" class="item-notes">
          <textarea
            v-model="item.notes"
            placeholder="Add notes (required for failures)..."
            class="notes-input"
            :data-testid="`notes-input-${index}`"
            rows="2"
          ></textarea>
        </div>
      </div>
    </div>

    <!-- Overall Assessment -->
    <div class="overall-assessment" data-testid="overall-assessment">
      <h2 class="assessment-heading">Overall Assessment</h2>
      <div class="assessment-buttons">
        <button
          @click="overallPass = true"
          class="btn-assessment btn-assessment-pass"
          :class="{ active: overallPass === true }"
          data-testid="btn-overall-pass"
        >
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
            <path d="M22 11.08V12a10 10 0 11-5.93-9.14"/>
            <polyline points="22 4 12 14.01 9 11.01"/>
          </svg>
          <span>Pass Inspection</span>
        </button>
        <button
          @click="overallPass = false"
          class="btn-assessment btn-assessment-fail"
          :class="{ active: overallPass === false }"
          data-testid="btn-overall-fail"
        >
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
            <circle cx="12" cy="12" r="10"/>
            <line x1="15" y1="9" x2="9" y2="15"/>
            <line x1="9" y1="9" x2="15" y2="15"/>
          </svg>
          <span>Fail Inspection</span>
        </button>
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

    <!-- Continue Button -->
    <button
      @click="handleContinue"
      class="btn-continue"
      data-testid="continue-button"
    >
      <span>Continue to Photos</span>
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
        <path d="M5 12h14M12 5l7 7-7 7"/>
      </svg>
    </button>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useInspectorStore } from '@/stores/useInspectorStore'

const router = useRouter()
const inspectorStore = useInspectorStore()

// State
const checklistItems = ref([
  {
    id: 1,
    description: 'Extinguisher is accessible and visible (not blocked)',
    response: null,
    notes: ''
  },
  {
    id: 2,
    description: 'Operating instructions are legible and facing outward',
    response: null,
    notes: ''
  },
  {
    id: 3,
    description: 'Tamper seal is intact and unbroken',
    response: null,
    notes: ''
  },
  {
    id: 4,
    description: 'Pressure gauge shows proper pressure (green zone)',
    response: null,
    notes: ''
  },
  {
    id: 5,
    description: 'Inspection tag is present and current',
    response: null,
    notes: ''
  },
  {
    id: 6,
    description: 'No physical damage, corrosion, or leakage',
    response: null,
    notes: ''
  },
  {
    id: 7,
    description: 'Hose and nozzle are in good condition (if applicable)',
    response: null,
    notes: ''
  },
  {
    id: 8,
    description: 'Safety pin is intact and secure',
    response: null,
    notes: ''
  },
  {
    id: 9,
    description: 'Extinguisher is mounted properly on wall bracket',
    response: null,
    notes: ''
  },
  {
    id: 10,
    description: 'Signage is present and clearly visible',
    response: null,
    notes: ''
  }
])

const overallPass = ref(null)
const validationError = ref('')

// Computed
const currentLocation = computed(() => inspectorStore.currentLocation)
const currentExtinguisher = computed(() => inspectorStore.currentExtinguisher)

const completedItems = computed(() => {
  return checklistItems.value.filter(item => item.response !== null).length
})

const progressPercentage = computed(() => {
  if (checklistItems.value.length === 0) return 0
  return Math.round((completedItems.value / checklistItems.value.length) * 100)
})

/**
 * Handle checklist item response
 */
const handleResponse = (itemId, response) => {
  const item = checklistItems.value.find(i => i.id === itemId)
  if (item) {
    item.response = response

    // Clear notes if changing to pass or N/A
    if (response !== 'fail' && item.notes) {
      item.notes = ''
    }
  }

  validationError.value = ''
}

/**
 * Validate checklist before continuing
 */
const validateChecklist = () => {
  // Check if all items are answered
  const unansweredItems = checklistItems.value.filter(item => item.response === null)
  if (unansweredItems.length > 0) {
    validationError.value = `Please answer all checklist items (${unansweredItems.length} remaining)`
    return false
  }

  // Check if overall assessment is selected
  if (overallPass.value === null) {
    validationError.value = 'Please select overall inspection result (Pass or Fail)'
    return false
  }

  // Check if failed items have notes
  const failedItemsWithoutNotes = checklistItems.value.filter(
    item => item.response === 'fail' && !item.notes.trim()
  )
  if (failedItemsWithoutNotes.length > 0) {
    validationError.value = 'Please add notes for all failed items'
    return false
  }

  return true
}

/**
 * Handle back button
 */
const handleBack = () => {
  if (confirm('Are you sure? Your checklist progress will be lost.')) {
    router.push('/inspector/scan-extinguisher')
  }
}

/**
 * Handle continue button
 */
const handleContinue = () => {
  validationError.value = ''

  if (!validateChecklist()) {
    return
  }

  // Save checklist responses to inspector store
  const responses = checklistItems.value.map(item => ({
    checklistItemId: item.id,
    description: item.description,
    response: item.response,
    notes: item.notes
  }))

  inspectorStore.startInspection({
    overallPass: overallPass.value,
    checklistResponses: responses,
    startedAt: new Date().toISOString()
  })

  // Save individual checklist responses
  responses.forEach(response => {
    inspectorStore.addChecklistResponse(response)
  })

  // Navigate to photos
  // TODO: Implement photo capture view
  router.push('/inspector/inspection-photos')
}

// Check if inspection context exists
onMounted(() => {
  if (!currentLocation.value || !currentExtinguisher.value) {
    validationError.value = 'Missing inspection context. Please scan location and extinguisher first.'
    setTimeout(() => {
      router.push('/inspector/dashboard')
    }, 3000)
  }
})
</script>

<style scoped>
/* Container */
.inspection-checklist {
  max-width: 600px;
  margin: 0 auto;
  padding: 0 0 1rem 0;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

/* Header */
.checklist-header {
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

.checklist-heading {
  font-size: 1.125rem;
  font-weight: 700;
  color: #111827;
  margin: 0;
}

.header-spacer {
  width: 44px;
}

/* Context Summary */
.context-summary {
  background: #f9fafb;
  border-bottom: 1px solid #e5e7eb;
  padding: 0.75rem 1rem;
}

.context-row {
  display: flex;
  justify-content: space-between;
  padding: 0.25rem 0;
}

.context-label {
  font-size: 0.75rem;
  font-weight: 600;
  color: #6b7280;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.context-value {
  font-size: 0.75rem;
  font-weight: 600;
  color: #111827;
}

/* Progress Section */
.progress-section {
  padding: 1rem;
  background: white;
  border-bottom: 1px solid #e5e7eb;
}

.progress-bar-container {
  width: 100%;
  height: 8px;
  background: #e5e7eb;
  border-radius: 9999px;
  overflow: hidden;
  margin-bottom: 0.5rem;
}

.progress-bar {
  height: 100%;
  background: #3b82f6;
  transition: width 0.3s ease;
  border-radius: 9999px;
}

.progress-text {
  font-size: 0.875rem;
  font-weight: 600;
  color: #6b7280;
  text-align: center;
}

/* Checklist Items */
.checklist-items {
  padding: 1rem;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.checklist-item {
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 0.5rem;
  padding: 1rem;
  transition: all 0.2s;
}

.checklist-item-completed {
  border-color: #3b82f6;
  background: #eff6ff;
}

.item-header {
  display: flex;
  gap: 0.75rem;
  margin-bottom: 0.75rem;
}

.item-number {
  width: 32px;
  height: 32px;
  flex-shrink: 0;
  background: #3b82f6;
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.875rem;
  font-weight: 700;
}

.item-description {
  flex: 1;
  font-size: 0.9375rem;
  font-weight: 500;
  color: #111827;
  line-height: 1.5;
}

.item-responses {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 0.5rem;
  margin-bottom: 0.75rem;
}

.btn-response {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.25rem;
  padding: 0.75rem 0.5rem;
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 0.375rem;
  font-size: 0.875rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  min-height: 64px;
}

.btn-response svg {
  width: 20px;
  height: 20px;
  stroke-width: 2.5;
}

.btn-response:hover {
  border-color: #d1d5db;
  background: #f9fafb;
}

.btn-response:active {
  transform: scale(0.98);
}

.btn-pass.active {
  background: #d1fae5;
  border-color: #10b981;
  color: #065f46;
}

.btn-fail.active {
  background: #fee2e2;
  border-color: #ef4444;
  color: #991b1b;
}

.btn-na.active {
  background: #f3f4f6;
  border-color: #9ca3af;
  color: #374151;
}

.item-notes {
  margin-top: 0.75rem;
}

.notes-input {
  width: 100%;
  padding: 0.75rem;
  font-size: 0.875rem;
  border: 2px solid #e5e7eb;
  border-radius: 0.375rem;
  resize: vertical;
  font-family: inherit;
  transition: all 0.2s;
}

.notes-input:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.notes-input::placeholder {
  color: #9ca3af;
}

/* Overall Assessment */
.overall-assessment {
  padding: 1rem;
  background: white;
  border-top: 2px solid #e5e7eb;
}

.assessment-heading {
  font-size: 1rem;
  font-weight: 700;
  color: #111827;
  margin: 0 0 1rem 0;
  text-align: center;
}

.assessment-buttons {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0.75rem;
}

.btn-assessment {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 1.25rem 1rem;
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 0.5rem;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  min-height: 96px;
}

.btn-assessment svg {
  width: 32px;
  height: 32px;
  stroke-width: 2.5;
}

.btn-assessment:hover {
  border-color: #d1d5db;
  background: #f9fafb;
}

.btn-assessment:active {
  transform: scale(0.98);
}

.btn-assessment-pass.active {
  background: #d1fae5;
  border-color: #10b981;
  color: #065f46;
}

.btn-assessment-fail.active {
  background: #fee2e2;
  border-color: #ef4444;
  color: #991b1b;
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

/* Continue Button */
.btn-continue {
  width: calc(100% - 2rem);
  margin: 1rem 1rem 0 1rem;
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
  .checklist-header {
    padding: 0.75rem;
  }

  .checklist-heading {
    font-size: 1rem;
  }

  .context-summary {
    padding: 0.625rem 0.75rem;
  }

  .progress-section {
    padding: 0.75rem;
  }

  .checklist-items {
    padding: 0.75rem;
    gap: 0.75rem;
  }

  .checklist-item {
    padding: 0.875rem;
  }

  .item-number {
    width: 28px;
    height: 28px;
    font-size: 0.8125rem;
  }

  .item-description {
    font-size: 0.875rem;
  }

  .btn-response {
    padding: 0.625rem 0.375rem;
    font-size: 0.8125rem;
    min-height: 56px;
  }

  .btn-response svg {
    width: 18px;
    height: 18px;
  }

  .btn-assessment {
    padding: 1rem 0.75rem;
    font-size: 0.9375rem;
    min-height: 84px;
  }

  .btn-assessment svg {
    width: 28px;
    height: 28px;
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

  .btn-response {
    min-height: 64px;
  }

  .btn-assessment {
    min-height: 96px;
  }

  .btn-continue {
    min-height: 68px;
  }
}
</style>
