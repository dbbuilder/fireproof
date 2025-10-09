# FireProof - Implementation TODO

## Document Overview
This TODO document outlines the complete implementation plan organized by phase, section, and priority. Each task includes acceptance criteria and estimated effort.

**Status Legend:**
- ⬜ Not Started
- 🟦 In Progress
- ✅ Completed
- ⚠️ Blocked

---

## Phase 1.1: Foundation (Weeks 1-2)

### Azure Infrastructure Setup

#### Azure Resources Provisioning
- ⬜ **Create Azure Resource Group** (1 hour)
  - Resource group name: `fireproof-rg`
  - Location: East US (or preferred region)
  - Tags: Environment=Production, Project=FireProof

- ⬜ **Provision Azure SQL Database** (2 hours)
  - Server name: `fireproof-sql-server`
  - Database name: `FireProofDB`
  - Tier: Standard S1 (initial), plan for S3 scaling
  - Firewall rules: Allow Azure services, add development IPs
  - Configure geo-replication backup
  - Enable Transparent Data Encryption (TDE)

- ⬜ **Create Azure App Service Plan** (1 hour)
  - Name: `fireproof-app-plan`
  - OS: Linux
  - Tier: B1 (dev), P1V2 (production)
  - Region: Same as resource group

- ⬜ **Provision Azure App Service** (1 hour)
  - Name: `fireproof-api`
  - Runtime: .NET 8.0
  - Enable HTTPS only
  - Configure custom domain (optional)
  - Enable Application Insights

- ⬜ **Create Azure Storage Account** (1 hour)
  - Name: `fireproofstorage` (globally unique)
  - Performance: Standard
  - Replication: LRS (dev), GRS (production)
  - Create container: `inspection-photos`
  - Configure lifecycle management (archive after 2 years)

- ⬜ **Provision Azure Key Vault** (1 hour)
  - Name: `fireproof-keyvault`
  - Enable soft delete and purge protection
  - Configure access policies for App Service
  - Add initial secrets (connection strings, API keys)

- ⬜ **Create Application Insights** (30 minutes)
  - Name: `fireproof-insights`
  - Link to App Service
  - Configure sampling rate
  - Set up availability tests

- ⬜ **Setup Azure AD B2C Tenant** (2 hours)
  - Create B2C tenant: `fireproof.onmicrosoft.com`
  - Configure sign-up/sign-in user flow
  - Setup MFA policies
  - Register API application
  - Configure scopes and permissions
  - Register web application
  - Test authentication flow

#### Acceptance Criteria
- All Azure resources created successfully
- Resources properly tagged and organized
- Firewall rules configured for secure access
- Monitoring and alerts enabled
- Estimated cost < $50/month for development

---

### Database Foundation

#### Core Schema Creation
- ⬜ **Execute 001_CreateCoreSchema.sql** (2 hours)
  - Create `dbo.Tenants` table
  - Create `dbo.Users` table
  - Create `dbo.UserTenantRoles` table
  - Create `dbo.AuditLog` table
  - Create all required indexes
  - Test Row-Level Security policies

- ⬜ **Execute 002_CreateTenantSchema.sql** (3 hours)
  - Create tenant schema template
  - Create `Locations` table
  - Create `ExtinguisherTypes` table
  - Create `Extinguishers` table
  - Create `InspectionTypes` table
  - Create `InspectionChecklistTemplates` table
  - Create `ChecklistItems` table
  - Create `Inspections` table
  - Create `InspectionChecklistResponses` table
  - Create `InspectionPhotos` table
  - Create `MaintenanceRecords` table
  - Test schema creation for sample tenant

- ⬜ **Execute 003_CreateStoredProcedures.sql** (4 hours)
  - Tenant management procedures
  - User management procedures
  - Location CRUD procedures
  - Extinguisher CRUD procedures
  - Inspection CRUD procedures
  - Reporting procedures
  - Audit log procedures
  - Test all procedures with sample data

- ⬜ **Execute 004_SeedData.sql** (1 hour)
  - Create sample tenant
  - Create sample users with roles
  - Create sample locations
  - Create sample extinguisher types
  - Create sample extinguishers
  - Create sample inspection types and templates
  - Verify data integrity

#### Acceptance Criteria
- Database schema deployed successfully
- All tables have proper indexes
- Stored procedures execute without errors
- Sample data populated for testing
- Foreign key constraints validated

---

### Backend API Foundation

#### Project Structure Setup
- ⬜ **Create .NET Solution and Projects** (1 hour)
  ```bash
  dotnet new sln -n FireExtinguisherInspection
  cd backend
  dotnet new webapi -n FireExtinguisherInspection.API --framework net8.0
  dotnet sln add FireExtinguisherInspection.API
  ```

- ⬜ **Install NuGet Packages** (30 minutes)
  ```bash
  # Core packages
  dotnet add package Microsoft.EntityFrameworkCore.SqlServer --version 8.0.0
  dotnet add package Microsoft.Data.SqlClient --version 5.1.0
  
  # Authentication
  dotnet add package Microsoft.Identity.Web --version 2.15.0
  
  # Logging
  dotnet add package Serilog.AspNetCore --version 8.0.0
  dotnet add package Serilog.Sinks.ApplicationInsights --version 4.0.0
  
  # Resilience
  dotnet add package Polly --version 8.0.0
  
  # Background Jobs
  dotnet add package Hangfire.AspNetCore --version 1.8.0
  dotnet add package Hangfire.SqlServer --version 1.8.0
  
  # Azure SDKs
  dotnet add package Azure.Storage.Blobs --version 12.19.0
  dotnet add package Azure.Identity --version 1.10.0
  dotnet add package Azure.Security.KeyVault.Secrets --version 4.5.0
  
  # Utilities
  dotnet add package Swashbuckle.AspNetCore --version 6.5.0
  ```

#### Core Infrastructure Files
- ⬜ **Create Program.cs** (2 hours)
  - Configure services (DI container)
  - Add authentication (JWT Bearer)
  - Add authorization policies
  - Configure Entity Framework
  - Add Serilog configuration
  - Add Hangfire configuration
  - Configure CORS
  - Add Swagger/OpenAPI
  - Configure middleware pipeline
  - Add error handling middleware

- ⬜ **Create appsettings.json** (30 minutes)
  - Connection strings (with Key Vault reference)
  - Azure AD B2C configuration
  - Blob Storage configuration
  - Application Insights configuration
  - Hangfire configuration
  - Logging configuration
  - CORS allowed origins

- ⬜ **Create Data/DbConnectionFactory.cs** (1 hour)
  - Implement `IDbConnectionFactory` interface
  - Connection string resolution from Key Vault
  - Connection pooling configuration
  - Error handling and logging
  - Unit tests

- ⬜ **Create Middleware/TenantResolutionMiddleware.cs** (2 hours)
  - Extract tenant ID from JWT claims
  - Set tenant context for request
  - Validate tenant exists and is active
  - Handle missing/invalid tenant gracefully
  - Unit tests

- ⬜ **Create Middleware/ErrorHandlingMiddleware.cs** (1 hour)
  - Catch unhandled exceptions
  - Log errors with context
  - Return appropriate HTTP status codes
  - Return consistent error response format
  - Unit tests

- ⬜ **Create Middleware/RequestLoggingMiddleware.cs** (1 hour)
  - Log request/response details
  - Calculate request duration
  - Include correlation IDs
  - Filter sensitive data from logs
  - Unit tests

#### Acceptance Criteria
- .NET project builds successfully
- All NuGet packages installed
- Middleware pipeline configured correctly
- Application starts without errors
- Swagger UI accessible at /swagger
- Health check endpoint returns 200 OK

---

### Authentication Implementation

#### Azure AD B2C Integration
- ⬜ **Create Infrastructure/Authentication/JwtBearerConfiguration.cs** (2 hours)
  - Configure JWT Bearer authentication
  - Set token validation parameters
  - Configure audience and issuer validation
  - Setup claims transformation
  - Add authentication event handlers
  - Unit tests

- ⬜ **Create Controllers/AuthController.cs** (3 hours)
  - `POST /api/auth/login` - User login
  - `POST /api/auth/refresh` - Refresh token
  - `POST /api/auth/logout` - User logout
  - `GET /api/auth/me` - Current user info
  - Input validation
  - Error handling
  - Integration tests

- ⬜ **Create Services/Implementations/AuthService.cs** (2 hours)
  - Implement `IAuthService` interface
  - User authentication logic
  - Token generation and validation
  - Refresh token rotation
  - Device fingerprinting
  - Unit tests

#### Acceptance Criteria
- Users can authenticate via Azure AD B2C
- JWT tokens issued successfully
- Token refresh works correctly
- Authentication errors handled gracefully
- Integration tests passing

---

### Basic CRUD Operations

#### Tenants Management
- ⬜ **Create Models/Entities/Tenant.cs** (30 minutes)
  - Define Tenant entity properties
  - Add validation attributes
  - Include navigation properties

- ⬜ **Create Models/Requests/CreateTenantRequest.cs** (30 minutes)
  - Define request DTO
  - Add validation attributes
  - Include all required fields

- ⬜ **Create Models/Responses/TenantResponse.cs** (30 minutes)
  - Define response DTO
  - Map entity to response
  - Include computed properties

- ⬜ **Create Services/Interfaces/ITenantService.cs** (30 minutes)
  - Define service contract
  - Include all CRUD methods
  - Add tenant provisioning methods

- ⬜ **Create Services/Implementations/TenantService.cs** (3 hours)
  - Implement `GetTenantByIdAsync`
  - Implement `CreateTenantAsync` (creates schema)
  - Implement `UpdateTenantAsync`
  - Implement `GetTenantUsersAsync`
  - Implement `AddUserToTenantAsync`
  - Implement `UpdateUserRoleAsync`
  - Error handling and logging
  - Unit tests

- ⬜ **Create Controllers/TenantsController.cs** (2 hours)
  - `GET /api/tenants/{tenantId}`
  - `POST /api/tenants`
  - `PUT /api/tenants/{tenantId}`
  - `GET /api/tenants/{tenantId}/users`
  - `POST /api/tenants/{tenantId}/users`
  - `PUT /api/tenants/{tenantId}/users/{userId}/role`
  - Authorization policies
  - Integration tests

#### Users Management
- ⬜ **Create Models/Entities/User.cs** (30 minutes)
- ⬜ **Create Services/Interfaces/IUserService.cs** (30 minutes)
- ⬜ **Create Services/Implementations/UserService.cs** (2 hours)
  - Implement user CRUD operations
  - Password hashing (if not using Azure AD B2C)
  - User search and filtering
  - Unit tests

#### Acceptance Criteria
- Tenant CRUD operations working
- User management functional
- Proper authorization enforced
- All tests passing
- API documented in Swagger

---

### Frontend Foundation

#### Vue.js Project Setup
- ⬜ **Create Vue.js Project** (1 hour)
  ```bash
  npm create vite@latest fire-extinguisher-web -- --template vue
  cd fire-extinguisher-web
  npm install
  ```

- ⬜ **Install Frontend Dependencies** (30 minutes)
  ```bash
  # Core dependencies
  npm install vue-router@4 pinia axios
  
  # UI Framework
  npm install -D tailwindcss@3 postcss autoprefixer
  npx tailwindcss init -p
  
  # Utilities
  npm install date-fns lodash
  npm install @vueuse/core
  
  # Barcode scanning
  npm install html5-qrcode
  npm install qrcode
  
  # PWA
  npm install -D vite-plugin-pwa
  
  # Dev dependencies
  npm install -D @vitejs/plugin-vue
  npm install -D eslint prettier
  ```

- ⬜ **Configure Tailwind CSS** (30 minutes)
  - Update tailwind.config.js with custom theme
  - Create base styles in src/assets/styles/main.css
  - Import Tailwind directives
  - Test utility classes

- ⬜ **Configure Vue Router** (1 hour)
  - Create router/index.js
  - Define initial routes
  - Setup route guards for authentication
  - Test navigation

- ⬜ **Configure Pinia Store** (1 hour)
  - Create stores/auth.js
  - Create stores/tenant.js
  - Setup state persistence (localStorage)
  - Test state management

- ⬜ **Configure Axios** (1 hour)
  - Create services/api.js
  - Setup base URL from env
  - Add request interceptor (auth token)
  - Add response interceptor (error handling)
  - Test API calls

- ⬜ **Configure PWA** (1 hour)
  - Add vite-plugin-pwa to vite.config.js
  - Create manifest.json
  - Configure service worker
  - Test offline functionality

#### Core Components
- ⬜ **Create src/components/common/AppHeader.vue** (1 hour)
  - Navigation menu
  - User profile dropdown
  - Tenant switcher
  - Responsive design

- ⬜ **Create src/components/common/AppSidebar.vue** (1 hour)
  - Navigation links
  - Role-based menu items
  - Collapse/expand functionality
  - Mobile drawer

- ⬜ **Create src/components/common/LoadingSpinner.vue** (30 minutes)
  - Animated spinner
  - Configurable size and color
  - Overlay option

- ⬜ **Create src/components/common/ErrorAlert.vue** (30 minutes)
  - Error message display
  - Dismissible alert
  - Different severity levels
  - Icon support

#### Core Views
- ⬜ **Create src/views/Login.vue** (2 hours)
  - Login form
  - Azure AD B2C integration
  - Remember me option
  - Error handling
  - Redirect after login

- ⬜ **Create src/views/Dashboard.vue** (2 hours)
  - Welcome message
  - Quick stats cards
  - Recent activity
  - Upcoming inspections
  - Responsive grid layout

#### Acceptance Criteria
- Vue.js project builds successfully
- Tailwind CSS working
- Routing functional
- State management working
- API integration functional
- PWA installable

---

### CI/CD Pipeline Setup

#### GitHub Actions Workflow
- ⬜ **Create .github/workflows/backend-ci.yml** (1 hour)
  - Trigger on push to main and PRs
  - .NET build and test
  - Code coverage report
  - Publish artifacts

- ⬜ **Create .github/workflows/backend-cd.yml** (1 hour)
  - Deploy to Azure App Service
  - Run database migrations
  - Health check after deployment
  - Rollback on failure

- ⬜ **Create .github/workflows/frontend-ci.yml** (1 hour)
  - Trigger on push to main and PRs
  - npm build and test
  - Lint checks
  - Build artifacts

- ⬜ **Create .github/workflows/frontend-cd.yml** (1 hour)
  - Deploy to Vercel
  - Environment-specific builds
  - Preview deployments for PRs

#### Acceptance Criteria
- CI pipelines run on every commit
- Tests must pass before merge
- CD deploys automatically on main branch
- Rollback mechanism tested

---

## Phase 1.2: Core Features (Weeks 3-5)

### Location Management

#### Backend Implementation
- ⬜ **Create Models/Entities/Location.cs** (30 minutes)
- ⬜ **Create Models/Requests/CreateLocationRequest.cs** (30 minutes)
- ⬜ **Create Models/Responses/LocationResponse.cs** (30 minutes)

- ⬜ **Create Services/Interfaces/ILocationService.cs** (30 minutes)
- ⬜ **Create Services/Implementations/LocationService.cs** (4 hours)
  - `GetLocationsAsync` - Get all locations for tenant
  - `GetLocationByIdAsync` - Get single location
  - `CreateLocationAsync` - Create new location
  - `UpdateLocationAsync` - Update location
  - `DeleteLocationAsync` - Soft delete location
  - `GetLocationExtinguishersAsync` - Get extinguishers at location
  - `GenerateLocationBarcodeAsync` - Generate QR code
  - GPS coordinate validation
  - Error handling and logging
  - Unit tests (80% coverage)

- ⬜ **Create Controllers/LocationsController.cs** (2 hours)
  - `GET /api/locations`
  - `GET /api/locations/{locationId}`
  - `POST /api/locations`
  - `PUT /api/locations/{locationId}`
  - `DELETE /api/locations/{locationId}`
  - `GET /api/locations/{locationId}/extinguishers`
  - `POST /api/locations/{locationId}/generate-barcode`
  - Pagination support
  - Filtering and sorting
  - Authorization checks
  - Integration tests

#### Frontend Implementation
- ⬜ **Create services/location.service.js** (1 hour)
  - API wrapper functions
  - Error handling
  - Response transformation

- ⬜ **Create stores/locations.js** (1 hour)
  - State: locations list, selected location, loading state
  - Actions: fetch, create, update, delete
  - Getters: filtered locations, location by ID
  - State persistence

- ⬜ **Create components/locations/LocationList.vue** (2 hours)
  - Table view with sorting
  - Search and filter
  - Pagination
  - Delete confirmation
  - Responsive design
  - Loading states

- ⬜ **Create components/locations/LocationForm.vue** (3 hours)
  - Create/edit form
  - Form validation
  - Address autocomplete (optional)
  - GPS coordinate picker
  - Image upload for location photo
  - Error handling
  - Success feedback

- ⬜ **Create components/locations/LocationMap.vue** (2 hours)
  - Map display using Leaflet or Google Maps
  - Location markers
  - Click to view details
  - Responsive design

- ⬜ **Create views/Locations.vue** (1 hour)
  - Page layout
  - Add location button
  - Location list component
  - Location map component
  - Breadcrumbs

#### Acceptance Criteria
- Locations can be created, viewed, edited, deleted
- GPS coordinates validated
- QR codes generated successfully
- Map displays locations correctly
- All tests passing

---

### Extinguisher Management

#### Backend Implementation
- ⬜ **Create Models/Entities/Extinguisher.cs** (30 minutes)
- ⬜ **Create Models/Entities/ExtinguisherType.cs** (30 minutes)
- ⬜ **Create Models/Requests/CreateExtinguisherRequest.cs** (30 minutes)
- ⬜ **Create Models/Responses/ExtinguisherResponse.cs** (30 minutes)

- ⬜ **Create Services/Interfaces/IExtinguisherService.cs** (30 minutes)
- ⬜ **Create Services/Implementations/ExtinguisherService.cs** (5 hours)
  - `GetExtinguishersAsync` - List with filtering
  - `GetExtinguisherByIdAsync` - Single extinguisher
  - `GetExtinguisherByBarcodeAsync` - Scan lookup
  - `CreateExtinguisherAsync` - Create new
  - `UpdateExtinguisherAsync` - Update existing
  - `DeleteExtinguisherAsync` - Soft delete
  - `GetInspectionHistoryAsync` - Inspection timeline
  - `GetMaintenanceHistoryAsync` - Maintenance records
  - Barcode uniqueness validation
  - Unit tests

- ⬜ **Create Services/Interfaces/IBarcodeService.cs** (30 minutes)
- ⬜ **Create Services/Implementations/BarcodeService.cs** (3 hours)
  - `GenerateBarcodeAsync` - Create QR code image
  - `ValidateBarcodeAsync` - Verify barcode data
  - `DecodeBarcodeAsync` - Extract information
  - `GenerateBulkBarcodesAsync` - Batch generation
  - QR code encoding/decoding
  - Unit tests

- ⬜ **Create Controllers/ExtinguishersController.cs** (3 hours)
  - `GET /api/extinguishers`
  - `GET /api/extinguishers/{extinguisherId}`
  - `GET /api/extinguishers/scan/{barcode}`
  - `POST /api/extinguishers`
  - `PUT /api/extinguishers/{extinguisherId}`
  - `DELETE /api/extinguishers/{extinguisherId}`
  - `GET /api/extinguishers/{extinguisherId}/inspection-history`
  - `GET /api/extinguishers/{extinguisherId}/maintenance-history`
  - Integration tests

- ⬜ **Create Controllers/BarcodesController.cs** (2 hours)
  - `POST /api/barcodes/generate`
  - `GET /api/barcodes/validate/{data}`
  - `POST /api/barcodes/bulk-generate`
  - Integration tests

#### Frontend Implementation
- ⬜ **Create services/extinguisher.service.js** (1 hour)
- ⬜ **Create services/barcode.service.js** (1 hour)

- ⬜ **Create stores/extinguishers.js** (1 hour)
  - State management for extinguishers
  - Filter and search logic
  - Barcode scanning state

- ⬜ **Create components/extinguishers/ExtinguisherList.vue** (2 hours)
  - Table with filters
  - Status indicators (due for inspection, overdue)
  - Quick actions (view, edit, inspect)
  - Export functionality
  - Responsive design

- ⬜ **Create components/extinguishers/ExtinguisherForm.vue** (3 hours)
  - Create/edit form
  - Type selection dropdown
  - Location selection
  - Barcode generation
  - Photo upload
  - Validation
  - Auto-save drafts

- ⬜ **Create components/extinguishers/ExtinguisherDetails.vue** (2 hours)
  - Detailed view
  - Inspection history timeline
  - Maintenance records
  - QR code display
  - Print label button
  - Edit/delete actions

- ⬜ **Create components/extinguishers/BarcodeScanner.vue** (4 hours)
  - HTML5-QRCode integration
  - Camera access request
  - Scan feedback (success/error)
  - Retry mechanism
  - Fallback manual entry
  - Error handling
  - Responsive design

- ⬜ **Create views/Extinguishers.vue** (1 hour)
  - Page layout
  - Add extinguisher button
  - Scan barcode button
  - List component
  - Breadcrumbs

#### Acceptance Criteria
- Extinguishers can be created, viewed, edited, deleted
- Barcodes generated and validated
- Barcode scanning works in browser
- Inspection history displayed
- All tests passing

---

### Inspection Workflow

#### Backend Implementation
- ⬜ **Create Models/Entities/Inspection.cs** (30 minutes)
- ⬜ **Create Models/Entities/InspectionChecklistResponse.cs** (30 minutes)
- ⬜ **Create Models/Entities/InspectionPhoto.cs** (30 minutes)
- ⬜ **Create Models/Requests/CreateInspectionRequest.cs** (30 minutes)
- ⬜ **Create Models/Requests/CompleteInspectionRequest.cs** (30 minutes)
- ⬜ **Create Models/Responses/InspectionResponse.cs** (30 minutes)

- ⬜ **Create Services/Interfaces/IInspectionService.cs** (1 hour)
- ⬜ **Create Services/Implementations/InspectionService.cs** (6 hours)
  - `GetInspectionsAsync` - List with filtering
  - `GetInspectionByIdAsync` - Single inspection
  - `GetDueInspectionsAsync` - Inspections due soon
  - `CreateInspectionAsync` - Start new inspection
  - `UpdateInspectionAsync` - Update in-progress
  - `CompleteInspectionAsync` - Finalize inspection
  - `UploadInspectionPhotoAsync` - Add photos
  - `SyncOfflineInspectionsAsync` - Sync offline data
  - Checklist validation
  - GPS validation
  - Tamper-proof hash generation
  - Unit tests

- ⬜ **Create Services/Interfaces/ITamperProofingService.cs** (30 minutes)
- ⬜ **Create Services/Implementations/TamperProofingService.cs** (4 hours)
  - `GenerateInspectionHashAsync` - HMAC-SHA256
  - `ValidateInspectionHashAsync` - Verify integrity
  - `GetPreviousInspectionHashAsync` - Hash chaining
  - `ValidateGpsCoordinatesAsync` - Location verification
  - `ValidatePhotoExifAsync` - Photo metadata check
  - `EncryptOfflineDataAsync` - Offline security
  - Unit tests

- ⬜ **Create Infrastructure/Storage/Interfaces/IBlobStorageService.cs** (30 minutes)
- ⬜ **Create Infrastructure/Storage/Implementations/AzureBlobStorageService.cs** (3 hours)
  - `UploadBlobAsync` - Upload photo
  - `DownloadBlobAsync` - Download photo
  - `DeleteBlobAsync` - Delete photo
  - `GetBlobUrlAsync` - Get SAS URL
  - Error handling
  - Retry policies (Polly)
  - Unit tests

- ⬜ **Create Controllers/InspectionsController.cs** (4 hours)
  - `GET /api/inspections`
  - `GET /api/inspections/{inspectionId}`
  - `GET /api/inspections/due`
  - `POST /api/inspections`
  - `PUT /api/inspections/{inspectionId}`
  - `POST /api/inspections/{inspectionId}/complete`
  - `POST /api/inspections/{inspectionId}/photos`
  - `POST /api/inspections/sync-offline`
  - Authorization checks
  - Integration tests

#### Frontend Implementation
- ⬜ **Create services/inspection.service.js** (1 hour)
- ⬜ **Create stores/inspections.js** (2 hours)
  - State: inspections, current inspection, offline queue
  - Actions: create, update, complete, sync
  - Offline queue management
  - IndexedDB integration

- ⬜ **Create components/inspections/InspectionList.vue** (2 hours)
  - Table with status indicators
  - Filters (date range, status, inspector)
  - Sort options
  - Quick view
  - Responsive design

- ⬜ **Create components/inspections/InspectionForm.vue** (5 hours)
  - Multi-step wizard
  - Step 1: Scan extinguisher barcode
  - Step 2: Select inspection type
  - Step 3: Complete checklist
  - Step 4: Add photos and notes
  - Step 5: Review and submit
  - Form validation
  - Auto-save to offline queue
  - Progress indicator
  - Error handling

- ⬜ **Create components/inspections/ChecklistItem.vue** (2 hours)
  - Pass/Fail/NA radio buttons
  - Required indicator
  - Photo capture button
  - Notes textarea
  - Validation feedback

- ⬜ **Create components/inspections/PhotoCapture.vue** (3 hours)
  - Camera access
  - Capture photo
  - Preview captured photo
  - Retake option
  - Multiple photos support
  - Compress before upload
  - Offline storage

- ⬜ **Create components/inspections/InspectionHistory.vue** (2 hours)
  - Timeline view
  - Filter by date range
  - View inspection details
  - Download PDF report
  - Print option

- ⬜ **Create views/Inspections.vue** (1 hour)
  - Page layout
  - Start inspection button
  - Inspection list component
  - Breadcrumbs

#### Acceptance Criteria
- Inspections can be started and completed
- Checklist validation works
- Photos uploaded successfully
- GPS coordinates captured
- Offline inspections sync correctly
- Tamper-proof hash validated
- All tests passing

---

## Phase 1.3: Inspection & Tamper-Proofing (Weeks 6-7)

### Tamper-Proofing Implementation

#### Hash Generation and Validation
- ⬜ **Implement HMAC-SHA256 Hashing** (2 hours)
  - Generate hash from inspection data
  - Include all checklist responses
  - Include GPS coordinates
  - Include photos metadata
  - Include timestamps
  - Store hash in database
  - Unit tests

- ⬜ **Implement Hash Chaining** (3 hours)
  - Retrieve previous inspection hash
  - Include in current inspection hash
  - Validate chain integrity
  - Handle missing previous inspection
  - Unit tests

- ⬜ **Create Utilities/HashingUtility.cs** (2 hours)
  - Static helper methods
  - Configurable hash algorithm
  - Salt generation
  - Unit tests

#### GPS Validation
- ⬜ **Create Utilities/GpsValidator.cs** (3 hours)
  - Calculate distance between coordinates
  - Validate accuracy threshold
  - Check timestamp vs GPS time
  - Handle missing GPS data
  - Unit tests

- ⬜ **Implement GPS Coordinate Capture (Frontend)** (2 hours)
  - Request geolocation permission
  - Capture coordinates with high accuracy
  - Display accuracy to user
  - Retry on failure
  - Fallback to manual entry

#### Photo EXIF Validation
- ⬜ **Implement EXIF Data Extraction** (3 hours)
  - Parse EXIF metadata
  - Extract capture timestamp
  - Extract GPS from photo (if available)
  - Extract device information
  - Validate timestamp within inspection window
  - Unit tests

#### Offline Inspection Queue
- ⬜ **Implement IndexedDB Storage (Frontend)** (4 hours)
  - Create database schema
  - Store pending inspections
  - Store captured photos
  - Encrypt sensitive data
  - CRUD operations
  - Unit tests

- ⬜ **Implement Sync Mechanism (Frontend)** (4 hours)
  - Detect online/offline status
  - Queue inspections for sync
  - Upload photos
  - Update inspection status
  - Handle sync failures
  - Conflict resolution
  - Progress feedback
  - Unit tests

- ⬜ **Implement Cryptographic Sealing (Frontend)** (3 hours)
  - Generate hash of offline inspection
  - Include device fingerprint
  - Store sealed inspection
  - Validate seal on sync
  - Unit tests

#### Audit Trail
- ⬜ **Enhance Audit Logging** (2 hours)
  - Log all inspection changes
  - Log tamper detection events
  - Log sync activities
  - Include full context
  - Cannot be modified or deleted
  - Unit tests

#### Acceptance Criteria
- All inspections cryptographically signed
- Hash chain validated on every inspection
- GPS coordinates within acceptable range
- Photo EXIF validated
- Offline inspections securely stored
- Sync works reliably
- Tamper alerts generated
- All tests passing

---

### Inspection History and Reporting

#### Backend Implementation
- ⬜ **Create Stored Procedures for Reporting** (4 hours)
  - `usp_GetMonthlyInspectionReport`
  - `usp_GetAnnualInspectionReport`
  - `usp_GetComplianceSummary`
  - `usp_GetDeficiencyReport`
  - `usp_GetInspectionTimeline`
  - Optimize for performance
  - Test with large datasets

#### Frontend Implementation
- ⬜ **Create components/reports/MonthlyReport.vue** (3 hours)
  - Date range selector
  - Summary statistics
  - Inspection list table
  - Export to PDF/Excel
  - Print option
  - Loading states

- ⬜ **Create components/reports/AnnualReport.vue** (3 hours)
  - Year selector
  - Compliance percentage
  - Charts (pass/fail rates)
  - Location breakdown
  - Export options

- ⬜ **Create components/reports/ComplianceDashboard.vue** (4 hours)
  - Real-time compliance status
  - Color-coded indicators
  - Due inspections count
  - Overdue inspections count
  - Charts and graphs
  - Drill-down capability
  - Refresh button

#### Acceptance Criteria
- Reports display accurate data
- Export functionality works
- Charts render correctly
- Performance acceptable (< 2 seconds)
- All tests passing

---

## Phase 1.4: Reporting & Jobs (Weeks 8-9)

### Report Generation

#### Backend Implementation
- ⬜ **Create Services/Interfaces/IReportService.cs** (1 hour)
- ⬜ **Create Services/Implementations/ReportService.cs** (6 hours)
  - `GetMonthlyReportAsync` - Monthly inspection report
  - `GetAnnualReportAsync` - Annual compliance report
  - `GetComplianceDashboardAsync` - Real-time dashboard data
  - `GetDeficiencyReportAsync` - Outstanding issues
  - `GetInspectionTimelineAsync` - Historical timeline
  - `ExportReportAsync` - Export to various formats
  - Caching for expensive queries
  - Unit tests

- ⬜ **Install PDF Generation Library** (30 minutes)
  ```bash
  dotnet add package QuestPDF --version 2023.12.0
  ```

- ⬜ **Create Services/Implementations/PdfReportService.cs** (8 hours)
  - Implement QuestPDF templates
  - Monthly report template
  - Annual report template
  - Compliance certificate template
  - Include charts and tables
  - Company branding/logo
  - Unit tests

- ⬜ **Create Services/Implementations/ExcelReportService.cs** (4 hours)
  - Install EPPlus or ClosedXML
  - Create Excel workbook
  - Multiple sheets for different sections
  - Formatting and styling
  - Charts in Excel
  - Unit tests

- ⬜ **Create Controllers/ReportsController.cs** (3 hours)
  - `GET /api/reports/monthly`
  - `GET /api/reports/annual`
  - `GET /api/reports/compliance`
  - `GET /api/reports/deficiencies`
  - `GET /api/reports/export/{format}` (PDF, Excel, CSV)
  - Authorization checks
  - Integration tests

#### Frontend Implementation
- ⬜ **Create services/report.service.js** (1 hour)
- ⬜ **Create views/Reports.vue** (2 hours)
  - Report type selector
  - Parameter inputs
  - Generate button
  - Download link
  - Preview (optional)

#### Acceptance Criteria
- Reports generated successfully
- PDF quality acceptable
- Excel formatting correct
- Export performance < 5 seconds for standard reports
- All tests passing

---

### Background Jobs

#### Hangfire Configuration
- ⬜ **Configure Hangfire Dashboard** (1 hour)
  - Add dashboard authorization
  - Configure dashboard route
  - Test dashboard access

#### Job Implementation
- ⬜ **Create Infrastructure/BackgroundJobs/InspectionReminderJob.cs** (4 hours)
  - Query inspections due in 7 days
  - Group by location/inspector
  - Send email notifications
  - Update notification log
  - Error handling
  - Unit tests

- ⬜ **Create Infrastructure/BackgroundJobs/ReportGenerationJob.cs** (3 hours)
  - Scheduled monthly report generation
  - Save to blob storage
  - Send email with link
  - Error handling
  - Unit tests

- ⬜ **Create Infrastructure/BackgroundJobs/TenantCleanupJob.cs** (2 hours)
  - Archive old inspections (> 2 years)
  - Clean up soft-deleted records
  - Optimize database
  - Error handling
  - Unit tests

- ⬜ **Configure Job Schedules** (1 hour)
  - InspectionReminderJob: Daily at 8 AM
  - ReportGenerationJob: Monthly on 1st
  - TenantCleanupJob: Weekly on Sunday
  - Test job execution

#### Email Service
- ⬜ **Create Infrastructure/Email/IEmailService.cs** (30 minutes)
- ⬜ **Create Infrastructure/Email/EmailService.cs** (3 hours)
  - Configure SendGrid or Azure Communication Services
  - Send email method
  - Email templates
  - Attachment support
  - Error handling
  - Unit tests

#### Acceptance Criteria
- Hangfire dashboard accessible
- Jobs execute on schedule
- Email notifications sent successfully
- Job failures logged and alerted
- All tests passing

---

## Phase 1.5: Testing & Deployment (Week 10)

### Comprehensive Testing

#### Unit Tests
- ⬜ **Backend Unit Tests** (8 hours)
  - Service layer: 80% coverage
  - Middleware: 90% coverage
  - Utilities: 90% coverage
  - Review coverage reports
  - Fix failing tests

- ⬜ **Frontend Unit Tests** (6 hours)
  - Components: 70% coverage
  - Stores: 80% coverage
  - Services: 80% coverage
  - Review coverage reports
  - Fix failing tests

#### Integration Tests
- ⬜ **API Integration Tests** (8 hours)
  - Test all controller endpoints
  - Test authentication flows
  - Test authorization policies
  - Test error scenarios
  - Test database interactions
  - Review test results

#### End-to-End Tests
- ⬜ **E2E Test Suite** (12 hours)
  - User registration and login
  - Create and manage locations
  - Create and manage extinguishers
  - Complete inspection workflow
  - Generate and download reports
  - Test offline functionality
  - Test barcode scanning
  - Review test results

#### Performance Testing
- ⬜ **Load Testing** (4 hours)
  - Use Azure Load Testing or JMeter
  - Test 100 concurrent users
  - Test 500 concurrent users
  - Test 1000 concurrent users
  - Identify bottlenecks
  - Document results

- ⬜ **Stress Testing** (2 hours)
  - Push system to breaking point
  - Identify failure modes
  - Document recovery behavior

#### Security Testing
- ⬜ **OWASP Top 10 Review** (4 hours)
  - SQL Injection testing
  - XSS testing
  - CSRF testing
  - Authentication bypass attempts
  - Authorization bypass attempts
  - Document findings
  - Fix vulnerabilities

- ⬜ **Penetration Testing** (8 hours)
  - Hire security consultant (optional)
  - Vulnerability scanning
  - Manual testing
  - Document findings
  - Remediate issues

#### Acceptance Criteria
- All unit tests passing (80% coverage)
- All integration tests passing
- E2E tests cover critical workflows
- Load testing validates 1000 users
- No critical security vulnerabilities
- Performance meets SLAs

---

### Production Deployment

#### Pre-Deployment Checklist
- ⬜ **Review Configuration** (2 hours)
  - Validate production appsettings.json
  - Verify all secrets in Key Vault
  - Check connection strings
  - Validate Azure AD B2C configuration
  - Review CORS settings

- ⬜ **Database Migration** (2 hours)
  - Backup production database (if exists)
  - Run migration scripts
  - Validate schema
  - Seed production data
  - Test connections

- ⬜ **SSL/TLS Configuration** (1 hour)
  - Configure custom domain (optional)
  - Install SSL certificate
  - Force HTTPS redirect
  - Test secure connections

#### Deployment Steps
- ⬜ **Deploy Backend to Azure** (2 hours)
  - Build release configuration
  - Deploy to staging slot
  - Run smoke tests on staging
  - Swap staging to production
  - Monitor for errors

- ⬜ **Deploy Frontend to Vercel** (1 hour)
  - Configure production environment variables
  - Deploy to Vercel
  - Verify deployment
  - Test production site

- ⬜ **Configure Monitoring** (2 hours)
  - Validate Application Insights data
  - Setup alerts for errors
  - Setup availability tests
  - Configure dashboards
  - Test alert notifications

#### Post-Deployment
- ⬜ **Smoke Testing** (2 hours)
  - Test critical user workflows
  - Verify integrations
  - Check performance
  - Test from different devices/browsers

- ⬜ **User Acceptance Testing** (8 hours)
  - Invite beta users
  - Collect feedback
  - Document issues
  - Prioritize fixes

- ⬜ **Create Runbook** (4 hours)
  - Deployment procedures
  - Rollback procedures
  - Troubleshooting guides
  - Common issues and solutions

#### Acceptance Criteria
- Production environment stable
- All critical features working
- Monitoring and alerts active
- Rollback tested and documented
- UAT feedback incorporated
- Documentation complete

---

## Phase 2.0: Native Mobile Apps (Months 4-6)

### iOS Application

#### Project Setup
- ⬜ **Create Xcode Project** (2 hours)
  - SwiftUI app template
  - Configure bundle identifier
  - Setup signing certificates
  - Configure app capabilities
  - Add Info.plist permissions (Camera, Location)

- ⬜ **Install Dependencies** (2 hours)
  - Alamofire (HTTP networking)
  - KeychainAccess (secure storage)
  - Kingfisher (image loading)
  - RealmSwift or Core Data (local DB)
  - Setup Swift Package Manager

#### Core Implementation
- ⬜ **Implement Authentication** (8 hours)
  - Login screen
  - Azure AD B2C integration
  - Token storage in Keychain
  - Biometric authentication (Face ID/Touch ID)
  - Auto-login on app launch

- ⬜ **Implement Local Database** (6 hours)
  - Core Data model
  - Entities for offline storage
  - CRUD operations
  - Migration strategies

- ⬜ **Implement API Client** (6 hours)
  - Alamofire configuration
  - Request/response models
  - Error handling
  - Token refresh
  - Network reachability

- ⬜ **Implement Barcode Scanning** (8 hours)
  - AVFoundation camera setup
  - QR code detection
  - Scan feedback (haptics, sound)
  - Flashlight toggle
  - Manual entry fallback

- ⬜ **Implement GPS Tracking** (4 hours)
  - Core Location setup
  - Request location permissions
  - Continuous location updates
  - Geocoding (optional)
  - GPS accuracy display

- ⬜ **Implement Inspection Workflow** (12 hours)
  - Scan extinguisher
  - Load checklist
  - Checklist UI (SwiftUI forms)
  - Photo capture
  - GPS tagging
  - Offline queue
  - Background sync

- ⬜ **Implement Photo Capture** (6 hours)
  - Custom camera view
  - AVCaptureSession
  - Photo preview
  - Compression
  - Local storage
  - EXIF metadata

- ⬜ **Implement Sync Engine** (10 hours)
  - Background sync with URLSession
  - Conflict resolution
  - Upload queue
  - Progress tracking
  - Error handling
  - Retry logic

#### UI Implementation
- ⬜ **Dashboard Screen** (4 hours)
- ⬜ **Locations Screen** (4 hours)
- ⬜ **Extinguishers Screen** (4 hours)
- ⬜ **Inspection Screen** (6 hours)
- ⬜ **Reports Screen** (4 hours)
- ⬜ **Settings Screen** (4 hours)

#### Testing
- ⬜ **Unit Tests** (8 hours)
- ⬜ **UI Tests** (8 hours)
- ⬜ **Device Testing** (4 hours)
  - iPhone SE (small screen)
  - iPhone 14 Pro (standard)
  - iPad (tablet)

#### App Store Submission
- ⬜ **Prepare Metadata** (4 hours)
  - App name, description
  - Keywords
  - Screenshots
  - Privacy policy
  - Support URL

- ⬜ **Submit to App Store** (2 hours)
  - Create App Store Connect listing
  - Upload build
  - Submit for review
  - Respond to feedback

#### Acceptance Criteria
- iOS app fully functional
- Offline mode works reliably
- Sync is robust
- Barcode scanning accurate
- App Store approved
- Crash rate < 0.5%

---

### Android Application

#### Project Setup
- ⬜ **Create Android Studio Project** (2 hours)
  - Kotlin + Jetpack Compose
  - Configure package name
  - Setup signing config
  - Add permissions (Camera, Location, Storage)

- ⬜ **Add Dependencies** (2 hours)
  - Retrofit (HTTP client)
  - Room (local database)
  - Hilt (dependency injection)
  - CameraX (camera)
  - ML Kit Barcode Scanning
  - WorkManager (background tasks)
  - Coil (image loading)

#### Core Implementation
- ⬜ **Implement Authentication** (8 hours)
  - Login screen
  - Azure AD B2C integration
  - Token storage (EncryptedSharedPreferences)
  - Biometric authentication
  - Auto-login

- ⬜ **Implement Local Database** (6 hours)
  - Room entities
  - DAOs
  - Type converters
  - Migrations

- ⬜ **Implement API Client** (6 hours)
  - Retrofit setup
  - Interceptors (auth, logging)
  - Error handling
  - Token refresh

- ⬜ **Implement Barcode Scanning** (8 hours)
  - CameraX setup
  - ML Kit barcode detector
  - Scan feedback
  - Flashlight toggle
  - Manual entry

- ⬜ **Implement GPS Tracking** (4 hours)
  - FusedLocationProviderClient
  - Location permissions
  - Continuous updates
  - Geocoding (optional)

- ⬜ **Implement Inspection Workflow** (12 hours)
  - Scan extinguisher
  - Load checklist
  - Checklist UI (Compose)
  - Photo capture
  - GPS tagging
  - Offline queue
  - Background sync

- ⬜ **Implement Photo Capture** (6 hours)
  - CameraX ImageCapture
  - Preview screen
  - Compression
  - Local storage
  - EXIF metadata

- ⬜ **Implement Sync Engine** (10 hours)
  - WorkManager for background sync
  - Upload queue
  - Conflict resolution
  - Progress tracking
  - Retry logic

#### UI Implementation
- ⬜ **Dashboard Screen** (4 hours)
- ⬜ **Locations Screen** (4 hours)
- ⬜ **Extinguishers Screen** (4 hours)
- ⬜ **Inspection Screen** (6 hours)
- ⬜ **Reports Screen** (4 hours)
- ⬜ **Settings Screen** (4 hours)

#### Testing
- ⬜ **Unit Tests** (8 hours)
- ⬜ **UI Tests** (8 hours)
- ⬜ **Device Testing** (4 hours)
  - Small phone (5" screen)
  - Standard phone (6" screen)
  - Tablet (10" screen)

#### Play Store Submission
- ⬜ **Prepare Metadata** (4 hours)
  - App name, description
  - Screenshots
  - Feature graphic
  - Privacy policy

- ⬜ **Submit to Play Store** (2 hours)
  - Create Play Console listing
  - Upload APK/AAB
  - Submit for review
  - Respond to feedback

#### Acceptance Criteria
- Android app fully functional
- Offline mode works reliably
- Sync is robust
- Barcode scanning accurate
- Play Store approved
- Crash rate < 0.5%

---

## Ongoing Tasks

### Documentation Maintenance
- ⬜ **Update README.md** - As features are added
- ⬜ **Update API Documentation** - Keep Swagger current
- ⬜ **Create User Guides** - For each role
- ⬜ **Create Video Tutorials** - Screen recordings
- ⬜ **FAQ and Troubleshooting** - Based on user feedback

### Performance Optimization
- ⬜ **Database Query Optimization** - Regular review
- ⬜ **API Response Caching** - Redis implementation (optional)
- ⬜ **Image Optimization** - Compression and CDN
- ⬜ **Code Refactoring** - Remove technical debt
- ⬜ **Monitoring Review** - Weekly metrics review

### Security Updates
- ⬜ **Dependency Updates** - Monthly security patches
- ⬜ **Vulnerability Scans** - Weekly automated scans
- ⬜ **Security Audits** - Quarterly reviews
- ⬜ **Penetration Testing** - Annual tests

### Compliance
- ⬜ **GDPR Compliance Review** - Quarterly
- ⬜ **Privacy Policy Updates** - As regulations change
- ⬜ **Terms of Service Updates** - Annual review
- ⬜ **SOC 2 Preparation** - If pursuing certification

---

## Summary

**Total Estimated Effort:**
- Phase 1.1 (Foundation): 40 hours
- Phase 1.2 (Core Features): 60 hours
- Phase 1.3 (Inspection & Tamper-Proofing): 50 hours
- Phase 1.4 (Reporting & Jobs): 40 hours
- Phase 1.5 (Testing & Deployment): 50 hours
- Phase 2.0 (Mobile Apps): 200+ hours

**Total Phase 1: ~240 hours (~10 weeks for a solo developer)**

**Phase 2.0: ~200 hours (~3 months for mobile development)**

This TODO document serves as the master checklist for implementation. Update task statuses as work progresses, and add notes for any deviations or discoveries made during development.

---

**Last Updated:** October 8, 2025  
**Status:** Ready for Implementation  
**Next Review:** Weekly during active development


---

## Phase 1.6: Scheduling and Route Optimization (Week 11)

### Inspection Scheduling System

#### Backend Implementation
- ⬜ **Create Models/Entities/InspectionSchedule.cs** (30 minutes)
- ⬜ **Create Models/Entities/InspectorRoute.cs** (30 minutes)
- ⬜ **Create Models/Entities/LocationGeofence.cs** (30 minutes)

- ⬜ **Create Services/Interfaces/ISchedulingService.cs** (1 hour)
- ⬜ **Create Services/Implementations/SchedulingService.cs** (8 hours)
  - `GetUpcomingInspectionsAsync` - Inspections due in date range
  - `GenerateSchedulesAsync` - Auto-generate schedules for all extinguishers
  - `RecalculateNextDueDateAsync` - Update based on completion
  - `AssignInspectorAsync` - Assign inspector to schedule
  - `GetInspectorWorkloadAsync` - Current workload per inspector
  - `SuggestAssignmentAsync` - Auto-assign based on location proximity
  - Error handling and logging
  - Unit tests

- ⬜ **Create Services/Interfaces/IRouteOptimizationService.cs** (1 hour)
- ⬜ **Create Services/Implementations/RouteOptimizationService.cs** (10 hours)
  - `OptimizeRouteAsync` - Traveling salesman problem solver
  - `CalculateDistanceAsync` - Distance between two locations
  - `EstimateInspectionTimeAsync` - Time per inspection type
  - `GenerateDailyRouteAsync` - Create optimized route for inspector
  - `ExportToNavigationAsync` - Format for Google Maps/Apple Maps
  - Integration with mapping API (Google Maps Distance Matrix or Azure Maps)
  - Greedy nearest-neighbor algorithm (simple but effective)
  - Unit tests

- ⬜ **Create Services/Interfaces/IGeofencingService.cs** (30 minutes)
- ⬜ **Create Services/Implementations/GeofencingService.cs** (4 hours)
  - `CreateGeofenceAsync` - Define geofence for location
  - `CheckGeofenceAsync` - Is GPS coordinate within geofence?
  - `GetNearbyLocationsAsync` - Locations within distance
  - `CalculateDistanceAsync` - Haversine formula for GPS distance
  - Unit tests

- ⬜ **Create Controllers/SchedulingController.cs** (3 hours)
  - `GET /api/scheduling/upcoming` - Inspections due soon
  - `GET /api/scheduling/overdue` - Overdue inspections
  - `POST /api/scheduling/generate` - Generate schedules
  - `PUT /api/scheduling/{scheduleId}/assign` - Assign inspector
  - `GET /api/scheduling/inspector/{userId}/workload` - Inspector workload
  - Integration tests

- ⬜ **Create Controllers/RoutesController.cs** (3 hours)
  - `GET /api/routes/daily/{userId}/{date}` - Daily route for inspector
  - `POST /api/routes/optimize` - Generate optimized route
  - `GET /api/routes/export/{routeId}` - Export route to navigation
  - `GET /api/routes/nearby` - Nearby locations for opportunistic inspection
  - Integration tests

- ⬜ **Update Database with Scheduling Tables** (2 hours)
  - Execute 005_CreateSchedulingTables.sql
  - Add InspectionSchedules table
  - Add InspectorRoutes table
  - Add LocationGeofences table
  - Create stored procedures for scheduling queries
  - Test with sample data

#### Frontend Implementation
- ⬜ **Create services/scheduling.service.js** (1 hour)
- ⬜ **Create services/routing.service.js** (1 hour)

- ⬜ **Create stores/scheduling.js** (2 hours)
  - State: schedules, upcoming inspections, overdue count
  - Actions: fetch schedules, generate, assign inspector
  - Getters: filtered schedules, compliance metrics

- ⬜ **Create components/scheduling/ScheduleCalendar.vue** (4 hours)
  - Calendar view of scheduled inspections
  - Color-coded by status (due, overdue, completed)
  - Drag-and-drop to reschedule
  - Click date to see details
  - Month/week/day views

- ⬜ **Create components/scheduling/InspectorAssignment.vue** (3 hours)
  - Assign inspector to inspection
  - View inspector workload
  - Balance workload across inspectors
  - Filter by location proximity
  - Drag-and-drop assignment

- ⬜ **Create components/scheduling/RouteMap.vue** (4 hours)
  - Map with daily route
  - Numbered sequence markers
  - Distance and time estimates
  - Export to navigation app
  - Current location indicator
  - Traffic overlay (optional)

- ⬜ **Create components/scheduling/ComplianceDashboard.vue** (4 hours)
  - Overall compliance percentage gauge
  - Breakdown by location (list or map)
  - Trend chart (line chart)
  - Overdue list with days overdue
  - Quick actions (schedule, assign)

- ⬜ **Create views/Scheduling.vue** (2 hours)
  - Page layout
  - Calendar component
  - Upcoming inspections widget
  - Overdue alerts
  - Quick schedule generator

#### Acceptance Criteria
- Schedules auto-generate when extinguisher added
- Next due date recalculated after inspection
- Route optimization reduces travel time 30%+
- Inspectors see optimized daily route
- Geofence detection within 50 meters
- All tests passing

---

## Phase 1.7: Push Notifications and Mobile Features (Week 12)

### Push Notification System

#### Backend Implementation
- ⬜ **Install Push Notification Libraries** (30 minutes)
  ```bash
  # For Firebase Cloud Messaging (iOS and Android)
  dotnet add package FirebaseAdmin --version 2.4.0
  ```

- ⬜ **Create Models/Entities/PushNotificationSubscription.cs** (30 minutes)
- ⬜ **Create Models/Entities/UserNotificationPreference.cs** (30 minutes)

- ⬜ **Create Services/Interfaces/IPushNotificationService.cs** (1 hour)
- ⬜ **Create Services/Implementations/PushNotificationService.cs** (8 hours)
  - `RegisterDeviceAsync` - Register device token
  - `UnregisterDeviceAsync` - Remove device token
  - `SendNotificationAsync` - Send to specific user
  - `SendBulkNotificationAsync` - Send to multiple users
  - `ScheduleNotificationAsync` - Schedule for future delivery
  - Integration with Firebase Cloud Messaging
  - Handle iOS and Android differences
  - Retry logic for failed sends
  - Unit tests

- ⬜ **Create Services/Interfaces/INotificationPreferenceService.cs** (30 minutes)
- ⬜ **Create Services/Implementations/NotificationPreferenceService.cs** (3 hours)
  - `GetPreferencesAsync` - Get user notification preferences
  - `UpdatePreferencesAsync` - Save preferences
  - `CheckQuietHoursAsync` - Is it quiet hours for user?
  - `CanSendNotificationAsync` - Check if user accepts this type
  - Unit tests

- ⬜ **Create Infrastructure/BackgroundJobs/NotificationJob.cs** (6 hours)
  - Send inspection reminders (7 days, 1 day, day-of)
  - Send overdue alerts
  - Send daily digest
  - Send geofence entry notifications (queued from mobile)
  - Send sync completion notifications
  - Respect user preferences and quiet hours
  - Unit tests

- ⬜ **Create Controllers/NotificationsController.cs** (2 hours)
  - `POST /api/notifications/register` - Register device
  - `DELETE /api/notifications/unregister` - Unregister device
  - `GET /api/notifications/preferences` - Get preferences
  - `PUT /api/notifications/preferences` - Update preferences
  - `GET /api/notifications/history` - Notification history
  - Integration tests

- ⬜ **Configure Firebase Cloud Messaging** (2 hours)
  - Create Firebase project
  - Add iOS app to Firebase
  - Add Android app to Firebase
  - Download service account key
  - Store in Azure Key Vault
  - Test notification sending

#### Acceptance Criteria
- Push notifications delivered within 60 seconds
- 95% delivery success rate
- Deep links work correctly
- Users can customize preferences
- Quiet hours respected
- All tests passing

---

**Total Estimated Effort (Updated):**
- Phase 1.1-1.5 (Foundation through Testing): ~240 hours (10 weeks)
- **Phase 1.6 (Scheduling & Route Optimization): ~60 hours (1 week)**
- **Phase 1.7 (Push Notifications): ~25 hours (1 week)**
- Phase 2.0 (Native Mobile Apps): ~200 hours (3 months)

**Total Phase 1: ~325 hours (~14 weeks)**
**Total Project: ~525 hours**

---

**Last Updated:** October 8, 2025 (Enhanced with Scheduling and Mobile Features)
**Status:** Ready for Implementation  
**Next Review:** Weekly during active development
