# FireProof - Fire Extinguisher Inspection System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![.NET](https://img.shields.io/badge/.NET-8.0-512BD4)](https://dotnet.microsoft.com/)
[![Vue.js](https://img.shields.io/badge/Vue.js-3.x-4FC08D)](https://vuejs.org/)
[![Azure](https://img.shields.io/badge/Azure-Cloud-0078D4)](https://azure.microsoft.com/)

A comprehensive multi-tenant SaaS platform for managing fire extinguisher inspections, compliance tracking, and regulatory reporting. Built with modern cloud-native architecture on Azure with .NET, Vue.js, and native mobile apps.

## 🔥 Features

### Core Capabilities
- **Multi-Tenant Architecture:** Complete isolation with tenant-specific schemas
- **Role-Based Access Control:** Hierarchical permissions (System Admin, Tenant Admin, Location Manager, Inspector, Viewer)
- **Multi-Location Support:** Manage unlimited locations with GPS tracking
- **Asset Management:** Complete lifecycle tracking of fire extinguishers
- **Mobile & Web:** Progressive Web App + Native iOS/Android apps (Phase 2)
- **Barcode/QR Code System:** Generate and scan codes for locations and extinguishers
- **Offline Capability:** Conduct inspections without connectivity, sync when online
- **Tamper-Proofing:** Cryptographic signatures, hash chaining, GPS validation
- **Comprehensive Reporting:** Monthly, annual, compliance dashboards with PDF/Excel export
- **Automated Reminders:** Email and push notifications for due inspections

### Inspection Types
1. **Monthly Visual Inspection:** Quick checks (pressure, location, accessibility)
2. **Annual Inspection:** Detailed inspection by certified technician  
3. **Hydrostatic Test:** Pressure testing per regulatory schedule

## 🏗️ Architecture

### Technology Stack

**Backend (Azure)**
- .NET 8.0 on Azure Linux App Service
- Azure SQL Database with T-SQL stored procedures
- Entity Framework Core 8.0 (Stored Procedures only)
- Azure Key Vault for secret management
- Azure Blob Storage for photos and documents
- Azure Application Insights for monitoring
- Serilog for structured logging
- Polly for resilience
- Hangfire for background jobs

**Frontend (Web)**
- Vue.js 3 (Composition API)
- Vite build tool
- Tailwind CSS 3
- Progressive Web App (PWA)
- Pinia state management
- Axios HTTP client

**Mobile (Phase 2.0)**
- iOS: Swift 5.9+ with SwiftUI
- Android: Kotlin 1.9+ with Jetpack Compose
- Offline-first architecture
- Native camera and GPS integration

### Architecture Diagram

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
```

## 🚀 Getting Started

### Prerequisites

**Development Tools:**
- .NET 8.0 SDK
- Node.js 18+ and npm
- SQL Server or Azure SQL Database
- Azure CLI (for deployment)
- Git

**Azure Resources:**
- Azure subscription
- App Service (Linux, B1 or higher)
- Azure SQL Database (S1 or higher)
- Azure Storage Account
- Azure Key Vault
- Azure Application Insights

### Local Development Setup

#### 1. Clone the Repository

```bash
git clone https://github.com/dbbuilder/fireproof.git
cd fireproof
```

#### 2. Database Setup

```bash
# Navigate to database scripts
cd database/scripts

# Run the setup scripts in order (using SQL Server Management Studio or Azure Data Studio)
# 001_CreateCoreSchema.sql
# 002_CreateTenantSchema.sql
# 003_CreateStoredProcedures.sql
# 004_SeedData.sql
```

#### 3. Backend Setup

```bash
cd backend/FireExtinguisherInspection.API

# Install dependencies
dotnet restore

# Update appsettings.Development.json with your connection strings
# Add secrets to Azure Key Vault or User Secrets for local dev

# Run migrations (if using EF migrations)
dotnet ef database update

# Run the API
dotnet run
```

The API will be available at `https://localhost:7001`

#### 4. Frontend Setup

```bash
cd frontend/fire-extinguisher-web

# Install dependencies
npm install

# Create .env.development file
cp .env.example .env.development

# Update API endpoint in .env.development
# VITE_API_BASE_URL=https://localhost:7001/api

# Run development server
npm run dev
```

The web app will be available at `http://localhost:5173`

### Configuration

#### Backend Configuration (appsettings.json)

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=tcp:your-server.database.windows.net,1433;Database=FireProofDB;"
  },
  "AzureAdB2C": {
    "Instance": "https://your-tenant.b2clogin.com",
    "Domain": "your-tenant.onmicrosoft.com",
    "ClientId": "your-client-id",
    "SignUpSignInPolicyId": "B2C_1_signupsignin"
  },
  "BlobStorage": {
    "ConnectionString": "DefaultEndpointsProtocol=https;AccountName=...",
    "ContainerName": "inspection-photos"
  },
  "ApplicationInsights": {
    "InstrumentationKey": "your-instrumentation-key"
  }
}
```

#### Frontend Configuration (.env)

```env
VITE_API_BASE_URL=https://your-api.azurewebsites.net/api
VITE_AZURE_AD_B2C_AUTHORITY=https://your-tenant.b2clogin.com/your-tenant.onmicrosoft.com/B2C_1_signupsignin
VITE_AZURE_AD_B2C_CLIENT_ID=your-client-id
```

## 📦 Deployment

### Backend Deployment to Azure

```bash
cd backend/FireExtinguisherInspection.API

# Build for release
dotnet publish -c Release -o ./publish

# Deploy using Azure CLI
az webapp deployment source config-zip \
  --resource-group fireproof-rg \
  --name fireproof-api \
  --src ./publish.zip
```

### Frontend Deployment to Vercel

```bash
cd frontend/fire-extinguisher-web

# Install Vercel CLI
npm i -g vercel

# Deploy
vercel --prod
```

Alternatively, connect your GitHub repository to Vercel for automatic deployments.

### Database Deployment

```bash
# Using Azure CLI to run migration scripts
az sql db create --resource-group fireproof-rg \
  --server fireproof-sql \
  --name FireProofDB \
  --service-objective S1

# Run migration scripts through Azure Data Studio or sqlcmd
```

## 🧪 Testing

### Backend Tests

```bash
cd backend/FireExtinguisherInspection.API

# Run all tests
dotnet test

# Run with coverage
dotnet test /p:CollectCoverage=true /p:CoverageReportsDirectory=./coverage
```

### Frontend Tests

```bash
cd frontend/fire-extinguisher-web

# Run unit tests
npm run test:unit

# Run E2E tests
npm run test:e2e
```

## 📊 Project Structure

```
fireproof/
├── docs/                          # Documentation
│   ├── REQUIREMENTS.md            # Technical requirements
│   ├── README.md                  # This file
│   ├── TODO.md                    # Implementation checklist
│   └── FUTURE.md                  # Future enhancements
├── database/                      # Database scripts
│   ├── scripts/                   # SQL creation scripts
│   │   ├── 001_CreateCoreSchema.sql
│   │   ├── 002_CreateTenantSchema.sql
│   │   ├── 003_CreateStoredProcedures.sql
│   │   └── 004_SeedData.sql
│   └── migrations/                # EF Core migrations
├── backend/                       # .NET API
│   └── FireExtinguisherInspection.API/
│       ├── Controllers/           # API endpoints
│       ├── Services/              # Business logic
│       ├── Data/                  # Database access
│       ├── Models/                # DTOs and entities
│       ├── Middleware/            # Custom middleware
│       └── Infrastructure/        # Cross-cutting concerns
├── frontend/                      # Vue.js web app
│   └── fire-extinguisher-web/
│       ├── src/
│       │   ├── components/        # Vue components
│       │   ├── views/             # Page components
│       │   ├── stores/            # Pinia stores
│       │   ├── services/          # API services
│       │   └── utils/             # Helper functions
│       └── public/                # Static assets
├── mobile/                        # Native mobile apps (Phase 2)
│   ├── ios/                       # iOS Swift app
│   └── android/                   # Android Kotlin app
├── infrastructure/                # IaC templates
│   ├── azure/
│   │   └── arm-templates/         # ARM templates
│   └── bicep/                     # Bicep templates
├── tests/                         # Test projects
│   ├── unit/                      # Unit tests
│   ├── integration/               # Integration tests
│   └── e2e/                       # End-to-end tests
└── .github/                       # GitHub configuration
    └── workflows/                 # CI/CD pipelines
```

## 🔐 Security

### Authentication
- Azure AD B2C with MFA support
- JWT tokens (15-minute expiration)
- Refresh token rotation
- Device fingerprinting

### Data Protection
- TLS 1.2+ for all communications
- Transparent Data Encryption (TDE) on database
- Azure Blob Storage encryption at rest
- Azure Key Vault for secrets management

### Tamper-Proofing
- HMAC-SHA256 digital signatures on inspections
- Hash chaining (blockchain-style) for audit trail
- GPS coordinate validation
- Photo EXIF data validation
- Immutable audit logs

### Compliance
- GDPR compliant (data export, right to deletion)
- SOC 2 Type II readiness
- OSHA and NFPA 10 alignment

## 📈 Monitoring

### Application Insights Dashboards
- API request rates and latency
- Error rates and exception tracking
- Database query performance
- User activity metrics
- Custom business metrics (inspection completion rates)

### Alerts Configured
- API availability < 99.5%
- Response time > 1 second
- Error rate > 1%
- Database DTU > 80%
- Storage capacity > 90%

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Workflow
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Standards
- Follow C# coding conventions for backend
- Use ESLint/Prettier for frontend code
- Write unit tests for new features
- Update documentation as needed
- All PRs require code review

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- NFPA for fire safety standards
- Open-source community for excellent libraries
- Azure for reliable cloud infrastructure

## 📞 Support

### Documentation
- [Technical Requirements](docs/REQUIREMENTS.md)
- [Implementation Guide](docs/TODO.md)
- [Future Roadmap](docs/FUTURE.md)

### Contact
- **Issues:** [GitHub Issues](https://github.com/dbbuilder/fireproof/issues)
- **Discussions:** [GitHub Discussions](https://github.com/dbbuilder/fireproof/discussions)
- **Email:** support@fireproof.app

## 🗺️ Roadmap

### Phase 1.0 - Web Application (Current)
- ✅ Multi-tenant architecture
- ✅ Web-based inspection workflow
- ✅ Barcode scanning via webcam
- ✅ Reporting and dashboards
- ✅ Offline PWA capabilities

### Phase 2.0 - Native Mobile Apps (Q2 2026)
- 📱 iOS native app (Swift)
- 📱 Android native app (Kotlin)
- 📷 Native camera integration
- 🗺️ Enhanced GPS tracking
- 🔔 Push notifications

### Phase 3.0 - Advanced Features (Q4 2026)
- 🤖 AI-powered defect detection
- 📊 Predictive maintenance analytics
- 🌍 Multi-language support
- 🔗 Third-party integrations (QuickBooks, Salesforce)
- 📱 Smartwatch support

## 📊 Statistics

- **Lines of Code:** ~50,000
- **Test Coverage:** 80%+
- **API Endpoints:** 50+
- **Database Tables:** 20+
- **Supported Devices:** iOS 15+, Android 8.0+, Modern browsers

---

**Built with ❤️ by the FireProof Team**

*Making fire safety compliance simple and reliable.*
