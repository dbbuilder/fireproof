import api from './api'

/**
 * User management service (SystemAdmin only)
 * Handles all user-related API calls including role management
 */
const userService = {
  /**
   * Get all users with optional filtering and pagination
   * @param {Object} params - Query parameters
   * @param {string|null} params.searchTerm - Search term for email, first name, or last name
   * @param {boolean|null} params.isActive - Filter by active status
   * @param {number} params.pageNumber - Page number (1-based)
   * @param {number} params.pageSize - Number of records per page
   * @returns {Promise<Object>} Paginated list of users
   */
  async getAll({ searchTerm = null, isActive = null, pageNumber = 1, pageSize = 50 } = {}) {
    const params = {}
    if (searchTerm) params.searchTerm = searchTerm
    if (isActive !== null) params.isActive = isActive
    if (pageNumber) params.pageNumber = pageNumber
    if (pageSize) params.pageSize = pageSize

    const response = await api.get('/users', { params })
    return response.data
  },

  /**
   * Get a specific user by ID with full role information
   * @param {string} userId - User ID
   * @returns {Promise<Object>} User details with roles
   */
  async getById(userId) {
    const response = await api.get(`/users/${userId}`)
    return response.data
  },

  /**
   * Update user profile information
   * @param {string} userId - User ID
   * @param {Object} userData - Updated user data
   * @returns {Promise<Object>} Updated user
   */
  async update(userId, userData) {
    const response = await api.put(`/users/${userId}`, {
      ...userData,
      userId
    })
    return response.data
  },

  /**
   * Delete a user (soft delete)
   * @param {string} userId - User ID
   * @returns {Promise<void>}
   */
  async delete(userId) {
    await api.delete(`/users/${userId}`)
  },

  /**
   * Get all system roles assigned to a user
   * @param {string} userId - User ID
   * @returns {Promise<Array>} List of system roles
   */
  async getSystemRoles(userId) {
    const response = await api.get(`/users/${userId}/system-roles`)
    return response.data
  },

  /**
   * Assign a system role to a user
   * @param {string} userId - User ID
   * @param {string} systemRoleId - System role ID
   * @returns {Promise<Array>} Updated list of system roles
   */
  async assignSystemRole(userId, systemRoleId) {
    const response = await api.post(`/users/${userId}/system-roles`, {
      userId,
      systemRoleId
    })
    return response.data
  },

  /**
   * Remove a system role from a user
   * @param {string} userId - User ID
   * @param {string} systemRoleId - System role ID
   * @returns {Promise<void>}
   */
  async removeSystemRole(userId, systemRoleId) {
    await api.delete(`/users/${userId}/system-roles/${systemRoleId}`)
  },

  /**
   * Get all tenant roles assigned to a user
   * @param {string} userId - User ID
   * @returns {Promise<Array>} List of tenant roles
   */
  async getTenantRoles(userId) {
    const response = await api.get(`/users/${userId}/tenant-roles`)
    return response.data
  },

  /**
   * Assign a tenant role to a user
   * @param {string} userId - User ID
   * @param {string} tenantId - Tenant ID
   * @param {string} roleName - Role name (TenantAdmin, LocationManager, Inspector, Viewer)
   * @returns {Promise<Array>} Updated list of tenant roles
   */
  async assignTenantRole(userId, tenantId, roleName) {
    const response = await api.post(`/users/${userId}/tenant-roles`, {
      userId,
      tenantId,
      roleName
    })
    return response.data
  },

  /**
   * Remove a tenant role from a user
   * @param {string} userId - User ID
   * @param {string} userTenantRoleId - User tenant role ID
   * @returns {Promise<void>}
   */
  async removeTenantRole(userId, userTenantRoleId) {
    await api.delete(`/users/${userId}/tenant-roles/${userTenantRoleId}`)
  },

  /**
   * Get all available system roles (for dropdown selection)
   * @returns {Promise<Array>} List of system roles
   */
  async getAllSystemRoles() {
    const response = await api.get('/users/system-roles')
    return response.data
  }
}

export default userService
