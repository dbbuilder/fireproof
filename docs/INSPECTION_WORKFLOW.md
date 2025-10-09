# Inspection Workflow with Tamper-Proofing

## Overview

The inspection workflow provides comprehensive fire extinguisher inspection management with cryptographic tamper-proofing to ensure data integrity and regulatory compliance. All inspection records are secured with SHA-256 hashing and HMAC-based digital signatures.

## Key Features

### Tamper-Proof Records
- **SHA-256 Hashing**: All inspection data hashed for integrity verification
- **HMAC Digital Signatures**: Inspector signatures using HMAC-SHA256
- **Immutable Records**: Modifications detectable through hash verification
- **Audit Trail**: Complete history with cryptographic proof
- **Regulatory Compliance**: Meet NFPA 10 and local code requirements

### Comprehensive Inspections
- **Multiple Inspection Types**: Monthly, Annual, 5-Year, 12-Year
- **GPS Location Verification**: Verify extinguisher is at correct location
- **Physical Condition Checks**: 10+ critical inspection points
- **Photo Evidence**: Attach photos for documentation
- **Pass/Fail Determination**: Automatic based on critical checks
- **Service Recommendations**: Flag units needing service or replacement

### Inspection Types

#### Monthly Inspections
- Visual inspection
- Accessibility check
- Signage verification
- Seal and pin integrity
- Gauge pressure check

#### Annual Inspections
- All monthly checks
- Hose condition
- Nozzle clarity
- Weight verification
- Tag documentation

#### 5-Year Inspections
- Internal examination
- Hose testing
- Comprehensive documentation

#### 12-Year Hydrostatic Testing
- Pressure testing
- Valve inspection
- Complete overhaul if required

## Backend Implementation

### DTOs

**InspectionDto** - Complete inspection record
```csharp
public class InspectionDto
{
    public Guid InspectionId { get; set; }
    public Guid ExtinguisherId { get; set; }
    public Guid InspectorUserId { get; set; }
    public DateTime InspectionDate { get; set; }
    public string InspectionType { get; set; }

    // GPS verification
    public decimal? GpsLatitude { get; set; }
    public decimal? GpsLongitude { get; set; }
    public bool LocationVerified { get; set; }

    // Critical checks
    public bool IsAccessible { get; set; }
    public bool SealIntact { get; set; }
    public bool PinInPlace { get; set; }
    public bool GaugeInGreenZone { get; set; }
    // ... 10+ more checks

    // Results
    public bool Passed { get; set; }
    public bool RequiresService { get; set; }
    public string? FailureReason { get; set; }

    // Tamper-proofing
    public string DataHash { get; set; }           // SHA-256 hash
    public string InspectorSignature { get; set; }  // HMAC signature
    public DateTime SignedDate { get; set; }
    public bool IsVerified { get; set; }
}
```

**CreateInspectionRequest** - Inspection submission
**InspectionVerificationResponse** - Integrity verification results
**InspectionStatsDto** - Reporting statistics

### Tamper-Proofing Service

**ITamperProofingService** - Cryptographic operations
```csharp
public interface ITamperProofingService
{
    string ComputeInspectionHash(object inspectionData);
    bool VerifyInspectionIntegrity(object inspectionData, string storedHash);
    string CreateInspectorSignature(Guid inspectorUserId, string inspectionHash, DateTime timestamp);
    bool VerifyInspectorSignature(string signature, Guid inspectorUserId, string inspectionHash, DateTime timestamp);
}
```

**Implementation Details**:
- Uses SHA-256 for data hashing
- HMAC-SHA256 for digital signatures
- JSON serialization for consistent hashing
- Key stored in configuration (Azure Key Vault in production)

**Hash Calculation**:
1. Create `InspectionHashData` object (excludes IDs, timestamps, hash itself)
2. Serialize to JSON with consistent formatting
3. Compute SHA-256 hash
4. Return as hexadecimal string

**Signature Creation**:
1. Combine inspector ID, hash, and timestamp
2. Compute HMAC-SHA256 with secret key
3. Return as base64 string

### Inspection Service

**IInspectionService** - Main inspection operations
```csharp
public interface IInspectionService
{
    Task<InspectionDto> CreateInspectionAsync(Guid tenantId, CreateInspectionRequest request);
    Task<IEnumerable<InspectionDto>> GetAllInspectionsAsync(...filters);
    Task<InspectionDto?> GetInspectionByIdAsync(Guid tenantId, Guid inspectionId);
    Task<IEnumerable<InspectionDto>> GetExtinguisherInspectionHistoryAsync(Guid tenantId, Guid extinguisherId);
    Task<InspectionVerificationResponse> VerifyInspectionIntegrityAsync(Guid tenantId, Guid inspectionId);
    Task<InspectionStatsDto> GetInspectionStatsAsync(...);
    Task<IEnumerable<InspectionDto>> GetOverdueInspectionsAsync(...);
}
```

**Pass/Fail Logic**:
Inspection automatically passes if ALL critical checks pass:
- IsAccessible
- !HasObstructions
- SignageVisible
- SealIntact
- PinInPlace
- NozzleClear
- HoseConditionGood
- GaugeInGreenZone
- !PhysicalDamagePresent
- InspectionTagAttached

### Controller

**InspectionsController** - RESTful API endpoints
- `POST /api/inspections` - Create tamper-proof inspection
- `GET /api/inspections` - List all (with filters)
- `GET /api/inspections/{id}` - Get by ID
- `GET /api/inspections/extinguisher/{id}` - Get history for extinguisher
- `GET /api/inspections/inspector/{id}` - Get inspector's inspections
- `POST /api/inspections/{id}/verify` - Verify integrity
- `GET /api/inspections/stats` - Get statistics
- `GET /api/inspections/overdue` - Get overdue inspections
- `DELETE /api/inspections/{id}` - Delete (soft delete)

## Frontend Implementation

### TypeScript Types

```typescript
export interface InspectionDto {
  inspectionId: string
  extinguisherId: string
  inspectorUserId: string
  inspectionDate: string
  inspectionType: string

  // GPS verification
  gpsLatitude?: number | null
  gpsLongitude?: number | null
  locationVerified: boolean

  // Critical checks (10+ boolean fields)
  isAccessible: boolean
  sealIntact: boolean
  gaugeInGreenZone: boolean
  // ...

  // Results
  passed: boolean
  requiresService: boolean
  requiresReplacement: boolean

  // Tamper-proofing
  dataHash: string
  inspectorSignature: string
  signedDate: string
  isVerified: boolean
}
```

### Service

**inspectionService.ts** - API client
```typescript
const inspectionService = {
  async create(data: CreateInspectionRequest): Promise<InspectionDto>
  async getAll(filters?: InspectionFilters): Promise<InspectionDto[]>
  async getById(inspectionId: string): Promise<InspectionDto>
  async getExtinguisherHistory(extinguisherId: string): Promise<InspectionDto[]>
  async verifyIntegrity(inspectionId: string): Promise<InspectionVerificationResponse>
  async getStats(startDate?, endDate?): Promise<InspectionStatsDto>
  async getOverdue(inspectionType?): Promise<InspectionDto[]>
  async delete(inspectionId: string): Promise<void>
}
```

### Store

**inspections.ts** - Pinia state management
```typescript
export const useInspectionStore = defineStore('inspections', {
  state: () => ({
    inspections: InspectionDto[]
    currentInspection: InspectionDto | null
    stats: InspectionStatsDto | null
    loading: boolean
    error: string | null
  }),

  getters: {
    passedInspections()
    failedInspections()
    inspectionsRequiringService()
    inspectionsByExtinguisher()
    inspectionsByInspector()
    recentInspections()
    passRatePercentage()
  },

  actions: {
    // All CRUD operations with integrity verification
  }
})
```

## Tamper-Proofing Workflow

### Creating an Inspection

1. **Inspector performs inspection** - Collects all check data
2. **GPS coordinates captured** - Verifies location (if available)
3. **Pass/fail determined** - Based on critical checks
4. **Hash computed** - SHA-256 hash of all inspection data
5. **Signature created** - HMAC signature with inspector ID, hash, timestamp
6. **Record saved** - Inspection stored with hash and signature
7. **Immutable** - Any modifications will break hash verification

### Verifying an Inspection

1. **Retrieve inspection** - Get record from database
2. **Recreate hash data** - Extract inspection fields
3. **Compute new hash** - SHA-256 of current data
4. **Compare hashes** - Match against stored hash
5. **Verify signature** - Recompute HMAC and compare
6. **Return result** - Valid if both hash and signature match

### Verification Response

```typescript
interface InspectionVerificationResponse {
  inspectionId: string
  isValid: boolean                    // Overall result
  validationMessage: string
  originalHash: string                // Stored hash
  computedHash: string                // Newly computed hash
  hashMatch: boolean                  // Do they match?
  verifiedDate: string
}
```

## Usage Examples

### Backend - Create Tamper-Proof Inspection

```csharp
var request = new CreateInspectionRequest
{
    ExtinguisherId = extinguisherId,
    InspectorUserId = inspectorId,
    InspectionDate = DateTime.UtcNow,
    InspectionType = "Monthly",
    GpsLatitude = 40.7128m,
    GpsLongitude = -74.0060m,
    IsAccessible = true,
    SealIntact = true,
    GaugeInGreenZone = true,
    // ... all other checks
};

var inspection = await inspectionService.CreateInspectionAsync(tenantId, request);
// inspection.DataHash contains SHA-256 hash
// inspection.InspectorSignature contains HMAC signature
// inspection.IsVerified = true initially
```

### Backend - Verify Inspection Integrity

```csharp
var verification = await inspectionService.VerifyInspectionIntegrityAsync(tenantId, inspectionId);

if (verification.IsValid)
{
    // Inspection has not been tampered with
    Console.WriteLine("Inspection is valid and tamper-proof");
}
else
{
    // Inspection has been modified
    Console.WriteLine($"Tampering detected: {verification.ValidationMessage}");
    Console.WriteLine($"Original hash: {verification.OriginalHash}");
    Console.WriteLine($"Computed hash: {verification.ComputedHash}");
}
```

### Frontend - Perform Inspection

```vue
<script setup>
import { useInspectionStore } from '@/stores/inspections'

const inspectionStore = useInspectionStore()

const performInspection = async () => {
  const inspectionData = {
    extinguisherId: currentExtinguisher.value.extinguisherId,
    inspectorUserId: currentUser.value.userId,
    inspectionDate: new Date().toISOString(),
    inspectionType: 'Monthly',
    gpsLatitude: position.coords.latitude,
    gpsLongitude: position.coords.longitude,
    isAccessible: form.isAccessible,
    sealIntact: form.sealIntact,
    gaugeInGreenZone: form.gaugeInGreenZone,
    // ... all other checks from form
  }

  const inspection = await inspectionStore.createInspection(inspectionData)

  // Inspection now has tamper-proof hash and signature
  console.log('Hash:', inspection.dataHash)
  console.log('Signature:', inspection.inspectorSignature)
}
</script>
```

### Frontend - Verify Inspection

```typescript
const verifyInspection = async (inspectionId: string) => {
  const verification = await inspectionStore.verifyInspectionIntegrity(inspectionId)

  if (verification.isValid) {
    showSuccess('Inspection is valid and has not been tampered with')
  } else {
    showWarning(`Tampering detected: ${verification.validationMessage}`)
  }
}
```

## Security Considerations

### Hash Security
- **SHA-256**: Industry-standard cryptographic hash function
- **Collision Resistant**: Computationally infeasible to find two inputs with same hash
- **One-Way**: Cannot reverse hash to get original data
- **Deterministic**: Same input always produces same hash

### Signature Security
- **HMAC-SHA256**: Message authentication code
- **Secret Key**: Stored securely (Azure Key Vault in production)
- **Timestamp Included**: Prevents replay attacks
- **Inspector Binding**: Ties signature to specific inspector

### Key Management
- Development: Placeholder key in appsettings.json
- Production: Azure Key Vault for secret storage
- Key Rotation: Support for periodic key changes
- Access Control**: Only authorized services can sign

### Tamper Detection
- **Hash Mismatch**: Any field modification detected
- **Signature Invalid**: Unauthorized changes caught
- **Audit Logging**: All verification attempts logged
- **Immutable Records**: Original hash always preserved

## Regulatory Compliance

### NFPA 10 Requirements
- **Monthly Inspections**: Visual checks, location verification
- **Annual Inspections**: Comprehensive examination
- **6-Year Maintenance**: Internal examination
- **12-Year Hydrostatic Test**: Pressure testing
- **Documentation**: Complete records with signatures

### Tamper-Proofing Benefits
- **Legal Admissibility**: Cryptographic proof of authenticity
- **Auditor Confidence**: Verifiable inspection history
- **Liability Protection**: Proof inspections were performed correctly
- **Dispute Resolution**: Immutable records settle disagreements

## Database

Stored procedures in `004_CreateTenantStoredProcedures.sql`:
- `usp_Inspection_Create`
- `usp_Inspection_GetAll`
- `usp_Inspection_GetById`
- `usp_Inspection_GetStats`
- `usp_Inspection_GetOverdue`
- `usp_Inspection_Delete`

## Future Enhancements

- [ ] Offline inspection with deferred signing
- [ ] Blockchain anchoring for additional verification
- [ ] AI-powered photo analysis for damage detection
- [ ] Mobile app with camera integration
- [ ] Biometric inspector authentication
- [ ] NFC tag reading for automatic extinguisher identification
- [ ] Weather data correlation
- [ ] Automated compliance reporting
- [ ] Third-party audit API
- [ ] Certificate generation for completed inspections
