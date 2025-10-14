import api from './api'
import type {
  ChecklistTemplateDto,
  ChecklistItemDto,
  CreateChecklistTemplateRequest,
  UpdateChecklistTemplateRequest,
  CreateChecklistItemsRequest
} from '@/types/api'

/**
 * Checklist Template Service
 * Manages NFPA 10 compliance templates (Monthly, Annual, 6-Year, 12-Year, Hydrostatic)
 * Supports both system templates and tenant-specific custom templates
 */
const checklistTemplateService = {
  /**
   * Get all system-wide NFPA templates
   * @returns Promise resolving to array of system templates
   */
  async getSystemTemplates(): Promise<ChecklistTemplateDto[]> {
    const response = await api.get<ChecklistTemplateDto[]>('/checklisttemplates/system')
    return response.data
  },

  /**
   * Get all templates for current tenant (system + tenant custom)
   * @param activeOnly - Filter by active status
   * @returns Promise resolving to array of templates
   */
  async getTenantTemplates(activeOnly: boolean = true): Promise<ChecklistTemplateDto[]> {
    const params = { activeOnly }
    const response = await api.get<ChecklistTemplateDto[]>('/checklisttemplates/tenant', { params })
    return response.data
  },

  /**
   * Get templates by inspection type
   * @param inspectionType - Monthly, Annual, 6-Year, 12-Year, or Hydrostatic
   * @returns Promise resolving to array of matching templates
   */
  async getByType(inspectionType: string): Promise<ChecklistTemplateDto[]> {
    const response = await api.get<ChecklistTemplateDto[]>(`/checklisttemplates/type/${inspectionType}`)
    return response.data
  },

  /**
   * Get a specific template by ID with checklist items
   * @param templateId - Template UUID
   * @returns Promise resolving to template with items
   */
  async getById(templateId: string): Promise<ChecklistTemplateDto> {
    const response = await api.get<ChecklistTemplateDto>(`/checklisttemplates/${templateId}`)
    return response.data
  },

  /**
   * Get checklist items for a specific template
   * @param templateId - Template UUID
   * @returns Promise resolving to array of checklist items
   */
  async getItems(templateId: string): Promise<ChecklistItemDto[]> {
    const response = await api.get<ChecklistItemDto[]>(`/checklisttemplates/${templateId}/items`)
    return response.data
  },

  /**
   * Create a custom tenant-specific template
   * @param templateData - Template creation data
   * @returns Promise resolving to created template
   */
  async create(templateData: CreateChecklistTemplateRequest): Promise<ChecklistTemplateDto> {
    const response = await api.post<ChecklistTemplateDto>('/checklisttemplates', templateData)
    return response.data
  },

  /**
   * Add checklist items to a template
   * @param templateId - Template UUID
   * @param itemsData - Items to add
   * @returns Promise resolving to created items
   */
  async addItems(templateId: string, itemsData: CreateChecklistItemsRequest): Promise<ChecklistItemDto[]> {
    const response = await api.post<ChecklistItemDto[]>(`/checklisttemplates/${templateId}/items`, itemsData)
    return response.data
  },

  /**
   * Update an existing template
   * @param templateId - Template UUID
   * @param templateData - Updated template data
   * @returns Promise resolving to updated template
   */
  async update(templateId: string, templateData: UpdateChecklistTemplateRequest): Promise<ChecklistTemplateDto> {
    const response = await api.put<ChecklistTemplateDto>(`/checklisttemplates/${templateId}`, templateData)
    return response.data
  },

  /**
   * Deactivate a template (soft delete for tenant templates)
   * @param templateId - Template UUID
   * @returns Promise resolving when deactivation is complete
   */
  async deactivate(templateId: string): Promise<void> {
    await api.delete(`/checklisttemplates/${templateId}`)
  }
}

export default checklistTemplateService
