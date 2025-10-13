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
// Extinguisher Types
// ============================================================================

export interface ExtinguisherDto {
  extinguisherId: string
  tenantId: string
  locationId: string
  extinguisherTypeId: string
  extinguisherCode: string
  serialNumber: string
  assetTag?: string | null
  manufacturer?: string | null
  manufactureDate?: string | null
  installDate?: string | null
  lastServiceDate?: string | null
  nextServiceDueDate?: string | null
  lastHydroTestDate?: string | null
  nextHydroTestDueDate?: string | null
  locationDescription?: string | null
  floorLevel?: string | null
  notes?: string | null
  barcodeData?: string | null
  qrCodeData?: string | null
  isActive: boolean
  isOutOfService: boolean
  outOfServiceReason?: string | null
  createdDate: string
  modifiedDate: string
  // Navigation properties
  locationName?: string | null
  typeName?: string | null
  typeCode?: string | null
}

export interface CreateExtinguisherRequest {
  locationId: string
  extinguisherTypeId: string
  extinguisherCode: string
  serialNumber: string
  assetTag?: string | null
  manufacturer?: string | null
  manufactureDate?: string | null
  installDate?: string | null
  locationDescription?: string | null
  floorLevel?: string | null
  notes?: string | null
}

export interface UpdateExtinguisherRequest {
  locationId: string
  extinguisherTypeId: string
  serialNumber: string
  assetTag?: string | null
  manufacturer?: string | null
  manufactureDate?: string | null
  installDate?: string | null
  lastServiceDate?: string | null
  nextServiceDueDate?: string | null
  lastHydroTestDate?: string | null
  nextHydroTestDueDate?: string | null
  locationDescription?: string | null
  floorLevel?: string | null
  notes?: string | null
  isActive: boolean
  isOutOfService: boolean
  outOfServiceReason?: string | null
}

export interface BarcodeResponse {
  barcodeData: string
  qrCodeData: string
  format: string
}

// ============================================================================
// Inspection Types
// ============================================================================

export interface InspectionDto {
  inspectionId: string
  tenantId: string
  extinguisherId: string
  inspectorUserId: string
  inspectionDate: string
  inspectionType: string // Monthly, Annual, 5-Year, 12-Year
  gpsLatitude?: number | null
  gpsLongitude?: number | null
  gpsAccuracyMeters?: number | null
  locationVerified: boolean
  isAccessible: boolean
  hasObstructions: boolean
  signageVisible: boolean
  sealIntact: boolean
  pinInPlace: boolean
  nozzleClear: boolean
  hoseConditionGood: boolean
  gaugeInGreenZone: boolean
  gaugePressurePsi?: number | null
  physicalDamagePresent: boolean
  damageDescription?: string | null
  weightPounds?: number | null
  weightWithinSpec: boolean
  inspectionTagAttached: boolean
  previousInspectionDate?: string | null
  notes?: string | null
  passed: boolean
  requiresService: boolean
  requiresReplacement: boolean
  failureReason?: string | null
  correctiveAction?: string | null
  photoUrls?: string[] | null
  dataHash: string
  inspectorSignature: string
  signedDate: string
  isVerified: boolean
  createdDate: string
  modifiedDate: string
  // Navigation properties
  extinguisherCode?: string | null
  inspectorName?: string | null
  locationName?: string | null
}

export interface CreateInspectionRequest {
  extinguisherId: string
  inspectorUserId: string
  inspectionDate: string
  inspectionType: string
  gpsLatitude?: number | null
  gpsLongitude?: number | null
  gpsAccuracyMeters?: number | null
  isAccessible: boolean
  hasObstructions: boolean
  signageVisible: boolean
  sealIntact: boolean
  pinInPlace: boolean
  nozzleClear: boolean
  hoseConditionGood: boolean
  gaugeInGreenZone: boolean
  gaugePressurePsi?: number | null
  physicalDamagePresent: boolean
  damageDescription?: string | null
  weightPounds?: number | null
  inspectionTagAttached: boolean
  previousInspectionDate?: string | null
  notes?: string | null
  requiresService: boolean
  requiresReplacement: boolean
  failureReason?: string | null
  correctiveAction?: string | null
  photoUrls?: string[] | null
}

export interface InspectionVerificationResponse {
  inspectionId: string
  isValid: boolean
  validationMessage?: string | null
  originalHash: string
  computedHash: string
  hashMatch: boolean
  verifiedDate: string
}

export interface InspectionStatsDto {
  totalInspections: number
  passedInspections: number
  failedInspections: number
  requireingService: number
  requiringReplacement: number
  passRate: number
  lastInspectionDate?: string | null
  inspectionsThisMonth: number
  inspectionsThisYear: number
}

// ============================================================================
// Authentication Types
// ============================================================================

export interface RegisterRequest {
  email: string
  password: string
  firstName: string
  lastName: string
  phoneNumber?: string | null
  tenantId?: string | null
  tenantRole?: string | null
}

export interface LoginRequest {
  email: string
  password: string
}

export interface DevLoginRequest {
  email: string
}

export interface RefreshTokenRequest {
  refreshToken: string
}

export interface AuthenticationResponse {
  accessToken: string
  refreshToken: string
  expiresAt: string
  user: UserDto
  roles: RoleDto[]
}

export interface UserDto {
  userId: string
  email: string
  firstName: string
  lastName: string
  phoneNumber?: string | null
  emailConfirmed: boolean
  mfaEnabled: boolean
  lastLoginDate?: string | null
  isActive: boolean
  createdDate: string
  modifiedDate: string
}

export interface RoleDto {
  roleType: string // "System" or "Tenant"
  tenantId?: string | null
  roleName: string
  description?: string | null
  isActive: boolean
}

export interface ResetPasswordRequest {
  userId: string
  currentPassword: string
  newPassword: string
}

export interface ConfirmEmailRequest {
  userId: string
  confirmationToken: string
}

export interface AssignUserToTenantRequest {
  userId: string
  tenantId: string
  roleName: string
}

// ============================================================================
// Tenant Types
// ============================================================================

export interface TenantDto {
  tenantId: string
  tenantName: string
  tenantCode: string
  contactName?: string | null
  contactEmail?: string | null
  contactPhone?: string | null
  addressLine1?: string | null
  addressLine2?: string | null
  city?: string | null
  stateProvince?: string | null
  postalCode?: string | null
  country?: string | null
  subscriptionTier?: string | null
  subscriptionStartDate?: string | null
  subscriptionEndDate?: string | null
  maxUsers?: number | null
  maxLocations?: number | null
  isActive: boolean
  createdDate: string
  modifiedDate: string
}

export interface CreateTenantRequest {
  tenantName: string
  tenantCode: string
  contactName?: string | null
  contactEmail?: string | null
  contactPhone?: string | null
  addressLine1?: string | null
  addressLine2?: string | null
  city?: string | null
  stateProvince?: string | null
  postalCode?: string | null
  country?: string | null
  subscriptionTier?: string | null
  maxUsers?: number | null
  maxLocations?: number | null
}

export interface UpdateTenantRequest {
  tenantName: string
  contactName?: string | null
  contactEmail?: string | null
  contactPhone?: string | null
  addressLine1?: string | null
  addressLine2?: string | null
  city?: string | null
  stateProvince?: string | null
  postalCode?: string | null
  country?: string | null
  subscriptionTier?: string | null
  maxUsers?: number | null
  maxLocations?: number | null
  isActive: boolean
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

export function isExtinguisherDto(obj: any): obj is ExtinguisherDto {
  return (
    obj &&
    typeof obj.extinguisherId === 'string' &&
    typeof obj.extinguisherCode === 'string' &&
    typeof obj.serialNumber === 'string' &&
    typeof obj.isActive === 'boolean' &&
    typeof obj.isOutOfService === 'boolean'
  )
}
