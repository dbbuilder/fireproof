import api from './api'

/**
 * Extinguisher type management service
 * Handles all extinguisher type-related API calls
 */
const extinguisherTypeService = {
  /**
   * Get all extinguisher types for the current tenant
   * @param {boolean|null} isActive - Filter by active status
   * @returns {Promise<Array>} Array of extinguisher types
   */
  async getAll(isActive = null) {
    const params = isActive !== null ? { isActive } : {}
    const response = await api.get('/extinguishertypes', { params })
    return response.data
  },

  /**
   * Get a specific extinguisher type by ID
   * @param {string} extinguisherTypeId - Extinguisher type ID
   * @returns {Promise<Object>} Extinguisher type details
   */
  async getById(extinguisherTypeId) {
    const response = await api.get(`/extinguishertypes/${extinguisherTypeId}`)
    return response.data
  },

  /**
   * Create a new extinguisher type
   * @param {Object} typeData - Extinguisher type data
   * @returns {Promise<Object>} Created extinguisher type
   */
  async create(typeData) {
    const response = await api.post('/extinguishertypes', typeData)
    return response.data
  },

  /**
   * Update an existing extinguisher type
   * @param {string} extinguisherTypeId - Extinguisher type ID
   * @param {Object} typeData - Updated extinguisher type data
   * @returns {Promise<Object>} Updated extinguisher type
   */
  async update(extinguisherTypeId, typeData) {
    const response = await api.put(`/extinguishertypes/${extinguisherTypeId}`, typeData)
    return response.data
  },

  /**
   * Delete an extinguisher type (soft delete)
   * @param {string} extinguisherTypeId - Extinguisher type ID
   * @returns {Promise<void>}
   */
  async delete(extinguisherTypeId) {
    await api.delete(`/extinguishertypes/${extinguisherTypeId}`)
  }
}

export default extinguisherTypeService
