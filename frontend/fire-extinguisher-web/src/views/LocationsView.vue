<template>
  <AppLayout>
    <div>
      <!-- Header -->
      <div class="flex justify-between items-center mb-8">
        <div>
          <h1 class="text-3xl font-display font-semibold text-gray-900 mb-2">
            Locations
          </h1>
          <p class="text-gray-600">
            Manage facility locations for fire extinguisher inspections
          </p>
        </div>
        <button
          class="btn-primary inline-flex items-center"
          @click="openCreateModal"
        >
          <PlusIcon class="h-5 w-5 mr-2" />
          Add Location
        </button>
      </div>

      <!-- Error Alert -->
      <div
        v-if="locationStore.error"
        class="alert-danger mb-6"
      >
        <XCircleIcon class="h-5 w-5" />
        <div class="flex-1">
          <p class="text-sm font-medium">
            {{ locationStore.error }}
          </p>
        </div>
        <button
          type="button"
          class="text-red-400 hover:text-red-600"
          @click="locationStore.clearError()"
        >
          <XMarkIcon class="h-5 w-5" />
        </button>
      </div>

      <!-- Loading State -->
      <div
        v-if="locationStore.loading"
        class="card"
      >
        <div class="p-12 text-center">
          <div class="spinner-lg mx-auto mb-4" />
          <p class="text-gray-600">
            Loading locations...
          </p>
        </div>
      </div>

      <!-- Locations Grid -->
      <div
        v-else-if="locationStore.locations.length > 0"
        class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
      >
        <div
          v-for="location in locationStore.locations"
          :key="location.locationId"
          class="card hover:shadow-lg transition-all duration-200 group"
        >
          <div class="p-6">
            <!-- Header -->
            <div class="flex justify-between items-start mb-4">
              <div class="flex-1">
                <h3 class="text-lg font-semibold text-gray-900 mb-1">
                  {{ location.locationName }}
                </h3>
                <p class="text-sm text-gray-500">
                  {{ location.locationCode }}
                </p>
              </div>
              <span
                :class="[
                  'badge-success',
                  !location.isActive && 'badge-secondary'
                ]"
              >
                {{ location.isActive ? 'Active' : 'Inactive' }}
              </span>
            </div>

            <!-- Address -->
            <div class="space-y-1 text-sm text-gray-600 mb-4">
              <div
                v-if="location.addressLine1"
                class="flex items-start"
              >
                <MapPinIcon class="h-4 w-4 mr-2 mt-0.5 flex-shrink-0 text-gray-400" />
                <div>
                  <p>{{ location.addressLine1 }}</p>
                  <p v-if="location.addressLine2">
                    {{ location.addressLine2 }}
                  </p>
                  <p v-if="location.city">
                    {{ location.city }}{{ location.stateProvince ? ', ' + location.stateProvince : '' }}
                    {{ location.postalCode }}
                  </p>
                </div>
              </div>

              <!-- GPS Coordinates -->
              <div
                v-if="location.latitude && location.longitude"
                class="flex items-center text-xs text-gray-500 mt-2"
              >
                <GlobeAltIcon class="h-4 w-4 mr-1" />
                {{ location.latitude.toFixed(6) }}, {{ location.longitude.toFixed(6) }}
              </div>
            </div>

            <!-- Actions -->
            <div class="flex space-x-2 pt-4 border-t border-gray-100">
              <button
                class="flex-1 inline-flex items-center justify-center px-3 py-2 text-sm font-medium text-gray-700 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
                @click="openEditModal(location)"
              >
                <PencilIcon class="h-4 w-4 mr-1.5" />
                Edit
              </button>
              <button
                class="inline-flex items-center justify-center px-3 py-2 text-sm font-medium text-red-600 bg-red-50 rounded-lg hover:bg-red-100 transition-colors"
                @click="confirmDelete(location)"
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
            <MapPinIcon class="h-8 w-8 text-primary-600" />
          </div>
          <h3 class="text-lg font-semibold text-gray-900 mb-2">
            No locations yet
          </h3>
          <p class="text-gray-600 mb-6">
            Get started by adding your first facility location
          </p>
          <button
            class="btn-primary inline-flex items-center"
            @click="openCreateModal"
          >
            <PlusIcon class="h-5 w-5 mr-2" />
            Add Your First Location
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
          <div class="modal-container">
            <div class="modal-content">
              <!-- Modal Header -->
              <div class="flex items-center justify-between mb-6">
                <h2 class="text-2xl font-display font-semibold text-gray-900">
                  {{ isEditing ? 'Edit Location' : 'Add New Location' }}
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
                <div class="grid grid-cols-2 gap-4">
                  <!-- Location Code -->
                  <div>
                    <label
                      for="locationCode"
                      class="form-label"
                    >
                      Location Code *
                    </label>
                    <input
                      id="locationCode"
                      v-model="formData.locationCode"
                      type="text"
                      required
                      :disabled="isEditing"
                      class="form-input"
                      :class="{ 'bg-gray-50': isEditing }"
                      placeholder="LOC001"
                    >
                    <p class="form-helper">
                      Unique identifier (cannot be changed)
                    </p>
                  </div>

                  <!-- Location Name -->
                  <div>
                    <label
                      for="locationName"
                      class="form-label"
                    >
                      Location Name *
                    </label>
                    <input
                      id="locationName"
                      v-model="formData.locationName"
                      type="text"
                      required
                      class="form-input"
                      placeholder="Main Office"
                    >
                  </div>
                </div>

                <!-- Address Line 1 -->
                <div>
                  <label
                    for="addressLine1"
                    class="form-label"
                  >
                    Address Line 1
                  </label>
                  <input
                    id="addressLine1"
                    v-model="formData.addressLine1"
                    type="text"
                    class="form-input"
                    placeholder="123 Main Street"
                  >
                </div>

                <!-- Address Line 2 -->
                <div>
                  <label
                    for="addressLine2"
                    class="form-label"
                  >
                    Address Line 2
                  </label>
                  <input
                    id="addressLine2"
                    v-model="formData.addressLine2"
                    type="text"
                    class="form-input"
                    placeholder="Suite 100"
                  >
                </div>

                <div class="grid grid-cols-3 gap-4">
                  <!-- City -->
                  <div>
                    <label
                      for="city"
                      class="form-label"
                    >
                      City
                    </label>
                    <input
                      id="city"
                      v-model="formData.city"
                      type="text"
                      class="form-input"
                      placeholder="Seattle"
                    >
                  </div>

                  <!-- State/Province -->
                  <div>
                    <label
                      for="stateProvince"
                      class="form-label"
                    >
                      State/Province
                    </label>
                    <input
                      id="stateProvince"
                      v-model="formData.stateProvince"
                      type="text"
                      class="form-input"
                      placeholder="WA"
                    >
                  </div>

                  <!-- Postal Code -->
                  <div>
                    <label
                      for="postalCode"
                      class="form-label"
                    >
                      Postal Code
                    </label>
                    <input
                      id="postalCode"
                      v-model="formData.postalCode"
                      type="text"
                      class="form-input"
                      placeholder="98101"
                    >
                  </div>
                </div>

                <!-- GPS Coordinates -->
                <div class="grid grid-cols-2 gap-4">
                  <div>
                    <label
                      for="latitude"
                      class="form-label"
                    >
                      Latitude
                    </label>
                    <input
                      id="latitude"
                      v-model.number="formData.latitude"
                      type="number"
                      step="0.000001"
                      class="form-input"
                      placeholder="47.606209"
                    >
                  </div>

                  <div>
                    <label
                      for="longitude"
                      class="form-label"
                    >
                      Longitude
                    </label>
                    <input
                      id="longitude"
                      v-model.number="formData.longitude"
                      type="number"
                      step="0.000001"
                      class="form-input"
                      placeholder="-122.332069"
                    >
                  </div>
                </div>

                <!-- Active Status (Edit only) -->
                <div
                  v-if="isEditing"
                  class="flex items-center"
                >
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
                    Active location
                  </label>
                </div>

                <!-- Form Actions -->
                <div class="flex space-x-3 pt-4">
                  <button
                    type="submit"
                    :disabled="submitting"
                    class="btn-primary flex-1"
                  >
                    <span v-if="!submitting">{{ isEditing ? 'Update Location' : 'Create Location' }}</span>
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
  </AppLayout>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useLocationStore } from '@/stores/locations'
import { useToastStore } from '@/stores/toast'
import AppLayout from '@/components/layout/AppLayout.vue'
import {
  PlusIcon,
  MapPinIcon,
  GlobeAltIcon,
  PencilIcon,
  TrashIcon,
  XMarkIcon,
  XCircleIcon
} from '@heroicons/vue/24/outline'

const locationStore = useLocationStore()
const toast = useToastStore()

const showModal = ref(false)
const isEditing = ref(false)
const editingLocationId = ref(null)
const submitting = ref(false)

const formData = ref({
  locationCode: '',
  locationName: '',
  addressLine1: '',
  addressLine2: '',
  city: '',
  stateProvince: '',
  postalCode: '',
  country: 'USA',
  latitude: null,
  longitude: null,
  isActive: true
})

onMounted(async () => {
  try {
    await locationStore.fetchLocations()
  } catch (error) {
    console.error('Failed to load locations:', error)
    toast.error('Failed to load locations')
  }
})

const openCreateModal = () => {
  resetForm()
  isEditing.value = false
  showModal.value = true
}

const openEditModal = (location) => {
  editingLocationId.value = location.locationId
  formData.value = {
    locationCode: location.locationCode,
    locationName: location.locationName,
    addressLine1: location.addressLine1 || '',
    addressLine2: location.addressLine2 || '',
    city: location.city || '',
    stateProvince: location.stateProvince || '',
    postalCode: location.postalCode || '',
    country: location.country || 'USA',
    latitude: location.latitude,
    longitude: location.longitude,
    isActive: location.isActive
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
  editingLocationId.value = null
  formData.value = {
    locationCode: '',
    locationName: '',
    addressLine1: '',
    addressLine2: '',
    city: '',
    stateProvince: '',
    postalCode: '',
    country: 'USA',
    latitude: null,
    longitude: null,
    isActive: true
  }
}

const handleSubmit = async () => {
  submitting.value = true

  try {
    if (isEditing.value) {
      await locationStore.updateLocation(editingLocationId.value, formData.value)
      toast.success('Location updated successfully')
    } else {
      await locationStore.createLocation(formData.value)
      toast.success('Location created successfully')
    }
    closeModal()
  } catch (error) {
    console.error('Form submission error:', error)
    toast.error(error.response?.data?.message || 'Failed to save location')
  } finally {
    submitting.value = false
  }
}

const confirmDelete = async (location) => {
  if (confirm(`Are you sure you want to delete "${location.locationName}"?\n\nThis action cannot be undone.`)) {
    try {
      await locationStore.deleteLocation(location.locationId)
      toast.success('Location deleted successfully')
    } catch (error) {
      console.error('Failed to delete location:', error)
      toast.error('Failed to delete location')
    }
  }
}
</script>
