<template>
  <AppLayout>
    <div
      ref="contentContainer"
      class="relative"
      @touchstart="handleTouchStart"
      @touchmove="handleTouchMove"
      @touchend="handleTouchEnd"
    >
      <!-- Pull-to-Refresh Indicator -->
      <transition name="fade">
        <div
          v-if="pullToRefreshActive"
          class="fixed top-0 left-0 right-0 z-50 flex items-center justify-center py-4 bg-primary-600 text-white shadow-lg"
          data-testid="pull-to-refresh-indicator"
        >
          <svg
            v-if="isRefreshing"
            class="animate-spin h-5 w-5 mr-3"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
          >
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          <span v-else>↓ Pull to refresh</span>
          <span v-if="isRefreshing">Refreshing...</span>
        </div>
      </transition>

      <!-- Header -->
      <div class="flex justify-between items-center mb-8">
        <div>
          <h1 class="text-3xl font-display font-semibold text-gray-900 mb-2" data-testid="page-heading">
            Fire Extinguishers
          </h1>
          <p class="text-gray-600">
            Manage fire extinguisher inventory and track service schedules
          </p>
        </div>
        <button
          class="btn-primary inline-flex items-center"
          @click="openCreateModal"
          data-testid="new-extinguisher-button"
        >
          <PlusIcon class="h-5 w-5 mr-2" />
          Add Extinguisher
        </button>
      </div>

      <!-- Stats Cards -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8" data-testid="stats-cards">
        <div class="card" data-testid="stat-card-total">
          <div class="p-4">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-gray-600">Total</p>
                <p class="text-2xl font-bold text-gray-900" data-testid="total-count">
                  {{ filteredCount }}
                </p>
              </div>
              <ShieldCheckIcon class="h-8 w-8 text-gray-400" />
            </div>
          </div>
        </div>

        <div class="card" data-testid="stat-card-active">
          <div class="p-4">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-gray-600">Active</p>
                <p class="text-2xl font-bold text-secondary-600" data-testid="active-count">
                  {{ stats.active }}
                </p>
              </div>
              <CheckCircleIcon class="h-8 w-8 text-secondary-400" />
            </div>
          </div>
        </div>

        <div class="card" data-testid="stat-card-out-of-service">
          <div class="p-4">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-gray-600">Out of Service</p>
                <p class="text-2xl font-bold text-red-600" data-testid="out-of-service-count">
                  {{ stats.outOfService }}
                </p>
              </div>
              <ExclamationTriangleIcon class="h-8 w-8 text-red-400" />
            </div>
          </div>
        </div>

        <div class="card" data-testid="stat-card-need-attention">
          <div class="p-4">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-gray-600">Need Attention</p>
                <p class="text-2xl font-bold text-accent-600" data-testid="need-attention-count">
                  {{ stats.needingAttention }}
                </p>
              </div>
              <ClockIcon class="h-8 w-8 text-accent-400" />
            </div>
          </div>
        </div>
      </div>

      <!-- Filters (Collapsible on Mobile) -->
      <div class="card mb-6" data-testid="filters-card">
        <div class="p-4">
          <!-- Filter Header with Toggle Button (Mobile Only) -->
          <div class="flex justify-between items-center mb-4 md:hidden">
            <h3 class="text-sm font-semibold text-gray-700">Filters</h3>
            <button
              @click="toggleFilters"
              class="text-primary-600 hover:text-primary-800 transition-colors"
              data-testid="toggle-filters-button"
            >
              {{ filtersExpanded ? 'Hide' : 'Show' }}
            </button>
          </div>

          <!-- Filters Content -->
          <transition name="expand">
            <div v-show="filtersExpanded || isDesktop" class="flex flex-wrap gap-4">
            <!-- Search -->
            <div class="flex-1 min-w-[200px] w-full md:w-auto">
              <label for="search" class="form-label">Search</label>
              <input
                id="search"
                v-model="filters.search"
                type="text"
                class="form-input"
                placeholder="Search code, serial number, or manufacturer..."
                data-testid="filter-search"
              >
            </div>

            <!-- Location Filter -->
            <div class="w-full md:w-64">
              <label for="locationFilter" class="form-label">Location</label>
              <select
                id="locationFilter"
                v-model="filters.locationId"
                class="form-input"
                data-testid="filter-location"
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

            <!-- Type Filter -->
            <div class="w-full md:w-64">
              <label for="typeFilter" class="form-label">Type</label>
              <select
                id="typeFilter"
                v-model="filters.extinguisherTypeId"
                class="form-input"
                data-testid="filter-type"
              >
                <option value="">All Types</option>
                <option
                  v-for="type in typeStore.types"
                  :key="type.extinguisherTypeId"
                  :value="type.extinguisherTypeId"
                >
                  {{ type.typeName }}
                </option>
              </select>
            </div>

            <!-- Status Filter -->
            <div class="w-full md:w-48">
              <label for="statusFilter" class="form-label">Status</label>
              <select
                id="statusFilter"
                v-model="filters.status"
                class="form-input"
                data-testid="filter-status"
              >
                <option value="">All Status</option>
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
                <option value="out-of-service">Out of Service</option>
                <option value="needs-attention">Needs Attention</option>
              </select>
            </div>

            <!-- Reset Button -->
            <div class="flex items-end">
              <button
                class="btn-outline"
                @click="resetFilters"
                data-testid="filter-reset"
              >
                Reset
              </button>
            </div>
          </div>
          </transition>
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
          <p class="text-gray-600">Loading extinguishers...</p>
        </div>
      </div>

      <!-- Banded Grid -->
      <BandedGrid
        v-else-if="filteredExtinguishers.length > 0"
        :data="filteredExtinguishers"
        :columns="gridColumns"
        :expandable="true"
        :paginated="true"
        :items-per-page="50"
        :row-key="'extinguisherId'"
        :row-class="getRowClass"
        empty-message="No extinguishers match your filters"
        @row-click="handleRowClick"
        @sort-change="handleSortChange"
      >
        <!-- Custom Cell Templates -->
        <template #cell-extinguisherCode="{ row }">
          <div class="font-semibold text-gray-900">
            {{ row.extinguisherCode }}
          </div>
        </template>

        <template #cell-status="{ row }">
          <span
            v-if="row.isOutOfService"
            class="badge-danger text-xs"
          >
            Out of Service
          </span>
          <span
            v-else-if="!row.isActive"
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
        </template>

        <template #cell-typeName="{ row }">
          <span class="text-gray-700">{{ row.typeName || 'Unknown' }}</span>
        </template>

        <template #cell-locationName="{ row }">
          <div class="flex items-center text-gray-700">
            <MapPinIcon class="h-4 w-4 mr-1.5 text-gray-400" />
            {{ row.locationName || 'No Location' }}
          </div>
        </template>

        <template #cell-serialNumber="{ row }">
          <span class="text-gray-600 text-sm">{{ row.serialNumber }}</span>
        </template>

        <template #cell-nextServiceDueDate="{ row }">
          <span
            v-if="row.nextServiceDueDate"
            :class="{
              'text-red-600 font-semibold': isOverdue(row.nextServiceDueDate),
              'text-accent-600 font-semibold': needsAttentionSoon(row.nextServiceDueDate),
              'text-gray-600': !isOverdue(row.nextServiceDueDate) && !needsAttentionSoon(row.nextServiceDueDate)
            }"
          >
            {{ formatDate(row.nextServiceDueDate) }}
          </span>
          <span v-else class="text-gray-400 text-sm">Not set</span>
        </template>

        <template #cell-actions="{ row }">
          <div class="flex space-x-2">
            <button
              class="text-primary-600 hover:text-primary-800 transition-colors"
              @click.stop="openEditModal(row)"
              title="Edit"
              data-testid="edit-button"
            >
              <PencilIcon class="h-4 w-4" />
            </button>
            <button
              v-if="row.qrCodeData"
              class="text-secondary-600 hover:text-secondary-800 transition-colors"
              @click.stop="showQRCode(row)"
              title="View QR Code"
              data-testid="qr-button"
            >
              <QrCodeIcon class="h-4 w-4" />
            </button>
            <button
              v-else
              class="text-secondary-600 hover:text-secondary-800 transition-colors"
              @click.stop="generateQRCode(row)"
              title="Generate QR Code"
              data-testid="generate-qr-button"
            >
              <SparklesIcon class="h-4 w-4" />
            </button>
            <button
              class="text-red-600 hover:text-red-800 transition-colors"
              @click.stop="confirmDelete(row)"
              title="Delete"
              data-testid="delete-button"
            >
              <TrashIcon class="h-4 w-4" />
            </button>
          </div>
        </template>

        <!-- Expanded Row Content -->
        <template #expanded-content="{ row }">
          <div class="p-6 bg-white">
            <div class="grid grid-cols-2 lg:grid-cols-3 gap-6">
              <!-- Details Section -->
              <div>
                <h4 class="text-sm font-semibold text-gray-900 mb-3">Details</h4>
                <dl class="space-y-2 text-sm">
                  <div v-if="row.manufacturer">
                    <dt class="text-gray-500">Manufacturer</dt>
                    <dd class="text-gray-900 font-medium">{{ row.manufacturer }}</dd>
                  </div>
                  <div v-if="row.assetTag">
                    <dt class="text-gray-500">Asset Tag</dt>
                    <dd class="text-gray-900 font-medium">{{ row.assetTag }}</dd>
                  </div>
                  <div v-if="row.floorLevel">
                    <dt class="text-gray-500">Floor Level</dt>
                    <dd class="text-gray-900">{{ row.floorLevel }}</dd>
                  </div>
                  <div v-if="row.locationDescription">
                    <dt class="text-gray-500">Location Description</dt>
                    <dd class="text-gray-900">{{ row.locationDescription }}</dd>
                  </div>
                </dl>
              </div>

              <!-- Dates Section -->
              <div>
                <h4 class="text-sm font-semibold text-gray-900 mb-3">Service History</h4>
                <dl class="space-y-2 text-sm">
                  <div v-if="row.manufactureDate">
                    <dt class="text-gray-500">Manufacture Date</dt>
                    <dd class="text-gray-900">{{ formatDate(row.manufactureDate) }}</dd>
                  </div>
                  <div v-if="row.installDate">
                    <dt class="text-gray-500">Install Date</dt>
                    <dd class="text-gray-900">{{ formatDate(row.installDate) }}</dd>
                  </div>
                  <div v-if="row.lastServiceDate">
                    <dt class="text-gray-500">Last Service</dt>
                    <dd class="text-gray-900">{{ formatDate(row.lastServiceDate) }}</dd>
                  </div>
                  <div v-if="row.nextHydroTestDueDate">
                    <dt class="text-gray-500">Next Hydro Test</dt>
                    <dd
                      :class="{
                        'text-red-600 font-semibold': isOverdue(row.nextHydroTestDueDate),
                        'text-accent-600 font-semibold': needsAttentionSoon(row.nextHydroTestDueDate),
                        'text-gray-900': !isOverdue(row.nextHydroTestDueDate) && !needsAttentionSoon(row.nextHydroTestDueDate)
                      }"
                    >
                      {{ formatDate(row.nextHydroTestDueDate) }}
                    </dd>
                  </div>
                </dl>
              </div>

              <!-- Notes Section -->
              <div v-if="row.notes || row.outOfServiceReason">
                <h4 class="text-sm font-semibold text-gray-900 mb-3">Notes</h4>
                <div class="space-y-2 text-sm">
                  <div v-if="row.outOfServiceReason" class="p-3 bg-red-50 border border-red-200 rounded">
                    <p class="text-xs font-semibold text-red-700 mb-1">Out of Service Reason:</p>
                    <p class="text-red-900">{{ row.outOfServiceReason }}</p>
                  </div>
                  <div v-if="row.notes" class="text-gray-700">
                    <p class="text-gray-500 mb-1">General Notes:</p>
                    <p>{{ row.notes }}</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </template>
      </BandedGrid>

      <!-- Empty State -->
      <div
        v-else
        class="card"
        data-testid="empty-state"
      >
        <div class="p-12 text-center">
          <div class="inline-flex items-center justify-center w-16 h-16 rounded-full bg-primary-100 mb-4">
            <ShieldCheckIcon class="h-8 w-8 text-primary-600" />
          </div>
          <h3 class="text-lg font-semibold text-gray-900 mb-2">
            {{ filters.search || filters.locationId || filters.extinguisherTypeId || filters.status ? 'No matching extinguishers' : 'No extinguishers yet' }}
          </h3>
          <p class="text-gray-600 mb-6">
            {{ filters.search || filters.locationId || filters.extinguisherTypeId || filters.status ? 'Try adjusting your filters' : 'Get started by adding your first fire extinguisher' }}
          </p>
          <button
            v-if="!filters.search && !filters.locationId && !filters.extinguisherTypeId && !filters.status"
            class="btn-primary inline-flex items-center"
            @click="openCreateModal"
          >
            <PlusIcon class="h-5 w-5 mr-2" />
            Add First Extinguisher
          </button>
          <button
            v-else
            class="btn-outline"
            @click="resetFilters"
          >
            Reset Filters
          </button>
        </div>
      </div>
    </div>

    <!-- Create/Edit Modal (keeping original modal code) -->
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

              <!-- Form (keeping original form code for brevity - same as original) -->
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

    <!-- QR Code Modal (keeping original) -->
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
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useExtinguisherStore } from '@/stores/extinguishers'
import { useExtinguisherTypeStore } from '@/stores/extinguisherTypes'
import { useLocationStore } from '@/stores/locations'
import { useToastStore } from '@/stores/toast'
import AppLayout from '@/components/layout/AppLayout.vue'
import BandedGrid from '@/components/BandedGrid.vue'
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
  QrCodeIcon,
  SparklesIcon
} from '@heroicons/vue/24/outline'

const extinguisherStore = useExtinguisherStore()
const typeStore = useExtinguisherTypeStore()
const locationStore = useLocationStore()
const toast = useToastStore()

// State
const showModal = ref(false)
const showQRModal = ref(false)
const isEditing = ref(false)
const editingExtinguisherId = ref(null)
const submitting = ref(false)
const selectedExtinguisher = ref(null)

// Pull-to-refresh state
const pullToRefreshActive = ref(false)
const isRefreshing = ref(false)
const touchStartY = ref(0)
const touchCurrentY = ref(0)
const contentContainer = ref(null)

// Collapsible filters state
const filtersExpanded = ref(false)
const isDesktop = ref(window.innerWidth >= 768)

const filters = ref({
  search: '',
  locationId: '',
  extinguisherTypeId: '',
  status: ''
})

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

// Grid Configuration
const gridColumns = [
  { key: 'extinguisherCode', label: 'Code', width: '150px', sortable: true },
  { key: 'status', label: 'Status', width: '120px', sortable: false },
  { key: 'typeName', label: 'Type', width: '180px', sortable: true },
  { key: 'locationName', label: 'Location', width: '200px', sortable: true },
  { key: 'serialNumber', label: 'Serial Number', width: '150px', sortable: false },
  { key: 'nextServiceDueDate', label: 'Next Service', width: '150px', sortable: true },
  { key: 'actions', label: 'Actions', width: '120px', sortable: false, align: 'center' }
]

// Computed
const filteredExtinguishers = computed(() => {
  let filtered = extinguisherStore.extinguishers

  // Search filter
  if (filters.value.search) {
    const search = filters.value.search.toLowerCase()
    filtered = filtered.filter(ext =>
      ext.extinguisherCode?.toLowerCase().includes(search) ||
      ext.serialNumber?.toLowerCase().includes(search) ||
      ext.manufacturer?.toLowerCase().includes(search) ||
      ext.locationName?.toLowerCase().includes(search)
    )
  }

  // Location filter
  if (filters.value.locationId) {
    filtered = filtered.filter(ext => ext.locationId === filters.value.locationId)
  }

  // Type filter
  if (filters.value.extinguisherTypeId) {
    filtered = filtered.filter(ext => ext.extinguisherTypeId === filters.value.extinguisherTypeId)
  }

  // Status filter
  if (filters.value.status) {
    switch (filters.value.status) {
      case 'active':
        filtered = filtered.filter(ext => ext.isActive && !ext.isOutOfService)
        break
      case 'inactive':
        filtered = filtered.filter(ext => !ext.isActive)
        break
      case 'out-of-service':
        filtered = filtered.filter(ext => ext.isOutOfService)
        break
      case 'needs-attention':
        filtered = filtered.filter(ext => needsAttention(ext))
        break
    }
  }

  return filtered
})

const filteredCount = computed(() => filteredExtinguishers.value.length)

const stats = computed(() => {
  const filtered = filteredExtinguishers.value
  return {
    active: filtered.filter(ext => ext.isActive && !ext.isOutOfService).length,
    outOfService: filtered.filter(ext => ext.isOutOfService).length,
    needingAttention: filtered.filter(ext => needsAttention(ext)).length
  }
})

// Methods
const needsAttention = (extinguisher) => {
  const now = new Date()
  const thirtyDaysFromNow = new Date()
  thirtyDaysFromNow.setDate(now.getDate() + 30)

  const nextService = extinguisher.nextServiceDueDate ? new Date(extinguisher.nextServiceDueDate) : null
  const nextHydro = extinguisher.nextHydroTestDueDate ? new Date(extinguisher.nextHydroTestDueDate) : null

  return (nextService && nextService <= thirtyDaysFromNow) || (nextHydro && nextHydro <= thirtyDaysFromNow)
}

const isOverdue = (dateString) => {
  if (!dateString) return false
  return new Date(dateString) < new Date()
}

const needsAttentionSoon = (dateString) => {
  if (!dateString) return false
  const date = new Date(dateString)
  const now = new Date()
  const thirtyDaysFromNow = new Date()
  thirtyDaysFromNow.setDate(now.getDate() + 30)
  return date > now && date <= thirtyDaysFromNow
}

const formatDate = (dateString) => {
  if (!dateString) return 'Not set'
  const date = new Date(dateString)
  return date.toLocaleDateString()
}

const resetFilters = () => {
  filters.value = {
    search: '',
    locationId: '',
    extinguisherTypeId: '',
    status: ''
  }
}

const getRowClass = (row) => {
  if (row.isOutOfService) return 'bg-red-50 border-l-4 border-red-500'
  if (needsAttention(row)) return 'bg-accent-50 border-l-4 border-accent-500'
  return ''
}

const handleRowClick = (row) => {
  console.log('Row clicked:', row)
}

const handleSortChange = (sortBy, direction) => {
  console.log('Sort changed:', sortBy, direction)
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
    await extinguisherStore.generateBarcode(extinguisher.extinguisherId)
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

// Pull-to-Refresh Functions
const handleTouchStart = (e) => {
  // Only activate if at top of page
  if (window.scrollY === 0) {
    touchStartY.value = e.touches[0].clientY
  }
}

const handleTouchMove = (e) => {
  if (!isRefreshing.value && window.scrollY === 0) {
    touchCurrentY.value = e.touches[0].clientY
    const pullDistance = touchCurrentY.value - touchStartY.value

    // Show indicator if pulled down more than 80px
    if (pullDistance > 80) {
      pullToRefreshActive.value = true
    } else {
      pullToRefreshActive.value = false
    }
  }
}

const handleTouchEnd = async () => {
  if (pullToRefreshActive.value && !isRefreshing.value) {
    isRefreshing.value = true

    try {
      // Reload all data
      await Promise.all([
        extinguisherStore.fetchExtinguishers(),
        typeStore.fetchTypes(true),
        locationStore.fetchLocations()
      ])
      toast.success('Data refreshed')
    } catch (error) {
      console.error('Failed to refresh data:', error)
      toast.error('Failed to refresh data')
    } finally {
      // Reset states
      setTimeout(() => {
        isRefreshing.value = false
        pullToRefreshActive.value = false
        touchStartY.value = 0
        touchCurrentY.value = 0
      }, 500)
    }
  } else {
    pullToRefreshActive.value = false
  }
}

// Collapsible Filters Function
const toggleFilters = () => {
  filtersExpanded.value = !filtersExpanded.value
}

// Handle window resize for filter display
const handleResize = () => {
  isDesktop.value = window.innerWidth >= 768
  if (isDesktop.value) {
    filtersExpanded.value = false // Reset when switching to desktop
  }
}

// Lifecycle
onMounted(async () => {
  try {
    await Promise.all([
      extinguisherStore.fetchExtinguishers(),
      typeStore.fetchTypes(true),
      locationStore.fetchLocations()
    ])
  } catch (error) {
    console.error('Failed to load data:', error)
    toast.error('Failed to load data')
  }

  // Add resize listener for responsive filter display
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  // Cleanup resize listener
  window.removeEventListener('resize', handleResize)
})
</script>
