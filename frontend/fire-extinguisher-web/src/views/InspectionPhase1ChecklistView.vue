<template>
  <div class="min-h-screen bg-gray-50 pb-24">
    <!-- Mobile Header -->
    <div class="bg-white border-b border-gray-200 sticky top-0 z-10">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex items-center justify-between h-16">
          <router-link
            :to="`/inspections/${inspection?.inspectionId}`"
            class="flex items-center text-gray-600 hover:text-gray-900"
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
          </router-link>
          <h1 class="text-lg font-semibold text-gray-900">
            Inspection Checklist
          </h1>
          <button
            class="text-sm text-primary-600 font-medium"
            @click="showProgress = true"
          >
            {{ completedItems }} / {{ totalItems }}
          </button>
        </div>
      </div>

      <!-- Progress Bar -->
      <div class="w-full bg-gray-200 h-1">
        <div
          class="bg-primary-600 h-1 transition-all duration-300"
          :style="{ width: `${progressPercent}%` }"
        />
      </div>
    </div>

    <!-- Main Content -->
    <div
      v-if="inspection && checklistItems.length > 0"
      class="max-w-2xl mx-auto px-4 py-6"
    >
      <!-- Inspection Info Card -->
      <div class="bg-white rounded-lg shadow-soft p-4 mb-6">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-600">
              Extinguisher
            </p>
            <p class="font-medium text-gray-900">
              {{ inspection.extinguisherAssetTag || inspection.extinguisherCode }}
            </p>
            <p class="text-xs text-gray-500">
              {{ inspection.locationName }}
            </p>
          </div>
          <div class="text-right">
            <p class="text-sm text-gray-600">
              Type
            </p>
            <p class="font-medium text-gray-900">
              {{ inspection.inspectionType }}
            </p>
          </div>
        </div>
      </div>

      <!-- Checklist Items -->
      <div class="space-y-4">
        <div
          v-for="(item, index) in checklistItems"
          :key="item.itemId"
          class="bg-white rounded-lg shadow-soft p-6 animate-slide-up"
        >
          <!-- Item Header -->
          <div class="flex items-start mb-4">
            <div class="flex-shrink-0 w-8 h-8 rounded-full bg-primary-100 text-primary-700 flex items-center justify-center font-semibold text-sm">
              {{ item.itemNumber }}
            </div>
            <div class="ml-3 flex-1">
              <h3 class="text-base font-medium text-gray-900">
                {{ item.itemText }}
              </h3>
              <p class="text-xs text-gray-500 mt-1">
                {{ item.itemCategory }}
              </p>
              <div class="flex items-center mt-2 space-x-2">
                <span
                  v-if="item.requiresPhoto"
                  class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800"
                >
                  <svg
                    class="h-3 w-3 mr-1"
                    fill="currentColor"
                    viewBox="0 0 20 20"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M4 3a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V5a2 2 0 00-2-2H4zm12 12H4l4-8 3 6 2-4 3 6z"
                      clip-rule="evenodd"
                    />
                  </svg>
                  Photo
                </span>
                <span
                  v-if="item.isRequired"
                  class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-red-100 text-red-800"
                >
                  Required
                </span>
              </div>
            </div>
          </div>

          <!-- Response Buttons -->
          <div class="grid grid-cols-3 gap-3 mb-4">
            <button
              v-for="response in getAllowedResponses(item)"
              :key="response"
              :class="getResponseButtonClass(item, response)"
              class="flex flex-col items-center justify-center py-3 px-2 rounded-lg border-2 transition-all text-sm font-medium"
              @click="setResponse(item, response)"
            >
              <svg
                class="h-6 w-6 mb-1"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  v-if="response === 'Pass'"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M5 13l4 4L19 7"
                />
                <path
                  v-else-if="response === 'Fail'"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M6 18L18 6M6 6l12 12"
                />
                <path
                  v-else
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M20 12H4"
                />
              </svg>
              {{ response }}
            </button>
          </div>

          <!-- Comment Field -->
          <div
            v-if="item.requiresComment || responses[item.itemId]?.response === 'Fail'"
            class="mb-4"
          >
            <label
              :for="`comment-${item.itemId}`"
              class="block text-sm font-medium text-gray-700 mb-1"
            >
              {{ responses[item.itemId]?.response === 'Fail' ? 'Why did this fail?' : 'Comment' }}
              <span
                v-if="item.requiresComment"
                class="text-red-600"
              >*</span>
            </label>
            <textarea
              :id="`comment-${item.itemId}`"
              v-model="responses[item.itemId].comment"
              rows="2"
              class="w-full rounded-lg border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 text-sm"
              :placeholder="responses[item.itemId]?.response === 'Fail' ? 'Describe the issue...' : 'Optional comment...'"
            />
          </div>

          <!-- Photo Upload -->
          <div v-if="item.requiresPhoto || responses[item.itemId]?.photoId">
            <button
              class="w-full flex items-center justify-center px-4 py-2 border border-dashed border-gray-300 rounded-lg text-sm text-gray-600 hover:border-primary-500 hover:bg-primary-50 transition-colors"
              @click="openPhotoCapture(item)"
            >
              <svg
                class="h-5 w-5 mr-2"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z"
                />
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M15 13a3 3 0 11-6 0 3 3 0 016 0z"
                />
              </svg>
              {{ responses[item.itemId]?.photoId ? 'Change Photo' : 'Take Photo' }}
              <span
                v-if="item.requiresPhoto"
                class="ml-1 text-red-600"
              >*</span>
            </button>
            <p
              v-if="responses[item.itemId]?.photoId"
              class="text-xs text-green-600 mt-1 text-center"
            >
              ✓ Photo captured
            </p>
          </div>
        </div>
      </div>

      <!-- Auto-save Indicator -->
      <div
        v-if="saving"
        class="mt-4 flex items-center justify-center text-sm text-gray-600"
      >
        <svg
          class="animate-spin h-4 w-4 mr-2"
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
        Saving...
      </div>

      <p
        v-else-if="lastSaved"
        class="mt-4 text-center text-sm text-gray-500"
      >
        Last saved {{ lastSaved }}
      </p>
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

    <!-- Error State -->
    <div
      v-else-if="error"
      class="max-w-2xl mx-auto px-4 py-12"
    >
      <div class="bg-red-50 border border-red-200 rounded-lg p-6 text-center">
        <p class="text-red-800">
          {{ error }}
        </p>
        <button
          class="mt-4 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700"
          @click="loadInspection"
        >
          Retry
        </button>
      </div>
    </div>

    <!-- Bottom Action Bar -->
    <div
      v-if="inspection"
      class="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 z-10"
    >
      <div class="max-w-2xl mx-auto px-4 py-3">
        <button
          :disabled="!canComplete || completing"
          class="w-full px-6 py-3 bg-primary-600 text-white rounded-lg font-medium hover:bg-primary-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition-colors shadow-sm"
          @click="completeInspection"
        >
          {{ completing ? 'Completing...' : canComplete ? 'Complete Inspection' : `Complete ${completedItems}/${totalItems} Items` }}
        </button>
      </div>
    </div>

    <!-- Progress Modal -->
    <div
      v-if="showProgress"
      class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4"
      @click="showProgress = false"
    >
      <div
        class="bg-white rounded-lg p-6 max-w-sm w-full"
        @click.stop
      >
        <h3 class="text-lg font-semibold text-gray-900 mb-4">
          Inspection Progress
        </h3>
        <div class="space-y-3">
          <div class="flex items-center justify-between">
            <span class="text-sm text-gray-600">Completed</span>
            <span class="text-sm font-medium text-gray-900">{{ completedItems }} / {{ totalItems }}</span>
          </div>
          <div class="w-full bg-gray-200 rounded-full h-2">
            <div
              class="bg-primary-600 h-2 rounded-full transition-all"
              :style="{ width: `${progressPercent}%` }"
            />
          </div>
          <div class="flex items-center justify-between text-xs text-gray-500">
            <span>{{ progressPercent }}% Complete</span>
            <span>{{ totalItems - completedItems }} remaining</span>
          </div>
        </div>
        <button
          class="mt-6 w-full px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200"
          @click="showProgress = false"
        >
          Close
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useInspectionPhase1Store } from '@/stores/inspectionsPhase1'
import { useChecklistTemplateStore } from '@/stores/checklistTemplates'
import type { ChecklistItemDto, InspectionPhase1Dto } from '@/types/api'

const route = useRoute()
const router = useRouter()
const inspectionStore = useInspectionPhase1Store()
const templateStore = useChecklistTemplateStore()

// State
const inspection = ref<InspectionPhase1Dto | null>(null)
const checklistItems = ref<ChecklistItemDto[]>([])
const responses = ref<Record<string, { response: string; comment: string | null; photoId: string | null }>>({})
const loading = ref(false)
const saving = ref(false)
const completing = ref(false)
const error = ref<string | null>(null)
const lastSaved = ref<string | null>(null)
const showProgress = ref(false)

// Computed
const inspectionId = computed(() => route.params.id as string)

const totalItems = computed(() => checklistItems.value.length)

const completedItems = computed(() => {
  return Object.keys(responses.value).filter(itemId => {
    const response = responses.value[itemId]
    const item = checklistItems.value.find(i => i.itemId === itemId)
    if (!item) return false

    // Must have response
    if (!response.response) return false

    // If requires comment, must have comment
    if (item.requiresComment && !response.comment) return false

    // If requires photo, must have photo
    if (item.requiresPhoto && !response.photoId) return false

    // If failed, must have comment
    if (response.response === 'Fail' && !response.comment) return false

    return true
  }).length
})

const progressPercent = computed(() => {
  if (totalItems.value === 0) return 0
  return Math.round((completedItems.value / totalItems.value) * 100)
})

const canComplete = computed(() => {
  return completedItems.value === totalItems.value && totalItems.value > 0
})

// Methods
const getAllowedResponses = (item: ChecklistItemDto): string[] => {
  try {
    const allowed = JSON.parse(item.allowedResponses)
    return Array.isArray(allowed) ? allowed : ['Pass', 'Fail', 'N/A']
  } catch {
    return ['Pass', 'Fail', 'N/A']
  }
}

const getResponseButtonClass = (item: ChecklistItemDto, response: string): string => {
  const selected = responses.value[item.itemId]?.response === response

  if (selected) {
    if (response === 'Pass') return 'border-green-600 bg-green-50 text-green-700'
    if (response === 'Fail') return 'border-red-600 bg-red-50 text-red-700'
    return 'border-gray-600 bg-gray-50 text-gray-700'
  }

  return 'border-gray-300 text-gray-600 hover:border-gray-400 hover:bg-gray-50'
}

const setResponse = (item: ChecklistItemDto, response: string) => {
  if (!responses.value[item.itemId]) {
    responses.value[item.itemId] = {
      response,
      comment: null,
      photoId: null
    }
  } else {
    responses.value[item.itemId].response = response
  }

  // Auto-save after 1 second
  setTimeout(() => saveResponses(), 1000)
}

const saveResponses = async () => {
  if (saving.value) return

  saving.value = true
  error.value = null

  try {
    const responsesToSave = Object.keys(responses.value)
      .filter(itemId => responses.value[itemId].response)
      .map(itemId => ({
        checklistItemId: itemId,
        response: responses.value[itemId].response,
        comment: responses.value[itemId].comment || null,
        photoId: responses.value[itemId].photoId || null
      }))

    if (responsesToSave.length > 0) {
      await inspectionStore.saveChecklistResponses(inspectionId.value, {
        responses: responsesToSave
      })

      lastSaved.value = new Date().toLocaleTimeString()
    }
  } catch (err: any) {
    error.value = 'Failed to save responses'
    console.error('Error saving responses:', err)
  } finally {
    saving.value = false
  }
}

const openPhotoCapture = (item: ChecklistItemDto) => {
  // TODO: Open photo capture component
  // For now, navigate to photo capture view
  router.push({
    path: `/inspections/${inspectionId.value}/photo`,
    query: { itemId: item.itemId }
  })
}

const completeInspection = async () => {
  if (!canComplete.value) return

  completing.value = true
  error.value = null

  try {
    // Save any unsaved responses first
    await saveResponses()

    // Navigate to completion screen
    router.push(`/inspections/${inspectionId.value}/complete`)
  } catch (err: any) {
    error.value = 'Failed to proceed to completion'
  } finally {
    completing.value = false
  }
}

const loadInspection = async () => {
  loading.value = true
  error.value = null

  try {
    // Fetch inspection
    inspection.value = await inspectionStore.fetchInspectionById(inspectionId.value, true)

    // Fetch checklist items for template
    if (inspection.value.templateId) {
      checklistItems.value = await templateStore.fetchTemplateItems(inspection.value.templateId)
    }

    // Initialize responses from existing data
    if (inspection.value.checklistResponses) {
      inspection.value.checklistResponses.forEach(resp => {
        responses.value[resp.checklistItemId] = {
          response: resp.response,
          comment: resp.comment || null,
          photoId: resp.photoId || null
        }
      })
    } else {
      // Initialize empty responses for each item
      checklistItems.value.forEach(item => {
        if (!responses.value[item.itemId]) {
          responses.value[item.itemId] = {
            response: '',
            comment: null,
            photoId: null
          }
        }
      })
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

// Watch for responses changes to trigger auto-save
watch(
  responses,
  () => {
    // Debounced auto-save handled in setResponse
  },
  { deep: true }
)
</script>
