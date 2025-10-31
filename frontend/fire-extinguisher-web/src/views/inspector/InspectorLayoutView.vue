<template>
  <div class="inspector-layout">
    <!-- Offline Banner -->
    <transition name="slide-down">
      <div
        v-if="!isOnline"
        class="offline-banner"
        data-testid="offline-banner"
      >
        <svg
          class="banner-icon"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
        >
          <path d="M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z" />
          <line
            x1="12"
            y1="9"
            x2="12"
            y2="13"
          />
          <line
            x1="12"
            y1="17"
            x2="12.01"
            y2="17"
          />
        </svg>
        <span>You're offline. Inspections will sync when online.</span>
        <span
          v-if="draftCount > 0"
          class="draft-count"
        >{{ draftCount }} in queue</span>
      </div>
    </transition>

    <!-- Header -->
    <header class="inspector-header">
      <div class="header-content">
        <div class="header-left">
          <h1
            class="header-title"
            data-testid="header-title"
          >
            FireProof Inspector
          </h1>
        </div>
        <div class="header-right">
          <!-- Inspector Name -->
          <span
            class="inspector-name"
            data-testid="inspector-name"
          >
            {{ user?.firstName || 'Inspector' }}
          </span>
          <!-- Logout Button -->
          <button
            class="btn-logout"
            data-testid="logout-button"
            @click="handleLogout"
          >
            <svg
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
            >
              <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4" />
              <polyline points="16 17 21 12 16 7" />
              <line
                x1="21"
                y1="12"
                x2="9"
                y2="12"
              />
            </svg>
            <span class="btn-text">Logout</span>
          </button>
        </div>
      </div>
    </header>

    <!-- Main Content -->
    <main class="inspector-main">
      <router-view v-slot="{ Component }">
        <transition
          name="fade"
          mode="out-in"
        >
          <component :is="Component" />
        </transition>
      </router-view>
    </main>
  </div>
</template>

<script setup>
import { computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useInspectorStore } from '@/stores/useInspectorStore'

const router = useRouter()
const inspectorStore = useInspectorStore()

// Computed
const user = computed(() => inspectorStore.user)
const isOnline = computed(() => inspectorStore.isOnline)
const draftCount = computed(() => inspectorStore.draftInspections.length)

/**
 * Handle logout
 */
const handleLogout = () => {
  if (confirm('Are you sure you want to logout?')) {
    inspectorStore.logout()
    router.push('/inspector/login')
  }
}

/**
 * Update online status
 */
const updateOnlineStatus = () => {
  inspectorStore.updateOnlineStatus(navigator.onLine)
}

// Listen for online/offline events
onMounted(() => {
  window.addEventListener('online', updateOnlineStatus)
  window.addEventListener('offline', updateOnlineStatus)
})

onUnmounted(() => {
  window.removeEventListener('online', updateOnlineStatus)
  window.removeEventListener('offline', updateOnlineStatus)
})
</script>

<style scoped>
/* Layout */
.inspector-layout {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background: #f9fafb;
}

/* Offline Banner */
.offline-banner {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  padding: 0.75rem 1rem;
  background: #fef3c7;
  border-bottom: 1px solid #fbbf24;
  color: #92400e;
  font-size: 0.875rem;
  font-weight: 500;
}

.banner-icon {
  width: 20px;
  height: 20px;
  flex-shrink: 0;
  stroke-width: 2;
}

.draft-count {
  margin-left: auto;
  padding: 0.25rem 0.75rem;
  background: #fbbf24;
  border-radius: 9999px;
  color: white;
  font-weight: 600;
  font-size: 0.75rem;
}

/* Header */
.inspector-header {
  background: white;
  border-bottom: 1px solid #e5e7eb;
  padding: 0.75rem 1rem;
}

.header-content {
  max-width: 1200px;
  margin: 0 auto;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.header-title {
  font-size: 1.125rem;
  font-weight: 700;
  color: #111827;
  margin: 0;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.inspector-name {
  font-size: 0.875rem;
  font-weight: 600;
  color: #374151;
}

.btn-logout {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  background: transparent;
  border: 1px solid #e5e7eb;
  border-radius: 0.375rem;
  color: #6b7280;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-logout svg {
  width: 18px;
  height: 18px;
  stroke-width: 2;
}

.btn-logout:hover {
  background: #f3f4f6;
  border-color: #d1d5db;
  color: #374151;
}

.btn-logout:active {
  transform: scale(0.98);
}

/* Main Content */
.inspector-main {
  flex: 1;
  padding: 1rem;
  max-width: 1200px;
  width: 100%;
  margin: 0 auto;
}

/* Transitions */
.slide-down-enter-active,
.slide-down-leave-active {
  transition: all 0.3s;
}

.slide-down-enter-from,
.slide-down-leave-to {
  transform: translateY(-100%);
  opacity: 0;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* Mobile Optimization */
@media (max-width: 640px) {
  .inspector-header {
    padding: 0.75rem;
  }

  .header-title {
    font-size: 1rem;
  }

  .inspector-name {
    display: none; /* Hide on mobile to save space */
  }

  .btn-text {
    display: none; /* Show icon only on mobile */
  }

  .btn-logout {
    padding: 0.5rem;
    min-width: 44px; /* Touch target */
    justify-content: center;
  }

  .inspector-main {
    padding: 0.75rem;
  }

  .offline-banner {
    flex-wrap: wrap;
    font-size: 0.8125rem;
  }

  .draft-count {
    margin-left: 0;
  }
}
</style>
