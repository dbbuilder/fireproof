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
          <h1 class="text-lg font-semibold text-gray-900">Inspection Details</h1>
          <button
            @click="showActions = true"
            class="text-gray-600 hover:text-gray-900"
          >
            <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" />
            </svg>
          </button>
        </div>
      </div>
    </div>

    <!-- Main Content -->
    <div v-if="inspection" class="max-w-2xl mx-auto px-4 py-6 sm:px-6 lg:px-8 space-y-6">
      <!-- Success Alert (if just completed) -->
      <div v-if="route.query.completed === 'true'" class="bg-green-50 border border-green-200 rounded-lg p-4 animate-slide-down">
        <div class="flex">
          <svg class="h-5 w-5 text-green-600 mr-2" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
          </svg>
          <p class="text-sm text-green-800 font-medium">Inspection completed successfully!</p>
        </div>
      </div>

      <!-- Status & Result Card -->
      <div class="bg-white rounded-lg shadow-soft p-6">
        <div class="flex items-center justify-between mb-4">
          <div>
            <div class="flex items-center">
              <span
                :class="getStatusBadgeClass(inspection.status)"
                class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium"
              >
                {{ inspection.status }}
              </span>
              <span
                v-if="inspection.overallResult"
                :class="getResultBadgeClass(inspection.overallResult)"
                class="ml-2 inline-flex items-center px-3 py-1 rounded-full text-xs font-medium"
              >
                {{ inspection.overallResult }}
              </span>
            </div>
            <h2 class="text-2xl font-bold text-gray-900 mt-2">{{ inspection.inspectionType }}</h2>
          </div>
          <div
            v-if="inspection.overallResult"
            :class="getResultIconClass(inspection.overallResult)"
            class="flex-shrink-0 w-16 h-16 rounded-full flex items-center justify-center"
          >
            <svg v-if="inspection.overallResult === 'Pass'" class="h-8 w-8" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
            </svg>
            <svg v-else-if="inspection.overallResult === 'Fail'" class="h-8 w-8" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
            </svg>
            <svg v-else class="h-8 w-8" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
            </svg>
          </div>
        </div>

        <!-- Details Grid -->
        <div class="grid grid-cols-2 gap-4 mt-6">
          <div>
            <p class="text-xs text-gray-500 uppercase tracking-wide">Extinguisher</p>
            <p class="text-sm font-medium text-gray-900 mt-1">{{ inspection.extinguisherAssetTag || inspection.extinguisherCode }}</p>
          </div>
          <div>
            <p class="text-xs text-gray-500 uppercase tracking-wide">Location</p>
            <p class="text-sm font-medium text-gray-900 mt-1">{{ inspection.locationName }}</p>
          </div>
          <div>
            <p class="text-xs text-gray-500 uppercase tracking-wide">Date</p>
            <p class="text-sm font-medium text-gray-900 mt-1">{{ formatDate(inspection.inspectionDate) }}</p>
          </div>
          <div>
            <p class="text-xs text-gray-500 uppercase tracking-wide">Inspector</p>
            <p class="text-sm font-medium text-gray-900 mt-1">{{ inspection.inspectorName }}</p>
          </div>
        </div>

        <!-- GPS Info -->
        <div v-if="inspection.latitude && inspection.longitude" class="mt-4 pt-4 border-t border-gray-200">
          <p class="text-xs text-gray-500 uppercase tracking-wide mb-1">GPS Coordinates</p>
          <div class="flex items-center text-sm text-gray-900">
            <svg class="h-4 w-4 text-gray-400 mr-1" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M5.05 4.05a7 7 0 119.9 9.9L10 18.9l-4.95-4.95a7 7 0 010-9.9zM10 11a2 2 0 100-4 2 2 0 000 4z" clip-rule="evenodd" />
            </svg>
            <span>{{ inspection.latitude.toFixed(6) }}, {{ inspection.longitude.toFixed(6) }}</span>
            <span
              :class="inspection.locationVerified ? 'text-green-600' : 'text-gray-400'"
              class="ml-2 text-xs"
            >
              {{ inspection.locationVerified ? '✓ Verified' : '○ Unverified' }}
            </span>
          </div>
        </div>

        <!-- Verification Status -->
        <div v-if="inspection.inspectionHash" class="mt-4 pt-4 border-t border-gray-200">
          <div class="flex items-center justify-between">
            <div class="flex items-center">
              <svg
                :class="inspection.hashVerified ? 'text-green-600' : 'text-gray-400'"
                class="h-5 w-5 mr-2"
                fill="currentColor"
                viewBox="0 0 20 20"
              >
                <path fill-rule="evenodd" d="M2.166 4.999A11.954 11.954 0 0010 1.944 11.954 11.954 0 0017.834 5c.11.65.166 1.32.166 2.001 0 5.225-3.34 9.67-8 11.317C5.34 16.67 2 12.225 2 7c0-.682.057-1.35.166-2.001zm11.541 3.708a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
              </svg>
              <span class="text-sm font-medium text-gray-900">
                {{ inspection.hashVerified ? 'Tamper-Proof Verified' : 'Verification Pending' }}
              </span>
            </div>
            <button
              v-if="!verifying"
              @click="verifyIntegrity"
              class="text-sm text-primary-600 hover:text-primary-700 font-medium"
            >
              Verify Now
            </button>
            <span v-else class="text-sm text-gray-500">Verifying...</span>
          </div>
        </div>
      </div>

      <!-- Checklist Responses -->
      <div v-if="inspection.checklistResponses && inspection.checklistResponses.length > 0" class="bg-white rounded-lg shadow-soft p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Checklist Responses</h3>

        <div class="space-y-3">
          <div
            v-for="response in inspection.checklistResponses"
            :key="response.responseId"
            class="flex items-start justify-between py-3 border-b border-gray-100 last:border-0"
          >
            <div class="flex-1">
              <p class="text-sm font-medium text-gray-900">{{ response.itemText }}</p>
              <p v-if="response.comment" class="text-sm text-gray-600 mt-1">{{ response.comment }}</p>
            </div>
            <span
              :class="getResponseBadgeClass(response.response)"
              class="ml-3 inline-flex items-center px-2 py-1 rounded text-xs font-medium"
            >
              {{ response.response }}
            </span>
          </div>
        </div>
      </div>

      <!-- Photos -->
      <div v-if="inspection.photos && inspection.photos.length > 0" class="bg-white rounded-lg shadow-soft p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Photos ({{ inspection.photos.length }})</h3>

        <div class="grid grid-cols-3 gap-3">
          <div
            v-for="photo in inspection.photos"
            :key="photo.photoId"
            @click="viewPhoto(photo)"
            class="aspect-square rounded-lg overflow-hidden cursor-pointer hover:opacity-90 transition-opacity"
          >
            <img
              :src="photo.thumbnailUrl"
              :alt="photo.photoType"
              class="w-full h-full object-cover"
            />
          </div>
        </div>
      </div>

      <!-- Deficiencies -->
      <div v-if="inspection.deficiencies && inspection.deficiencies.length > 0" class="bg-white rounded-lg shadow-soft p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Deficiencies ({{ inspection.deficiencies.length }})</h3>

        <div class="space-y-3">
          <div
            v-for="deficiency in inspection.deficiencies"
            :key="deficiency.deficiencyId"
            class="p-4 border border-gray-200 rounded-lg"
          >
            <div class="flex items-start justify-between mb-2">
              <p class="font-medium text-gray-900">{{ deficiency.deficiencyType }}</p>
              <span
                :class="getSeverityBadgeClass(deficiency.severity)"
                class="inline-flex items-center px-2 py-1 rounded text-xs font-medium"
              >
                {{ deficiency.severity }}
              </span>
            </div>
            <p class="text-sm text-gray-600">{{ deficiency.description }}</p>
            <div class="mt-2 flex items-center text-xs text-gray-500">
              <span>Status: {{ deficiency.status }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Final Notes -->
      <div v-if="inspection.notes" class="bg-white rounded-lg shadow-soft p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Final Notes</h3>
        <p class="text-sm text-gray-700 whitespace-pre-wrap">{{ inspection.notes }}</p>
      </div>

      <!-- Inspector Signature -->
      <div v-if="inspection.inspectorSignature" class="bg-white rounded-lg shadow-soft p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Inspector Signature</h3>
        <p class="text-base font-medium text-gray-900 italic">{{ inspection.inspectorSignature }}</p>
        <p class="text-xs text-gray-500 mt-1">
          Signed on {{ formatDate(inspection.modifiedDate) }}
        </p>
      </div>
    </div>

    <!-- Loading State -->
    <div v-else-if="loading" class="flex items-center justify-center min-h-screen">
      <svg class="animate-spin h-12 w-12 text-primary-600" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
    </div>

    <!-- Actions Modal -->
    <div
      v-if="showActions"
      class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-end justify-center sm:items-center"
      @click="showActions = false"
    >
      <div @click.stop class="bg-white rounded-t-lg sm:rounded-lg p-4 w-full max-w-sm space-y-2 animate-slide-up">
        <button
          @click="exportPDF"
          class="w-full px-4 py-3 text-left text-gray-700 hover:bg-gray-50 rounded-lg transition-colors"
        >
          Export PDF
        </button>
        <button
          @click="shareInspection"
          class="w-full px-4 py-3 text-left text-gray-700 hover:bg-gray-50 rounded-lg transition-colors"
        >
          Share
        </button>
        <button
          @click="showActions = false"
          class="w-full px-4 py-3 text-center text-gray-500 hover:bg-gray-50 rounded-lg transition-colors border-t"
        >
          Cancel
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useInspectionPhase1Store } from '@/stores/inspectionsPhase1'
import type { InspectionPhase1Dto, InspectionPhotoDto } from '@/types/api'

const route = useRoute()
const inspectionStore = useInspectionPhase1Store()

// State
const inspection = ref<InspectionPhase1Dto | null>(null)
const loading = ref(false)
const verifying = ref(false)
const showActions = ref(false)

// Methods
const formatDate = (dateString: string): string => {
  return new Date(dateString).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const getStatusBadgeClass = (status: string): string => {
  const classes: Record<string, string> = {
    'Scheduled': 'bg-blue-100 text-blue-800',
    'InProgress': 'bg-yellow-100 text-yellow-800',
    'Completed': 'bg-green-100 text-green-800',
    'Failed': 'bg-red-100 text-red-800',
    'Cancelled': 'bg-gray-100 text-gray-800'
  }
  return classes[status] || 'bg-gray-100 text-gray-800'
}

const getResultBadgeClass = (result: string): string => {
  const classes: Record<string, string> = {
    'Pass': 'bg-green-100 text-green-800',
    'Fail': 'bg-red-100 text-red-800',
    'ConditionalPass': 'bg-yellow-100 text-yellow-800'
  }
  return classes[result] || 'bg-gray-100 text-gray-800'
}

const getResultIconClass = (result: string): string => {
  const classes: Record<string, string> = {
    'Pass': 'bg-green-100 text-green-600',
    'Fail': 'bg-red-100 text-red-600',
    'ConditionalPass': 'bg-yellow-100 text-yellow-600'
  }
  return classes[result] || 'bg-gray-100 text-gray-600'
}

const getResponseBadgeClass = (response: string): string => {
  const classes: Record<string, string> = {
    'Pass': 'bg-green-100 text-green-800',
    'Fail': 'bg-red-100 text-red-800',
    'N/A': 'bg-gray-100 text-gray-800'
  }
  return classes[response] || 'bg-gray-100 text-gray-800'
}

const getSeverityBadgeClass = (severity: string): string => {
  const classes: Record<string, string> = {
    'Critical': 'bg-red-100 text-red-800',
    'High': 'bg-orange-100 text-orange-800',
    'Medium': 'bg-yellow-100 text-yellow-800',
    'Low': 'bg-blue-100 text-blue-800'
  }
  return classes[severity] || 'bg-gray-100 text-gray-800'
}

const verifyIntegrity = async () => {
  if (!inspection.value) return

  verifying.value = true

  try {
    const verification = await inspectionStore.verifyIntegrity(inspection.value.inspectionId)

    if (verification.isValid) {
      alert('✓ Inspection integrity verified!\n\nThis inspection has not been tampered with.')
    } else {
      alert('⚠ Integrity Verification Failed!\n\n' + verification.validationMessage)
    }
  } catch (err) {
    alert('Failed to verify inspection integrity')
  } finally {
    verifying.value = false
  }
}

const viewPhoto = (photo: InspectionPhotoDto) => {
  // TODO: Open photo viewer modal
  window.open(photo.blobUrl, '_blank')
}

const exportPDF = () => {
  // TODO: Implement PDF export
  alert('PDF export will be implemented')
  showActions.value = false
}

const shareInspection = () => {
  // TODO: Implement share functionality
  if (navigator.share) {
    navigator.share({
      title: 'Inspection Report',
      text: `Fire Extinguisher Inspection - ${inspection.value?.extinguisherAssetTag}`,
      url: window.location.href
    })
  } else {
    alert('Sharing is not supported on this device')
  }
  showActions.value = false
}

const loadInspection = async () => {
  loading.value = true

  try {
    const inspectionId = route.params.id as string
    inspection.value = await inspectionStore.fetchInspectionById(inspectionId, true)
  } catch (err) {
    console.error('Error loading inspection:', err)
  } finally {
    loading.value = false
  }
}

// Lifecycle
onMounted(() => {
  loadInspection()
})
</script>
