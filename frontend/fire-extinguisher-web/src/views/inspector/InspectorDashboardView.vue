<template>
  <div class="inspector-dashboard">
    <!-- Welcome Section -->
    <div class="welcome-section">
      <h1 class="welcome-heading" data-testid="dashboard-heading">
        Welcome, {{ user?.firstName || 'Inspector' }}
      </h1>
      <p class="welcome-subtitle">Ready to start your next inspection</p>
    </div>

    <!-- Stats Cards -->
    <div class="stats-grid" data-testid="stats-cards">
      <!-- Completed Today -->
      <div class="stat-card" data-testid="stat-card-completed">
        <div class="stat-icon">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
            <path d="M9 11l3 3L22 4"/>
            <path d="M21 12v7a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h11"/>
          </svg>
        </div>
        <div class="stat-content">
          <div class="stat-value" data-testid="completed-count">{{ completedToday }}</div>
          <div class="stat-label">Completed Today</div>
        </div>
      </div>

      <!-- Offline Queue -->
      <div
        class="stat-card"
        :class="{ 'stat-card-warning': draftCount > 0 }"
        data-testid="stat-card-offline"
      >
        <div class="stat-icon">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
            <path d="M12 2v20M17 5H9.5a3.5 3.5 0 000 7h5a3.5 3.5 0 010 7H6"/>
          </svg>
        </div>
        <div class="stat-content">
          <div class="stat-value" data-testid="offline-queue-count">{{ draftCount }}</div>
          <div class="stat-label">In Offline Queue</div>
        </div>
      </div>
    </div>

    <!-- Start Inspection Button -->
    <div class="action-section">
      <button
        @click="handleStartInspection"
        class="btn-start-inspection"
        data-testid="start-inspection-button"
      >
        <svg class="btn-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path d="M9 3v18M15 3v18M3 9h18M3 15h18"/>
        </svg>
        <span class="btn-text">Start Inspection</span>
        <svg class="btn-arrow" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path d="M5 12h14M12 5l7 7-7 7"/>
        </svg>
      </button>
    </div>

    <!-- Quick Info -->
    <div class="info-section">
      <div class="info-card">
        <h2 class="info-heading">Quick Guide</h2>
        <ol class="info-list">
          <li>Scan location QR code</li>
          <li>Scan extinguisher barcode</li>
          <li>Complete inspection checklist</li>
          <li>Add photos (if needed)</li>
          <li>Sign and submit</li>
        </ol>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useInspectorStore } from '@/stores/useInspectorStore'

const router = useRouter()
const inspectorStore = useInspectorStore()

// State
const completedToday = ref(0)

// Computed
const user = computed(() => inspectorStore.user)
const draftCount = computed(() => inspectorStore.draftInspections.length)

/**
 * Handle start inspection button click
 */
const handleStartInspection = () => {
  // Clear any previous inspection context
  inspectorStore.clearInspectionContext()

  // Navigate to scan location
  router.push('/inspector/scan-location')
}

/**
 * Fetch today's completed inspections count
 */
const fetchCompletedToday = async () => {
  try {
    // TODO: Implement API call to get today's count
    // const response = await api.get('/api/inspections/today-count')
    // completedToday.value = response.data.count

    // Placeholder for now
    completedToday.value = 0
  } catch (error) {
    console.error('Failed to fetch completed count:', error)
  }
}

// Load data on mount
onMounted(() => {
  fetchCompletedToday()
})
</script>

<style scoped>
/* Container */
.inspector-dashboard {
  max-width: 600px;
  margin: 0 auto;
  padding: 1rem;
}

/* Welcome Section */
.welcome-section {
  margin-bottom: 2rem;
  text-align: center;
}

.welcome-heading {
  font-size: 1.75rem;
  font-weight: 700;
  color: #111827;
  margin: 0 0 0.5rem 0;
}

.welcome-subtitle {
  font-size: 1rem;
  color: #6b7280;
  margin: 0;
}

/* Stats Grid */
.stats-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
  margin-bottom: 2rem;
}

.stat-card {
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 0.5rem;
  padding: 1.25rem;
  display: flex;
  gap: 1rem;
  transition: all 0.2s;
}

.stat-card-warning {
  border-color: #fbbf24;
  background: #fef3c7;
}

.stat-icon {
  width: 48px;
  height: 48px;
  flex-shrink: 0;
  background: #eff6ff;
  border-radius: 0.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #3b82f6;
}

.stat-card-warning .stat-icon {
  background: #fef3c7;
  color: #f59e0b;
}

.stat-icon svg {
  width: 24px;
  height: 24px;
  stroke-width: 2;
}

.stat-content {
  flex: 1;
}

.stat-value {
  font-size: 2rem;
  font-weight: 700;
  color: #111827;
  line-height: 1;
  margin-bottom: 0.25rem;
}

.stat-label {
  font-size: 0.75rem;
  color: #6b7280;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

/* Action Section */
.action-section {
  margin-bottom: 2rem;
}

.btn-start-inspection {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  padding: 1.5rem 2rem;
  background: #3b82f6;
  border: none;
  border-radius: 0.75rem;
  color: white;
  font-size: 1.25rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s;
  box-shadow: 0 4px 6px rgba(59, 130, 246, 0.2);
  min-height: 80px;
}

.btn-start-inspection:hover {
  background: #2563eb;
  box-shadow: 0 6px 8px rgba(59, 130, 246, 0.3);
  transform: translateY(-2px);
}

.btn-start-inspection:active {
  background: #1d4ed8;
  transform: translateY(0);
  box-shadow: 0 2px 4px rgba(59, 130, 246, 0.2);
}

.btn-icon {
  width: 32px;
  height: 32px;
  stroke-width: 2;
}

.btn-text {
  flex: 1;
  text-align: center;
}

.btn-arrow {
  width: 24px;
  height: 24px;
  stroke-width: 2.5;
}

/* Info Section */
.info-section {
  margin-bottom: 1rem;
}

.info-card {
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 0.5rem;
  padding: 1.5rem;
}

.info-heading {
  font-size: 1rem;
  font-weight: 700;
  color: #111827;
  margin: 0 0 1rem 0;
}

.info-list {
  margin: 0;
  padding-left: 1.25rem;
  list-style: decimal;
}

.info-list li {
  font-size: 0.875rem;
  color: #374151;
  line-height: 1.75;
  margin-bottom: 0.5rem;
}

.info-list li:last-child {
  margin-bottom: 0;
}

/* Mobile Optimization */
@media (max-width: 640px) {
  .inspector-dashboard {
    padding: 0.75rem;
  }

  .welcome-heading {
    font-size: 1.5rem;
  }

  .welcome-subtitle {
    font-size: 0.875rem;
  }

  .stats-grid {
    gap: 0.75rem;
  }

  .stat-card {
    padding: 1rem;
  }

  .stat-icon {
    width: 40px;
    height: 40px;
  }

  .stat-icon svg {
    width: 20px;
    height: 20px;
  }

  .stat-value {
    font-size: 1.75rem;
  }

  .stat-label {
    font-size: 0.625rem;
  }

  .btn-start-inspection {
    padding: 1.25rem 1.5rem;
    font-size: 1.125rem;
    min-height: 68px;
  }

  .btn-icon {
    width: 28px;
    height: 28px;
  }

  .btn-arrow {
    width: 20px;
    height: 20px;
  }

  .info-card {
    padding: 1.25rem;
  }

  .info-list li {
    font-size: 0.8125rem;
  }
}

/* Tablet */
@media (max-width: 768px) and (min-width: 641px) {
  .inspector-dashboard {
    padding: 1.5rem;
  }
}

/* Touch target assurance */
@media (pointer: coarse) {
  .btn-start-inspection {
    min-height: 88px; /* Extra large for primary action */
  }
}
</style>
