import api from './api'

/**
 * Location management service
 * Handles all location-related API calls
 */
const locationService = {
  /**
   * Get all locations for the current tenant
   * @param {boolean|null} isActive - Filter by active status
   * @returns {Promise<Array>} Array of locations
   */
  async getAll(isActive = null) {
    const params = isActive !== null ? { isActive } : {}
    const response = await api.get('/locations', { params })
    return response.data
  },

  /**
   * Get a specific location by ID
   * @param {string} locationId - Location ID
   * @returns {Promise<Object>} Location details
   */
  async getById(locationId) {
    const response = await api.get(`/locations/${locationId}`)
    return response.data
  },

  /**
   * Create a new location
   * @param {Object} locationData - Location data
   * @returns {Promise<Object>} Created location
   */
  async create(locationData) {
    const response = await api.post('/locations', locationData)
    return response.data
  },

  /**
   * Update an existing location
   * @param {string} locationId - Location ID
   * @param {Object} locationData - Updated location data
   * @returns {Promise<Object>} Updated location
   */
  async update(locationId, locationData) {
    const response = await api.put(`/locations/${locationId}`, locationData)
    return response.data
  },

  /**
   * Delete a location (soft delete)
   * @param {string} locationId - Location ID
   * @returns {Promise<void>}
   */
  async delete(locationId) {
    await api.delete(`/locations/${locationId}`)
  }
}

export default locationService
