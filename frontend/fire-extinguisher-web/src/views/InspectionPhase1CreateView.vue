<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Mobile Header -->
    <div class="bg-white border-b border-gray-200 sticky top-0 z-10">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex items-center justify-between h-16">
          <router-link
            to="/inspections"
            class="flex items-center text-gray-600 hover:text-gray-900"
          >
            <svg class="h-6 w-6 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
            </svg>
            <span class="font-medium">Back</span>
          </router-link>
          <h1 class="text-lg font-semibold text-gray-900">New Inspection</h1>
          <div class="w-20"></div> <!-- Spacer for center alignment -->
        </div>
      </div>
    </div>

    <!-- Main Content -->
    <div class="max-w-2xl mx-auto px-4 py-6 sm:px-6 lg:px-8">
      <!-- Step Indicator -->
      <div class="mb-6">
        <div class="flex items-center justify-center space-x-4">
          <div
            class="flex items-center"
            :class="step >= 1 ? 'text-primary-600' : 'text-gray-400'"
          >
            <div
              class="flex items-center justify-center w-10 h-10 rounded-full border-2"
              :class="step >= 1 ? 'border-primary-600 bg-primary-50' : 'border-gray-300'"
            >
              <span class="text-sm font-semibold">1</span>
            </div>
            <span class="ml-2 text-sm font-medium hidden sm:inline">Extinguisher</span>
          </div>
          <div class="w-12 h-0.5" :class="step >= 2 ? 'bg-primary-600' : 'bg-gray-300'"></div>
          <div
            class="flex items-center"
            :class="step >= 2 ? 'text-primary-600' : 'text-gray-400'"
          >
            <div
              class="flex items-center justify-center w-10 h-10 rounded-full border-2"
              :class="step >= 2 ? 'border-primary-600 bg-primary-50' : 'border-gray-300'"
            >
              <span class="text-sm font-semibold">2</span>
            </div>
            <span class="ml-2 text-sm font-medium hidden sm:inline">Template</span>
          </div>
          <div class="w-12 h-0.5" :class="step >= 3 ? 'bg-primary-600' : 'bg-gray-300'"></div>
          <div
            class="flex items-center"
            :class="step >= 3 ? 'text-primary-600' : 'text-gray-400'"
          >
            <div
              class="flex items-center justify-center w-10 h-10 rounded-full border-2"
              :class="step >= 3 ? 'border-primary-600 bg-primary-50' : 'border-gray-300'"
            >
              <span class="text-sm font-semibold">3</span>
            </div>
            <span class="ml-2 text-sm font-medium hidden sm:inline">Start</span>
          </div>
        </div>
      </div>

      <!-- Step 1: Select Extinguisher -->
      <div v-if="step === 1" class="animate-fade-in">
        <div class="bg-white rounded-lg shadow-soft p-6">
          <h2 class="text-xl font-semibold text-gray-900 mb-4">Select Extinguisher</h2>

          <!-- Scan QR Code Button -->
          <button
            @click="scanQRCode"
            class="w-full mb-4 flex items-center justify-center px-4 py-3 border-2 border-dashed border-gray-300 rounded-lg text-gray-700 hover:border-primary-500 hover:bg-primary-50 transition-colors"
          >
            <svg class="h-6 w-6 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z" />
            </svg>
            Scan Barcode/QR Code
          </button>

          <div class="relative">
            <div class="absolute inset-0 flex items-center">
              <div class="w-full border-t border-gray-300"></div>
            </div>
            <div class="relative flex justify-center text-sm">
              <span class="px-2 bg-white text-gray-500">or select manually</span>
            </div>
          </div>

          <!-- Search/Filter -->
          <div class="mt-4">
            <label for="search" class="block text-sm font-medium text-gray-700 mb-1">Search</label>
            <input
              type="text"
              id="search"
              v-model="searchQuery"
              placeholder="Asset tag, location, serial..."
              class="w-full rounded-lg border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
            />
          </div>

          <!-- Extinguisher List -->
          <div class="mt-4 space-y-2 max-h-96 overflow-y-auto">
            <div
              v-for="extinguisher in filteredExtinguishers"
              :key="extinguisher.extinguisherId"
              @click="selectExtinguisher(extinguisher)"
              class="p-4 border border-gray-200 rounded-lg cursor-pointer hover:border-primary-500 hover:bg-primary-50 transition-colors"
            >
              <div class="flex justify-between items-start">
                <div>
                  <p class="font-medium text-gray-900">{{ extinguisher.assetTag || extinguisher.extinguisherCode }}</p>
                  <p class="text-sm text-gray-600">{{ extinguisher.locationName }}</p>
                  <p class="text-xs text-gray-500">{{ extinguisher.typeName }} • {{ extinguisher.serialNumber }}</p>
                </div>
                <svg class="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                </svg>
              </div>
            </div>

            <div v-if="filteredExtinguishers.length === 0" class="text-center py-8 text-gray-500">
              No extinguishers found
            </div>
          </div>
        </div>
      </div>

      <!-- Step 2: Select Template -->
      <div v-if="step === 2" class="animate-fade-in">
        <div class="bg-white rounded-lg shadow-soft p-6">
          <h2 class="text-xl font-semibold text-gray-900 mb-4">Select Inspection Type</h2>

          <!-- Template List -->
          <div class="space-y-3">
            <div
              v-for="template in templates"
              :key="template.templateId"
              @click="selectTemplate(template)"
              class="p-4 border border-gray-200 rounded-lg cursor-pointer hover:border-primary-500 hover:bg-primary-50 transition-colors"
            >
              <div class="flex justify-between items-start">
                <div class="flex-1">
                  <p class="font-medium text-gray-900">{{ template.templateName }}</p>
                  <p class="text-sm text-gray-600 mt-1">{{ template.inspectionType }}</p>
                  <p class="text-xs text-gray-500 mt-1">{{ template.standard }}</p>
                  <p v-if="template.description" class="text-sm text-gray-600 mt-2">{{ template.description }}</p>
                </div>
                <svg class="h-5 w-5 text-gray-400 ml-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                </svg>
              </div>
            </div>
          </div>

          <!-- Back Button -->
          <button
            @click="step = 1"
            class="mt-6 w-full px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50"
          >
            Back
          </button>
        </div>
      </div>

      <!-- Step 3: Confirm and Start -->
      <div v-if="step === 3" class="animate-fade-in">
        <div class="bg-white rounded-lg shadow-soft p-6">
          <h2 class="text-xl font-semibold text-gray-900 mb-4">Confirm Inspection</h2>

          <!-- Summary -->
          <div class="space-y-4">
            <div class="p-4 bg-gray-50 rounded-lg">
              <p class="text-sm text-gray-600 mb-1">Extinguisher</p>
              <p class="font-medium text-gray-900">{{ selectedExtinguisher?.assetTag || selectedExtinguisher?.extinguisherCode }}</p>
              <p class="text-sm text-gray-600">{{ selectedExtinguisher?.locationName }}</p>
            </div>

            <div class="p-4 bg-gray-50 rounded-lg">
              <p class="text-sm text-gray-600 mb-1">Inspection Type</p>
              <p class="font-medium text-gray-900">{{ selectedTemplate?.templateName }}</p>
              <p class="text-sm text-gray-600">{{ selectedTemplate?.inspectionType }}</p>
            </div>

            <!-- GPS Location (optional) -->
            <div class="p-4 bg-gray-50 rounded-lg">
              <div class="flex items-center justify-between mb-2">
                <p class="text-sm text-gray-600">GPS Location</p>
                <button
                  @click="captureLocation"
                  :disabled="capturingLocation"
                  class="text-sm text-primary-600 hover:text-primary-700 disabled:text-gray-400"
                >
                  {{ capturingLocation ? 'Capturing...' : gpsLocation ? 'Update' : 'Capture' }}
                </button>
              </div>
              <p v-if="gpsLocation" class="text-sm text-gray-900">
                {{ gpsLocation.latitude.toFixed(6) }}, {{ gpsLocation.longitude.toFixed(6) }}
              </p>
              <p v-else class="text-sm text-gray-500">Not captured</p>
            </div>
          </div>

          <!-- Actions -->
          <div class="mt-6 space-y-3">
            <button
              @click="startInspection"
              :disabled="creatingInspection"
              class="w-full px-6 py-3 bg-primary-600 text-white rounded-lg font-medium hover:bg-primary-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition-colors shadow-sm"
            >
              {{ creatingInspection ? 'Starting...' : 'Start Inspection' }}
            </button>

            <button
              @click="step = 2"
              :disabled="creatingInspection"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 disabled:bg-gray-100 disabled:cursor-not-allowed"
            >
              Back
            </button>
          </div>
        </div>
      </div>

      <!-- Error Message -->
      <div v-if="error" class="mt-4 p-4 bg-red-50 border border-red-200 rounded-lg">
        <div class="flex">
          <svg class="h-5 w-5 text-red-600 mr-2" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
          </svg>
          <p class="text-sm text-red-800">{{ error }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useExtinguisherStore } from '@/stores/extinguishers'
import { useChecklistTemplateStore } from '@/stores/checklistTemplates'
import { useInspectionPhase1Store } from '@/stores/inspectionsPhase1'
import { useAuthStore } from '@/stores/auth'
import type { ExtinguisherDto, ChecklistTemplateDto } from '@/types/api'

const router = useRouter()
const extinguisherStore = useExtinguisherStore()
const templateStore = useChecklistTemplateStore()
const inspectionStore = useInspectionPhase1Store()
const authStore = useAuthStore()

// State
const step = ref(1)
const searchQuery = ref('')
const selectedExtinguisher = ref<ExtinguisherDto | null>(null)
const selectedTemplate = ref<ChecklistTemplateDto | null>(null)
const gpsLocation = ref<{ latitude: number; longitude: number } | null>(null)
const capturingLocation = ref(false)
const creatingInspection = ref(false)
const error = ref<string | null>(null)

// Computed
const filteredExtinguishers = computed(() => {
  if (!searchQuery.value) {
    return extinguisherStore.extinguishers
  }

  const query = searchQuery.value.toLowerCase()
  return extinguisherStore.extinguishers.filter(ext =>
    ext.assetTag?.toLowerCase().includes(query) ||
    ext.extinguisherCode.toLowerCase().includes(query) ||
    ext.serialNumber.toLowerCase().includes(query) ||
    ext.locationName?.toLowerCase().includes(query) ||
    ext.typeName?.toLowerCase().includes(query)
  )
})

const templates = computed(() => templateStore.templates)

// Methods
const selectExtinguisher = (extinguisher: ExtinguisherDto) => {
  selectedExtinguisher.value = extinguisher
  step.value = 2
}

const selectTemplate = (template: ChecklistTemplateDto) => {
  selectedTemplate.value = template
  step.value = 3
}

const scanQRCode = async () => {
  // TODO: Implement QR/barcode scanning
  error.value = 'QR code scanning will be implemented with camera component'
}

const captureLocation = async () => {
  if (!navigator.geolocation) {
    error.value = 'Geolocation is not supported by your device'
    return
  }

  capturingLocation.value = true
  error.value = null

  try {
    const position = await new Promise<GeolocationPosition>((resolve, reject) => {
      navigator.geolocation.getCurrentPosition(resolve, reject, {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0
      })
    })

    gpsLocation.value = {
      latitude: position.coords.latitude,
      longitude: position.coords.longitude
    }
  } catch (err: any) {
    error.value = `Failed to capture location: ${err.message}`
  } finally {
    capturingLocation.value = false
  }
}

const startInspection = async () => {
  if (!selectedExtinguisher.value || !selectedTemplate.value) {
    error.value = 'Please select extinguisher and template'
    return
  }

  creatingInspection.value = true
  error.value = null

  try {
    const inspection = await inspectionStore.createInspection({
      extinguisherId: selectedExtinguisher.value.extinguisherId,
      inspectorUserId: authStore.user?.userId || '',
      templateId: selectedTemplate.value.templateId,
      inspectionType: selectedTemplate.value.inspectionType,
      latitude: gpsLocation.value?.latitude || null,
      longitude: gpsLocation.value?.longitude || null
    })

    // Navigate to inspection checklist
    router.push(`/inspections/${inspection.inspectionId}/checklist`)
  } catch (err: any) {
    error.value = err.response?.data?.message || 'Failed to create inspection'
  } finally {
    creatingInspection.value = false
  }
}

// Lifecycle
onMounted(async () => {
  try {
    // Fetch extinguishers and templates
    await Promise.all([
      extinguisherStore.fetchExtinguishers(),
      templateStore.fetchTenantTemplates()
    ])
  } catch (err: any) {
    error.value = 'Failed to load data'
  }
})
</script>
