# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**FireProof** is a multi-tenant SaaS platform for managing fire extinguisher inspections, compliance tracking, and regulatory reporting. Built with .NET 8.0 backend, Vue.js 3 frontend, and Azure SQL Database with a stored-procedure-first architecture.

## Essential Commands

### Backend (.NET 8.0)

```bash
# Navigate to backend
cd backend/FireExtinguisherInspection.API

# Restore and build
dotnet restore
dotnet build

# Run API (default: https://localhost:7001)
dotnet run

# Run tests
dotnet test

# Publish for production
dotnet publish -c Release -o ./publish
```

### Frontend (Vue.js 3)

```bash
# Navigate to frontend
cd frontend/fire-extinguisher-web

# Install dependencies
npm install

# Development server (default: http://localhost:5173)
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Lint and format
npm run lint
npm run format
```

### Database

```bash
# Run migration scripts in order:
# 1. database/scripts/001_CreateCoreSchema.sql (Core tables: Tenants, Users, AuditLog)
# 2. database/scripts/002_CreateTenantSchema.sql (Tenant tables: Locations, Extinguishers, etc.)
# 3. database/scripts/002b_CreateTenantSchema_Part2.sql (Inspections, Photos, Maintenance)
# 4. database/scripts/005_CreateSchedulingTables.sql (Scheduling features)

# Connect via sqlcmd (example for WSL to SQL Server)
sqlcmd -S 172.31.208.1,14333 -U sqladmin -P YourPassword -C -d FireProofDB -i database/scripts/001_CreateCoreSchema.sql
```

## Architecture Principles

### Multi-Tenancy Model

- **Schema-per-tenant isolation**: Each tenant gets isolated tables (created by stored procedures)
- **Core schema** (`dbo`): Shared tables for Tenants, Users, UserTenantRoles, AuditLog
- **Tenant schemas**: Dynamic schemas created per tenant with prefix pattern
- **Tenant resolution**: Middleware extracts tenant context from JWT claims

### Stored Procedure Architecture

**CRITICAL**: All database operations MUST use stored procedures. Entity Framework Core is used ONLY for executing stored procedures, never for direct table access.

Naming convention: `usp_<Entity>_<Operation>`

Examples:
- `usp_Tenant_Create`
- `usp_Location_GetAll`
- `usp_Inspection_VerifyHash`

### Tamper-Proofing System

Inspections use cryptographic verification:
1. **HMAC-SHA256 signatures** on each inspection
2. **Hash chaining** (blockchain-style) linking inspections
3. **GPS validation** against expected location coordinates
4. **Photo EXIF metadata** validation
5. **Immutable audit logs**

Implementation: `Services/TamperProofingService.cs` or `ITamperProofingService`

### Offline-First Frontend

- **IndexedDB** for offline inspection storage
- **Service Worker** for PWA capabilities with background sync
- **Inspection queue**: Queue inspections offline, auto-sync when online
- Implemented in frontend stores and services

## Project Structure

```
fireproof/
├── backend/FireExtinguisherInspection.API/
│   ├── Controllers/          # API endpoints (RESTful)
│   ├── Services/             # Business logic (interfaces + implementations)
│   ├── Data/                 # Database access (stored procedure execution)
│   ├── Models/               # DTOs and request/response models
│   ├── Middleware/           # TenantResolution, ErrorHandling, etc.
│   ├── Infrastructure/       # Cross-cutting (logging, caching, etc.)
│   └── Utilities/            # Helper functions
├── frontend/fire-extinguisher-web/
│   └── src/
│       ├── components/       # Reusable Vue components
│       ├── views/            # Page-level components
│       ├── stores/           # Pinia state management
│       ├── services/         # API client services (axios)
│       ├── router/           # Vue Router configuration
│       └── utils/            # Helper utilities
├── database/
│   ├── scripts/              # SQL schema creation scripts
│   └── migrations/           # EF Core migrations (rarely used)
├── mobile/                   # Phase 2.0 - Native apps (iOS Swift, Android Kotlin)
├── infrastructure/           # Azure ARM/Bicep templates
└── docs/                     # Requirements, TODO, FUTURE
```

## Key Dependencies

### Backend NuGet Packages

- **Microsoft.EntityFrameworkCore.SqlServer** (8.0.0) - For stored procedure execution only
- **Microsoft.Data.SqlClient** (5.1.0) - Direct SQL connectivity
- **Microsoft.Identity.Web** (2.15.0) - Azure AD B2C integration
- **Serilog.AspNetCore** (8.0.0) + Serilog.Sinks.ApplicationInsights
- **Polly** (8.0.0) - Resilience patterns (retry, circuit breaker)
- **Hangfire** (1.8.0) - Background job scheduling
- **Azure.Storage.Blobs** (12.19.0) - Photo storage
- **Azure.Security.KeyVault.Secrets** (4.5.0) - Secret management

### Frontend NPM Packages

- **vue** (3.4.0) - Framework
- **vue-router** (4.2.5) - Routing
- **pinia** (2.1.7) - State management
- **axios** (1.6.2) - HTTP client
- **tailwindcss** (3.4.0) - CSS framework
- **html5-qrcode** (2.3.8) - Barcode/QR scanning
- **qrcode** (1.5.3) - QR code generation
- **vite-plugin-pwa** (0.17.4) - PWA support

## Development Workflow

### Service Layer Pattern

All business logic goes in `Services/` with interface-first design:

```csharp
// Define interface
public interface ITenantService
{
    Task<TenantDto> CreateTenantAsync(CreateTenantRequest request);
    Task<TenantDto?> GetTenantByIdAsync(Guid tenantId);
}

// Implement with stored procedure calls
public class TenantService : ITenantService
{
    private readonly IDbConnectionFactory _connectionFactory;

    public async Task<TenantDto> CreateTenantAsync(CreateTenantRequest request)
    {
        // Execute usp_Tenant_Create stored procedure
    }
}
```

### API Controller Pattern

- Controllers are thin, delegating to services
- Use attribute routing: `[Route("api/[controller]")]`
- Apply authorization: `[Authorize(Policy = "TenantAdmin")]`
- Return consistent response types: `ActionResult<T>`

### Frontend Service Pattern

API clients in `services/` use axios instances with interceptors:

```javascript
// services/api.js
import axios from 'axios'

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL
})

// Add JWT token to requests
api.interceptors.request.use(config => {
  const token = localStorage.getItem('token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

export default api
```

### Pinia Store Pattern

State management per domain entity:

```javascript
// stores/locations.js
import { defineStore } from 'pinia'
import locationService from '@/services/locationService'

export const useLocationStore = defineStore('locations', {
  state: () => ({
    locations: [],
    currentLocation: null
  }),
  actions: {
    async fetchLocations() {
      this.locations = await locationService.getAll()
    }
  }
})
```

## Testing Strategy

### Backend Testing

- **Unit tests**: Services with mocked dependencies
- **Integration tests**: API endpoints with test database
- **Target coverage**: 70%+

### Frontend Testing

- **Component tests**: Vue Test Utils
- **Store tests**: Pinia testing utilities
- **E2E tests**: Playwright (configured and running)

### Test ID Guidelines

**CRITICAL**: All UI components MUST include `data-testid` attributes for reliable E2E testing.

#### Naming Convention

Use descriptive, kebab-case test IDs that describe the element's purpose:

```vue
<!-- Good examples -->
<h1 data-testid="page-heading">Dashboard</h1>
<button data-testid="submit-button">Submit</button>
<input data-testid="email-input" />
<div data-testid="user-profile-card">...</div>

<!-- Bad examples -->
<h1 data-testid="h1">Dashboard</h1>           <!-- Too generic -->
<button data-testid="btn1">Submit</button>    <!-- Meaningless -->
<input data-testid="input">...</input>        <!-- Not specific -->
```

#### When to Add Test IDs

Add test IDs to:
- **Page headings** (`h1`, `h2` for major sections)
- **Interactive elements** (buttons, links, inputs, selects)
- **Navigation elements** (menu items, tabs)
- **Data containers** (cards, tables, lists with dynamic content)
- **Stat cards and metrics**
- **Modal dialogs and their key elements**
- **Form fields** (all inputs, textareas, selects)
- **Status indicators** (badges, alerts, toasts)

#### Component-Specific Patterns

```vue
<!-- Authentication Views -->
<input data-testid="email-input" />
<input data-testid="password-input" />
<button data-testid="login-submit-button" />
<button data-testid="register-submit-button" />

<!-- List/Table Views -->
<h1 data-testid="inspections-heading" />
<button data-testid="new-inspection-button" />
<div data-testid="inspections-table-container" />
<table data-testid="inspections-table" />
<div data-testid="inspections-empty-state" />

<!-- Stats Cards -->
<div data-testid="stats-cards">
  <div data-testid="stat-card-total">
    <div data-testid="total-count">42</div>
  </div>
  <div data-testid="stat-card-passrate">
    <div data-testid="pass-rate">95.2%</div>
  </div>
</div>

<!-- Selection/Navigation -->
<div data-testid="tenant-list">
  <div
    data-testid="tenant-card"
    :data-tenant-id="tenant.tenantId"
  >
    {{ tenant.name }}
  </div>
</div>
```

#### Test ID Best Practices

1. **Be Specific**: Use descriptive names that make tests self-documenting
2. **Be Consistent**: Follow the same naming patterns across the app
3. **Avoid Implementation Details**: Don't use class names or IDs
4. **Use Data Attributes**: Prefer `data-tenant-id` over generic attributes for list items
5. **Add During Development**: Include test IDs when creating new components
6. **Update Tests Together**: When adding test IDs, update corresponding tests

#### Testing with Test IDs

```javascript
// Playwright E2E tests
await page.click('[data-testid="login-submit-button"]')
await page.fill('[data-testid="email-input"]', 'user@example.com')
await expect(page.locator('[data-testid="dashboard-heading"]')).toBeVisible()

// Selecting specific items
await page.click('[data-tenant-id="tenant-123"]')
```

#### Checklist for New UI Components

When creating a new view or component:
- [ ] Add `data-testid` to the main heading
- [ ] Add `data-testid` to all buttons and links
- [ ] Add `data-testid` to all form inputs
- [ ] Add `data-testid` to data containers (tables, cards, lists)
- [ ] Add `data-testid` to empty states
- [ ] Add `data-testid` to loading states
- [ ] Add `data-testid` to error messages
- [ ] Update or create corresponding E2E tests

## Security & Compliance

### Authentication

- **Azure AD B2C** for user authentication
- **JWT tokens** with 15-minute expiration
- **Refresh token rotation**
- MFA support

### Authorization

Role-based access control (RBAC):
- System Administrator (platform-wide)
- Tenant Administrator (organization management)
- Location Manager (site management)
- Inspector (perform inspections)
- Viewer (read-only)

### Data Protection

- **TLS 1.2+** for all communications
- **Transparent Data Encryption (TDE)** on Azure SQL
- **Azure Blob Storage** encryption at rest
- **Azure Key Vault** for secrets (connection strings, API keys)

### Compliance

- **NFPA 10** standards alignment
- **GDPR** compliant (data export, right to deletion)
- **SOC 2 Type II** readiness
- **7-year audit log retention**

## Common Development Tasks

### Adding a New API Endpoint

1. Create stored procedure in appropriate script file
2. Define DTOs in `Models/`
3. Create service interface and implementation in `Services/`
4. Add controller action in `Controllers/`
5. Register service in `Program.cs` DI container
6. Add authorization policy if needed
7. Document with XML comments for Swagger

### Adding a New Frontend Feature

1. Create service in `services/` for API calls
2. Create Pinia store in `stores/` for state management
3. Create components in `components/`
4. Create view in `views/`
5. Add route in `router/index.js`
6. Add navigation link in layout components

### Working with Barcode/QR Codes

- **Backend**: Use QRCoder library for generation
- **Frontend**: Use html5-qrcode for scanning
- **Format**: Custom format includes tenant ID, entity type, and unique identifier
- **Labels**: Generate printable PDF labels with barcode + human-readable info

### Implementing Background Jobs

Use Hangfire for scheduled tasks:

```csharp
// In Program.cs or Startup
services.AddHangfire(config => config.UseSqlServerStorage(connectionString));
services.AddHangfireServer();

// Schedule job
RecurringJob.AddOrUpdate<InspectionReminderJob>(
    "inspection-reminders",
    job => job.ExecuteAsync(),
    Cron.Daily);
```

## Deployment

### Azure Resources Required

- **App Service** (Linux, B1+ for dev, P1V2+ for prod)
- **Azure SQL Database** (S1+ for dev, S3+ for prod)
- **Storage Account** (Standard LRS)
- **Key Vault**
- **Application Insights**
- **Azure AD B2C** tenant

### Deployment Process

1. Backend: Deploy via `az webapp deployment` or GitHub Actions
2. Frontend: Deploy to Vercel or Azure Static Web Apps
3. Database: Run migration scripts manually or via CI/CD
4. Configuration: Update Key Vault secrets and App Service settings

## Important Notes

### WSL SQL Server Connection

If developing on WSL and connecting to SQL Server on Windows host:

```bash
# Use WSL host IP, not localhost
Server=172.31.208.1,14333
sqlcmd -S 172.31.208.1,14333 -U sqladmin -P YourPassword -C -d FireProofDB
```

### Vite Build Issues

If encountering tree-shaking issues where helper functions are removed:
- Use direct method calls instead of wrapper functions
- Check build hash changes to detect tree-shaking
- Use timestamp filenames temporarily to debug: `entryFileNames: 'assets/[name]-${Date.now()}.js'`

### Service Scope Factory Pattern

For Singleton services needing Scoped dependencies (e.g., background jobs):

```csharp
public class InspectionReminderJob
{
    private readonly IServiceScopeFactory _serviceScopeFactory;

    public async Task ExecuteAsync()
    {
        using var scope = _serviceScopeFactory.CreateScope();
        var service = scope.ServiceProvider.GetRequiredService<IInspectionService>();
        // Use service
    }
}
```

## Reference Documentation

- **Technical Requirements**: `REQUIREMENTS.md`
- **Implementation Checklist**: `TODO.md` (phased approach)
- **Future Enhancements**: `docs/FUTURE.md`
- **Quick Start**: `QUICKSTART.md`
- **Project README**: `README.md`

## Current Phase

**Phase 1.1: Foundation** (Weeks 1-2)

Focus areas:
- Azure infrastructure setup
- Database schema creation
- Basic API skeleton with authentication
- Frontend skeleton with routing

Refer to `TODO.md` for detailed task breakdown and priorities.
