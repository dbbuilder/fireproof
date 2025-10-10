# FireProof - Implementation Checklist (TODO)

**Document Version:** 1.0  
**Last Updated:** October 8, 2025  
**Status:** Active Development

This document tracks the phased implementation of the Fire Extinguisher Inspection System. Tasks are organized by phase, section, and priority.

**Priority Levels:**
- 🔴 **P0 (Critical):** Blockers - must be completed before moving forward
- 🟠 **P1 (High):** Important - should be completed in current phase
- 🟡 **P2 (Medium):** Nice to have - can be deferred if needed
- 🟢 **P3 (Low):** Future enhancement - can be postponed to later phases

**Status Indicators:**
- ⬜ Not Started
- 🔄 In Progress
- ✅ Completed
- ⏸️ Blocked
- ❌ Cancelled

---

## Phase 1.1: Foundation (Weeks 1-2)

### 🎯 Phase Objectives
- Set up Azure infrastructure
- Create database schema with multi-tenancy
- Build basic .NET API skeleton
- Create Vue.js frontend skeleton
- Establish CI/CD pipelines

### Azure Infrastructure Setup

#### Resource Provisioning
- ⬜ 🔴 Create Azure resource group (rg-fireproof-dev)
- ⬜ 🔴 Create Azure App Service Plan (Linux, B1)
- ⬜ 🔴 Create Azure App Service for API
- ⬜ 🔴 Create Azure SQL Database (S1)
- ⬜ 🔴 Create Azure Storage Account
- ⬜ 🔴 Create Azure Key Vault
- ⬜ 🟠 Create Azure Application Insights
- ⬜ 🟡 Configure Azure AD B2C tenant
- ⬜ 🟡 Create service principal for CI/CD
- ⬜ 🟢 Setup Azure Front Door (optional for dev)

#### Environment Configuration
- ⬜ 🔴 Configure Key Vault access policies
- ⬜ 🔴 Store connection strings in Key Vault
- ⬜ 🔴 Configure App Service application settings
- ⬜ 🟠 Setup Application Insights instrumentation key
- ⬜ 🟡 Configure custom domain (if applicable)
- ⬜ 🟡 Setup SSL certificates

### Database Schema Creation

#### Core Schema (dbo)
- ⬜ 🔴 Create `dbo.Tenants` table
- ⬜ 🔴 Create `dbo.Users` table
- ⬜ 🔴 Create `dbo.UserTenantRoles` table
- ⬜ 🔴 Create `dbo.AuditLog` table
- ⬜ 🟠 Create indexes on core tables
- ⬜ 🟠 Add foreign key constraints
- ⬜ 🟡 Implement Row-Level Security (RLS)

#### Tenant Schema Template
- ⬜ 🔴 Create stored procedure to generate tenant schema
- ⬜ 🔴 Create `Locations` table template
- ⬜ 🔴 Create `ExtinguisherTypes` table template
- ⬜ 🔴 Create `Extinguishers` table template
- ⬜ 🔴 Create `InspectionTypes` table template
- ⬜ 🔴 Create `InspectionChecklistTemplates` table template
- ⬜ 🔴 Create `ChecklistItems` table template
- ⬜ 🔴 Create `Inspections` table template
- ⬜ 🔴 Create `InspectionChecklistResponses` table template
- ⬜ 🔴 Create `InspectionPhotos` table template
- ⬜ 🟠 Create `MaintenanceRecords` table template
- ⬜ 🟠 Add indexes on tenant tables
- ⬜ 🟠 Add foreign key constraints

#### Stored Procedures
- ⬜ 🔴 `usp_Tenant_Create` - Create new tenant with schema
- ⬜ 🔴 `usp_Tenant_GetById` - Retrieve tenant details
- ⬜ 🔴 `usp_User_Create` - Create new user
- ⬜ 🔴 `usp_User_GetByEmail` - Retrieve user by email
- ⬜ 🔴 `usp_UserTenantRole_Assign` - Assign role to user
- ⬜ 🔴 `usp_UserTenantRole_GetByUser` - Get user's tenant roles
- ⬜ 🟠 `usp_AuditLog_Insert` - Log audit entry
- ⬜ 🟡 `usp_Tenant_Update` - Update tenant details
- ⬜ 🟡 `usp_Tenant_Deactivate` - Deactivate tenant

#### Seed Data
- ⬜ 🟠 Create sample tenant for development
- ⬜ 🟠 Create test users with various roles
- ⬜ 🟡 Insert common extinguisher types
- ⬜ 🟡 Insert standard inspection types
- ⬜ 🟡 Create sample inspection checklist templates

### .NET API Backend

#### Project Setup
- ⬜ 🔴 Create .NET 8.0 Web API project
- ⬜ 🔴 Configure project structure (Controllers, Services, Data, etc.)
- ⬜ 🔴 Install NuGet packages:
  - Microsoft.EntityFrameworkCore.SqlServer
  - Microsoft.Data.SqlClient
  - Serilog.AspNetCore
  - Serilog.Sinks.ApplicationInsights
  - Azure.Identity
  - Azure.Storage.Blobs
  - Azure.Security.KeyVault.Secrets
  - Polly
  - Hangfire
  - Swashbuckle.AspNetCore
  - Microsoft.AspNetCore.Authentication.JwtBearer
- ⬜ 🔴 Create appsettings.json structure
- ⬜ 🔴 Create appsettings.Development.json
- ⬜ 🟠 Setup .editorconfig for code style

#### Core Infrastructure
- ⬜ 🔴 Implement `IDbConnectionFactory` interface
- ⬜ 🔴 Implement `DbConnectionFactory` with Key Vault integration
- ⬜ 🔴 Configure Serilog with Application Insights sink
- ⬜ 🔴 Create `ErrorHandlingMiddleware`
- ⬜ 🔴 Create `TenantResolutionMiddleware`
- ⬜ 🟠 Create `RequestLoggingMiddleware`
- ⬜ 🟠 Configure CORS policies
- ⬜ 🟡 Implement rate limiting middleware

#### Authentication & Authorization
- ⬜ 🔴 Configure JWT Bearer authentication
- ⬜ 🔴 Integrate Azure AD B2C
- ⬜ 🔴 Implement claims transformation
- ⬜ 🔴 Create authorization policies for roles
- ⬜ 🟠 Implement token refresh mechanism
- ⬜ 🟡 Add device fingerprinting

#### Services Layer
- ⬜ 🔴 Create `ITenantService` interface
- ⬜ 🔴 Implement `TenantService` with SP calls
- ⬜ 🟠 Add error handling and logging to all services
- ⬜ 🟠 Implement Polly retry policies

#### API Controllers
- ⬜ 🔴 Create `AuthController` (login, refresh, logout)
- ⬜ 🔴 Create `TenantsController` (basic CRUD)
- ⬜ 🟠 Add Swagger documentation to controllers
- ⬜ 🟠 Add request validation
- ⬜ 🟡 Implement API versioning

#### Configuration
- ⬜ 🔴 Setup dependency injection in Program.cs
- ⬜ 🔴 Configure Swagger/OpenAPI
- ⬜ 🔴 Configure health checks
- ⬜ 🟠 Setup Hangfire dashboard
- ⬜ 🟡 Configure response compression

### Vue.js Frontend

#### Project Setup
- ⬜ 🔴 Create Vue 3 project with Vite
- ⬜ 🔴 Install dependencies:
  - vue-router
  - pinia
  - axios
  - tailwindcss
  - @headlessui/vue
  - @heroicons/vue
  - html5-qrcode
  - qrcode
  - date-fns
- ⬜ 🔴 Configure Tailwind CSS
- ⬜ 🔴 Setup project structure (components, views, stores, services)
- ⬜ 🟠 Configure ESLint and Prettier

#### Core Setup
- ⬜ 🔴 Configure Vue Router with routes
- ⬜ 🔴 Create Pinia store structure
- ⬜ 🔴 Create Axios instance with interceptors
- ⬜ 🔴 Implement JWT token handling
- ⬜ 🟠 Configure environment variables (.env files)
- ⬜ 🟡 Setup PWA manifest and service worker

#### Authentication
- ⬜ 🔴 Create Login view
- ⬜ 🔴 Implement auth store (Pinia)
- ⬜ 🔴 Create auth service for API calls
- ⬜ 🔴 Implement route guards
- ⬜ 🟠 Add token refresh logic
- ⬜ 🟡 Implement "Remember Me" functionality

#### Common Components
- ⬜ 🔴 Create AppHeader component
- ⬜ 🔴 Create AppSidebar component
- ⬜ 🔴 Create LoadingSpinner component
- ⬜ 🔴 Create ErrorAlert component
- ⬜ 🟠 Create SuccessToast component
- ⬜ 🟡 Create ConfirmDialog component

#### Views
- ⬜ 🔴 Create Dashboard view (placeholder)
- ⬜ 🔴 Create Login view (functional)
- ⬜ 🟡 Create Settings view (placeholder)

### CI/CD Pipeline

#### GitHub Actions Setup
- ⬜ 🔴 Create `.github/workflows/deploy-api.yml`
- ⬜ 🔴 Configure API build and test steps
- ⬜ 🔴 Configure API deployment to Azure
- ⬜ 🔴 Create `.github/workflows/deploy-frontend.yml`
- ⬜ 🔴 Configure frontend build steps
- ⬜ 🔴 Configure frontend deployment to Vercel/Azure
- ⬜ 🟠 Add automated testing to pipeline
- ⬜ 🟡 Add security scanning (CodeQL)

#### GitHub Repository Configuration
- ⬜ 🔴 Configure GitHub secrets (Azure credentials, connection strings)
- ⬜ 🟠 Setup branch protection rules
- ⬜ 🟡 Configure pull request templates

---

## Phase 1.2: Core Features (Weeks 3-5)

### 🎯 Phase Objectives
- Implement location management
- Implement extinguisher management
- Add barcode generation and scanning (web)
- Build basic inspection workflow
- Implement photo capture and storage

### Location Management

#### Backend - Stored Procedures
- ⬜ 🔴 `usp_Location_Create` - Create location
- ⬜ 🔴 `usp_Location_GetAll` - List locations by tenant
- ⬜ 🔴 `usp_Location_GetById` - Get location details
- ⬜ 🔴 `usp_Location_Update` - Update location
- ⬜ 🔴 `usp_Location_Delete` - Soft delete location
- ⬜ 🟠 `usp_Location_GetExtinguishers` - Get extinguishers by location
- ⬜ 🟡 `usp_Location_GetByBarcode` - Find location by barcode

#### Backend - Services
- ⬜ 🔴 Create `ILocationService` interface
- ⬜ 🔴 Implement `LocationService`
- ⬜ 🔴 Add GPS coordinate validation
- ⬜ 🟠 Add address geocoding (Azure Maps API)
- ⬜ 🟡 Implement location search/filter

#### Backend - API Endpoints
- ⬜ 🔴 `GET /api/locations` - List locations
- ⬜ 🔴 `POST /api/locations` - Create location
- ⬜ 🔴 `GET /api/locations/{id}` - Get location
- ⬜ 🔴 `PUT /api/locations/{id}` - Update location
- ⬜ 🔴 `DELETE /api/locations/{id}` - Delete location
- ⬜ 🟠 `GET /api/locations/{id}/extinguishers` - List extinguishers
- ⬜ 🟡 `POST /api/locations/{id}/generate-barcode` - Generate QR code

#### Frontend - Components
- ⬜ 🔴 Create LocationList component
- ⬜ 🔴 Create LocationForm component
- ⬜ 🔴 Create LocationDetails component
- ⬜ 🟠 Create LocationMap component (optional)
- ⬜ 🟡 Create LocationSearch component

#### Frontend - Views & Store
- ⬜ 🔴 Create Locations view
- ⬜ 🔴 Create locations Pinia store
- ⬜ 🔴 Create location service for API calls
- ⬜ 🟠 Add form validation
- ⬜ 🟡 Add pagination for large lists

### Extinguisher Management

#### Backend - Stored Procedures
- ⬜ 🔴 `usp_ExtinguisherType_GetAll` - List extinguisher types
- ⬜ 🔴 `usp_Extinguisher_Create` - Create extinguisher
- ⬜ 🔴 `usp_Extinguisher_GetAll` - List extinguishers by tenant
- ⬜ 🔴 `usp_Extinguisher_GetById` - Get extinguisher details
- ⬜ 🔴 `usp_Extinguisher_Update` - Update extinguisher
- ⬜ 🔴 `usp_Extinguisher_Delete` - Soft delete extinguisher
- ⬜ 🔴 `usp_Extinguisher_GetByBarcode` - Find by barcode
- ⬜ 🟠 `usp_Extinguisher_GetInspectionHistory` - Get inspections
- ⬜ 🟡 `usp_Extinguisher_Transfer` - Transfer to new location

#### Backend - Services
- ⬜ 🔴 Create `IExtinguisherService` interface
- ⬜ 🔴 Implement `ExtinguisherService`
- ⬜ 🔴 Create `IBarcodeService` interface
- ⬜ 🔴 Implement `BarcodeService` (QR code generation)
- ⬜ 🟠 Add barcode validation logic
- ⬜ 🟡 Implement bulk import from CSV/Excel

#### Backend - API Endpoints
- ⬜ 🔴 `GET /api/extinguishers` - List extinguishers
- ⬜ 🔴 `POST /api/extinguishers` - Create extinguisher
- ⬜ 🔴 `GET /api/extinguishers/{id}` - Get extinguisher
- ⬜ 🔴 `PUT /api/extinguishers/{id}` - Update extinguisher
- ⬜ 🔴 `DELETE /api/extinguishers/{id}` - Delete extinguisher
- ⬜ 🔴 `GET /api/extinguishers/scan/{barcode}` - Scan barcode
- ⬜ 🟠 `GET /api/extinguishers/{id}/history` - Inspection history
- ⬜ 🟡 `POST /api/extinguishers/bulk-import` - Bulk import

#### Frontend - Components
- ⬜ 🔴 Create ExtinguisherList component
- ⬜ 🔴 Create ExtinguisherForm component
- ⬜ 🔴 Create ExtinguisherDetails component
- ⬜ 🔴 Create BarcodeScanner component (Html5-QRCode)
- ⬜ 🟠 Create ExtinguisherHistory component
- ⬜ 🟡 Create BarcodeLabel component (printable)

#### Frontend - Views & Store
- ⬜ 🔴 Create Extinguishers view
- ⬜ 🔴 Create extinguishers Pinia store
- ⬜ 🔴 Create extinguisher service for API calls
- ⬜ 🔴 Implement barcode scanning workflow
- ⬜ 🟠 Add search and filter functionality
- ⬜ 🟡 Add bulk operations (delete, transfer)

### Barcode Generation & Scanning

#### Backend - Barcode Service
- ⬜ 🔴 Implement QR code generation (QRCoder library)
- ⬜ 🔴 Generate unique barcode data format
- ⬜ 🟠 Create barcode label PDF templates
- ⬜ 🟡 Implement batch barcode generation

#### Frontend - Scanning
- ⬜ 🔴 Integrate Html5-QRCode library
- ⬜ 🔴 Create camera permission handling
- ⬜ 🔴 Implement scan success/failure feedback
- ⬜ 🟠 Add manual barcode entry fallback
- ⬜ 🟡 Support multiple barcode formats (QR, Code 128, etc.)

### Basic Inspection Workflow

#### Backend - Stored Procedures
- ⬜ 🔴 `usp_InspectionType_GetAll` - List inspection types
- ⬜ 🔴 `usp_ChecklistTemplate_GetByType` - Get checklist
- ⬜ 🔴 `usp_Inspection_Create` - Create inspection
- ⬜ 🔴 `usp_Inspection_GetById` - Get inspection details
- ⬜ 🔴 `usp_Inspection_Update` - Update inspection
- ⬜ 🔴 `usp_InspectionResponse_CreateBatch` - Save checklist responses
- ⬜ 🟠 `usp_Inspection_GetAll` - List inspections by tenant
- ⬜ 🟠 `usp_Inspection_GetByExtinguisher` - Get by extinguisher
- ⬜ 🟡 `usp_Inspection_GetDue` - Get overdue inspections

#### Backend - Services
- ⬜ 🔴 Create `IInspectionService` interface
- ⬜ 🔴 Implement `InspectionService`
- ⬜ 🔴 Add inspection validation logic
- ⬜ 🟠 Calculate next inspection due dates
- ⬜ 🟡 Implement inspection scoring/rating

#### Backend - API Endpoints
- ⬜ 🔴 `GET /api/inspections` - List inspections
- ⬜ 🔴 `POST /api/inspections` - Create inspection
- ⬜ 🔴 `GET /api/inspections/{id}` - Get inspection
- ⬜ 🔴 `PUT /api/inspections/{id}` - Update inspection
- ⬜ 🔴 `POST /api/inspections/{id}/complete` - Complete inspection
- ⬜ 🟠 `GET /api/inspections/due` - Get due inspections
- ⬜ 🟡 `POST /api/inspections/sync-offline` - Sync offline inspections

#### Frontend - Components
- ⬜ 🔴 Create InspectionList component
- ⬜ 🔴 Create InspectionForm component
- ⬜ 🔴 Create ChecklistItem component
- ⬜ 🔴 Create InspectionSummary component
- ⬜ 🟠 Create InspectionHistory component
- ⬜ 🟡 Create InspectionTimeline component

#### Frontend - Views & Store
- ⬜ 🔴 Create Inspections view
- ⬜ 🔴 Create inspections Pinia store
- ⬜ 🔴 Create inspection service for API calls
- ⬜ 🔴 Implement inspection workflow (start → checklist → complete)
- ⬜ 🟠 Add GPS coordinate capture
- ⬜ 🟡 Add timer for inspection duration

### Photo Capture & Storage

#### Backend - Services
- ⬜ 🔴 Create `IBlobStorageService` interface
- ⬜ 🔴 Implement `AzureBlobStorageService`
- ⬜ 🔴 Add photo upload endpoint
- ⬜ 🟠 Implement photo compression
- ⬜ 🟠 Extract and validate EXIF data
- ⬜ 🟡 Add photo thumbnail generation

#### Backend - Stored Procedures
- ⬜ 🔴 `usp_InspectionPhoto_Create` - Save photo metadata
- ⬜ 🟠 `usp_InspectionPhoto_GetByInspection` - List photos

#### Backend - API Endpoints
- ⬜ 🔴 `POST /api/inspections/{id}/photos` - Upload photo
- ⬜ 🟠 `GET /api/inspections/{id}/photos` - List photos
- ⬜ 🟡 `DELETE /api/inspections/{id}/photos/{photoId}` - Delete photo

#### Frontend - Components
- ⬜ 🔴 Create PhotoCapture component
- ⬜ 🔴 Create PhotoGallery component
- ⬜ 🟠 Add photo preview before upload
- ⬜ 🟡 Implement photo annotation/markup

---

## Phase 1.3: Inspection & Tamper-Proofing (Weeks 6-7)

### 🎯 Phase Objectives
- Implement full inspection workflow with validation
- Add tamper-proofing with cryptographic signatures
- Build offline inspection queue with IndexedDB
- Implement GPS tracking and validation
- Create inspection history and audit trails

### Tamper-Proofing Implementation

#### Backend - Cryptography Service
- ⬜ 🔴 Create `ITamperProofingService` interface
- ⬜ 🔴 Implement HMAC-SHA256 signature generation
- ⬜ 🔴 Implement hash chain verification
- ⬜ 🔴 Create inspection data serialization
- ⬜ 🟠 Add device fingerprint generation
- ⬜ 🟡 Implement blockchain-style verification

#### Backend - Stored Procedures
- ⬜ 🔴 Update `usp_Inspection_Create` to include tamper hash
- ⬜ 🔴 `usp_Inspection_VerifyHash` - Verify inspection integrity
- ⬜ 🔴 `usp_Inspection_GetHashChain` - Get hash chain for extinguisher
- ⬜ 🟠 Add hash validation to all inspection queries

#### Backend - Integration
- ⬜ 🔴 Integrate tamper-proofing into InspectionService
- ⬜ 🔴 Generate hash on inspection creation
- ⬜ 🔴 Verify hash on inspection retrieval
- ⬜ 🟠 Add tamper detection alerts
- ⬜ 🟡 Create audit report for tampered inspections

### Offline Inspection Queue

#### Frontend - IndexedDB Setup
- ⬜ 🔴 Create IndexedDB schema for offline storage
- ⬜ 🔴 Implement offline storage service
- ⬜ 🔴 Add inspection queue management
- ⬜ 🟠 Implement data encryption for offline storage
- ⬜ 🟡 Add conflict resolution for offline edits

#### Frontend - Offline Workflow
- ⬜ 🔴 Detect online/offline status
- ⬜ 🔴 Queue inspections when offline
- ⬜ 🔴 Display offline indicator in UI
- ⬜ 🔴 Auto-sync when connection restored
- ⬜ 🟠 Show sync progress and status
- ⬜ 🟡 Implement manual sync trigger

#### Frontend - PWA Configuration
- ⬜ 🔴 Configure service worker for offline caching
- ⬜ 🔴 Add offline page fallback
- ⬜ 🟠 Implement background sync API
- ⬜ 🟡 Add install prompt for PWA

### GPS Tracking & Validation

#### Backend - GPS Service
- ⬜ 🔴 Add GPS coordinate validation logic
- ⬜ 🟠 Implement geofencing validation
- ⬜ 🟠 Calculate distance between GPS coordinates
- ⬜ 🟡 Add GPS accuracy thresholds

#### Frontend - GPS Capture
- ⬜ 🔴 Request geolocation permission
- ⬜ 🔴 Capture GPS coordinates during inspection
- ⬜ 🔴 Display GPS accuracy indicator
- ⬜ 🟠 Show location on map
- ⬜ 🟡 Add GPS spoofing detection

### Inspection History & Audit

#### Backend - Stored Procedures
- ⬜ 🔴 `usp_Inspection_GetHistory` - Complete inspection history
- ⬜ 🟠 `usp_Inspection_GetAuditTrail` - Detailed audit trail
- ⬜ 🟡 `usp_Inspection_CompareVersions` - Compare inspection versions

#### Frontend - History Components
- ⬜ 🔴 Create InspectionHistory component
- ⬜ 🟠 Create AuditTrail component
- ⬜ 🟡 Add timeline visualization

---

## Phase 1.4: Reporting & Jobs (Weeks 8-9)

### 🎯 Phase Objectives
- Build monthly and annual reports
- Create compliance dashboard
- Implement automated reminder system
- Add PDF report generation
- Implement export functionality (Excel, CSV)

### Reporting - Backend

#### Stored Procedures
- ⬜ 🔴 `usp_Report_MonthlyCompliance` - Monthly report data
- ⬜ 🔴 `usp_Report_AnnualCompliance` - Annual report data
- ⬜ 🔴 `usp_Report_OverdueInspections` - Overdue list
- ⬜ 🟠 `usp_Report_ComplianceByLocation` - Location breakdown
- ⬜ 🟠 `usp_Report_InspectorPerformance` - Inspector metrics
- ⬜ 🟡 `usp_Report_TrendAnalysis` - Trend over time

#### Services
- ⬜ 🔴 Create `IReportService` interface
- ⬜ 🔴 Implement `ReportService`
- ⬜ 🔴 Add report data aggregation logic
- ⬜ 🟠 Implement PDF generation with QuestPDF
- ⬜ 🟠 Add Excel export with EPPlus or ClosedXML
- ⬜ 🟡 Add CSV export

#### API Endpoints
- ⬜ 🔴 `GET /api/reports/monthly` - Monthly report
- ⬜ 🔴 `GET /api/reports/annual` - Annual report
- ⬜ 🔴 `GET /api/reports/compliance` - Compliance dashboard data
- ⬜ 🟠 `GET /api/reports/export/{format}` - Export in format (PDF/Excel/CSV)
- ⬜ 🟡 `POST /api/reports/schedule` - Schedule recurring report

### Reporting - Frontend

#### Components
- ⬜ 🔴 Create MonthlyReport component
- ⬜ 🔴 Create AnnualReport component
- ⬜ 🔴 Create ComplianceDashboard component
- ⬜ 🟠 Create ReportChart component (Chart.js integration)
- ⬜ 🟡 Create ReportFilters component

#### Views & Store
- ⬜ 🔴 Create Reports view
- ⬜ 🔴 Create Dashboard view (functional)
- ⬜ 🔴 Create reports Pinia store
- ⬜ 🔴 Create report service for API calls
- ⬜ 🟠 Add export button functionality
- ⬜ 🟡 Add print-friendly report layouts

### Background Jobs (Hangfire)

#### Job Setup
- ⬜ 🔴 Configure Hangfire server
- ⬜ 🔴 Setup Hangfire dashboard
- ⬜ 🟠 Configure job storage (SQL Server)

#### Job Implementations
- ⬜ 🔴 Create `InspectionReminderJob` - Send email reminders
- ⬜ 🔴 Schedule daily reminder job
- ⬜ 🟠 Create `ReportGenerationJob` - Auto-generate monthly reports
- ⬜ 🟠 Create `TenantCleanupJob` - Archive old data
- ⬜ 🟡 Create `DataBackupJob` - Backup important data
- ⬜ 🟡 Create `AnalyticsJob` - Aggregate analytics data

#### Email Notifications
- ⬜ 🔴 Configure email service (SendGrid or Azure Communication Services)
- ⬜ 🔴 Create email templates for reminders
- ⬜ 🟠 Add email unsubscribe functionality
- ⬜ 🟡 Implement email preferences per user

---

## Phase 1.5: Testing & Deployment (Week 10)

### 🎯 Phase Objectives
- Comprehensive testing (unit, integration, E2E)
- Performance optimization and load testing
- Production deployment to Azure
- Documentation and user guides
- User acceptance testing (UAT)

### Unit Testing

#### Backend Tests
- ⬜ 🔴 Write unit tests for TenantService
- ⬜ 🔴 Write unit tests for LocationService
- ⬜ 🔴 Write unit tests for ExtinguisherService
- ⬜ 🔴 Write unit tests for InspectionService
- ⬜ 🔴 Write unit tests for TamperProofingService
- ⬜ 🟠 Write unit tests for ReportService
- ⬜ 🟠 Achieve 70%+ code coverage

#### Frontend Tests
- ⬜ 🟠 Write component tests (Vue Test Utils)
- ⬜ 🟠 Write store tests (Pinia)
- ⬜ 🟡 Write service tests (mocked API)

### Integration Testing

#### API Integration Tests
- ⬜ 🔴 Test authentication endpoints
- ⬜ 🔴 Test location CRUD operations
- ⬜ 🔴 Test extinguisher CRUD operations
- ⬜ 🔴 Test inspection workflow
- ⬜ 🟠 Test reporting endpoints
- ⬜ 🟠 Test file upload/download
- ⬜ 🟡 Test error handling and edge cases

### End-to-End Testing

#### E2E Test Scenarios
- ⬜ 🔴 User registration and login
- ⬜ 🔴 Create location and add extinguishers
- ⬜ 🔴 Perform inspection (complete workflow)
- ⬜ 🔴 View reports and export data
- ⬜ 🟠 Offline inspection and sync
- ⬜ 🟡 User role permissions

#### E2E Test Setup
- ⬜ 🟠 Setup Playwright or Cypress
- ⬜ 🟠 Create test data seeding scripts
- ⬜ 🟡 Configure CI/CD for E2E tests

### Performance Testing

#### Load Testing
- ⬜ 🟠 Setup Azure Load Testing or JMeter
- ⬜ 🟠 Create load test scenarios (1000 concurrent users)
- ⬜ 🟠 Test API response times
- ⬜ 🟡 Test database query performance

#### Optimization
- ⬜ 🔴 Add database indexes for slow queries
- ⬜ 🟠 Implement caching (Redis optional)
- ⬜ 🟠 Optimize frontend bundle size
- ⬜ 🟡 Implement lazy loading for routes

### Production Deployment

#### Azure Production Environment
- ⬜ 🔴 Create production resource group
- ⬜ 🔴 Provision production Azure resources (P1V2, S3 SQL)
- ⬜ 🔴 Configure production Key Vault
- ⬜ 🔴 Setup production database with schemas
- ⬜ 🟠 Configure Azure Front Door
- ⬜ 🟠 Setup custom domain and SSL
- ⬜ 🟡 Configure geo-replication for disaster recovery

#### Deployment Process
- ⬜ 🔴 Deploy API to production App Service
- ⬜ 🔴 Deploy frontend to Vercel or Azure Static Web Apps
- ⬜ 🔴 Run database migrations in production
- ⬜ 🟠 Configure Application Insights alerts
- ⬜ 🟠 Setup monitoring dashboards
- ⬜ 🟡 Configure automated backups

#### Security Hardening
- ⬜ 🔴 Enable Azure AD authentication
- ⬜ 🔴 Configure firewall rules
- ⬜ 🟠 Enable DDoS protection
- ⬜ 🟠 Run security scan (OWASP ZAP)
- ⬜ 🟡 Configure Web Application Firewall (WAF)

### Documentation

#### Technical Documentation
- ⬜ 🔴 API documentation (Swagger/OpenAPI)
- ⬜ 🔴 Database schema documentation
- ⬜ 🟠 Deployment guide
- ⬜ 🟠 Architecture diagrams
- ⬜ 🟡 Contributing guidelines

#### User Documentation
- ⬜ 🔴 User guide for inspectors
- ⬜ 🔴 Admin guide for tenant setup
- ⬜ 🟠 Video tutorials (optional)
- ⬜ 🟡 FAQ and troubleshooting

### User Acceptance Testing
- ⬜ 🔴 Create UAT test plan
- ⬜ 🔴 Setup UAT environment
- ⬜ 🔴 Conduct UAT with stakeholders
- ⬜ 🟠 Document and fix UAT issues
- ⬜ 🟠 Get sign-off from stakeholders

---

## Phase 2.0: Native Mobile Apps (Months 4-6)

### 🎯 Phase Objectives
- Build native iOS app with Swift/SwiftUI
- Build native Android app with Kotlin/Jetpack Compose
- Implement offline-first architecture
- Add native barcode scanning
- Implement background sync and push notifications

### iOS App (Swift/SwiftUI)

#### Project Setup
- ⬜ 🔴 Create iOS project in Xcode
- ⬜ 🔴 Setup project structure (Views, ViewModels, Services, Models)
- ⬜ 🔴 Configure Swift Package Manager dependencies
- ⬜ 🟠 Setup Xcode schemes (Debug, Release)

#### Core Infrastructure
- ⬜ 🔴 Implement networking layer (URLSession)
- ⬜ 🔴 Implement Core Data models
- ⬜ 🔴 Create authentication service
- ⬜ 🔴 Implement offline sync manager
- ⬜ 🟠 Add Keychain for secure storage
- ⬜ 🟡 Implement biometric authentication

#### Features
- ⬜ 🔴 Login screen
- ⬜ 🔴 Dashboard view
- ⬜ 🔴 Location list and details
- ⬜ 🔴 Extinguisher list and details
- ⬜ 🔴 Barcode scanner (AVFoundation)
- ⬜ 🔴 Inspection form
- ⬜ 🔴 Photo capture (camera)
- ⬜ 🔴 GPS coordinate capture (Core Location)
- ⬜ 🟠 Reports view
- ⬜ 🟡 Settings view

#### Offline & Sync
- ⬜ 🔴 Implement offline inspection queue
- ⬜ 🔴 Background sync with BackgroundTasks framework
- ⬜ 🔴 Conflict resolution
- ⬜ 🟠 Network reachability monitoring

#### Push Notifications
- ⬜ 🟠 Setup Apple Push Notification service (APNs)
- ⬜ 🟠 Implement push notification handling
- ⬜ 🟡 Add notification preferences

#### Testing & Deployment
- ⬜ 🟠 Write unit tests (XCTest)
- ⬜ 🟠 Write UI tests (XCUITest)
- ⬜ 🔴 Configure App Store Connect
- ⬜ 🔴 Submit to App Store
- ⬜ 🟡 Setup TestFlight for beta testing

### Android App (Kotlin/Jetpack Compose)

#### Project Setup
- ⬜ 🔴 Create Android project in Android Studio
- ⬜ 🔴 Setup project structure (UI, ViewModel, Repository, Data)
- ⬜ 🔴 Configure Gradle dependencies
- ⬜ 🟠 Setup build variants (Debug, Release)

#### Core Infrastructure
- ⬜ 🔴 Implement networking layer (Retrofit + OkHttp)
- ⬜ 🔴 Implement Room database models
- ⬜ 🔴 Create authentication service
- ⬜ 🔴 Implement offline sync manager with WorkManager
- ⬜ 🟠 Add encrypted SharedPreferences
- ⬜ 🟡 Implement biometric authentication

#### Features
- ⬜ 🔴 Login screen (Composable)
- ⬜ 🔴 Dashboard screen
- ⬜ 🔴 Location list and details
- ⬜ 🔴 Extinguisher list and details
- ⬜ 🔴 Barcode scanner (CameraX + ML Kit)
- ⬜ 🔴 Inspection form
- ⬜ 🔴 Photo capture (CameraX)
- ⬜ 🔴 GPS coordinate capture (Location Services)
- ⬜ 🟠 Reports screen
- ⬜ 🟡 Settings screen

#### Offline & Sync
- ⬜ 🔴 Implement offline inspection queue
- ⬜ 🔴 Background sync with WorkManager
- ⬜ 🔴 Conflict resolution
- ⬜ 🟠 Network connectivity monitoring

#### Push Notifications
- ⬜ 🟠 Setup Firebase Cloud Messaging (FCM)
- ⬜ 🟠 Implement push notification handling
- ⬜ 🟡 Add notification channels and preferences

#### Testing & Deployment
- ⬜ 🟠 Write unit tests (JUnit)
- ⬜ 🟠 Write UI tests (Espresso)
- ⬜ 🔴 Configure Google Play Console
- ⬜ 🔴 Submit to Google Play Store
- ⬜ 🟡 Setup internal testing track

---

## Phase 2.5: Service Provider Multi-Tenancy (Months 7-8)

### 🎯 Phase Objectives
- Implement hierarchical multi-tenancy for service providers
- Allow 3rd party inspection companies to manage multiple sub-tenants
- Enable outside sales/implementation partners to operate software for clients
- Build consolidated management and reporting for providers
- Implement billing and revenue tracking systems

---

### **Feature Overview**

Implement a hierarchical multi-tenancy model that supports **Service Providers** who can manage multiple sub-tenants (institutions/customers). This allows 3rd party inspection companies, outside sales organizations, or managed service providers to operate and manage the software on behalf of multiple institutions.

### **Use Cases**
1. **3rd Party Inspection Companies**: Companies that provide inspection services to multiple institutions
2. **Outside Sales/Implementation Partners**: Organizations that sell, implement, and operate the software for multiple customers
3. **Managed Service Providers**: Companies that manage fire safety compliance for multiple client institutions
4. **White Label Providers**: Service providers offering branded solutions to their clients

---

### Database Schema - Service Provider Tables

#### Core Service Provider Schema
- ⬜ 🔴 Create `dbo.ServiceProviders` table
  - ServiceProviderId (PK)
  - ParentProviderId (FK, nullable - for provider hierarchies)
  - CompanyName, LegalBusinessName
  - TaxId, BusinessLicense
  - BrandingLogoUrl, BrandingColorPrimary, BrandingColorSecondary
  - CustomDomain (for white-label)
  - PrimaryContactEmail, PrimaryContactPhone
  - BillingEmail, BillingAddress
  - DefaultCommissionRate (decimal)
  - IsActive, IsApproved, ApprovedDate, ApprovedByUserId
  - ContractStartDate, ContractEndDate
  - CreatedDate, ModifiedDate, CreatedBy, ModifiedBy

- ⬜ 🔴 Create `dbo.ServiceProviderUsers` table
  - ServiceProviderUserId (PK)
  - ServiceProviderId (FK)
  - UserId (FK to dbo.Users)
  - ServiceProviderRole (enum: 'Admin', 'Manager', 'Inspector', 'Billing')
  - CanManageAllTenants (bit)
  - IsActive, HireDate, TerminationDate
  - CreatedDate, ModifiedDate

- ⬜ 🔴 Create `dbo.ServiceProviderTenants` table
  - ServiceProviderTenantId (PK)
  - ServiceProviderId (FK)
  - TenantId (FK)
  - RelationshipStartDate, RelationshipEndDate
  - BillingModel (enum: 'PerInspection', 'Monthly', 'Annual', 'PerExtinguisher', 'Tiered')
  - MonthlyRate, AnnualRate, PerInspectionRate
  - CommissionRate (decimal, overrides default)
  - ServiceLevelAgreement (JSON or separate table)
  - AutoRenewal (bit)
  - IsActive, IsPaused, PausedReason
  - CreatedDate, ModifiedDate

- ⬜ 🔴 Create `dbo.ServiceProviderContracts` table
  - ContractId (PK)
  - ServiceProviderId (FK)
  - TenantId (FK, nullable - master vs per-tenant contracts)
  - ContractType (enum: 'Master', 'TenantSpecific', 'Amendment')
  - ContractNumber, EffectiveDate, ExpirationDate
  - DocumentUrl (Azure Blob Storage)
  - SignedDate, SignedByName, SignedByEmail
  - TermsAndConditions (text)
  - IsActive, CreatedDate, ModifiedDate

- ⬜ 🟠 Create `dbo.ServiceProviderInvoices` table
  - InvoiceId (PK)
  - ServiceProviderId (FK)
  - TenantId (FK, nullable - could be aggregated)
  - InvoiceNumber, InvoiceDate, DueDate
  - BillingPeriodStart, BillingPeriodEnd
  - Subtotal, Tax, Total
  - Currency (default USD)
  - Status (enum: 'Draft', 'Sent', 'Paid', 'Overdue', 'Cancelled')
  - PaidDate, PaymentMethod
  - InvoiceDocumentUrl
  - CreatedDate, ModifiedDate

- ⬜ 🟠 Create `dbo.ServiceProviderInvoiceLineItems` table
  - LineItemId (PK)
  - InvoiceId (FK)
  - Description (e.g., "Inspection Services - October 2025")
  - Quantity, UnitPrice, Amount
  - TenantId (FK, nullable - for multi-tenant invoices)
  - InspectionId (FK, nullable - for inspection-based billing)
  - CreatedDate

- ⬜ 🟠 Create `dbo.ServiceProviderCommissions` table
  - CommissionId (PK)
  - ServiceProviderId (FK)
  - ServiceProviderUserId (FK, nullable - for inspector commissions)
  - InvoiceId (FK)
  - CommissionAmount
  - CommissionRate
  - Status (enum: 'Pending', 'Approved', 'Paid')
  - ApprovedDate, PaidDate
  - CreatedDate, ModifiedDate

- ⬜ 🟠 Create `dbo.ServiceProviderSLAMetrics` table
  - MetricId (PK)
  - ServiceProviderTenantId (FK)
  - MetricDate
  - InspectionsDue, InspectionsCompleted, InspectionsOverdue
  - SLACompliancePercentage
  - ResponseTime (hours to first inspection)
  - ResolutionTime (hours to complete inspection)
  - CustomerSatisfactionScore
  - CreatedDate

- ⬜ 🟡 Create `dbo.ServiceProviderPermissions` table
  - PermissionId (PK)
  - ServiceProviderId (FK)
  - TenantId (FK)
  - PermissionType (enum: 'Read', 'Write', 'Delete', 'ManageUsers', 'ViewReports', 'ManageBilling')
  - IsGranted (bit)
  - GrantedDate, GrantedBy
  - ExpiryDate (nullable)
  - CreatedDate, ModifiedDate

- ⬜ 🟡 Create `dbo.ServiceProviderBranding` table
  - BrandingId (PK)
  - ServiceProviderId (FK)
  - LogoUrl, FaviconUrl
  - PrimaryColor, SecondaryColor, AccentColor
  - FontFamily
  - CustomCSS (text, for advanced customization)
  - EmailTemplate (HTML)
  - ReportHeader (HTML)
  - ReportFooter (HTML)
  - CreatedDate, ModifiedDate

#### Indexes and Constraints
- ⬜ 🟠 Add indexes on ServiceProviderTenants (ServiceProviderId, TenantId, IsActive)
- ⬜ 🟠 Add indexes on ServiceProviderUsers (ServiceProviderId, UserId)
- ⬜ 🟠 Add indexes on ServiceProviderInvoices (ServiceProviderId, Status, InvoiceDate)
- ⬜ 🟠 Add foreign key constraints with appropriate cascading rules
- ⬜ 🟡 Add check constraints for date validations (EndDate > StartDate)

---

### Database - Stored Procedures

#### Service Provider Management
- ⬜ 🔴 `usp_ServiceProvider_Create` - Create new service provider with approval workflow
- ⬜ 🔴 `usp_ServiceProvider_GetById` - Get provider details with branding
- ⬜ 🔴 `usp_ServiceProvider_GetAll` - List all providers with filtering
- ⬜ 🔴 `usp_ServiceProvider_Update` - Update provider details
- ⬜ 🔴 `usp_ServiceProvider_Approve` - Approve/activate provider
- ⬜ 🔴 `usp_ServiceProvider_Deactivate` - Deactivate provider
- ⬜ 🟠 `usp_ServiceProvider_GetHierarchy` - Get provider hierarchy tree

#### Tenant Assignment
- ⬜ 🔴 `usp_ServiceProviderTenant_Create` - Assign tenant to provider
- ⬜ 🔴 `usp_ServiceProviderTenant_GetByProvider` - List provider's tenants
- ⬜ 🔴 `usp_ServiceProviderTenant_GetByTenant` - Get tenant's provider
- ⬜ 🔴 `usp_ServiceProviderTenant_Update` - Update relationship
- ⬜ 🔴 `usp_ServiceProviderTenant_Terminate` - End provider-tenant relationship
- ⬜ 🟠 `usp_ServiceProviderTenant_Transfer` - Transfer tenant between providers

#### User Management
- ⬜ 🔴 `usp_ServiceProviderUser_Create` - Add user to provider
- ⬜ 🔴 `usp_ServiceProviderUser_GetByProvider` - List provider users
- ⬜ 🔴 `usp_ServiceProviderUser_GetByUser` - Get user's provider affiliations
- ⬜ 🔴 `usp_ServiceProviderUser_AssignTenants` - Assign user to specific tenants
- ⬜ 🟠 `usp_ServiceProviderUser_GetWorkload` - Get inspector's workload across tenants

#### Billing & Invoicing
- ⬜ 🔴 `usp_ServiceProviderInvoice_Create` - Create invoice
- ⬜ 🔴 `usp_ServiceProviderInvoice_GetByProvider` - List provider invoices
- ⬜ 🔴 `usp_ServiceProviderInvoice_GetByTenant` - List tenant invoices
- ⬜ 🔴 `usp_ServiceProviderInvoice_CalculateBilling` - Calculate billing for period
- ⬜ 🔴 `usp_ServiceProviderInvoice_MarkPaid` - Mark invoice as paid
- ⬜ 🟠 `usp_ServiceProviderInvoice_GenerateLineItems` - Auto-generate from inspections
- ⬜ 🟠 `usp_ServiceProviderCommission_Calculate` - Calculate commissions
- ⬜ 🟡 `usp_ServiceProviderInvoice_SendReminder` - Get overdue invoices

#### Reporting & Analytics
- ⬜ 🔴 `usp_ServiceProvider_GetDashboard` - Provider dashboard metrics
- ⬜ 🔴 `usp_ServiceProvider_GetConsolidatedReport` - Cross-tenant report data
- ⬜ 🟠 `usp_ServiceProvider_GetRevenueReport` - Revenue by tenant/period
- ⬜ 🟠 `usp_ServiceProvider_GetSLACompliance` - SLA metrics per tenant
- ⬜ 🟠 `usp_ServiceProvider_GetInspectorPerformance` - Inspector metrics across tenants
- ⬜ 🟡 `usp_ServiceProvider_GetUsageAnalytics` - Usage patterns and trends

---

### Backend - .NET API Services

#### Service Provider Service
- ⬜ 🔴 Create `IServiceProviderService` interface
- ⬜ 🔴 Implement `ServiceProviderService`
  - CRUD operations for providers
  - Approval workflow
  - Branding management
  - Hierarchy management
- ⬜ 🟠 Add validation logic for provider data
- ⬜ 🟠 Implement provider status transitions
- ⬜ 🟡 Add bulk operations support

#### Service Provider Tenant Service
- ⬜ 🔴 Create `IServiceProviderTenantService` interface
- ⬜ 🔴 Implement `ServiceProviderTenantService`
  - Assign/unassign tenants
  - Manage relationships
  - Calculate billing
  - SLA tracking
- ⬜ 🟠 Add tenant transfer logic
- ⬜ 🟡 Implement relationship history tracking

#### Billing Service
- ⬜ 🔴 Create `IBillingService` interface
- ⬜ 🔴 Implement `BillingService`
  - Invoice generation
  - Line item calculation
  - Payment tracking
  - Commission calculation
- ⬜ 🟠 Integrate with Stripe or payment gateway
- ⬜ 🟠 Add PDF invoice generation
- ⬜ 🟡 Implement subscription management
- ⬜ 🟡 Add dunning management (overdue payment handling)

#### Contract Management Service
- ⬜ 🟠 Create `IContractService` interface
- ⬜ 🟠 Implement `ContractService`
  - Contract CRUD operations
  - Document storage integration
  - E-signature integration (DocuSign/HelloSign)
  - Contract renewal notifications
- ⬜ 🟡 Add contract template system
- ⬜ 🟡 Implement contract versioning

#### Service Provider Analytics Service
- ⬜ 🔴 Create `IServiceProviderAnalyticsService` interface
- ⬜ 🔴 Implement `ServiceProviderAnalyticsService`
  - Cross-tenant dashboards
  - Revenue analytics
  - Performance metrics
  - SLA compliance tracking
- ⬜ 🟠 Add predictive analytics (forecasting)
- ⬜ 🟡 Implement custom report builder

---

### Backend - API Endpoints

#### Service Provider Endpoints
- ⬜ 🔴 `GET /api/service-providers` - List all providers (admin)
- ⬜ 🔴 `POST /api/service-providers` - Create provider (registration)
- ⬜ 🔴 `GET /api/service-providers/{id}` - Get provider details
- ⬜ 🔴 `PUT /api/service-providers/{id}` - Update provider
- ⬜ 🔴 `POST /api/service-providers/{id}/approve` - Approve provider (admin)
- ⬜ 🔴 `DELETE /api/service-providers/{id}` - Deactivate provider
- ⬜ 🟠 `GET /api/service-providers/{id}/hierarchy` - Get provider hierarchy
- ⬜ 🟠 `PUT /api/service-providers/{id}/branding` - Update branding

#### Tenant Management Endpoints
- ⬜ 🔴 `GET /api/service-providers/{id}/tenants` - List provider's tenants
- ⬜ 🔴 `POST /api/service-providers/{id}/tenants` - Add tenant to provider
- ⬜ 🔴 `PUT /api/service-providers/{id}/tenants/{tenantId}` - Update relationship
- ⬜ 🔴 `DELETE /api/service-providers/{id}/tenants/{tenantId}` - Remove tenant
- ⬜ 🟠 `POST /api/service-providers/{id}/tenants/{tenantId}/transfer` - Transfer tenant

#### User Management Endpoints
- ⬜ 🔴 `GET /api/service-providers/{id}/users` - List provider users
- ⬜ 🔴 `POST /api/service-providers/{id}/users` - Add user to provider
- ⬜ 🔴 `PUT /api/service-providers/{id}/users/{userId}` - Update user role
- ⬜ 🔴 `DELETE /api/service-providers/{id}/users/{userId}` - Remove user
- ⬜ 🟠 `POST /api/service-providers/{id}/users/{userId}/assign-tenants` - Assign tenants

#### Inspection & Operations Endpoints
- ⬜ 🔴 `GET /api/service-providers/{id}/inspections` - All inspections across tenants
- ⬜ 🔴 `GET /api/service-providers/{id}/inspections/due` - Due inspections across all tenants
- ⬜ 🔴 `GET /api/service-providers/{id}/inspections/schedule` - Optimized inspection schedule
- ⬜ 🟠 `GET /api/service-providers/{id}/inspections/route` - Route optimization for inspectors
- ⬜ 🟡 `POST /api/service-providers/{id}/inspections/bulk-assign` - Bulk assign inspections

#### Billing & Invoicing Endpoints
- ⬜ 🔴 `GET /api/service-providers/{id}/invoices` - List invoices
- ⬜ 🔴 `POST /api/service-providers/{id}/invoices` - Create invoice
- ⬜ 🔴 `GET /api/service-providers/{id}/invoices/{invoiceId}` - Get invoice
- ⬜ 🔴 `PUT /api/service-providers/{id}/invoices/{invoiceId}` - Update invoice
- ⬜ 🔴 `POST /api/service-providers/{id}/invoices/{invoiceId}/send` - Send invoice
- ⬜ 🔴 `POST /api/service-providers/{id}/invoices/{invoiceId}/pay` - Record payment
- ⬜ 🟠 `GET /api/service-providers/{id}/billing/calculate` - Calculate billing for period
- ⬜ 🟠 `GET /api/service-providers/{id}/commissions` - Commission report
- ⬜ 🟡 `POST /api/service-providers/{id}/invoices/bulk-generate` - Bulk invoice generation

#### Reporting & Dashboard Endpoints
- ⬜ 🔴 `GET /api/service-providers/{id}/dashboard` - Provider dashboard data
- ⬜ 🔴 `GET /api/service-providers/{id}/reports/consolidated` - Cross-tenant compliance report
- ⬜ 🔴 `GET /api/service-providers/{id}/reports/revenue` - Revenue by tenant/period
- ⬜ 🟠 `GET /api/service-providers/{id}/reports/sla-compliance` - SLA metrics
- ⬜ 🟠 `GET /api/service-providers/{id}/reports/inspector-performance` - Inspector metrics
- ⬜ 🟠 `GET /api/service-providers/{id}/reports/tenant-summary` - Per-tenant summary
- ⬜ 🟡 `GET /api/service-providers/{id}/analytics/trends` - Usage and revenue trends
- ⬜ 🟡 `GET /api/service-providers/{id}/analytics/forecast` - Revenue forecasting

#### Contract Management Endpoints
- ⬜ 🟠 `GET /api/service-providers/{id}/contracts` - List contracts
- ⬜ 🟠 `POST /api/service-providers/{id}/contracts` - Create contract
- ⬜ 🟠 `GET /api/service-providers/{id}/contracts/{contractId}` - Get contract
- ⬜ 🟠 `PUT /api/service-providers/{id}/contracts/{contractId}` - Update contract
- ⬜ 🟡 `POST /api/service-providers/{id}/contracts/{contractId}/sign` - E-signature integration

---

### Frontend - Service Provider Portal

#### Provider Registration & Onboarding
- ⬜ 🔴 Create ServiceProviderRegistration view
- ⬜ 🔴 Create ServiceProviderOnboarding wizard component
- ⬜ 🔴 Create BrandingSetup component
- ⬜ 🟠 Add document upload for business license/insurance
- ⬜ 🟡 Add e-signature for master agreement

#### Provider Dashboard
- ⬜ 🔴 Create ProviderDashboard view
- ⬜ 🔴 Create TenantOverview component (list all managed tenants)
- ⬜ 🔴 Create ConsolidatedMetrics component (KPIs across all tenants)
- ⬜ 🔴 Create RevenueChart component
- ⬜ 🟠 Create SLAComplianceWidget component
- ⬜ 🟠 Create InspectorWorkloadWidget component
- ⬜ 🟡 Create PredictiveAnalytics component

#### Tenant Management UI
- ⬜ 🔴 Create TenantManagement view
- ⬜ 🔴 Create TenantList component (provider's tenants)
- ⬜ 🔴 Create TenantSelector component (switch context)
- ⬜ 🔴 Create AddTenantModal component
- ⬜ 🔴 Create TenantRelationshipForm component
- ⬜ 🟠 Create TenantTransferModal component
- ⬜ 🟡 Create BulkTenantOperations component

#### User & Inspector Management
- ⬜ 🔴 Create ProviderUserManagement view
- ⬜ 🔴 Create InspectorList component
- ⬜ 🔴 Create InspectorSchedule component (cross-tenant)
- ⬜ 🔴 Create TenantAssignment component (assign inspectors to tenants)
- ⬜ 🟠 Create InspectorPerformanceReport component
- ⬜ 🟡 Create WorkloadBalancer component (optimize assignments)

#### Inspection Operations
- ⬜ 🔴 Create ConsolidatedInspectionQueue view
- ⬜ 🔴 Create MultiTenantInspectionList component
- ⬜ 🔴 Create InspectionScheduleOptimizer component
- ⬜ 🟠 Create RouteOptimization component (GPS-based routing)
- ⬜ 🟠 Create BulkInspectionAssignment component
- ⬜ 🟡 Create InspectionHeatmap component (geographic view)

#### Billing & Invoicing UI
- ⬜ 🔴 Create BillingDashboard view
- ⬜ 🔴 Create InvoiceList component
- ⬜ 🔴 Create InvoiceDetails component
- ⬜ 🔴 Create GenerateInvoice component
- ⬜ 🔴 Create PaymentTracking component
- ⬜ 🟠 Create CommissionReport component
- ⬜ 🟠 Create RevenueByTenant component
- ⬜ 🟡 Create PaymentGatewayIntegration component (Stripe Elements)
- ⬜ 🟡 Create RecurringBillingSetup component

#### Reporting & Analytics
- ⬜ 🔴 Create ProviderReports view
- ⬜ 🔴 Create ConsolidatedComplianceReport component
- ⬜ 🔴 Create RevenueDashboard component
- ⬜ 🔴 Create SLAComplianceReport component
- ⬜ 🟠 Create CustomReportBuilder component
- ⬜ 🟠 Create TrendAnalysis component
- ⬜ 🟡 Create ForecastingDashboard component
- ⬜ 🟡 Create ExportToExcel component (consolidated exports)

#### Branding & White Label
- ⬜ 🟠 Create BrandingManagement view
- ⬜ 🟠 Create LogoUpload component
- ⬜ 🟠 Create ColorScheme component
- ⬜ 🟠 Create EmailTemplateEditor component
- ⬜ 🟡 Create ReportTemplateEditor component
- ⬜ 🟡 Create CustomDomainSetup component

#### Contract Management
- ⬜ 🟠 Create ContractManagement view
- ⬜ 🟠 Create ContractList component
- ⬜ 🟠 Create ContractDetails component
- ⬜ 🟡 Create ContractRenewalReminder component
- ⬜ 🟡 Create ESignatureIntegration component

---

### Frontend - Mobile App Enhancements

#### Multi-Tenant Inspector Experience
- ⬜ 🔴 Add TenantSwitcher component to mobile app
- ⬜ 🔴 Add CurrentTenant indicator in app header
- ⬜ 🔴 Update InspectionList to show tenant context
- ⬜ 🟠 Add cross-tenant search
- ⬜ 🟡 Add tenant-specific branding support

#### Inspector Assignment
- ⬜ 🔴 Create MyAssignments view (across all tenants)
- ⬜ 🔴 Add TenantFilter to assignment list
- ⬜ 🟠 Add RouteOptimization for daily inspections
- ⬜ 🟡 Add cross-tenant navigation optimization

---

### Authorization & Security

#### New Authorization Policies
- ⬜ 🔴 Create `ServiceProviderAdmin` policy
- ⬜ 🔴 Create `ServiceProviderManager` policy
- ⬜ 🔴 Create `ServiceProviderInspector` policy
- ⬜ 🔴 Create `ServiceProviderBilling` policy
- ⬜ 🟠 Implement cross-tenant authorization checks
- ⬜ 🟠 Add provider-level data isolation
- ⬜ 🟡 Implement granular permissions system

#### Claims Transformation
- ⬜ 🔴 Add `service_provider_id` claim
- ⬜ 🔴 Add `service_provider_role` claim
- ⬜ 🔴 Add `managed_tenant_ids` claim (array)
- ⬜ 🟠 Update JWT token generation for provider users
- ⬜ 🟠 Add tenant context switching claims

#### Middleware Updates
- ⬜ 🔴 Update `TenantResolutionMiddleware` to handle provider context
- ⬜ 🔴 Create `ServiceProviderResolutionMiddleware`
- ⬜ 🟠 Add provider-tenant validation middleware
- ⬜ 🟡 Implement audit logging for cross-tenant access

---

### Integration & Dependencies

#### Payment Gateway Integration (Stripe)
- ⬜ 🟠 Setup Stripe account and API keys
- ⬜ 🟠 Install Stripe .NET SDK
- ⬜ 🟠 Implement customer creation in Stripe
- ⬜ 🟠 Implement subscription management
- ⬜ 🟠 Implement invoice sync with Stripe
- ⬜ 🟠 Add webhook handlers for payment events
- ⬜ 🟡 Implement payment method management
- ⬜ 🟡 Add support for multiple currencies

#### E-Signature Integration (DocuSign/HelloSign)
- ⬜ 🟡 Setup DocuSign or HelloSign account
- ⬜ 🟡 Install SDK
- ⬜ 🟡 Implement contract sending workflow
- ⬜ 🟡 Add webhook handlers for signature events
- ⬜ 🟡 Store signed documents in Azure Blob Storage
- ⬜ 🟡 Add contract status tracking

#### Email & Communication
- ⬜ 🔴 Create email templates for provider notifications
  - New tenant assignment
  - Invoice generated
  - Payment received
  - SLA violation alerts
  - Contract renewal reminders
- ⬜ 🟠 Implement SendGrid template system
- ⬜ 🟠 Add email scheduling for reminders
- ⬜ 🟡 Add SMS notifications (Twilio)

#### Analytics & Reporting Integration
- ⬜ 🟠 Implement Power BI embedding for advanced analytics
- ⬜ 🟡 Add Google Analytics for provider portal usage
- ⬜ 🟡 Implement custom event tracking for billing events

#### Accounting Software Integration (Optional)
- ⬜ 🟡 QuickBooks Online integration
- ⬜ 🟡 Xero integration
- ⬜ 🟡 Automated invoice sync
- ⬜ 🟡 Payment reconciliation

---

### Background Jobs & Automation

#### Billing Automation Jobs
- ⬜ 🔴 Create `GenerateMonthlyInvoicesJob` - Auto-generate invoices
- ⬜ 🔴 Create `SendInvoiceRemindersJob` - Send payment reminders
- ⬜ 🔴 Create `CalculateCommissionsJob` - Calculate provider/inspector commissions
- ⬜ 🟠 Create `ProcessPaymentsJob` - Process recurring payments
- ⬜ 🟠 Create `SyncStripeInvoicesJob` - Sync with Stripe
- ⬜ 🟡 Create `HandleOverdueInvoicesJob` - Dunning management

#### SLA Monitoring Jobs
- ⬜ 🔴 Create `CalculateSLAMetricsJob` - Calculate daily SLA metrics
- ⬜ 🔴 Create `SendSLAViolationAlertsJob` - Alert on SLA violations
- ⬜ 🟠 Create `GenerateSLAReportsJob` - Weekly/monthly SLA reports

#### Contract Management Jobs
- ⬜ 🟠 Create `ContractRenewalReminderJob` - Alert on upcoming renewals
- ⬜ 🟡 Create `ContractExpirationJob` - Handle expired contracts
- ⬜ 🟡 Create `AutoRenewContractsJob` - Process auto-renewals

---

### Testing

#### Unit Tests
- ⬜ 🔴 Write unit tests for ServiceProviderService
- ⬜ 🔴 Write unit tests for ServiceProviderTenantService
- ⬜ 🔴 Write unit tests for BillingService
- ⬜ 🟠 Write unit tests for ContractService
- ⬜ 🟠 Write unit tests for ServiceProviderAnalyticsService
- ⬜ 🟠 Achieve 70%+ code coverage

#### Integration Tests
- ⬜ 🔴 Test provider registration and approval workflow
- ⬜ 🔴 Test tenant assignment and management
- ⬜ 🔴 Test invoice generation and calculation
- ⬜ 🔴 Test cross-tenant authorization
- ⬜ 🟠 Test billing calculations for various models
- ⬜ 🟠 Test commission calculations
- ⬜ 🟡 Test contract workflow

#### E2E Tests
- ⬜ 🔴 Provider registration → approval → tenant assignment → inspection → billing flow
- ⬜ 🟠 Multi-tenant inspector workflow
- ⬜ 🟡 White label branding verification

---

### Migration & Data Updates

#### Database Migrations
- ⬜ 🔴 Create migration script for all service provider tables
- ⬜ 🔴 Add foreign keys to existing tables
- ⬜ 🔴 Update existing stored procedures
- ⬜ 🟠 Create seed data for testing
- ⬜ 🟠 Add database indexes
- ⬜ 🟡 Create views for common reporting queries

#### Existing Table Updates
- ⬜ 🔴 Add `ServiceProviderId` to `dbo.Inspections` (nullable, FK)
- ⬜ 🔴 Add `PerformedByServiceProviderId` to track which provider performed inspection
- ⬜ 🟠 Add `ServiceProviderInvoiceId` to `dbo.Inspections` (for billing linkage)
- ⬜ 🟠 Update `dbo.Users` to support multi-provider affiliations
- ⬜ 🟡 Add audit fields to all new tables

---

### Documentation

#### Technical Documentation
- ⬜ 🔴 Service provider data model documentation
- ⬜ 🔴 Multi-tenancy architecture documentation
- ⬜ 🔴 API documentation for all provider endpoints
- ⬜ 🟠 Billing calculation logic documentation
- ⬜ 🟠 Integration guides (Stripe, DocuSign)
- ⬜ 🟡 White label setup guide

#### User Documentation
- ⬜ 🔴 Service provider admin guide
- ⬜ 🔴 Billing and invoicing guide
- ⬜ 🔴 Multi-tenant inspector guide
- ⬜ 🟠 Branding customization guide
- ⬜ 🟡 Contract management guide

#### Business Documentation
- ⬜ 🟠 Pricing models and examples
- ⬜ 🟠 SLA templates
- ⬜ 🟠 Contract templates
- ⬜ 🟡 Onboarding checklist for providers

---

### Performance & Optimization

#### Query Optimization
- ⬜ 🔴 Optimize cross-tenant queries
- ⬜ 🔴 Add database indexes for reporting queries
- ⬜ 🟠 Implement query result caching for dashboards
- ⬜ 🟡 Add read replicas for reporting workloads

#### Scalability
- ⬜ 🟠 Test with 100+ tenants per provider
- ⬜ 🟠 Test with 1000+ inspections per month
- ⬜ 🟡 Implement database partitioning for large datasets
- ⬜ 🟡 Add Redis caching for frequently accessed data

---

### Compliance & Legal

#### Data Privacy
- ⬜ 🔴 Implement data isolation between providers
- ⬜ 🔴 Add data access audit logging
- ⬜ 🟠 GDPR compliance for provider data
- ⬜ 🟠 Add data retention policies
- ⬜ 🟡 Implement right-to-be-forgotten for providers

#### Financial Compliance
- ⬜ 🟠 Add tax calculation support
- ⬜ 🟠 Generate tax reports (1099 for contractors)
- ⬜ 🟡 PCI compliance for payment processing
- ⬜ 🟡 SOC 2 compliance documentation

---

### Priority & Timeline

**Priority:** 🟡 P2 (Medium) - Implement after core inspection functionality is stable and tested

**Estimated Timeline:** 8-10 weeks

**Prerequisites:**
- ✅ Complete authentication system
- ⬜ Complete core inspection workflow
- ⬜ Complete reporting infrastructure
- ⬜ Complete role-based authorization
- ⬜ Complete billing system foundation

**Dependencies:**
- 🔴 P0 - Stripe integration (for billing)
- 🟠 P1 - Email notification system (for provider communications)
- 🟠 P1 - PDF generation (for invoices and contracts)
- 🟡 P2 - E-signature integration (for contracts)
- 🟡 P2 - Accounting software integration (optional)
- 🟡 P2 - Advanced analytics/reporting (Power BI)

---

### Future Enhancements (Phase 3+)

#### Advanced Features
- ⬜ 🟢 Implement provider marketplace (providers bid on tenant contracts)
- ⬜ 🟢 Add provider rating and review system
- ⬜ 🟢 Implement provider-to-provider sub-contracting
- ⬜ 🟢 Add AI-powered inspection scheduling optimization
- ⬜ 🟢 Implement predictive maintenance recommendations
- ⬜ 🟢 Add multi-language support for international providers
- ⬜ 🟢 Implement provider insurance verification and tracking
- ⬜ 🟢 Add provider certification and training tracking
- ⬜ 🟢 Implement automated route optimization with traffic data
- ⬜ 🟢 Add provider referral program

---

## Continuous Improvement

### Monitoring & Maintenance
- ⬜ 🟠 Setup Application Insights dashboards
- ⬜ 🟠 Configure alerting rules
- ⬜ 🟠 Monitor error rates and performance
- ⬜ 🟡 Implement A/B testing framework

### Security
- ⬜ 🟠 Regular security audits
- ⬜ 🟠 Dependency vulnerability scanning
- ⬜ 🟠 Penetration testing
- ⬜ 🟡 GDPR compliance audit

### Performance
- ⬜ 🟡 Regular performance reviews
- ⬜ 🟡 Database query optimization
- ⬜ 🟡 Frontend bundle optimization
- ⬜ 🟡 API response time improvements

---

## Notes

**Completed Tasks:** 0 / 400+  
**Phase 1.1 Progress:** 0%  
**Overall Progress:** 0%

**Last Updated:** October 8, 2025  
**Next Review:** Weekly during active development

**Sprint Planning:**
- Sprint duration: 2 weeks
- Daily standups recommended
- Weekly sprint reviews
- Retrospectives at end of each phase

---

## Legend

**Emoji Key:**
- ⬜ Not Started
- 🔄 In Progress
- ✅ Completed
- ⏸️ Blocked
- ❌ Cancelled

**Priority Key:**
- 🔴 P0 - Critical
- 🟠 P1 - High
- 🟡 P2 - Medium
- 🟢 P3 - Low
