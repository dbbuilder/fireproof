import api from './api'
import type {
  ExtinguisherTypeDto,
  CreateExtinguisherTypeRequest,
  UpdateExtinguisherTypeRequest
} from '@/types/api'

/**
 * Extinguisher type management service
 * Handles all extinguisher type-related API calls with full TypeScript type safety
 */
const extinguisherTypeService = {
  /**
   * Get all extinguisher types for the current tenant
   * @param isActive - Optional filter by active status
   * @returns Promise resolving to array of extinguisher types
   */
  async getAll(isActive: boolean | null = null): Promise<ExtinguisherTypeDto[]> {
    const params = isActive !== null ? { isActive } : {}
    const response = await api.get<ExtinguisherTypeDto[]>('/extinguishertypes', { params })
    return response.data
  },

  /**
   * Get a specific extinguisher type by ID
   * @param extinguisherTypeId - Extinguisher type UUID
   * @returns Promise resolving to extinguisher type details
   */
  async getById(extinguisherTypeId: string): Promise<ExtinguisherTypeDto> {
    const response = await api.get<ExtinguisherTypeDto>(`/extinguishertypes/${extinguisherTypeId}`)
    return response.data
  },

  /**
   * Create a new extinguisher type
   * @param typeData - Extinguisher type creation data
   * @returns Promise resolving to created extinguisher type
   */
  async create(typeData: CreateExtinguisherTypeRequest): Promise<ExtinguisherTypeDto> {
    const response = await api.post<ExtinguisherTypeDto>('/extinguishertypes', typeData)
    return response.data
  },

  /**
   * Update an existing extinguisher type
   * @param extinguisherTypeId - Extinguisher type UUID
   * @param typeData - Updated extinguisher type data
   * @returns Promise resolving to updated extinguisher type
   */
  async update(extinguisherTypeId: string, typeData: UpdateExtinguisherTypeRequest): Promise<ExtinguisherTypeDto> {
    const response = await api.put<ExtinguisherTypeDto>(`/extinguishertypes/${extinguisherTypeId}`, typeData)
    return response.data
  },

  /**
   * Delete an extinguisher type (soft delete)
   * @param extinguisherTypeId - Extinguisher type UUID
   * @returns Promise resolving when delete is complete
   */
  async delete(extinguisherTypeId: string): Promise<void> {
    await api.delete(`/extinguishertypes/${extinguisherTypeId}`)
  }
}

export default extinguisherTypeService
