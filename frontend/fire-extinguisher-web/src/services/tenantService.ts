import api from './api'
import type {
  TenantDto,
  CreateTenantRequest,
  UpdateTenantRequest
} from '@/types/api'

/**
 * Tenant management service
 * Handles all tenant-related API calls with full TypeScript type safety
 */
const tenantService = {
  /**
   * Get all tenants (SystemAdmin only)
   * @returns Promise resolving to array of all tenants
   */
  async getAll(): Promise<TenantDto[]> {
    const response = await api.get<TenantDto[]>('/tenants')
    return response.data
  },

  /**
   * Get tenants available to the current user
   * - SystemAdmin: Returns all tenants
   * - Multi-tenant users: Returns tenants they have access to
   * - Single-tenant users: Returns their tenant
   * @returns Promise resolving to array of available tenants
   */
  async getAvailable(): Promise<TenantDto[]> {
    const response = await api.get<TenantDto[]>('/tenants/available')
    return response.data
  },

  /**
   * Get a specific tenant by ID
   * @param tenantId - Tenant UUID
   * @returns Promise resolving to tenant details
   */
  async getById(tenantId: string): Promise<TenantDto> {
    const response = await api.get<TenantDto>(`/tenants/${tenantId}`)
    return response.data
  },

  /**
   * Create a new tenant (SystemAdmin only)
   * @param tenantData - Tenant creation data
   * @returns Promise resolving to created tenant
   */
  async create(tenantData: CreateTenantRequest): Promise<TenantDto> {
    const response = await api.post<TenantDto>('/tenants', tenantData)
    return response.data
  },

  /**
   * Update an existing tenant (SystemAdmin only)
   * @param tenantId - Tenant UUID
   * @param tenantData - Updated tenant data
   * @returns Promise resolving to updated tenant
   */
  async update(tenantId: string, tenantData: UpdateTenantRequest): Promise<TenantDto> {
    const response = await api.put<TenantDto>(`/tenants/${tenantId}`, tenantData)
    return response.data
  }
}

export default tenantService
