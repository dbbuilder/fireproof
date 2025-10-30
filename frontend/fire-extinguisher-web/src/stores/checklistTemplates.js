import { defineStore } from 'pinia'
import { ref } from 'vue'
import checklistTemplateService from '@/services/checklistTemplateService'

export const useChecklistTemplateStore = defineStore('checklistTemplates', () => {
  // State
  const templates = ref([])
  const systemTemplates = ref([])
  const currentTemplate = ref(null)
  const loading = ref(false)
  const error = ref(null)

  // Actions
  async function fetchTemplates(activeOnly = true) {
    loading.value = true
    error.value = null

    try {
      templates.value = await checklistTemplateService.getAll(activeOnly)
      return templates.value
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch templates'
      console.error('Error fetching templates:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  async function fetchSystemTemplates() {
    loading.value = true
    error.value = null

    try {
      systemTemplates.value = await checklistTemplateService.getSystemTemplates()
      return systemTemplates.value
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch system templates'
      console.error('Error fetching system templates:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  async function fetchTemplateById(templateId) {
    loading.value = true
    error.value = null

    try {
      currentTemplate.value = await checklistTemplateService.getById(templateId)
      return currentTemplate.value
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch template'
      console.error('Error fetching template:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  async function createTemplate(templateData) {
    loading.value = true
    error.value = null

    try {
      const newTemplate = await checklistTemplateService.create(templateData)
      templates.value.push(newTemplate)
      return newTemplate
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to create template'
      console.error('Error creating template:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  async function updateTemplate(templateId, templateData) {
    loading.value = true
    error.value = null

    try {
      const updatedTemplate = await checklistTemplateService.update(templateId, templateData)

      // Update in list
      const index = templates.value.findIndex(t => t.templateId === templateId)
      if (index !== -1) {
        templates.value[index] = updatedTemplate
      }

      // Update current template if it's the same
      if (currentTemplate.value?.templateId === templateId) {
        currentTemplate.value = updatedTemplate
      }

      return updatedTemplate
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to update template'
      console.error('Error updating template:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  async function deleteTemplate(templateId) {
    loading.value = true
    error.value = null

    try {
      await checklistTemplateService.delete(templateId)

      // Remove from list
      templates.value = templates.value.filter(t => t.templateId !== templateId)

      // Clear current template if it's the same
      if (currentTemplate.value?.templateId === templateId) {
        currentTemplate.value = null
      }
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to delete template'
      console.error('Error deleting template:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  async function addItems(templateId, items) {
    loading.value = true
    error.value = null

    try {
      const updatedTemplate = await checklistTemplateService.addItems(templateId, items)

      // Update current template
      if (currentTemplate.value?.templateId === templateId) {
        currentTemplate.value = updatedTemplate
      }

      return updatedTemplate
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to add items'
      console.error('Error adding items:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  async function duplicateTemplate(templateId, newName) {
    loading.value = true
    error.value = null

    try {
      const newTemplate = await checklistTemplateService.duplicate(templateId, newName)
      templates.value.push(newTemplate)
      return newTemplate
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to duplicate template'
      console.error('Error duplicating template:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  function clearError() {
    error.value = null
  }

  function clearCurrentTemplate() {
    currentTemplate.value = null
  }

  return {
    // State
    templates,
    systemTemplates,
    currentTemplate,
    loading,
    error,

    // Actions
    fetchTemplates,
    fetchSystemTemplates,
    fetchTemplateById,
    createTemplate,
    updateTemplate,
    deleteTemplate,
    addItems,
    duplicateTemplate,
    clearError,
    clearCurrentTemplate
  }
})
