<template>
  <AppLayout>
    <LoadingSpinner v-if="loading" message="Loading dashboard..." size="large" />
    <div v-else>
      <!-- Welcome Header -->
      <div class="mb-8">
        <h1 class="text-3xl font-display font-semibold text-gray-900 mb-2">
          Welcome back, {{ userFirstName }}!
        </h1>
        <p class="text-gray-600">
          Here's an overview of your fire safety compliance
        </p>
      </div>

      <!-- KPI Cards -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <!-- Total Locations -->
        <div class="card hover:shadow-lg transition-all duration-200">
          <div class="p-6">
            <div class="flex items-center justify-between mb-4">
              <div class="flex items-center justify-center w-12 h-12 rounded-lg bg-primary-100">
                <MapPinIcon class="h-6 w-6 text-primary-600" />
              </div>
              <span class="text-xs font-medium text-gray-500 uppercase tracking-wide">Locations</span>
            </div>
            <div class="text-3xl font-bold text-gray-900 mb-1">
              {{ locationStore.locations.length }}
            </div>
            <router-link
              to="/locations"
              class="text-sm text-primary-600 hover:text-primary-700 font-medium"
            >
              Manage locations →
            </router-link>
          </div>
        </div>

        <!-- Total Extinguishers -->
        <div class="card hover:shadow-lg transition-all duration-200">
          <div class="p-6">
            <div class="flex items-center justify-between mb-4">
              <div class="flex items-center justify-center w-12 h-12 rounded-lg bg-secondary-100">
                <ShieldCheckIcon class="h-6 w-6 text-secondary-600" />
              </div>
              <span class="text-xs font-medium text-gray-500 uppercase tracking-wide">Extinguishers</span>
            </div>
            <div class="text-3xl font-bold text-gray-900 mb-1">
              {{ extinguisherStore.extinguisherCount }}
            </div>
            <router-link
              to="/extinguishers"
              class="text-sm text-primary-600 hover:text-primary-700 font-medium"
            >
              View inventory →
            </router-link>
          </div>
        </div>

        <!-- Inspections This Month -->
        <div class="card hover:shadow-lg transition-all duration-200">
          <div class="p-6">
            <div class="flex items-center justify-between mb-4">
              <div class="flex items-center justify-center w-12 h-12 rounded-lg bg-blue-100">
                <ClipboardDocumentCheckIcon class="h-6 w-6 text-blue-600" />
              </div>
              <span class="text-xs font-medium text-gray-500 uppercase tracking-wide">This Month</span>
            </div>
            <div class="text-3xl font-bold text-gray-900 mb-1">
              0
            </div>
            <router-link
              to="/inspections"
              class="text-sm text-primary-600 hover:text-primary-700 font-medium"
            >
              View inspections →
            </router-link>
          </div>
        </div>

        <!-- Compliance Rate -->
        <div class="card hover:shadow-lg transition-all duration-200">
          <div class="p-6">
            <div class="flex items-center justify-between mb-4">
              <div class="flex items-center justify-center w-12 h-12 rounded-lg bg-accent-100">
                <ChartBarIcon class="h-6 w-6 text-accent-600" />
              </div>
              <span class="text-xs font-medium text-gray-500 uppercase tracking-wide">Compliance</span>
            </div>
            <div class="text-3xl font-bold text-gray-900 mb-1">
              --%
            </div>
            <router-link
              to="/reports"
              class="text-sm text-primary-600 hover:text-primary-700 font-medium"
            >
              View reports →
            </router-link>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        <!-- Quick Actions -->
        <div class="card">
          <div class="card-header">
            <h2 class="text-lg font-semibold text-gray-900">Quick Actions</h2>
          </div>
          <div class="card-body">
            <div class="grid grid-cols-2 gap-3">
              <router-link
                to="/locations"
                class="flex flex-col items-center justify-center p-6 rounded-lg border-2 border-gray-200 hover:border-primary-500 hover:bg-primary-50 transition-all duration-200 group"
              >
                <MapPinIcon class="h-8 w-8 text-gray-400 group-hover:text-primary-600 mb-2" />
                <span class="text-sm font-medium text-gray-700 group-hover:text-primary-700">Add Location</span>
              </router-link>

              <router-link
                to="/extinguishers"
                class="flex flex-col items-center justify-center p-6 rounded-lg border-2 border-gray-200 hover:border-primary-500 hover:bg-primary-50 transition-all duration-200 group"
              >
                <ShieldCheckIcon class="h-8 w-8 text-gray-400 group-hover:text-primary-600 mb-2" />
                <span class="text-sm font-medium text-gray-700 group-hover:text-primary-700">Add Extinguisher</span>
              </router-link>

              <router-link
                to="/inspections"
                class="flex flex-col items-center justify-center p-6 rounded-lg border-2 border-gray-200 hover:border-primary-500 hover:bg-primary-50 transition-all duration-200 group"
              >
                <ClipboardDocumentCheckIcon class="h-8 w-8 text-gray-400 group-hover:text-primary-600 mb-2" />
                <span class="text-sm font-medium text-gray-700 group-hover:text-primary-700">Start Inspection</span>
              </router-link>

              <router-link
                to="/reports"
                class="flex flex-col items-center justify-center p-6 rounded-lg border-2 border-gray-200 hover:border-primary-500 hover:bg-primary-50 transition-all duration-200 group"
              >
                <DocumentTextIcon class="h-8 w-8 text-gray-400 group-hover:text-primary-600 mb-2" />
                <span class="text-sm font-medium text-gray-700 group-hover:text-primary-700">Generate Report</span>
              </router-link>
            </div>
          </div>
        </div>

        <!-- Recent Activity -->
        <div class="card">
          <div class="card-header">
            <h2 class="text-lg font-semibold text-gray-900">Recent Activity</h2>
          </div>
          <div class="card-body">
            <!-- Empty State -->
            <div class="text-center py-8">
              <div class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-gray-100 mb-3">
                <ClockIcon class="h-6 w-6 text-gray-400" />
              </div>
              <p class="text-sm text-gray-600 mb-4">
                No recent activity yet
              </p>
              <p class="text-xs text-gray-500">
                Activity will appear here once you start using the system
              </p>
            </div>
          </div>
        </div>
      </div>

      <!-- Getting Started Guide -->
      <div v-if="locationStore.locations.length === 0" class="card border-2 border-primary-200 bg-primary-50">
        <div class="p-6">
          <div class="flex items-start">
            <div class="flex items-center justify-center w-12 h-12 rounded-lg bg-primary-100 flex-shrink-0">
              <SparklesIcon class="h-6 w-6 text-primary-600" />
            </div>
            <div class="ml-4 flex-1">
              <h3 class="text-lg font-semibold text-gray-900 mb-2">
                Get Started with FireProof
              </h3>
              <p class="text-sm text-gray-700 mb-4">
                Follow these steps to set up your fire safety management system:
              </p>
              <div class="space-y-3">
                <div class="flex items-start">
                  <div class="flex items-center justify-center w-6 h-6 rounded-full bg-primary-600 text-white text-xs font-bold flex-shrink-0 mt-0.5">
                    1
                  </div>
                  <div class="ml-3">
                    <p class="text-sm font-medium text-gray-900">Add your first location</p>
                    <p class="text-xs text-gray-600">Set up facilities where fire extinguishers are installed</p>
                  </div>
                </div>
                <div class="flex items-start">
                  <div class="flex items-center justify-center w-6 h-6 rounded-full bg-gray-300 text-white text-xs font-bold flex-shrink-0 mt-0.5">
                    2
                  </div>
                  <div class="ml-3">
                    <p class="text-sm font-medium text-gray-900">Register fire extinguishers</p>
                    <p class="text-xs text-gray-600">Add equipment to your inventory with QR codes</p>
                  </div>
                </div>
                <div class="flex items-start">
                  <div class="flex items-center justify-center w-6 h-6 rounded-full bg-gray-300 text-white text-xs font-bold flex-shrink-0 mt-0.5">
                    3
                  </div>
                  <div class="ml-3">
                    <p class="text-sm font-medium text-gray-900">Perform inspections</p>
                    <p class="text-xs text-gray-600">Complete monthly and annual inspections</p>
                  </div>
                </div>
              </div>
              <div class="mt-4">
                <router-link to="/locations" class="btn-primary inline-flex items-center">
                  <PlusIcon class="h-5 w-5 mr-2" />
                  Add First Location
                </router-link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </AppLayout>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useLocationStore } from '@/stores/locations'
import { useExtinguisherStore } from '@/stores/extinguishers'
import AppLayout from '@/components/layout/AppLayout.vue'
import LoadingSpinner from '@/components/LoadingSpinner.vue'
import {
  MapPinIcon,
  ShieldCheckIcon,
  ClipboardDocumentCheckIcon,
  ChartBarIcon,
  DocumentTextIcon,
  ClockIcon,
  SparklesIcon,
  PlusIcon
} from '@heroicons/vue/24/outline'

const authStore = useAuthStore()
const locationStore = useLocationStore()
const extinguisherStore = useExtinguisherStore()

const loading = ref(true)
const userFirstName = computed(() => authStore.user?.firstName || 'there')

onMounted(async () => {
  try {
    loading.value = true
    // Load initial data
    await Promise.all([
      locationStore.fetchLocations(),
      extinguisherStore.fetchExtinguishers()
    ])
  } catch (error) {
    console.error('Failed to load dashboard data:', error)
  } finally {
    loading.value = false
  }
})
</script>
