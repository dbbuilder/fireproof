import api from './api'
import type {
  InspectionDto,
  CreateInspectionRequest,
  InspectionVerificationResponse,
  InspectionStatsDto
} from '@/types/api'

/**
 * Inspection management service with tamper-proof verification
 * Handles all inspection-related API calls with full TypeScript type safety
 */
const inspectionService = {
  /**
   * Create a new tamper-proof inspection
   * @param inspectionData - Inspection creation data
   * @returns Promise resolving to created inspection with cryptographic hash
   */
  async create(inspectionData: CreateInspectionRequest): Promise<InspectionDto> {
    const response = await api.post<InspectionDto>('/inspections', inspectionData)
    return response.data
  },

  /**
   * Get all inspections with optional filtering
   * @param filters - Optional filters for extinguisher, inspector, dates, type, pass/fail
   * @returns Promise resolving to array of inspections
   */
  async getAll(filters?: {
    extinguisherId?: string
    inspectorUserId?: string
    startDate?: string
    endDate?: string
    inspectionType?: string
    passed?: boolean
  }): Promise<InspectionDto[]> {
    const params = filters || {}
    const response = await api.get<InspectionDto[]>('/inspections', { params })
    return response.data
  },

  /**
   * Get a specific inspection by ID
   * @param inspectionId - Inspection UUID
   * @returns Promise resolving to inspection details
   */
  async getById(inspectionId: string): Promise<InspectionDto> {
    const response = await api.get<InspectionDto>(`/inspections/${inspectionId}`)
    return response.data
  },

  /**
   * Get inspection history for a specific extinguisher
   * @param extinguisherId - Extinguisher UUID
   * @returns Promise resolving to array of inspections for this extinguisher
   */
  async getExtinguisherHistory(extinguisherId: string): Promise<InspectionDto[]> {
    const response = await api.get<InspectionDto[]>(`/inspections/extinguisher/${extinguisherId}`)
    return response.data
  },

  /**
   * Get inspections performed by a specific inspector
   * @param inspectorUserId - Inspector UUID
   * @param startDate - Optional start date filter
   * @param endDate - Optional end date filter
   * @returns Promise resolving to array of inspections
   */
  async getInspectorInspections(
    inspectorUserId: string,
    startDate?: string,
    endDate?: string
  ): Promise<InspectionDto[]> {
    const params = { startDate, endDate }
    const response = await api.get<InspectionDto[]>(`/inspections/inspector/${inspectorUserId}`, { params })
    return response.data
  },

  /**
   * Verify the tamper-proof integrity of an inspection
   * @param inspectionId - Inspection UUID
   * @returns Promise resolving to verification response with hash validation
   */
  async verifyIntegrity(inspectionId: string): Promise<InspectionVerificationResponse> {
    const response = await api.post<InspectionVerificationResponse>(`/inspections/${inspectionId}/verify`)
    return response.data
  },

  /**
   * Get inspection statistics
   * @param startDate - Optional start date filter
   * @param endDate - Optional end date filter
   * @returns Promise resolving to inspection statistics
   */
  async getStats(startDate?: string, endDate?: string): Promise<InspectionStatsDto> {
    const params = { startDate, endDate }
    const response = await api.get<InspectionStatsDto>('/inspections/stats', { params })
    return response.data
  },

  /**
   * Get overdue inspections
   * @param inspectionType - Type of inspection (Monthly, Annual, etc.)
   * @returns Promise resolving to array of overdue inspections
   */
  async getOverdue(inspectionType: string = 'Monthly'): Promise<InspectionDto[]> {
    const response = await api.get<InspectionDto[]>('/inspections/overdue', {
      params: { inspectionType }
    })
    return response.data
  },

  /**
   * Delete an inspection
   * @param inspectionId - Inspection UUID
   * @returns Promise resolving when delete is complete
   */
  async delete(inspectionId: string): Promise<void> {
    await api.delete(`/inspections/${inspectionId}`)
  }
}

export default inspectionService
