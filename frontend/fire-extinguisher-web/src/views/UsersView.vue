<template>
  <AppLayout>
    <div class="users-view">
      <!-- Header -->
      <div class="page-header" data-testid="users-heading">
        <div>
          <h1 class="page-title">User Management</h1>
          <p class="page-description">Manage user accounts, roles, and permissions</p>
        </div>
      </div>

      <!-- Search and Filters -->
      <div class="filters-card">
        <div class="filters-grid">
          <div class="filter-item">
            <label for="search" class="filter-label">Search</label>
            <input
              id="search"
              v-model="searchTerm"
              type="text"
              placeholder="Search by email, name..."
              class="filter-input"
              data-testid="search-input"
              @input="debouncedSearch"
            />
          </div>

          <div class="filter-item">
            <label for="status-filter" class="filter-label">Status</label>
            <select
              id="status-filter"
              v-model="statusFilter"
              class="filter-select"
              data-testid="status-filter"
              @change="loadUsers"
            >
              <option :value="null">All Users</option>
              <option :value="true">Active Only</option>
              <option :value="false">Inactive Only</option>
            </select>
          </div>

          <div class="filter-item">
            <label for="page-size" class="filter-label">Per Page</label>
            <select
              id="page-size"
              v-model="pageSize"
              class="filter-select"
              data-testid="page-size-select"
              @change="loadUsers"
            >
              <option :value="25">25</option>
              <option :value="50">50</option>
              <option :value="100">100</option>
            </select>
          </div>
        </div>
      </div>

      <!-- Loading State -->
      <div v-if="usersStore.loading" class="loading-state" data-testid="loading-state">
        <div class="spinner"></div>
        <p>Loading users...</p>
      </div>

      <!-- Error State -->
      <div v-else-if="usersStore.error" class="error-state" data-testid="error-state">
        <div class="error-icon">⚠️</div>
        <p class="error-message">{{ usersStore.error }}</p>
        <button @click="loadUsers" class="btn-retry">Retry</button>
      </div>

      <!-- Users Table -->
      <div v-else-if="usersStore.users.length > 0" class="table-container" data-testid="users-table-container">
        <table class="data-table" data-testid="users-table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Email</th>
              <th>System Roles</th>
              <th>Tenant Roles</th>
              <th>Last Login</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="user in usersStore.users"
              :key="user.userId"
              :data-user-id="user.userId"
              data-testid="user-row"
            >
              <td>
                <div class="user-name">
                  <span class="font-semibold">{{ user.firstName }} {{ user.lastName }}</span>
                  <span v-if="user.emailConfirmed" class="badge badge-success ml-2">✓ Verified</span>
                  <span v-if="user.mfaEnabled" class="badge badge-info ml-2">🔐 MFA</span>
                </div>
              </td>
              <td>{{ user.email }}</td>
              <td>
                <span class="role-count">{{ user.systemRoleCount }} role(s)</span>
              </td>
              <td>
                <span class="role-count">{{ user.tenantRoleCount }} role(s)</span>
              </td>
              <td>
                <span v-if="user.lastLoginDate" class="text-sm">
                  {{ formatDate(user.lastLoginDate) }}
                </span>
                <span v-else class="text-gray-400">Never</span>
              </td>
              <td>
                <span
                  :class="[
                    'badge',
                    user.isActive ? 'badge-success' : 'badge-error'
                  ]"
                  data-testid="user-status"
                >
                  {{ user.isActive ? 'Active' : 'Inactive' }}
                </span>
              </td>
              <td>
                <div class="action-buttons">
                  <button
                    @click="viewUser(user)"
                    class="btn-action btn-primary"
                    data-testid="view-user-button"
                    title="View Details"
                  >
                    👁️
                  </button>
                  <button
                    @click="editUser(user)"
                    class="btn-action btn-secondary"
                    data-testid="edit-user-button"
                    title="Edit User"
                  >
                    ✏️
                  </button>
                  <button
                    @click="confirmDelete(user)"
                    class="btn-action btn-danger"
                    data-testid="delete-user-button"
                    title="Delete User"
                  >
                    🗑️
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>

        <!-- Pagination -->
        <div class="pagination" data-testid="pagination">
          <button
            @click="goToPage(usersStore.pageNumber - 1)"
            :disabled="!usersStore.hasPrevPage"
            class="btn-pagination"
            data-testid="prev-page-button"
          >
            ← Previous
          </button>

          <span class="pagination-info">
            Page {{ usersStore.pageNumber }} of {{ usersStore.totalPages }}
            ({{ usersStore.totalCount }} total users)
          </span>

          <button
            @click="goToPage(usersStore.pageNumber + 1)"
            :disabled="!usersStore.hasNextPage"
            class="btn-pagination"
            data-testid="next-page-button"
          >
            Next →
          </button>
        </div>
      </div>

      <!-- Empty State -->
      <div v-else class="empty-state" data-testid="empty-state">
        <div class="empty-icon">👥</div>
        <h3>No users found</h3>
        <p>{{ searchTerm ? 'Try adjusting your search' : 'No users match the current filters' }}</p>
      </div>

      <!-- User Detail Modal -->
      <teleport to="body">
        <div
          v-if="showDetailModal"
          class="modal-overlay"
          @click="closeDetailModal"
          data-testid="user-detail-modal"
        >
          <div class="modal-content" @click.stop>
            <div class="modal-header">
              <h2 class="modal-title">User Details</h2>
              <button @click="closeDetailModal" class="btn-close">✕</button>
            </div>

            <div v-if="selectedUser" class="modal-body">
              <!-- Basic Info -->
              <section class="detail-section">
                <h3 class="section-title">Basic Information</h3>
                <div class="detail-grid">
                  <div class="detail-item">
                    <span class="detail-label">Name:</span>
                    <span class="detail-value">{{ selectedUser.firstName }} {{ selectedUser.lastName }}</span>
                  </div>
                  <div class="detail-item">
                    <span class="detail-label">Email:</span>
                    <span class="detail-value">{{ selectedUser.email }}</span>
                  </div>
                  <div class="detail-item">
                    <span class="detail-label">Phone:</span>
                    <span class="detail-value">{{ selectedUser.phoneNumber || 'N/A' }}</span>
                  </div>
                  <div class="detail-item">
                    <span class="detail-label">Status:</span>
                    <span :class="['badge', selectedUser.isActive ? 'badge-success' : 'badge-error']">
                      {{ selectedUser.isActive ? 'Active' : 'Inactive' }}
                    </span>
                  </div>
                  <div class="detail-item">
                    <span class="detail-label">Email Verified:</span>
                    <span>{{ selectedUser.emailConfirmed ? '✓ Yes' : '✗ No' }}</span>
                  </div>
                  <div class="detail-item">
                    <span class="detail-label">MFA Enabled:</span>
                    <span>{{ selectedUser.mfaEnabled ? '🔐 Yes' : '✗ No' }}</span>
                  </div>
                </div>
              </section>

              <!-- System Roles -->
              <section class="detail-section">
                <div class="section-header">
                  <h3 class="section-title">System Roles ({{ selectedUser.systemRoles?.length || 0 }})</h3>
                  <button @click="showAddSystemRoleModal = true" class="btn-add-role">
                    + Add System Role
                  </button>
                </div>
                <div v-if="selectedUser.systemRoles?.length" class="roles-list">
                  <div
                    v-for="role in selectedUser.systemRoles"
                    :key="role.systemRoleId"
                    class="role-item"
                  >
                    <div>
                      <span class="role-name">{{ role.roleName }}</span>
                      <span class="role-description">{{ role.description }}</span>
                    </div>
                    <button
                      @click="removeSystemRole(selectedUser.userId, role.systemRoleId)"
                      class="btn-remove-role"
                      title="Remove Role"
                    >
                      ✕
                    </button>
                  </div>
                </div>
                <p v-else class="text-gray-500">No system roles assigned</p>
              </section>

              <!-- Tenant Roles -->
              <section class="detail-section">
                <div class="section-header">
                  <h3 class="section-title">Tenant Roles ({{ selectedUser.tenantRoles?.length || 0 }})</h3>
                  <button @click="showAddTenantRoleModal = true" class="btn-add-role">
                    + Add Tenant Role
                  </button>
                </div>
                <div v-if="selectedUser.tenantRoles?.length" class="roles-list">
                  <div
                    v-for="role in selectedUser.tenantRoles"
                    :key="role.userTenantRoleId"
                    class="role-item"
                  >
                    <div>
                      <span class="role-name">{{ role.roleName }}</span>
                      <span class="role-description">{{ role.tenantName }} ({{ role.tenantCode }})</span>
                    </div>
                    <button
                      @click="removeTenantRole(selectedUser.userId, role.userTenantRoleId)"
                      class="btn-remove-role"
                      title="Remove Role"
                    >
                      ✕
                    </button>
                  </div>
                </div>
                <p v-else class="text-gray-500">No tenant roles assigned</p>
              </section>
            </div>
          </div>
        </div>
      </teleport>

      <!-- Edit User Modal -->
      <teleport to="body">
        <div
          v-if="showEditModal"
          class="modal-overlay"
          @click="closeEditModal"
          data-testid="edit-user-modal"
        >
          <div class="modal-content" @click.stop>
            <div class="modal-header">
              <h2 class="modal-title">Edit User</h2>
              <button @click="closeEditModal" class="btn-close">✕</button>
            </div>

            <form @submit.prevent="saveUser" class="modal-body">
              <div class="form-grid">
                <div class="form-group">
                  <label for="edit-first-name" class="form-label">First Name *</label>
                  <input
                    id="edit-first-name"
                    v-model="editForm.firstName"
                    type="text"
                    required
                    class="form-input"
                    data-testid="edit-first-name"
                  />
                </div>

                <div class="form-group">
                  <label for="edit-last-name" class="form-label">Last Name *</label>
                  <input
                    id="edit-last-name"
                    v-model="editForm.lastName"
                    type="text"
                    required
                    class="form-input"
                    data-testid="edit-last-name"
                  />
                </div>

                <div class="form-group">
                  <label for="edit-phone" class="form-label">Phone Number</label>
                  <input
                    id="edit-phone"
                    v-model="editForm.phoneNumber"
                    type="tel"
                    class="form-input"
                    data-testid="edit-phone"
                  />
                </div>

                <div class="form-group">
                  <label class="checkbox-label">
                    <input
                      v-model="editForm.emailConfirmed"
                      type="checkbox"
                      class="checkbox-input"
                      data-testid="edit-email-confirmed"
                    />
                    <span>Email Confirmed</span>
                  </label>
                </div>

                <div class="form-group">
                  <label class="checkbox-label">
                    <input
                      v-model="editForm.mfaEnabled"
                      type="checkbox"
                      class="checkbox-input"
                      data-testid="edit-mfa-enabled"
                    />
                    <span>MFA Enabled</span>
                  </label>
                </div>

                <div class="form-group">
                  <label class="checkbox-label">
                    <input
                      v-model="editForm.isActive"
                      type="checkbox"
                      class="checkbox-input"
                      data-testid="edit-is-active"
                    />
                    <span>Active</span>
                  </label>
                </div>
              </div>

              <div class="modal-footer">
                <button type="button" @click="closeEditModal" class="btn-secondary">
                  Cancel
                </button>
                <button type="submit" class="btn-primary" :disabled="usersStore.loading">
                  {{ usersStore.loading ? 'Saving...' : 'Save Changes' }}
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
          @click="closeDeleteModal"
          data-testid="delete-confirm-modal"
        >
          <div class="modal-content modal-small" @click.stop>
            <div class="modal-header">
              <h2 class="modal-title">Confirm Delete</h2>
              <button @click="closeDeleteModal" class="btn-close">✕</button>
            </div>

            <div class="modal-body">
              <p>Are you sure you want to delete this user?</p>
              <p class="font-semibold mt-2">
                {{ userToDelete?.firstName }} {{ userToDelete?.lastName }}
                ({{ userToDelete?.email }})
              </p>
              <p class="text-sm text-gray-600 mt-2">
                This will deactivate the user and all their role assignments.
              </p>
            </div>

            <div class="modal-footer">
              <button @click="closeDeleteModal" class="btn-secondary">
                Cancel
              </button>
              <button
                @click="deleteUser"
                class="btn-danger"
                :disabled="usersStore.loading"
              >
                {{ usersStore.loading ? 'Deleting...' : 'Delete User' }}
              </button>
            </div>
          </div>
        </div>
      </teleport>

      <!-- Add System Role Modal -->
      <teleport to="body">
        <div
          v-if="showAddSystemRoleModal"
          class="modal-overlay"
          @click="showAddSystemRoleModal = false"
        >
          <div class="modal-content modal-small" @click.stop>
            <div class="modal-header">
              <h2 class="modal-title">Assign System Role</h2>
              <button @click="showAddSystemRoleModal = false" class="btn-close">✕</button>
            </div>

            <form @submit.prevent="addSystemRole" class="modal-body">
              <div class="form-group">
                <label for="system-role-select" class="form-label">Select System Role</label>
                <select
                  id="system-role-select"
                  v-model="selectedSystemRoleId"
                  required
                  class="form-input"
                >
                  <option value="">-- Select Role --</option>
                  <option
                    v-for="role in availableSystemRoles"
                    :key="role.systemRoleId"
                    :value="role.systemRoleId"
                  >
                    {{ role.roleName }}
                  </option>
                </select>
              </div>

              <div class="modal-footer">
                <button type="button" @click="showAddSystemRoleModal = false" class="btn-secondary">
                  Cancel
                </button>
                <button type="submit" class="btn-primary" :disabled="!selectedSystemRoleId">
                  Assign Role
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
import { useUsersStore } from '@/stores/users'
import AppLayout from '@/components/layout/AppLayout.vue'

const usersStore = useUsersStore()

// Search and Filter
const searchTerm = ref('')
const statusFilter = ref(null)
const pageSize = ref(50)

// Modals
const showDetailModal = ref(false)
const showEditModal = ref(false)
const showDeleteModal = ref(false)
const showAddSystemRoleModal = ref(false)
const showAddTenantRoleModal = ref(false)

// Selected User
const selectedUser = ref(null)
const userToDelete = ref(null)

// Edit Form
const editForm = ref({
  userId: '',
  firstName: '',
  lastName: '',
  phoneNumber: '',
  emailConfirmed: false,
  mfaEnabled: false,
  isActive: true
})

// Role Assignment
const selectedSystemRoleId = ref('')
const availableSystemRoles = computed(() => {
  if (!usersStore.systemRoles || !selectedUser.value) return []

  const assignedRoleIds = new Set(
    selectedUser.value.systemRoles?.map(r => r.systemRoleId) || []
  )

  return usersStore.systemRoles.filter(r => !assignedRoleIds.has(r.systemRoleId))
})

// Debounce search
let searchTimeout
const debouncedSearch = () => {
  clearTimeout(searchTimeout)
  searchTimeout = setTimeout(() => {
    loadUsers()
  }, 500)
}

// Load users
async function loadUsers() {
  try {
    await usersStore.fetchUsers({
      searchTerm: searchTerm.value || null,
      isActive: statusFilter.value,
      page: 1,
      size: pageSize.value
    })
  } catch (error) {
    console.error('Error loading users:', error)
  }
}

// Pagination
async function goToPage(page) {
  try {
    await usersStore.fetchUsers({
      searchTerm: searchTerm.value || null,
      isActive: statusFilter.value,
      page,
      size: pageSize.value
    })
  } catch (error) {
    console.error('Error loading page:', error)
  }
}

// View user details
async function viewUser(user) {
  try {
    selectedUser.value = await usersStore.fetchUserById(user.userId)
    showDetailModal.value = true
  } catch (error) {
    console.error('Error loading user details:', error)
    alert('Failed to load user details')
  }
}

// Edit user
function editUser(user) {
  editForm.value = {
    userId: user.userId,
    firstName: user.firstName,
    lastName: user.lastName,
    phoneNumber: user.phoneNumber || '',
    emailConfirmed: user.emailConfirmed,
    mfaEnabled: user.mfaEnabled,
    isActive: user.isActive
  }
  showEditModal.value = true
}

// Save user changes
async function saveUser() {
  try {
    await usersStore.updateUser(editForm.value.userId, editForm.value)
    alert('User updated successfully')
    showEditModal.value = false
    await loadUsers()
  } catch (error) {
    console.error('Error saving user:', error)
    alert('Failed to update user')
  }
}

// Confirm delete
function confirmDelete(user) {
  userToDelete.value = user
  showDeleteModal.value = true
}

// Delete user
async function deleteUser() {
  try {
    await usersStore.deleteUser(userToDelete.value.userId)
    alert('User deleted successfully')
    showDeleteModal.value = false
    userToDelete.value = null
    await loadUsers()
  } catch (error) {
    console.error('Error deleting user:', error)
    alert('Failed to delete user')
  }
}

// Add system role
async function addSystemRole() {
  if (!selectedSystemRoleId.value || !selectedUser.value) return

  try {
    const roles = await usersStore.assignSystemRole(
      selectedUser.value.userId,
      selectedSystemRoleId.value
    )
    selectedUser.value.systemRoles = roles
    selectedUser.value.systemRoleCount = roles.length
    selectedSystemRoleId.value = ''
    showAddSystemRoleModal.value = false
    alert('System role assigned successfully')
  } catch (error) {
    console.error('Error assigning system role:', error)
    alert('Failed to assign system role')
  }
}

// Remove system role
async function removeSystemRole(userId, roleId) {
  if (!confirm('Are you sure you want to remove this system role?')) return

  try {
    await usersStore.removeSystemRole(userId, roleId)
    selectedUser.value.systemRoles = selectedUser.value.systemRoles.filter(
      r => r.systemRoleId !== roleId
    )
    selectedUser.value.systemRoleCount = selectedUser.value.systemRoles.length
    alert('System role removed successfully')
  } catch (error) {
    console.error('Error removing system role:', error)
    alert('Failed to remove system role')
  }
}

// Remove tenant role
async function removeTenantRole(userId, roleId) {
  if (!confirm('Are you sure you want to remove this tenant role?')) return

  try {
    await usersStore.removeTenantRole(userId, roleId)
    selectedUser.value.tenantRoles = selectedUser.value.tenantRoles.filter(
      r => r.userTenantRoleId !== roleId
    )
    selectedUser.value.tenantRoleCount = selectedUser.value.tenantRoles.length
    alert('Tenant role removed successfully')
  } catch (error) {
    console.error('Error removing tenant role:', error)
    alert('Failed to remove tenant role')
  }
}

// Close modals
function closeDetailModal() {
  showDetailModal.value = false
  selectedUser.value = null
}

function closeEditModal() {
  showEditModal.value = false
  editForm.value = {
    userId: '',
    firstName: '',
    lastName: '',
    phoneNumber: '',
    emailConfirmed: false,
    mfaEnabled: false,
    isActive: true
  }
}

function closeDeleteModal() {
  showDeleteModal.value = false
  userToDelete.value = null
}

// Format date
function formatDate(dateString) {
  const date = new Date(dateString)
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  }).format(date)
}

// Initialize
onMounted(async () => {
  await Promise.all([
    loadUsers(),
    usersStore.fetchAllSystemRoles()
  ])
})
</script>

<style scoped>
.users-view {
  max-width: 1400px;
  margin: 0 auto;
  padding: 2rem;
}

.page-header {
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

.filters-card {
  background: white;
  border-radius: 0.5rem;
  padding: 1.5rem;
  margin-bottom: 2rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.filters-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
}

.filter-item {
  display: flex;
  flex-direction: column;
}

.filter-label {
  font-size: 0.875rem;
  font-weight: 500;
  color: #374151;
  margin-bottom: 0.5rem;
}

.filter-input,
.filter-select {
  padding: 0.5rem 0.75rem;
  border: 1px solid #d1d5db;
  border-radius: 0.375rem;
  font-size: 0.875rem;
}

.filter-input:focus,
.filter-select:focus {
  outline: none;
  border-color: #3b82f6;
  ring: 2px;
  ring-color: rgba(59, 130, 246, 0.5);
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

.error-message {
  color: #ef4444;
  margin-bottom: 1rem;
}

.btn-retry {
  padding: 0.5rem 1rem;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 0.375rem;
  cursor: pointer;
}

.btn-retry:hover {
  background: #2563eb;
}

.table-container {
  background: white;
  border-radius: 0.5rem;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.data-table {
  width: 100%;
  border-collapse: collapse;
}

.data-table th {
  background: #f9fafb;
  padding: 0.75rem 1rem;
  text-align: left;
  font-weight: 600;
  color: #374151;
  border-bottom: 2px solid #e5e7eb;
}

.data-table td {
  padding: 0.75rem 1rem;
  border-bottom: 1px solid #e5e7eb;
}

.user-name {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.badge {
  display: inline-block;
  padding: 0.25rem 0.5rem;
  font-size: 0.75rem;
  font-weight: 600;
  border-radius: 0.25rem;
}

.badge-success {
  background: #d1fae5;
  color: #065f46;
}

.badge-error {
  background: #fee2e2;
  color: #991b1b;
}

.badge-info {
  background: #dbeafe;
  color: #1e40af;
}

.role-count {
  font-size: 0.875rem;
  color: #6b7280;
}

.action-buttons {
  display: flex;
  gap: 0.5rem;
}

.btn-action {
  padding: 0.25rem 0.5rem;
  border: none;
  border-radius: 0.25rem;
  cursor: pointer;
  font-size: 1rem;
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

.btn-action:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.pagination {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  border-top: 1px solid #e5e7eb;
}

.btn-pagination {
  padding: 0.5rem 1rem;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 0.375rem;
  cursor: pointer;
}

.btn-pagination:hover:not(:disabled) {
  background: #2563eb;
}

.btn-pagination:disabled {
  background: #9ca3af;
  cursor: not-allowed;
}

.pagination-info {
  color: #6b7280;
  font-size: 0.875rem;
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
  max-width: 800px;
  width: 90%;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
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
}

.detail-section {
  margin-bottom: 2rem;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.section-title {
  font-size: 1.125rem;
  font-weight: 600;
  color: #1f2937;
}

.detail-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 1rem;
}

.detail-item {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.detail-label {
  font-size: 0.875rem;
  color: #6b7280;
}

.detail-value {
  font-weight: 500;
  color: #1f2937;
}

.roles-list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.role-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem;
  background: #f9fafb;
  border-radius: 0.375rem;
}

.role-name {
  font-weight: 600;
  color: #1f2937;
  display: block;
}

.role-description {
  font-size: 0.875rem;
  color: #6b7280;
  display: block;
}

.btn-add-role {
  padding: 0.5rem 1rem;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 0.375rem;
  cursor: pointer;
  font-size: 0.875rem;
}

.btn-add-role:hover {
  background: #2563eb;
}

.btn-remove-role {
  background: #ef4444;
  color: white;
  border: none;
  border-radius: 0.25rem;
  padding: 0.25rem 0.5rem;
  cursor: pointer;
}

.btn-remove-role:hover {
  background: #dc2626;
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 1rem;
}

.form-group {
  display: flex;
  flex-direction: column;
}

.form-label {
  font-size: 0.875rem;
  font-weight: 500;
  color: #374151;
  margin-bottom: 0.5rem;
}

.form-input {
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
  .filters-grid,
  .detail-grid,
  .form-grid {
    grid-template-columns: 1fr;
  }

  .data-table {
    font-size: 0.875rem;
  }

  .action-buttons {
    flex-direction: column;
  }
}
</style>
