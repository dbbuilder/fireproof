<template>
  <AppLayout>
    <div>
      <!-- Header -->
      <div class="flex justify-between items-center mb-8">
        <div>
          <h1 class="text-3xl font-display font-semibold text-gray-900 mb-2">
            Fire Extinguishers
          </h1>
          <p class="text-gray-600">
            Manage fire extinguisher inventory and track service schedules
          </p>
        </div>
        <button
          class="btn-primary inline-flex items-center"
          @click="openCreateModal"
        >
          <PlusIcon class="h-5 w-5 mr-2" />
          Add Extinguisher
        </button>
      </div>

      <!-- Stats Cards -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
        <div class="card">
          <div class="p-4">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-gray-600">
                  Total
                </p>
                <p class="text-2xl font-bold text-gray-900">
                  {{ extinguisherStore.extinguisherCount }}
                </p>
              </div>
              <ShieldCheckIcon class="h-8 w-8 text-gray-400" />
            </div>
          </div>
        </div>

        <div class="card">
          <div class="p-4">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-gray-600">
                  Active
                </p>
                <p class="text-2xl font-bold text-secondary-600">
                  {{ extinguisherStore.activeExtinguishers.length }}
                </p>
              </div>
              <CheckCircleIcon class="h-8 w-8 text-secondary-400" />
            </div>
          </div>
        </div>

        <div class="card">
          <div class="p-4">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-gray-600">
                  Out of Service
                </p>
                <p class="text-2xl font-bold text-red-600">
                  {{ extinguisherStore.outOfServiceExtinguishers.length }}
                </p>
              </div>
              <ExclamationTriangleIcon class="h-8 w-8 text-red-400" />
            </div>
          </div>
        </div>

        <div class="card">
          <div class="p-4">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-gray-600">
                  Need Attention
                </p>
                <p class="text-2xl font-bold text-accent-600">
                  {{ extinguisherStore.needingAttention.length }}
                </p>
              </div>
              <ClockIcon class="h-8 w-8 text-accent-400" />
            </div>
          </div>
        </div>
      </div>

      <!-- Error Alert -->
      <div
        v-if="extinguisherStore.error"
        class="alert-danger mb-6"
      >
        <XCircleIcon class="h-5 w-5" />
        <div class="flex-1">
          <p class="text-sm font-medium">
            {{ extinguisherStore.error }}
          </p>
        </div>
        <button
          type="button"
          class="text-red-400 hover:text-red-600"
          @click="extinguisherStore.clearError()"
        >
          <XMarkIcon class="h-5 w-5" />
        </button>
      </div>

      <!-- Loading State -->
      <div
        v-if="extinguisherStore.loading && extinguisherStore.extinguishers.length === 0"
        class="card"
      >
        <div class="p-12 text-center">
          <div class="spinner-lg mx-auto mb-4" />
          <p class="text-gray-600">
            Loading extinguishers...
          </p>
        </div>
      </div>

      <!-- Extinguishers Grid -->
      <div
        v-else-if="extinguisherStore.extinguishers.length > 0"
        class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
      >
        <div
          v-for="extinguisher in extinguisherStore.extinguishers"
          :key="extinguisher.extinguisherId"
          class="card hover:shadow-lg transition-all duration-200"
          :class="{
            'border-2 border-red-200 bg-red-50': extinguisher.isOutOfService,
            'border-2 border-accent-200': needsAttention(extinguisher)
          }"
        >
          <div class="p-6">
            <!-- Header -->
            <div class="flex justify-between items-start mb-4">
              <div class="flex-1">
                <h3 class="text-lg font-semibold text-gray-900 mb-1">
                  {{ extinguisher.extinguisherCode }}
                </h3>
                <p class="text-sm text-gray-500">
                  {{ extinguisher.typeName || 'Type Unknown' }}
                </p>
              </div>
              <div class="flex flex-col items-end space-y-1">
                <span
                  v-if="extinguisher.isOutOfService"
                  class="badge-danger text-xs"
                >
                  Out of Service
                </span>
                <span
                  v-else-if="!extinguisher.isActive"
                  class="badge-secondary text-xs"
                >
                  Inactive
                </span>
                <span
                  v-else
                  class="badge-success text-xs"
                >
                  Active
                </span>
                <span
                  v-if="needsAttention(extinguisher)"
                  class="badge-warning text-xs"
                >
                  Service Due
                </span>
              </div>
            </div>

            <!-- Details -->
            <div class="space-y-2 text-sm text-gray-600 mb-4">
              <div class="flex items-center">
                <MapPinIcon class="h-4 w-4 mr-2 text-gray-400" />
                <span>{{ extinguisher.locationName || 'No Location' }}</span>
              </div>

              <div
                v-if="extinguisher.serialNumber"
                class="flex items-center"
              >
                <IdentificationIcon class="h-4 w-4 mr-2 text-gray-400" />
                <span>SN: {{ extinguisher.serialNumber }}</span>
              </div>

              <div
                v-if="extinguisher.manufacturer"
                class="flex items-center"
              >
                <BuildingOfficeIcon class="h-4 w-4 mr-2 text-gray-400" />
                <span>{{ extinguisher.manufacturer }}</span>
              </div>

              <div
                v-if="extinguisher.locationDescription"
                class="flex items-center"
              >
                <InformationCircleIcon class="h-4 w-4 mr-2 text-gray-400" />
                <span class="truncate">{{ extinguisher.locationDescription }}</span>
              </div>

              <!-- Service Dates -->
              <div
                v-if="extinguisher.nextServiceDueDate"
                class="flex items-center"
              >
                <CalendarIcon class="h-4 w-4 mr-2 text-gray-400" />
                <span class="text-xs">
                  Next Service: {{ formatDate(extinguisher.nextServiceDueDate) }}
                </span>
              </div>
            </div>

            <!-- Actions -->
            <div class="flex space-x-2 pt-4 border-t border-gray-100">
              <button
                class="flex-1 inline-flex items-center justify-center px-3 py-2 text-sm font-medium text-gray-700 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
                @click="openEditModal(extinguisher)"
              >
                <PencilIcon class="h-4 w-4 mr-1.5" />
                Edit
              </button>
              <button
                v-if="extinguisher.qrCodeData"
                class="inline-flex items-center justify-center px-3 py-2 text-sm font-medium text-primary-600 bg-primary-50 rounded-lg hover:bg-primary-100 transition-colors"
                title="View QR Code"
                @click="showQRCode(extinguisher)"
              >
                <QrCodeIcon class="h-4 w-4" />
              </button>
              <button
                v-else
                class="inline-flex items-center justify-center px-3 py-2 text-sm font-medium text-primary-600 bg-primary-50 rounded-lg hover:bg-primary-100 transition-colors"
                title="Generate QR Code"
                @click="generateQRCode(extinguisher)"
              >
                <SparklesIcon class="h-4 w-4" />
              </button>
              <button
                class="inline-flex items-center justify-center px-3 py-2 text-sm font-medium text-red-600 bg-red-50 rounded-lg hover:bg-red-100 transition-colors"
                @click="confirmDelete(extinguisher)"
              >
                <TrashIcon class="h-4 w-4" />
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Empty State -->
      <div
        v-else
        class="card"
      >
        <div class="p-12 text-center">
          <div class="inline-flex items-center justify-center w-16 h-16 rounded-full bg-primary-100 mb-4">
            <ShieldCheckIcon class="h-8 w-8 text-primary-600" />
          </div>
          <h3 class="text-lg font-semibold text-gray-900 mb-2">
            No extinguishers yet
          </h3>
          <p class="text-gray-600 mb-6">
            Get started by adding your first fire extinguisher
          </p>
          <button
            class="btn-primary inline-flex items-center"
            @click="openCreateModal"
          >
            <PlusIcon class="h-5 w-5 mr-2" />
            Add First Extinguisher
          </button>
        </div>
      </div>
    </div>

    <!-- Create/Edit Modal -->
    <transition
      enter-active-class="transition ease-out duration-200"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="transition ease-in duration-150"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div
        v-if="showModal"
        class="modal-overlay"
        @click.self="closeModal"
      >
        <transition
          enter-active-class="transition ease-out duration-200"
          enter-from-class="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
          enter-to-class="opacity-100 translate-y-0 sm:scale-100"
          leave-active-class="transition ease-in duration-150"
          leave-from-class="opacity-100 translate-y-0 sm:scale-100"
          leave-to-class="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
        >
          <div class="modal-container max-w-3xl">
            <div class="modal-content max-h-[90vh] overflow-y-auto">
              <!-- Modal Header -->
              <div class="flex items-center justify-between mb-6 sticky top-0 bg-white pb-4 border-b">
                <h2 class="text-2xl font-display font-semibold text-gray-900">
                  {{ isEditing ? 'Edit Extinguisher' : 'Add New Extinguisher' }}
                </h2>
                <button
                  type="button"
                  class="text-gray-400 hover:text-gray-600 transition-colors"
                  @click="closeModal"
                >
                  <XMarkIcon class="h-6 w-6" />
                </button>
              </div>

              <!-- Form -->
              <form
                class="space-y-5"
                @submit.prevent="handleSubmit"
              >
                <!-- Basic Information -->
                <div class="grid grid-cols-2 gap-4">
                  <!-- Extinguisher Code -->
                  <div>
                    <label
                      for="extinguisherCode"
                      class="form-label"
                    >
                      Extinguisher Code *
                    </label>
                    <input
                      id="extinguisherCode"
                      v-model="formData.extinguisherCode"
                      type="text"
                      required
                      :disabled="isEditing"
                      class="form-input"
                      :class="{ 'bg-gray-50': isEditing }"
                      placeholder="EXT-001"
                    >
                    <p class="form-helper">
                      Unique identifier (cannot be changed)
                    </p>
                  </div>

                  <!-- Serial Number -->
                  <div>
                    <label
                      for="serialNumber"
                      class="form-label"
                    >
                      Serial Number *
                    </label>
                    <input
                      id="serialNumber"
                      v-model="formData.serialNumber"
                      type="text"
                      required
                      class="form-input"
                      placeholder="SN123456"
                    >
                  </div>
                </div>

                <!-- Location and Type -->
                <div class="grid grid-cols-2 gap-4">
                  <!-- Location -->
                  <div>
                    <label
                      for="locationId"
                      class="form-label"
                    >
                      Location *
                    </label>
                    <select
                      id="locationId"
                      v-model="formData.locationId"
                      required
                      class="form-input"
                    >
                      <option value="">
                        Select location...
                      </option>
                      <option
                        v-for="location in locationStore.locations"
                        :key="location.locationId"
                        :value="location.locationId"
                      >
                        {{ location.locationName }}
                      </option>
                    </select>
                  </div>

                  <!-- Extinguisher Type -->
                  <div>
                    <label
                      for="extinguisherTypeId"
                      class="form-label"
                    >
                      Extinguisher Type *
                    </label>
                    <select
                      id="extinguisherTypeId"
                      v-model="formData.extinguisherTypeId"
                      required
                      class="form-input"
                    >
                      <option value="">
                        Select type...
                      </option>
                      <option
                        v-for="type in typeStore.activeTypes"
                        :key="type.extinguisherTypeId"
                        :value="type.extinguisherTypeId"
                      >
                        {{ type.typeName }} ({{ type.agentType }})
                      </option>
                    </select>
                  </div>
                </div>

                <!-- Manufacturer and Asset Tag -->
                <div class="grid grid-cols-2 gap-4">
                  <div>
                    <label
                      for="manufacturer"
                      class="form-label"
                    >
                      Manufacturer
                    </label>
                    <input
                      id="manufacturer"
                      v-model="formData.manufacturer"
                      type="text"
                      class="form-input"
                      placeholder="Ansul, Amerex, etc."
                    >
                  </div>

                  <div>
                    <label
                      for="assetTag"
                      class="form-label"
                    >
                      Asset Tag
                    </label>
                    <input
                      id="assetTag"
                      v-model="formData.assetTag"
                      type="text"
                      class="form-input"
                      placeholder="ASSET-001"
                    >
                  </div>
                </div>

                <!-- Dates -->
                <div class="grid grid-cols-3 gap-4">
                  <div>
                    <label
                      for="manufactureDate"
                      class="form-label"
                    >
                      Manufacture Date
                    </label>
                    <input
                      id="manufactureDate"
                      v-model="formData.manufactureDate"
                      type="date"
                      class="form-input"
                    >
                  </div>

                  <div>
                    <label
                      for="installDate"
                      class="form-label"
                    >
                      Install Date
                    </label>
                    <input
                      id="installDate"
                      v-model="formData.installDate"
                      type="date"
                      class="form-input"
                    >
                  </div>

                  <div v-if="isEditing">
                    <label
                      for="lastServiceDate"
                      class="form-label"
                    >
                      Last Service Date
                    </label>
                    <input
                      id="lastServiceDate"
                      v-model="formData.lastServiceDate"
                      type="date"
                      class="form-input"
                    >
                  </div>
                </div>

                <!-- Location Description -->
                <div>
                  <label
                    for="locationDescription"
                    class="form-label"
                  >
                    Location Description
                  </label>
                  <input
                    id="locationDescription"
                    v-model="formData.locationDescription"
                    type="text"
                    class="form-input"
                    placeholder="Near main entrance, by stairwell A, etc."
                  >
                </div>

                <div class="grid grid-cols-2 gap-4">
                  <div>
                    <label
                      for="floorLevel"
                      class="form-label"
                    >
                      Floor Level
                    </label>
                    <input
                      id="floorLevel"
                      v-model="formData.floorLevel"
                      type="text"
                      class="form-input"
                      placeholder="1st Floor, Basement, etc."
                    >
                  </div>
                </div>

                <!-- Notes -->
                <div>
                  <label
                    for="notes"
                    class="form-label"
                  >
                    Notes
                  </label>
                  <textarea
                    id="notes"
                    v-model="formData.notes"
                    rows="3"
                    class="form-input"
                    placeholder="Additional notes..."
                  />
                </div>

                <!-- Status Checkboxes (Edit only) -->
                <div
                  v-if="isEditing"
                  class="space-y-3 p-4 bg-gray-50 rounded-lg"
                >
                  <div class="flex items-center">
                    <input
                      id="isActive"
                      v-model="formData.isActive"
                      type="checkbox"
                      class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                    >
                    <label
                      for="isActive"
                      class="ml-2 block text-sm text-gray-700"
                    >
                      Active extinguisher
                    </label>
                  </div>

                  <div class="flex items-center">
                    <input
                      id="isOutOfService"
                      v-model="formData.isOutOfService"
                      type="checkbox"
                      class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                    >
                    <label
                      for="isOutOfService"
                      class="ml-2 block text-sm text-gray-700"
                    >
                      Out of service
                    </label>
                  </div>

                  <div v-if="formData.isOutOfService">
                    <label
                      for="outOfServiceReason"
                      class="form-label"
                    >
                      Out of Service Reason
                    </label>
                    <textarea
                      id="outOfServiceReason"
                      v-model="formData.outOfServiceReason"
                      rows="2"
                      class="form-input"
                      placeholder="Reason for being out of service..."
                    />
                  </div>
                </div>

                <!-- Form Actions -->
                <div class="flex space-x-3 pt-4 sticky bottom-0 bg-white border-t">
                  <button
                    type="submit"
                    :disabled="submitting"
                    class="btn-primary flex-1"
                  >
                    <span v-if="!submitting">{{ isEditing ? 'Update Extinguisher' : 'Create Extinguisher' }}</span>
                    <span
                      v-else
                      class="flex items-center justify-center"
                    >
                      <div class="spinner mr-2" />
                      {{ isEditing ? 'Updating...' : 'Creating...' }}
                    </span>
                  </button>
                  <button
                    type="button"
                    :disabled="submitting"
                    class="btn-outline"
                    @click="closeModal"
                  >
                    Cancel
                  </button>
                </div>
              </form>
            </div>
          </div>
        </transition>
      </div>
    </transition>

    <!-- QR Code Modal -->
    <transition
      enter-active-class="transition ease-out duration-200"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="transition ease-in duration-150"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div
        v-if="showQRModal"
        class="modal-overlay"
        @click.self="closeQRModal"
      >
        <div class="modal-container max-w-md">
          <div class="modal-content text-center">
            <h3 class="text-xl font-semibold text-gray-900 mb-4">
              QR Code for {{ selectedExtinguisher?.extinguisherCode }}
            </h3>
            <div class="bg-white p-4 rounded-lg inline-block mb-4">
              <img
                :src="selectedExtinguisher?.qrCodeData"
                alt="QR Code"
                class="w-64 h-64"
              >
            </div>
            <p class="text-sm text-gray-600 mb-4">
              Scan this code to quickly access extinguisher information
            </p>
            <button
              class="btn-primary"
              @click="closeQRModal"
            >
              Close
            </button>
          </div>
        </div>
      </div>
    </transition>
  </AppLayout>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useExtinguisherStore } from '@/stores/extinguishers'
import { useExtinguisherTypeStore } from '@/stores/extinguisherTypes'
import { useLocationStore } from '@/stores/locations'
import { useToastStore } from '@/stores/toast'
import AppLayout from '@/components/layout/AppLayout.vue'
import {
  PlusIcon,
  ShieldCheckIcon,
  MapPinIcon,
  PencilIcon,
  TrashIcon,
  XMarkIcon,
  XCircleIcon,
  CheckCircleIcon,
  ExclamationTriangleIcon,
  ClockIcon,
  IdentificationIcon,
  BuildingOfficeIcon,
  InformationCircleIcon,
  CalendarIcon,
  QrCodeIcon,
  SparklesIcon
} from '@heroicons/vue/24/outline'

const extinguisherStore = useExtinguisherStore()
const typeStore = useExtinguisherTypeStore()
const locationStore = useLocationStore()
const toast = useToastStore()

const showModal = ref(false)
const showQRModal = ref(false)
const isEditing = ref(false)
const editingExtinguisherId = ref(null)
const submitting = ref(false)
const selectedExtinguisher = ref(null)

const formData = ref({
  extinguisherCode: '',
  serialNumber: '',
  locationId: '',
  extinguisherTypeId: '',
  assetTag: '',
  manufacturer: '',
  manufactureDate: '',
  installDate: '',
  lastServiceDate: '',
  locationDescription: '',
  floorLevel: '',
  notes: '',
  isActive: true,
  isOutOfService: false,
  outOfServiceReason: ''
})

onMounted(async () => {
  try {
    await Promise.all([
      extinguisherStore.fetchExtinguishers(),
      typeStore.fetchTypes(true), // Only active types
      locationStore.fetchLocations()
    ])
  } catch (error) {
    console.error('Failed to load data:', error)
    toast.error('Failed to load data')
  }
})

const needsAttention = (extinguisher) => {
  const now = new Date()
  const thirtyDaysFromNow = new Date()
  thirtyDaysFromNow.setDate(now.getDate() + 30)

  const nextService = extinguisher.nextServiceDueDate ? new Date(extinguisher.nextServiceDueDate) : null
  const nextHydro = extinguisher.nextHydroTestDueDate ? new Date(extinguisher.nextHydroTestDueDate) : null

  return (nextService && nextService <= thirtyDaysFromNow) || (nextHydro && nextHydro <= thirtyDaysFromNow)
}

const formatDate = (dateString) => {
  if (!dateString) return 'Not set'
  const date = new Date(dateString)
  return date.toLocaleDateString()
}

const openCreateModal = () => {
  resetForm()
  isEditing.value = false
  showModal.value = true
}

const openEditModal = (extinguisher) => {
  editingExtinguisherId.value = extinguisher.extinguisherId
  formData.value = {
    extinguisherCode: extinguisher.extinguisherCode,
    serialNumber: extinguisher.serialNumber,
    locationId: extinguisher.locationId,
    extinguisherTypeId: extinguisher.extinguisherTypeId,
    assetTag: extinguisher.assetTag || '',
    manufacturer: extinguisher.manufacturer || '',
    manufactureDate: extinguisher.manufactureDate ? extinguisher.manufactureDate.split('T')[0] : '',
    installDate: extinguisher.installDate ? extinguisher.installDate.split('T')[0] : '',
    lastServiceDate: extinguisher.lastServiceDate ? extinguisher.lastServiceDate.split('T')[0] : '',
    locationDescription: extinguisher.locationDescription || '',
    floorLevel: extinguisher.floorLevel || '',
    notes: extinguisher.notes || '',
    isActive: extinguisher.isActive,
    isOutOfService: extinguisher.isOutOfService,
    outOfServiceReason: extinguisher.outOfServiceReason || ''
  }
  isEditing.value = true
  showModal.value = true
}

const closeModal = () => {
  showModal.value = false
  setTimeout(() => {
    resetForm()
  }, 200)
}

const resetForm = () => {
  isEditing.value = false
  editingExtinguisherId.value = null
  formData.value = {
    extinguisherCode: '',
    serialNumber: '',
    locationId: '',
    extinguisherTypeId: '',
    assetTag: '',
    manufacturer: '',
    manufactureDate: '',
    installDate: '',
    lastServiceDate: '',
    locationDescription: '',
    floorLevel: '',
    notes: '',
    isActive: true,
    isOutOfService: false,
    outOfServiceReason: ''
  }
}

const handleSubmit = async () => {
  submitting.value = true

  try {
    // Clean up empty strings to null for optional fields
    const cleanData = {
      ...formData.value,
      assetTag: formData.value.assetTag || null,
      manufacturer: formData.value.manufacturer || null,
      manufactureDate: formData.value.manufactureDate || null,
      installDate: formData.value.installDate || null,
      lastServiceDate: formData.value.lastServiceDate || null,
      locationDescription: formData.value.locationDescription || null,
      floorLevel: formData.value.floorLevel || null,
      notes: formData.value.notes || null,
      outOfServiceReason: formData.value.outOfServiceReason || null
    }

    if (isEditing.value) {
      await extinguisherStore.updateExtinguisher(editingExtinguisherId.value, cleanData)
      toast.success('Extinguisher updated successfully')
    } else {
      await extinguisherStore.createExtinguisher(cleanData)
      toast.success('Extinguisher created successfully')
    }
    closeModal()
  } catch (error) {
    console.error('Form submission error:', error)
    toast.error(error.response?.data?.message || 'Failed to save extinguisher')
  } finally {
    submitting.value = false
  }
}

const confirmDelete = async (extinguisher) => {
  if (confirm(`Are you sure you want to delete "${extinguisher.extinguisherCode}"?\n\nThis action cannot be undone.`)) {
    try {
      await extinguisherStore.deleteExtinguisher(extinguisher.extinguisherId)
      toast.success('Extinguisher deleted successfully')
    } catch (error) {
      console.error('Failed to delete extinguisher:', error)
      toast.error('Failed to delete extinguisher')
    }
  }
}

const generateQRCode = async (extinguisher) => {
  try {
    const response = await extinguisherStore.generateBarcode(extinguisher.extinguisherId)
    toast.success('QR Code generated successfully')
    selectedExtinguisher.value = extinguisher
    showQRModal.value = true
  } catch (error) {
    console.error('Failed to generate QR code:', error)
    toast.error('Failed to generate QR code')
  }
}

const showQRCode = (extinguisher) => {
  selectedExtinguisher.value = extinguisher
  showQRModal.value = true
}

const closeQRModal = () => {
  showQRModal.value = false
  selectedExtinguisher.value = null
}
</script>
