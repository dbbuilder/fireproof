<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Navigation -->
    <nav class="bg-white shadow-sm border-b">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <div class="flex items-center space-x-8">
            <router-link to="/dashboard" class="text-xl font-bold text-gray-900">
              FireProof
            </router-link>
            <router-link to="/locations" class="text-blue-600 font-medium">
              Locations
            </router-link>
          </div>
          <div class="flex items-center">
            <button
              @click="handleLogout"
              class="px-4 py-2 text-sm text-gray-700 hover:text-gray-900"
            >
              Logout
            </button>
          </div>
        </div>
      </div>
    </nav>

    <!-- Main Content -->
    <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
      <div class="px-4 sm:px-0">
        <!-- Header -->
        <div class="flex justify-between items-center mb-6">
          <div>
            <h1 class="text-3xl font-bold text-gray-900">Locations</h1>
            <p class="mt-2 text-sm text-gray-600">
              Manage facility locations for fire extinguisher inspections
            </p>
          </div>
          <button
            @click="showCreateModal = true"
            class="px-4 py-2 bg-blue-600 text-white font-semibold rounded-lg hover:bg-blue-700 transition-colors"
          >
            + Add Location
          </button>
        </div>

        <!-- Error Display -->
        <div v-if="locationStore.error" class="mb-4 bg-red-50 border border-red-200 rounded-lg p-4">
          <p class="text-sm text-red-800">{{ locationStore.error }}</p>
          <button
            @click="locationStore.clearError()"
            class="mt-2 text-sm text-red-600 hover:text-red-800"
          >
            Dismiss
          </button>
        </div>

        <!-- Loading State -->
        <div v-if="locationStore.loading" class="text-center py-12">
          <div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
          <p class="mt-4 text-gray-600">Loading locations...</p>
        </div>

        <!-- Locations Grid -->
        <div v-else-if="locationStore.locations.length > 0" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div
            v-for="location in locationStore.locations"
            :key="location.locationId"
            class="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow"
          >
            <div class="flex justify-between items-start mb-4">
              <div>
                <h3 class="text-lg font-semibold text-gray-900">{{ location.locationName }}</h3>
                <p class="text-sm text-gray-500">{{ location.locationCode }}</p>
              </div>
              <span
                :class="[
                  'px-2 py-1 text-xs font-medium rounded-full',
                  location.isActive ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'
                ]"
              >
                {{ location.isActive ? 'Active' : 'Inactive' }}
              </span>
            </div>

            <div class="space-y-2 text-sm text-gray-600">
              <p v-if="location.addressLine1">{{ location.addressLine1 }}</p>
              <p v-if="location.city">
                {{ location.city }}{{ location.stateProvince ? ', ' + location.stateProvince : '' }}
                {{ location.postalCode }}
              </p>
              <p v-if="location.latitude && location.longitude" class="text-xs text-gray-500">
                📍 {{ location.latitude.toFixed(6) }}, {{ location.longitude.toFixed(6) }}
              </p>
            </div>

            <div class="mt-4 flex space-x-2">
              <button
                @click="handleEdit(location)"
                class="flex-1 px-3 py-2 text-sm bg-gray-100 text-gray-700 rounded hover:bg-gray-200 transition-colors"
              >
                Edit
              </button>
              <button
                @click="handleDelete(location)"
                class="px-3 py-2 text-sm bg-red-50 text-red-600 rounded hover:bg-red-100 transition-colors"
              >
                Delete
              </button>
            </div>
          </div>
        </div>

        <!-- Empty State -->
        <div v-else class="bg-white rounded-lg shadow-md p-12 text-center">
          <div class="text-6xl mb-4">📍</div>
          <h3 class="text-lg font-semibold text-gray-900 mb-2">No locations yet</h3>
          <p class="text-gray-600 mb-6">Get started by adding your first location</p>
          <button
            @click="showCreateModal = true"
            class="px-6 py-3 bg-blue-600 text-white font-semibold rounded-lg hover:bg-blue-700 transition-colors"
          >
            Add Your First Location
          </button>
        </div>
      </div>
    </main>

    <!-- Create/Edit Modal (placeholder - will be enhanced) -->
    <div
      v-if="showCreateModal || showEditModal"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50"
      @click.self="closeModals"
    >
      <div class="bg-white rounded-lg shadow-xl p-6 max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <h2 class="text-2xl font-bold text-gray-900 mb-6">
          {{ showEditModal ? 'Edit Location' : 'Add New Location' }}
        </h2>

        <form @submit.prevent="handleSubmit" class="space-y-4">
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">
                Location Code *
              </label>
              <input
                v-model="formData.locationCode"
                type="text"
                required
                :disabled="showEditModal"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="LOC001"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">
                Location Name *
              </label>
              <input
                v-model="formData.locationName"
                type="text"
                required
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="Main Office"
              />
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Address Line 1
            </label>
            <input
              v-model="formData.addressLine1"
              type="text"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="123 Main Street"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Address Line 2
            </label>
            <input
              v-model="formData.addressLine2"
              type="text"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Suite 100"
            />
          </div>

          <div class="grid grid-cols-3 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">
                City
              </label>
              <input
                v-model="formData.city"
                type="text"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="Seattle"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">
                State/Province
              </label>
              <input
                v-model="formData.stateProvince"
                type="text"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="WA"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">
                Postal Code
              </label>
              <input
                v-model="formData.postalCode"
                type="text"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="98101"
              />
            </div>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">
                Latitude
              </label>
              <input
                v-model.number="formData.latitude"
                type="number"
                step="0.000001"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="47.606209"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">
                Longitude
              </label>
              <input
                v-model.number="formData.longitude"
                type="number"
                step="0.000001"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="-122.332069"
              />
            </div>
          </div>

          <div v-if="showEditModal" class="flex items-center">
            <input
              v-model="formData.isActive"
              type="checkbox"
              class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
            />
            <label class="ml-2 block text-sm text-gray-700">
              Active
            </label>
          </div>

          <div class="flex space-x-3 pt-4">
            <button
              type="submit"
              class="flex-1 px-4 py-2 bg-blue-600 text-white font-semibold rounded-lg hover:bg-blue-700 transition-colors"
            >
              {{ showEditModal ? 'Update Location' : 'Create Location' }}
            </button>
            <button
              type="button"
              @click="closeModals"
              class="px-4 py-2 bg-gray-200 text-gray-700 font-semibold rounded-lg hover:bg-gray-300 transition-colors"
            >
              Cancel
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useLocationStore } from '@/stores/locations'

const router = useRouter()
const locationStore = useLocationStore()

const showCreateModal = ref(false)
const showEditModal = ref(false)
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
const editingLocationId = ref(null)

onMounted(async () => {
  try {
    await locationStore.fetchLocations()
  } catch (error) {
    console.error('Failed to load locations:', error)
  }
})

const handleLogout = () => {
  localStorage.removeItem('auth_token')
  router.push('/login')
}

const handleEdit = (location) => {
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
  showEditModal.value = true
}

const handleDelete = async (location) => {
  if (confirm(`Are you sure you want to delete "${location.locationName}"?`)) {
    try {
      await locationStore.deleteLocation(location.locationId)
    } catch (error) {
      console.error('Failed to delete location:', error)
    }
  }
}

const handleSubmit = async () => {
  try {
    if (showEditModal.value) {
      await locationStore.updateLocation(editingLocationId.value, formData.value)
    } else {
      await locationStore.createLocation(formData.value)
    }
    closeModals()
  } catch (error) {
    console.error('Form submission error:', error)
  }
}

const closeModals = () => {
  showCreateModal.value = false
  showEditModal.value = false
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
</script>
