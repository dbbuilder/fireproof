import api from './api'
import type {
  LocationDto,
  CreateLocationRequest,
  UpdateLocationRequest,
  isLocationDto
} from '@/types/api'

/**
 * Location management service
 * Handles all location-related API calls with full TypeScript type safety
 */
const locationService = {
  /**
   * Get all locations for the current tenant
   * @param isActive - Optional filter by active status
   * @returns Promise resolving to array of locations
   */
  async getAll(isActive: boolean | null = null): Promise<LocationDto[]> {
    const params = isActive !== null ? { isActive } : {}
    const response = await api.get<LocationDto[]>('/locations', { params })
    return response.data
  },

  /**
   * Get a specific location by ID
   * @param locationId - Location UUID
   * @returns Promise resolving to location details
   */
  async getById(locationId: string): Promise<LocationDto> {
    const response = await api.get<LocationDto>(`/locations/${locationId}`)
    return response.data
  },

  /**
   * Create a new location
   * @param locationData - Location creation data
   * @returns Promise resolving to created location
   */
  async create(locationData: CreateLocationRequest): Promise<LocationDto> {
    const response = await api.post<LocationDto>('/locations', locationData)
    return response.data
  },

  /**
   * Update an existing location
   * @param locationId - Location UUID
   * @param locationData - Updated location data
   * @returns Promise resolving to updated location
   */
  async update(locationId: string, locationData: UpdateLocationRequest): Promise<LocationDto> {
    const response = await api.put<LocationDto>(`/locations/${locationId}`, locationData)
    return response.data
  },

  /**
   * Delete a location (soft delete)
   * @param locationId - Location UUID
   * @returns Promise resolving when delete is complete
   */
  async delete(locationId: string): Promise<void> {
    await api.delete(`/locations/${locationId}`)
  },

  /**
   * Generate a barcode for a location
   * @param locationId - Location UUID
   * @returns Promise resolving to barcode data URL
   */
  async generateBarcode(locationId: string): Promise<string> {
    const response = await api.post<{ barcodeData: string }>(`/locations/${locationId}/barcode`)
    return response.data.barcodeData
  }
}

export default locationService
