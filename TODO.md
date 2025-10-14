# FireProof - Comprehensive Development Roadmap

**Last Updated:** October 14, 2025
**Version:** 2.0 - Competitive Feature Parity + AI Differentiation
**Status:** Phase 1 Foundation Complete, Moving to MVP

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Competitive Landscape](#competitive-landscape)
3. [Completed Work](#completed-work)
4. [Phase 1: MVP - Core Inspection (Weeks 1-4)](#phase-1-mvp---core-inspection-weeks-1-4)
5. [Phase 2: Business Features (Weeks 5-8)](#phase-2-business-features-weeks-5-8)
6. [Phase 3: AI & Native Apps (Weeks 9-16)](#phase-3-ai--native-apps-weeks-9-16)
7. [Phase 4: Enterprise (Weeks 17-24)](#phase-4-enterprise-weeks-17-24)
8. [Pricing Strategy](#pricing-strategy)
9. [Success Metrics](#success-metrics)

---

## Executive Summary

FireProof is a multi-tenant fire extinguisher inspection SaaS platform designed to **match or exceed all major competitors** while introducing **AI-powered features** that don't exist in the market.

**Current Status:**
- ✅ Database foundation complete (multi-tenant, DEMO001 seeded)
- ✅ Backend API skeleton (authentication, CRUD operations)
- ✅ Frontend skeleton (Vue 3, routing, auth, tenant switching)
- ⏳ **Next:** Complete Phase 1 inspection workflow

**Market Position:**
- **Target 1:** Fire protection contractors (competing with Uptick, ServiceTrade)
- **Target 2:** Facility managers (competing with IMEC, Inspect Point)
- **Differentiator:** AI-powered scheduling + tamper-proof records (UNIQUE)

**Competitors Analyzed:** 17 total
- Tier 1: Uptick, ServiceTrade, SafetyCulture, IMEC
- Tier 2: InspectNTrack, Firebug EXT, Fulcrum, Array
- Tier 3: Ecesis, Orca Scan, Snappii, Joyfill, ZenFire, Inspect Point

---

## Competitive Landscape

### Pricing Analysis (2025)

| Competitor | Pricing | Target Market | Key Strength |
|------------|---------|---------------|--------------|
| **Fulcrum** | $15-30/user/month | Field data capture | GPS & timestamping |
| **Array** | $30/user/month | NFPA compliance | Offline capability |
| **Firebug EXT** | $19-$159/month | Small to enterprise | Low entry price |
| **InspectNTrack** | $125-$249+/month | Inspection companies | Barcode focus |
| **SafetyCulture** | $24/user/month | Cross-industry | General inspection |
| **Uptick** | Per-user (custom) | Fire protection pros | 20+ dashboards |
| **ServiceTrade** | Office free, tech-based | Fire contractors | Free office users |
| **Streamline** | $2,000/year flat | Fire departments | Fire professional-designed |
| **IMEC** | Custom | Healthcare, industrial | Barcode verification |

**Market Gaps:**
1. ❌ NO AI-powered features in any competitor
2. ❌ NO tamper-proof/blockchain-style records
3. ❌ NO transparent freemium tier
4. ❌ Limited focus on facility managers (most target contractors)

**FireProof Competitive Advantages:**
1. ✅ AI-powered inspection scheduling (UNIQUE)
2. ✅ Predictive maintenance alerts (UNIQUE)
3. ✅ Tamper-proof inspection records (UNIQUE)
4. ✅ Transparent pricing with freemium tier
5. ✅ Modern tech stack (Vue 3, .NET 8, PWA)
6. ✅ Dual-market focus (contractors + facilities)

---

## Completed Work

### Database & Infrastructure ✅

**Core Schema (dbo):**
- [x] Tenants table
- [x] Users table
- [x] UserTenantRoles table (multi-tenant support)
- [x] AuditLog table

**Tenant Schema (DEMO001):**
- [x] Locations table (3 seed locations)
- [x] ExtinguisherTypes table (10 seed types)
- [x] Extinguishers table with all required columns:
  - [x] LastServiceDate, NextServiceDueDate, NextHydroTestDueDate
  - [x] FloorLevel, Notes, QrCodeData
  - [x] IsOutOfService, OutOfServiceReason

**Stored Procedures (16 total for DEMO001):**
- [x] usp_Tenant_GetAll, GetById, GetAvailableForUser
- [x] usp_Location_Create, GetAll, GetById
- [x] usp_Extinguisher_Create, GetAll, GetById, GetByBarcode
- [x] usp_ExtinguisherType_Create, GetAll, GetById
- [x] usp_Inspection_Create, GetById, GetByExtinguisher, Complete
- [x] usp_InspectionResponse_CreateBatch
- [x] usp_Report_ComplianceDashboard

**Seed Data:**
- [x] 3 Locations (HQ Seattle, Warehouse Tacoma, Factory Everett)
- [x] 10 Extinguisher Types (ABC, BC, K, CO2, H2O)
- [x] 15 Extinguishers (5 per location)
- [x] 2 Test users (chris@servicevision.net SystemAdmin, multi@servicevision.net TenantAdmin)

### Backend API ✅

**Services:**
- [x] TenantService (Create, GetAvailableForUser)
- [x] AuthenticationService (DevLogin, Login, RefreshToken)
- [x] LocationService (Create, GetAll, GetById)
- [x] ExtinguisherService (Create, GetAll, GetById, GetByBarcode)
- [x] ExtinguisherTypeService (Create, GetAll, GetById)
- [x] TamperProofingService (HMAC-SHA256 signatures)

**API Controllers:**
- [x] AuthenticationController (login, dev-login, refresh)
- [x] TenantsController (available tenants)
- [x] LocationsController (CRUD operations)
- [x] ExtinguishersController (CRUD operations)
- [x] ExtinguisherTypesController (CRUD operations)

**Infrastructure:**
- [x] DbConnectionFactory (multi-tenant connection routing)
- [x] TenantResolutionMiddleware (X-Tenant-ID header)
- [x] ErrorHandlingMiddleware
- [x] JWT authentication with Azure AD B2C
- [x] Azure deployment (Container Apps)

### Frontend (Vue 3) ✅

**Views:**
- [x] LoginView (with dev login)
- [x] TenantSelectorView (for multi-tenant users)
- [x] DashboardView (skeleton)
- [x] LocationsView (full CRUD)
- [x] ExtinguishersView (full CRUD)
- [x] ExtinguisherTypesView (full CRUD)
- [x] ProfileView
- [x] SettingsView

**Features:**
- [x] Pinia state management (auth, locations, extinguishers, extinguisherTypes)
- [x] Axios interceptors (auth token, tenant context)
- [x] Route guards (authentication, tenant selection)
- [x] Tenant switching capability
- [x] PWA configuration (offline-ready)
- [x] Console error cleanup (silent auth failures)
- [x] Tailwind CSS styling

**Deployment:**
- [x] Azure Static Web Apps (https://fireproofapp.net)
- [x] GitHub Actions CI/CD
- [x] Production environment configured

---

## Phase 1: MVP - Core Inspection (Weeks 1-4)

**Goal:** Match InspectNTrack, IMEC, and Firebug EXT core capabilities
**Priority:** 🔴 CRITICAL - Required for market entry
**Timeline:** 4 weeks
**Target:** Launch with functional inspection workflow

### Compliance Matrix Implementation

Based on the compliance & usability matrix from docs/solutions.md, implement all inspection steps:

#### 1.1 Inspection Workflow - Backend

**Database Tables:**
- [ ] 🔴 Inspections table
  ```sql
  InspectionId UNIQUEIDENTIFIER PK
  TenantId UNIQUEIDENTIFIER FK
  ExtinguisherId UNIQUEIDENTIFIER FK
  InspectorUserId UNIQUEIDENTIFIER FK
  InspectionType (Monthly, Annual, SixYear, TwelveYear, Hydrostatic)
  InspectionDate DATETIME2
  ScheduledDate DATETIME2
  Status (Scheduled, InProgress, Completed, Failed, Cancelled)

  -- GPS & Location Verification
  Latitude DECIMAL(9,6)
  Longitude DECIMAL(9,6)
  LocationAccuracy DECIMAL(10,2) -- meters
  LocationVerified BIT -- matches extinguisher location

  -- Physical Condition Checks
  PhysicalConditionPass BIT
  PhysicalConditionNotes NVARCHAR(500)
  HasDamage BIT
  HasCorrosion BIT
  HasLeakage BIT
  IsObstructed BIT

  -- Pressure/Weight Check
  PressureCheckPass BIT
  PressureReading NVARCHAR(50) -- "Green", "Red", or actual PSI
  WeightReading DECIMAL(10,2) -- for CO2
  WeightUnit NVARCHAR(10) -- lbs, kg

  -- Label/Tag Integrity
  LabelIntegrityPass BIT
  InstructionsLegible BIT
  LastInspectionDateVisible BIT

  -- Seal & Pin Status
  SealIntegrityPass BIT
  SealPresent BIT
  SealUnbroken BIT
  PinPresent BIT

  -- Hose/Nozzle Check
  HoseNozzlePass BIT
  HoseCondition NVARCHAR(50) -- Good, Cracked, Blocked
  NozzleCondition NVARCHAR(50)

  -- Overall Results
  OverallPass BIT
  RequiresRepair BIT
  RequiresReplacement BIT
  DeficiencyCount INT

  -- Signatures & Timestamps
  InspectorSignature NVARCHAR(MAX) -- base64 image
  StartTime DATETIME2
  CompletedTime DATETIME2
  DurationSeconds INT

  -- Device Info
  DeviceInfo NVARCHAR(500) -- JSON: device, OS, app version
  AppVersion NVARCHAR(50)

  -- Tamper-Proofing
  InspectionHash NVARCHAR(256) -- HMAC-SHA256
  PreviousInspectionHash NVARCHAR(256) -- hash chain
  HashVerified BIT

  CreatedDate DATETIME2
  ModifiedDate DATETIME2
  ```

- [ ] 🔴 InspectionPhotos table
  ```sql
  PhotoId UNIQUEIDENTIFIER PK
  InspectionId UNIQUEIDENTIFIER FK
  PhotoType (Location, PhysicalCondition, Pressure, Label, Seal, Hose, Deficiency, Other)
  BlobUrl NVARCHAR(500) -- Azure Blob Storage
  ThumbnailUrl NVARCHAR(500)
  FileSize BIGINT
  MimeType NVARCHAR(100)

  -- EXIF Data (for tamper verification)
  CaptureDate DATETIME2
  Latitude DECIMAL(9,6)
  Longitude DECIMAL(9,6)
  DeviceModel NVARCHAR(200)
  EXIFData NVARCHAR(MAX) -- full JSON

  Notes NVARCHAR(500)
  CreatedDate DATETIME2
  ```

- [ ] 🔴 InspectionDeficiencies table
  ```sql
  DeficiencyId UNIQUEIDENTIFIER PK
  InspectionId UNIQUEIDENTIFIER FK
  DeficiencyType (Damage, Corrosion, Leakage, Pressure, Seal, Label, Hose, Location, Other)
  Severity (Low, Medium, High, Critical)
  Description NVARCHAR(1000)
  Status (Open, InProgress, Resolved, Deferred)

  ActionRequired NVARCHAR(500)
  EstimatedCost DECIMAL(10,2)

  AssignedToUserId UNIQUEIDENTIFIER FK (nullable)
  DueDate DATE

  ResolutionNotes NVARCHAR(1000)
  ResolvedDate DATETIME2
  ResolvedByUserId UNIQUEIDENTIFIER FK (nullable)

  PhotoIds NVARCHAR(MAX) -- JSON array of PhotoIds

  CreatedDate DATETIME2
  ModifiedDate DATETIME2
  ```

- [ ] 🔴 ChecklistTemplates table (NFPA compliance)
  ```sql
  TemplateId UNIQUEIDENTIFIER PK
  TenantId UNIQUEIDENTIFIER FK (nullable - system templates)
  TemplateName NVARCHAR(200)
  InspectionType (Monthly, Annual, SixYear, TwelveYear, Hydrostatic)
  Standard (NFPA10, Title19, ULC, OSHA)
  IsSystemTemplate BIT
  IsActive BIT
  Description NVARCHAR(1000)
  CreatedDate DATETIME2
  ModifiedDate DATETIME2
  ```

- [ ] 🔴 ChecklistItems table
  ```sql
  ChecklistItemId UNIQUEIDENTIFIER PK
  TemplateId UNIQUEIDENTIFIER FK
  ItemText NVARCHAR(500)
  ItemDescription NVARCHAR(1000) -- help text for clients
  Order INT
  Category (Location, PhysicalCondition, Pressure, Seal, Hose, Label, Other)
  Required BIT
  RequiresPhoto BIT
  RequiresComment BIT
  PassFailNA BIT -- true for Pass/Fail/NA, false for just Pass/Fail
  VisualAid NVARCHAR(500) -- URL to diagram/photo
  CreatedDate DATETIME2
  ```

- [ ] 🔴 InspectionChecklistResponses table
  ```sql
  ResponseId UNIQUEIDENTIFIER PK
  InspectionId UNIQUEIDENTIFIER FK
  ChecklistItemId UNIQUEIDENTIFIER FK
  Response (Pass, Fail, NA)
  Comment NVARCHAR(1000)
  PhotoId UNIQUEIDENTIFIER FK (nullable)
  CreatedDate DATETIME2
  ```

**Stored Procedures:**
- [ ] 🔴 `usp_ChecklistTemplate_GetAll` - List templates (system + tenant)
- [ ] 🔴 `usp_ChecklistTemplate_GetById` - Get template with items
- [ ] 🔴 `usp_ChecklistTemplate_GetByType` - Get template by inspection type
- [ ] 🔴 `usp_ChecklistTemplate_Create` - Create custom template
- [ ] 🔴 `usp_ChecklistItem_CreateBatch` - Add items to template

- [ ] 🔴 `usp_Inspection_Create` - Create inspection
- [ ] 🔴 `usp_Inspection_Update` - Update inspection progress
- [ ] 🔴 `usp_Inspection_Complete` - Finalize inspection with hash
- [ ] 🔴 `usp_Inspection_GetById` - Get inspection details
- [ ] 🔴 `usp_Inspection_GetByExtinguisher` - Inspection history
- [ ] 🔴 `usp_Inspection_GetByDate` - Inspections in date range
- [ ] 🔴 `usp_Inspection_GetDue` - Overdue inspections
- [ ] 🔴 `usp_Inspection_GetScheduled` - Upcoming inspections
- [ ] 🔴 `usp_Inspection_VerifyHash` - Verify tamper-proof chain

- [ ] 🔴 `usp_InspectionChecklistResponse_CreateBatch` - Save checklist
- [ ] 🔴 `usp_InspectionChecklistResponse_GetByInspection` - Get responses

- [ ] 🔴 `usp_InspectionPhoto_Create` - Save photo metadata
- [ ] 🔴 `usp_InspectionPhoto_GetByInspection` - List photos
- [ ] 🔴 `usp_InspectionPhoto_GetByType` - Photos by type

- [ ] 🔴 `usp_InspectionDeficiency_Create` - Create deficiency
- [ ] 🔴 `usp_InspectionDeficiency_Update` - Update deficiency
- [ ] 🔴 `usp_InspectionDeficiency_Resolve` - Mark resolved
- [ ] 🔴 `usp_InspectionDeficiency_GetByInspection` - Deficiencies for inspection
- [ ] 🔴 `usp_InspectionDeficiency_GetOpen` - Open deficiencies by tenant
- [ ] 🔴 `usp_InspectionDeficiency_GetBySeverity` - Critical deficiencies

**Backend Services:**
- [ ] 🔴 `IInspectionService` + `InspectionService`
  - [ ] CreateInspectionAsync(tenantId, request)
  - [ ] UpdateInspectionAsync(tenantId, inspectionId, request)
  - [ ] CompleteInspectionAsync(tenantId, inspectionId, signature)
  - [ ] GetInspectionByIdAsync(tenantId, inspectionId)
  - [ ] GetInspectionsByExtinguisherAsync(tenantId, extinguisherId)
  - [ ] GetInspectionsByDateRangeAsync(tenantId, startDate, endDate)
  - [ ] GetDueInspectionsAsync(tenantId)
  - [ ] GetScheduledInspectionsAsync(tenantId)
  - [ ] VerifyInspectionIntegrityAsync(tenantId, inspectionId)
  - [ ] CalculateNextDueDateAsync(extinguisherId, inspectionType)

- [ ] 🔴 `IChecklistTemplateService` + `ChecklistTemplateService`
  - [ ] GetSystemTemplatesAsync()
  - [ ] GetTenantTemplatesAsync(tenantId)
  - [ ] GetTemplateByIdAsync(templateId)
  - [ ] GetTemplateByTypeAsync(tenantId, inspectionType)
  - [ ] CreateCustomTemplateAsync(tenantId, request)
  - [ ] CloneTemplateAsync(tenantId, sourceTemplateId)

- [ ] 🔴 `IDeficiencyService` + `DeficiencyService`
  - [ ] CreateDeficiencyAsync(tenantId, inspectionId, request)
  - [ ] UpdateDeficiencyAsync(tenantId, deficiencyId, request)
  - [ ] ResolveDeficiencyAsync(tenantId, deficiencyId, resolution)
  - [ ] GetDeficienciesByInspectionAsync(tenantId, inspectionId)
  - [ ] GetOpenDeficienciesAsync(tenantId)
  - [ ] GetCriticalDeficienciesAsync(tenantId)
  - [ ] AssignDeficiencyAsync(tenantId, deficiencyId, userId)

- [ ] 🔴 `IPhotoService` + `AzureBlobPhotoService`
  - [ ] UploadPhotoAsync(tenantId, inspectionId, file, photoType)
  - [ ] GetPhotoAsync(photoId)
  - [ ] GetPhotosByInspectionAsync(tenantId, inspectionId)
  - [ ] DeletePhotoAsync(tenantId, photoId)
  - [ ] ExtractEXIFDataAsync(file)
  - [ ] GenerateThumbnailAsync(file)
  - [ ] CompressPhotoAsync(file) - reduce size for mobile
  - [ ] ValidatePhotoIntegrityAsync(photoId) - check GPS/timestamp

**API Controllers:**
- [ ] 🔴 `InspectionsController`
  - [ ] GET /api/inspections - List inspections (with filters)
  - [ ] POST /api/inspections - Create inspection
  - [ ] GET /api/inspections/{id} - Get inspection details
  - [ ] PUT /api/inspections/{id} - Update inspection
  - [ ] POST /api/inspections/{id}/complete - Complete with signature
  - [ ] GET /api/inspections/due - Get overdue inspections
  - [ ] GET /api/inspections/scheduled - Get upcoming inspections
  - [ ] POST /api/inspections/{id}/photos - Upload photo
  - [ ] GET /api/inspections/{id}/photos - List photos
  - [ ] POST /api/inspections/{id}/deficiencies - Create deficiency
  - [ ] GET /api/inspections/{id}/deficiencies - List deficiencies
  - [ ] POST /api/inspections/{id}/checklist - Save checklist responses
  - [ ] GET /api/inspections/{id}/verify - Verify hash chain

- [ ] 🔴 `ChecklistTemplatesController`
  - [ ] GET /api/checklist-templates - List templates (system + tenant)
  - [ ] GET /api/checklist-templates/{id} - Get template with items
  - [ ] POST /api/checklist-templates - Create custom template
  - [ ] POST /api/checklist-templates/{id}/clone - Clone template

- [ ] 🔴 `DeficienciesController`
  - [ ] GET /api/deficiencies - List deficiencies (tenant-wide)
  - [ ] GET /api/deficiencies/{id} - Get deficiency details
  - [ ] PUT /api/deficiencies/{id} - Update deficiency
  - [ ] POST /api/deficiencies/{id}/resolve - Mark resolved
  - [ ] POST /api/deficiencies/{id}/assign - Assign to user
  - [ ] GET /api/deficiencies/critical - Critical deficiencies alert

#### 1.2 NFPA Compliance Checklist Templates

Create system templates for all NFPA 10 inspection types:

**Monthly Inspection Template (NFPA 10 Section 7.2):**
- [ ] 🔴 Extinguisher accessible and visible
- [ ] 🔴 Location clearly marked
- [ ] 🔴 Pressure gauge in operable range (green zone)
- [ ] 🔴 Safety seal/tamper indicator intact
- [ ] 🔴 No visible physical damage
- [ ] 🔴 Operating instructions legible and facing outward
- [ ] 🔴 Service tag attached and current
- [ ] 🔴 Hose and nozzle unobstructed and in good condition
- [ ] 🔴 Mounting bracket secure
- [ ] 🔴 No signs of discharge
- [ ] 🔴 Inspection date documented on tag

**Annual Inspection Template (NFPA 10 Section 7.3):**
- [ ] 🔴 All monthly checklist items
- [ ] 🔴 Mechanical parts examination
- [ ] 🔴 Extinguishing agent examination
- [ ] 🔴 Expelling means examination
- [ ] 🔴 Physical condition detailed check
- [ ] 🟠 Weight check (CO2 and stored pressure types)
- [ ] 🟠 Pressure check (rechargeable stored pressure types)
- [ ] 🟠 Examine for obvious physical damage, corrosion
- [ ] 🟠 Examine extinguisher nameplate legibility
- [ ] 🟠 Check manufacturer's instructions are available
- [ ] 🟠 Verify proper extinguisher type for hazard location
- [ ] 🟠 Verify proper mounting height and accessibility
- [ ] 🔴 Service tag updated with inspection date

**Six-Year Maintenance Template (NFPA 10 Section 7.3.1):**
- [ ] 🟠 All annual inspection items
- [ ] 🟠 Internal examination (applicable types)
- [ ] 🟠 Complete disassembly
- [ ] 🟠 Examination of all components
- [ ] 🟠 Replacement of parts as needed
- [ ] 🟠 Refill or recharge
- [ ] 🟠 New tamper seal installed
- [ ] 🟠 Service tag updated with 6-year maintenance
- [ ] 🟠 Photo documentation of internal condition

**Twelve-Year Hydrostatic Test Template (NFPA 10 Section 8.3):**
- [ ] 🟠 Visual internal examination
- [ ] 🟠 Hydrostatic pressure test performed
- [ ] 🟠 Test results documented
- [ ] 🟠 Thread inspection (hose assemblies)
- [ ] 🟠 Valve inspection
- [ ] 🟠 Cylinder inspection for damage/corrosion
- [ ] 🟠 Recharge after test
- [ ] 🟠 New service tag with hydrostatic test date
- [ ] 🟠 Photo documentation

**California Title 19 Template (if applicable):**
- [ ] 🟡 State-specific requirements
- [ ] 🟡 Additional documentation requirements
- [ ] 🟡 California-specific reporting format

**ULC Template (Canadian Standards):**
- [ ] 🟡 ULC-specific checklist items
- [ ] 🟡 Canadian regulatory compliance
- [ ] 🟡 ULC reporting format

#### 1.3 Inspection Workflow - Frontend

**Views:**
- [ ] 🔴 InspectionsView - List all inspections
  - [ ] Filter by date range
  - [ ] Filter by status (Scheduled, InProgress, Completed, Failed)
  - [ ] Filter by location
  - [ ] Filter by inspector
  - [ ] Search by extinguisher
  - [ ] Color-coded status badges
  - [ ] Quick action buttons (View, Edit, Continue)
  - [ ] Export to PDF/Excel

- [ ] 🔴 InspectionDetailView - View completed inspection
  - [ ] Inspection summary card
  - [ ] Checklist results with Pass/Fail/NA indicators
  - [ ] Photo gallery
  - [ ] Deficiency list
  - [ ] GPS location map
  - [ ] Inspector signature
  - [ ] Tamper-proof hash verification status
  - [ ] Print inspection report button
  - [ ] Email report button

- [ ] 🔴 CreateInspectionView - Start new inspection
  - [ ] **Step 1: Scan or Select Extinguisher**
    - [ ] Large "Scan Barcode" button (camera integration)
    - [ ] Alternative: Search extinguisher by location/asset tag
    - [ ] Display extinguisher details when found
    - [ ] Show last inspection date
    - [ ] Show next due date

  - [ ] **Step 2: Select Inspection Type**
    - [ ] Radio buttons: Monthly, Annual, 6-Year, 12-Year, Hydrostatic
    - [ ] Display relevant checklist template preview
    - [ ] Show estimated time to complete

  - [ ] **Step 3: Capture GPS Location**
    - [ ] Request geolocation permission
    - [ ] Display current GPS coordinates
    - [ ] Show accuracy (meters)
    - [ ] Display map with extinguisher expected location
    - [ ] Warning if GPS doesn't match expected location
    - [ ] Override option with reason

  - [ ] **Step 4: Begin Inspection**
    - [ ] Start timer
    - [ ] Load checklist items

- [ ] 🔴 PerformInspectionView - Guided inspection workflow
  - [ ] **Mobile-Optimized UI:**
    - [ ] Large touch-friendly buttons
    - [ ] Single checklist item at a time (swipe to next)
    - [ ] Progress bar (e.g., "5 of 12 items complete")
    - [ ] Visual aids (diagrams, photos) for each item
    - [ ] Pass/Fail/NA buttons (green/red/gray)
    - [ ] Optional comment field (expands on tap)
    - [ ] "Add Photo" button (required items auto-prompt)

  - [ ] **Checklist Item Component:**
    - [ ] Item number and category badge
    - [ ] Item text in large, readable font
    - [ ] Help icon (shows detailed instructions)
    - [ ] Visual aid image (if available)
    - [ ] Response buttons (Pass/Fail/NA)
    - [ ] Comment textarea
    - [ ] Photo thumbnail (if captured)
    - [ ] "Next" button (disabled until answered)

  - [ ] **Photo Capture:**
    - [ ] Native camera integration
    - [ ] Auto-capture GPS coordinates
    - [ ] Auto-capture timestamp
    - [ ] Photo preview before adding
    - [ ] Compress photo for mobile upload
    - [ ] Attach to checklist item

  - [ ] **Deficiency Flagging:**
    - [ ] "Flag as Deficiency" button on failed items
    - [ ] Severity selector (Low, Medium, High, Critical)
    - [ ] Description textarea
    - [ ] Action required field
    - [ ] Estimated cost field (optional)
    - [ ] Assign to user (optional)

  - [ ] **Save Draft:**
    - [ ] "Save & Exit" button (save progress)
    - [ ] Store in IndexedDB if offline
    - [ ] Resume from saved draft

  - [ ] **Complete Inspection:**
    - [ ] Review screen (summary of all responses)
    - [ ] Overall Pass/Fail determination
    - [ ] Deficiency count
    - [ ] Digital signature capture canvas
    - [ ] "Complete Inspection" button
    - [ ] Generate tamper-proof hash
    - [ ] Sync to server (or queue if offline)

- [ ] 🔴 DeficienciesView - Deficiency management
  - [ ] List all open deficiencies
  - [ ] Filter by severity
  - [ ] Filter by status
  - [ ] Filter by assigned user
  - [ ] Assign deficiency modal
  - [ ] Update status modal
  - [ ] Resolve deficiency modal (with resolution notes)
  - [ ] Deficiency detail view (linked inspection, photos)

**Components:**
- [ ] 🔴 InspectionCard - Summary card for list view
  - [ ] Extinguisher asset tag
  - [ ] Location name
  - [ ] Inspection type badge
  - [ ] Status badge (color-coded)
  - [ ] Inspection date
  - [ ] Inspector name
  - [ ] Pass/Fail indicator
  - [ ] Deficiency count badge
  - [ ] Quick action menu

- [ ] 🔴 ChecklistItem - Individual checklist item
  - [ ] Item number
  - [ ] Item text
  - [ ] Help icon with popover
  - [ ] Visual aid image
  - [ ] Pass/Fail/NA button group
  - [ ] Comment field
  - [ ] Photo thumbnail
  - [ ] "Required" badge if mandatory

- [ ] 🔴 PhotoCapture - Camera integration
  - [ ] Camera preview
  - [ ] Capture button
  - [ ] Retake button
  - [ ] Confirm button
  - [ ] GPS/timestamp overlay
  - [ ] Compression progress

- [ ] 🔴 BarcodeScanner - QR/Barcode scanner
  - [ ] Camera preview with targeting box
  - [ ] Scan success feedback (sound + visual)
  - [ ] Manual entry fallback
  - [ ] Scan history (recent scans)

- [ ] 🔴 SignaturePad - Digital signature capture
  - [ ] Canvas for drawing
  - [ ] Clear button
  - [ ] Signature preview
  - [ ] Inspector name confirmation
  - [ ] Date/time stamp

- [ ] 🔴 DeficiencyBadge - Severity indicator
  - [ ] Color-coded by severity
  - [ ] Icon (exclamation, warning, etc.)
  - [ ] Tooltip with description

- [ ] 🔴 InspectionProgressBar - Visual progress
  - [ ] Completed items count
  - [ ] Total items count
  - [ ] Percentage bar
  - [ ] Estimated time remaining

- [ ] 🔴 GPSLocationMap - Location verification
  - [ ] Map view (Leaflet or Google Maps)
  - [ ] Current location marker
  - [ ] Expected location marker
  - [ ] Distance indicator
  - [ ] Accuracy circle

**Stores (Pinia):**
- [ ] 🔴 useInspectionStore
  - State:
    - [ ] inspections (list)
    - [ ] currentInspection
    - [ ] draftInspections (offline queue)
    - [ ] deficiencies
    - [ ] checklistTemplates
  - Actions:
    - [ ] fetchInspections(filters)
    - [ ] fetchInspectionById(id)
    - [ ] createInspection(data)
    - [ ] updateInspection(id, data)
    - [ ] completeInspection(id, signature)
    - [ ] saveDraft(inspection)
    - [ ] resumeDraft(id)
    - [ ] deleteDraft(id)
    - [ ] syncOfflineInspections()
    - [ ] fetchChecklistTemplates()
    - [ ] getTemplateByType(type)

- [ ] 🔴 useDeficiencyStore
  - State:
    - [ ] deficiencies
    - [ ] openDeficiencies
    - [ ] criticalDeficiencies
  - Actions:
    - [ ] fetchDeficiencies(filters)
    - [ ] createDeficiency(data)
    - [ ] updateDeficiency(id, data)
    - [ ] resolveDeficiency(id, resolution)
    - [ ] assignDeficiency(id, userId)

**Services:**
- [ ] 🔴 inspectionService.js
  - [ ] getAll(filters)
  - [ ] getById(id)
  - [ ] create(data)
  - [ ] update(id, data)
  - [ ] complete(id, signature)
  - [ ] uploadPhoto(inspectionId, file)
  - [ ] getPhotos(inspectionId)
  - [ ] getDue()
  - [ ] getScheduled()
  - [ ] verify(id) - verify hash chain

- [ ] 🔴 checklistService.js
  - [ ] getTemplates()
  - [ ] getTemplate(id)
  - [ ] getTemplateByType(type)
  - [ ] createCustom(data)

- [ ] 🔴 deficiencyService.js
  - [ ] getAll(filters)
  - [ ] create(data)
  - [ ] update(id, data)
  - [ ] resolve(id, resolution)
  - [ ] assign(id, userId)

**Offline Support:**
- [ ] 🔴 IndexedDB schema for offline inspections
  - [ ] draftInspections table
  - [ ] offlinePhotos table (base64 encoded)
  - [ ] syncQueue table
- [ ] 🔴 Background sync when online
- [ ] 🔴 Conflict resolution (if inspection was modified server-side)
- [ ] 🔴 Offline indicator in UI
- [ ] 🔴 Sync progress indicator

#### 1.4 Reporting & Compliance

**Backend:**
- [ ] 🔴 `IReportService` + `ReportService`
  - [ ] GenerateInspectionReportAsync(tenantId, inspectionId) - PDF
  - [ ] GenerateComplianceReportAsync(tenantId, startDate, endDate) - PDF
  - [ ] GenerateDeficiencyReportAsync(tenantId, filters) - PDF
  - [ ] GenerateInspectionHistoryAsync(tenantId, extinguisherId) - PDF
  - [ ] ExportInspectionsToExcelAsync(tenantId, filters)
  - [ ] ExportDeficienciesToExcelAsync(tenantId, filters)

**PDF Generation (QuestPDF):**
- [ ] 🔴 Install QuestPDF NuGet package
- [ ] 🔴 Create PDF templates:
  - [ ] Inspection report template
    - [ ] Company logo/branding
    - [ ] Extinguisher details
    - [ ] Inspection checklist results table
    - [ ] Photos (embedded)
    - [ ] Deficiencies section
    - [ ] Inspector signature
    - [ ] Tamper-proof hash (QR code)
  - [ ] Compliance summary report template
  - [ ] Deficiency report template

**API Endpoints:**
- [ ] 🔴 GET /api/reports/inspection/{inspectionId} - Generate inspection PDF
- [ ] 🔴 GET /api/reports/compliance - Generate compliance report
- [ ] 🔴 GET /api/reports/deficiencies - Generate deficiency report
- [ ] 🔴 GET /api/reports/export/inspections - Export to Excel
- [ ] 🔴 GET /api/reports/export/deficiencies - Export to Excel

**Frontend:**
- [ ] 🔴 ReportsView
  - [ ] Report type selector
  - [ ] Date range picker
  - [ ] Filter options
  - [ ] Generate PDF button
  - [ ] Export to Excel button
  - [ ] Email report option
  - [ ] Report preview

#### 1.5 Automated Scheduling & Reminders

**Backend:**
- [ ] 🔴 Install Hangfire NuGet package
- [ ] 🔴 Configure Hangfire server (SQL Server storage)
- [ ] 🔴 Create Hangfire dashboard (/hangfire)

**Background Jobs:**
- [ ] 🔴 `CalculateNextDueDatesJob`
  - [ ] Run daily at 2 AM
  - [ ] Calculate next inspection due dates based on:
    - [ ] Last inspection date
    - [ ] Inspection type frequency (monthly, annual, etc.)
    - [ ] Extinguisher type requirements
  - [ ] Update Extinguishers.NextServiceDueDate

- [ ] 🔴 `InspectionReminderJob`
  - [ ] Run daily at 8 AM
  - [ ] Find inspections due in 7 days, 3 days, 1 day, overdue
  - [ ] Send email reminders to inspectors and clients
  - [ ] Send SMS reminders (optional, Twilio)
  - [ ] Log reminder sent

- [ ] 🔴 `OverdueInspectionEscalationJob`
  - [ ] Run daily at 9 AM
  - [ ] Find inspections overdue by 1 week, 2 weeks, 1 month
  - [ ] Escalate to manager/admin
  - [ ] Send critical alerts for high-severity overdue

**Email Service:**
- [ ] 🔴 Configure SendGrid or Azure Communication Services
- [ ] 🔴 Create email templates:
  - [ ] Inspection reminder (7 days)
  - [ ] Inspection reminder (3 days)
  - [ ] Inspection reminder (1 day)
  - [ ] Inspection overdue
  - [ ] Critical deficiency alert
- [ ] 🔴 IEmailService + SendGridEmailService
  - [ ] SendInspectionReminderAsync(inspectionId)
  - [ ] SendDeficiencyAlertAsync(deficiencyId)
  - [ ] SendWeeklyComplianceSummaryAsync(tenantId)

**Frontend:**
- [ ] 🔴 CalendarView (optional for Phase 2)
  - [ ] Month/week/day views
  - [ ] Scheduled inspections
  - [ ] Due inspections (color-coded)
  - [ ] Drag-and-drop rescheduling

---

## Phase 2: Business Features (Weeks 5-8)

**Goal:** Match Uptick & ServiceTrade business management capabilities
**Priority:** 🟠 HIGH - Required for contractor market
**Timeline:** 4 weeks

### 2.1 Customer Portal

**Competitor Feature:** Uptick ✅ | ServiceTrade ✅ | Firebug EXT ❓

**Backend:**
- [ ] 🟠 Customers table
  ```sql
  CustomerId UNIQUEIDENTIFIER PK
  TenantId UNIQUEIDENTIFIER FK
  CompanyName NVARCHAR(200)
  BillingAddress NVARCHAR(500)
  ServiceAddress NVARCHAR(500)
  Phone NVARCHAR(20)
  Email NVARCHAR(200)
  CustomerType (Residential, Commercial, Government, Industrial)
  PaymentTerms INT -- days
  TaxId NVARCHAR(50)
  IsActive BIT
  ```

- [ ] 🟠 Contacts table (multiple per customer)
  ```sql
  ContactId UNIQUEIDENTIFIER PK
  CustomerId UNIQUEIDENTIFIER FK
  FirstName NVARCHAR(100)
  LastName NVARCHAR(100)
  Title NVARCHAR(100)
  Email NVARCHAR(200)
  Phone NVARCHAR(20)
  IsPrimary BIT
  ReceivesInspectionReports BIT
  ReceivesDeficiencyAlerts BIT
  ReceivesInvoices BIT
  ```

- [ ] 🟠 `ICustomerService` + `CustomerService`
- [ ] 🟠 `CustomersController` (CRUD endpoints)

**Customer-Facing Portal (Separate Vue App or Route):**
- [ ] 🟠 Customer login (separate auth)
- [ ] 🟠 Customer dashboard
  - [ ] Equipment register (read-only)
  - [ ] Inspection history
  - [ ] Upcoming inspections
  - [ ] Deficiency status
  - [ ] Service agreements
- [ ] 🟠 View inspection reports (PDF download)
- [ ] 🟠 Deficiency notifications
- [ ] 🟠 Accept/approve quotes online
- [ ] 🟠 Customer profile management
- [ ] 🟠 Contact management

### 2.2 Service Agreements & Contracts

**Competitor Feature:** Uptick ✅ | ServiceTrade ✅ | SmartServ ✅

**Backend:**
- [ ] 🟠 ServiceAgreements table
  ```sql
  AgreementId UNIQUEIDENTIFIER PK
  TenantId UNIQUEIDENTIFIER FK
  CustomerId UNIQUEIDENTIFIER FK
  AgreementNumber NVARCHAR(50)
  StartDate DATE
  EndDate DATE
  Frequency (Monthly, Quarterly, Annual)
  ContractValue DECIMAL(10,2)
  BillingCycle (Monthly, Annual, PerInspection)
  AutoRenew BIT
  Status (Draft, Active, Expired, Cancelled)
  ```

- [ ] 🟠 `IServiceAgreementService` + `ServiceAgreementService`
- [ ] 🟠 Automated inspection scheduling based on agreements
  - [ ] Create recurring inspections on agreement activation
  - [ ] Update schedules on agreement changes
  - [ ] Cancel inspections on agreement termination

### 2.3 Quoting & Invoicing

**Competitor Feature:** Uptick ✅ | ServiceTrade ✅ | SmartServ ✅

**Backend:**
- [ ] 🟠 Quotes table
  ```sql
  QuoteId UNIQUEIDENTIFIER PK
  TenantId UNIQUEIDENTIFIER FK
  CustomerId UNIQUEIDENTIFIER FK
  QuoteNumber NVARCHAR(50)
  QuoteDate DATE
  ValidUntil DATE
  Subtotal DECIMAL(10,2)
  Tax DECIMAL(10,2)
  Total DECIMAL(10,2)
  Status (Draft, Sent, Approved, Declined, Converted)
  ```

- [ ] 🟠 QuoteLineItems table
- [ ] 🟠 Invoices table (similar structure)
- [ ] 🟠 InvoiceLineItems table

- [ ] 🟠 `IQuoteService` + `QuoteService`
  - [ ] CreateQuoteFromDeficiencyAsync(deficiencyId)
  - [ ] ConvertQuoteToInvoiceAsync(quoteId)

- [ ] 🟠 `IInvoiceService` + `InvoiceService`
  - [ ] GenerateInvoiceAsync
  - [ ] SendInvoiceAsync (email)
  - [ ] RecordPaymentAsync

**Frontend:**
- [ ] 🟠 QuotesView
  - [ ] List quotes
  - [ ] Create quote from deficiency (auto-populate)
  - [ ] Add line items
  - [ ] Apply discounts/taxes
  - [ ] Send to customer (email)
  - [ ] Track approval status
  - [ ] Convert to invoice

- [ ] 🟠 InvoicesView
  - [ ] List invoices
  - [ ] Generate from quote or service agreement
  - [ ] Track payment status
  - [ ] Record payment
  - [ ] Send invoice (email)

### 2.4 Analytics Dashboard

**Competitor Feature:** Uptick (20+ dashboards) ✅ | IMEC ✅ | SafetyCulture ✅

**Backend:**
- [ ] 🟠 `IDashboardService` + `DashboardService`
  - [ ] GetComplianceMetricsAsync(tenantId, dateRange)
  - [ ] GetInspectionTrendsAsync(tenantId, dateRange)
  - [ ] GetDeficiencyMetricsAsync(tenantId, dateRange)
  - [ ] GetRevenueMetricsAsync(tenantId, dateRange)
  - [ ] GetInspectorPerformanceAsync(tenantId, dateRange)

**Stored Procedures:**
- [ ] 🟠 `usp_Dashboard_ComplianceMetrics`
  - [ ] Total extinguishers
  - [ ] Compliant count
  - [ ] Overdue count
  - [ ] Due soon count
  - [ ] Compliance percentage
  - [ ] Trend (up/down vs. last period)

- [ ] 🟠 `usp_Dashboard_InspectionTrends`
  - [ ] Inspections per month (12 months)
  - [ ] Pass/fail ratio
  - [ ] Average inspection duration
  - [ ] Inspections by type

- [ ] 🟠 `usp_Dashboard_DeficiencyMetrics`
  - [ ] Open deficiencies
  - [ ] Deficiencies by severity
  - [ ] Average resolution time
  - [ ] Deficiencies by type

**Frontend:**
- [ ] 🟠 Enhanced DashboardView
  - [ ] Compliance rate card (with trend)
  - [ ] Total inspections card
  - [ ] Open deficiencies card
  - [ ] Revenue card (this month)
  - [ ] Inspection completion trend chart (12 months)
  - [ ] Deficiencies by severity chart (pie)
  - [ ] Inspections by location chart (bar)
  - [ ] Inspections by type chart (donut)
  - [ ] Overdue inspections list widget
  - [ ] Critical deficiencies list widget
  - [ ] Date range filter
  - [ ] Export dashboard to PDF

**Charting Library:**
- [ ] 🟠 Install Chart.js or Recharts
- [ ] 🟠 Create reusable chart components

### 2.5 Accounting Integrations

**Competitor Feature:** Uptick (QuickBooks, Xero) ✅ | ServiceTrade ✅

**Phase 2.5 (Optional for MVP+):**
- [ ] 🟡 QuickBooks Online integration
  - [ ] OAuth authentication
  - [ ] Sync customers
  - [ ] Create invoices in QuickBooks
  - [ ] Sync payments
  - [ ] Sync chart of accounts

- [ ] 🟡 Xero integration (similar to QuickBooks)

- [ ] 🟡 Stripe payment processing
  - [ ] Customer payment methods
  - [ ] Process credit card payments
  - [ ] Recurring billing for service agreements
  - [ ] Webhook handlers for payment events

---

## Phase 3: AI & Native Apps (Weeks 9-16)

**Goal:** Differentiate with AI features (UNIQUE in market) + native mobile apps
**Priority:** 🟠 MEDIUM-HIGH - Competitive differentiator
**Timeline:** 8 weeks

### 3.1 AI-Powered Inspection Scheduling

**Competitor Feature:** NONE ❌ - First mover advantage

#### Data Collection Layer
- [ ] 🟠 InspectionMetrics table (for ML training)
  ```sql
  MetricId UNIQUEIDENTIFIER PK
  ExtinguisherId UNIQUEIDENTIFIER FK
  InspectionDate DATE
  DaysSinceLastInspection INT
  PressureReading NVARCHAR(50)
  WeightReading DECIMAL(10,2)
  DeficiencyCount INT
  PassFail BIT
  InspectionDuration INT -- seconds
  ```

- [ ] 🟠 EnvironmentalFactors table
  ```sql
  FactorId UNIQUEIDENTIFIER PK
  LocationId UNIQUEIDENTIFIER FK
  AvgTemperature DECIMAL(5,2)
  AvgHumidity DECIMAL(5,2)
  IndoorOutdoor NVARCHAR(20)
  ExposureToChemicals BIT
  HighTrafficArea BIT
  HarshEnvironment BIT
  ```

- [ ] 🟠 Background job to populate metrics daily

#### ML Model Development

**Python Service (Azure Function or Container):**
- [ ] 🟠 Setup Python environment
  - [ ] Install scikit-learn, pandas, numpy
  - [ ] Install Azure ML SDK
  - [ ] Setup Azure ML workspace

- [ ] 🟠 Data extraction from SQL
  - [ ] Query inspection history
  - [ ] Query environmental factors
  - [ ] Query extinguisher metadata
  - [ ] Create training dataset CSV/Parquet

- [ ] 🟠 Feature engineering
  ```python
  Features:
  - equipment_age_years
  - days_since_last_inspection
  - historical_deficiency_count
  - location_risk_score (0-100)
  - avg_temperature
  - avg_humidity
  - indoor_outdoor (binary)
  - exposure_to_chemicals (binary)
  - manufacturer_reliability (historical fail rate)
  - extinguisher_type (categorical)
  - capacity

  Target:
  - optimal_inspection_interval (days)
  - failure_risk_score (0-100)
  ```

- [ ] 🟠 Model training
  - [ ] Train regression model (optimal interval)
  - [ ] Train classification model (risk level: low/medium/high/critical)
  - [ ] Hyperparameter tuning
  - [ ] Cross-validation
  - [ ] Model versioning with MLflow

- [ ] 🟠 Model deployment
  - [ ] Deploy to Azure ML endpoint
  - [ ] Create inference API (Flask or FastAPI)
  - [ ] Endpoints:
    - [ ] POST /predict/optimal-interval
    - [ ] POST /predict/risk-score
    - [ ] POST /predict/batch

#### .NET Integration
- [ ] 🟠 `IAISchedulingService` + `AISchedulingService`
  - [ ] GetRecommendedInspectionDateAsync(extinguisherId)
  - [ ] CalculateRiskScoreAsync(extinguisherId)
  - [ ] GetHighRiskExtinguishersAsync(tenantId)
  - [ ] OptimizeInspectionScheduleAsync(tenantId, locationId)
  - [ ] GetRouteOptimizationAsync(inspectionIds[])

- [ ] 🟠 Background job: `UpdateRiskScoresJob`
  - [ ] Run daily
  - [ ] Call AI service for all extinguishers
  - [ ] Update ExtinguisherMetrics table with risk scores
  - [ ] Generate alerts for high-risk equipment

#### Frontend
- [ ] 🟠 AI Insights Dashboard
  - [ ] High-risk extinguisher list (top 10)
  - [ ] Risk score heat map by location
  - [ ] Recommended inspection schedule (AI-optimized)
  - [ ] Predicted failure timeline chart
  - [ ] Inspection efficiency metrics (AI vs. manual)
  - [ ] Estimated cost savings

- [ ] 🟠 Inspection Schedule Optimizer
  - [ ] "Auto-Schedule with AI" button
  - [ ] Show AI vs. manual schedule comparison
  - [ ] Route optimization map (GPS-based)
  - [ ] Estimated time savings display
  - [ ] Accept/reject AI recommendations

### 3.2 Predictive Maintenance & Anomaly Detection

**Competitor Feature:** NONE ❌ - Unique to FireProof

**Backend:**
- [ ] 🟡 Pressure trend analysis
  - [ ] Track pressure readings over time
  - [ ] Detect gradual pressure loss (anomaly)
  - [ ] Alert before failure threshold

- [ ] 🟡 Deficiency pattern recognition
  - [ ] Identify recurring deficiencies (same extinguisher)
  - [ ] Suggest root cause (environmental, manufacturer defect)
  - [ ] Recommend preventive action (relocation, replacement)

- [ ] 🟡 Equipment lifespan prediction
  - [ ] Estimate remaining useful life
  - [ ] Budget planning for replacements
  - [ ] Depreciation tracking

**Frontend:**
- [ ] 🟡 Anomaly detection alerts widget
  - [ ] Email/SMS when unusual pattern detected
  - [ ] Dashboard widget with flagged extinguishers
  - [ ] Recommended actions

### 3.3 Native Mobile Apps

**Competitor Feature:** Most have native apps ✅

#### iOS App (Swift/SwiftUI)
- [ ] 🟠 Project setup in Xcode
- [ ] 🟠 Core infrastructure
  - [ ] Networking layer (URLSession)
  - [ ] Core Data models (offline storage)
  - [ ] Authentication service
  - [ ] Offline sync manager
  - [ ] Keychain for secure token storage

- [ ] 🟠 Features
  - [ ] Login screen
  - [ ] Dashboard
  - [ ] Location list & details
  - [ ] Extinguisher list & details
  - [ ] Barcode scanner (AVFoundation)
  - [ ] Inspection form (step-by-step)
  - [ ] Photo capture (camera)
  - [ ] GPS coordinate capture (Core Location)
  - [ ] Digital signature (SwiftUI Canvas)
  - [ ] Reports view

- [ ] 🟠 Offline sync
  - [ ] Offline inspection queue
  - [ ] Background sync (BackgroundTasks framework)
  - [ ] Conflict resolution

- [ ] 🟠 Push notifications (APNs)
  - [ ] Inspection reminders
  - [ ] Deficiency alerts
  - [ ] Overdue escalations

- [ ] 🟠 Testing & Deployment
  - [ ] Unit tests (XCTest)
  - [ ] UI tests (XCUITest)
  - [ ] App Store Connect configuration
  - [ ] TestFlight beta testing
  - [ ] App Store submission

#### Android App (Kotlin/Jetpack Compose)
- [ ] 🟠 Project setup in Android Studio
- [ ] 🟠 Core infrastructure
  - [ ] Networking layer (Retrofit + OkHttp)
  - [ ] Room database (offline storage)
  - [ ] Authentication service
  - [ ] Offline sync manager (WorkManager)
  - [ ] Encrypted SharedPreferences

- [ ] 🟠 Features (same as iOS)
  - [ ] Login screen (Composable)
  - [ ] Dashboard
  - [ ] Locations, Extinguishers
  - [ ] Barcode scanner (CameraX + ML Kit)
  - [ ] Inspection form
  - [ ] Photo capture (CameraX)
  - [ ] GPS (Location Services)
  - [ ] Digital signature (Canvas)
  - [ ] Reports

- [ ] 🟠 Offline sync
  - [ ] Offline queue
  - [ ] Background sync (WorkManager)
  - [ ] Conflict resolution

- [ ] 🟠 Push notifications (FCM)
  - [ ] Inspection reminders
  - [ ] Deficiency alerts

- [ ] 🟠 Testing & Deployment
  - [ ] Unit tests (JUnit)
  - [ ] UI tests (Espresso)
  - [ ] Google Play Console configuration
  - [ ] Internal testing track
  - [ ] Google Play Store submission

---

## Phase 4: Enterprise (Weeks 17-24)

**Goal:** Enterprise features + multi-system support
**Priority:** 🟡 MEDIUM - Enterprise market
**Timeline:** 8 weeks

### 4.1 Multi-System Support

**Competitor Feature:** ServiceTrade ✅ | Streamline ✅

Expand beyond fire extinguishers to full fire safety systems:

**Fire Alarms (NFPA 72):**
- [ ] 🟡 FireAlarms table
- [ ] 🟡 AlarmInspections table
- [ ] 🟡 NFPA 72 checklist templates
  - [ ] Alarm control panel inspection
  - [ ] Detector testing
  - [ ] Notification device testing
  - [ ] Backup power testing
  - [ ] Communication path testing

**Fire Sprinklers (NFPA 25):**
- [ ] 🟡 FireSprinklerSystems table
- [ ] 🟡 SprinklerInspections table
- [ ] 🟡 NFPA 25 checklist templates
  - [ ] Sprinkler head inspection
  - [ ] Valve inspection
  - [ ] Pipe inspection
  - [ ] Flow testing
  - [ ] Pump testing

**Fire Pumps (NFPA 20):**
- [ ] 🟡 FirePumps table
- [ ] 🟡 PumpInspections table
- [ ] 🟡 NFPA 20 checklist templates
  - [ ] Weekly churn test
  - [ ] Annual flow test
  - [ ] Pump performance test

**Emergency Lighting:**
- [ ] 🟡 EmergencyLights table
- [ ] 🟡 EmergencyLightInspections table
- [ ] 🟡 Checklist templates
  - [ ] Monthly 30-second test
  - [ ] Annual 90-minute discharge test

### 4.2 White-Label & SSO (Enterprise)

**Backend:**
- [ ] 🟡 TenantBranding table
  ```sql
  BrandingId UNIQUEIDENTIFIER PK
  TenantId UNIQUEIDENTIFIER FK
  LogoUrl NVARCHAR(500)
  FaviconUrl NVARCHAR(500)
  PrimaryColor NVARCHAR(20)
  SecondaryColor NVARCHAR(20)
  CustomDomain NVARCHAR(200) -- e.g., inspections.clientcompany.com
  HidePoweredBy BIT
  ```

- [ ] 🟡 SSO Integration
  - [ ] SAML 2.0 support
  - [ ] Azure AD integration
  - [ ] Okta integration
  - [ ] Google Workspace
  - [ ] Custom OIDC providers

**Frontend:**
- [ ] 🟡 White-label branding support
  - [ ] Dynamic logo/colors from tenant config
  - [ ] Custom domain routing
  - [ ] Hide "Powered by FireProof" (enterprise tier)

### 4.3 Technician Management & Dispatch

**Competitor Feature:** Uptick ✅ | ServiceTrade ✅

**Backend:**
- [ ] 🟡 Technicians table
  ```sql
  TechnicianId UNIQUEIDENTIFIER PK
  UserId UNIQUEIDENTIFIER FK
  CertificationNumber NVARCHAR(100)
  CertificationExpiry DATE
  Specializations NVARCHAR(MAX) -- JSON array
  HourlyRate DECIMAL(10,2)
  IsActive BIT
  ```

- [ ] 🟡 TechnicianSchedule table (availability tracking)
- [ ] 🟡 Route optimization
  - [ ] Assign inspections to technicians
  - [ ] Optimize travel routes (Google Maps Directions API)
  - [ ] Estimated completion time
  - [ ] Real-time GPS tracking

**Frontend:**
- [ ] 🟡 TechniciansView
  - [ ] List technicians
  - [ ] Calendar view (availability)
  - [ ] Assign inspections
  - [ ] Track certifications
  - [ ] Performance metrics (inspections/day, deficiencies found)

### 4.4 Advanced Reporting

**Backend:**
- [ ] 🟡 Report templates
  - [ ] Compliance audit report
  - [ ] Customer invoice report
  - [ ] Technician performance report
  - [ ] Revenue by location report
  - [ ] Equipment lifecycle report
  - [ ] Deficiency trends report

- [ ] 🟡 Scheduled reports
  - [ ] Email reports on schedule (daily, weekly, monthly)
  - [ ] Auto-generate compliance reports for AHJs (Authorities Having Jurisdiction)
  - [ ] Customer automatic delivery

**Frontend:**
- [ ] 🟡 Custom report builder
  - [ ] Drag-and-drop interface
  - [ ] Select data sources
  - [ ] Choose visualizations
  - [ ] Save custom reports
  - [ ] Schedule automated delivery

---

## Pricing Strategy

Based on competitive analysis and market positioning:

### Freemium Tier (FREE)
**Goal:** Attract small businesses and facility managers

- ✅ Single location
- ✅ Up to 50 extinguishers
- ✅ Basic inspections (monthly, annual)
- ✅ PDF reports
- ✅ Email reminders
- ✅ Mobile PWA access
- ❌ Customer portal
- ❌ Advanced analytics
- ❌ API access
- ❌ AI features

**Target:** Small facilities, churches, schools

---

### Professional Tier: **$49/month**
**Competitive:** Below Array ($30/user), similar to Fulcrum ($15-30/user)

- ✅ Up to 5 locations
- ✅ Up to 500 extinguishers
- ✅ All inspection types (monthly, annual, 6-year, 12-year, hydrostatic)
- ✅ Custom checklists
- ✅ All report formats (PDF, Excel, CSV)
- ✅ Priority email support
- ✅ Basic analytics dashboard
- ✅ Email & SMS reminders
- ✅ Mobile PWA + Native apps (when available)
- ❌ Customer portal
- ❌ API access
- ❌ AI features

**Target:** Small inspection companies, multi-location facilities

---

### Business Tier: **$149/month**
**Competitive:** Below InspectNTrack ($249/month), similar to Firebug EXT mid-tier

- ✅ Unlimited locations
- ✅ Unlimited extinguishers
- ✅ Customer portal
- ✅ Advanced analytics (20+ dashboards)
- ✅ Quoting & invoicing
- ✅ Service agreements
- ✅ API access (REST API)
- ✅ Phone support
- ✅ **AI-powered scheduling** (UNIQUE)
- ✅ **Predictive maintenance alerts** (UNIQUE)
- ✅ Accounting integrations (QuickBooks, Xero)
- ✅ Custom branding (logo, colors)
- ❌ White-label (no custom domain)
- ❌ SSO

**Target:** Mid-size inspection companies, enterprise facilities

---

### Enterprise Tier: **Custom Pricing**
**Competitive:** Match Uptick, ServiceTrade enterprise offerings

- ✅ Everything in Business tier
- ✅ Multi-system support (alarms, sprinklers, pumps, lighting)
- ✅ White-label (custom domain, remove branding)
- ✅ SSO (SAML, Azure AD, Okta)
- ✅ Dedicated account manager
- ✅ SLA guarantee (99.9% uptime)
- ✅ Custom integrations
- ✅ Advanced API (webhooks, rate limits)
- ✅ Training & onboarding
- ✅ Custom report templates
- ✅ Multi-tenant management (for service providers)

**Target:** Large inspection companies, enterprise corporations, government

---

### Add-Ons (All Tiers)
- **Additional users:** $10/user/month (beyond base)
- **SMS notifications:** $0.05/SMS (volume pricing)
- **Advanced AI features:** $29/month (anomaly detection, predictive maintenance)
- **Native mobile apps:** Included in Professional+ (when available)

---

## Success Metrics

### Phase 1 Success Criteria (MVP)
- [ ] 🔴 Complete end-to-end inspection workflow functional
- [ ] 🔴 NFPA 10 monthly inspection template working
- [ ] 🔴 Mobile-optimized UI tested on iOS and Android browsers
- [ ] 🔴 Offline inspection queue working
- [ ] 🔴 PDF report generation functional
- [ ] 🔴 Automated reminders sending successfully
- [ ] 🔴 10 beta testers complete 100 inspections combined
- [ ] 🔴 No critical bugs in production

**Timeline:** 4 weeks
**Go/No-Go:** Must pass all criteria before Phase 2

### Phase 2 Success Criteria (Business Features)
- [ ] 🟠 Customer portal live
- [ ] 🟠 Quoting & invoicing functional
- [ ] 🟠 Analytics dashboard with real-time data
- [ ] 🟠 QuickBooks integration tested
- [ ] 🟠 5 paying customers acquired
- [ ] 🟠 $1,000 MRR (Monthly Recurring Revenue)
- [ ] 🟠 Customer satisfaction score > 8/10

**Timeline:** 4 weeks
**Go/No-Go:** Must achieve $1,000 MRR before Phase 3

### Phase 3 Success Criteria (AI & Native Apps)
- [ ] 🟠 AI model accuracy > 85% (risk prediction)
- [ ] 🟠 AI recommendations accepted by users > 60% of time
- [ ] 🟠 Native iOS app approved on App Store
- [ ] 🟠 Native Android app approved on Google Play
- [ ] 🟠 500 inspections completed via native apps
- [ ] 🟠 10 paying customers
- [ ] 🟠 $5,000 MRR

**Timeline:** 8 weeks

### Phase 4 Success Criteria (Enterprise)
- [ ] 🟡 Multi-system support live (alarms, sprinklers, pumps)
- [ ] 🟡 White-label customer deployed
- [ ] 🟡 SSO integration tested (Azure AD + Okta)
- [ ] 🟡 1 enterprise customer ($500+/month)
- [ ] 🟡 $10,000 MRR
- [ ] 🟡 20 total paying customers

**Timeline:** 8 weeks

---

## Priority Legend

- 🔴 **P0 (Critical):** Blocker - must complete before proceeding
- 🟠 **P1 (High):** Important - required for market competitiveness
- 🟡 **P2 (Medium):** Nice to have - enhances offering
- 🟢 **P3 (Low):** Future - can defer to later phases

---

## Notes

**Current Status:** Phase 1 foundation complete
**Next Sprint:** Phase 1.1 - Inspection workflow (backend tables + stored procedures)
**Estimated Time to MVP:** 4 weeks
**Estimated Time to Market-Ready:** 8 weeks
**Estimated Time to Market Leader:** 24 weeks

**Last Updated:** October 14, 2025
**Next Review:** Weekly during active development

---

**END OF ROADMAP**
