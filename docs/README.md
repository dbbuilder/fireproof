# Fire Extinguisher Inspection System

## Overview

The Fire Extinguisher Inspection System is a comprehensive, multi-tenant SaaS platform for managing fire extinguisher inspections, maintenance tracking, and compliance reporting. Built with modern cloud-native architecture on Azure, the system provides mobile-first workflows with tamper-proof audit trails and offline capabilities.

## Key Features

- ✅ **Multi-Tenant Architecture**: Complete data isolation with shared infrastructure
- ✅ **Role-Based Access Control**: Hierarchical permissions for system, tenant, location, and inspector roles
- ✅ **Mobile-First Design**: Progressive Web App with offline support, native apps in Phase 2
- ✅ **Barcode/QR Code Scanning**: Fast identification of locations and extinguishers
- ✅ **Tamper-Proof Inspections**: Cryptographic hashing and blockchain-style chaining
- ✅ **GPS Validation**: Location verification for on-site inspections
- ✅ **Comprehensive Reporting**: Monthly, annual, and compliance reports with PDF export
- ✅ **Photo Documentation**: Capture and store inspection photos with EXIF validation
- ✅ **Automated Reminders**: Email notifications for upcoming and overdue inspections
- ✅ **Maintenance Tracking**: Complete lifecycle management from installation to disposal

## Technology Stack

### Backend
- **.NET 8.0**: ASP.NET Core Web API on Azure Linux App Service
- **Azure SQL Database**: T-SQL stored procedures with Entity Framework Core
- **Azure Blob Storage**: Photo and document storage
- **Azure Key Vault**: Secrets management
- **Azure Application Insights**: Monitoring and telemetry
- **Serilog**: Structured logging
- **Polly**: Resilience and retry policies
- **Hangfire**: Background job processing

### Frontend
- **Vue.js 3**: Composition API with Vite build tool
- **Tailwind CSS 3**: Utility-first styling
- **Pinia**: State management
- **Vue Router**: Client-side routing
- **Axios**: HTTP client
- **Html5-QRCode**: Barcode/QR code scanning
- **PWA**: Offline-first capabilities

### Mobile (Phase 2)
- **iOS**: Swift 5.9+ with SwiftUI
- **Android**: Kotlin 1.9+ with Jetpack Compose

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Internet/Users                            │
└─────────────────┬───────────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────────┐
│              Azure Front Door (CDN/WAF)                      │
└─────────────────┬───────────────────────────────────────────┘
                  │
      ┌───────────┴───────────┐
      │                       │
┌─────▼─────────┐   ┌────────▼────────┐
│  Vercel/Azure │   │ Azure App Service│
│  Static Site  │   │   (.NET API)     │
│  (Vue.js PWA) │   │                  │
└───────────────┘   └────────┬─────────┘
                             │
                ┌────────────┼────────────┐
                │            │            │
         ┌──────▼─────┐ ┌───▼─────┐ ┌───▼──────┐
         │Azure SQL   │ │Key Vault│ │Blob      │
         │Database    │ │         │ │Storage   │
         └────────────┘ └─────────┘ └──────────┘
                             │
                    ┌────────▼────────┐
                    │App Insights     │
                    │(Monitoring)     │
                    └─────────────────┘
```

## Project Structure

```
fire-extinguisher-system/
├── docs/                           # Documentation
│   ├── REQUIREMENTS.md             # Complete requirements specification
│   ├── README.md                   # This file
│   ├── TODO.md                     # Implementation checklist
│   └── FUTURE.md                   # Future enhancements
├── database/                       # Database scripts
│   ├── scripts/                    # Schema and stored procedure scripts
│   │   ├── 001_CreateCoreSchema.sql
│   │   ├── 002_CreateTenantSchema.sql
│   │   ├── 003_CreateStoredProcedures.sql
│   │   └── 004_SeedData.sql
│   └── migrations/                 # EF Core migrations
├── backend/                        # .NET API
│   └── FireExtinguisherInspection.API/
│       ├── Controllers/            # API controllers
│       ├── Models/                 # Request/response/entity models
│       ├── Services/               # Business logic
│       ├── Data/                   # Database access
│       ├── Middleware/             # Custom middleware
│       ├── Infrastructure/         # Cross-cutting concerns
│       └── Utilities/              # Helper classes
├── frontend/                       # Vue.js web app
│   └── fire-extinguisher-web/
│       ├── src/
│       │   ├── components/         # Vue components
│       │   ├── views/              # Page views
│       │   ├── stores/             # Pinia stores
│       │   ├── services/           # API services
│       │   ├── utils/              # Utility functions
│       │   └── router/             # Vue Router configuration
│       └── public/                 # Static assets
├── mobile/                         # Native mobile apps (Phase 2)
│   ├── ios/                        # Swift iOS app
│   └── android/                    # Kotlin Android app
├── infrastructure/                 # IaC templates
│   └── azure/                      # Azure ARM/Bicep templates
└── tests/                          # Test projects
    ├── unit/                       # Unit tests
    ├── integration/                # Integration tests
    └── e2e/                        # End-to-end tests
```

## Getting Started

### Prerequisites

#### Development Environment
- **Windows 10/11** or **macOS** or **Linux**
- **Visual Studio 2022** or **Visual Studio Code** with C# extension
- **.NET 8.0 SDK** ([Download](https://dotnet.microsoft.com/download/dotnet/8.0))
- **Node.js 18+** with npm ([Download](https://nodejs.org/))
- **SQL Server 2019+** or **Azure SQL Database**
- **Git** for version control

#### Azure Resources (for deployment)
- Azure subscription
- Azure SQL Database (S1 or higher)
- Azure App Service (B1 or higher)
- Azure Storage Account (Standard LRS)
- Azure Key Vault
- Azure Application Insights

### Initial Setup

#### 1. Clone the Repository

```bash
git clone <repository-url>
cd fireproof
```

#### 2. Database Setup

```bash
# Connect to your SQL Server instance
# Run the database scripts in order:
# 1. 001_CreateCoreSchema.sql
# 2. 002_CreateTenantSchema.sql (creates first tenant schema)
# 3. 003_CreateStoredProcedures.sql
# 4. 004_SeedData.sql (optional test data)

# Using SQL Server Management Studio or Azure Data Studio
# Execute each script against your database
```

#### 3. Backend Setup

```bash
cd backend/FireExtinguisherInspection.API

# Restore NuGet packages
dotnet restore

# Update appsettings.Development.json with your connection strings
# See appsettings.json for configuration options

# Run database migrations (if using EF Core migrations)
dotnet ef database update

# Run the API
dotnet run
```

The API will start on `https://localhost:5001` (or `http://localhost:5000`)

#### 4. Frontend Setup

```bash
cd frontend/fire-extinguisher-web

# Install npm packages
npm install

# Update .env.development with your API URL
# Create .env.development file:
# VITE_API_BASE_URL=https://localhost:5001
# VITE_AZURE_B2C_CLIENT_ID=<your-client-id>
# VITE_AZURE_B2C_TENANT_NAME=<your-tenant-name>

# Run the development server
npm run dev
```

The web app will start on `http://localhost:5173`

### Configuration

#### Backend Configuration (appsettings.json)

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=<server>;Database=<database>;User ID=<user>;Password=<password>"
  },
  "AzureAd": {
    "Instance": "https://<tenant>.b2clogin.com/",
    "Domain": "<tenant>.onmicrosoft.com",
    "TenantId": "<tenant-id>",
    "ClientId": "<client-id>"
  },
  "AzureKeyVault": {
    "VaultUri": "https://<keyvault-name>.vault.azure.net/"
  },
  "AzureStorage": {
    "ConnectionString": "<storage-connection-string>",
    "ContainerName": "inspection-photos"
  },
  "ApplicationInsights": {
    "InstrumentationKey": "<instrumentation-key>"
  }
}
```

**Note**: Never commit appsettings.Development.json or .env files with secrets. Use Azure Key Vault for production.

#### Frontend Configuration (.env.development)

```env
VITE_API_BASE_URL=https://localhost:5001
VITE_AZURE_B2C_CLIENT_ID=<your-client-id>
VITE_AZURE_B2C_TENANT_NAME=<your-tenant-name>
VITE_AZURE_B2C_POLICY_NAME=B2C_1_signupsignin
```

## Development Workflow

### Running Locally

#### Backend
```bash
cd backend/FireExtinguisherInspection.API
dotnet watch run
```

#### Frontend
```bash
cd frontend/fire-extinguisher-web
npm run dev
```

### Building for Production

#### Backend
```bash
cd backend/FireExtinguisherInspection.API
dotnet publish -c Release -o ./publish
```

#### Frontend
```bash
cd frontend/fire-extinguisher-web
npm run build
# Outputs to dist/ folder
```

### Testing

#### Backend Unit Tests
```bash
cd tests/unit
dotnet test
```

#### Frontend Unit Tests
```bash
cd frontend/fire-extinguisher-web
npm run test:unit
```

#### E2E Tests
```bash
cd tests/e2e
npm run test:e2e
```

## Deployment

### Azure Deployment

#### Option 1: Azure DevOps or GitHub Actions (Recommended)

See `.github/workflows/` or `azure-pipelines.yml` for CI/CD configuration.

#### Option 2: Manual Deployment

##### Backend to Azure App Service
```bash
# Build and publish
cd backend/FireExtinguisherInspection.API
dotnet publish -c Release -o ./publish

# Deploy using Azure CLI
az webapp deployment source config-zip \
  --resource-group <resource-group> \
  --name <app-service-name> \
  --src ./publish.zip
```

##### Frontend to Vercel
```bash
cd frontend/fire-extinguisher-web

# Install Vercel CLI
npm i -g vercel

# Deploy
vercel --prod
```

##### Frontend to Azure Static Web Apps
```bash
# Using Azure CLI
az staticwebapp create \
  --name fire-extinguisher-web \
  --resource-group <resource-group> \
  --source ./frontend/fire-extinguisher-web \
  --location "West US 2" \
  --branch main
```

### Environment Variables

Set the following environment variables in Azure App Service:

```
ASPNETCORE_ENVIRONMENT=Production
ConnectionStrings__DefaultConnection=<from-key-vault>
AzureKeyVault__VaultUri=https://<keyvault>.vault.azure.net/
```

Use Azure Key Vault references for sensitive values:
```
@Microsoft.KeyVault(SecretUri=https://<keyvault>.vault.azure.net/secrets/<secret-name>/)
```

## API Documentation

Once the API is running, access the Swagger UI at:
- Development: `https://localhost:5001/swagger`
- Production: `https://your-api.azurewebsites.net/swagger`

## Security

### Authentication
- Azure AD B2C with JWT tokens
- Token expiration: 15 minutes
- Refresh token rotation enabled
- MFA support

### Authorization
- Role-based access control (RBAC)
- Claims-based authorization
- Tenant-level isolation
- Resource-level permissions

### Data Protection
- Encryption at rest: Azure SQL TDE
- Encryption in transit: TLS 1.2+
- Secrets: Azure Key Vault
- Password hashing: Identity default (PBKDF2)

### Tamper-Proofing
- HMAC-SHA256 signatures on inspections
- Hash chaining (blockchain-style)
- Immutable audit logs
- GPS and timestamp validation

## Monitoring & Logging

### Application Insights
- Automatic dependency tracking
- Custom business metrics
- Real-time analytics
- Alerts and notifications

### Structured Logging (Serilog)
```csharp
_logger.LogInformation(
    "Inspection {InspectionId} completed by {InspectorId} at {LocationId}",
    inspectionId, inspectorId, locationId
);
```

### Health Checks
- `/health` - Overall health
- `/health/ready` - Readiness probe
- `/health/live` - Liveness probe

## Troubleshooting

### Common Issues

#### Database Connection Fails
```
Error: Cannot connect to SQL Server
```
**Solution**: Verify connection string in appsettings.json and ensure SQL Server is running.

#### API Returns 401 Unauthorized
```
Error: 401 Unauthorized
```
**Solution**: Check Azure AD B2C configuration and ensure JWT token is valid.

#### Barcode Scanning Not Working
```
Error: Camera permission denied
```
**Solution**: Ensure browser has camera permissions. Check browser console for errors.

#### Offline Sync Fails
```
Error: Failed to sync offline inspections
```
**Solution**: Check network connectivity and API availability. Review browser console logs.

## Support

For questions or issues:
- Create an issue in the GitHub repository
- Email: support@yourcompany.com
- Documentation: https://docs.yourcompany.com

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Standards
- Follow .NET coding conventions
- Use ESLint and Prettier for frontend code
- Write unit tests for new features
- Update documentation as needed

## License

Copyright (c) 2025 Your Company. All rights reserved.

---

## Quick Reference

### API Endpoints

```
Auth:        POST /api/auth/login, /api/auth/refresh
Tenants:     GET|POST|PUT /api/tenants
Locations:   GET|POST|PUT|DELETE /api/locations
Extinguishers: GET|POST|PUT|DELETE /api/extinguishers
Inspections: GET|POST|PUT /api/inspections
Reports:     GET /api/reports/monthly, /annual, /compliance
```

### Database Connection

```bash
# Local SQL Server
Server=localhost;Database=FireExtinguisherDB;Trusted_Connection=True

# Azure SQL Database
Server=tcp:<server>.database.windows.net,1433;
Database=<database>;User ID=<user>;Password=<password>;
Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;
```

### Useful Commands

```bash
# Backend
dotnet restore                  # Restore packages
dotnet build                    # Build solution
dotnet run                      # Run API
dotnet test                     # Run tests
dotnet ef migrations add <name> # Add migration
dotnet ef database update       # Apply migrations

# Frontend
npm install                     # Install packages
npm run dev                     # Development server
npm run build                   # Production build
npm run preview                 # Preview production build
npm run lint                    # Lint code
npm run test                    # Run tests
```

---

**Version**: 1.0  
**Last Updated**: October 8, 2025  
**Status**: Active Development
