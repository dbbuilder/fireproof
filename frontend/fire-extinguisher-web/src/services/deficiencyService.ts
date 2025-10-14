import api from './api'
import type {
  InspectionDeficiencyDto,
  CreateDeficiencyRequest,
  UpdateDeficiencyRequest,
  ResolveDeficiencyRequest
} from '@/types/api'

/**
 * Deficiency Service
 * Manages inspection deficiencies and corrective actions
 * Supports assignment, tracking, and resolution workflow
 */
const deficiencyService = {
  /**
   * Create a new deficiency
   * @param deficiencyData - Deficiency creation data
   * @returns Promise resolving to created deficiency
   */
  async create(deficiencyData: CreateDeficiencyRequest): Promise<InspectionDeficiencyDto> {
    const response = await api.post<InspectionDeficiencyDto>('/deficiencies', deficiencyData)
    return response.data
  },

  /**
   * Get a specific deficiency by ID
   * @param deficiencyId - Deficiency UUID
   * @returns Promise resolving to deficiency details
   */
  async getById(deficiencyId: string): Promise<InspectionDeficiencyDto> {
    const response = await api.get<InspectionDeficiencyDto>(`/deficiencies/${deficiencyId}`)
    return response.data
  },

  /**
   * Update an existing deficiency
   * @param deficiencyId - Deficiency UUID
   * @param deficiencyData - Updated deficiency data
   * @returns Promise resolving to updated deficiency
   */
  async update(deficiencyId: string, deficiencyData: UpdateDeficiencyRequest): Promise<InspectionDeficiencyDto> {
    const response = await api.put<InspectionDeficiencyDto>(`/deficiencies/${deficiencyId}`, deficiencyData)
    return response.data
  },

  /**
   * Resolve a deficiency
   * @param deficiencyId - Deficiency UUID
   * @param resolutionData - Resolution notes
   * @returns Promise resolving to resolved deficiency
   */
  async resolve(deficiencyId: string, resolutionData: ResolveDeficiencyRequest): Promise<InspectionDeficiencyDto> {
    const response = await api.put<InspectionDeficiencyDto>(`/deficiencies/${deficiencyId}/resolve`, resolutionData)
    return response.data
  },

  /**
   * Delete a deficiency
   * @param deficiencyId - Deficiency UUID
   * @returns Promise resolving when delete is complete
   */
  async delete(deficiencyId: string): Promise<void> {
    await api.delete(`/deficiencies/${deficiencyId}`)
  },

  /**
   * Get all deficiencies for a specific inspection
   * @param inspectionId - Inspection UUID
   * @returns Promise resolving to array of deficiencies
   */
  async getByInspection(inspectionId: string): Promise<InspectionDeficiencyDto[]> {
    const response = await api.get<InspectionDeficiencyDto[]>(`/deficiencies/inspection/${inspectionId}`)
    return response.data
  },

  /**
   * Get open deficiencies (unresolved)
   * @param startDate - Optional start date (ISO 8601)
   * @param endDate - Optional end date (ISO 8601)
   * @returns Promise resolving to array of open deficiencies
   */
  async getOpen(startDate?: string | null, endDate?: string | null): Promise<InspectionDeficiencyDto[]> {
    const params: any = {}
    if (startDate) params.startDate = startDate
    if (endDate) params.endDate = endDate
    const response = await api.get<InspectionDeficiencyDto[]>('/deficiencies/open', { params })
    return response.data
  },

  /**
   * Get deficiencies by severity
   * @param severity - Critical, High, Medium, Low
   * @param startDate - Optional start date (ISO 8601)
   * @param endDate - Optional end date (ISO 8601)
   * @returns Promise resolving to array of deficiencies
   */
  async getBySeverity(
    severity: string,
    startDate?: string | null,
    endDate?: string | null
  ): Promise<InspectionDeficiencyDto[]> {
    const params: any = {}
    if (startDate) params.startDate = startDate
    if (endDate) params.endDate = endDate
    const response = await api.get<InspectionDeficiencyDto[]>(`/deficiencies/severity/${severity}`, { params })
    return response.data
  },

  /**
   * Get deficiencies assigned to a specific user
   * @param userId - User UUID
   * @param openOnly - Show only open deficiencies
   * @returns Promise resolving to array of assigned deficiencies
   */
  async getByAssignee(userId: string, openOnly: boolean = true): Promise<InspectionDeficiencyDto[]> {
    const params = { openOnly }
    const response = await api.get<InspectionDeficiencyDto[]>(`/deficiencies/assigned/${userId}`, { params })
    return response.data
  }
}

export default deficiencyService
