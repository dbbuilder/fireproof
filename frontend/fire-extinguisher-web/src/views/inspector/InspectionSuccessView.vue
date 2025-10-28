<template>
  <div class="inspection-success">
    <!-- Success Icon -->
    <div class="success-icon" data-testid="success-icon">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
        <path d="M22 11.08V12a10 10 0 11-5.93-9.14"/>
        <polyline points="22 4 12 14.01 9 11.01"/>
      </svg>
    </div>

    <!-- Success Message -->
    <h1 class="success-heading" data-testid="success-heading">Inspection Submitted!</h1>
    <p class="success-message" data-testid="success-message">
      {{ message || 'Your inspection has been saved and will sync when online.' }}
    </p>

    <!-- Info Card -->
    <div class="info-card" data-testid="info-card">
      <div class="info-row">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path d="M9 11l3 3L22 4"/>
          <path d="M21 12v7a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h11"/>
        </svg>
        <span>Inspection data saved locally</span>
      </div>
      <div v-if="!isOnline" class="info-row warning">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <circle cx="12" cy="12" r="10"/>
          <line x1="12" y1="8" x2="12" y2="12"/>
          <line x1="12" y1="16" x2="12.01" y2="16"/>
        </svg>
        <span>Will sync automatically when online</span>
      </div>
      <div v-else class="info-row">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07 19.5 19.5 0 01-6-6 19.79 19.79 0 01-3.07-8.67A2 2 0 014.11 2h3a2 2 0 012 1.72 12.84 12.84 0 00.7 2.81 2 2 0 01-.45 2.11L8.09 9.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45 12.84 12.84 0 002.81.7A2 2 0 0122 16.92z"/>
        </svg>
        <span>Syncing to server...</span>
      </div>
    </div>

    <!-- Actions -->
    <div class="actions">
      <button
        @click="handleNewInspection"
        class="btn-primary"
        data-testid="btn-new-inspection"
      >
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path d="M12 5v14M5 12h14"/>
        </svg>
        <span>Start New Inspection</span>
      </button>

      <button
        @click="handleDashboard"
        class="btn-secondary"
        data-testid="btn-dashboard"
      >
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <rect x="3" y="3" width="7" height="7"/>
          <rect x="14" y="3" width="7" height="7"/>
          <rect x="14" y="14" width="7" height="7"/>
          <rect x="3" y="14" width="7" height="7"/>
        </svg>
        <span>Back to Dashboard</span>
      </button>
    </div>

    <!-- Draft Queue Info -->
    <div v-if="draftCount > 0" class="draft-info" data-testid="draft-info">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
        <circle cx="12" cy="12" r="10"/>
        <polyline points="12 6 12 12 16 14"/>
      </svg>
      <span>{{ draftCount }} inspection{{ draftCount === 1 ? '' : 's' }} in offline queue</span>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useInspectorStore } from '@/stores/useInspectorStore'

const router = useRouter()
const route = useRoute()
const inspectorStore = useInspectorStore()

// Computed
const message = computed(() => route.params.message)
const isOnline = computed(() => inspectorStore.isOnline)
const draftCount = computed(() => inspectorStore.draftInspections.length)

/**
 * Handle new inspection button
 */
const handleNewInspection = () => {
  router.push('/inspector/scan-location')
}

/**
 * Handle dashboard button
 */
const handleDashboard = () => {
  router.push('/inspector/dashboard')
}

// Clear inspection context on mount
onMounted(() => {
  inspectorStore.clearInspectionContext()
})
</script>

<style scoped>
/* Container */
.inspection-success {
  max-width: 600px;
  margin: 0 auto;
  padding: 2rem 1rem;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
}

/* Success Icon */
.success-icon {
  width: 120px;
  height: 120px;
  margin-bottom: 2rem;
  background: #d1fae5;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #10b981;
}

.success-icon svg {
  width: 64px;
  height: 64px;
  stroke-width: 2.5;
}

/* Success Message */
.success-heading {
  font-size: 2rem;
  font-weight: 700;
  color: #111827;
  margin: 0 0 1rem 0;
}

.success-message {
  font-size: 1.125rem;
  color: #6b7280;
  margin: 0 0 2rem 0;
  line-height: 1.6;
}

/* Info Card */
.info-card {
  width: 100%;
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 0.5rem;
  padding: 1.5rem;
  margin-bottom: 2rem;
  text-align: left;
}

.info-row {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 0.75rem 0;
  color: #374151;
  font-size: 0.9375rem;
  font-weight: 500;
}

.info-row:not(:last-child) {
  border-bottom: 1px solid #f3f4f6;
}

.info-row svg {
  width: 24px;
  height: 24px;
  flex-shrink: 0;
  stroke-width: 2;
  color: #10b981;
}

.info-row.warning svg {
  color: #f59e0b;
}

/* Actions */
.actions {
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.btn-primary,
.btn-secondary {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  padding: 1.25rem 1.5rem;
  border: none;
  border-radius: 0.5rem;
  font-size: 1.125rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  min-height: 68px;
}

.btn-primary svg,
.btn-secondary svg {
  width: 24px;
  height: 24px;
  stroke-width: 2.5;
}

.btn-primary {
  background: #3b82f6;
  color: white;
}

.btn-primary:hover {
  background: #2563eb;
  transform: translateY(-2px);
  box-shadow: 0 4px 6px rgba(59, 130, 246, 0.3);
}

.btn-primary:active {
  background: #1d4ed8;
  transform: translateY(0);
}

.btn-secondary {
  background: transparent;
  color: #6b7280;
  border: 2px solid #e5e7eb;
}

.btn-secondary:hover {
  border-color: #d1d5db;
  background: #f9fafb;
}

.btn-secondary:active {
  transform: scale(0.98);
}

/* Draft Info */
.draft-info {
  margin-top: 2rem;
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1rem 1.5rem;
  background: #fef3c7;
  border: 1px solid #fbbf24;
  border-radius: 0.5rem;
  color: #92400e;
  font-size: 0.875rem;
  font-weight: 600;
}

.draft-info svg {
  width: 20px;
  height: 20px;
  flex-shrink: 0;
  stroke-width: 2;
}

/* Mobile Optimization */
@media (max-width: 640px) {
  .inspection-success {
    padding: 1.5rem 0.75rem;
  }

  .success-icon {
    width: 100px;
    height: 100px;
  }

  .success-icon svg {
    width: 56px;
    height: 56px;
  }

  .success-heading {
    font-size: 1.75rem;
  }

  .success-message {
    font-size: 1rem;
  }

  .info-card {
    padding: 1.25rem;
  }

  .info-row {
    font-size: 0.875rem;
  }

  .info-row svg {
    width: 20px;
    height: 20px;
  }

  .btn-primary,
  .btn-secondary {
    font-size: 1rem;
    padding: 1rem 1.25rem;
    min-height: 56px;
  }

  .btn-primary svg,
  .btn-secondary svg {
    width: 20px;
    height: 20px;
  }

  .draft-info {
    padding: 0.875rem 1.25rem;
    font-size: 0.8125rem;
  }
}

/* Touch target assurance */
@media (pointer: coarse) {
  .btn-primary,
  .btn-secondary {
    min-height: 68px;
  }
}
</style>
