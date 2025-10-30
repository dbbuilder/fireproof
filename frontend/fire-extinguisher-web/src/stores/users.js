import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import userService from '@/services/userService'

export const useUsersStore = defineStore('users', () => {
  // State
  const users = ref([])
  const currentUser = ref(null)
  const systemRoles = ref([])
  const loading = ref(false)
  const error = ref(null)

  // Pagination
  const totalCount = ref(0)
  const pageNumber = ref(1)
  const pageSize = ref(50)

  // Computed
  const totalPages = computed(() => Math.ceil(totalCount.value / pageSize.value))
  const hasNextPage = computed(() => pageNumber.value < totalPages.value)
  const hasPrevPage = computed(() => pageNumber.value > 1)

  // Actions
  async function fetchUsers({ searchTerm = null, isActive = null, page = 1, size = 50 } = {}) {
    loading.value = true
    error.value = null

    try {
      const response = await userService.getAll({
        searchTerm,
        isActive,
        pageNumber: page,
        pageSize: size
      })

      users.value = response.users
      totalCount.value = response.totalCount
      pageNumber.value = response.pageNumber
      pageSize.value = response.pageSize
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch users'
      console.error('Error fetching users:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  async function fetchUserById(userId) {
    loading.value = true
    error.value = null

    try {
      currentUser.value = await userService.getById(userId)
      return currentUser.value
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch user'
      console.error('Error fetching user:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  async function updateUser(userId, userData) {
    loading.value = true
    error.value = null

    try {
      const updatedUser = await userService.update(userId, userData)

      // Update in list
      const index = users.value.findIndex(u => u.userId === userId)
      if (index !== -1) {
        users.value[index] = { ...users.value[index], ...updatedUser }
      }

      // Update current user if it's the same
      if (currentUser.value?.userId === userId) {
        currentUser.value = { ...currentUser.value, ...updatedUser }
      }

      return updatedUser
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to update user'
      console.error('Error updating user:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  async function deleteUser(userId) {
    loading.value = true
    error.value = null

    try {
      await userService.delete(userId)

      // Remove from list
      users.value = users.value.filter(u => u.userId !== userId)
      totalCount.value -= 1

      // Clear current user if it's the same
      if (currentUser.value?.userId === userId) {
        currentUser.value = null
      }
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to delete user'
      console.error('Error deleting user:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  async function assignSystemRole(userId, systemRoleId) {
    loading.value = true
    error.value = null

    try {
      const roles = await userService.assignSystemRole(userId, systemRoleId)

      // Update current user's roles
      if (currentUser.value?.userId === userId) {
        currentUser.value.systemRoles = roles
        currentUser.value.systemRoleCount = roles.length
      }

      return roles
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to assign system role'
      console.error('Error assigning system role:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  async function removeSystemRole(userId, systemRoleId) {
    loading.value = true
    error.value = null

    try {
      await userService.removeSystemRole(userId, systemRoleId)

      // Update current user's roles
      if (currentUser.value?.userId === userId) {
        currentUser.value.systemRoles = currentUser.value.systemRoles.filter(
          r => r.systemRoleId !== systemRoleId
        )
        currentUser.value.systemRoleCount = currentUser.value.systemRoles.length
      }
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to remove system role'
      console.error('Error removing system role:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  async function assignTenantRole(userId, tenantId, roleName) {
    loading.value = true
    error.value = null

    try {
      const roles = await userService.assignTenantRole(userId, tenantId, roleName)

      // Update current user's roles
      if (currentUser.value?.userId === userId) {
        currentUser.value.tenantRoles = roles
        currentUser.value.tenantRoleCount = roles.length
      }

      return roles
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to assign tenant role'
      console.error('Error assigning tenant role:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  async function removeTenantRole(userId, userTenantRoleId) {
    loading.value = true
    error.value = null

    try {
      await userService.removeTenantRole(userId, userTenantRoleId)

      // Update current user's roles
      if (currentUser.value?.userId === userId) {
        currentUser.value.tenantRoles = currentUser.value.tenantRoles.filter(
          r => r.userTenantRoleId !== userTenantRoleId
        )
        currentUser.value.tenantRoleCount = currentUser.value.tenantRoles.length
      }
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to remove tenant role'
      console.error('Error removing tenant role:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  async function fetchAllSystemRoles() {
    loading.value = true
    error.value = null

    try {
      systemRoles.value = await userService.getAllSystemRoles()
      return systemRoles.value
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch system roles'
      console.error('Error fetching system roles:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  function clearError() {
    error.value = null
  }

  function clearCurrentUser() {
    currentUser.value = null
  }

  return {
    // State
    users,
    currentUser,
    systemRoles,
    loading,
    error,
    totalCount,
    pageNumber,
    pageSize,

    // Computed
    totalPages,
    hasNextPage,
    hasPrevPage,

    // Actions
    fetchUsers,
    fetchUserById,
    updateUser,
    deleteUser,
    assignSystemRole,
    removeSystemRole,
    assignTenantRole,
    removeTenantRole,
    fetchAllSystemRoles,
    clearError,
    clearCurrentUser
  }
})
