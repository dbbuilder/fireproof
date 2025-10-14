import api from './api'
import type {
  InspectionPhase1Dto,
  CreateInspectionPhase1Request,
  UpdateInspectionPhase1Request,
  CompleteInspectionRequest,
  InspectionChecklistResponseDto,
  SaveChecklistResponsesRequest,
  InspectionPhase1VerificationResponse,
  InspectionPhase1StatsDto
} from '@/types/api'

/**
 * Inspection Phase 1 Service
 * Manages checklist-based inspections with NFPA compliance
 * Supports multi-step workflow: Create → Respond → Complete
 * Mobile-optimized for offline queue sync
 */
const inspectionPhase1Service = {
  /**
   * Create a new inspection
   * @param inspectionData - Inspection creation data
   * @returns Promise resolving to created inspection (status: InProgress)
   */
  async create(inspectionData: CreateInspectionPhase1Request): Promise<InspectionPhase1Dto> {
    const response = await api.post<InspectionPhase1Dto>('/v2/inspections', inspectionData)
    return response.data
  },

  /**
   * Get all inspections with optional filters
   * @param filters - Query filters
   * @returns Promise resolving to array of inspections
   */
  async getAll(filters: {
    extinguisherId?: string | null
    inspectorUserId?: string | null
    startDate?: string | null
    endDate?: string | null
    status?: string | null
    inspectionType?: string | null
  } = {}): Promise<InspectionPhase1Dto[]> {
    const params = Object.fromEntries(
      Object.entries(filters).filter(([_, value]) => value !== null && value !== undefined)
    )
    const response = await api.get<InspectionPhase1Dto[]>('/v2/inspections', { params })
    return response.data
  },

  /**
   * Get a specific inspection by ID
   * @param inspectionId - Inspection UUID
   * @param includeDetails - Include checklist responses, photos, deficiencies
   * @returns Promise resolving to inspection details
   */
  async getById(inspectionId: string, includeDetails: boolean = true): Promise<InspectionPhase1Dto> {
    const params = { includeDetails }
    const response = await api.get<InspectionPhase1Dto>(`/v2/inspections/${inspectionId}`, { params })
    return response.data
  },

  /**
   * Update inspection metadata (GPS, notes)
   * @param inspectionId - Inspection UUID
   * @param inspectionData - Updated inspection data
   * @returns Promise resolving to updated inspection
   */
  async update(inspectionId: string, inspectionData: UpdateInspectionPhase1Request): Promise<InspectionPhase1Dto> {
    const response = await api.put<InspectionPhase1Dto>(`/v2/inspections/${inspectionId}`, inspectionData)
    return response.data
  },

  /**
   * Complete an inspection (sets status to Completed)
   * @param inspectionId - Inspection UUID
   * @param completionData - Overall result, notes, signature
   * @returns Promise resolving to completed inspection
   */
  async complete(inspectionId: string, completionData: CompleteInspectionRequest): Promise<InspectionPhase1Dto> {
    const response = await api.put<InspectionPhase1Dto>(`/v2/inspections/${inspectionId}/complete`, completionData)
    return response.data
  },

  /**
   * Delete an inspection (soft delete)
   * @param inspectionId - Inspection UUID
   * @returns Promise resolving when delete is complete
   */
  async delete(inspectionId: string): Promise<void> {
    await api.delete(`/v2/inspections/${inspectionId}`)
  },

  /**
   * Save checklist responses (batch operation)
   * @param inspectionId - Inspection UUID
   * @param responsesData - Checklist responses
   * @returns Promise resolving to saved responses
   */
  async saveChecklistResponses(
    inspectionId: string,
    responsesData: SaveChecklistResponsesRequest
  ): Promise<InspectionChecklistResponseDto[]> {
    const response = await api.post<InspectionChecklistResponseDto[]>(
      `/v2/inspections/${inspectionId}/responses`,
      responsesData
    )
    return response.data
  },

  /**
   * Get checklist responses for an inspection
   * @param inspectionId - Inspection UUID
   * @returns Promise resolving to array of responses
   */
  async getChecklistResponses(inspectionId: string): Promise<InspectionChecklistResponseDto[]> {
    const response = await api.get<InspectionChecklistResponseDto[]>(`/v2/inspections/${inspectionId}/responses`)
    return response.data
  },

  /**
   * Get inspection history for a specific extinguisher
   * @param extinguisherId - Extinguisher UUID
   * @param limit - Max number of inspections to return
   * @returns Promise resolving to inspection history
   */
  async getExtinguisherHistory(extinguisherId: string, limit: number = 20): Promise<InspectionPhase1Dto[]> {
    const params = { limit }
    const response = await api.get<InspectionPhase1Dto[]>(`/v2/inspections/extinguisher/${extinguisherId}`, { params })
    return response.data
  },

  /**
   * Get inspections for a specific inspector
   * @param inspectorUserId - Inspector user UUID
   * @param filters - Optional filters
   * @returns Promise resolving to inspector's inspections
   */
  async getInspectorInspections(
    inspectorUserId: string,
    filters: {
      startDate?: string | null
      endDate?: string | null
      status?: string | null
    } = {}
  ): Promise<InspectionPhase1Dto[]> {
    const params = Object.fromEntries(
      Object.entries(filters).filter(([_, value]) => value !== null && value !== undefined)
    )
    const response = await api.get<InspectionPhase1Dto[]>(`/v2/inspections/inspector/${inspectorUserId}`, { params })
    return response.data
  },

  /**
   * Get due inspections (within date range)
   * @param startDate - Start date (ISO 8601)
   * @param endDate - End date (ISO 8601)
   * @returns Promise resolving to due inspections
   */
  async getDueInspections(startDate?: string | null, endDate?: string | null): Promise<InspectionPhase1Dto[]> {
    const params: any = {}
    if (startDate) params.startDate = startDate
    if (endDate) params.endDate = endDate
    const response = await api.get<InspectionPhase1Dto[]>('/v2/inspections/due', { params })
    return response.data
  },

  /**
   * Get scheduled inspections (within date range)
   * @param startDate - Start date (ISO 8601)
   * @param endDate - End date (ISO 8601)
   * @returns Promise resolving to scheduled inspections
   */
  async getScheduledInspections(startDate?: string | null, endDate?: string | null): Promise<InspectionPhase1Dto[]> {
    const params: any = {}
    if (startDate) params.startDate = startDate
    if (endDate) params.endDate = endDate
    const response = await api.get<InspectionPhase1Dto[]>('/v2/inspections/scheduled', { params })
    return response.data
  },

  /**
   * Verify inspection integrity (blockchain-style hash verification)
   * @param inspectionId - Inspection UUID
   * @returns Promise resolving to verification result
   */
  async verifyIntegrity(inspectionId: string): Promise<InspectionPhase1VerificationResponse> {
    const response = await api.post<InspectionPhase1VerificationResponse>(`/v2/inspections/${inspectionId}/verify`)
    return response.data
  },

  /**
   * Get inspection statistics
   * @param startDate - Start date (ISO 8601)
   * @param endDate - End date (ISO 8601)
   * @param inspectorUserId - Optional inspector filter
   * @returns Promise resolving to inspection stats
   */
  async getStats(
    startDate?: string | null,
    endDate?: string | null,
    inspectorUserId?: string | null
  ): Promise<InspectionPhase1StatsDto> {
    const params: any = {}
    if (startDate) params.startDate = startDate
    if (endDate) params.endDate = endDate
    if (inspectorUserId) params.inspectorUserId = inspectorUserId
    const response = await api.get<InspectionPhase1StatsDto>('/v2/inspections/stats', { params })
    return response.data
  }
}

export default inspectionPhase1Service
