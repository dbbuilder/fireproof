import { defineStore } from 'pinia'
import checklistTemplateService from '@/services/checklistTemplateService'
import type {
  ChecklistTemplateDto,
  ChecklistItemDto,
  CreateChecklistTemplateRequest,
  UpdateChecklistTemplateRequest,
  CreateChecklistItemsRequest
} from '@/types/api'

interface ChecklistTemplateState {
  templates: ChecklistTemplateDto[]
  systemTemplates: ChecklistTemplateDto[]
  currentTemplate: ChecklistTemplateDto | null
  templateItems: Record<string, ChecklistItemDto[]> // Keyed by templateId
  loading: boolean
  error: string | null
}

export const useChecklistTemplateStore = defineStore('checklistTemplates', {
  state: (): ChecklistTemplateState => ({
    templates: [],
    systemTemplates: [],
    currentTemplate: null,
    templateItems: {},
    loading: false,
    error: null
  }),

  getters: {
    activeTemplates: (state): ChecklistTemplateDto[] => {
      return state.templates.filter(template => template.isActive)
    },

    templateCount: (state): number => state.templates.length,

    getTemplateById: (state) => (id: string): ChecklistTemplateDto | undefined => {
      return state.templates.find(template => template.templateId === id)
    },

    /**
     * Get templates by inspection type
     */
    getTemplatesByType: (state) => (inspectionType: string): ChecklistTemplateDto[] => {
      return state.templates.filter(template => template.inspectionType === inspectionType)
    },

    /**
     * Get templates grouped by inspection type
     */
    templatesByType: (state): Record<string, ChecklistTemplateDto[]> => {
      const grouped: Record<string, ChecklistTemplateDto[]> = {}
      state.templates.forEach(template => {
        const type = template.inspectionType
        if (!grouped[type]) {
          grouped[type] = []
        }
        grouped[type].push(template)
      })
      return grouped
    },

    /**
     * Get checklist items for a specific template
     */
    getItemsForTemplate: (state) => (templateId: string): ChecklistItemDto[] | undefined => {
      return state.templateItems[templateId]
    }
  },

  actions: {
    async fetchSystemTemplates(): Promise<void> {
      this.loading = true
      this.error = null

      try {
        this.systemTemplates = await checklistTemplateService.getSystemTemplates()
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch system templates'
        console.error('Error fetching system templates:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchTenantTemplates(activeOnly: boolean = true): Promise<void> {
      this.loading = true
      this.error = null

      try {
        this.templates = await checklistTemplateService.getTenantTemplates(activeOnly)
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch tenant templates'
        console.error('Error fetching tenant templates:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchTemplatesByType(inspectionType: string): Promise<void> {
      this.loading = true
      this.error = null

      try {
        const templates = await checklistTemplateService.getByType(inspectionType)
        // Merge with existing templates (avoid duplicates)
        templates.forEach(template => {
          const index = this.templates.findIndex(t => t.templateId === template.templateId)
          if (index === -1) {
            this.templates.push(template)
          } else {
            this.templates[index] = template
          }
        })
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch templates by type'
        console.error('Error fetching templates by type:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchTemplateById(id: string): Promise<ChecklistTemplateDto> {
      this.loading = true
      this.error = null

      try {
        this.currentTemplate = await checklistTemplateService.getById(id)
        return this.currentTemplate
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch template'
        console.error('Error fetching template:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchTemplateItems(templateId: string): Promise<ChecklistItemDto[]> {
      this.loading = true
      this.error = null

      try {
        const items = await checklistTemplateService.getItems(templateId)
        this.templateItems[templateId] = items
        return items
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch template items'
        console.error('Error fetching template items:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async createTemplate(templateData: CreateChecklistTemplateRequest): Promise<ChecklistTemplateDto> {
      this.loading = true
      this.error = null

      try {
        const newTemplate = await checklistTemplateService.create(templateData)
        this.templates.push(newTemplate)
        return newTemplate
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to create template'
        console.error('Error creating template:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async addTemplateItems(templateId: string, itemsData: CreateChecklistItemsRequest): Promise<ChecklistItemDto[]> {
      this.loading = true
      this.error = null

      try {
        const items = await checklistTemplateService.addItems(templateId, itemsData)
        this.templateItems[templateId] = items
        return items
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to add template items'
        console.error('Error adding template items:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async updateTemplate(id: string, templateData: UpdateChecklistTemplateRequest): Promise<ChecklistTemplateDto> {
      this.loading = true
      this.error = null

      try {
        const updatedTemplate = await checklistTemplateService.update(id, templateData)

        // Update in local state
        const index = this.templates.findIndex(template => template.templateId === id)
        if (index !== -1) {
          this.templates[index] = updatedTemplate
        }

        if (this.currentTemplate?.templateId === id) {
          this.currentTemplate = updatedTemplate
        }

        return updatedTemplate
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to update template'
        console.error('Error updating template:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async deactivateTemplate(id: string): Promise<void> {
      this.loading = true
      this.error = null

      try {
        await checklistTemplateService.deactivate(id)

        // Update in local state (mark as inactive)
        const index = this.templates.findIndex(template => template.templateId === id)
        if (index !== -1) {
          this.templates[index] = {
            ...this.templates[index],
            isActive: false
          }
        }

        if (this.currentTemplate?.templateId === id) {
          this.currentTemplate = {
            ...this.currentTemplate,
            isActive: false
          }
        }
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to deactivate template'
        console.error('Error deactivating template:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    clearError(): void {
      this.error = null
    }
  }
})
