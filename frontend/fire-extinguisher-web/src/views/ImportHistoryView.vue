<template>
  <AppLayout>
    <!-- Page Header -->
    <div class="mb-8 flex justify-between items-center">
      <div>
        <h1
          data-testid="import-history-heading"
          class="text-3xl font-bold text-gray-900"
        >
          Import History
        </h1>
        <p class="mt-2 text-gray-600">
          View past data imports and their status
        </p>
      </div>
      <button
        class="btn btn-primary"
        data-testid="new-import-button"
        @click="$router.push('/import-data')"
      >
        <ArrowUpTrayIcon class="h-5 w-5 mr-2 inline-block" />
        New Import
      </button>
    </div>

    <!-- Filters -->
    <div class="bg-white shadow sm:rounded-lg p-4 mb-6">
      <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <div>
          <label class="block text-sm font-medium text-gray-700">Job Type</label>
          <select
            v-model="filterJobType"
            class="mt-1 input w-full"
            data-testid="job-type-filter"
            @change="loadImportHistory"
          >
            <option :value="null">
              All Types
            </option>
            <option value="HistoricalInspections">
              Historical Inspections
            </option>
            <option value="Locations">
              Locations
            </option>
            <option value="Extinguishers">
              Extinguishers
            </option>
          </select>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700">Page Size</label>
          <select
            v-model="pageSize"
            class="mt-1 input w-full"
            data-testid="page-size-select"
            @change="changePageSize"
          >
            <option :value="10">
              10 per page
            </option>
            <option :value="25">
              25 per page
            </option>
            <option :value="50">
              50 per page
            </option>
            <option :value="100">
              100 per page
            </option>
          </select>
        </div>

        <div class="flex items-end">
          <button
            class="btn btn-secondary w-full"
            :disabled="importStore.isLoading"
            data-testid="refresh-button"
            @click="loadImportHistory"
          >
            <ArrowPathIcon class="h-5 w-5 mr-2 inline-block" />
            Refresh
          </button>
        </div>
      </div>
    </div>

    <!-- Loading State -->
    <div
      v-if="importStore.isLoading"
      class="text-center py-12"
      data-testid="loading-state"
    >
      <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" />
      <p class="mt-2 text-sm text-gray-600">
        Loading import history...
      </p>
    </div>

    <!-- Import Jobs Table -->
    <div
      v-else-if="importStore.importJobs.length > 0"
      class="bg-white shadow overflow-hidden sm:rounded-lg"
      data-testid="import-jobs-table"
    >
      <table class="min-w-full divide-y divide-gray-300">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Job Type
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              File Name
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Status
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Progress
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Date
            </th>
            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
              Actions
            </th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <tr
            v-for="job in importStore.importJobs"
            :key="job.importJobId"
            data-testid="import-job-row"
          >
            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
              {{ job.jobType }}
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
              <div class="flex items-center">
                <DocumentTextIcon class="h-5 w-5 text-gray-400 mr-2" />
                {{ job.fileName }}
              </div>
            </td>
            <td class="px-6 py-4 whitespace-nowrap">
              <span
                class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                :class="getStatusClass(job.status)"
                data-testid="job-status"
              >
                {{ job.status }}
              </span>
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
              <div
                v-if="job.totalRows"
                class="flex items-center"
              >
                <span class="mr-2">
                  {{ job.successRows || 0 }} / {{ job.totalRows }}
                </span>
                <div
                  v-if="job.status === 'Processing'"
                  class="w-24 bg-gray-200 rounded-full h-2"
                >
                  <div
                    class="bg-blue-600 h-2 rounded-full"
                    :style="{ width: getProgressPercent(job) + '%' }"
                  />
                </div>
              </div>
              <span v-else>-</span>
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
              {{ formatDate(job.createdDate) }}
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
              <button
                class="text-blue-600 hover:text-blue-900"
                data-testid="view-job-button"
                @click="viewJobDetails(job)"
              >
                View Details
              </button>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- Pagination -->
      <div
        class="bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6"
        data-testid="pagination"
      >
        <div class="flex-1 flex justify-between sm:hidden">
          <button
            :disabled="!importStore.hasPrevPage"
            class="btn btn-secondary"
            data-testid="prev-page-mobile"
            @click="previousPage"
          >
            Previous
          </button>
          <button
            :disabled="!importStore.hasNextPage"
            class="btn btn-secondary ml-3"
            data-testid="next-page-mobile"
            @click="nextPage"
          >
            Next
          </button>
        </div>
        <div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
          <div>
            <p
              class="text-sm text-gray-700"
              data-testid="pagination-info"
            >
              Showing
              <span class="font-medium">{{ getStartItem() }}</span>
              to
              <span class="font-medium">{{ getEndItem() }}</span>
              of
              <span class="font-medium">{{ importStore.totalCount }}</span>
              results
            </p>
          </div>
          <div>
            <nav class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px">
              <button
                :disabled="!importStore.hasPrevPage"
                class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                data-testid="prev-page"
                @click="previousPage"
              >
                <ChevronLeftIcon class="h-5 w-5" />
              </button>
              <span class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700">
                Page {{ importStore.pageNumber }} of {{ importStore.totalPages }}
              </span>
              <button
                :disabled="!importStore.hasNextPage"
                class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                data-testid="next-page"
                @click="nextPage"
              >
                <ChevronRightIcon class="h-5 w-5" />
              </button>
            </nav>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty State -->
    <div
      v-else
      class="text-center py-12 bg-white shadow sm:rounded-lg"
      data-testid="empty-state"
    >
      <DocumentTextIcon class="mx-auto h-12 w-12 text-gray-400" />
      <h3 class="mt-2 text-sm font-medium text-gray-900">
        No import jobs found
      </h3>
      <p class="mt-1 text-sm text-gray-500">
        Get started by uploading a CSV file.
      </p>
      <div class="mt-6">
        <button
          class="btn btn-primary"
          data-testid="empty-state-new-import-button"
          @click="$router.push('/import-data')"
        >
          <ArrowUpTrayIcon class="h-5 w-5 mr-2 inline-block" />
          Start Import
        </button>
      </div>
    </div>

    <!-- Job Details Modal -->
    <Teleport to="body">
      <div
        v-if="selectedJob"
        class="fixed inset-0 z-50 overflow-y-auto"
        data-testid="job-details-modal"
      >
        <div class="flex min-h-screen items-center justify-center p-4">
          <div
            class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
            @click="selectedJob = null"
          />

          <div class="relative transform overflow-hidden rounded-lg bg-white px-4 pb-4 pt-5 text-left shadow-xl sm:my-8 sm:w-full sm:max-w-2xl sm:p-6">
            <div class="absolute right-0 top-0 pr-4 pt-4">
              <button
                class="text-gray-400 hover:text-gray-500"
                data-testid="close-modal-button"
                @click="selectedJob = null"
              >
                <XMarkIcon class="h-6 w-6" />
              </button>
            </div>

            <div>
              <h3 class="text-lg font-medium leading-6 text-gray-900">
                Import Job Details
              </h3>

              <!-- Job Info -->
              <dl class="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div>
                  <dt class="text-sm font-medium text-gray-500">
                    Job ID
                  </dt>
                  <dd
                    class="mt-1 text-sm text-gray-900 font-mono"
                    data-testid="job-id"
                  >
                    {{ selectedJob.importJobId.substring(0, 8) }}...
                  </dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500">
                    Status
                  </dt>
                  <dd class="mt-1">
                    <span
                      class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                      :class="getStatusClass(selectedJob.status)"
                    >
                      {{ selectedJob.status }}
                    </span>
                  </dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500">
                    File Name
                  </dt>
                  <dd
                    class="mt-1 text-sm text-gray-900"
                    data-testid="job-filename"
                  >
                    {{ selectedJob.fileName }}
                  </dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500">
                    File Size
                  </dt>
                  <dd class="mt-1 text-sm text-gray-900">
                    {{ formatFileSize(selectedJob.fileSize) }}
                  </dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500">
                    Total Rows
                  </dt>
                  <dd
                    class="mt-1 text-sm text-gray-900"
                    data-testid="job-total-rows"
                  >
                    {{ selectedJob.totalRows || 'N/A' }}
                  </dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500">
                    Success / Failed
                  </dt>
                  <dd class="mt-1 text-sm text-gray-900">
                    <span class="text-green-600">{{ selectedJob.successRows || 0 }}</span>
                    /
                    <span class="text-red-600">{{ selectedJob.failedRows || 0 }}</span>
                  </dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500">
                    Started
                  </dt>
                  <dd class="mt-1 text-sm text-gray-900">
                    {{ selectedJob.startedDate ? formatDateTime(selectedJob.startedDate) : 'N/A' }}
                  </dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500">
                    Completed
                  </dt>
                  <dd class="mt-1 text-sm text-gray-900">
                    {{ selectedJob.completedDate ? formatDateTime(selectedJob.completedDate) : 'N/A' }}
                  </dd>
                </div>
              </dl>

              <!-- Error Message -->
              <div
                v-if="selectedJob.errorMessage"
                class="mt-4 p-4 bg-red-50 rounded-lg"
                data-testid="job-error-message"
              >
                <p class="text-sm font-medium text-red-800">
                  Error:
                </p>
                <p class="mt-1 text-sm text-red-700">
                  {{ selectedJob.errorMessage }}
                </p>
              </div>

              <!-- Error Details -->
              <div
                v-if="selectedJob.errorDetails"
                class="mt-4"
                data-testid="job-error-details"
              >
                <p class="text-sm font-medium text-gray-900">
                  Error Details:
                </p>
                <pre class="mt-2 text-xs text-gray-700 bg-gray-100 p-2 rounded overflow-x-auto">{{ selectedJob.errorDetails }}</pre>
              </div>
            </div>

            <div class="mt-5 sm:mt-6">
              <button
                class="btn btn-secondary w-full"
                data-testid="close-details-button"
                @click="selectedJob = null"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </AppLayout>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useImportStore } from '@/stores/imports'
import AppLayout from '@/components/layout/AppLayout.vue'
import {
  ArrowUpTrayIcon,
  ArrowPathIcon,
  DocumentTextIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
  XMarkIcon
} from '@heroicons/vue/24/outline'

const router = useRouter()
const importStore = useImportStore()

// State
const filterJobType = ref(null)
const pageSize = ref(50)
const selectedJob = ref(null)

// Lifecycle
onMounted(async () => {
  await loadImportHistory()
})

// Methods
async function loadImportHistory() {
  try {
    await importStore.fetchImportHistory(filterJobType.value)
  } catch (error) {
    console.error('Error loading import history:', error)
  }
}

function getStatusClass(status) {
  const classes = {
    Pending: 'bg-yellow-100 text-yellow-800',
    Processing: 'bg-blue-100 text-blue-800',
    Completed: 'bg-green-100 text-green-800',
    Failed: 'bg-red-100 text-red-800',
    PartialSuccess: 'bg-orange-100 text-orange-800'
  }
  return classes[status] || 'bg-gray-100 text-gray-800'
}

function getProgressPercent(job) {
  if (!job.totalRows || job.totalRows === 0) return 0
  const processed = (job.successRows || 0) + (job.failedRows || 0)
  return Math.round((processed / job.totalRows) * 100)
}

function formatDate(dateString) {
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
}

function formatDateTime(dateString) {
  const date = new Date(dateString)
  return date.toLocaleString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

function formatFileSize(bytes) {
  if (bytes < 1024) return bytes + ' B'
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(2) + ' KB'
  return (bytes / (1024 * 1024)).toFixed(2) + ' MB'
}

function viewJobDetails(job) {
  selectedJob.value = job
}

function getStartItem() {
  if (importStore.totalCount === 0) return 0
  return (importStore.pageNumber - 1) * importStore.pageSize + 1
}

function getEndItem() {
  const end = importStore.pageNumber * importStore.pageSize
  return Math.min(end, importStore.totalCount)
}

function previousPage() {
  if (importStore.hasPrevPage) {
    importStore.setPageNumber(importStore.pageNumber - 1)
    loadImportHistory()
  }
}

function nextPage() {
  if (importStore.hasNextPage) {
    importStore.setPageNumber(importStore.pageNumber + 1)
    loadImportHistory()
  }
}

function changePageSize() {
  importStore.setPageSize(pageSize.value)
  loadImportHistory()
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
</style>
