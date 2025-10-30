<template>
  <div
    v-if="show"
    class="bg-primary-600 text-white shadow-lg"
    data-testid="tenant-selector-banner"
  >
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
      <div class="flex items-center justify-between flex-wrap gap-4">
        <!-- Info Section -->
        <div class="flex items-center gap-3">
          <BuildingOfficeIcon class="h-6 w-6 flex-shrink-0" />
          <div>
            <h3 class="text-sm font-semibold" data-testid="tenant-selector-title">
              Select Organization
            </h3>
            <p class="text-xs text-primary-100" data-testid="tenant-selector-description">
              Choose an organization to view and manage data
            </p>
          </div>
        </div>

        <!-- Tenant Dropdown -->
        <div class="flex items-center gap-3">
          <div class="relative" data-testid="tenant-selector-dropdown">
            <select
              v-model="selectedTenantId"
              class="appearance-none bg-white text-gray-900 rounded-lg px-4 py-2 pr-10 text-sm font-medium border-2 border-primary-700 focus:outline-none focus:ring-2 focus:ring-white focus:border-white transition-colors min-w-[250px]"
              :disabled="loading"
              data-testid="tenant-selector-select"
              @change="handleTenantChange"
            >
              <option value="" disabled data-testid="tenant-selector-placeholder">
                {{ loading ? 'Loading organizations...' : 'Choose an organization...' }}
              </option>
              <option
                v-for="tenant in availableTenants"
                :key="tenant.tenantId"
                :value="tenant.tenantId"
                :data-testid="`tenant-option-${tenant.tenantId}`"
              >
                {{ tenant.tenantName }} ({{ tenant.tenantCode }})
              </option>
            </select>
            <ChevronDownIcon
              class="absolute right-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-500 pointer-events-none"
            />
          </div>

          <button
            v-if="selectedTenantId"
            type="button"
            class="px-4 py-2 bg-white text-primary-700 rounded-lg text-sm font-semibold hover:bg-primary-50 focus:outline-none focus:ring-2 focus:ring-white transition-colors"
            :disabled="applying"
            data-testid="tenant-selector-apply-button"
            @click="applyTenantSelection"
          >
            {{ applying ? 'Applying...' : 'Apply' }}
          </button>
        </div>
      </div>

      <!-- Error Display -->
      <div
        v-if="error"
        class="mt-3 bg-red-600 text-white rounded-lg px-4 py-2 text-sm"
        data-testid="tenant-selector-error"
      >
        {{ error }}
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { BuildingOfficeIcon, ChevronDownIcon } from '@heroicons/vue/24/outline'
import api from '@/services/api'
import type { TenantDto } from '@/types/api'

const authStore = useAuthStore()

// State
const availableTenants = ref<TenantDto[]>([])
const selectedTenantId = ref<string>('')
const loading = ref(false)
const applying = ref(false)
const error = ref<string | null>(null)

// Computed
const show = computed(() => authStore.needsTenantSelection)

// Methods
const fetchAvailableTenants = async (): Promise<void> => {
  loading.value = true
  error.value = null

  try {
    const response = await api.get<TenantDto[]>('/api/tenants/available')
    availableTenants.value = response.data

    // Pre-select if user already has a selection in localStorage
    const storedTenantId = localStorage.getItem('currentTenantId')
    if (storedTenantId && availableTenants.value.some(t => t.tenantId === storedTenantId)) {
      selectedTenantId.value = storedTenantId
    }
  } catch (err: any) {
    console.error('Failed to fetch available tenants:', err)
    error.value = err.response?.data?.message || 'Failed to load organizations'
  } finally {
    loading.value = false
  }
}

const handleTenantChange = (): void => {
  error.value = null
}

const applyTenantSelection = async (): Promise<void> => {
  if (!selectedTenantId.value) {
    error.value = 'Please select an organization'
    return
  }

  applying.value = true
  error.value = null

  try {
    // Update auth store with selected tenant
    authStore.setCurrentTenant(selectedTenantId.value)

    // Reload the page to refresh all data with new tenant context
    // This ensures all views and stores re-fetch data with the correct tenantId
    window.location.reload()
  } catch (err: any) {
    console.error('Failed to apply tenant selection:', err)
    error.value = 'Failed to apply organization selection'
    applying.value = false
  }
}

// Lifecycle
onMounted(() => {
  if (show.value) {
    fetchAvailableTenants()
  }
})
</script>
