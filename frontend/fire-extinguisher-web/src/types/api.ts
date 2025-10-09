/**
 * API Type Definitions for FireProof
 * Provides TypeScript type safety for all API objects
 */

// ============================================================================
// Location Types
// ============================================================================

export interface LocationDto {
  locationId: string
  tenantId: string
  locationCode: string
  locationName: string
  addressLine1?: string | null
  addressLine2?: string | null
  city?: string | null
  stateProvince?: string | null
  postalCode?: string | null
  country?: string | null
  latitude?: number | null
  longitude?: number | null
  locationBarcodeData?: string | null
  isActive: boolean
  createdDate: string
  modifiedDate: string
}

export interface CreateLocationRequest {
  locationCode: string
  locationName: string
  addressLine1?: string | null
  addressLine2?: string | null
  city?: string | null
  stateProvince?: string | null
  postalCode?: string | null
  country?: string | null
  latitude?: number | null
  longitude?: number | null
}

export interface UpdateLocationRequest {
  locationName: string
  addressLine1?: string | null
  addressLine2?: string | null
  city?: string | null
  stateProvince?: string | null
  postalCode?: string | null
  country?: string | null
  latitude?: number | null
  longitude?: number | null
  isActive: boolean
}

// ============================================================================
// Extinguisher Type Types
// ============================================================================

export interface ExtinguisherTypeDto {
  extinguisherTypeId: string
  tenantId: string
  typeCode: string
  typeName: string
  description?: string | null
  agentType?: string | null
  capacity?: number | null
  capacityUnit?: string | null
  fireClassRating?: string | null
  serviceLifeYears?: number | null
  hydroTestIntervalYears?: number | null
  isActive: boolean
  createdDate: string
  modifiedDate: string
}

export interface CreateExtinguisherTypeRequest {
  typeCode: string
  typeName: string
  description?: string | null
  agentType?: string | null
  capacity?: number | null
  capacityUnit?: string | null
  fireClassRating?: string | null
  serviceLifeYears?: number | null
  hydroTestIntervalYears?: number | null
}

export interface UpdateExtinguisherTypeRequest {
  typeName: string
  description?: string | null
  agentType?: string | null
  capacity?: number | null
  capacityUnit?: string | null
  fireClassRating?: string | null
  serviceLifeYears?: number | null
  hydroTestIntervalYears?: number | null
  isActive: boolean
}

// ============================================================================
// Common Enums
// ============================================================================

export enum FireClass {
  A = 'A',
  B = 'B',
  C = 'C',
  D = 'D',
  K = 'K'
}

export enum AgentType {
  DryChemical = 'Dry Chemical',
  CO2 = 'CO2',
  Water = 'Water',
  Foam = 'Foam',
  CleanAgent = 'Clean Agent',
  WetChemical = 'Wet Chemical'
}

// ============================================================================
// API Response Types
// ============================================================================

export interface ApiError {
  message: string
  statusCode?: number
  errors?: Record<string, string[]>
}

export interface PaginatedResponse<T> {
  items: T[]
  totalCount: number
  pageNumber: number
  pageSize: number
  totalPages: number
}

// ============================================================================
// Type Guards
// ============================================================================

export function isLocationDto(obj: any): obj is LocationDto {
  return (
    obj &&
    typeof obj.locationId === 'string' &&
    typeof obj.locationCode === 'string' &&
    typeof obj.locationName === 'string' &&
    typeof obj.isActive === 'boolean'
  )
}

export function isExtinguisherTypeDto(obj: any): obj is ExtinguisherTypeDto {
  return (
    obj &&
    typeof obj.extinguisherTypeId === 'string' &&
    typeof obj.typeCode === 'string' &&
    typeof obj.typeName === 'string' &&
    typeof obj.isActive === 'boolean'
  )
}
