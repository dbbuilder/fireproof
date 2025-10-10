<template>
  <AppLayout>
    <div>
      <!-- Header -->
      <div class="flex justify-between items-center mb-8">
        <div>
          <h1 class="text-3xl font-display font-semibold text-gray-900 mb-2">
            Inspections
          </h1>
          <p class="text-gray-600">
            Perform and review fire extinguisher inspections
          </p>
        </div>
        <button
          @click="startNewInspection"
          class="btn-primary inline-flex items-center"
        >
          <PlusIcon class="h-5 w-5 mr-2" />
          Start Inspection
        </button>
      </div>

      <!-- Error Alert -->
      <div v-if="inspectionStore.error" class="alert-danger mb-6">
        <XCircleIcon class="h-5 w-5" />
        <div class="flex-1">
          <p class="text-sm font-medium">{{ inspectionStore.error }}</p>
        </div>
        <button
          type="button"
          class="text-red-400 hover:text-red-600"
          @click="inspectionStore.clearError()"
        >
          <XMarkIcon class="h-5 w-5" />
        </button>
      </div>

      <!-- Stats Cards -->
      <div v-if="inspectionStore.stats" class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <div class="card">
          <div class="p-6">
            <div class="flex items-center justify-between mb-2">
              <span class="text-sm font-medium text-gray-500">Total</span>
              <ClipboardDocumentCheckIcon class="h-8 w-8 text-gray-400" />
            </div>
            <div class="text-2xl font-bold text-gray-900">
              {{ inspectionStore.stats.totalInspections }}
            </div>
          </div>
        </div>

        <div class="card">
          <div class="p-6">
            <div class="flex items-center justify-between mb-2">
              <span class="text-sm font-medium text-gray-500">Passed</span>
              <CheckCircleIcon class="h-8 w-8 text-green-400" />
            </div>
            <div class="text-2xl font-bold text-green-600">
              {{ inspectionStore.stats.passedInspections }}
            </div>
          </div>
        </div>

        <div class="card">
          <div class="p-6">
            <div class="flex items-center justify-between mb-2">
              <span class="text-sm font-medium text-gray-500">Failed</span>
              <XCircleIcon class="h-8 w-8 text-red-400" />
            </div>
            <div class="text-2xl font-bold text-red-600">
              {{ inspectionStore.stats.failedInspections }}
            </div>
          </div>
        </div>

        <div class="card">
          <div class="p-6">
            <div class="flex items-center justify-between mb-2">
              <span class="text-sm font-medium text-gray-500">Pass Rate</span>
              <ChartBarIcon class="h-8 w-8 text-blue-400" />
            </div>
            <div class="text-2xl font-bold text-gray-900">
              {{ inspectionStore.stats.passRate.toFixed(1) }}%
            </div>
          </div>
        </div>
      </div>

      <!-- Loading State -->
      <div v-if="inspectionStore.loading" class="card">
        <div class="p-12 text-center">
          <div class="spinner-lg mx-auto mb-4"></div>
          <p class="text-gray-600">Loading inspections...</p>
        </div>
      </div>

      <!-- Inspections List -->
      <div v-else-if="inspectionStore.inspections.length > 0" class="card">
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Date
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Extinguisher
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Location
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Type
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Inspector
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr
                v-for="inspection in inspectionStore.recentInspections"
                :key="inspection.inspectionId"
                class="hover:bg-gray-50"
              >
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  {{ formatDate(inspection.inspectionDate) }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                  {{ inspection.extinguisherCode }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                  {{ inspection.locationName }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class="badge-primary">
                    {{ inspection.inspectionType }}
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                  {{ inspection.inspectorName }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span
                    :class="[
                      inspection.passed ? 'badge-success' : 'badge-danger'
                    ]"
                  >
                    {{ inspection.passed ? 'Passed' : 'Failed' }}
                  </span>
                  <span v-if="inspection.requiresService" class="badge-warning ml-2">
                    Service
                  </span>
                  <span v-if="inspection.requiresReplacement" class="badge-danger ml-2">
                    Replace
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                  <button
                    @click="viewInspection(inspection)"
                    class="text-primary-600 hover:text-primary-900 mr-3"
                  >
                    View
                  </button>
                  <button
                    @click="confirmDelete(inspection)"
                    class="text-red-600 hover:text-red-900"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Empty State -->
      <div v-else class="card">
        <div class="p-12 text-center">
          <div class="inline-flex items-center justify-center w-16 h-16 rounded-full bg-primary-100 mb-4">
            <ClipboardDocumentCheckIcon class="h-8 w-8 text-primary-600" />
          </div>
          <h3 class="text-lg font-semibold text-gray-900 mb-2">
            No inspections yet
          </h3>
          <p class="text-gray-600 mb-6">
            Get started by performing your first extinguisher inspection
          </p>
          <button
            @click="startNewInspection"
            class="btn-primary inline-flex items-center"
          >
            <PlusIcon class="h-5 w-5 mr-2" />
            Start Your First Inspection
          </button>
        </div>
      </div>
    </div>

    <!-- Inspection Wizard Modal -->
    <transition
      enter-active-class="transition ease-out duration-200"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="transition ease-in duration-150"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div
        v-if="showWizard"
        class="modal-overlay"
        @click.self="closeWizard"
      >
        <div class="modal-container max-w-4xl">
          <div class="modal-content">
            <!-- Wizard Header with Steps -->
            <div class="mb-6">
              <div class="flex items-center justify-between mb-4">
                <h2 class="text-2xl font-display font-semibold text-gray-900">
                  Fire Extinguisher Inspection
                </h2>
                <button
                  type="button"
                  class="text-gray-400 hover:text-gray-600 transition-colors"
                  @click="closeWizard"
                >
                  <XMarkIcon class="h-6 w-6" />
                </button>
              </div>

              <!-- Progress Steps -->
              <div class="flex items-center justify-between">
                <div
                  v-for="(step, index) in steps"
                  :key="index"
                  class="flex items-center flex-1"
                >
                  <div class="flex flex-col items-center flex-1">
                    <div
                      class="flex items-center justify-center w-10 h-10 rounded-full transition-colors"
                      :class="[
                        currentStep > index ? 'bg-green-500 text-white' :
                        currentStep === index ? 'bg-primary-600 text-white' :
                        'bg-gray-200 text-gray-500'
                      ]"
                    >
                      <CheckIcon v-if="currentStep > index" class="h-5 w-5" />
                      <span v-else>{{ index + 1 }}</span>
                    </div>
                    <span
                      class="mt-2 text-xs font-medium"
                      :class="[
                        currentStep >= index ? 'text-gray-900' : 'text-gray-500'
                      ]"
                    >
                      {{ step.name }}
                    </span>
                  </div>
                  <div
                    v-if="index < steps.length - 1"
                    class="flex-1 h-1 mx-2 transition-colors"
                    :class="[
                      currentStep > index ? 'bg-green-500' : 'bg-gray-200'
                    ]"
                  ></div>
                </div>
              </div>
            </div>

            <!-- Step Content -->
            <div class="min-h-[400px]">
              <!-- Step 1: Select Extinguisher -->
              <div v-if="currentStep === 0" class="space-y-4">
                <h3 class="text-lg font-semibold text-gray-900 mb-4">
                  Select Extinguisher
                </h3>

                <div class="form-group">
                  <label for="extinguisher" class="form-label">
                    Extinguisher *
                  </label>
                  <select
                    id="extinguisher"
                    v-model="inspectionData.extinguisherId"
                    required
                    class="form-input"
                    @change="onExtinguisherSelected"
                  >
                    <option value="">-- Select Extinguisher --</option>
                    <option
                      v-for="extinguisher in extinguisherStore.activeExtinguishers"
                      :key="extinguisher.extinguisherId"
                      :value="extinguisher.extinguisherId"
                    >
                      {{ extinguisher.extinguisherCode }} - {{ extinguisher.locationName }}
                    </option>
                  </select>
                </div>

                <div v-if="selectedExtinguisher" class="card bg-gray-50 p-4">
                  <h4 class="font-medium text-gray-900 mb-2">Extinguisher Details</h4>
                  <div class="grid grid-cols-2 gap-3 text-sm">
                    <div>
                      <span class="text-gray-500">Code:</span>
                      <span class="ml-2 font-medium">{{ selectedExtinguisher.extinguisherCode }}</span>
                    </div>
                    <div>
                      <span class="text-gray-500">Type:</span>
                      <span class="ml-2 font-medium">{{ selectedExtinguisher.typeName }}</span>
                    </div>
                    <div>
                      <span class="text-gray-500">Location:</span>
                      <span class="ml-2 font-medium">{{ selectedExtinguisher.locationName }}</span>
                    </div>
                    <div>
                      <span class="text-gray-500">Serial:</span>
                      <span class="ml-2 font-medium">{{ selectedExtinguisher.serialNumber }}</span>
                    </div>
                    <div v-if="selectedExtinguisher.lastServiceDate">
                      <span class="text-gray-500">Last Service:</span>
                      <span class="ml-2 font-medium">{{ formatDate(selectedExtinguisher.lastServiceDate) }}</span>
                    </div>
                    <div v-if="selectedExtinguisher.nextServiceDueDate">
                      <span class="text-gray-500">Next Service:</span>
                      <span class="ml-2 font-medium">{{ formatDate(selectedExtinguisher.nextServiceDueDate) }}</span>
                    </div>
                  </div>
                </div>

                <div class="form-group">
                  <label for="inspectionType" class="form-label">
                    Inspection Type *
                  </label>
                  <select
                    id="inspectionType"
                    v-model="inspectionData.inspectionType"
                    required
                    class="form-input"
                  >
                    <option value="">-- Select Type --</option>
                    <option value="Monthly">Monthly</option>
                    <option value="Annual">Annual</option>
                    <option value="5-Year">5-Year</option>
                    <option value="12-Year">12-Year</option>
                  </select>
                  <p class="form-helper">
                    Monthly: Visual inspection. Annual: Full inspection. 5-Year: Internal examination. 12-Year: Hydrostatic test.
                  </p>
                </div>

                <div class="form-group">
                  <label for="inspectionDate" class="form-label">
                    Inspection Date *
                  </label>
                  <input
                    id="inspectionDate"
                    v-model="inspectionData.inspectionDate"
                    type="date"
                    required
                    class="form-input"
                  />
                </div>
              </div>

              <!-- Step 2: Checklist -->
              <div v-if="currentStep === 1" class="space-y-6">
                <h3 class="text-lg font-semibold text-gray-900 mb-4">
                  Inspection Checklist
                </h3>

                <!-- Accessibility & Location -->
                <div class="card bg-gray-50 p-4">
                  <h4 class="font-medium text-gray-900 mb-3">Accessibility & Location</h4>
                  <div class="space-y-3">
                    <label class="flex items-center">
                      <input
                        v-model="inspectionData.isAccessible"
                        type="checkbox"
                        class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                      />
                      <span class="ml-2 text-sm text-gray-700">Extinguisher is accessible</span>
                    </label>

                    <label class="flex items-center">
                      <input
                        v-model="inspectionData.hasObstructions"
                        type="checkbox"
                        class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                      />
                      <span class="ml-2 text-sm text-gray-700">Obstructions present (check if YES)</span>
                    </label>

                    <label class="flex items-center">
                      <input
                        v-model="inspectionData.signageVisible"
                        type="checkbox"
                        class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                      />
                      <span class="ml-2 text-sm text-gray-700">Signage visible</span>
                    </label>
                  </div>
                </div>

                <!-- Physical Condition -->
                <div class="card bg-gray-50 p-4">
                  <h4 class="font-medium text-gray-900 mb-3">Physical Condition</h4>
                  <div class="space-y-3">
                    <label class="flex items-center">
                      <input
                        v-model="inspectionData.sealIntact"
                        type="checkbox"
                        class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                      />
                      <span class="ml-2 text-sm text-gray-700">Tamper seal intact</span>
                    </label>

                    <label class="flex items-center">
                      <input
                        v-model="inspectionData.pinInPlace"
                        type="checkbox"
                        class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                      />
                      <span class="ml-2 text-sm text-gray-700">Safety pin in place</span>
                    </label>

                    <label class="flex items-center">
                      <input
                        v-model="inspectionData.nozzleClear"
                        type="checkbox"
                        class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                      />
                      <span class="ml-2 text-sm text-gray-700">Nozzle clear and unobstructed</span>
                    </label>

                    <label class="flex items-center">
                      <input
                        v-model="inspectionData.hoseConditionGood"
                        type="checkbox"
                        class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                      />
                      <span class="ml-2 text-sm text-gray-700">Hose in good condition</span>
                    </label>

                    <label class="flex items-center">
                      <input
                        v-model="inspectionData.inspectionTagAttached"
                        type="checkbox"
                        class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                      />
                      <span class="ml-2 text-sm text-gray-700">Inspection tag attached</span>
                    </label>
                  </div>
                </div>

                <!-- Gauge & Pressure -->
                <div class="card bg-gray-50 p-4">
                  <h4 class="font-medium text-gray-900 mb-3">Gauge & Pressure</h4>
                  <div class="space-y-3">
                    <label class="flex items-center">
                      <input
                        v-model="inspectionData.gaugeInGreenZone"
                        type="checkbox"
                        class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                      />
                      <span class="ml-2 text-sm text-gray-700">Gauge needle in green zone</span>
                    </label>

                    <div>
                      <label for="gaugePressure" class="form-label">
                        Gauge Pressure (PSI)
                      </label>
                      <input
                        id="gaugePressure"
                        v-model.number="inspectionData.gaugePressurePsi"
                        type="number"
                        step="0.1"
                        class="form-input"
                        placeholder="150"
                      />
                    </div>
                  </div>
                </div>

                <!-- Damage Assessment -->
                <div class="card bg-gray-50 p-4">
                  <h4 class="font-medium text-gray-900 mb-3">Damage Assessment</h4>
                  <div class="space-y-3">
                    <label class="flex items-center">
                      <input
                        v-model="inspectionData.physicalDamagePresent"
                        type="checkbox"
                        class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                      />
                      <span class="ml-2 text-sm text-gray-700">Physical damage present (check if YES)</span>
                    </label>

                    <div v-if="inspectionData.physicalDamagePresent">
                      <label for="damageDescription" class="form-label">
                        Damage Description *
                      </label>
                      <textarea
                        id="damageDescription"
                        v-model="inspectionData.damageDescription"
                        rows="3"
                        class="form-input"
                        placeholder="Describe the damage..."
                      ></textarea>
                    </div>
                  </div>
                </div>

                <!-- Weight Check (if applicable) -->
                <div class="card bg-gray-50 p-4">
                  <h4 class="font-medium text-gray-900 mb-3">Weight Check</h4>
                  <div class="space-y-3">
                    <div>
                      <label for="weight" class="form-label">
                        Weight (pounds)
                      </label>
                      <input
                        id="weight"
                        v-model.number="inspectionData.weightPounds"
                        type="number"
                        step="0.1"
                        class="form-input"
                        placeholder="10.5"
                      />
                      <p class="form-helper">
                        Required for CO2 and halon extinguishers
                      </p>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Step 3: Results & Notes -->
              <div v-if="currentStep === 2" class="space-y-6">
                <h3 class="text-lg font-semibold text-gray-900 mb-4">
                  Results & Corrective Actions
                </h3>

                <div class="form-group">
                  <label for="notes" class="form-label">
                    General Notes
                  </label>
                  <textarea
                    id="notes"
                    v-model="inspectionData.notes"
                    rows="4"
                    class="form-input"
                    placeholder="Additional observations or comments..."
                  ></textarea>
                </div>

                <div class="space-y-3">
                  <label class="flex items-center">
                    <input
                      v-model="inspectionData.requiresService"
                      type="checkbox"
                      class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                    />
                    <span class="ml-2 text-sm font-medium text-gray-700">Requires service</span>
                  </label>

                  <label class="flex items-center">
                    <input
                      v-model="inspectionData.requiresReplacement"
                      type="checkbox"
                      class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                    />
                    <span class="ml-2 text-sm font-medium text-gray-700">Requires replacement</span>
                  </label>
                </div>

                <div v-if="inspectionData.requiresService || inspectionData.requiresReplacement" class="form-group">
                  <label for="failureReason" class="form-label">
                    Failure Reason
                  </label>
                  <textarea
                    id="failureReason"
                    v-model="inspectionData.failureReason"
                    rows="3"
                    class="form-input"
                    placeholder="Explain why the extinguisher failed..."
                  ></textarea>
                </div>

                <div v-if="inspectionData.requiresService || inspectionData.requiresReplacement" class="form-group">
                  <label for="correctiveAction" class="form-label">
                    Corrective Action Required
                  </label>
                  <textarea
                    id="correctiveAction"
                    v-model="inspectionData.correctiveAction"
                    rows="3"
                    class="form-input"
                    placeholder="Describe required corrective actions..."
                  ></textarea>
                </div>

                <!-- Pass/Fail Summary -->
                <div class="card p-6" :class="inspectionPassed ? 'bg-green-50 border-2 border-green-500' : 'bg-red-50 border-2 border-red-500'">
                  <div class="flex items-center">
                    <CheckCircleIcon v-if="inspectionPassed" class="h-12 w-12 text-green-600 mr-4" />
                    <XCircleIcon v-else class="h-12 w-12 text-red-600 mr-4" />
                    <div>
                      <h4 class="text-lg font-semibold" :class="inspectionPassed ? 'text-green-900' : 'text-red-900'">
                        {{ inspectionPassed ? 'Inspection Passed' : 'Inspection Failed' }}
                      </h4>
                      <p class="text-sm" :class="inspectionPassed ? 'text-green-700' : 'text-red-700'">
                        {{ inspectionPassed ? 'Extinguisher meets all inspection criteria' : 'Extinguisher requires attention' }}
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Wizard Navigation -->
            <div class="flex items-center justify-between pt-6 border-t border-gray-200 mt-6">
              <button
                v-if="currentStep > 0"
                @click="previousStep"
                type="button"
                class="btn-outline inline-flex items-center"
              >
                <ChevronLeftIcon class="h-5 w-5 mr-1" />
                Previous
              </button>
              <div v-else></div>

              <div class="flex space-x-3">
                <button
                  @click="closeWizard"
                  type="button"
                  class="btn-outline"
                >
                  Cancel
                </button>
                <button
                  v-if="currentStep < steps.length - 1"
                  @click="nextStep"
                  type="button"
                  class="btn-primary inline-flex items-center"
                  :disabled="!canProceedToNextStep"
                >
                  Next
                  <ChevronRightIcon class="h-5 w-5 ml-1" />
                </button>
                <button
                  v-else
                  @click="submitInspection"
                  type="button"
                  class="btn-primary"
                  :disabled="submitting"
                >
                  <span v-if="!submitting">Submit Inspection</span>
                  <span v-else class="flex items-center">
                    <div class="spinner mr-2"></div>
                    Submitting...
                  </span>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </transition>

    <!-- View Inspection Modal -->
    <transition
      enter-active-class="transition ease-out duration-200"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="transition ease-in duration-150"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div
        v-if="showViewModal"
        class="modal-overlay"
        @click.self="closeViewModal"
      >
        <div class="modal-container max-w-3xl">
          <div class="modal-content" v-if="viewingInspection">
            <div class="flex items-center justify-between mb-6">
              <h2 class="text-2xl font-display font-semibold text-gray-900">
                Inspection Details
              </h2>
              <button
                type="button"
                class="text-gray-400 hover:text-gray-600"
                @click="closeViewModal"
              >
                <XMarkIcon class="h-6 w-6" />
              </button>
            </div>

            <div class="space-y-6">
              <!-- Header Info -->
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <span class="text-sm text-gray-500">Date:</span>
                  <p class="font-medium">{{ formatDate(viewingInspection.inspectionDate) }}</p>
                </div>
                <div>
                  <span class="text-sm text-gray-500">Type:</span>
                  <p class="font-medium">{{ viewingInspection.inspectionType }}</p>
                </div>
                <div>
                  <span class="text-sm text-gray-500">Extinguisher:</span>
                  <p class="font-medium">{{ viewingInspection.extinguisherCode }}</p>
                </div>
                <div>
                  <span class="text-sm text-gray-500">Inspector:</span>
                  <p class="font-medium">{{ viewingInspection.inspectorName }}</p>
                </div>
              </div>

              <!-- Status -->
              <div>
                <span
                  class="inline-flex items-center px-4 py-2 rounded-lg text-sm font-medium"
                  :class="viewingInspection.passed ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'"
                >
                  {{ viewingInspection.passed ? 'Passed' : 'Failed' }}
                </span>
                <span v-if="viewingInspection.requiresService" class="ml-2 badge-warning">
                  Requires Service
                </span>
                <span v-if="viewingInspection.requiresReplacement" class="ml-2 badge-danger">
                  Requires Replacement
                </span>
              </div>

              <!-- Checklist Results -->
              <div class="card bg-gray-50 p-4">
                <h3 class="font-medium text-gray-900 mb-3">Checklist Results</h3>
                <div class="grid grid-cols-2 gap-2 text-sm">
                  <div class="flex items-center">
                    <CheckIcon v-if="viewingInspection.isAccessible" class="h-4 w-4 text-green-600 mr-2" />
                    <XMarkIcon v-else class="h-4 w-4 text-red-600 mr-2" />
                    <span>Accessible</span>
                  </div>
                  <div class="flex items-center">
                    <XMarkIcon v-if="viewingInspection.hasObstructions" class="h-4 w-4 text-red-600 mr-2" />
                    <CheckIcon v-else class="h-4 w-4 text-green-600 mr-2" />
                    <span>No Obstructions</span>
                  </div>
                  <div class="flex items-center">
                    <CheckIcon v-if="viewingInspection.signageVisible" class="h-4 w-4 text-green-600 mr-2" />
                    <XMarkIcon v-else class="h-4 w-4 text-red-600 mr-2" />
                    <span>Signage Visible</span>
                  </div>
                  <div class="flex items-center">
                    <CheckIcon v-if="viewingInspection.sealIntact" class="h-4 w-4 text-green-600 mr-2" />
                    <XMarkIcon v-else class="h-4 w-4 text-red-600 mr-2" />
                    <span>Seal Intact</span>
                  </div>
                  <div class="flex items-center">
                    <CheckIcon v-if="viewingInspection.pinInPlace" class="h-4 w-4 text-green-600 mr-2" />
                    <XMarkIcon v-else class="h-4 w-4 text-red-600 mr-2" />
                    <span>Pin in Place</span>
                  </div>
                  <div class="flex items-center">
                    <CheckIcon v-if="viewingInspection.nozzleClear" class="h-4 w-4 text-green-600 mr-2" />
                    <XMarkIcon v-else class="h-4 w-4 text-red-600 mr-2" />
                    <span>Nozzle Clear</span>
                  </div>
                  <div class="flex items-center">
                    <CheckIcon v-if="viewingInspection.hoseConditionGood" class="h-4 w-4 text-green-600 mr-2" />
                    <XMarkIcon v-else class="h-4 w-4 text-red-600 mr-2" />
                    <span>Hose Good</span>
                  </div>
                  <div class="flex items-center">
                    <CheckIcon v-if="viewingInspection.gaugeInGreenZone" class="h-4 w-4 text-green-600 mr-2" />
                    <XMarkIcon v-else class="h-4 w-4 text-red-600 mr-2" />
                    <span>Gauge Green</span>
                  </div>
                </div>
              </div>

              <!-- Notes -->
              <div v-if="viewingInspection.notes">
                <h3 class="font-medium text-gray-900 mb-2">Notes</h3>
                <p class="text-sm text-gray-700 whitespace-pre-wrap">{{ viewingInspection.notes }}</p>
              </div>

              <!-- Failure Info -->
              <div v-if="viewingInspection.failureReason">
                <h3 class="font-medium text-gray-900 mb-2">Failure Reason</h3>
                <p class="text-sm text-gray-700 whitespace-pre-wrap">{{ viewingInspection.failureReason }}</p>
              </div>

              <div v-if="viewingInspection.correctiveAction">
                <h3 class="font-medium text-gray-900 mb-2">Corrective Action</h3>
                <p class="text-sm text-gray-700 whitespace-pre-wrap">{{ viewingInspection.correctiveAction }}</p>
              </div>

              <button
                @click="closeViewModal"
                class="btn-outline w-full"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      </div>
    </transition>
  </AppLayout>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useInspectionStore } from '@/stores/inspections'
import { useExtinguisherStore } from '@/stores/extinguishers'
import { useAuthStore } from '@/stores/auth'
import { useToastStore } from '@/stores/toast'
import AppLayout from '@/components/layout/AppLayout.vue'
import {
  PlusIcon,
  ClipboardDocumentCheckIcon,
  CheckCircleIcon,
  XCircleIcon,
  XMarkIcon,
  ChartBarIcon,
  CheckIcon,
  ChevronLeftIcon,
  ChevronRightIcon
} from '@heroicons/vue/24/outline'

const inspectionStore = useInspectionStore()
const extinguisherStore = useExtinguisherStore()
const authStore = useAuthStore()
const toast = useToastStore()

const showWizard = ref(false)
const showViewModal = ref(false)
const currentStep = ref(0)
const submitting = ref(false)
const viewingInspection = ref(null)

const steps = [
  { name: 'Select' },
  { name: 'Inspect' },
  { name: 'Results' }
]

const inspectionData = ref({
  extinguisherId: '',
  inspectorUserId: '',
  inspectionDate: new Date().toISOString().split('T')[0],
  inspectionType: '',
  gpsLatitude: null,
  gpsLongitude: null,
  gpsAccuracyMeters: null,
  isAccessible: true,
  hasObstructions: false,
  signageVisible: true,
  sealIntact: true,
  pinInPlace: true,
  nozzleClear: true,
  hoseConditionGood: true,
  gaugeInGreenZone: true,
  gaugePressurePsi: null,
  physicalDamagePresent: false,
  damageDescription: '',
  weightPounds: null,
  inspectionTagAttached: true,
  previousInspectionDate: null,
  notes: '',
  requiresService: false,
  requiresReplacement: false,
  failureReason: '',
  correctiveAction: '',
  photoUrls: []
})

const selectedExtinguisher = computed(() => {
  if (!inspectionData.value.extinguisherId) return null
  return extinguisherStore.getExtinguisherById(inspectionData.value.extinguisherId)
})

const inspectionPassed = computed(() => {
  return !inspectionData.value.requiresService &&
         !inspectionData.value.requiresReplacement &&
         inspectionData.value.isAccessible &&
         !inspectionData.value.hasObstructions &&
         inspectionData.value.signageVisible &&
         inspectionData.value.sealIntact &&
         inspectionData.value.pinInPlace &&
         inspectionData.value.nozzleClear &&
         inspectionData.value.hoseConditionGood &&
         inspectionData.value.gaugeInGreenZone &&
         !inspectionData.value.physicalDamagePresent
})

const canProceedToNextStep = computed(() => {
  if (currentStep.value === 0) {
    return inspectionData.value.extinguisherId &&
           inspectionData.value.inspectionType &&
           inspectionData.value.inspectionDate
  }
  return true
})

onMounted(async () => {
  try {
    await Promise.all([
      inspectionStore.fetchInspections(),
      inspectionStore.fetchStats(),
      extinguisherStore.fetchExtinguishers()
    ])
  } catch (error) {
    console.error('Failed to load inspection data:', error)
    toast.error('Failed to load inspections')
  }
})

const startNewInspection = () => {
  resetForm()
  inspectionData.value.inspectorUserId = authStore.user?.userId || ''
  currentStep.value = 0
  showWizard.value = true

  // Try to get GPS location
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(
      (position) => {
        inspectionData.value.gpsLatitude = position.coords.latitude
        inspectionData.value.gpsLongitude = position.coords.longitude
        inspectionData.value.gpsAccuracyMeters = position.coords.accuracy
      },
      (error) => {
        console.warn('Could not get GPS location:', error)
      }
    )
  }
}

const onExtinguisherSelected = () => {
  if (selectedExtinguisher.value && selectedExtinguisher.value.lastServiceDate) {
    inspectionData.value.previousInspectionDate = selectedExtinguisher.value.lastServiceDate
  }
}

const nextStep = () => {
  if (currentStep.value < steps.length - 1) {
    currentStep.value++
  }
}

const previousStep = () => {
  if (currentStep.value > 0) {
    currentStep.value--
  }
}

const submitInspection = async () => {
  submitting.value = true

  try {
    const cleanData = {
      ...inspectionData.value,
      damageDescription: inspectionData.value.damageDescription || null,
      gaugePressurePsi: inspectionData.value.gaugePressurePsi || null,
      weightPounds: inspectionData.value.weightPounds || null,
      notes: inspectionData.value.notes || null,
      failureReason: inspectionData.value.failureReason || null,
      correctiveAction: inspectionData.value.correctiveAction || null,
      gpsLatitude: inspectionData.value.gpsLatitude || null,
      gpsLongitude: inspectionData.value.gpsLongitude || null,
      gpsAccuracyMeters: inspectionData.value.gpsAccuracyMeters || null,
      previousInspectionDate: inspectionData.value.previousInspectionDate || null,
      photoUrls: inspectionData.value.photoUrls?.length ? inspectionData.value.photoUrls : null
    }

    await inspectionStore.createInspection(cleanData)
    toast.success('Inspection submitted successfully')
    closeWizard()

    // Refresh data
    await Promise.all([
      inspectionStore.fetchInspections(),
      inspectionStore.fetchStats()
    ])
  } catch (error) {
    console.error('Failed to submit inspection:', error)
    toast.error(error.response?.data?.message || 'Failed to submit inspection')
  } finally {
    submitting.value = false
  }
}

const viewInspection = (inspection) => {
  viewingInspection.value = inspection
  showViewModal.value = true
}

const closeViewModal = () => {
  showViewModal.value = false
  setTimeout(() => {
    viewingInspection.value = null
  }, 200)
}

const confirmDelete = async (inspection) => {
  if (confirm(`Are you sure you want to delete this inspection?\n\nDate: ${formatDate(inspection.inspectionDate)}\nExtinguisher: ${inspection.extinguisherCode}\n\nThis action cannot be undone.`)) {
    try {
      await inspectionStore.deleteInspection(inspection.inspectionId)
      toast.success('Inspection deleted successfully')
    } catch (error) {
      console.error('Failed to delete inspection:', error)
      toast.error('Failed to delete inspection')
    }
  }
}

const closeWizard = () => {
  if (submitting.value) return

  if (currentStep.value > 0) {
    if (confirm('Are you sure you want to cancel this inspection? All data will be lost.')) {
      showWizard.value = false
      setTimeout(resetForm, 200)
    }
  } else {
    showWizard.value = false
    setTimeout(resetForm, 200)
  }
}

const resetForm = () => {
  currentStep.value = 0
  inspectionData.value = {
    extinguisherId: '',
    inspectorUserId: '',
    inspectionDate: new Date().toISOString().split('T')[0],
    inspectionType: '',
    gpsLatitude: null,
    gpsLongitude: null,
    gpsAccuracyMeters: null,
    isAccessible: true,
    hasObstructions: false,
    signageVisible: true,
    sealIntact: true,
    pinInPlace: true,
    nozzleClear: true,
    hoseConditionGood: true,
    gaugeInGreenZone: true,
    gaugePressurePsi: null,
    physicalDamagePresent: false,
    damageDescription: '',
    weightPounds: null,
    inspectionTagAttached: true,
    previousInspectionDate: null,
    notes: '',
    requiresService: false,
    requiresReplacement: false,
    failureReason: '',
    correctiveAction: '',
    photoUrls: []
  }
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
