<template>
  <AppLayout>
    <div>
      <!-- Header -->
      <div class="flex justify-between items-center mb-8">
        <div>
          <h1 class="text-3xl font-display font-semibold text-gray-900 mb-2">
            Extinguisher Types
          </h1>
          <p class="text-gray-600">
            Manage fire extinguisher type specifications and configurations
          </p>
        </div>
        <button
          class="btn-primary inline-flex items-center"
          @click="openCreateModal"
        >
          <PlusIcon class="h-5 w-5 mr-2" />
          Add Type
        </button>
      </div>

      <!-- Error Alert -->
      <div
        v-if="typeStore.error"
        class="alert-danger mb-6"
      >
        <XCircleIcon class="h-5 w-5" />
        <div class="flex-1">
          <p class="text-sm font-medium">
            {{ typeStore.error }}
          </p>
        </div>
        <button
          type="button"
          class="text-red-400 hover:text-red-600"
          @click="typeStore.clearError()"
        >
          <XMarkIcon class="h-5 w-5" />
        </button>
      </div>

      <!-- Loading State -->
      <div
        v-if="typeStore.loading && typeStore.types.length === 0"
        class="card"
      >
        <div class="p-12 text-center">
          <div class="spinner-lg mx-auto mb-4" />
          <p class="text-gray-600">
            Loading extinguisher types...
          </p>
        </div>
      </div>

      <!-- Types Table -->
      <div
        v-else-if="typeStore.types.length > 0"
        class="card"
      >
        <div class="table-container">
          <table class="table">
            <thead>
              <tr>
                <th>Type Code</th>
                <th>Type Name</th>
                <th>Agent Type</th>
                <th>Capacity</th>
                <th>Fire Class</th>
                <th>Service Life</th>
                <th>Status</th>
                <th class="text-right">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="type in typeStore.types"
                :key="type.extinguisherTypeId"
              >
                <td class="font-mono text-sm">
                  {{ type.typeCode }}
                </td>
                <td class="font-medium">
                  {{ type.typeName }}
                </td>
                <td>
                  <span class="badge-info">{{ type.agentType || 'N/A' }}</span>
                </td>
                <td class="text-sm text-gray-600">
                  {{ type.capacity ? `${type.capacity} ${type.capacityUnit || 'lbs'}` : 'N/A' }}
                </td>
                <td>
                  <div class="flex flex-wrap gap-1">
                    <span
                      v-for="cls in parseFireClasses(type.fireClassRating)"
                      :key="cls"
                      class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-red-100 text-red-800"
                    >
                      Class {{ cls }}
                    </span>
                    <span
                      v-if="!type.fireClassRating"
                      class="text-gray-400 text-sm"
                    >N/A</span>
                  </div>
                </td>
                <td class="text-sm text-gray-600">
                  {{ type.serviceLifeYears ? `${type.serviceLifeYears} years` : 'N/A' }}
                </td>
                <td>
                  <span
                    :class="type.isActive ? 'badge-success' : 'badge-secondary'"
                  >
                    {{ type.isActive ? 'Active' : 'Inactive' }}
                  </span>
                </td>
                <td class="text-right">
                  <div class="flex justify-end space-x-2">
                    <button
                      class="inline-flex items-center px-3 py-1.5 text-sm font-medium text-gray-700 bg-gray-50 rounded hover:bg-gray-100 transition-colors"
                      @click="openEditModal(type)"
                    >
                      <PencilIcon class="h-4 w-4 mr-1" />
                      Edit
                    </button>
                    <button
                      class="inline-flex items-center px-3 py-1.5 text-sm font-medium text-red-600 bg-red-50 rounded hover:bg-red-100 transition-colors"
                      @click="confirmDelete(type)"
                    >
                      <TrashIcon class="h-4 w-4" />
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Empty State -->
      <div
        v-else
        class="card"
      >
        <div class="p-12 text-center">
          <div class="inline-flex items-center justify-center w-16 h-16 rounded-full bg-primary-100 mb-4">
            <BeakerIcon class="h-8 w-8 text-primary-600" />
          </div>
          <h3 class="text-lg font-semibold text-gray-900 mb-2">
            No extinguisher types yet
          </h3>
          <p class="text-gray-600 mb-6">
            Create type specifications before adding extinguishers
          </p>
          <button
            class="btn-primary inline-flex items-center"
            @click="openCreateModal"
          >
            <PlusIcon class="h-5 w-5 mr-2" />
            Add First Type
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
          <div class="modal-container max-w-2xl">
            <div class="modal-content max-h-[90vh] overflow-y-auto">
              <!-- Modal Header -->
              <div class="flex items-center justify-between mb-6 sticky top-0 bg-white pb-4 border-b">
                <h2 class="text-2xl font-display font-semibold text-gray-900">
                  {{ isEditing ? 'Edit Extinguisher Type' : 'Add New Extinguisher Type' }}
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
                  <!-- Type Code -->
                  <div>
                    <label
                      for="typeCode"
                      class="form-label"
                    >
                      Type Code *
                    </label>
                    <input
                      id="typeCode"
                      v-model="formData.typeCode"
                      type="text"
                      required
                      :disabled="isEditing"
                      class="form-input"
                      :class="{ 'bg-gray-50': isEditing }"
                      placeholder="ABC-10"
                    >
                    <p class="form-helper">
                      Unique identifier (cannot be changed)
                    </p>
                  </div>

                  <!-- Type Name -->
                  <div>
                    <label
                      for="typeName"
                      class="form-label"
                    >
                      Type Name *
                    </label>
                    <input
                      id="typeName"
                      v-model="formData.typeName"
                      type="text"
                      required
                      class="form-input"
                      placeholder="10lb ABC Dry Chemical"
                    >
                  </div>
                </div>

                <!-- Agent Type -->
                <div>
                  <label
                    for="agentType"
                    class="form-label"
                  >
                    Agent Type
                  </label>
                  <select
                    id="agentType"
                    v-model="formData.agentType"
                    class="form-input"
                  >
                    <option value="">
                      Select agent type...
                    </option>
                    <option value="Dry Chemical">
                      Dry Chemical
                    </option>
                    <option value="CO2">
                      CO2
                    </option>
                    <option value="Water">
                      Water
                    </option>
                    <option value="Foam">
                      Foam
                    </option>
                    <option value="Clean Agent">
                      Clean Agent
                    </option>
                    <option value="Wet Chemical">
                      Wet Chemical
                    </option>
                  </select>
                </div>

                <!-- Capacity -->
                <div class="grid grid-cols-2 gap-4">
                  <div>
                    <label
                      for="capacity"
                      class="form-label"
                    >
                      Capacity
                    </label>
                    <input
                      id="capacity"
                      v-model.number="formData.capacity"
                      type="number"
                      step="0.1"
                      class="form-input"
                      placeholder="10"
                    >
                  </div>

                  <div>
                    <label
                      for="capacityUnit"
                      class="form-label"
                    >
                      Capacity Unit
                    </label>
                    <select
                      id="capacityUnit"
                      v-model="formData.capacityUnit"
                      class="form-input"
                    >
                      <option value="">
                        Select unit...
                      </option>
                      <option value="lbs">
                        lbs (pounds)
                      </option>
                      <option value="kg">
                        kg (kilograms)
                      </option>
                      <option value="gal">
                        gal (gallons)
                      </option>
                      <option value="L">
                        L (liters)
                      </option>
                    </select>
                  </div>
                </div>

                <!-- Fire Class Rating -->
                <div>
                  <label class="form-label">
                    Fire Class Rating
                  </label>
                  <div class="grid grid-cols-5 gap-3">
                    <div
                      v-for="fireClass in fireClasses"
                      :key="fireClass.value"
                      class="flex items-center p-3 border-2 rounded-lg cursor-pointer transition-all"
                      :class="selectedFireClasses.includes(fireClass.value)
                        ? 'border-primary-500 bg-primary-50'
                        : 'border-gray-200 hover:border-gray-300'"
                      @click="toggleFireClass(fireClass.value)"
                    >
                      <input
                        type="checkbox"
                        :checked="selectedFireClasses.includes(fireClass.value)"
                        class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                        @change="toggleFireClass(fireClass.value)"
                      >
                      <label class="ml-2 block text-sm font-medium text-gray-700 cursor-pointer">
                        {{ fireClass.label }}
                      </label>
                    </div>
                  </div>
                  <p class="form-helper mt-2">
                    A: Ordinary combustibles | B: Flammable liquids | C: Electrical | D: Combustible metals | K: Kitchen fires
                  </p>
                </div>

                <!-- Service Intervals -->
                <div class="grid grid-cols-2 gap-4">
                  <div>
                    <label
                      for="serviceLifeYears"
                      class="form-label"
                    >
                      Service Life (Years)
                    </label>
                    <input
                      id="serviceLifeYears"
                      v-model.number="formData.serviceLifeYears"
                      type="number"
                      min="1"
                      class="form-input"
                      placeholder="12"
                    >
                    <p class="form-helper">
                      Expected service life before replacement
                    </p>
                  </div>

                  <div>
                    <label
                      for="hydroTestIntervalYears"
                      class="form-label"
                    >
                      Hydro Test Interval (Years)
                    </label>
                    <input
                      id="hydroTestIntervalYears"
                      v-model.number="formData.hydroTestIntervalYears"
                      type="number"
                      min="1"
                      class="form-input"
                      placeholder="5"
                    >
                    <p class="form-helper">
                      Hydrostatic test frequency
                    </p>
                  </div>
                </div>

                <!-- Description -->
                <div>
                  <label
                    for="description"
                    class="form-label"
                  >
                    Description
                  </label>
                  <textarea
                    id="description"
                    v-model="formData.description"
                    rows="3"
                    class="form-input"
                    placeholder="Additional specifications and notes..."
                  />
                </div>

                <!-- Active Status (Edit only) -->
                <div
                  v-if="isEditing"
                  class="flex items-center p-4 bg-gray-50 rounded-lg"
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
                    Active type (available for new extinguishers)
                  </label>
                </div>

                <!-- Form Actions -->
                <div class="flex space-x-3 pt-4 sticky bottom-0 bg-white border-t">
                  <button
                    type="submit"
                    :disabled="submitting"
                    class="btn-primary flex-1"
                  >
                    <span v-if="!submitting">{{ isEditing ? 'Update Type' : 'Create Type' }}</span>
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
import { useExtinguisherTypeStore } from '@/stores/extinguisherTypes'
import { useToastStore } from '@/stores/toast'
import AppLayout from '@/components/layout/AppLayout.vue'
import {
  PlusIcon,
  PencilIcon,
  TrashIcon,
  XMarkIcon,
  XCircleIcon,
  BeakerIcon
} from '@heroicons/vue/24/outline'

const typeStore = useExtinguisherTypeStore()
const toast = useToastStore()

const showModal = ref(false)
const isEditing = ref(false)
const editingTypeId = ref(null)
const submitting = ref(false)
const selectedFireClasses = ref([])

const fireClasses = [
  { value: 'A', label: 'Class A' },
  { value: 'B', label: 'Class B' },
  { value: 'C', label: 'Class C' },
  { value: 'D', label: 'Class D' },
  { value: 'K', label: 'Class K' }
]

const formData = ref({
  typeCode: '',
  typeName: '',
  description: '',
  agentType: '',
  capacity: null,
  capacityUnit: '',
  fireClassRating: '',
  serviceLifeYears: null,
  hydroTestIntervalYears: null,
  isActive: true
})

onMounted(async () => {
  try {
    await typeStore.fetchTypes()
  } catch (error) {
    console.error('Failed to load extinguisher types:', error)
    toast.error('Failed to load extinguisher types')
  }
})

const parseFireClasses = (fireClassRating) => {
  if (!fireClassRating) return []
  return fireClassRating.split(',').map(c => c.trim()).filter(Boolean)
}

const toggleFireClass = (fireClass) => {
  const index = selectedFireClasses.value.indexOf(fireClass)
  if (index > -1) {
    selectedFireClasses.value.splice(index, 1)
  } else {
    selectedFireClasses.value.push(fireClass)
  }
  // Update form data
  formData.value.fireClassRating = selectedFireClasses.value.sort().join(',')
}

const openCreateModal = () => {
  resetForm()
  isEditing.value = false
  showModal.value = true
}

const openEditModal = (type) => {
  editingTypeId.value = type.extinguisherTypeId
  formData.value = {
    typeCode: type.typeCode,
    typeName: type.typeName,
    description: type.description || '',
    agentType: type.agentType || '',
    capacity: type.capacity,
    capacityUnit: type.capacityUnit || '',
    fireClassRating: type.fireClassRating || '',
    serviceLifeYears: type.serviceLifeYears,
    hydroTestIntervalYears: type.hydroTestIntervalYears,
    isActive: type.isActive
  }
  selectedFireClasses.value = parseFireClasses(type.fireClassRating)
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
  editingTypeId.value = null
  selectedFireClasses.value = []
  formData.value = {
    typeCode: '',
    typeName: '',
    description: '',
    agentType: '',
    capacity: null,
    capacityUnit: '',
    fireClassRating: '',
    serviceLifeYears: null,
    hydroTestIntervalYears: null,
    isActive: true
  }
}

const handleSubmit = async () => {
  submitting.value = true

  try {
    // Clean up empty strings to null for optional fields
    const cleanData = {
      ...formData.value,
      description: formData.value.description || null,
      agentType: formData.value.agentType || null,
      capacity: formData.value.capacity || null,
      capacityUnit: formData.value.capacityUnit || null,
      fireClassRating: formData.value.fireClassRating || null,
      serviceLifeYears: formData.value.serviceLifeYears || null,
      hydroTestIntervalYears: formData.value.hydroTestIntervalYears || null
    }

    if (isEditing.value) {
      await typeStore.updateType(editingTypeId.value, cleanData)
      toast.success('Extinguisher type updated successfully')
    } else {
      await typeStore.createType(cleanData)
      toast.success('Extinguisher type created successfully')
    }
    closeModal()
  } catch (error) {
    console.error('Form submission error:', error)
    toast.error(error.response?.data?.message || 'Failed to save extinguisher type')
  } finally {
    submitting.value = false
  }
}

const confirmDelete = async (type) => {
  if (confirm(`Are you sure you want to delete "${type.typeName}"?\n\nThis action cannot be undone.`)) {
    try {
      await typeStore.deleteType(type.extinguisherTypeId)
      toast.success('Extinguisher type deleted successfully')
    } catch (error) {
      console.error('Failed to delete extinguisher type:', error)
      toast.error('Failed to delete extinguisher type')
    }
  }
}
</script>
