<template>
  <div class="min-h-screen bg-gray-50 flex items-center justify-center p-4">
    <div class="max-w-2xl w-full">
      <!-- Logo & Brand -->
      <div class="text-center mb-8">
        <div class="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-br from-primary-500 to-primary-600 shadow-glow mb-4">
          <svg class="w-10 h-10 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
          </svg>
        </div>
        <h1 class="text-3xl font-display font-semibold text-gray-900 mb-2">
          Select Organization
        </h1>
        <p class="text-gray-600">
          {{ isSystemAdmin ? 'Choose an organization to manage' : 'Select which organization to work with' }}
        </p>
      </div>

      <!-- Tenant Selection Card -->
      <div class="card">
        <div class="p-8">
          <!-- Loading State -->
          <div v-if="loading" class="text-center py-12">
            <div class="spinner mx-auto mb-4"></div>
            <p class="text-gray-600">Loading organizations...</p>
          </div>

          <!-- Error State -->
          <div v-else-if="error" class="alert-danger">
            <XCircleIcon class="h-5 w-5" />
            <div>
              <p class="text-sm font-medium">Failed to load organizations</p>
              <p class="text-xs mt-1">{{ error }}</p>
            </div>
            <button
              type="button"
              class="text-red-400 hover:text-red-600"
              @click="loadTenants"
            >
              Retry
            </button>
          </div>

          <!-- Tenant List -->
          <div v-else-if="tenants.length > 0" class="space-y-3" data-testid="tenant-list">
            <div
              v-for="tenant in tenants"
              :key="tenant.tenantId"
              @click="selectTenant(tenant)"
              class="relative flex items-center p-4 border-2 border-gray-200 rounded-lg hover:border-primary-500 hover:bg-primary-50 cursor-pointer transition-all group"
              :class="{ 'border-primary-500 bg-primary-50': selectedTenantId === tenant.tenantId }"
              :data-tenant-id="tenant.tenantId"
              data-testid="tenant-card"
            >
              <!-- Tenant Icon -->
              <div class="flex-shrink-0 mr-4">
                <div class="w-12 h-12 rounded-lg bg-gradient-to-br from-primary-400 to-primary-600 flex items-center justify-center text-white font-semibold text-lg">
                  {{ tenant.tenantCode.substring(0, 2).toUpperCase() }}
                </div>
              </div>

              <!-- Tenant Info -->
              <div class="flex-1 min-w-0">
                <h3 class="text-lg font-semibold text-gray-900 truncate">
                  {{ tenant.tenantName }}
                </h3>
                <p class="text-sm text-gray-600">
                  Code: {{ tenant.tenantCode }}
                  <span v-if="tenant.roleName" class="ml-2 text-primary-600">
                    • {{ tenant.roleName }}
                  </span>
                </p>
                <div class="flex items-center gap-2 mt-1">
                  <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800">
                    {{ tenant.subscriptionTier }}
                  </span>
                  <span v-if="isSystemAdmin" class="text-xs text-gray-500">
                    {{ tenant.maxUsers }} users • {{ tenant.maxLocations }} locations
                  </span>
                </div>
              </div>

              <!-- Selection Indicator -->
              <div class="flex-shrink-0 ml-4">
                <div
                  v-if="selectedTenantId === tenant.tenantId"
                  class="w-6 h-6 rounded-full bg-primary-600 flex items-center justify-center"
                >
                  <CheckIcon class="w-4 h-4 text-white" />
                </div>
                <div
                  v-else
                  class="w-6 h-6 rounded-full border-2 border-gray-300 group-hover:border-primary-500"
                ></div>
              </div>
            </div>
          </div>

          <!-- No Tenants State -->
          <div v-else class="text-center py-12">
            <BuildingOfficeIcon class="w-16 h-16 mx-auto text-gray-400 mb-4" />
            <p class="text-gray-600 mb-2">No organizations available</p>
            <p class="text-sm text-gray-500">Please contact your administrator</p>
          </div>

          <!-- Action Buttons -->
          <div v-if="tenants.length > 0" class="mt-8 flex gap-4">
            <button
              @click="handleContinue"
              :disabled="!selectedTenantId || continuing"
              class="btn-primary flex-1"
              data-testid="continue-button"
            >
              <span v-if="!continuing">Continue</span>
              <span v-else class="flex items-center justify-center">
                <div class="spinner mr-2"></div>
                Loading...
              </span>
            </button>
            <button
              @click="handleLogout"
              class="btn-outline"
              data-testid="logout-button"
            >
              Logout
            </button>
          </div>
        </div>
      </div>

      <!-- System Admin Notice -->
      <div v-if="isSystemAdmin" class="mt-6 text-center text-sm text-gray-600">
        You are logged in as a System Administrator
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useToastStore } from '@/stores/toast'
import tenantService from '@/services/tenantService'
import type { TenantDto } from '@/types/api'
import {
  BuildingOfficeIcon,
  XCircleIcon,
  CheckIcon
} from '@heroicons/vue/24/outline'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()
const toast = useToastStore()

// State
const tenants = ref<TenantDto[]>([])
const selectedTenantId = ref<string | null>(null)
const loading = ref(false)
const continuing = ref(false)
const error = ref<string | null>(null)

// Computed
const isSystemAdmin = computed(() => authStore.isSystemAdmin)

// Methods
const loadTenants = async () => {
  loading.value = true
  error.value = null

  try {
    tenants.value = await tenantService.getAvailable()

    // Auto-select if only one tenant
    if (tenants.value.length === 1) {
      selectedTenantId.value = tenants.value[0].tenantId
    }
  } catch (err: any) {
    error.value = err.response?.data?.message || 'Failed to load organizations'
    console.error('Failed to load tenants:', err)
  } finally {
    loading.value = false
  }
}

const selectTenant = (tenant: TenantDto) => {
  selectedTenantId.value = tenant.tenantId
}

const handleContinue = async () => {
  if (!selectedTenantId.value) return

  continuing.value = true

  try {
    // Set the selected tenant in the auth store
    authStore.setCurrentTenant(selectedTenantId.value)

    toast.success('Organization selected successfully')

    // Redirect to intended page or dashboard
    const redirect = (route.query.redirect as string) || '/dashboard'
    router.push(redirect)
  } catch (err: any) {
    error.value = err.response?.data?.message || 'Failed to select organization'
    console.error('Failed to select tenant:', err)
  } finally {
    continuing.value = false
  }
}

const handleLogout = () => {
  authStore.logout()
  router.push('/login')
}

// Lifecycle
onMounted(() => {
  loadTenants()
})
</script>
