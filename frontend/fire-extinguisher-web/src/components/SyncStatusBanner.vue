<template>
  <div
    v-if="shouldShow"
    class="fixed top-0 left-0 right-0 z-50 animate-slide-down"
  >
    <!-- Offline Banner -->
    <div
      v-if="!status.online"
      class="bg-gray-800 text-white px-4 py-3 shadow-lg"
    >
      <div class="max-w-7xl mx-auto flex items-center justify-between">
        <div class="flex items-center">
          <svg
            class="h-5 w-5 text-gray-400 mr-2"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M18.364 5.636a9 9 0 010 12.728m0 0l-2.829-2.829m2.829 2.829L21 21M15.536 8.464a5 5 0 010 7.072m0 0l-2.829-2.829m-4.243 2.829a4.978 4.978 0 01-1.414-2.83m-1.414 5.658a9 9 0 01-2.167-9.238m7.824 2.167a1 1 0 111.414 1.414m-1.414-1.414L3 3m8.293 8.293l1.414 1.414"
            />
          </svg>
          <div>
            <p class="text-sm font-medium">
              Working Offline
            </p>
            <p
              v-if="hasPending"
              class="text-xs text-gray-300 mt-0.5"
            >
              {{ status.pendingOperations + status.pendingPhotos }} items will sync when online
            </p>
          </div>
        </div>
        <button
          class="text-gray-400 hover:text-white"
          @click="dismiss"
        >
          <svg
            class="h-5 w-5"
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
        </button>
      </div>
    </div>

    <!-- Syncing Banner -->
    <div
      v-else-if="status.syncing"
      class="bg-blue-600 text-white px-4 py-3 shadow-lg"
    >
      <div class="max-w-7xl mx-auto flex items-center justify-between">
        <div class="flex items-center">
          <svg
            class="animate-spin h-5 w-5 text-white mr-2"
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
          <div>
            <p class="text-sm font-medium">
              Syncing...
            </p>
            <p
              v-if="hasPending"
              class="text-xs text-blue-100 mt-0.5"
            >
              {{ status.pendingOperations }} operations, {{ status.pendingPhotos }} photos
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Failures Banner -->
    <div
      v-else-if="hasFailures"
      class="bg-red-600 text-white px-4 py-3 shadow-lg"
    >
      <div class="max-w-7xl mx-auto flex items-center justify-between">
        <div class="flex items-center">
          <svg
            class="h-5 w-5 text-white mr-2"
            fill="currentColor"
            viewBox="0 0 20 20"
          >
            <path
              fill-rule="evenodd"
              d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
              clip-rule="evenodd"
            />
          </svg>
          <div>
            <p class="text-sm font-medium">
              Sync Failed
            </p>
            <p class="text-xs text-red-100 mt-0.5">
              {{ status.failedOperations + status.failedPhotos }} items failed to sync
            </p>
          </div>
        </div>
        <div class="flex items-center space-x-2">
          <button
            class="text-xs bg-white bg-opacity-20 hover:bg-opacity-30 px-3 py-1 rounded transition-colors"
            @click="retry"
          >
            Retry
          </button>
          <button
            class="text-white hover:text-red-100"
            @click="dismiss"
          >
            <svg
              class="h-5 w-5"
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
          </button>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { offlineSync, type SyncStatus, type SyncEvent } from '@/utils/offlineSync'

// State
const status = ref<SyncStatus>({
  online: navigator.onLine,
  syncing: false,
  pendingOperations: 0,
  pendingPhotos: 0,
  failedOperations: 0,
  failedPhotos: 0
})

const dismissed = ref(false)

// Computed
const hasPending = computed(() => {
  return status.value.pendingOperations > 0 || status.value.pendingPhotos > 0
})

const hasFailures = computed(() => {
  return status.value.failedOperations > 0 || status.value.failedPhotos > 0
})

const shouldShow = computed(() => {
  if (dismissed.value) return false

  return (
    !status.value.online ||
    status.value.syncing ||
    hasFailures.value
  )
})

// Methods
const updateStatus = async () => {
  status.value = await offlineSync.getStatus()
}

const dismiss = () => {
  dismissed.value = true
  // Re-enable after 5 minutes
  setTimeout(() => {
    dismissed.value = false
  }, 5 * 60 * 1000)
}

const retry = async () => {
  await offlineSync.syncAll()
  updateStatus()
}

const handleSyncEvent = (event: SyncEvent) => {
  // Update status on any sync event
  updateStatus()
}

// Lifecycle
onMounted(() => {
  // Initial status
  updateStatus()

  // Listen to sync events
  offlineSync.on(handleSyncEvent)

  // Update status periodically
  const interval = setInterval(updateStatus, 10000) // Every 10 seconds

  // Cleanup
  onUnmounted(() => {
    clearInterval(interval)
    offlineSync.off(handleSyncEvent)
  })
})
</script>
