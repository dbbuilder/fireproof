<template>
  <AppLayout>
    <!-- Page Header -->
    <div class="mb-8">
      <h1 data-testid="import-heading" class="text-3xl font-bold text-gray-900">
        Import Historical Data
      </h1>
      <p class="mt-2 text-gray-600">
        Import past inspection records from CSV files to establish compliance history
      </p>
    </div>

    <!-- Historical Import Status Warning -->
    <div
      v-if="!importStore.canImportHistoricalData"
      class="mb-6 p-4 bg-yellow-50 border border-yellow-200 rounded-lg"
      data-testid="historical-import-disabled-warning"
    >
      <div class="flex items-start">
        <ExclamationTriangleIcon class="h-6 w-6 text-yellow-600 mt-0.5" />
        <div class="ml-3">
          <h3 class="text-sm font-medium text-yellow-800">Historical Imports Disabled</h3>
          <p class="mt-1 text-sm text-yellow-700">
            Historical data imports have been permanently disabled for this tenant. This cannot be
            undone.
          </p>
        </div>
      </div>
    </div>

    <!-- Step Progress -->
    <div class="mb-8">
      <nav aria-label="Progress" data-testid="import-progress">
        <ol role="list" class="flex items-center">
          <li
            v-for="(step, index) in steps"
            :key="step.name"
            :class="[
              index !== steps.length - 1 ? 'pr-8 sm:pr-20' : '',
              'relative'
            ]"
          >
            <!-- Step connector line -->
            <div
              v-if="index !== steps.length - 1"
              class="absolute top-4 left-4 -ml-px mt-0.5 h-full w-0.5"
              :class="step.status === 'complete' ? 'bg-blue-600' : 'bg-gray-300'"
              aria-hidden="true"
            />

            <div class="group relative flex items-start">
              <!-- Step number/check -->
              <span class="flex h-9 items-center">
                <span
                  class="relative z-10 flex h-8 w-8 items-center justify-center rounded-full"
                  :class="{
                    'bg-blue-600': step.status === 'complete',
                    'bg-white border-2 border-blue-600': step.status === 'current',
                    'bg-white border-2 border-gray-300': step.status === 'upcoming'
                  }"
                >
                  <CheckIcon
                    v-if="step.status === 'complete'"
                    class="h-5 w-5 text-white"
                    aria-hidden="true"
                  />
                  <span
                    v-else
                    class="text-sm font-medium"
                    :class="{
                      'text-blue-600': step.status === 'current',
                      'text-gray-500': step.status === 'upcoming'
                    }"
                  >
                    {{ index + 1 }}
                  </span>
                </span>
              </span>
              <span class="ml-4 flex min-w-0 flex-col">
                <span
                  class="text-sm font-medium"
                  :class="{
                    'text-blue-600': step.status === 'current',
                    'text-gray-900': step.status === 'complete',
                    'text-gray-500': step.status === 'upcoming'
                  }"
                >
                  {{ step.name }}
                </span>
                <span class="text-sm text-gray-500">{{ step.description }}</span>
              </span>
            </div>
          </li>
        </ol>
      </nav>
    </div>

    <!-- Step 1: Upload File -->
    <div v-if="currentStep === 1" data-testid="step-upload">
      <div class="bg-white shadow sm:rounded-lg p-6">
        <h2 class="text-lg font-medium text-gray-900 mb-4">Upload CSV File</h2>

        <!-- File upload area -->
        <div
          class="mt-4 flex justify-center px-6 pt-5 pb-6 border-2 border-gray-300 border-dashed rounded-lg hover:border-gray-400 transition-colors cursor-pointer"
          :class="{ 'border-blue-500 bg-blue-50': isDragging }"
          @dragover.prevent="isDragging = true"
          @dragleave.prevent="isDragging = false"
          @drop.prevent="handleFileDrop"
          @click="$refs.fileInput.click()"
          data-testid="file-upload-area"
        >
          <div class="space-y-1 text-center">
            <ArrowUpTrayIcon class="mx-auto h-12 w-12 text-gray-400" />
            <div class="flex text-sm text-gray-600">
              <span class="font-medium text-blue-600 hover:text-blue-500">Upload a file</span>
              <span class="pl-1">or drag and drop</span>
            </div>
            <p class="text-xs text-gray-500">CSV files up to 10MB</p>
          </div>
          <input
            ref="fileInput"
            type="file"
            class="sr-only"
            accept=".csv"
            @change="handleFileSelect"
            data-testid="file-input"
          />
        </div>

        <!-- Upload progress -->
        <div
          v-if="importStore.isUploading"
          class="mt-4"
          data-testid="upload-progress"
        >
          <div class="flex justify-between text-sm text-gray-600 mb-2">
            <span>Uploading...</span>
            <span>{{ importStore.uploadProgress }}%</span>
          </div>
          <div class="w-full bg-gray-200 rounded-full h-2">
            <div
              class="bg-blue-600 h-2 rounded-full transition-all duration-300"
              :style="{ width: importStore.uploadProgress + '%' }"
            />
          </div>
        </div>

        <!-- Upload error -->
        <div
          v-if="importStore.error && currentStep === 1"
          class="mt-4 p-4 bg-red-50 rounded-lg"
          data-testid="upload-error"
        >
          <p class="text-sm text-red-800">{{ importStore.error }}</p>
        </div>

        <!-- File info after upload -->
        <div
          v-if="importStore.uploadedFileInfo"
          class="mt-6"
          data-testid="file-info"
        >
          <h3 class="text-sm font-medium text-gray-900 mb-2">File Information</h3>
          <dl class="grid grid-cols-1 gap-x-4 gap-y-4 sm:grid-cols-2">
            <div>
              <dt class="text-sm font-medium text-gray-500">File Name</dt>
              <dd class="mt-1 text-sm text-gray-900" data-testid="file-name">
                {{ importStore.uploadedFileInfo.fileName }}
              </dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">File Size</dt>
              <dd class="mt-1 text-sm text-gray-900" data-testid="file-size">
                {{ formatFileSize(importStore.uploadedFileInfo.fileSize) }}
              </dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Total Rows</dt>
              <dd class="mt-1 text-sm text-gray-900" data-testid="total-rows">
                {{ importStore.uploadedFileInfo.totalRows }}
              </dd>
            </div>
          </dl>

          <div class="mt-4 flex justify-end">
            <button
              @click="nextStep"
              class="btn btn-primary"
              data-testid="next-to-mapping-button"
            >
              Next: Map Fields
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Step 2: Field Mapping -->
    <div v-if="currentStep === 2" data-testid="step-mapping">
      <div class="bg-white shadow sm:rounded-lg p-6">
        <div class="flex justify-between items-center mb-4">
          <h2 class="text-lg font-medium text-gray-900">Map CSV Fields</h2>

          <!-- Mapping templates -->
          <div class="flex items-center space-x-2">
            <select
              v-model="selectedTemplateId"
              @change="applyTemplate"
              class="input"
              data-testid="template-select"
            >
              <option :value="null">Select template...</option>
              <option
                v-for="template in importStore.mappingTemplates"
                :key="template.mappingTemplateId"
                :value="template.mappingTemplateId"
              >
                {{ template.templateName }}
              </option>
            </select>
            <button
              @click="showSaveTemplateModal = true"
              class="btn btn-secondary text-sm"
              data-testid="save-template-button"
            >
              Save as Template
            </button>
          </div>
        </div>

        <p class="text-sm text-gray-600 mb-4">
          Map the columns from your CSV file to the FireProof database fields.
          Required fields are marked with an asterisk (*).
        </p>

        <!-- Field mapping table -->
        <div class="overflow-x-auto" data-testid="field-mapping-table">
          <table class="min-w-full divide-y divide-gray-300">
            <thead>
              <tr>
                <th class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                  CSV Column
                </th>
                <th class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                  FireProof Field
                </th>
                <th class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                  Sample Value
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
              <tr
                v-for="(mapping, index) in importStore.fieldMappings"
                :key="mapping.sourceField"
                :data-testid="`mapping-row-${index}`"
              >
                <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-900">
                  {{ mapping.sourceField }}
                </td>
                <td class="px-3 py-4 text-sm">
                  <select
                    v-model="mapping.destinationField"
                    class="input w-full"
                    :data-testid="`destination-select-${index}`"
                  >
                    <option value="">-- Skip this field --</option>
                    <option value="ExtinguisherBarcode">Extinguisher Barcode *</option>
                    <option value="InspectionDate">Inspection Date *</option>
                    <option value="InspectorName">Inspector Name *</option>
                    <option value="InspectionType">Inspection Type *</option>
                    <option value="PassFail">Pass/Fail *</option>
                    <option value="Notes">Notes</option>
                    <option value="LocationName">Location Name</option>
                    <option value="SerialNumber">Serial Number</option>
                    <option value="Manufacturer">Manufacturer</option>
                    <option value="ExtinguisherType">Extinguisher Type</option>
                    <option value="Weight">Weight</option>
                    <option value="LastHydroTestDate">Last Hydro Test Date</option>
                    <option value="ManufactureDate">Manufacture Date</option>
                  </select>
                </td>
                <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                  {{ getSampleValue(mapping.sourceField) }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Navigation buttons -->
        <div class="mt-6 flex justify-between">
          <button
            @click="previousStep"
            class="btn btn-secondary"
            data-testid="back-to-upload-button"
          >
            Back
          </button>
          <button
            @click="validateAndPreview"
            class="btn btn-primary"
            :disabled="!hasRequiredMappings"
            data-testid="validate-button"
          >
            Validate & Preview
          </button>
        </div>
      </div>
    </div>

    <!-- Step 3: Validation & Preview -->
    <div v-if="currentStep === 3" data-testid="step-validation">
      <div class="bg-white shadow sm:rounded-lg p-6">
        <h2 class="text-lg font-medium text-gray-900 mb-4">Validation Results</h2>

        <!-- Validation in progress -->
        <div
          v-if="importStore.isValidating"
          class="text-center py-8"
          data-testid="validation-progress"
        >
          <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" />
          <p class="mt-2 text-sm text-gray-600">Validating data...</p>
        </div>

        <!-- Validation summary -->
        <div
          v-if="importStore.validationSummary && !importStore.isValidating"
          data-testid="validation-summary"
        >
          <!-- Summary cards -->
          <div class="grid grid-cols-1 gap-5 sm:grid-cols-4 mb-6">
            <div class="bg-white overflow-hidden shadow rounded-lg">
              <div class="p-5">
                <div class="flex items-center">
                  <div class="flex-shrink-0">
                    <DocumentTextIcon class="h-6 w-6 text-gray-400" />
                  </div>
                  <div class="ml-5 w-0 flex-1">
                    <dl>
                      <dt class="text-sm font-medium text-gray-500 truncate">Total Rows</dt>
                      <dd class="text-lg font-semibold text-gray-900" data-testid="summary-total">
                        {{ importStore.validationSummary.totalRows }}
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>

            <div class="bg-white overflow-hidden shadow rounded-lg">
              <div class="p-5">
                <div class="flex items-center">
                  <div class="flex-shrink-0">
                    <CheckCircleIcon class="h-6 w-6 text-green-500" />
                  </div>
                  <div class="ml-5 w-0 flex-1">
                    <dl>
                      <dt class="text-sm font-medium text-gray-500 truncate">Valid Rows</dt>
                      <dd class="text-lg font-semibold text-green-600" data-testid="summary-valid">
                        {{ importStore.validationSummary.validRows }}
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>

            <div class="bg-white overflow-hidden shadow rounded-lg">
              <div class="p-5">
                <div class="flex items-center">
                  <div class="flex-shrink-0">
                    <XCircleIcon class="h-6 w-6 text-red-500" />
                  </div>
                  <div class="ml-5 w-0 flex-1">
                    <dl>
                      <dt class="text-sm font-medium text-gray-500 truncate">Invalid Rows</dt>
                      <dd class="text-lg font-semibold text-red-600" data-testid="summary-invalid">
                        {{ importStore.validationSummary.invalidRows }}
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>

            <div class="bg-white overflow-hidden shadow rounded-lg">
              <div class="p-5">
                <div class="flex items-center">
                  <div class="flex-shrink-0">
                    <ExclamationTriangleIcon class="h-6 w-6 text-yellow-500" />
                  </div>
                  <div class="ml-5 w-0 flex-1">
                    <dl>
                      <dt class="text-sm font-medium text-gray-500 truncate">Warnings</dt>
                      <dd class="text-lg font-semibold text-yellow-600" data-testid="summary-warnings">
                        {{ importStore.validationSummary.rowsWithWarnings }}
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Can proceed or has errors -->
          <div
            v-if="!importStore.validationSummary.canProceed"
            class="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg"
            data-testid="validation-errors"
          >
            <div class="flex">
              <XCircleIcon class="h-5 w-5 text-red-400" />
              <div class="ml-3">
                <h3 class="text-sm font-medium text-red-800">Cannot proceed with import</h3>
                <p class="mt-1 text-sm text-red-700">
                  Please fix the errors below before importing.
                </p>
              </div>
            </div>
          </div>

          <div
            v-else-if="importStore.validationSummary.hasWarnings"
            class="mb-6 p-4 bg-yellow-50 border border-yellow-200 rounded-lg"
            data-testid="validation-warnings"
          >
            <div class="flex">
              <ExclamationTriangleIcon class="h-5 w-5 text-yellow-400" />
              <div class="ml-3">
                <h3 class="text-sm font-medium text-yellow-800">Warnings detected</h3>
                <p class="mt-1 text-sm text-yellow-700">
                  Some rows have warnings. Review them before proceeding.
                </p>
              </div>
            </div>
          </div>

          <!-- Validation details (first 10 rows with errors/warnings) -->
          <div v-if="rowsWithIssues.length > 0" class="mb-6">
            <h3 class="text-sm font-medium text-gray-900 mb-2">Rows with Issues</h3>
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-300" data-testid="issues-table">
                <thead>
                  <tr>
                    <th class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">Row</th>
                    <th class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">Status</th>
                    <th class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">Issues</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-200">
                  <tr v-for="row in rowsWithIssues.slice(0, 10)" :key="row.rowNumber">
                    <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-900">
                      {{ row.rowNumber }}
                    </td>
                    <td class="whitespace-nowrap px-3 py-4 text-sm">
                      <span
                        v-if="!row.isValid"
                        class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800"
                      >
                        Error
                      </span>
                      <span
                        v-else
                        class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800"
                      >
                        Warning
                      </span>
                    </td>
                    <td class="px-3 py-4 text-sm text-gray-500">
                      <ul class="list-disc list-inside">
                        <li v-for="(error, idx) in row.errors" :key="`error-${idx}`" class="text-red-700">
                          {{ error }}
                        </li>
                        <li v-for="(warning, idx) in row.warnings" :key="`warning-${idx}`" class="text-yellow-700">
                          {{ warning }}
                        </li>
                      </ul>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
            <p v-if="rowsWithIssues.length > 10" class="mt-2 text-sm text-gray-500">
              Showing first 10 of {{ rowsWithIssues.length }} rows with issues
            </p>
          </div>

          <!-- Navigation buttons -->
          <div class="flex justify-between">
            <button
              @click="previousStep"
              class="btn btn-secondary"
              data-testid="back-to-mapping-button"
            >
              Back to Mapping
            </button>
            <button
              @click="startImport"
              class="btn btn-primary"
              :disabled="!importStore.validationSummary.canProceed || importStore.isImporting"
              data-testid="start-import-button"
            >
              {{ importStore.isImporting ? 'Importing...' : 'Start Import' }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Step 4: Import Complete -->
    <div v-if="currentStep === 4" data-testid="step-complete">
      <div class="bg-white shadow sm:rounded-lg p-6 text-center">
        <CheckCircleIcon class="mx-auto h-12 w-12 text-green-500" />
        <h2 class="mt-4 text-lg font-medium text-gray-900">Import Started</h2>
        <p class="mt-2 text-sm text-gray-600">
          Your import job has been created and is being processed in the background.
        </p>
        <div class="mt-6 flex justify-center space-x-4">
          <button
            @click="resetImport"
            class="btn btn-secondary"
            data-testid="new-import-button"
          >
            Start New Import
          </button>
          <button
            @click="viewImportHistory"
            class="btn btn-primary"
            data-testid="view-history-button"
          >
            View Import History
          </button>
        </div>
      </div>
    </div>

    <!-- Save Template Modal -->
    <Teleport to="body">
      <div
        v-if="showSaveTemplateModal"
        class="fixed inset-0 z-50 overflow-y-auto"
        data-testid="save-template-modal"
      >
        <div class="flex min-h-screen items-center justify-center p-4">
          <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" @click="showSaveTemplateModal = false" />

          <div class="relative transform overflow-hidden rounded-lg bg-white px-4 pb-4 pt-5 text-left shadow-xl sm:my-8 sm:w-full sm:max-w-lg sm:p-6">
            <div>
              <h3 class="text-lg font-medium leading-6 text-gray-900">Save Mapping Template</h3>
              <div class="mt-4">
                <label class="block text-sm font-medium text-gray-700">Template Name</label>
                <input
                  v-model="newTemplateName"
                  type="text"
                  class="mt-1 input w-full"
                  placeholder="e.g., Monthly Inspections Template"
                  data-testid="template-name-input"
                />
              </div>
              <div class="mt-4">
                <label class="flex items-center">
                  <input
                    v-model="makeTemplateDefault"
                    type="checkbox"
                    class="checkbox"
                    data-testid="default-template-checkbox"
                  />
                  <span class="ml-2 text-sm text-gray-700">Set as default template</span>
                </label>
              </div>
            </div>
            <div class="mt-5 sm:mt-6 sm:grid sm:grid-flow-row-dense sm:grid-cols-2 sm:gap-3">
              <button
                @click="saveTemplate"
                class="btn btn-primary"
                :disabled="!newTemplateName"
                data-testid="save-template-confirm-button"
              >
                Save Template
              </button>
              <button
                @click="showSaveTemplateModal = false"
                class="btn btn-secondary"
                data-testid="save-template-cancel-button"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </AppLayout>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useImportStore } from '@/stores/imports'
import AppLayout from '@/components/layout/AppLayout.vue'
import {
  ArrowUpTrayIcon,
  CheckIcon,
  CheckCircleIcon,
  XCircleIcon,
  ExclamationTriangleIcon,
  DocumentTextIcon
} from '@heroicons/vue/24/outline'

const router = useRouter()
const importStore = useImportStore()

// State
const currentStep = ref(1)
const isDragging = ref(false)
const selectedTemplateId = ref(null)
const showSaveTemplateModal = ref(false)
const newTemplateName = ref('')
const makeTemplateDefault = ref(false)
const fileInput = ref(null)

// Steps configuration
const steps = computed(() => [
  {
    name: 'Upload',
    description: 'Select CSV file',
    status: currentStep.value > 1 ? 'complete' : currentStep.value === 1 ? 'current' : 'upcoming'
  },
  {
    name: 'Map Fields',
    description: 'Map columns to fields',
    status: currentStep.value > 2 ? 'complete' : currentStep.value === 2 ? 'current' : 'upcoming'
  },
  {
    name: 'Validate',
    description: 'Preview and validate',
    status: currentStep.value > 3 ? 'complete' : currentStep.value === 3 ? 'current' : 'upcoming'
  },
  {
    name: 'Complete',
    description: 'Import data',
    status: currentStep.value === 4 ? 'current' : 'upcoming'
  }
])

// Computed
const hasRequiredMappings = computed(() => {
  const requiredFields = ['ExtinguisherBarcode', 'InspectionDate', 'InspectorName', 'InspectionType', 'PassFail']
  const mappedFields = importStore.fieldMappings.map((m) => m.destinationField)
  return requiredFields.every((field) => mappedFields.includes(field))
})

const rowsWithIssues = computed(() => {
  if (!importStore.validationResults) return []
  return importStore.validationResults.results.filter(
    (r) => !r.isValid || r.warnings.length > 0
  )
})

// Lifecycle
onMounted(async () => {
  await importStore.fetchHistoricalImportStatus()
  await importStore.fetchMappingTemplates('HistoricalInspections')
})

// Methods
function handleFileSelect(event) {
  const file = event.target.files[0]
  if (file) {
    uploadFile(file)
  }
}

function handleFileDrop(event) {
  isDragging.value = false
  const file = event.dataTransfer.files[0]
  if (file) {
    uploadFile(file)
  }
}

async function uploadFile(file) {
  try {
    await importStore.uploadFile(file, 'HistoricalInspections')
  } catch (error) {
    console.error('Upload error:', error)
  }
}

function getSampleValue(sourceField) {
  if (!importStore.previewRows || importStore.previewRows.length === 0) return ''
  return importStore.previewRows[0][sourceField] || ''
}

function formatFileSize(bytes) {
  if (bytes < 1024) return bytes + ' B'
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(2) + ' KB'
  return (bytes / (1024 * 1024)).toFixed(2) + ' MB'
}

function nextStep() {
  if (currentStep.value < 4) {
    currentStep.value++
  }
}

function previousStep() {
  if (currentStep.value > 1) {
    currentStep.value--
  }
}

async function validateAndPreview() {
  try {
    // Use preview rows for validation (in production, would use full dataset)
    const rows = importStore.previewRows
    await importStore.validateImportData('HistoricalInspections', rows)
    nextStep()
  } catch (error) {
    console.error('Validation error:', error)
  }
}

async function startImport() {
  try {
    await importStore.createImportJob('HistoricalInspections', false)
    nextStep()
  } catch (error) {
    console.error('Import error:', error)
  }
}

function applyTemplate() {
  if (selectedTemplateId.value) {
    const template = importStore.mappingTemplates.find(
      (t) => t.mappingTemplateId === selectedTemplateId.value
    )
    if (template) {
      importStore.applyMappingTemplate(template)
    }
  }
}

async function saveTemplate() {
  if (!newTemplateName.value) return

  try {
    await importStore.saveMappingTemplate(
      newTemplateName.value,
      'HistoricalInspections',
      makeTemplateDefault.value
    )
    showSaveTemplateModal.value = false
    newTemplateName.value = ''
    makeTemplateDefault.value = false
  } catch (error) {
    console.error('Save template error:', error)
  }
}

function resetImport() {
  importStore.resetUploadState()
  currentStep.value = 1
  selectedTemplateId.value = null
}

function viewImportHistory() {
  router.push('/import-history')
}
</script>

<style scoped>
.btn {
  @apply px-4 py-2 rounded-lg font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2;
}

.btn-primary {
  @apply bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed;
}

.btn-secondary {
  @apply bg-white text-gray-700 border border-gray-300 hover:bg-gray-50 focus:ring-blue-500;
}

.input {
  @apply block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm;
}

.checkbox {
  @apply h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500;
}
</style>
