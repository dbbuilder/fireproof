<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Mobile Header -->
    <div class="bg-white border-b border-gray-200 sticky top-0 z-10">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex items-center justify-between h-16">
          <button
            class="flex items-center text-gray-600 hover:text-gray-900"
            @click="goBack"
          >
            <svg
              class="h-6 w-6 mr-2"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M15 19l-7-7 7-7"
              />
            </svg>
            <span class="font-medium">Back</span>
          </button>
          <h1 class="text-lg font-semibold text-gray-900">
            Complete Inspection
          </h1>
          <div class="w-20" />
        </div>
      </div>
    </div>

    <!-- Main Content -->
    <div
      v-if="inspection"
      class="max-w-2xl mx-auto px-4 py-6 sm:px-6 lg:px-8"
    >
      <!-- Inspection Summary Card -->
      <div class="bg-white rounded-lg shadow-soft p-6 mb-6">
        <div class="flex items-center mb-4">
          <div class="flex-shrink-0 w-12 h-12 rounded-full bg-primary-100 flex items-center justify-center">
            <svg
              class="h-6 w-6 text-primary-600"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
          </div>
          <div class="ml-4">
            <h2 class="text-xl font-semibold text-gray-900">
              Inspection Summary
            </h2>
            <p class="text-sm text-gray-600">
              Review and finalize your inspection
            </p>
          </div>
        </div>

        <div class="space-y-3 border-t border-gray-200 pt-4">
          <div class="flex justify-between">
            <span class="text-sm text-gray-600">Extinguisher</span>
            <span class="text-sm font-medium text-gray-900">{{ inspection.extinguisherAssetTag || inspection.extinguisherCode }}</span>
          </div>
          <div class="flex justify-between">
            <span class="text-sm text-gray-600">Location</span>
            <span class="text-sm font-medium text-gray-900">{{ inspection.locationName }}</span>
          </div>
          <div class="flex justify-between">
            <span class="text-sm text-gray-600">Type</span>
            <span class="text-sm font-medium text-gray-900">{{ inspection.inspectionType }}</span>
          </div>
          <div class="flex justify-between">
            <span class="text-sm text-gray-600">Date</span>
            <span class="text-sm font-medium text-gray-900">{{ formatDate(inspection.inspectionDate) }}</span>
          </div>
          <div class="flex justify-between">
            <span class="text-sm text-gray-600">Checklist Items</span>
            <span class="text-sm font-medium text-gray-900">{{ checklistResponsesCount }} responses</span>
          </div>
        </div>
      </div>

      <!-- Overall Result Selection -->
      <div class="bg-white rounded-lg shadow-soft p-6 mb-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">
          Overall Result *
        </h3>
        <p class="text-sm text-gray-600 mb-4">
          Select the final inspection result
        </p>

        <div class="grid grid-cols-1 gap-3">
          <button
            :class="overallResult === 'Pass' ? 'border-green-600 bg-green-50' : 'border-gray-300 hover:border-gray-400 hover:bg-gray-50'"
            class="flex items-center p-4 border-2 rounded-lg transition-all"
            @click="overallResult = 'Pass'"
          >
            <div
              :class="overallResult === 'Pass' ? 'bg-green-600' : 'bg-gray-300'"
              class="flex-shrink-0 w-6 h-6 rounded-full flex items-center justify-center mr-3"
            >
              <svg
                v-if="overallResult === 'Pass'"
                class="h-4 w-4 text-white"
                fill="currentColor"
                viewBox="0 0 20 20"
              >
                <path
                  fill-rule="evenodd"
                  d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                  clip-rule="evenodd"
                />
              </svg>
            </div>
            <div class="flex-1 text-left">
              <p
                :class="overallResult === 'Pass' ? 'text-green-900' : 'text-gray-900'"
                class="font-medium"
              >
                Pass
              </p>
              <p
                :class="overallResult === 'Pass' ? 'text-green-700' : 'text-gray-600'"
                class="text-sm"
              >
                All items meet requirements
              </p>
            </div>
          </button>

          <button
            :class="overallResult === 'ConditionalPass' ? 'border-yellow-600 bg-yellow-50' : 'border-gray-300 hover:border-gray-400 hover:bg-gray-50'"
            class="flex items-center p-4 border-2 rounded-lg transition-all"
            @click="overallResult = 'ConditionalPass'"
          >
            <div
              :class="overallResult === 'ConditionalPass' ? 'bg-yellow-600' : 'bg-gray-300'"
              class="flex-shrink-0 w-6 h-6 rounded-full flex items-center justify-center mr-3"
            >
              <svg
                v-if="overallResult === 'ConditionalPass'"
                class="h-4 w-4 text-white"
                fill="currentColor"
                viewBox="0 0 20 20"
              >
                <path
                  fill-rule="evenodd"
                  d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                  clip-rule="evenodd"
                />
              </svg>
            </div>
            <div class="flex-1 text-left">
              <p
                :class="overallResult === 'ConditionalPass' ? 'text-yellow-900' : 'text-gray-900'"
                class="font-medium"
              >
                Conditional Pass
              </p>
              <p
                :class="overallResult === 'ConditionalPass' ? 'text-yellow-700' : 'text-gray-600'"
                class="text-sm"
              >
                Minor issues require attention
              </p>
            </div>
          </button>

          <button
            :class="overallResult === 'Fail' ? 'border-red-600 bg-red-50' : 'border-gray-300 hover:border-gray-400 hover:bg-gray-50'"
            class="flex items-center p-4 border-2 rounded-lg transition-all"
            @click="overallResult = 'Fail'"
          >
            <div
              :class="overallResult === 'Fail' ? 'bg-red-600' : 'bg-gray-300'"
              class="flex-shrink-0 w-6 h-6 rounded-full flex items-center justify-center mr-3"
            >
              <svg
                v-if="overallResult === 'Fail'"
                class="h-4 w-4 text-white"
                fill="currentColor"
                viewBox="0 0 20 20"
              >
                <path
                  fill-rule="evenodd"
                  d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                  clip-rule="evenodd"
                />
              </svg>
            </div>
            <div class="flex-1 text-left">
              <p
                :class="overallResult === 'Fail' ? 'text-red-900' : 'text-gray-900'"
                class="font-medium"
              >
                Fail
              </p>
              <p
                :class="overallResult === 'Fail' ? 'text-red-700' : 'text-gray-600'"
                class="text-sm"
              >
                Critical issues found, immediate action required
              </p>
            </div>
          </button>
        </div>
      </div>

      <!-- Final Notes -->
      <div class="bg-white rounded-lg shadow-soft p-6 mb-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">
          Final Notes
        </h3>
        <p class="text-sm text-gray-600 mb-4">
          Add any additional comments or observations
        </p>

        <textarea
          v-model="notes"
          rows="4"
          class="w-full rounded-lg border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
          placeholder="Optional: Add any final notes, observations, or recommendations..."
        />
      </div>

      <!-- Inspector Signature -->
      <div class="bg-white rounded-lg shadow-soft p-6 mb-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">
          Inspector Signature *
        </h3>
        <p class="text-sm text-gray-600 mb-4">
          Confirm your identity to finalize this inspection
        </p>

        <div class="space-y-4">
          <div>
            <label
              for="signature-name"
              class="block text-sm font-medium text-gray-700 mb-1"
            >
              Full Name
            </label>
            <input
              id="signature-name"
              v-model="signature"
              type="text"
              placeholder="Enter your full name"
              class="w-full rounded-lg border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
            >
          </div>

          <div class="flex items-start">
            <input
              id="confirm-accuracy"
              v-model="confirmAccuracy"
              type="checkbox"
              class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded mt-1"
            >
            <label
              for="confirm-accuracy"
              class="ml-2 text-sm text-gray-700"
            >
              I confirm that this inspection was conducted accurately and in accordance with NFPA 10 standards
            </label>
          </div>
        </div>
      </div>

      <!-- Error Message -->
      <div
        v-if="error"
        class="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg"
      >
        <div class="flex">
          <svg
            class="h-5 w-5 text-red-600 mr-2"
            fill="currentColor"
            viewBox="0 0 20 20"
          >
            <path
              fill-rule="evenodd"
              d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
              clip-rule="evenodd"
            />
          </svg>
          <p class="text-sm text-red-800">
            {{ error }}
          </p>
        </div>
      </div>

      <!-- Actions -->
      <div class="space-y-3 mb-6">
        <button
          :disabled="!canComplete || completing"
          class="w-full px-6 py-4 bg-primary-600 text-white rounded-lg font-medium text-lg hover:bg-primary-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition-colors shadow-md"
          @click="completeInspection"
        >
          {{ completing ? 'Completing Inspection...' : 'Complete Inspection' }}
        </button>

        <button
          :disabled="completing"
          class="w-full px-6 py-3 border border-gray-300 rounded-lg text-gray-700 font-medium hover:bg-gray-50 disabled:bg-gray-100 disabled:cursor-not-allowed"
          @click="goBack"
        >
          Back to Checklist
        </button>
      </div>
    </div>

    <!-- Loading State -->
    <div
      v-else-if="loading"
      class="flex items-center justify-center min-h-screen"
    >
      <svg
        class="animate-spin h-12 w-12 text-primary-600"
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
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useInspectionPhase1Store } from '@/stores/inspectionsPhase1'
import { useAuthStore } from '@/stores/auth'
import type { InspectionPhase1Dto } from '@/types/api'

const route = useRoute()
const router = useRouter()
const inspectionStore = useInspectionPhase1Store()
const authStore = useAuthStore()

// State
const inspection = ref<InspectionPhase1Dto | null>(null)
const overallResult = ref<string>('')
const notes = ref<string>('')
const signature = ref<string>('')
const confirmAccuracy = ref<boolean>(false)
const loading = ref(false)
const completing = ref(false)
const error = ref<string | null>(null)

// Computed
const inspectionId = computed(() => route.params.id as string)

const checklistResponsesCount = computed(() => {
  return inspection.value?.checklistResponses?.length || 0
})

const canComplete = computed(() => {
  return (
    overallResult.value !== '' &&
    signature.value.trim() !== '' &&
    confirmAccuracy.value
  )
})

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

const goBack = () => {
  router.push(`/inspections/${inspectionId.value}/checklist`)
}

const completeInspection = async () => {
  if (!canComplete.value) {
    error.value = 'Please fill in all required fields'
    return
  }

  completing.value = true
  error.value = null

  try {
    const completedInspection = await inspectionStore.completeInspection(inspectionId.value, {
      overallResult: overallResult.value,
      notes: notes.value || null,
      inspectorSignature: signature.value
    })

    // Navigate to inspection detail view
    router.push({
      path: `/inspections/${completedInspection.inspectionId}`,
      query: { completed: 'true' }
    })
  } catch (err: any) {
    error.value = err.response?.data?.message || 'Failed to complete inspection'
    console.error('Error completing inspection:', err)
  } finally {
    completing.value = false
  }
}

const loadInspection = async () => {
  loading.value = true
  error.value = null

  try {
    inspection.value = await inspectionStore.fetchInspectionById(inspectionId.value, true)

    // Pre-fill signature with user's name
    if (authStore.user) {
      signature.value = `${authStore.user.firstName} ${authStore.user.lastName}`
    }
  } catch (err: any) {
    error.value = err.response?.data?.message || 'Failed to load inspection'
  } finally {
    loading.value = false
  }
}

// Lifecycle
onMounted(() => {
  loadInspection()
})
</script>
