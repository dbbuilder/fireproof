<template>
  <AppLayout>
    <div>
      <!-- Header -->
      <div class="flex justify-between items-center mb-8">
        <div>
          <h1 class="text-3xl font-display font-semibold text-gray-900 mb-2" data-testid="reports-heading">
            Reports & Analytics
          </h1>
          <p class="text-gray-600">
            Generate compliance reports and view analytics
          </p>
        </div>
        <button
          @click="generateReport"
          class="btn-primary inline-flex items-center"
          :disabled="generating"
          data-testid="generate-report-button"
        >
          <DocumentArrowDownIcon class="h-5 w-5 mr-2" />
          {{ generating ? 'Generating...' : 'Generate Report' }}
        </button>
      </div>

      <!-- Filters -->
      <div class="card mb-8">
        <div class="card-header">
          <h2 class="text-lg font-semibold text-gray-900">Report Filters</h2>
        </div>
        <div class="card-body">
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <!-- Date Range -->
            <div>
              <label for="startDate" class="form-label">Start Date</label>
              <input
                id="startDate"
                v-model="filters.startDate"
                type="date"
                class="form-input"
                @change="applyFilters"
              />
            </div>

            <div>
              <label for="endDate" class="form-label">End Date</label>
              <input
                id="endDate"
                v-model="filters.endDate"
                type="date"
                class="form-input"
                @change="applyFilters"
              />
            </div>

            <!-- Location Filter -->
            <div>
              <label for="location" class="form-label">Location</label>
              <select
                id="location"
                v-model="filters.locationId"
                class="form-input"
                @change="applyFilters"
              >
                <option value="">All Locations</option>
                <option
                  v-for="location in locationStore.locations"
                  :key="location.locationId"
                  :value="location.locationId"
                >
                  {{ location.locationName }}
                </option>
              </select>
            </div>

            <!-- Inspection Type Filter -->
            <div>
              <label for="inspectionType" class="form-label">Inspection Type</label>
              <select
                id="inspectionType"
                v-model="filters.inspectionType"
                class="form-input"
                @change="applyFilters"
              >
                <option value="">All Types</option>
                <option value="Monthly">Monthly</option>
                <option value="Annual">Annual</option>
                <option value="5-Year">5-Year</option>
                <option value="12-Year">12-Year</option>
              </select>
            </div>
          </div>

          <div class="flex items-center justify-between mt-4 pt-4 border-t border-gray-200">
            <div class="text-sm text-gray-600">
              Showing data from {{ formatDate(filters.startDate) }} to {{ formatDate(filters.endDate) }}
            </div>
            <button
              @click="resetFilters"
              class="btn-outline text-sm"
            >
              Reset Filters
            </button>
          </div>
        </div>
      </div>

      <!-- Loading State -->
      <div v-if="inspectionStore.loading" class="card">
        <div class="p-12 text-center">
          <div class="spinner-lg mx-auto mb-4"></div>
          <p class="text-gray-600">Loading analytics...</p>
        </div>
      </div>

      <template v-else>
        <!-- Overview Stats -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8" data-testid="overview-stats">
          <!-- Total Inspections -->
          <div class="card" data-testid="stat-card-total">
            <div class="p-6">
              <div class="flex items-center justify-between mb-2">
                <span class="text-sm font-medium text-gray-500">Total Inspections</span>
                <ClipboardDocumentCheckIcon class="h-8 w-8 text-gray-400" />
              </div>
              <div class="text-3xl font-bold text-gray-900" data-testid="total-inspections">
                {{ stats.totalInspections }}
              </div>
              <p class="text-xs text-gray-500 mt-1">
                In selected period
              </p>
            </div>
          </div>

          <!-- Pass Rate -->
          <div class="card" data-testid="stat-card-passrate">
            <div class="p-6">
              <div class="flex items-center justify-between mb-2">
                <span class="text-sm font-medium text-gray-500">Pass Rate</span>
                <ChartBarIcon class="h-8 w-8 text-green-400" />
              </div>
              <div class="text-3xl font-bold text-green-600" data-testid="pass-rate">
                {{ (stats.passRate || 0).toFixed(1) }}%
              </div>
              <p class="text-xs text-gray-500 mt-1">
                {{ stats.passedInspections }} passed, {{ stats.failedInspections }} failed
              </p>
            </div>
          </div>

          <!-- Require Service -->
          <div class="card" data-testid="stat-card-service">
            <div class="p-6">
              <div class="flex items-center justify-between mb-2">
                <span class="text-sm font-medium text-gray-500">Require Service</span>
                <WrenchScrewdriverIcon class="h-8 w-8 text-amber-400" />
              </div>
              <div class="text-3xl font-bold text-amber-600" data-testid="require-service">
                {{ stats.requireingService }}
              </div>
              <p class="text-xs text-gray-500 mt-1">
                Need maintenance
              </p>
            </div>
          </div>

          <!-- Require Replacement -->
          <div class="card" data-testid="stat-card-replacement">
            <div class="p-6">
              <div class="flex items-center justify-between mb-2">
                <span class="text-sm font-medium text-gray-500">Require Replacement</span>
                <ExclamationTriangleIcon class="h-8 w-8 text-red-400" />
              </div>
              <div class="text-3xl font-bold text-red-600" data-testid="require-replacement">
                {{ stats.requiringReplacement }}
              </div>
              <p class="text-xs text-gray-500 mt-1">
                Critical attention
              </p>
            </div>
          </div>
        </div>

        <!-- Charts Section -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8" data-testid="charts-section">
          <!-- Inspection Type Breakdown -->
          <div class="card" data-testid="inspections-by-type-card">
            <div class="card-header">
              <h3 class="text-lg font-semibold text-gray-900">Inspections by Type</h3>
            </div>
            <div class="card-body">
              <div v-if="Object.keys(inspectionsByType).length > 0" class="space-y-3">
                <div
                  v-for="(inspections, type) in inspectionsByType"
                  :key="type"
                  class="flex items-center justify-between"
                >
                  <div class="flex items-center flex-1">
                    <span class="text-sm font-medium text-gray-700 w-24">{{ type }}</span>
                    <div class="flex-1 mx-4">
                      <div class="w-full bg-gray-200 rounded-full h-2">
                        <div
                          class="bg-primary-600 h-2 rounded-full transition-all duration-300"
                          :style="{ width: `${(inspections.length / stats.totalInspections) * 100}%` }"
                        ></div>
                      </div>
                    </div>
                    <span class="text-sm font-semibold text-gray-900 w-12 text-right">
                      {{ inspections.length }}
                    </span>
                  </div>
                </div>
              </div>
              <div v-else class="text-center py-8 text-gray-500">
                No inspection data available
              </div>
            </div>
          </div>

          <!-- Pass/Fail Distribution -->
          <div class="card" data-testid="pass-fail-distribution-card">
            <div class="card-header">
              <h3 class="text-lg font-semibold text-gray-900">Pass/Fail Distribution</h3>
            </div>
            <div class="card-body">
              <div v-if="stats.totalInspections > 0" class="space-y-4">
                <!-- Passed -->
                <div class="flex items-center justify-between">
                  <div class="flex items-center flex-1">
                    <div class="w-3 h-3 rounded-full bg-green-500 mr-3"></div>
                    <span class="text-sm font-medium text-gray-700 w-20">Passed</span>
                    <div class="flex-1 mx-4">
                      <div class="w-full bg-gray-200 rounded-full h-2">
                        <div
                          class="bg-green-500 h-2 rounded-full transition-all duration-300"
                          :style="{ width: `${stats.passRate}%` }"
                        ></div>
                      </div>
                    </div>
                    <span class="text-sm font-semibold text-gray-900 w-16 text-right">
                      {{ stats.passedInspections }} ({{ (stats.passRate || 0).toFixed(1) }}%)
                    </span>
                  </div>
                </div>

                <!-- Failed -->
                <div class="flex items-center justify-between">
                  <div class="flex items-center flex-1">
                    <div class="w-3 h-3 rounded-full bg-red-500 mr-3"></div>
                    <span class="text-sm font-medium text-gray-700 w-20">Failed</span>
                    <div class="flex-1 mx-4">
                      <div class="w-full bg-gray-200 rounded-full h-2">
                        <div
                          class="bg-red-500 h-2 rounded-full transition-all duration-300"
                          :style="{ width: `${100 - stats.passRate}%` }"
                        ></div>
                      </div>
                    </div>
                    <span class="text-sm font-semibold text-gray-900 w-16 text-right">
                      {{ stats.failedInspections }} ({{ (100 - (stats.passRate || 0)).toFixed(1) }}%)
                    </span>
                  </div>
                </div>

                <!-- Visual Pie -->
                <div class="pt-6 border-t border-gray-200" data-testid="visual-pie-chart">
                  <div class="flex items-center justify-center space-x-2">
                    <div
                      data-testid="visual-pie-chart-green"
                      class="h-24 rounded-lg bg-green-500 transition-all duration-300 flex items-center justify-center"
                      :style="{ width: `${stats.passRate}%` }"
                    >
                      <span v-if="stats.passRate > 20" class="text-white font-bold text-sm">
                        {{ (stats.passRate || 0).toFixed(0) }}%
                      </span>
                    </div>
                    <div
                      data-testid="visual-pie-chart-red"
                      class="h-24 rounded-lg bg-red-500 transition-all duration-300 flex items-center justify-center"
                      :style="{ width: `${100 - stats.passRate}%` }"
                    >
                      <span v-if="100 - stats.passRate > 20" class="text-white font-bold text-sm">
                        {{ (100 - (stats.passRate || 0)).toFixed(0) }}%
                      </span>
                    </div>
                  </div>
                </div>
              </div>
              <div v-else class="text-center py-8 text-gray-500">
                No inspection data available
              </div>
            </div>
          </div>
        </div>

        <!-- Inspections by Location -->
        <div class="card mb-8" data-testid="inspections-by-location-card">
          <div class="card-header">
            <h3 class="text-lg font-semibold text-gray-900">Inspections by Location</h3>
          </div>
          <div class="card-body">
            <div v-if="locationStats.length > 0" class="space-y-3">
              <div
                v-for="location in locationStats"
                :key="location.locationId"
                class="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
              >
                <div class="flex items-center flex-1">
                  <MapPinIcon class="h-5 w-5 text-gray-400 mr-3" />
                  <div class="flex-1">
                    <div class="font-medium text-gray-900">{{ location.locationName }}</div>
                    <div class="text-xs text-gray-500">{{ location.extinguisherCount }} extinguishers</div>
                  </div>
                </div>
                <div class="flex items-center space-x-6">
                  <div class="text-center">
                    <div class="text-sm font-semibold text-gray-900">{{ location.inspectionCount }}</div>
                    <div class="text-xs text-gray-500">Inspections</div>
                  </div>
                  <div class="text-center">
                    <div class="text-sm font-semibold text-green-600">{{ location.passed }}</div>
                    <div class="text-xs text-gray-500">Passed</div>
                  </div>
                  <div class="text-center">
                    <div class="text-sm font-semibold text-red-600">{{ location.failed }}</div>
                    <div class="text-xs text-gray-500">Failed</div>
                  </div>
                  <div class="text-center min-w-[60px]">
                    <div
                      class="text-sm font-semibold"
                      :class="[
                        location.passRate >= 90 ? 'text-green-600' :
                        location.passRate >= 70 ? 'text-amber-600' :
                        'text-red-600'
                      ]"
                    >
                      {{ (location.passRate || 0).toFixed(1) }}%
                    </div>
                    <div class="text-xs text-gray-500">Pass Rate</div>
                  </div>
                </div>
              </div>
            </div>
            <div v-else class="text-center py-8 text-gray-500">
              No location data available
            </div>
          </div>
        </div>

        <!-- Recent Activity -->
        <div class="card" data-testid="recent-activity-card">
          <div class="card-header">
            <h3 class="text-lg font-semibold text-gray-900">Recent Inspection Activity</h3>
          </div>
          <div class="card-body">
            <div v-if="recentInspections.length > 0" class="space-y-3">
              <div
                v-for="inspection in recentInspections"
                :key="inspection.inspectionId"
                class="flex items-center justify-between p-3 border border-gray-200 rounded-lg hover:border-gray-300 transition-colors"
              >
                <div class="flex items-center flex-1">
                  <div
                    class="flex items-center justify-center w-10 h-10 rounded-full mr-3"
                    :class="[
                      inspection.passed ? 'bg-green-100' : 'bg-red-100'
                    ]"
                  >
                    <CheckCircleIcon v-if="inspection.passed" class="h-5 w-5 text-green-600" />
                    <XCircleIcon v-else class="h-5 w-5 text-red-600" />
                  </div>
                  <div class="flex-1">
                    <div class="flex items-center space-x-2">
                      <span class="font-medium text-gray-900">{{ inspection.extinguisherCode }}</span>
                      <span class="badge-primary text-xs">{{ inspection.inspectionType }}</span>
                    </div>
                    <div class="text-sm text-gray-600">
                      {{ inspection.locationName }} • {{ formatDate(inspection.inspectionDate) }}
                    </div>
                  </div>
                </div>
                <div class="flex items-center space-x-2">
                  <span
                    v-if="inspection.requiresService"
                    class="badge-warning text-xs"
                  >
                    Service
                  </span>
                  <span
                    v-if="inspection.requiresReplacement"
                    class="badge-danger text-xs"
                  >
                    Replace
                  </span>
                </div>
              </div>
            </div>
            <div v-else class="text-center py-8 text-gray-500">
              No recent inspections
            </div>
          </div>
        </div>
      </template>
    </div>
  </AppLayout>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useInspectionStore } from '@/stores/inspections'
import { useExtinguisherStore } from '@/stores/extinguishers'
import { useLocationStore } from '@/stores/locations'
import { useToastStore } from '@/stores/toast'
import AppLayout from '@/components/layout/AppLayout.vue'
import {
  DocumentArrowDownIcon,
  ClipboardDocumentCheckIcon,
  ChartBarIcon,
  WrenchScrewdriverIcon,
  ExclamationTriangleIcon,
  MapPinIcon,
  CheckCircleIcon,
  XCircleIcon
} from '@heroicons/vue/24/outline'

const inspectionStore = useInspectionStore()
const extinguisherStore = useExtinguisherStore()
const locationStore = useLocationStore()
const toast = useToastStore()

const generating = ref(false)

// Calculate default date range (last 30 days)
const getDefaultDateRange = () => {
  const endDate = new Date()
  const startDate = new Date()
  startDate.setDate(startDate.getDate() - 30)

  return {
    startDate: startDate.toISOString().split('T')[0],
    endDate: endDate.toISOString().split('T')[0]
  }
}

const filters = ref({
  startDate: getDefaultDateRange().startDate,
  endDate: getDefaultDateRange().endDate,
  locationId: '',
  inspectionType: ''
})

const stats = computed(() => {
  if (!inspectionStore.stats) {
    return {
      totalInspections: 0,
      passedInspections: 0,
      failedInspections: 0,
      requireingService: 0,
      requiringReplacement: 0,
      passRate: 0
    }
  }
  return inspectionStore.stats
})

const inspectionsByType = computed(() => {
  return inspectionStore.inspectionsByType || {}
})

const recentInspections = computed(() => {
  return inspectionStore.recentInspections.slice(0, 10)
})

const locationStats = computed(() => {
  const stats = []

  for (const location of locationStore.locations) {
    // Get extinguishers for this location
    const locationExtinguishers = extinguisherStore.extinguishers.filter(
      e => e.locationId === location.locationId
    )

    // Get inspections for extinguishers at this location
    const locationInspections = inspectionStore.inspections.filter(inspection => {
      const extinguisher = extinguisherStore.getExtinguisherById(inspection.extinguisherId)
      return extinguisher && extinguisher.locationId === location.locationId
    })

    if (locationInspections.length > 0) {
      const passed = locationInspections.filter(i => i.passed).length
      const failed = locationInspections.filter(i => !i.passed).length
      const passRate = locationInspections.length > 0
        ? (passed / locationInspections.length) * 100
        : 0

      stats.push({
        locationId: location.locationId,
        locationName: location.locationName,
        extinguisherCount: locationExtinguishers.length,
        inspectionCount: locationInspections.length,
        passed,
        failed,
        passRate
      })
    }
  }

  return stats.sort((a, b) => b.inspectionCount - a.inspectionCount)
})

onMounted(async () => {
  try {
    await Promise.all([
      inspectionStore.fetchInspections(),
      inspectionStore.fetchStats(filters.value.startDate, filters.value.endDate),
      extinguisherStore.fetchExtinguishers(),
      locationStore.fetchLocations()
    ])
  } catch (error) {
    console.error('Failed to load report data:', error)
    toast.error('Failed to load reports')
  }
})

const applyFilters = async () => {
  try {
    const filterParams = {
      startDate: filters.value.startDate,
      endDate: filters.value.endDate
    }

    if (filters.value.inspectionType) {
      filterParams.inspectionType = filters.value.inspectionType
    }

    await Promise.all([
      inspectionStore.fetchInspections(filterParams),
      inspectionStore.fetchStats(filters.value.startDate, filters.value.endDate)
    ])
  } catch (error) {
    console.error('Failed to apply filters:', error)
    toast.error('Failed to apply filters')
  }
}

const resetFilters = async () => {
  const defaultRange = getDefaultDateRange()
  filters.value = {
    startDate: defaultRange.startDate,
    endDate: defaultRange.endDate,
    locationId: '',
    inspectionType: ''
  }
  await applyFilters()
}

const generateReport = async () => {
  generating.value = true

  try {
    // In a real implementation, this would call an API endpoint that generates
    // a PDF or Excel report. For now, we'll simulate the process.

    toast.info('Generating report...')

    // Simulate report generation
    await new Promise(resolve => setTimeout(resolve, 2000))

    // Create a simple CSV export as a placeholder
    const csvContent = generateCSVReport()
    const blob = new Blob([csvContent], { type: 'text/csv' })
    const url = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `inspection-report-${new Date().toISOString().split('T')[0]}.csv`
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    window.URL.revokeObjectURL(url)

    toast.success('Report generated successfully')
  } catch (error) {
    console.error('Failed to generate report:', error)
    toast.error('Failed to generate report')
  } finally {
    generating.value = false
  }
}

const generateCSVReport = () => {
  let csv = 'Date,Extinguisher,Location,Type,Inspector,Status,Requires Service,Requires Replacement\n'

  for (const inspection of inspectionStore.inspections) {
    csv += `${formatDate(inspection.inspectionDate)},`
    csv += `${inspection.extinguisherCode},`
    csv += `${inspection.locationName || 'N/A'},`
    csv += `${inspection.inspectionType},`
    csv += `${inspection.inspectorName || 'N/A'},`
    csv += `${inspection.passed ? 'Passed' : 'Failed'},`
    csv += `${inspection.requiresService ? 'Yes' : 'No'},`
    csv += `${inspection.requiresReplacement ? 'Yes' : 'No'}\n`
  }

  return csv
}

const formatDate = (dateString) => {
  if (!dateString) return 'N/A'
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
}
</script>
