<template>
  <AppLayout>
    <div class="templates-view">
      <!-- Success Message -->
      <div
        v-if="successMessage"
        class="success-banner"
        data-testid="success-message"
      >
        {{ successMessage }}
      </div>

      <!-- Header -->
      <div
        class="page-header"
        data-testid="templates-heading"
      >
        <div>
          <h1 class="page-title">
            Checklist Templates
          </h1>
          <p class="page-description">
            Manage inspection checklist templates (NFPA, Title19, ULC, Custom)
          </p>
        </div>
        <button
          class="btn-create"
          data-testid="create-template-button"
          @click="showCreateModal = true"
        >
          + Create Template
        </button>
      </div>

      <!-- Filter Tabs -->
      <div
        class="tabs"
        data-testid="template-tabs"
      >
        <button
          :class="['tab', { 'tab-active': currentTab === 'all' }]"
          data-testid="tab-all"
          @click="currentTab = 'all'"
        >
          All Templates
        </button>
        <button
          :class="['tab', { 'tab-active': currentTab === 'system' }]"
          data-testid="tab-system"
          @click="currentTab = 'system'"
        >
          System Templates
        </button>
        <button
          :class="['tab', { 'tab-active': currentTab === 'custom' }]"
          data-testid="tab-custom"
          @click="currentTab = 'custom'"
        >
          Custom Templates
        </button>
      </div>

      <!-- Loading State -->
      <div
        v-if="templatesStore.loading"
        class="loading-state"
        data-testid="loading-state"
      >
        <div class="spinner" />
        <p>Loading templates...</p>
      </div>

      <!-- Error State -->
      <div
        v-else-if="templatesStore.error"
        class="error-state"
        data-testid="error-state"
      >
        <div class="error-icon">
          ⚠️
        </div>
        <p class="error-message">
          {{ templatesStore.error }}
        </p>
        <button
          class="btn-retry"
          @click="loadTemplates"
        >
          Retry
        </button>
      </div>

      <!-- Templates Grid -->
      <div
        v-else-if="filteredTemplates.length > 0"
        class="templates-grid"
        data-testid="templates-grid"
      >
        <div
          v-for="template in filteredTemplates"
          :key="template.templateId"
          :data-template-id="template.templateId"
          class="template-card"
          data-testid="template-card"
        >
          <div class="card-header">
            <h3 class="card-title">
              {{ template.templateName }}
            </h3>
            <span
              :class="['badge', getBadgeClass(template.templateType)]"
              data-testid="template-type-badge"
            >
              {{ template.templateType }}
            </span>
            <span
              v-if="template.isSystemTemplate"
              class="badge badge-info"
              data-testid="template-badge-system"
            >
              System
            </span>
            <span
              v-else
              class="badge badge-custom"
              data-testid="template-badge-custom"
            >
              Custom
            </span>
          </div>

          <p class="card-description">
            {{ template.description || 'No description' }}
          </p>

          <div class="card-meta">
            <span
              class="meta-item"
              data-testid="template-item-count"
            >
              📋 {{ template.checklistItems?.length || 0 }} items
            </span>
            <span :class="['badge', template.isActive ? 'badge-success' : 'badge-inactive']">
              {{ template.isActive ? 'Active' : 'Inactive' }}
            </span>
          </div>

          <div class="card-actions">
            <button
              class="btn-card btn-primary"
              data-testid="template-view-button"
              @click="viewTemplate(template)"
            >
              View
            </button>
            <button
              v-if="!template.isSystemTemplate"
              class="btn-card btn-secondary"
              data-testid="template-edit-button"
              @click="editTemplate(template)"
            >
              Edit
            </button>
            <button
              class="btn-card btn-secondary"
              data-testid="template-duplicate-button"
              @click="duplicateTemplate(template)"
            >
              Duplicate
            </button>
            <button
              v-if="!template.isSystemTemplate"
              class="btn-card btn-danger"
              data-testid="template-delete-button"
              @click="confirmDelete(template)"
            >
              Delete
            </button>
          </div>
        </div>
      </div>

      <!-- Empty State -->
      <div
        v-else
        class="empty-state"
        data-testid="templates-empty-state"
      >
        <div class="empty-icon">
          📋
        </div>
        <h3>No templates found</h3>
        <p>{{ currentTab === 'custom' ? 'Create your first custom template' : 'No templates available' }}</p>
        <button
          v-if="currentTab === 'custom'"
          class="btn-create-empty"
          @click="showCreateModal = true"
        >
          + Create Template
        </button>
      </div>

      <!-- View Template Modal -->
      <teleport to="body">
        <div
          v-if="showViewModal"
          class="modal-overlay"
          data-testid="template-view-modal"
          @click="closeViewModal"
        >
          <div
            class="modal-content modal-large"
            @click.stop
          >
            <div class="modal-header">
              <div>
                <h2
                  class="modal-title"
                  data-testid="template-detail-name"
                >
                  {{ currentTemplate?.templateName }}
                </h2>
                <span :class="['badge', getBadgeClass(currentTemplate?.templateType)]">
                  {{ currentTemplate?.templateType }}
                </span>
              </div>
              <button
                class="btn-close"
                data-testid="modal-close-button"
                @click="closeViewModal"
              >
                ✕
              </button>
            </div>

            <div
              v-if="currentTemplate"
              class="modal-body"
            >
              <div class="template-info">
                <p
                  data-testid="template-detail-description"
                >
                  <strong>Description:</strong> {{ currentTemplate.description || 'No description' }}
                </p>
                <p>
                  <strong>Status:</strong>
                  <span :class="['badge', currentTemplate.isActive ? 'badge-success' : 'badge-inactive']">
                    {{ currentTemplate.isActive ? 'Active' : 'Inactive' }}
                  </span>
                </p>
                <p><strong>Type:</strong> {{ currentTemplate.isSystemTemplate ? 'System Template (Read-Only)' : 'Custom Template' }}</p>
              </div>

              <h3 class="section-title">
                Checklist Items ({{ currentTemplate.checklistItems?.length || 0 }})
              </h3>
              <div
                v-if="currentTemplate.checklistItems?.length"
                class="checklist-items"
                data-testid="template-items-list"
              >
                <div
                  v-for="(item, index) in currentTemplate.checklistItems"
                  :key="item.checklistItemId"
                  class="checklist-item"
                  data-testid="template-item"
                >
                  <div class="item-number">
                    {{ index + 1 }}
                  </div>
                  <div class="item-content">
                    <p class="item-text">
                      {{ item.itemText }}
                    </p>
                    <span
                      :class="['badge', item.isRequired ? 'badge-error' : 'badge-info']"
                      data-testid="item-required-badge"
                    >
                      {{ item.isRequired ? 'Required' : 'Optional' }}
                    </span>
                  </div>
                </div>
              </div>
              <p
                v-else
                class="text-gray-500"
              >
                No checklist items
              </p>
            </div>
          </div>
        </div>
      </teleport>

      <!-- Create/Edit Template Modal -->
      <teleport to="body">
        <div
          v-if="showCreateModal || showEditModal"
          class="modal-overlay"
          :data-testid="showCreateModal ? 'template-create-modal' : 'template-edit-modal'"
          @click="closeEditModal"
        >
          <div
            class="modal-content"
            @click.stop
          >
            <div class="modal-header">
              <h2 class="modal-title">
                {{ showEditModal ? 'Edit Template' : 'Create Template' }}
              </h2>
              <button
                class="btn-close"
                data-testid="modal-close-button"
                @click="closeEditModal"
              >
                ✕
              </button>
            </div>

            <form
              class="modal-body"
              @submit.prevent="saveTemplate"
            >
              <div class="form-group">
                <label
                  for="template-name"
                  class="form-label"
                >Template Name *</label>
                <input
                  id="template-name"
                  v-model="templateForm.templateName"
                  type="text"
                  required
                  class="form-input"
                  data-testid="template-name-input"
                >
                <p
                  v-if="showNameError"
                  class="text-red-600 text-sm mt-1"
                  data-testid="name-error"
                >
                  Template name is required
                </p>
              </div>

              <div class="form-group">
                <label
                  for="template-description"
                  class="form-label"
                >Description</label>
                <textarea
                  id="template-description"
                  v-model="templateForm.description"
                  rows="3"
                  class="form-input"
                  data-testid="template-description-input"
                />
              </div>

              <div class="form-group">
                <label
                  for="template-type"
                  class="form-label"
                >Template Type *</label>
                <select
                  id="template-type"
                  v-model="templateForm.templateType"
                  required
                  class="form-input"
                  data-testid="template-type-select"
                >
                  <option value="CUSTOM">
                    Custom
                  </option>
                  <option value="NFPA_10">
                    NFPA 10
                  </option>
                  <option value="TITLE_19">
                    Title 19
                  </option>
                  <option value="ULC">
                    ULC
                  </option>
                </select>
              </div>

              <div class="form-group">
                <label class="checkbox-label">
                  <input
                    v-model="templateForm.isActive"
                    type="checkbox"
                    class="checkbox-input"
                    data-testid="template-active-checkbox"
                  >
                  <span>Active</span>
                </label>
              </div>

              <div class="form-group">
                <label class="form-label">Checklist Items</label>
                <button
                  type="button"
                  class="btn-secondary mb-2"
                  data-testid="add-item-button"
                  @click="addChecklistItem"
                >
                  + Add Item
                </button>
                <div
                  v-if="templateForm.checklistItems && templateForm.checklistItems.length > 0"
                  class="space-y-2"
                >
                  <div
                    v-for="(item, index) in templateForm.checklistItems"
                    :key="index"
                    class="flex gap-2 items-start"
                  >
                    <input
                      v-model="item.itemText"
                      type="text"
                      class="form-input flex-1"
                      :data-testid="`item-text-${index}`"
                      placeholder="Item text"
                    >
                    <label class="checkbox-label">
                      <input
                        v-model="item.isRequired"
                        type="checkbox"
                        class="checkbox-input"
                        :data-testid="`item-required-${index}`"
                      >
                      <span class="text-sm">Required</span>
                    </label>
                    <button
                      type="button"
                      class="btn-danger"
                      @click="removeChecklistItem(index)"
                    >
                      Remove
                    </button>
                  </div>
                </div>
                <p
                  v-if="showItemsError"
                  class="text-red-600 text-sm mt-1"
                  data-testid="items-error"
                >
                  At least one checklist item is required
                </p>
              </div>

              <div class="modal-footer">
                <button
                  type="button"
                  class="btn-secondary"
                  @click="closeEditModal"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="btn-primary"
                  data-testid="template-save-button"
                  :disabled="templatesStore.loading"
                >
                  {{ templatesStore.loading ? 'Saving...' : 'Save Template' }}
                </button>
              </div>
            </form>
          </div>
        </div>
      </teleport>

      <!-- Delete Confirmation Modal -->
      <teleport to="body">
        <div
          v-if="showDeleteModal"
          class="modal-overlay"
          data-testid="delete-confirm-modal"
          @click="closeDeleteModal"
        >
          <div
            class="modal-content modal-small"
            @click.stop
          >
            <div class="modal-header">
              <h2 class="modal-title">
                Confirm Delete
              </h2>
              <button
                class="btn-close"
                data-testid="modal-close-button"
                @click="closeDeleteModal"
              >
                ✕
              </button>
            </div>

            <div class="modal-body">
              <p>Are you sure you want to delete this template?</p>
              <p class="font-semibold mt-2">
                {{ templateToDelete?.templateName }}
              </p>
              <p class="text-sm text-gray-600 mt-2">
                This action cannot be undone.
              </p>
            </div>

            <div class="modal-footer">
              <button
                class="btn-secondary"
                @click="closeDeleteModal"
              >
                Cancel
              </button>
              <button
                class="btn-danger"
                data-testid="confirm-delete-button"
                :disabled="templatesStore.loading"
                @click="deleteTemplate"
              >
                {{ templatesStore.loading ? 'Deleting...' : 'Delete Template' }}
              </button>
            </div>
          </div>
        </div>
      </teleport>

      <!-- Duplicate Template Modal -->
      <teleport to="body">
        <div
          v-if="showDuplicateModal"
          class="modal-overlay"
          data-testid="template-duplicate-modal"
          @click="showDuplicateModal = false"
        >
          <div
            class="modal-content modal-small"
            @click.stop
          >
            <div class="modal-header">
              <h2 class="modal-title">
                Duplicate Template
              </h2>
              <button
                class="btn-close"
                data-testid="modal-close-button"
                @click="showDuplicateModal = false"
              >
                ✕
              </button>
            </div>

            <form
              class="modal-body"
              @submit.prevent="saveDuplicate"
            >
              <p class="mb-4">
                Create a copy of <strong>{{ templateToDuplicate?.templateName }}</strong>
              </p>

              <div class="form-group">
                <label
                  for="new-template-name"
                  class="form-label"
                >New Template Name *</label>
                <input
                  id="new-template-name"
                  v-model="newTemplateName"
                  type="text"
                  required
                  class="form-input"
                  data-testid="duplicate-name-input"
                  placeholder="Enter new template name"
                >
              </div>

              <div class="modal-footer">
                <button
                  type="button"
                  class="btn-secondary"
                  @click="showDuplicateModal = false"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="btn-primary"
                  data-testid="duplicate-confirm-button"
                  :disabled="!newTemplateName || templatesStore.loading"
                >
                  Create Copy
                </button>
              </div>
            </form>
          </div>
        </div>
      </teleport>
    </div>
  </AppLayout>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useChecklistTemplateStore } from '@/stores/checklistTemplates'
import AppLayout from '@/components/layout/AppLayout.vue'

const templatesStore = useChecklistTemplateStore()

// State
const currentTab = ref('all')
const showViewModal = ref(false)
const showCreateModal = ref(false)
const showEditModal = ref(false)
const showDeleteModal = ref(false)
const showDuplicateModal = ref(false)
const showNameError = ref(false)
const showItemsError = ref(false)
const successMessage = ref('')

const currentTemplate = ref(null)
const templateToDelete = ref(null)
const templateToDuplicate = ref(null)
const newTemplateName = ref('')

// Form
const templateForm = ref({
  templateName: '',
  description: '',
  templateType: 'CUSTOM',
  isActive: true,
  isSystemTemplate: false,
  checklistItems: []
})

// Computed
const filteredTemplates = computed(() => {
  const templates = templatesStore.templates

  if (currentTab.value === 'system') {
    return templates.filter(t => t.isSystemTemplate)
  }

  if (currentTab.value === 'custom') {
    return templates.filter(t => !t.isSystemTemplate)
  }

  return templates
})

// Methods
function getBadgeClass(type) {
  const classes = {
    'NFPA_10': 'badge-primary',
    'TITLE_19': 'badge-secondary',
    'ULC': 'badge-info',
    'CUSTOM': 'badge-custom'
  }
  return classes[type] || 'badge-default'
}

async function loadTemplates() {
  try {
    await templatesStore.fetchTemplates()
  } catch (error) {
    console.error('Error loading templates:', error)
  }
}

async function viewTemplate(template) {
  try {
    currentTemplate.value = await templatesStore.fetchTemplateById(template.templateId)
    showViewModal.value = true
  } catch (error) {
    console.error('Error loading template:', error)
    alert('Failed to load template details')
  }
}

function editTemplate(template) {
  templateForm.value = {
    templateId: template.templateId,
    templateName: template.templateName,
    description: template.description || '',
    templateType: template.templateType,
    isActive: template.isActive,
    isSystemTemplate: false
  }
  showEditModal.value = true
}

function addChecklistItem() {
  if (!templateForm.value.checklistItems) {
    templateForm.value.checklistItems = []
  }
  templateForm.value.checklistItems.push({
    itemText: '',
    isRequired: false
  })
}

function removeChecklistItem(index) {
  templateForm.value.checklistItems.splice(index, 1)
}

async function saveTemplate() {
  try {
    // Validation
    showNameError.value = false
    showItemsError.value = false

    if (!templateForm.value.templateName || templateForm.value.templateName.trim() === '') {
      showNameError.value = true
      return
    }

    if (!templateForm.value.checklistItems || templateForm.value.checklistItems.length === 0) {
      showItemsError.value = true
      return
    }

    if (showEditModal.value && templateForm.value.templateId) {
      await templatesStore.updateTemplate(templateForm.value.templateId, templateForm.value)
      successMessage.value = 'Template updated successfully'
    } else {
      await templatesStore.createTemplate(templateForm.value)
      successMessage.value = 'Template created successfully'
    }
    closeEditModal()
    await loadTemplates()

    // Show success message for 3 seconds
    setTimeout(() => {
      successMessage.value = ''
    }, 3000)
  } catch (error) {
    console.error('Error saving template:', error)
    alert('Failed to save template')
  }
}

function confirmDelete(template) {
  templateToDelete.value = template
  showDeleteModal.value = true
}

async function deleteTemplate() {
  try {
    await templatesStore.deleteTemplate(templateToDelete.value.templateId)
    successMessage.value = 'Template deleted successfully'
    closeDeleteModal()
    await loadTemplates()

    // Show success message for 3 seconds
    setTimeout(() => {
      successMessage.value = ''
    }, 3000)
  } catch (error) {
    console.error('Error deleting template:', error)
    alert('Failed to delete template')
  }
}

function duplicateTemplate(template) {
  templateToDuplicate.value = template
  newTemplateName.value = `${template.templateName} (Copy)`
  showDuplicateModal.value = true
}

async function saveDuplicate() {
  try {
    await templatesStore.duplicateTemplate(
      templateToDuplicate.value.templateId,
      newTemplateName.value
    )
    successMessage.value = 'Template duplicated successfully'
    showDuplicateModal.value = false
    templateToDuplicate.value = null
    newTemplateName.value = ''
    await loadTemplates()

    // Show success message for 3 seconds
    setTimeout(() => {
      successMessage.value = ''
    }, 3000)
  } catch (error) {
    console.error('Error duplicating template:', error)
    alert('Failed to duplicate template')
  }
}

function closeViewModal() {
  showViewModal.value = false
  currentTemplate.value = null
}

function closeEditModal() {
  showCreateModal.value = false
  showEditModal.value = false
  showNameError.value = false
  showItemsError.value = false
  templateForm.value = {
    templateName: '',
    description: '',
    templateType: 'CUSTOM',
    isActive: true,
    isSystemTemplate: false,
    checklistItems: []
  }
}

function closeDeleteModal() {
  showDeleteModal.value = false
  templateToDelete.value = null
}

// Initialize
onMounted(() => {
  loadTemplates()
})
</script>

<style scoped>
.templates-view {
  max-width: 1400px;
  margin: 0 auto;
  padding: 2rem;
}

.success-banner {
  background: #d1fae5;
  color: #065f46;
  padding: 1rem;
  border-radius: 0.375rem;
  margin-bottom: 1rem;
  font-weight: 500;
  border: 1px solid #059669;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 2rem;
}

.page-title {
  font-size: 2rem;
  font-weight: 700;
  color: #1f2937;
  margin-bottom: 0.5rem;
}

.page-description {
  color: #6b7280;
}

.btn-create,
.btn-create-empty {
  padding: 0.75rem 1.5rem;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 0.375rem;
  font-weight: 600;
  cursor: pointer;
}

.btn-create:hover {
  background: #2563eb;
}

.tabs {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 2rem;
  border-bottom: 2px solid #e5e7eb;
}

.tab {
  padding: 0.75rem 1.5rem;
  background: none;
  border: none;
  border-bottom: 2px solid transparent;
  color: #6b7280;
  font-weight: 500;
  cursor: pointer;
  margin-bottom: -2px;
}

.tab:hover {
  color: #1f2937;
}

.tab-active {
  color: #3b82f6;
  border-bottom-color: #3b82f6;
}

.loading-state,
.error-state,
.empty-state {
  text-align: center;
  padding: 4rem 2rem;
}

.spinner {
  width: 48px;
  height: 48px;
  border: 4px solid #e5e7eb;
  border-top-color: #3b82f6;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 1rem;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.error-icon,
.empty-icon {
  font-size: 3rem;
  margin-bottom: 1rem;
}

.templates-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 1.5rem;
}

.template-card {
  background: white;
  border-radius: 0.5rem;
  padding: 1.5rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  transition: box-shadow 0.2s;
}

.template-card:hover {
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 0.75rem;
}

.card-title {
  font-size: 1.125rem;
  font-weight: 600;
  color: #1f2937;
  margin: 0;
}

.card-description {
  color: #6b7280;
  font-size: 0.875rem;
  margin-bottom: 1rem;
  line-height: 1.5;
}

.card-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
  padding-top: 1rem;
  border-top: 1px solid #e5e7eb;
}

.meta-item {
  font-size: 0.875rem;
  color: #6b7280;
}

.card-actions {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.btn-card {
  flex: 1;
  min-width: fit-content;
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 0.375rem;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
}

.btn-primary {
  background: #3b82f6;
  color: white;
}

.btn-primary:hover {
  background: #2563eb;
}

.btn-secondary {
  background: #6b7280;
  color: white;
}

.btn-secondary:hover {
  background: #4b5563;
}

.btn-danger {
  background: #ef4444;
  color: white;
}

.btn-danger:hover {
  background: #dc2626;
}

.badge {
  display: inline-block;
  padding: 0.25rem 0.5rem;
  font-size: 0.75rem;
  font-weight: 600;
  border-radius: 0.25rem;
}

.badge-primary {
  background: #dbeafe;
  color: #1e40af;
}

.badge-secondary {
  background: #e0e7ff;
  color: #4338ca;
}

.badge-info {
  background: #dbeafe;
  color: #1e40af;
}

.badge-custom {
  background: #f3e8ff;
  color: #6b21a8;
}

.badge-success {
  background: #d1fae5;
  color: #065f46;
}

.badge-inactive {
  background: #fee2e2;
  color: #991b1b;
}

.badge-error {
  background: #fee2e2;
  color: #991b1b;
}

/* Modal Styles */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 0.5rem;
  max-width: 600px;
  width: 90%;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
}

.modal-large {
  max-width: 800px;
}

.modal-small {
  max-width: 500px;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  border-bottom: 1px solid #e5e7eb;
}

.modal-title {
  font-size: 1.5rem;
  font-weight: 600;
  color: #1f2937;
}

.btn-close {
  background: none;
  border: none;
  font-size: 1.5rem;
  color: #6b7280;
  cursor: pointer;
  padding: 0;
  width: 2rem;
  height: 2rem;
}

.btn-close:hover {
  color: #1f2937;
}

.modal-body {
  padding: 1.5rem;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  padding: 1.5rem;
  border-top: 1px solid #e5e7eb;
  margin-top: 1.5rem;
}

.template-info {
  background: #f9fafb;
  padding: 1rem;
  border-radius: 0.375rem;
  margin-bottom: 1.5rem;
}

.template-info p {
  margin-bottom: 0.5rem;
}

.section-title {
  font-size: 1.125rem;
  font-weight: 600;
  color: #1f2937;
  margin-bottom: 1rem;
}

.checklist-items {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.checklist-item {
  display: flex;
  gap: 1rem;
  padding: 0.75rem;
  background: #f9fafb;
  border-radius: 0.375rem;
}

.item-number {
  flex-shrink: 0;
  width: 2rem;
  height: 2rem;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #3b82f6;
  color: white;
  border-radius: 50%;
  font-weight: 600;
  font-size: 0.875rem;
}

.item-content {
  flex: 1;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
}

.item-text {
  margin: 0;
  color: #1f2937;
}

.form-group {
  margin-bottom: 1rem;
}

.form-label {
  display: block;
  font-size: 0.875rem;
  font-weight: 500;
  color: #374151;
  margin-bottom: 0.5rem;
}

.form-input {
  width: 100%;
  padding: 0.5rem 0.75rem;
  border: 1px solid #d1d5db;
  border-radius: 0.375rem;
  font-size: 0.875rem;
}

.form-input:focus {
  outline: none;
  border-color: #3b82f6;
  ring: 2px;
  ring-color: rgba(59, 130, 246, 0.5);
}

.checkbox-label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  cursor: pointer;
}

.checkbox-input {
  width: 1rem;
  height: 1rem;
  cursor: pointer;
}

@media (max-width: 768px) {
  .templates-grid {
    grid-template-columns: 1fr;
  }

  .page-header {
    flex-direction: column;
    gap: 1rem;
  }
}
</style>
