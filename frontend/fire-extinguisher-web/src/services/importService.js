import api from './api'

/**
 * Service for data import/export operations
 */
const importService = {
  // ========================================================================
  // Import Job Management
  // ========================================================================

  /**
   * Gets import job history for the current tenant
   * @param {Object} params - Query parameters
   * @param {string} params.jobType - Filter by job type (optional)
   * @param {number} params.pageNumber - Page number (default: 1)
   * @param {number} params.pageSize - Page size (default: 50)
   * @returns {Promise<Object>} Import history response with jobs and pagination
   */
  async getImportHistory({ jobType = null, pageNumber = 1, pageSize = 50 } = {}) {
    const params = { pageNumber, pageSize }
    if (jobType) params.jobType = jobType

    const response = await api.get('/imports/history', { params })
    return response.data
  },

  /**
   * Gets import job details by ID
   * @param {string} importJobId - Import job ID
   * @returns {Promise<Object>} Import job details
   */
  async getImportJobById(importJobId) {
    const response = await api.get(`/imports/${importJobId}`)
    return response.data
  },

  // ========================================================================
  // File Upload
  // ========================================================================

  /**
   * Uploads a file for import
   * @param {File} file - File to upload
   * @param {string} jobType - Type of import job (e.g., 'HistoricalInspections')
   * @param {Function} onProgress - Progress callback (optional)
   * @returns {Promise<Object>} Upload response with preview data
   */
  async uploadFile(file, jobType, onProgress = null) {
    const formData = new FormData()
    formData.append('file', file)
    formData.append('jobType', jobType)

    const config = {}
    if (onProgress) {
      config.onUploadProgress = (progressEvent) => {
        const percentCompleted = Math.round(
          (progressEvent.loaded * 100) / progressEvent.total
        )
        onProgress(percentCompleted)
      }
    }

    const response = await api.post('/imports/upload', formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      },
      ...config
    })
    return response.data
  },

  // ========================================================================
  // Validation
  // ========================================================================

  /**
   * Validates import data (dry run)
   * @param {Object} request - Validation request
   * @param {string} request.jobType - Job type
   * @param {Array<Object>} request.rows - Data rows to validate
   * @param {Object} request.mappings - Field mappings
   * @returns {Promise<Object>} Validation response with errors/warnings
   */
  async validateImportData(request) {
    const response = await api.post('/imports/validate', request)
    return response.data
  },

  // ========================================================================
  // Import Execution
  // ========================================================================

  /**
   * Creates an import job and starts processing
   * @param {Object} request - Import job request
   * @param {string} request.jobType - Job type
   * @param {string} request.fileName - File name
   * @param {number} request.fileSize - File size in bytes
   * @param {string} request.fileHash - SHA256 hash of file
   * @param {string} request.blobStorageUrl - URL to uploaded file
   * @param {Object} request.mappingData - Field mappings (JSON string)
   * @param {string} request.mappingTemplateId - Mapping template ID (optional)
   * @param {boolean} request.isDryRun - Dry run flag (default: false)
   * @returns {Promise<Object>} Created import job
   */
  async createImportJob(request) {
    const response = await api.post('/imports', request)
    return response.data
  },

  // ========================================================================
  // Field Mapping Templates
  // ========================================================================

  /**
   * Gets field mapping templates for the current tenant
   * @param {string} jobType - Filter by job type (optional)
   * @returns {Promise<Array<Object>>} List of mapping templates
   */
  async getMappingTemplates(jobType = null) {
    const params = {}
    if (jobType) params.jobType = jobType

    const response = await api.get('/imports/mapping-templates', { params })
    return response.data
  },

  /**
   * Saves a field mapping template
   * @param {Object} template - Template to save
   * @param {string} template.templateName - Template name
   * @param {string} template.jobType - Job type
   * @param {string} template.mappingData - Mapping data (JSON string)
   * @param {string} template.transformationRules - Transformation rules (JSON string, optional)
   * @param {boolean} template.isDefault - Set as default template
   * @returns {Promise<Object>} Saved template
   */
  async saveMappingTemplate(template) {
    const response = await api.post('/imports/mapping-templates', template)
    return response.data
  },

  /**
   * Deletes a field mapping template
   * @param {string} mappingTemplateId - Template ID to delete
   * @returns {Promise<void>}
   */
  async deleteMappingTemplate(mappingTemplateId) {
    await api.delete(`/imports/mapping-templates/${mappingTemplateId}`)
  },

  // ========================================================================
  // Historical Import Settings
  // ========================================================================

  /**
   * Gets historical import status for current tenant
   * @returns {Promise<Object>} Historical import status
   */
  async getHistoricalImportStatus() {
    const response = await api.get('/imports/historical-status')
    return response.data
  },

  /**
   * Toggles historical import feature for current tenant
   * @param {boolean} enable - Enable or disable historical imports
   * @param {string} reason - Reason for change (optional but recommended)
   * @returns {Promise<Object>} Updated historical import status
   */
  async toggleHistoricalImports(enable, reason = null) {
    const response = await api.put('/imports/historical-imports/toggle', {
      enable,
      reason
    })
    return response.data
  }
}

export default importService
