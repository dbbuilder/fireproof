# Fire Extinguisher Inspection System - Technical Requirements

## Document Version
- **Version:** 1.0.0
- **Date:** October 8, 2025
- **Status:** Draft for Implementation

## Executive Summary

The Fire Extinguisher Inspection System is a comprehensive multi-tenant SaaS platform designed to manage fire safety compliance across multiple locations and organizations. The system provides web-based and native mobile applications for conducting inspections, tracking maintenance, generating compliance reports, and ensuring tamper-proof audit trails.

## Business Requirements

### BR-1: Multi-Tenant Architecture
**Priority:** Critical  
**Description:** The system must support multiple independent organizations (tenants) with complete data isolation and separate billing.

**Acceptance Criteria:**
- Each tenant operates in an isolated environment with no cross-tenant data access
- Tenants can have different subscription tiers (Free, Standard, Premium)
- Resource limits enforced per subscription tier (locations, users, extinguishers)
- Tenant administrators can manage their own users and roles
- System administrators can manage all tenants from master dashboard

### BR-2: Role-Based Access Control (RBAC)
**Priority:** Critical  
**Description:** The system must implement hierarchical role-based permissions.

**Roles:**
- **System Admin:** Platform-wide management, tenant provisioning
- **Tenant Admin:** Organization management, user provisioning, billing
- **Location Manager:** Site-level management, inspection scheduling
- **Inspector:** Conduct inspections, upload photos, mark deficiencies
- **Viewer:** Read-only access to reports and dashboards

**Acceptance Criteria:**
- Users can be assigned multiple roles across different locations
- Permissions are enforced at API and UI levels
- Role changes take effect immediately
- Audit trail of all permission changes

### BR-3: Multi-Location Support
**Priority:** Critical  
**Description:** Tenants must be able to manage unlimited locations (within subscription limits).

**Acceptance Criteria:**
- Locations have complete address information including GPS coordinates
- Each location can have unlimited fire extinguishers
- Location-specific QR codes for quick identification
- Hierarchical location structures (e.g., Building > Floor > Room)
- Location-based reporting and compliance tracking

### BR-4: Fire Extinguisher Asset Management
**Priority:** Critical  
**Description:** Complete lifecycle tracking of fire extinguisher assets.

**Acceptance Criteria:**
- Unique asset tags (barcode/QR code) for each extinguisher
- Track manufacturer, model, serial number, installation date
- Support all extinguisher types (ABC, BC, K, CO2, etc.)
- Maintenance history tracking
- Hydrostatic test scheduling
- Deficiency tracking and remediation workflow
- Photo documentation storage

### BR-5: Inspection Management
**Priority:** Critical  
**Description:** Support monthly, annual, and hydrostatic test inspections with configurable checklists.

**Inspection Types:**
1. **Monthly Visual Inspection:** Quick visual checks (pressure, location, accessibility)
2. **Annual Inspection:** Detailed inspection by certified technician
3. **Hydrostatic Test:** Pressure testing every 5-12 years depending on type

**Acceptance Criteria:**
- Configurable inspection checklists per inspection type
- Mandatory and optional checklist items
- Photo requirements for specific items
- Pass/Fail/Needs Service results
- Inspector notes and observations
- Start and end timestamps
- GPS coordinates captured during inspection
- Offline inspection support with sync capability

### BR-6: Barcode/QR Code System
**Priority:** Critical  
**Description:** Generate and scan barcodes for locations and extinguishers.

**Acceptance Criteria:**
- Generate printable QR codes for locations and extinguishers
- QR codes contain encoded data (tenant ID, location ID, extinguisher ID)
- Web-based scanning using device camera
- Native mobile scanning with high accuracy
- Bulk QR code generation and printing
- QR code validation before inspection starts

### BR-7: Tamper-Proofing and Audit Trail
**Priority:** Critical  
**Description:** Ensure inspection data integrity and prevent manipulation.

**Tamper-Proofing Mechanisms:**
1. **Digital Signatures:** HMAC-SHA256 hash of inspection data
2. **Hash Chaining:** Each inspection references the hash of the previous inspection
3. **GPS Validation:** Verify inspector was at location during inspection
4. **Photo EXIF Validation:** Verify photo capture time and device
5. **Immutable Audit Log:** All changes logged with who, what, when, where

**Acceptance Criteria:**
- All inspection records are cryptographically signed
- Any data tampering is detectable
- GPS coordinates must be within acceptable radius of location
- Photos must be captured during inspection timeframe
- Audit log cannot be modified or deleted
- Tamper alerts flagged for review

### BR-8: Reporting and Compliance
**Priority:** High  
**Description:** Generate comprehensive reports for regulatory compliance.

**Report Types:**
1. **Monthly Inspection Report:** All inspections completed in the month
2. **Annual Inspection Report:** Yearly compliance summary
3. **Compliance Dashboard:** Real-time status of all locations
4. **Deficiency Report:** Outstanding issues requiring attention
5. **Inspection History:** Complete timeline for a specific extinguisher
6. **Location Summary:** All extinguishers at a location

**Acceptance Criteria:**
- Reports available in PDF, Excel, and CSV formats
- Scheduled automated report generation
- Email delivery of reports
- Customizable report parameters (date range, location, status)
- Visual compliance indicators (color-coded status)
- Drill-down capability from summary to detail

### BR-9: Offline Capability
**Priority:** High  
**Description:** Mobile applications must function without internet connectivity.

**Acceptance Criteria:**
- Inspections can be conducted offline
- Photos captured and stored locally
- GPS coordinates captured offline
- Offline data encrypted and tamper-proof
- Automatic sync when connectivity restored
- Conflict resolution for offline edits
- Clear indication of sync status

### BR-10: Notification and Reminders
**Priority:** Medium  
**Description:** Automated reminders for upcoming inspections.

**Acceptance Criteria:**
- Email notifications for inspections due within 7 days
- Push notifications on mobile devices
- Dashboard indicators for overdue inspections
- Configurable reminder schedules
- Escalation to location managers if inspections overdue

## Technical Requirements

### TR-1: Backend Technology Stack
**Priority:** Critical  
**Technology:** .NET 8.0, Azure Linux App Service

**Requirements:**
- RESTful API using ASP.NET Core Web API
- Entity Framework Core 8.0 for database access (Stored Procedures only)
- Serilog for structured logging
- Polly for resilience and retry policies
- Hangfire for background job scheduling
- Azure Application Insights for monitoring
- Azure Key Vault for secret management
- Azure Blob Storage for file storage

**Acceptance Criteria:**
- API response time < 500ms for 95th percentile
- API availability > 99.5%
- All secrets stored in Key Vault (no hardcoded credentials)
- Comprehensive error handling and logging
- Health check endpoints for monitoring
- Swagger/OpenAPI documentation

### TR-2: Database Technology
**Priority:** Critical  
**Technology:** Azure SQL Database, T-SQL

**Requirements:**
- Shared database with tenant-specific schemas
- Row-Level Security (RLS) for additional isolation
- Stored procedures for all data access (no dynamic SQL)
- Parameterized queries to prevent SQL injection
- Full-text search for locations and extinguishers
- Temporal tables for audit history

**Acceptance Criteria:**
- Database response time < 100ms for simple queries
- Automated backups with 30-day retention
- Point-in-time restore capability
- Database encryption at rest (TDE)
- Connection pooling and resilience
- Index optimization for performance

### TR-3: Frontend Technology Stack
**Priority:** Critical  
**Technology:** Vue.js 3, Tailwind CSS

**Requirements:**
- Single Page Application (SPA) using Vue.js 3 Composition API
- Progressive Web App (PWA) capabilities
- Responsive design for mobile, tablet, desktop
- Tailwind CSS for styling
- Pinia for state management
- Vue Router for routing
- Axios for HTTP client with interceptors

**Acceptance Criteria:**
- Page load time < 2 seconds
- Lighthouse score > 90 for Performance, Accessibility, Best Practices
- Works on Chrome, Firefox, Safari, Edge (latest versions)
- Offline support for critical workflows
- Accessible (WCAG 2.1 AA compliance)

### TR-4: Mobile Technology Stack (Phase 2)
**Priority:** High  
**Technology:** Swift (iOS), Kotlin (Android)

**iOS Requirements:**
- Swift 5.9+ with SwiftUI
- Core Data for local persistence
- AVFoundation for camera and barcode scanning
- Core Location for GPS
- Background sync with URLSession
- Keychain for secure credential storage

**Android Requirements:**
- Kotlin 1.9+ with Jetpack Compose
- Room for local persistence
- CameraX and ML Kit for barcode scanning
- Google Play Services Location for GPS
- WorkManager for background sync
- EncryptedSharedPreferences for credential storage

**Acceptance Criteria:**
- App size < 50MB
- Cold start time < 3 seconds
- Offline-first architecture with automatic sync
- Battery efficient (no significant drain during normal use)
- Support iOS 15+ and Android 8.0+ (API 26+)

### TR-5: Authentication and Authorization
**Priority:** Critical  
**Technology:** Azure AD B2C, JWT

**Requirements:**
- Azure AD B2C for user authentication
- Multi-factor authentication (MFA) support
- JWT tokens for API authorization
- Refresh token rotation
- Token expiration (15 minutes for access, 7 days for refresh)
- Claims-based authorization

**Acceptance Criteria:**
- SSO support for enterprise customers
- Password reset flow
- Email verification for new accounts
- Session management
- Device tracking for suspicious login detection
- GDPR-compliant data handling

### TR-6: Security Requirements
**Priority:** Critical

**Requirements:**
1. **Data Encryption**
   - TLS 1.2+ for all data in transit
   - Transparent Data Encryption (TDE) for database
   - Azure Storage encryption at rest
   - Field-level encryption for sensitive data (if needed)

2. **API Security**
   - CORS configuration for known origins
   - Rate limiting per tenant (100 requests/minute)
   - Request validation and sanitization
   - SQL injection prevention (parameterized queries)
   - XSS prevention (output encoding)
   - CSRF protection for state-changing operations

3. **Compliance**
   - GDPR compliance (data export, right to deletion)
   - SOC 2 Type II compliance readiness
   - HIPAA compliance considerations (optional)

**Acceptance Criteria:**
- Penetration testing passed
- OWASP Top 10 vulnerabilities addressed
- Security audit trail for all sensitive operations
- Regular dependency vulnerability scans
- Incident response plan documented

### TR-7: Performance Requirements
**Priority:** High

**Requirements:**
- **API Response Times:**
  - Simple GET requests: < 200ms
  - Complex queries: < 500ms
  - Report generation: < 5 seconds (async for complex reports)
  
- **Database Performance:**
  - Query execution: < 100ms for 95th percentile
  - Concurrent users: Support 1000+ simultaneous users per tenant
  
- **Scalability:**
  - Horizontal scaling via multiple App Service instances
  - Database read replicas for reporting
  - CDN for static assets
  - Blob storage for photos (up to 10MB per photo)

**Acceptance Criteria:**
- Load testing validates 1000 concurrent users
- Stress testing identifies breaking points
- Auto-scaling configured for App Service
- Caching strategy implemented (Redis or in-memory)

### TR-8: Backup and Disaster Recovery
**Priority:** Critical

**Requirements:**
- Database: Automated daily backups, 30-day retention
- Blob Storage: Geo-redundant storage (GRS) with soft delete
- Recovery Time Objective (RTO): < 4 hours
- Recovery Point Objective (RPO): < 1 hour
- Documented disaster recovery procedures
- Quarterly disaster recovery testing

**Acceptance Criteria:**
- Automated backup verification
- Point-in-time restore tested
- Geo-failover tested for critical components
- Runbook documentation complete

### TR-9: Monitoring and Observability
**Priority:** High

**Requirements:**
- Application Insights for telemetry
- Custom metrics for business events
- Distributed tracing for requests
- Alerting for critical errors
- Dashboard for system health
- Log aggregation and search (Serilog with Application Insights sink)

**Metrics to Track:**
- API request rates and latency
- Error rates and types
- Database query performance
- Background job execution
- User activity patterns
- Inspection completion rates

**Acceptance Criteria:**
- Real-time dashboard available
- Alerts configured for critical issues
- On-call rotation defined
- Incident response procedures documented

### TR-10: DevOps and CI/CD
**Priority:** High

**Requirements:**
- Source control: Git (GitHub)
- CI/CD: GitHub Actions or Azure DevOps
- Environments: Development, Staging, Production
- Automated testing: Unit, integration, E2E
- Infrastructure as Code: Bicep or Terraform
- Blue-green deployment for zero-downtime releases

**Pipeline Stages:**
1. Build and compile
2. Unit tests
3. Integration tests
4. Security scanning
5. Deploy to staging
6. Automated E2E tests
7. Deploy to production (manual approval)

**Acceptance Criteria:**
- Pipeline runs in < 15 minutes
- Automated rollback on failure
- Infrastructure provisioned via code
- Secrets managed securely
- Deployment logs retained for 90 days

## Data Requirements

### DR-1: Data Retention
**Priority:** High

**Requirements:**
- Inspection records: Retained indefinitely (regulatory requirement)
- Audit logs: Retained for 7 years
- Photos: Retained for 7 years, archived to cold storage after 2 years
- User data: Deleted within 30 days of account closure (GDPR)
- Deleted tenant data: Soft delete for 90 days, then hard delete

### DR-2: Data Volume Estimates

**Assumptions per Tenant (Medium Size):**
- Locations: 50
- Extinguishers: 500
- Users: 25
- Monthly inspections: 500/month
- Photos per inspection: 3

**Annual Data Growth (per tenant):**
- Database: ~500 MB
- Blob Storage: ~20 GB (photos)

**System-wide (100 tenants):**
- Database: ~50 GB/year
- Blob Storage: ~2 TB/year

### DR-3: Data Privacy
**Priority:** Critical

**Requirements:**
- Personal data classification (PII, sensitive data)
- Data minimization (collect only necessary data)
- Purpose limitation (use data only for stated purposes)
- User consent management
- Right to data portability (export in JSON format)
- Right to deletion (complete data removal)

## Integration Requirements

### IR-1: Third-Party Integrations (Future)

**Potential Integrations:**
- Email: SendGrid or Azure Communication Services
- SMS: Twilio for urgent notifications
- Mapping: Google Maps or Azure Maps API
- Calendar: Microsoft Graph API for scheduling
- Accounting: QuickBooks or Xero for billing
- Identity Providers: SAML/OIDC for enterprise SSO

## Compliance Requirements

### CR-1: Fire Safety Regulations
**Priority:** Critical

**Requirements:**
- NFPA 10: Standard for Portable Fire Extinguishers
- OSHA regulations for workplace fire safety
- Local jurisdiction requirements (vary by location)

**Key Compliance Points:**
- Monthly visual inspections required
- Annual inspections by certified technician
- Hydrostatic testing per schedule
- Maintenance records retained
- Inspection tags/labels required

### CR-2: Data Protection Regulations
**Priority:** Critical

**Requirements:**
- GDPR (European Union)
- CCPA (California Consumer Privacy Act)
- State-specific privacy laws

**Compliance Features:**
- Privacy policy and terms of service
- Cookie consent management
- Data processing agreements
- User consent tracking
- Data export functionality
- Data deletion workflow

## Testing Requirements

### TR-11: Testing Strategy
**Priority:** High

**Test Types:**
1. **Unit Tests:** 80% code coverage minimum
2. **Integration Tests:** All API endpoints
3. **E2E Tests:** Critical user workflows
4. **Performance Tests:** Load and stress testing
5. **Security Tests:** Penetration testing, vulnerability scanning
6. **Accessibility Tests:** WCAG 2.1 AA compliance
7. **Mobile Tests:** Device testing matrix (iOS and Android)

**Acceptance Criteria:**
- All tests automated in CI/CD pipeline
- Test data generation for various scenarios
- Test environments mirror production
- Regression test suite maintained

## Documentation Requirements

### DR-4: Documentation Deliverables
**Priority:** High

**Required Documentation:**
1. **Technical Documentation**
   - Architecture diagrams
   - Database schema documentation
   - API documentation (Swagger/OpenAPI)
   - Deployment guides
   - Troubleshooting guides

2. **User Documentation**
   - User manuals (per role)
   - Video tutorials
   - FAQ and knowledge base
   - In-app help and tooltips

3. **Administrative Documentation**
   - System administration guide
   - Backup and recovery procedures
   - Security incident response plan
   - Disaster recovery runbook

4. **Developer Documentation**
   - Development setup guide
   - Coding standards and conventions
   - Git workflow and branching strategy
   - Release process documentation

## Success Metrics

### SM-1: Technical Metrics
- API uptime: > 99.5%
- API response time (p95): < 500ms
- Database query time (p95): < 100ms
- Page load time: < 2 seconds
- Mobile app crash rate: < 1%
- Zero security incidents

### SM-2: Business Metrics
- User adoption: 80% of users active monthly
- Inspection completion rate: > 95% on-time
- Customer satisfaction: NPS > 50
- System availability: > 99.9%
- Data accuracy: > 99.9%

### SM-3: Quality Metrics
- Bug density: < 1 bug per 1000 lines of code
- Test coverage: > 80%
- Code review completion: 100% of PRs
- Documentation coverage: 100% of public APIs

## Assumptions and Constraints

### Assumptions
1. Users have modern smartphones with camera and GPS
2. Internet connectivity available in most locations
3. Users are trained on fire safety inspection procedures
4. Azure services available in target regions
5. Budget allocated for cloud infrastructure costs

### Constraints
1. Must use open-source technologies where possible (no per-license fees)
2. Phase 1 (web) must be completed in 10 weeks
3. Initial deployment supports 100 tenants maximum
4. Budget: ~$250/month for Azure services (production)
5. No dedicated operations team (must be low-maintenance)

## Risks and Mitigations

### Risk 1: Offline Data Synchronization Conflicts
**Likelihood:** Medium  
**Impact:** High  
**Mitigation:** Implement last-write-wins with clear conflict indicators. User can review and resolve conflicts manually.

### Risk 2: Tamper-Proof Mechanism Bypass
**Likelihood:** Low  
**Impact:** Critical  
**Mitigation:** Multiple layered security measures (hashing, GPS validation, EXIF validation). Regular security audits.

### Risk 3: Mobile App Performance on Older Devices
**Likelihood:** Medium  
**Impact:** Medium  
**Mitigation:** Set minimum OS requirements. Optimize image compression. Progressive enhancement approach.

### Risk 4: Azure Cost Overruns
**Likelihood:** Medium  
**Impact:** Medium  
**Mitigation:** Implement cost alerts. Resource tagging and monitoring. Auto-shutdown for non-production environments.

### Risk 5: GDPR Compliance Gaps
**Likelihood:** Low  
**Impact:** High  
**Mitigation:** Legal review of data handling. Implement all required privacy features. Regular compliance audits.

## Glossary

- **AHJ:** Authority Having Jurisdiction - Local fire safety regulatory body
- **HMAC:** Hash-based Message Authentication Code - Cryptographic integrity check
- **NFPA:** National Fire Protection Association
- **OSHA:** Occupational Safety and Health Administration
- **PWA:** Progressive Web App
- **RBAC:** Role-Based Access Control
- **RLS:** Row-Level Security
- **RTO:** Recovery Time Objective
- **RPO:** Recovery Point Objective
- **SaaS:** Software as a Service
- **TDE:** Transparent Data Encryption

## Approval

This requirements document must be reviewed and approved by:
- Product Owner
- Technical Architect
- Security Officer
- Compliance Officer

**Status:** Pending Approval  
**Next Review Date:** [To be determined]

---

**Document Control:**
- Created: October 8, 2025
- Last Modified: October 8, 2025
- Version: 1.0.0
- Owner: Development Team
