# Fire Extinguisher Inspection System - Technical Requirements

## Document Control

**Version:** 1.0  
**Last Updated:** October 8, 2025  
**Status:** Draft  
**Owner:** Development Team

---

## 1. Executive Summary

The Fire Extinguisher Inspection System is a comprehensive multi-tenant SaaS platform designed to manage fire extinguisher compliance, inspections, maintenance tracking, and reporting. The system will support web-based management and mobile inspection capabilities with offline-first architecture, tamper-proofing, and automated compliance reporting.

### 1.1 Primary Objectives

- Enable organizations to track fire extinguisher assets across multiple locations
- Facilitate monthly and annual inspections with mobile devices
- Provide tamper-proof inspection records with cryptographic verification
- Generate automated compliance reports for regulatory requirements
- Support offline inspection workflows with synchronization
- Deliver role-based access control for multi-user organizations

### 1.2 Target Users

- **Facility Managers:** Oversee compliance across multiple locations
- **Fire Safety Inspectors:** Perform routine inspections
- **Maintenance Technicians:** Track service and repairs
- **Compliance Officers:** Generate reports for audits
- **System Administrators:** Manage tenants and users

---

## 2. Functional Requirements

### 2.1 Multi-Tenancy

**REQ-MT-001:** The system SHALL support multiple independent tenants (organizations) within a single deployment  
**Priority:** CRITICAL  
**Rationale:** Core business model requirement

**REQ-MT-002:** Each tenant SHALL have isolated data with no cross-tenant data access  
**Priority:** CRITICAL  
**Rationale:** Security and compliance requirement

**REQ-MT-003:** The system SHALL support tenant-specific branding and configuration  
**Priority:** MEDIUM  
**Rationale:** Professional white-label capability

**REQ-MT-004:** Tenants SHALL be able to manage multiple locations independently  
**Priority:** HIGH  
**Rationale:** Multi-site organizations requirement

### 2.2 User Management and RBAC

**REQ-USER-001:** The system SHALL support the following roles:
- System Administrator (platform management)
- Tenant Administrator (organization management)
- Location Manager (site management)
- Inspector (perform inspections)
- Viewer (read-only access)  
**Priority:** CRITICAL  
**Rationale:** Hierarchical access control

**REQ-USER-002:** Users SHALL authenticate using Azure AD B2C with MFA support  
**Priority:** HIGH  
**Rationale:** Enterprise security requirement

**REQ-USER-003:** Users SHALL be able to belong to multiple tenants with different roles  
**Priority:** MEDIUM  
**Rationale:** Contractor and consultant scenarios

**REQ-USER-004:** The system SHALL log all user actions for audit purposes  
**Priority:** HIGH  
**Rationale:** Compliance and security requirement

### 2.3 Location Management

**REQ-LOC-001:** Tenant Administrators SHALL be able to create, update, and delete locations  
**Priority:** HIGH  
**Rationale:** Core asset management

**REQ-LOC-002:** Each location SHALL have the following attributes:
- Location code (unique within tenant)
- Name
- Full address
- GPS coordinates
- Contact information
- Barcode/QR code for identification  
**Priority:** HIGH  
**Rationale:** Complete location identification

**REQ-LOC-003:** The system SHALL generate unique QR codes for each location  
**Priority:** MEDIUM  
**Rationale:** Mobile scanning workflow

**REQ-LOC-004:** Locations SHALL be displayable on an interactive map  
**Priority:** LOW  
**Rationale:** Visual management enhancement

### 2.4 Extinguisher Asset Management

**REQ-EXT-001:** The system SHALL track the following extinguisher attributes:
- Asset tag (unique identifier)
- Barcode/QR code
- Type (ABC, BC, K, CO2, etc.)
- Manufacturer and model
- Serial number
- Capacity
- Manufacture date
- Installation date
- Last hydrostatic test date
- Location assignment
- Physical location description  
**Priority:** CRITICAL  
**Rationale:** Complete asset tracking

**REQ-EXT-002:** The system SHALL generate unique QR codes/barcodes for each extinguisher  
**Priority:** HIGH  
**Rationale:** Mobile scanning workflow

**REQ-EXT-003:** The system SHALL support printing barcode labels for asset tagging  
**Priority:** HIGH  
**Rationale:** Physical asset identification

**REQ-EXT-004:** Extinguishers SHALL be transferable between locations  
**Priority:** MEDIUM  
**Rationale:** Asset mobility

**REQ-EXT-005:** The system SHALL track extinguisher lifecycle status:
- Active
- Out of service
- Retired
- Disposed  
**Priority:** MEDIUM  
**Rationale:** Complete lifecycle management

### 2.5 Inspection Management

**REQ-INSP-001:** The system SHALL support the following inspection types:
- Monthly visual inspection
- Annual maintenance inspection
- Hydrostatic testing
- Custom inspection types  
**Priority:** CRITICAL  
**Rationale:** Regulatory compliance

**REQ-INSP-002:** Each inspection type SHALL have a configurable checklist template  
**Priority:** HIGH  
**Rationale:** Flexible inspection workflows

**REQ-INSP-003:** Checklist items SHALL support the following response types:
- Pass/Fail
- Yes/No/N/A
- Numeric values
- Free text notes
- Photo capture  
**Priority:** HIGH  
**Rationale:** Comprehensive inspection data

**REQ-INSP-004:** The system SHALL capture the following inspection metadata:
- Inspector user
- Start and end timestamps
- GPS coordinates
- Device fingerprint
- Overall result (Pass/Fail/Needs Service)
- Inspector notes  
**Priority:** CRITICAL  
**Rationale:** Complete inspection record

**REQ-INSP-005:** Inspections SHALL support photo capture with EXIF metadata  
**Priority:** HIGH  
**Rationale:** Visual evidence requirement

**REQ-INSP-006:** The system SHALL allow inspections to be performed offline  
**Priority:** CRITICAL  
**Rationale:** Mobile inspection requirement

**REQ-INSP-007:** Offline inspections SHALL synchronize automatically when connectivity is restored  
**Priority:** HIGH  
**Rationale:** Seamless offline workflow

**REQ-INSP-008:** The system SHALL scan extinguisher barcodes to initiate inspections  
**Priority:** HIGH  
**Ratability:** Mobile workflow efficiency

### 2.6 Tamper-Proofing and Security

**REQ-TAMP-001:** Each inspection record SHALL be signed with HMAC-SHA256  
**Priority:** CRITICAL  
**Rationale:** Data integrity verification

**REQ-TAMP-002:** Inspection records SHALL form a hash chain (blockchain-style)  
**Priority:** HIGH  
**Rationale:** Tamper detection

**REQ-TAMP-003:** GPS coordinates SHALL be validated against expected location  
**Priority:** MEDIUM  
**Rationale:** Location verification

**REQ-TAMP-004:** Photo EXIF data SHALL be validated for authenticity  
**Priority:** MEDIUM  
**Rationale:** Image verification

**REQ-TAMP-005:** The system SHALL maintain immutable audit logs  
**Priority:** HIGH  
**Rationale:** Compliance requirement

**REQ-TAMP-006:** Offline inspections SHALL be cryptographically sealed before synchronization  
**Priority:** HIGH  
**Rationale:** Offline tamper prevention

### 2.7 Reporting and Analytics

**REQ-RPT-001:** The system SHALL generate monthly inspection reports showing:
- Inspection completion rate
- Failed inspections
- Overdue inspections
- Extinguishers by status  
**Priority:** HIGH  
**Rationale:** Compliance reporting

**REQ-RPT-002:** The system SHALL generate annual compliance reports showing:
- Annual maintenance completion
- Hydrostatic testing due/overdue
- Service history
- Compliance status by location  
**Priority:** HIGH  
**Rationale:** Regulatory reporting

**REQ-RPT-003:** Reports SHALL be exportable in the following formats:
- PDF
- Excel (XLSX)
- CSV  
**Priority:** MEDIUM  
**Rationale:** External system integration

**REQ-RPT-004:** The system SHALL provide a compliance dashboard showing:
- Overall compliance percentage
- Overdue inspections count
- Recent inspection activity
- Alerts and warnings  
**Priority:** MEDIUM  
**Rationale:** Management visibility

**REQ-RPT-005:** The system SHALL send automated email reminders for:
- Upcoming monthly inspections
- Overdue inspections
- Annual maintenance due
- Hydrostatic testing due  
**Priority:** MEDIUM  
**Rationale:** Proactive compliance management

### 2.8 Maintenance Tracking

**REQ-MAINT-001:** The system SHALL track maintenance records including:
- Maintenance type (recharge, repair, replace, hydrostatic test)
- Date performed
- Technician name
- Service company
- Cost
- Notes
- Receipt/invoice documents  
**Priority:** MEDIUM  
**Rationale:** Complete service history

**REQ-MAINT-002:** The system SHALL calculate next service due dates based on regulations  
**Priority:** MEDIUM  
**Rationale:** Proactive maintenance scheduling

---

## 3. Non-Functional Requirements

### 3.1 Performance

**REQ-PERF-001:** Web pages SHALL load within 2 seconds on standard broadband  
**Priority:** HIGH  
**Rationale:** User experience

**REQ-PERF-002:** API endpoints SHALL respond within 500ms for 95th percentile  
**Priority:** MEDIUM  
**Rationale:** Acceptable API performance

**REQ-PERF-003:** The system SHALL support 1000 concurrent users  
**Priority:** MEDIUM  
**Rationale:** Growth capacity

**REQ-PERF-004:** Database queries SHALL execute within 1 second for 95th percentile  
**Priority:** MEDIUM  
**Rationale:** Acceptable database performance

**REQ-PERF-005:** Mobile apps SHALL function smoothly on devices from 2020 or newer  
**Priority:** HIGH  
**Ratability:** Device compatibility

### 3.2 Scalability

**REQ-SCALE-001:** The system SHALL support up to 10,000 tenants  
**Priority:** LOW  
**Rationale:** Long-term growth

**REQ-SCALE-002:** Each tenant SHALL support up to 10,000 extinguishers  
**Priority:** MEDIUM  
**Rationale:** Enterprise tenant size

**REQ-SCALE-003:** The system SHALL support horizontal scaling of application servers  
**Priority:** MEDIUM  
**Rationale:** Performance scaling

**REQ-SCALE-004:** The database SHALL support read replicas for reporting queries  
**Priority:** LOW  
**Rationale:** Performance optimization

### 3.3 Availability

**REQ-AVAIL-001:** The system SHALL maintain 99.5% uptime (excluding planned maintenance)  
**Priority:** MEDIUM  
**Rationale:** Business continuity

**REQ-AVAIL-002:** Planned maintenance windows SHALL be scheduled during off-peak hours  
**Priority:** LOW  
**Rationale:** Minimize disruption

**REQ-AVAIL-003:** The system SHALL have automated backup and restore capabilities  
**Priority:** HIGH  
**Rationale:** Data protection

**REQ-AVAIL-004:** Critical failures SHALL trigger automatic alerts to operations team  
**Priority:** HIGH  
**Rationale:** Rapid incident response

### 3.4 Security

**REQ-SEC-001:** All data in transit SHALL be encrypted using TLS 1.2 or higher  
**Priority:** CRITICAL  
**Rationale:** Data protection

**REQ-SEC-002:** All data at rest SHALL be encrypted using AES-256  
**Priority:** CRITICAL  
**Rationale:** Data protection

**REQ-SEC-003:** Passwords SHALL be hashed using bcrypt or stronger  
**Priority:** CRITICAL  
**Rationale:** Credential protection

**REQ-SEC-004:** The system SHALL implement rate limiting to prevent abuse  
**Priority:** HIGH  
**Rationale:** DDoS protection

**REQ-SEC-005:** API keys and secrets SHALL be stored in Azure Key Vault  
**Priority:** HIGH  
**Rationale:** Secret management

**REQ-SEC-006:** The system SHALL pass OWASP Top 10 security assessment  
**Priority:** HIGH  
**Rationale:** Industry security standards

**REQ-SEC-007:** User sessions SHALL expire after 15 minutes of inactivity  
**Priority:** MEDIUM  
**Rationale:** Security best practice

### 3.5 Compliance

**REQ-COMP-001:** The system SHALL comply with NFPA 10 standards for fire extinguisher inspections  
**Priority:** CRITICAL  
**Rationale:** Regulatory compliance

**REQ-COMP-002:** The system SHALL support GDPR requirements (data export, deletion)  
**Priority:** HIGH  
**Rationale:** Privacy regulation

**REQ-COMP-003:** The system SHALL support data residency requirements  
**Priority:** LOW  
**Rationale:** Regional compliance

**REQ-COMP-004:** The system SHALL maintain audit logs for minimum 7 years  
**Priority:** MEDIUM  
**Rationale:** Regulatory retention

### 3.6 Usability

**REQ-USE-001:** The web interface SHALL be responsive and mobile-friendly  
**Priority:** HIGH  
**Rationale:** Multi-device access

**REQ-USE-002:** The system SHALL provide contextual help and tooltips  
**Priority:** LOW  
**Rationale:** User guidance

**REQ-USE-003:** Error messages SHALL be clear and actionable  
**Priority:** MEDIUM  
**Rationale:** User experience

**REQ-USE-004:** The mobile app SHALL support one-handed operation  
**Priority:** MEDIUM  
**Rationale:** Field use ergonomics

### 3.7 Compatibility

**REQ-COMPAT-001:** The web application SHALL support the following browsers:
- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+  
**Priority:** HIGH  
**Rationale:** Browser compatibility

**REQ-COMPAT-002:** The iOS app SHALL support iOS 15.0 and higher  
**Priority:** HIGH  
**Rationale:** Device compatibility

**REQ-COMPAT-003:** The Android app SHALL support Android 10 (API 29) and higher  
**Priority:** HIGH  
**Rationale:** Device compatibility

---

## 4. Technical Requirements

### 4.1 Backend Technology Stack

**REQ-TECH-001:** Backend SHALL be built with .NET 8.0 on Linux  
**Priority:** CRITICAL  
**Rationale:** Platform selection

**REQ-TECH-002:** Database SHALL be Azure SQL Database using T-SQL  
**Priority:** CRITICAL  
**Rationale:** Platform selection

**REQ-TECH-003:** Entity Framework Core SHALL only be used for stored procedure execution  
**Priority:** HIGH  
**Rationale:** Architecture decision

**REQ-TECH-004:** All database operations SHALL use parameterized stored procedures  
**Priority:** CRITICAL  
**Rationale:** Security and performance

**REQ-TECH-005:** Serilog SHALL be used for structured logging  
**Priority:** HIGH  
**Rationale:** Logging standard

**REQ-TECH-006:** Polly SHALL be used for resilience patterns  
**Priority:** MEDIUM  
**Rationale:** Fault tolerance

**REQ-TECH-007:** Hangfire SHALL be used for background job scheduling  
**Priority:** MEDIUM  
**Rationale:** Job scheduling

### 4.2 Frontend Technology Stack

**REQ-FRONT-001:** Web frontend SHALL be built with Vue.js 3  
**Priority:** CRITICAL  
**Rationale:** Platform selection

**REQ-FRONT-002:** Tailwind CSS SHALL be used for styling  
**Priority:** HIGH  
**Rationale:** CSS framework

**REQ-FRONT-003:** The web app SHALL be a Progressive Web App (PWA)  
**Priority:** HIGH  
**Rationale:** Offline capability

**REQ-FRONT-004:** Pinia SHALL be used for state management  
**Priority:** MEDIUM  
**Rationale:** State management

### 4.3 Mobile Technology Stack

**REQ-MOBILE-001:** iOS app SHALL be built with Swift and SwiftUI  
**Priority:** HIGH  
**Rationale:** Native platform

**REQ-MOBILE-002:** Android app SHALL be built with Kotlin and Jetpack Compose  
**Priority:** HIGH  
**Rationale:** Native platform

**REQ-MOBILE-003:** Mobile apps SHALL use native camera APIs for barcode scanning  
**Priority:** HIGH  
**Rationale:** Performance and reliability

### 4.4 Infrastructure

**REQ-INFRA-001:** The system SHALL be deployed on Azure  
**Priority:** CRITICAL  
**Rationale:** Cloud platform selection

**REQ-INFRA-002:** Application Insights SHALL be used for monitoring  
**Priority:** HIGH  
**Rationale:** Observability

**REQ-INFRA-003:** Azure Blob Storage SHALL be used for file storage  
**Priority:** HIGH  
**Rationale:** Scalable storage

**REQ-INFRA-004:** Azure Key Vault SHALL be used for secret management  
**Priority:** CRITICAL  
**Rationale:** Security requirement

---

## 5. Data Requirements

### 5.1 Data Retention

**REQ-DATA-001:** Inspection records SHALL be retained for 10 years  
**Priority:** HIGH  
**Rationale:** Regulatory requirement

**REQ-DATA-002:** Audit logs SHALL be retained for 7 years  
**Priority:** MEDIUM  
**Rationale:** Compliance requirement

**REQ-DATA-003:** Photos SHALL be retained for 3 years with archival option  
**Priority:** MEDIUM  
**Rationale:** Storage optimization

### 5.2 Data Backup

**REQ-BACKUP-001:** Database backups SHALL be performed daily  
**Priority:** CRITICAL  
**Rationale:** Data protection

**REQ-BACKUP-002:** Backup retention SHALL be 30 days  
**Priority:** MEDIUM  
**Rationale:** Recovery window

**REQ-BACKUP-003:** Point-in-time restore SHALL be supported  
**Priority:** MEDIUM  
**Rationale:** Granular recovery

### 5.3 Data Export

**REQ-EXPORT-001:** Users SHALL be able to export their complete data  
**Priority:** HIGH  
**Rationale:** GDPR compliance

**REQ-EXPORT-002:** Exports SHALL be available in JSON format  
**Priority:** MEDIUM  
**Rationale:** Machine-readable format

---

## 6. Integration Requirements

**REQ-INT-001:** The system SHALL provide RESTful API endpoints  
**Priority:** HIGH  
**Rationale:** External integration

**REQ-INT-002:** The system SHALL provide OpenAPI (Swagger) documentation  
**Priority:** MEDIUM  
**Rationale:** API documentation

**REQ-INT-003:** The system SHALL support webhook notifications for events  
**Priority:** LOW  
**Rationale:** Event-driven integration

---

## 7. Testing Requirements

**REQ-TEST-001:** Unit test coverage SHALL be minimum 70%  
**Priority:** MEDIUM  
**Rationale:** Code quality

**REQ-TEST-002:** Integration tests SHALL cover all API endpoints  
**Priority:** MEDIUM  
**Rationale:** API reliability

**REQ-TEST-003:** End-to-end tests SHALL cover critical user workflows  
**Priority:** MEDIUM  
**Rationale:** User experience verification

**REQ-TEST-004:** Load testing SHALL validate performance under expected load  
**Priority:** LOW  
**Rationale:** Performance validation

---

## 8. Documentation Requirements

**REQ-DOC-001:** User documentation SHALL be provided for all user roles  
**Priority:** MEDIUM  
**Rationale:** User enablement

**REQ-DOC-002:** API documentation SHALL be auto-generated from code  
**Priority:** MEDIUM  
**Rationale:** Documentation accuracy

**REQ-DOC-003:** Deployment documentation SHALL be maintained  
**Priority:** HIGH  
**Rationale:** Operational requirement

---

## 9. Licensing and Open Source

**REQ-LIC-001:** All third-party components SHALL use permissive licenses (MIT, Apache 2.0, BSD)  
**Priority:** HIGH  
**Rationale:** Commercial viability

**REQ-LIC-002:** No per-user or per-device licensing fees SHALL be incurred  
**Priority:** CRITICAL  
**Rationale:** Cost control

**REQ-LIC-003:** Open source alternatives SHALL be preferred when suitable  
**Priority:** MEDIUM  
**Rationale:** Cost and flexibility

---

## 10. Acceptance Criteria

### 10.1 Phase 1.0 (Web Application)

- [ ] User can register a new tenant organization
- [ ] User can create locations with GPS coordinates
- [ ] User can add extinguishers with barcodes
- [ ] User can scan barcode and perform inspection on web
- [ ] User can capture photos during inspection
- [ ] System generates monthly compliance report
- [ ] System sends email reminders for due inspections
- [ ] All inspection data is tamper-proof (hash verified)
- [ ] Web app works offline and syncs when online
- [ ] RBAC enforces role-based permissions

### 10.2 Phase 2.0 (Native Mobile Apps)

- [ ] iOS app can scan barcodes natively
- [ ] Android app can scan barcodes natively
- [ ] Mobile apps work fully offline
- [ ] Mobile apps capture GPS coordinates automatically
- [ ] Mobile apps sync inspections in background
- [ ] Mobile apps receive push notifications
- [ ] Mobile apps have equivalent functionality to web

---

## 11. Constraints and Assumptions

### 11.1 Constraints

- Budget: Target $250/month Azure costs for production
- Timeline: Phase 1.0 in 10 weeks, Phase 2.0 in additional 12 weeks
- Team: Small development team (1-3 developers)
- No on-premise deployment required

### 11.2 Assumptions

- Users have modern smartphones (iOS 15+ or Android 10+)
- Users have internet connectivity for synchronization
- Barcode labels will be printed externally (standard label printers)
- GPS accuracy of 10-50 meters is acceptable
- NFPA 10 standards will not change significantly during development

---

## 12. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-10-08 | Development Team | Initial requirements document |

---

## 13. Approval

This requirements document requires approval from the following stakeholders:

- [ ] Product Owner
- [ ] Technical Lead
- [ ] Security Officer
- [ ] Compliance Officer

**Document Status:** Draft - Pending Approval
