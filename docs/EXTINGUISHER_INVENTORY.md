# Extinguisher Inventory Management with Barcode Generation

## Overview

The extinguisher inventory management module provides comprehensive tracking of individual fire extinguishers with automatic barcode and QR code generation for asset identification and mobile scanning.

## Features

### Core Functionality
- **CRUD Operations**: Create, read, update, and delete fire extinguishers
- **Automatic Barcode Generation**: Code 128 barcodes and QR codes generated on creation
- **Asset Tracking**: Serial numbers, asset tags, manufacturer details
- **Location Management**: Track extinguisher placement within locations
- **Service Tracking**: Monitor service dates and hydro test schedules
- **Out of Service Management**: Mark units as out of service with reasons
- **Proactive Alerts**: Identify units needing service or hydro testing soon

### Barcode Implementation
- **Code 128 Barcodes**: Industry-standard linear barcodes for scanners
- **QR Codes**: 2D codes for mobile device scanning
- **Data URI Format**: Images encoded as base64 PNG for easy embedding
- **Unique Identifiers**: Barcodes based on extinguisher UUID (`FP-{guid}`)

## Backend Implementation

### DTOs

**ExtinguisherDto** - Full extinguisher details
```csharp
public class ExtinguisherDto
{
    public Guid ExtinguisherId { get; set; }
    public string ExtinguisherCode { get; set; }
    public string SerialNumber { get; set; }
    public string? AssetTag { get; set; }
    public string? Manufacturer { get; set; }
    public DateTime? ManufactureDate { get; set; }
    public DateTime? InstallDate { get; set; }
    public DateTime? LastServiceDate { get; set; }
    public DateTime? NextServiceDueDate { get; set; }
    public DateTime? LastHydroTestDate { get; set; }
    public DateTime? NextHydroTestDueDate { get; set; }
    public string? BarcodeData { get; set; }      // Base64 PNG
    public string? QrCodeData { get; set; }        // Base64 PNG
    public bool IsActive { get; set; }
    public bool IsOutOfService { get; set; }
    public string? OutOfServiceReason { get; set; }
    // ... more fields
}
```

**CreateExtinguisherRequest** - Creation payload
```csharp
public class CreateExtinguisherRequest
{
    public Guid LocationId { get; set; }
    public Guid ExtinguisherTypeId { get; set; }
    public string ExtinguisherCode { get; set; }
    public string SerialNumber { get; set; }
    // ... optional fields
}
```

**UpdateExtinguisherRequest** - Update payload
**BarcodeResponse** - Barcode generation response

### Services

**IExtinguisherService** - Main inventory service
- `CreateExtinguisherAsync()` - Create with automatic barcode generation
- `GetAllExtinguishersAsync()` - List with filtering (location, type, status)
- `GetExtinguisherByIdAsync()` - Get by UUID
- `GetExtinguisherByBarcodeAsync()` - Scan lookup
- `UpdateExtinguisherAsync()` - Update details
- `DeleteExtinguisherAsync()` - Soft delete
- `GenerateBarcodeAsync()` - Generate/regenerate barcodes
- `MarkOutOfServiceAsync()` - Take out of service
- `ReturnToServiceAsync()` - Return to service
- `GetExtinguishersNeedingServiceAsync()` - Service due soon
- `GetExtinguishersNeedingHydroTestAsync()` - Hydro test due soon

**IBarcodeGeneratorService** - Barcode/QR code generation
- `GenerateBarcode()` - Code 128 barcode as base64 PNG
- `GenerateQrCode()` - QR code as base64 PNG
- `GenerateBoth()` - Both formats
- `IsValidBarcodeData()` - Validation

**Implementation**: Uses BarcodeLib and QRCoder NuGet packages

### Controller

**ExtinguishersController** - RESTful API endpoints
- `POST /api/extinguishers` - Create extinguisher
- `GET /api/extinguishers` - List all (with filters)
- `GET /api/extinguishers/{id}` - Get by ID
- `GET /api/extinguishers/barcode/{barcodeData}` - Get by barcode scan
- `PUT /api/extinguishers/{id}` - Update
- `DELETE /api/extinguishers/{id}` - Delete
- `POST /api/extinguishers/{id}/barcode` - Generate/regenerate barcode
- `POST /api/extinguishers/{id}/outofservice` - Mark out of service
- `POST /api/extinguishers/{id}/returntoservice` - Return to service
- `GET /api/extinguishers/needingservice` - Get units needing service
- `GET /api/extinguishers/needinghydrotest` - Get units needing hydro test

### Database

Stored procedures already exist in `004_CreateTenantStoredProcedures.sql`:
- `usp_Extinguisher_Create`
- `usp_Extinguisher_GetAll`
- `usp_Extinguisher_GetById`
- `usp_Extinguisher_GetByBarcode`
- `usp_Extinguisher_Update`
- `usp_Extinguisher_Delete`
- `usp_Extinguisher_MarkOutOfService`
- `usp_Extinguisher_ReturnToService`
- `usp_Extinguisher_GetNeedingService`
- `usp_Extinguisher_GetNeedingHydroTest`

## Frontend Implementation

### TypeScript Types

**ExtinguisherDto** - Full extinguisher with navigation properties
```typescript
export interface ExtinguisherDto {
  extinguisherId: string
  extinguisherCode: string
  serialNumber: string
  barcodeData?: string | null      // Base64 PNG data URI
  qrCodeData?: string | null        // Base64 PNG data URI
  isActive: boolean
  isOutOfService: boolean
  locationName?: string | null       // From join
  typeName?: string | null           // From join
  // ... more fields
}
```

**CreateExtinguisherRequest** - Creation payload
**UpdateExtinguisherRequest** - Update payload
**BarcodeResponse** - Barcode generation response

### Service

**extinguisherService.ts** - API client
```typescript
const extinguisherService = {
  async getAll(filters?: ExtinguisherFilters): Promise<ExtinguisherDto[]>
  async getById(extinguisherId: string): Promise<ExtinguisherDto>
  async getByBarcode(barcodeData: string): Promise<ExtinguisherDto>
  async create(data: CreateExtinguisherRequest): Promise<ExtinguisherDto>
  async update(id: string, data: UpdateExtinguisherRequest): Promise<ExtinguisherDto>
  async delete(extinguisherId: string): Promise<void>
  async generateBarcode(extinguisherId: string): Promise<BarcodeResponse>
  async markOutOfService(id: string, reason: string): Promise<ExtinguisherDto>
  async returnToService(extinguisherId: string): Promise<ExtinguisherDto>
  async getNeedingService(daysAhead?: number): Promise<ExtinguisherDto[]>
  async getNeedingHydroTest(daysAhead?: number): Promise<ExtinguisherDto[]>
}
```

### Store

**extinguishers.ts** - Pinia state management
```typescript
export const useExtinguisherStore = defineStore('extinguishers', {
  state: () => ({
    extinguishers: ExtinguisherDto[]
    currentExtinguisher: ExtinguisherDto | null
    loading: boolean
    error: string | null
  }),

  getters: {
    activeExtinguishers()           // Active, in-service units
    outOfServiceExtinguishers()     // Out of service units
    extinguishersByLocation()       // Grouped by location
    extinguishersByType()           // Grouped by type
    needingAttention()              // Service/hydro test due within 30 days
  },

  actions: {
    // All CRUD operations with local state updates
  }
})
```

## Barcode Workflow

1. **Creation**: Extinguisher created → UUID generated → Barcode/QR code generated → Saved to database
2. **Format**: `FP-{guid}` (e.g., `FP-a1b2c3d4e5f6...`)
3. **Storage**: Base64-encoded PNG images stored as data URIs
4. **Display**: Can be rendered directly in `<img>` tags
5. **Scanning**: Mobile devices scan → Lookup by barcode → Display extinguisher details
6. **Regeneration**: Barcodes can be regenerated if needed

## NuGet Packages

```xml
<PackageReference Include="QRCoder" Version="1.7.0" />
<PackageReference Include="BarcodeLib" Version="3.1.5" />
<PackageReference Include="System.Drawing.Common" Version="9.0.9" />
```

## Usage Examples

### Backend - Create Extinguisher with Barcode
```csharp
var request = new CreateExtinguisherRequest
{
    LocationId = locationId,
    ExtinguisherTypeId = typeId,
    ExtinguisherCode = "FE-101",
    SerialNumber = "SN123456",
    Manufacturer = "Ansul",
    InstallDate = DateTime.UtcNow
};

var extinguisher = await extinguisherService.CreateExtinguisherAsync(tenantId, request);
// extinguisher.BarcodeData contains base64 PNG barcode
// extinguisher.QrCodeData contains base64 PNG QR code
```

### Frontend - Display Barcode
```vue
<template>
  <div v-if="extinguisher">
    <h2>{{ extinguisher.extinguisherCode }}</h2>
    <img :src="extinguisher.barcodeData" alt="Barcode" />
    <img :src="extinguisher.qrCodeData" alt="QR Code" />
  </div>
</template>

<script setup>
const extinguisherStore = useExtinguisherStore()
const extinguisher = ref(null)

onMounted(async () => {
  extinguisher.value = await extinguisherStore.fetchExtinguisherById(extinguisherId)
})
</script>
```

### Frontend - Scan and Lookup
```typescript
// After scanning barcode (e.g., "FP-a1b2c3d4...")
const extinguisher = await extinguisherStore.fetchExtinguisherByBarcode(scannedData)
```

## Service Tracking

### Automatic Due Date Calculation
When service is performed, next service due date is automatically calculated based on:
- NFPA 10 standards (typically monthly or annual inspections)
- Extinguisher type specifications
- Local jurisdiction requirements

### Hydro Test Tracking
Hydrostatic testing schedules tracked based on:
- Extinguisher type hydro test interval
- Last hydro test date
- Regulatory requirements (typically 5-12 years depending on type)

### Proactive Notifications
System identifies units needing attention:
- Service due within configurable window (default 30 days)
- Hydro test due within configurable window (default 30 days)
- Overdue units flagged for immediate attention

## Multi-Tenant Support

All operations are tenant-scoped:
- Tenant context resolved from JWT claims
- Database operations use tenant-specific schema
- Barcodes globally unique but scoped to tenant
- No cross-tenant data leakage

## Security Considerations

- All endpoints require authentication (when auth is enabled)
- Tenant isolation enforced at database level
- Barcode data validated before generation
- SQL injection prevented via parameterized stored procedures
- XSS prevention via proper encoding of user inputs

## Future Enhancements

- [ ] Batch barcode generation and printing
- [ ] Label templates for various printer formats
- [ ] Mobile barcode scanning app integration
- [ ] NFC tag support for additional identification
- [ ] Automated service scheduling based on due dates
- [ ] Email/SMS notifications for overdue services
- [ ] Photo attachments for damage documentation
- [ ] Bluetooth proximity beacons for location verification
- [ ] Integration with inspection workflow for automatic service date updates
