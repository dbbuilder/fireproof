import api from './api'

/**
 * Checklist template management service
 * Handles NFPA, Title19, ULC standards and custom templates
 */
const checklistTemplateService = {
  /**
   * Get all system templates (NFPA 10, Title 19, ULC)
   * @returns {Promise<Array>} List of system checklist templates
   */
  async getSystemTemplates() {
    const response = await api.get('/checklisttemplates/system')
    return response.data
  },

  /**
   * Get all templates available to the current tenant (system + custom)
   * @param {boolean} activeOnly - Filter by active status
   * @returns {Promise<Array>} List of available checklist templates
   */
  async getAll(activeOnly = true) {
    const params = { activeOnly }
    const response = await api.get('/checklisttemplates', { params })
    return response.data
  },

  /**
   * Get a specific template by ID with all checklist items
   * @param {string} templateId - Template ID
   * @returns {Promise<Object>} Template details with checklist items
   */
  async getById(templateId) {
    const response = await api.get(`/checklisttemplates/${templateId}`)
    return response.data
  },

  /**
   * Create a new custom checklist template
   * @param {Object} templateData - Template data
   * @param {string} templateData.templateName - Template name
   * @param {string} templateData.description - Template description
   * @param {string} templateData.templateType - Type (NFPA_10, TITLE_19, ULC, CUSTOM)
   * @param {boolean} templateData.isSystemTemplate - Is system template (false for custom)
   * @returns {Promise<Object>} Created template
   */
  async create(templateData) {
    const response = await api.post('/checklisttemplates', templateData)
    return response.data
  },

  /**
   * Update an existing template
   * @param {string} templateId - Template ID
   * @param {Object} templateData - Updated template data
   * @returns {Promise<Object>} Updated template
   */
  async update(templateId, templateData) {
    const response = await api.put(`/checklisttemplates/${templateId}`, templateData)
    return response.data
  },

  /**
   * Delete a template (soft delete - system templates cannot be deleted)
   * @param {string} templateId - Template ID
   * @returns {Promise<void>}
   */
  async delete(templateId) {
    await api.delete(`/checklisttemplates/${templateId}`)
  },

  /**
   * Add checklist items to a template
   * @param {string} templateId - Template ID
   * @param {Array<Object>} items - Array of checklist items
   * @returns {Promise<Object>} Updated template with items
   */
  async addItems(templateId, items) {
    const response = await api.post(`/checklisttemplates/${templateId}/items`, items)
    return response.data
  },

  /**
   * Update a checklist item
   * @param {string} templateId - Template ID
   * @param {string} itemId - Checklist item ID
   * @param {Object} itemData - Updated item data
   * @returns {Promise<Object>} Updated item
   */
  async updateItem(templateId, itemId, itemData) {
    const response = await api.put(`/checklisttemplates/${templateId}/items/${itemId}`, itemData)
    return response.data
  },

  /**
   * Delete a checklist item
   * @param {string} templateId - Template ID
   * @param {string} itemId - Checklist item ID
   * @returns {Promise<void>}
   */
  async deleteItem(templateId, itemId) {
    await api.delete(`/checklisttemplates/${templateId}/items/${itemId}`)
  },

  /**
   * Duplicate a template (create a copy)
   * @param {string} templateId - Template ID to duplicate
   * @param {string} newTemplateName - Name for the new template
   * @returns {Promise<Object>} New template
   */
  async duplicate(templateId, newTemplateName) {
    const response = await api.post(`/checklisttemplates/${templateId}/duplicate`, {
      newTemplateName
    })
    return response.data
  }
}

export default checklistTemplateService
