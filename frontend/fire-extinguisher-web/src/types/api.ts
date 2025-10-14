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

// ============================================================================
// Phase 1: Checklist Template Types (NFPA Compliance)
// ============================================================================

export interface ChecklistTemplateDto {
  templateId: string
  tenantId?: string | null
  templateName: string
  inspectionType: string // Monthly, Annual, 6-Year, 12-Year, Hydrostatic
  standard: string // NFPA 10, Title 19 CCR, ULC S508
  description?: string | null
  isSystemTemplate: boolean
  isActive: boolean
  createdDate: string
  modifiedDate: string
  items?: ChecklistItemDto[] | null
}

export interface ChecklistItemDto {
  itemId: string
  templateId: string
  itemNumber: number
  itemText: string
  itemCategory: string // PhysicalCondition, Signage, Gauge, etc.
  requiresPhoto: boolean
  requiresComment: boolean
  allowedResponses: string // JSON array: ["Pass", "Fail", "N/A"]
  sortOrder: number
  isRequired: boolean
  isActive: boolean
  createdDate: string
  modifiedDate: string
}

export interface CreateChecklistTemplateRequest {
  templateName: string
  inspectionType: string
  standard: string
  description?: string | null
}

export interface UpdateChecklistTemplateRequest {
  templateName: string
  description?: string | null
  isActive: boolean
}

export interface CreateChecklistItemsRequest {
  items: Array<{
    itemNumber: number
    itemText: string
    itemCategory: string
    requiresPhoto: boolean
    requiresComment: boolean
    allowedResponses: string
    sortOrder: number
    isRequired: boolean
  }>
}

// ============================================================================
// Phase 1: Inspection (Checklist-Based) Types
// ============================================================================

export interface InspectionPhase1Dto {
  inspectionId: string
  tenantId: string
  extinguisherId: string
  inspectorUserId: string
  templateId: string
  inspectionType: string
  inspectionDate: string
  scheduledDate?: string | null
  completedDate?: string | null
  status: string // Scheduled, InProgress, Completed, Failed, Cancelled
  latitude?: number | null
  longitude?: number | null
  gpsAccuracyMeters?: number | null
  locationVerified: boolean
  overallResult?: string | null // Pass, Fail, ConditionalPass
  notes?: string | null
  inspectionHash?: string | null
  previousInspectionHash?: string | null
  hashVerified: boolean
  inspectorSignature?: string | null
  createdDate: string
  modifiedDate: string
  // Navigation properties
  extinguisherCode?: string | null
  extinguisherAssetTag?: string | null
  locationName?: string | null
  inspectorName?: string | null
  templateName?: string | null
  // Related data (lazy loaded)
  checklistResponses?: InspectionChecklistResponseDto[] | null
  photos?: InspectionPhotoDto[] | null
  deficiencies?: InspectionDeficiencyDto[] | null
}

export interface CreateInspectionPhase1Request {
  extinguisherId: string
  inspectorUserId: string
  templateId: string
  inspectionType: string
  scheduledDate?: string | null
  latitude?: number | null
  longitude?: number | null
}

export interface UpdateInspectionPhase1Request {
  latitude?: number | null
  longitude?: number | null
  gpsAccuracyMeters?: number | null
  notes?: string | null
}

export interface CompleteInspectionRequest {
  overallResult: string // Pass, Fail, ConditionalPass
  notes?: string | null
  inspectorSignature?: string | null
}

export interface InspectionChecklistResponseDto {
  responseId: string
  inspectionId: string
  checklistItemId: string
  response: string // Pass, Fail, N/A
  comment?: string | null
  photoId?: string | null
  respondedDate: string
  // Navigation properties
  itemText?: string | null
  itemCategory?: string | null
}

export interface SaveChecklistResponsesRequest {
  responses: Array<{
    checklistItemId: string
    response: string
    comment?: string | null
    photoId?: string | null
  }>
}

export interface InspectionPhase1VerificationResponse {
  inspectionId: string
  isValid: boolean
  validationMessage?: string | null
  originalHash: string
  computedHash: string
  hashMatch: boolean
  previousHashMatch: boolean
  blockchainValid: boolean
  verifiedDate: string
}

export interface InspectionPhase1StatsDto {
  totalInspections: number
  completedInspections: number
  passedInspections: number
  failedInspections: number
  conditionalPassInspections: number
  inProgressInspections: number
  scheduledInspections: number
  passRate: number
  avgCompletionTimeMinutes: number
  inspectionsThisMonth: number
  inspectionsThisYear: number
  lastInspectionDate?: string | null
}

// ============================================================================
// Phase 1: Deficiency Types
// ============================================================================

export interface InspectionDeficiencyDto {
  deficiencyId: string
  inspectionId: string
  extinguisherId: string
  tenantId: string
  deficiencyType: string // MissingPin, DamagedHose, GaugeNotInGreen, etc.
  severity: string // Critical, High, Medium, Low
  description: string
  correctiveAction?: string | null
  assignedToUserId?: string | null
  dueDate?: string | null
  status: string // Open, InProgress, Resolved, Deferred
  resolutionNotes?: string | null
  resolvedDate?: string | null
  resolvedByUserId?: string | null
  photoIds?: string[] | null
  createdDate: string
  modifiedDate: string
  // Navigation properties
  extinguisherAssetTag?: string | null
  locationName?: string | null
  assignedToName?: string | null
  resolvedByName?: string | null
}

export interface CreateDeficiencyRequest {
  inspectionId: string
  extinguisherId: string
  deficiencyType: string
  severity: string
  description: string
  correctiveAction?: string | null
  assignedToUserId?: string | null
  dueDate?: string | null
  photoIds?: string[] | null
}

export interface UpdateDeficiencyRequest {
  deficiencyType: string
  severity: string
  description: string
  correctiveAction?: string | null
  assignedToUserId?: string | null
  dueDate?: string | null
  status: string
  photoIds?: string[] | null
}

export interface ResolveDeficiencyRequest {
  resolutionNotes: string
}

// ============================================================================
// Phase 1: Photo Types (Mobile-First)
// ============================================================================

export interface InspectionPhotoDto {
  photoId: string
  inspectionId: string
  tenantId: string
  photoType: string // Location, PhysicalCondition, Pressure, Label, Seal, Hose, Deficiency, Other
  blobUrl: string
  thumbnailUrl: string
  fileName: string
  fileSizeBytes: number
  contentType: string
  captureDate?: string | null
  latitude?: number | null
  longitude?: number | null
  deviceModel?: string | null
  deviceMake?: string | null
  exifExtracted: boolean
  createdDate: string
  modifiedDate: string
}

export interface PhotoUploadResponse {
  photoId: string
  photoUrl: string
  thumbnailUrl: string
  exifExtracted: boolean
  captureDate?: string | null
  latitude?: number | null
  longitude?: number | null
}

export interface UploadPhotoRequest {
  inspectionId: string
  photoType: string
  file: File
  captureDate?: string | null
}
