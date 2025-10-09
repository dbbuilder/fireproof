import api from './api'
import type {
  ExtinguisherDto,
  CreateExtinguisherRequest,
  UpdateExtinguisherRequest,
  BarcodeResponse
} from '@/types/api'

/**
 * Extinguisher inventory management service
 * Handles all fire extinguisher-related API calls with full TypeScript type safety
 */
const extinguisherService = {
  /**
   * Get all extinguishers with optional filtering
   * @param filters - Optional filters for location, type, active status, out of service status
   * @returns Promise resolving to array of extinguishers
   */
  async getAll(filters?: {
    locationId?: string
    typeId?: string
    isActive?: boolean
    isOutOfService?: boolean
  }): Promise<ExtinguisherDto[]> {
    const params = filters || {}
    const response = await api.get<ExtinguisherDto[]>('/extinguishers', { params })
    return response.data
  },

  /**
   * Get a specific extinguisher by ID
   * @param extinguisherId - Extinguisher UUID
   * @returns Promise resolving to extinguisher details
   */
  async getById(extinguisherId: string): Promise<ExtinguisherDto> {
    const response = await api.get<ExtinguisherDto>(`/extinguishers/${extinguisherId}`)
    return response.data
  },

  /**
   * Get extinguisher by barcode
   * @param barcodeData - Barcode data string
   * @returns Promise resolving to extinguisher details
   */
  async getByBarcode(barcodeData: string): Promise<ExtinguisherDto> {
    const response = await api.get<ExtinguisherDto>(`/extinguishers/barcode/${encodeURIComponent(barcodeData)}`)
    return response.data
  },

  /**
   * Create a new extinguisher
   * @param extinguisherData - Extinguisher creation data
   * @returns Promise resolving to created extinguisher with barcode
   */
  async create(extinguisherData: CreateExtinguisherRequest): Promise<ExtinguisherDto> {
    const response = await api.post<ExtinguisherDto>('/extinguishers', extinguisherData)
    return response.data
  },

  /**
   * Update an existing extinguisher
   * @param extinguisherId - Extinguisher UUID
   * @param extinguisherData - Updated extinguisher data
   * @returns Promise resolving to updated extinguisher
   */
  async update(extinguisherId: string, extinguisherData: UpdateExtinguisherRequest): Promise<ExtinguisherDto> {
    const response = await api.put<ExtinguisherDto>(`/extinguishers/${extinguisherId}`, extinguisherData)
    return response.data
  },

  /**
   * Delete an extinguisher
   * @param extinguisherId - Extinguisher UUID
   * @returns Promise resolving when delete is complete
   */
  async delete(extinguisherId: string): Promise<void> {
    await api.delete(`/extinguishers/${extinguisherId}`)
  },

  /**
   * Generate or regenerate barcode for an extinguisher
   * @param extinguisherId - Extinguisher UUID
   * @returns Promise resolving to barcode response with both barcode and QR code
   */
  async generateBarcode(extinguisherId: string): Promise<BarcodeResponse> {
    const response = await api.post<BarcodeResponse>(`/extinguishers/${extinguisherId}/barcode`)
    return response.data
  },

  /**
   * Mark extinguisher as out of service
   * @param extinguisherId - Extinguisher UUID
   * @param reason - Reason for being out of service
   * @returns Promise resolving to updated extinguisher
   */
  async markOutOfService(extinguisherId: string, reason: string): Promise<ExtinguisherDto> {
    const response = await api.post<ExtinguisherDto>(`/extinguishers/${extinguisherId}/outofservice`, { reason })
    return response.data
  },

  /**
   * Return extinguisher to service
   * @param extinguisherId - Extinguisher UUID
   * @returns Promise resolving to updated extinguisher
   */
  async returnToService(extinguisherId: string): Promise<ExtinguisherDto> {
    const response = await api.post<ExtinguisherDto>(`/extinguishers/${extinguisherId}/returntoservice`)
    return response.data
  },

  /**
   * Get extinguishers needing service soon
   * @param daysAhead - Number of days to look ahead (default: 30)
   * @returns Promise resolving to array of extinguishers needing service
   */
  async getNeedingService(daysAhead: number = 30): Promise<ExtinguisherDto[]> {
    const response = await api.get<ExtinguisherDto[]>('/extinguishers/needingservice', {
      params: { daysAhead }
    })
    return response.data
  },

  /**
   * Get extinguishers needing hydro test soon
   * @param daysAhead - Number of days to look ahead (default: 30)
   * @returns Promise resolving to array of extinguishers needing hydro test
   */
  async getNeedingHydroTest(daysAhead: number = 30): Promise<ExtinguisherDto[]> {
    const response = await api.get<ExtinguisherDto[]>('/extinguishers/needinghydrotest', {
      params: { daysAhead }
    })
    return response.data
  }
}

export default extinguisherService
