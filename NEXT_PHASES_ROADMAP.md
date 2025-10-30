# FireProof - Next Phases Roadmap

**Created:** October 30, 2025
**Status:** Planning Document
**Priority Framework:** P0 (Critical) → P1 (High) → P2 (Medium) → P3 (Nice-to-have)

---

## Current State (October 30, 2025)

### ✅ Completed Features

#### Core Platform
- Multi-tenant SaaS architecture with RLS (Row-Level Security)
- Complete authentication system (JWT + Refresh tokens)
- Password reset via email (SendGrid)
- Tenant management and selection
- Audit logging

#### Inspection Workflow
- Inspector mobile app (PWA) deployed at https://inspect.fireproofapp.net
- Barcode scanning for locations and extinguishers (13+ formats supported)
- Photo capture with EXIF metadata validation
- Digital signatures
- GPS location verification
- Offline-first architecture with sync

#### Admin Features (NEW - October 30, 2025)
- **User Management:** Full CRUD, system role assignment, tenant role management (SystemAdmin only)
- **Checklist Template Management:** View system templates (NFPA 10, Title 19, ULC), create/edit/delete custom templates, template duplication
- 7 new stored procedures deployed
- E2E Playwright tests created
- ~3,900 lines of code

#### Infrastructure
- Backend: Azure App Service (.NET 8.0) at https://api.fireproofapp.net
- Frontend: Azure Static Web Apps at https://www.fireproofapp.net
- Inspector App: Vercel at https://inspect.fireproofapp.net
- Database: SQL Server with 80 stored procedures
- CI/CD: GitHub Actions with automatic deployments

---

## Phase 2: Data Management & Reporting (P0 - Next 2-4 Weeks)

### 2.1 Data Import/Export System
**Priority:** P0
**Effort:** 2 weeks
**Value:** High - Critical for onboarding and compliance

#### Features:
- **CSV Import:**
  - Bulk import extinguishers with validation
  - Bulk import locations with geocoding
  - Template-based import with field mapping
  - Error reporting and rollback capability
  - Import history and audit trail

- **Historical Inspection Data Import:** ⭐ **NEW**
  - Import past inspection records from CSV files
  - Visual field mapping interface (drag-and-drop column matching)
  - Support for various date formats and inspection types
  - Automatic validation against existing extinguishers
  - Preserves historical compliance status
  - Configurable lockout feature:
    - SystemAdmin can enable/disable historical imports
    - Default: **Enabled for initial onboarding**
    - Can be permanently locked after first production import
    - Prevents accidental data tampering after go-live
    - Audit log entry when feature is locked/unlocked
  - Pre-import preview with error detection
  - Dry-run mode (validate without importing)
  - Mapping templates can be saved for reuse
  - Support for inspection photos (via URL references or zip upload)

  **Sample CSV Structure:**
  ```csv
  ExtinguisherBarcode,InspectionDate,InspectorName,InspectionType,PassFail,Deficiencies,Notes,LocationCode
  EXT-001,2024-01-15,John Smith,Monthly,Pass,,All checks OK,BLDG-A-FL1
  EXT-002,2024-01-15,John Smith,Monthly,Fail,"Pressure low, Hose damaged",Needs service,BLDG-A-FL1
  ```

  **Field Mapping UI:**
  - Left column: CSV headers from uploaded file
  - Right column: FireProof database fields (dropdown)
  - Auto-detection of common field names
  - Preview first 10 rows with mapped values
  - Validation messages for each row
  - Required field indicators
  - Data transformation options (date format, text case, etc.)

- **Excel Export:**
  - Export all extinguishers for a location
  - Export inspection history
  - Export compliance reports
  - Custom field selection
  - Multiple format support (XLSX, CSV, PDF)

- **Data Templates:**
  - Downloadable CSV/Excel templates
  - Pre-filled examples
  - Field validation rules documented
  - Barcode generation in bulk

#### Technical Implementation:
- Backend: EPPlus or ClosedXML for Excel processing
- Frontend: File upload component with progress tracking
- Field Mapping: React DnD or Vue Draggable for UI
- Validation: Server-side with detailed error messages
- Storage: Azure Blob Storage for large files
- Queue: Background jobs for large imports (Hangfire)
- Lockout: Feature flag stored in Tenants table (`AllowHistoricalImports` bit column)
- Preview: Sample processing with transaction rollback

#### Database Changes:
```sql
-- Add feature flag to Tenants table
ALTER TABLE dbo.Tenants ADD AllowHistoricalImports BIT NOT NULL DEFAULT 1;

-- Add audit log entry type
INSERT INTO dbo.AuditLogTypes (TypeName) VALUES ('HistoricalImportLockout');

-- Stored procedure to check/toggle feature
CREATE PROCEDURE dbo.usp_Tenant_ToggleHistoricalImports
  @TenantId UNIQUEIDENTIFIER,
  @Enable BIT,
  @UserId UNIQUEIDENTIFIER
AS
BEGIN
  -- Validation, update, audit logging
END
```

#### Security Considerations:
- Only SystemAdmin can disable historical imports permanently
- Once disabled, cannot be re-enabled (one-way operation)
- Confirmation dialog with warning: "This action cannot be undone"
- All historical imports are logged in AuditLog with file hash
- Import files are retained in blob storage for 90 days
- Row-level validation prevents invalid data (FK constraints)

#### User Stories:
1. As a TenantAdmin, I want to import 500 extinguishers from an Excel file so I can quickly onboard our facility
2. As a TenantAdmin, I want to import 3 years of historical inspection data from our old system so we have a complete compliance history
3. As a TenantAdmin, I want to map CSV columns to FireProof fields visually so I don't need to reformat my data
4. As a SystemAdmin, I want to disable historical imports after go-live to prevent data tampering
5. As a LocationManager, I want to export all extinguishers at my location to Excel for offline review
6. As a SystemAdmin, I want to export all inspection data for compliance auditing

#### Example Workflow:
1. TenantAdmin uploads CSV with 2 years of inspection history
2. System shows field mapping UI with auto-detected matches
3. Admin adjusts mappings and sees preview of first 10 records
4. Admin runs dry-run validation → 5 errors found (invalid dates)
5. Admin fixes CSV and re-uploads
6. System validates all 2000 records → Success
7. Admin confirms import
8. Background job processes import in 2 minutes
9. Admin reviews imported data in dashboard
10. SystemAdmin locks historical imports feature permanently
11. All future inspections must be done through normal workflow

---

### 2.2 Advanced Reporting Dashboard
**Priority:** P0
**Effort:** 2 weeks
**Value:** High - Core business value

#### Features:
- **Compliance Dashboard:**
  - Percentage of extinguishers up-to-date
  - Inspections due this week/month
  - Overdue inspections by location
  - Compliance trends over time
  - Deficiency tracking

- **Interactive Charts:**
  - Pass/fail rates by location
  - Inspection completion velocity
  - Inspector performance metrics
  - Extinguisher type distribution
  - Maintenance cost analysis

- **Scheduled Reports:**
  - Daily/weekly/monthly email reports
  - Customizable report templates
  - Auto-send to stakeholders
  - PDF generation with branding

- **Real-time Alerts:**
  - Inspections overdue
  - Critical deficiencies found
  - Low inspector activity
  - System health issues

#### Technical Implementation:
- Frontend: Chart.js or Recharts for visualizations
- Backend: Aggregate stored procedures for metrics
- Email: SendGrid with HTML templates
- PDF: Puppeteer or DinkToPdf
- Caching: Redis for expensive queries
- Real-time: SignalR for dashboard updates

#### User Stories:
1. As a TenantAdmin, I want to see a compliance dashboard showing all locations so I know where attention is needed
2. As a LocationManager, I want weekly email reports of my location's inspection status
3. As an Inspector, I want to see my inspection velocity compared to team average

---

## Phase 3: Notification System (P1 - 3-4 Weeks)

### 3.1 Multi-Channel Notifications
**Priority:** P1
**Effort:** 3 weeks
**Value:** High - Increases engagement and compliance

#### Features:
- **Email Notifications:**
  - Inspection reminders (7 days, 3 days, 1 day before due)
  - Overdue inspection alerts
  - Deficiency notifications
  - Daily/weekly digest of activities
  - Custom email templates per tenant

- **SMS Notifications (via Twilio):**
  - Critical alerts only
  - Opt-in for inspectors
  - Inspection assignment notifications
  - Urgent deficiency alerts

- **In-App Notifications:**
  - Bell icon with badge count
  - Notification center
  - Mark as read/unread
  - Action buttons (e.g., "View Inspection")
  - Real-time push via SignalR

- **Notification Preferences:**
  - User-level preferences (email, SMS, in-app)
  - Frequency control (immediate, daily digest, weekly digest)
  - Notification type filtering
  - Quiet hours

#### Technical Implementation:
- Backend: NotificationService with template engine
- Storage: Notifications table for history
- Queue: Hangfire for scheduled sends
- Email: SendGrid
- SMS: Twilio (already configured)
- Real-time: SignalR hub for WebSocket connections
- Frontend: Notification bell component

#### User Stories:
1. As an Inspector, I want SMS reminders when inspections are assigned to me
2. As a LocationManager, I want daily email digests of inspection activity at my locations
3. As a TenantAdmin, I want to configure notification preferences for my entire organization

---

## Phase 4: Native Mobile Apps (P1 - 8-12 Weeks)

### 4.1 iOS Native App (Swift/SwiftUI)
**Priority:** P1
**Effort:** 8 weeks
**Value:** High - Better performance and offline capabilities

#### Features:
- Native barcode scanning (AVFoundation)
- Native camera with advanced features
- Core Data for offline storage
- Background sync with conflict resolution
- Push notifications (APNs)
- FaceID/TouchID authentication
- GPS tracking with privacy controls
- Offline maps integration

#### Technical Stack:
- Language: Swift 5+
- UI Framework: SwiftUI
- Architecture: MVVM with Combine
- Networking: Alamofire
- Storage: Core Data + Realm
- Dependency Injection: Swinject
- Testing: XCTest

---

### 4.2 Android Native App (Kotlin)
**Priority:** P1
**Effort:** 8 weeks
**Value:** High - Reach Android users

#### Features:
- ML Kit barcode scanning
- CameraX for photos
- Room database for offline
- WorkManager for background sync
- Firebase Cloud Messaging
- Biometric authentication
- Location services
- Offline map support

#### Technical Stack:
- Language: Kotlin
- UI: Jetpack Compose
- Architecture: MVVM with Coroutines/Flow
- Networking: Retrofit + OkHttp
- Storage: Room + DataStore
- DI: Hilt
- Testing: JUnit + Espresso

---

## Phase 5: Advanced Scheduling & Automation (P1 - 4 Weeks)

### 5.1 Smart Scheduling System
**Priority:** P1
**Effort:** 3 weeks
**Value:** Medium-High - Reduces manual scheduling effort

#### Features:
- **Auto-Assignment:**
  - Assign inspections to inspectors based on workload
  - Route optimization for multiple locations
  - Skills-based assignment (certifications)
  - Timezone-aware scheduling

- **Recurring Inspection Schedules:**
  - Monthly, quarterly, annual frequencies
  - Auto-create inspections based on template
  - Custom recurrence patterns
  - Holiday exclusions

- **Calendar Integration:**
  - iCal export
  - Google Calendar sync
  - Outlook integration
  - Shared team calendars

- **Workload Balancing:**
  - Inspector capacity planning
  - Real-time availability tracking
  - Overtime alerts
  - Backup inspector assignments

#### Technical Implementation:
- Backend: Quartz.NET for scheduling
- Algorithm: Graph-based route optimization
- Calendar: iCal.NET library
- Frontend: FullCalendar.js
- Notifications: Email + SMS for assignments

---

### 5.2 Workflow Automation
**Priority:** P2
**Effort:** 2 weeks
**Value:** Medium - Reduces repetitive tasks

#### Features:
- **Automated Actions:**
  - Auto-approve inspections with no deficiencies
  - Auto-escalate overdue inspections to management
  - Auto-tag extinguishers by location/type
  - Auto-archive old inspections

- **Conditional Logic:**
  - If deficiency found → Send alert + Create work order
  - If inspection overdue > 30 days → Mark as critical
  - If extinguisher fails 3 times → Flag for replacement

- **Custom Workflows:**
  - Visual workflow builder (drag-and-drop)
  - Event triggers (inspection complete, deficiency found)
  - Multi-step approvals
  - Parallel and sequential actions

#### Technical Implementation:
- Backend: Workflow engine (Elsa Workflows or custom)
- Frontend: React Flow for visual builder
- Storage: Workflow definitions in JSON
- Execution: Background jobs with state persistence

---

## Phase 6: Integration Ecosystem (P2 - 6-8 Weeks)

### 6.1 External Integrations
**Priority:** P2
**Effort:** 6 weeks
**Value:** Medium - Expands market reach

#### Integrations:
- **ERP Systems:**
  - SAP integration for asset management
  - Oracle ERP integration
  - Microsoft Dynamics 365

- **CMMS (Computerized Maintenance Management):**
  - Fiix integration
  - UpKeep integration
  - Maintenance Connection

- **Payment Processors:**
  - Stripe for subscriptions
  - PayPal for invoicing
  - ACH payments

- **Document Management:**
  - SharePoint integration
  - Google Drive sync
  - Dropbox for photo backup

- **Communication:**
  - Slack notifications
  - Microsoft Teams webhooks
  - Zapier for custom integrations

#### Technical Implementation:
- Architecture: Plugin-based integration framework
- Authentication: OAuth 2.0 for third-party apps
- Data Sync: ETL pipelines with error handling
- API: RESTful + webhooks for real-time events
- Monitoring: Integration health dashboard

---

### 6.2 Public API & Developer Portal
**Priority:** P2
**Effort:** 4 weeks
**Value:** Medium - Enables custom integrations

#### Features:
- RESTful API with OpenAPI (Swagger) documentation
- API key management with rate limiting
- Webhook subscriptions
- SDKs (JavaScript, Python, C#)
- Developer documentation portal
- Sandbox environment for testing
- Usage analytics dashboard
- API versioning

---

## Phase 7: Enhanced Security & Compliance (P1 - 4 Weeks)

### 7.1 Advanced Security Features
**Priority:** P1
**Effort:** 3 weeks
**Value:** High - Required for enterprise customers

#### Features:
- **SSO (Single Sign-On):**
  - SAML 2.0 support
  - Azure AD integration
  - Okta integration
  - Google Workspace

- **IP Whitelisting:**
  - Restrict access by IP ranges
  - Office/VPN-only access
  - Geo-blocking

- **Session Management:**
  - Concurrent session limits
  - Force logout on all devices
  - Session activity logs
  - Idle timeout configuration

- **Data Encryption:**
  - Encryption at rest (Azure TDE)
  - Encryption in transit (TLS 1.3)
  - Field-level encryption for sensitive data
  - Key rotation policies

#### Technical Implementation:
- SSO: IdentityServer or Azure AD B2C
- IP Filtering: Middleware + Azure Front Door
- Encryption: Azure Key Vault + Transparent Data Encryption
- Audit: Detailed security event logging

---

### 7.2 Compliance Features
**Priority:** P1
**Effort:** 2 weeks
**Value:** High - Required for certifications

#### Features:
- **GDPR Compliance:**
  - Data export (machine-readable format)
  - Right to deletion (anonymization)
  - Consent management
  - Data processing agreements

- **SOC 2 Type II:**
  - Enhanced audit logging
  - Change management controls
  - Incident response procedures
  - Business continuity planning

- **HIPAA (if needed):**
  - BAA (Business Associate Agreement)
  - PHI encryption
  - Access controls
  - Breach notification

- **Compliance Reports:**
  - Auto-generated compliance documentation
  - Third-party audit support
  - Certification tracking
  - Policy management

---

## Phase 8: Performance & Scale (P2 - 3-4 Weeks)

### 8.1 Performance Optimization
**Priority:** P2
**Effort:** 3 weeks
**Value:** Medium-High - Improves user experience

#### Initiatives:
- **Frontend Optimization:**
  - Code splitting and lazy loading
  - Image optimization (WebP, lazy load)
  - Service Worker caching strategies
  - Bundle size reduction (tree shaking)
  - Critical CSS extraction

- **Backend Optimization:**
  - Query performance tuning (indexes, execution plans)
  - Response caching (Redis)
  - Database connection pooling
  - Async processing for heavy operations
  - Background job optimization

- **CDN & Edge:**
  - Azure CDN for static assets
  - Edge caching with Azure Front Door
  - Image resizing on-the-fly
  - Geographic distribution

#### Technical Implementation:
- Tools: Lighthouse, WebPageTest, Application Insights
- Monitoring: Real User Monitoring (RUM)
- Profiling: SQL Server Profiler, .NET Profiler
- Caching: Redis with sliding expiration
- CDN: Azure CDN + custom rules

---

### 8.2 Scalability Enhancements
**Priority:** P2
**Effort:** 2 weeks
**Value:** Medium - Prepares for growth

#### Features:
- Horizontal scaling (multiple App Service instances)
- Database read replicas for reporting
- Queue-based processing for imports
- Microservices for heavy operations
- Load testing and capacity planning

---

## Phase 9: Advanced Analytics & AI (P3 - 8-12 Weeks)

### 9.1 Predictive Analytics
**Priority:** P3
**Effort:** 8 weeks
**Value:** Medium - Differentiator

#### Features:
- Predict which extinguishers will fail next
- Maintenance cost forecasting
- Optimal inspection scheduling
- Anomaly detection in inspection patterns
- Resource allocation recommendations

#### Technical Stack:
- ML: Python with scikit-learn or Azure ML
- Data Pipeline: Azure Data Factory
- Visualization: Power BI embedded
- Storage: Azure Synapse Analytics

---

### 9.2 AI-Powered Features
**Priority:** P3
**Effort:** 6 weeks
**Value:** Low-Medium - Nice-to-have

#### Features:
- AI photo analysis (detect extinguisher issues automatically)
- Natural language deficiency descriptions
- Chatbot for common questions
- OCR for reading extinguisher labels
- Voice-to-text for inspection notes

---

## Phase 10: Customer Portal (P2 - 4-6 Weeks)

### 10.1 Self-Service Customer Portal
**Priority:** P2
**Effort:** 5 weeks
**Value:** Medium - Reduces support burden

#### Features:
- View inspection history
- Download compliance certificates
- Request additional services
- Manage billing and subscriptions
- View inspection photos
- Download inspection reports (PDF)
- Schedule new inspections
- Contact support with ticket tracking

#### Technical Implementation:
- Separate subdomain: portal.fireproofapp.net
- Limited API access (read-only mostly)
- Stripe Customer Portal integration
- White-label branding per tenant

---

## Summary: Recommended Prioritization

### Immediate (Next 4 Weeks):
1. ✅ **Phase 2.1:** Data Import/Export (2 weeks) - CRITICAL for customer onboarding
2. ✅ **Phase 2.2:** Advanced Reporting Dashboard (2 weeks) - HIGH business value

### Short-term (Weeks 5-12):
3. **Phase 3:** Notification System (3 weeks) - Increases engagement
4. **Phase 7.1:** Enhanced Security (3 weeks) - Required for enterprise sales
5. **Phase 5.1:** Smart Scheduling (3 weeks) - Reduces manual effort

### Medium-term (Months 4-6):
6. **Phase 4:** Native Mobile Apps (iOS + Android in parallel, 8-12 weeks)
7. **Phase 6.1:** External Integrations (6 weeks) - Market expansion
8. **Phase 8:** Performance & Scale (3 weeks) - Continuous improvement

### Long-term (Months 7-12):
9. **Phase 6.2:** Public API & Developer Portal (4 weeks)
10. **Phase 10:** Customer Portal (5 weeks)
11. **Phase 9:** Advanced Analytics & AI (8-12 weeks)

---

## Success Metrics

### Product Metrics:
- User adoption rate (MAU/total users)
- Inspector inspection velocity (inspections per day)
- Compliance rate (% of facilities compliant)
- Time to complete inspection
- Deficiency resolution time

### Business Metrics:
- Customer acquisition cost (CAC)
- Monthly recurring revenue (MRR)
- Customer churn rate
- Net Promoter Score (NPS)
- Support ticket volume

### Technical Metrics:
- API response time (p95 < 500ms)
- Error rate (< 0.1%)
- Uptime (99.9%)
- Deployment frequency (daily)
- Mean time to recovery (MTTR < 30 min)

---

## Risk Mitigation

### Technical Risks:
- Database performance degradation → Proactive monitoring + read replicas
- Third-party API failures → Circuit breakers + fallback strategies
- Security breaches → Penetration testing + bug bounty program

### Business Risks:
- Feature creep → Strict prioritization framework
- Scope expansion → Fixed time boxes for phases
- Competitor moves → Market analysis + rapid iteration

### Resource Risks:
- Key person dependencies → Documentation + knowledge sharing
- Skill gaps → Training + contractor support
- Burnout → Sustainable pace + realistic deadlines

---

## Next Steps (Action Items)

1. **Review & Approve** this roadmap with stakeholders
2. **Prioritize** Phase 2 features (Data Import/Export + Reporting)
3. **Estimate** detailed tasks for Phase 2.1 (2-week sprint)
4. **Assign** resources and set sprint start date
5. **Create** detailed user stories and acceptance criteria
6. **Set up** project tracking in GitHub Projects or Jira

---

**Document Version:** 1.0
**Last Updated:** October 30, 2025
**Next Review:** November 15, 2025
**Owner:** Development Team
