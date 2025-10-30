import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import importService from '@/services/importService'

/**
 * Pinia store for import/export management
 */
export const useImportStore = defineStore('imports', () => {
  // ========================================================================
  // State
  // ========================================================================

  const importJobs = ref([])
  const currentJob = ref(null)
  const mappingTemplates = ref([])
  const historicalImportStatus = ref(null)

  // Upload state
  const uploadProgress = ref(0)
  const uploadedFileInfo = ref(null)
  const previewRows = ref([])
  const detectedHeaders = ref([])

  // Field mapping state
  const fieldMappings = ref([])
  const validationResults = ref(null)

  // Pagination
  const pageNumber = ref(1)
  const pageSize = ref(50)
  const totalCount = ref(0)

  // Loading states
  const isLoading = ref(false)
  const isUploading = ref(false)
  const isValidating = ref(false)
  const isImporting = ref(false)

  // Error state
  const error = ref(null)

  // ========================================================================
  // Computed
  // ========================================================================

  const totalPages = computed(() => Math.ceil(totalCount.value / pageSize.value))
  const hasNextPage = computed(() => pageNumber.value < totalPages.value)
  const hasPrevPage = computed(() => pageNumber.value > 1)

  const canImportHistoricalData = computed(() => {
    return historicalImportStatus.value?.allowHistoricalImports ?? false
  })

  const validationSummary = computed(() => {
    if (!validationResults.value) return null

    return {
      totalRows: validationResults.value.totalRows,
      validRows: validationResults.value.validRows,
      invalidRows: validationResults.value.invalidRows,
      rowsWithWarnings: validationResults.value.rowsWithWarnings,
      canProceed: validationResults.value.canProceed,
      hasErrors: validationResults.value.invalidRows > 0 || validationResults.value.globalErrors?.length > 0,
      hasWarnings: validationResults.value.rowsWithWarnings > 0
    }
  })

  // ========================================================================
  // Actions
  // ========================================================================

  /**
   * Fetches import job history
   */
  async function fetchImportHistory(jobType = null) {
    try {
      isLoading.value = true
      error.value = null

      const response = await importService.getImportHistory({
        jobType,
        pageNumber: pageNumber.value,
        pageSize: pageSize.value
      })

      importJobs.value = response.jobs
      totalCount.value = response.totalCount
    } catch (err) {
      error.value = err.response?.data?.error || 'Failed to fetch import history'
      console.error('Error fetching import history:', err)
      throw err
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Fetches import job by ID
   */
  async function fetchImportJobById(importJobId) {
    try {
      isLoading.value = true
      error.value = null

      currentJob.value = await importService.getImportJobById(importJobId)
    } catch (err) {
      error.value = err.response?.data?.error || 'Failed to fetch import job'
      console.error('Error fetching import job:', err)
      throw err
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Uploads a file and gets preview
   */
  async function uploadFile(file, jobType) {
    try {
      isUploading.value = true
      uploadProgress.value = 0
      error.value = null

      const response = await importService.uploadFile(
        file,
        jobType,
        (progress) => {
          uploadProgress.value = progress
        }
      )

      uploadedFileInfo.value = {
        fileName: response.fileName,
        fileSize: response.fileSize,
        fileHash: response.fileHash,
        totalRows: response.totalRows
      }

      detectedHeaders.value = response.headers
      previewRows.value = response.previewRows

      // Initialize field mappings with auto-detected mappings
      initializeFieldMappings(response.headers)

      return response
    } catch (err) {
      error.value = err.response?.data?.error || 'Failed to upload file'
      console.error('Error uploading file:', err)
      throw err
    } finally {
      isUploading.value = false
    }
  }

  /**
   * Initializes field mappings with auto-detection
   */
  function initializeFieldMappings(headers) {
    // Auto-detect common field mappings based on header names
    const mappingRules = {
      'ExtinguisherBarcode': ['barcode', 'extinguisher_barcode', 'ext_barcode', 'id'],
      'InspectionDate': ['inspection_date', 'date', 'inspectiondate', 'inspected_date'],
      'InspectorName': ['inspector', 'inspector_name', 'inspected_by', 'technician'],
      'InspectionType': ['type', 'inspection_type', 'inspectiontype'],
      'PassFail': ['pass_fail', 'status', 'result', 'passfail', 'pass/fail'],
      'Notes': ['notes', 'comments', 'remarks', 'description'],
      'LocationName': ['location', 'location_name', 'site', 'building'],
      'SerialNumber': ['serial', 'serial_number', 'serial_no'],
      'Manufacturer': ['manufacturer', 'make', 'brand'],
      'ExtinguisherType': ['extinguisher_type', 'type', 'class'],
      'Weight': ['weight', 'size', 'capacity'],
      'LastHydroTestDate': ['hydro_date', 'hydro_test_date', 'last_hydro'],
      'ManufactureDate': ['manufacture_date', 'mfg_date', 'manufactured_date']
    }

    fieldMappings.value = headers.map((header) => {
      const normalizedHeader = header.toLowerCase().replace(/\s+/g, '_')

      // Find matching destination field
      let destinationField = ''
      let isRequired = false

      for (const [destField, patterns] of Object.entries(mappingRules)) {
        if (patterns.some((pattern) => normalizedHeader.includes(pattern))) {
          destinationField = destField
          // Mark required fields
          isRequired = ['ExtinguisherBarcode', 'InspectionDate', 'InspectorName', 'InspectionType', 'PassFail'].includes(destField)
          break
        }
      }

      return {
        sourceField: header,
        destinationField: destinationField || '', // Empty if no match
        defaultValue: null,
        isRequired: isRequired,
        transformationType: null,
        transformationOptions: null
      }
    })
  }

  /**
   * Updates a field mapping
   */
  function updateFieldMapping(sourceField, updates) {
    const mapping = fieldMappings.value.find((m) => m.sourceField === sourceField)
    if (mapping) {
      Object.assign(mapping, updates)
    }
  }

  /**
   * Validates import data (dry run)
   */
  async function validateImportData(jobType, rows) {
    try {
      isValidating.value = true
      error.value = null

      const request = {
        jobType,
        rows,
        mappings: {
          mappings: fieldMappings.value,
          globalTransformations: {}
        }
      }

      validationResults.value = await importService.validateImportData(request)
      return validationResults.value
    } catch (err) {
      error.value = err.response?.data?.error || 'Validation failed'
      console.error('Error validating import data:', err)
      throw err
    } finally {
      isValidating.value = false
    }
  }

  /**
   * Creates import job and starts processing
   */
  async function createImportJob(jobType, isDryRun = false) {
    try {
      isImporting.value = true
      error.value = null

      if (!uploadedFileInfo.value) {
        throw new Error('No file uploaded')
      }

      const request = {
        jobType,
        fileName: uploadedFileInfo.value.fileName,
        fileSize: uploadedFileInfo.value.fileSize,
        fileHash: uploadedFileInfo.value.fileHash,
        blobStorageUrl: 'placeholder', // TODO: Implement blob storage upload
        mappingData: JSON.stringify({
          mappings: fieldMappings.value,
          globalTransformations: {}
        }),
        isDryRun
      }

      const job = await importService.createImportJob(request)
      currentJob.value = job

      // Add to import jobs list
      importJobs.value.unshift(job)

      return job
    } catch (err) {
      error.value = err.response?.data?.error || 'Failed to create import job'
      console.error('Error creating import job:', err)
      throw err
    } finally {
      isImporting.value = false
    }
  }

  /**
   * Fetches field mapping templates
   */
  async function fetchMappingTemplates(jobType = null) {
    try {
      isLoading.value = true
      error.value = null

      mappingTemplates.value = await importService.getMappingTemplates(jobType)
    } catch (err) {
      error.value = err.response?.data?.error || 'Failed to fetch mapping templates'
      console.error('Error fetching mapping templates:', err)
      throw err
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Saves field mapping template
   */
  async function saveMappingTemplate(templateName, jobType, isDefault = false) {
    try {
      isLoading.value = true
      error.value = null

      const template = {
        templateName,
        jobType,
        mappingData: JSON.stringify({
          mappings: fieldMappings.value,
          globalTransformations: {}
        }),
        isDefault
      }

      const savedTemplate = await importService.saveMappingTemplate(template)
      mappingTemplates.value.push(savedTemplate)

      return savedTemplate
    } catch (err) {
      error.value = err.response?.data?.error || 'Failed to save mapping template'
      console.error('Error saving mapping template:', err)
      throw err
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Applies a mapping template
   */
  function applyMappingTemplate(template) {
    try {
      const mappingData = JSON.parse(template.mappingData)
      fieldMappings.value = mappingData.mappings
    } catch (err) {
      console.error('Error applying mapping template:', err)
      throw new Error('Invalid mapping template format')
    }
  }

  /**
   * Deletes mapping template
   */
  async function deleteMappingTemplate(mappingTemplateId) {
    try {
      isLoading.value = true
      error.value = null

      await importService.deleteMappingTemplate(mappingTemplateId)

      // Remove from local state
      mappingTemplates.value = mappingTemplates.value.filter(
        (t) => t.mappingTemplateId !== mappingTemplateId
      )
    } catch (err) {
      error.value = err.response?.data?.error || 'Failed to delete mapping template'
      console.error('Error deleting mapping template:', err)
      throw err
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Fetches historical import status
   */
  async function fetchHistoricalImportStatus() {
    try {
      isLoading.value = true
      error.value = null

      historicalImportStatus.value = await importService.getHistoricalImportStatus()
    } catch (err) {
      error.value = err.response?.data?.error || 'Failed to fetch historical import status'
      console.error('Error fetching historical import status:', err)
      throw err
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Toggles historical import feature
   */
  async function toggleHistoricalImports(enable, reason = null) {
    try {
      isLoading.value = true
      error.value = null

      historicalImportStatus.value = await importService.toggleHistoricalImports(enable, reason)
    } catch (err) {
      error.value = err.response?.data?.error || 'Failed to toggle historical imports'
      console.error('Error toggling historical imports:', err)
      throw err
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Resets upload state
   */
  function resetUploadState() {
    uploadProgress.value = 0
    uploadedFileInfo.value = null
    previewRows.value = []
    detectedHeaders.value = []
    fieldMappings.value = []
    validationResults.value = null
    error.value = null
  }

  /**
   * Sets page number
   */
  function setPageNumber(page) {
    pageNumber.value = page
  }

  /**
   * Sets page size
   */
  function setPageSize(size) {
    pageSize.value = size
    pageNumber.value = 1 // Reset to first page
  }

  return {
    // State
    importJobs,
    currentJob,
    mappingTemplates,
    historicalImportStatus,
    uploadProgress,
    uploadedFileInfo,
    previewRows,
    detectedHeaders,
    fieldMappings,
    validationResults,
    pageNumber,
    pageSize,
    totalCount,
    isLoading,
    isUploading,
    isValidating,
    isImporting,
    error,

    // Computed
    totalPages,
    hasNextPage,
    hasPrevPage,
    canImportHistoricalData,
    validationSummary,

    // Actions
    fetchImportHistory,
    fetchImportJobById,
    uploadFile,
    updateFieldMapping,
    validateImportData,
    createImportJob,
    fetchMappingTemplates,
    saveMappingTemplate,
    applyMappingTemplate,
    deleteMappingTemplate,
    fetchHistoricalImportStatus,
    toggleHistoricalImports,
    resetUploadState,
    setPageNumber,
    setPageSize
  }
})
