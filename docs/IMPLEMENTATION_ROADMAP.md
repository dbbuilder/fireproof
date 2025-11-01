# FireProof Implementation Roadmap
**Created:** October 31, 2025
**Updated:** October 31, 2025
**Status:** Active Development
**Current Phase:** Phase 2.2 - Scheduling & Reminders

---

## Overview

This document outlines the comprehensive implementation plan for FireProof's next 5 phases, building on the completed Phase 1 (Core MVP) and Phase 2.1 (Data Import/Export).

**Timeline:** 10-15 weeks
**Goal:** Production-ready system with competitive feature parity + AI differentiation

---

## Phase 1.3: Tenant Selector & Multi-Org Support ✅ COMPLETE

**Timeline:** 1 day (planned: 1-2 weeks) - Ahead of schedule ⚡
**Priority:** 🔴 CRITICAL
**Status:** Implementation complete - Ready for testing
**Completed:** October 31, 2025

### Why This Phase

- **Unblocks production use**: SystemAdmins need to switch between organizations
- **Fixes E2E tests**: 10 of 57 failing tests depend on this feature
- **Enables demos**: Single admin account can manage multiple organizations
- **Quick win**: High impact, relatively simple implementation

### Requirements

1. **Tenant Selector UI** (SystemAdmin only)
   - Modal or dropdown showing all accessible tenants
   - Display: Organization name, role, last accessed
   - Quick-switch capability without re-login
   - Accessible from header (all pages)

2. **Current Tenant Display**
   - Show active organization in header
   - Visual indicator (badge/pill)
   - Tenant logo support (future enhancement)

3. **Backend Changes**
   - API endpoint: `GET /api/users/me/tenants` - List accessible tenants
   - API endpoint: `POST /api/users/me/switch-tenant` - Switch active tenant
   - Update JWT claims with selected TenantId
   - Store last accessed tenant in database

4. **Frontend Changes**
   - TenantSelector component in AppHeader
   - Update auth store with tenant switching logic
   - Persist selected tenant to localStorage
   - Auto-redirect to tenant selector if no tenant selected
   - Reload all data after tenant switch

### Implementation Summary

#### Backend ✅ COMPLETE (1 day)

- [x] Created `SwitchTenantRequest`, `SwitchTenantResponse`, and `TenantSummaryDto` DTOs
- [x] Added `usp_User_GetAccessibleTenants` stored procedure
- [x] Added `usp_User_UpdateLastAccessedTenant` stored procedure
- [x] Added methods to `IUserService` and `UserService`:
  - [x] `GetAccessibleTenantsAsync(userId)`
  - [x] `SwitchTenantAsync(userId, tenantId)`
- [x] Added endpoints to `UsersController`:
  - [x] `GET /api/users/me/tenants`
  - [x] `POST /api/users/me/switch-tenant`
- [x] JWT token generation includes TenantId claim (updated on switch)
- [x] Added `LastAccessedTenantId` and `LastAccessedDate` columns to Users table

#### Frontend ✅ COMPLETE (1 day)

- [x] Updated `TenantSelector.vue` component:
  - [x] Fetches accessible tenants from API
  - [x] Calls auth store switchTenant() action
  - [x] Shows loading/error states
- [x] `AppHeader.vue` already has:
  - [x] Tenant selector trigger button (SystemAdmin + multi-tenant)
  - [x] Current tenant display
  - [x] Tenant badge indicator
- [x] Updated `auth.ts` store:
  - [x] Added `switchTenant(tenantId)` action
  - [x] Calls userService.switchTenant() for new JWT
  - [x] Persists selected tenant to localStorage
  - [x] Updates axios headers with new token
  - [x] Refreshes user and roles after switch
- [x] Router guard already implemented:
  - [x] Redirects to `/select-tenant` if no tenant selected
  - [x] Works for SystemAdmin and multi-tenant users
- [x] Updated `TenantSelectorView.vue`:
  - [x] Full-page tenant selection
  - [x] Card/grid layout with tenant details
  - [x] Shows last accessed date (relative formatting)
  - [x] Shows location and extinguisher counts

#### Testing 📋 PENDING

- [ ] Manual testing:
  - [ ] Login as SystemAdmin with multiple tenants
  - [ ] Switch between tenants
  - [ ] Verify data isolation (each tenant sees only their data)
  - [ ] Test localStorage persistence
  - [ ] Test JWT token refresh after switch
- [ ] Update E2E tests:
  - [ ] Fix 10 failing tenant-selector tests
  - [ ] Add tests for tenant switching workflow
  - [ ] Verify data isolation in tests

### Success Criteria

- ✅ SystemAdmin can see all accessible tenants
- ✅ SystemAdmin can switch between tenants without logout
- ✅ Current tenant is clearly displayed in header
- ✅ Data is properly isolated per tenant after switch
- ✅ Selected tenant persists across page refreshes
- ✅ E2E tenant selector tests pass (10 tests)

---

## Phase 2.2: Scheduling & Reminders

**Timeline:** 2-3 weeks
**Priority:** 🟡 HIGH
**Status:** Pending Phase 1.3 completion

### Why This Phase

- **Proactive compliance**: Auto-generate inspection schedules
- **Reduce manual work**: No more spreadsheet tracking
- **Prevent missed inspections**: Email reminders
- **Competitive feature**: Essential for market competitiveness

### Requirements

1. **Inspection Scheduling**
   - Auto-generate monthly/annual/hydrostatic schedules
   - Based on extinguisher type and last inspection date
   - Configurable inspection frequencies per tenant
   - Bulk schedule generation for all extinguishers

2. **Calendar View**
   - Month/week/day views
   - Color-coded by inspection type
   - Drag-and-drop reschedule
   - Filter by location/inspector/type

3. **Reminder System**
   - Email reminders (7 days, 3 days, 1 day before due)
   - Overdue inspection alerts
   - Daily digest for inspectors
   - Weekly summary for managers

4. **Inspector Assignment**
   - Assign inspections to specific inspectors
   - Load balancing (distribute workload)
   - Inspector availability calendar
   - Mobile notification of assignments

### Implementation Tasks

#### Backend (5-7 days)

**Database Schema:**
- [ ] Create `InspectionSchedules` table:
  ```sql
  ScheduleId UNIQUEIDENTIFIER PK
  TenantId UNIQUEIDENTIFIER FK
  ExtinguisherId UNIQUEIDENTIFIER FK
  InspectionType (Monthly, Annual, SixYear, TwelveYear, Hydrostatic)
  ScheduledDate DATE
  AssignedInspectorId UNIQUEIDENTIFIER FK (nullable)
  Status (Scheduled, InProgress, Completed, Cancelled, Overdue)
  Priority (Low, Normal, High, Critical)
  RecurrenceRule NVARCHAR(200) -- RRULE format for recurring schedules
  Notes NVARCHAR(500)
  CreatedDate DATETIME2
  ModifiedDate DATETIME2
  ```

- [ ] Create `InspectionReminders` table:
  ```sql
  ReminderId UNIQUEIDENTIFIER PK
  ScheduleId UNIQUEIDENTIFIER FK
  ReminderType (Email, SMS, Push)
  DaysBeforeDue INT
  SentDate DATETIME2
  Status (Pending, Sent, Failed)
  RecipientUserId UNIQUEIDENTIFIER FK
  ```

**Stored Procedures:**
- [ ] `usp_Schedule_Create` - Create schedule entry
- [ ] `usp_Schedule_CreateBatch` - Bulk schedule creation
- [ ] `usp_Schedule_Update` - Update schedule (reschedule, assign)
- [ ] `usp_Schedule_GetAll` - List schedules with filters
- [ ] `usp_Schedule_GetByDate` - Schedules for date range
- [ ] `usp_Schedule_GetOverdue` - Overdue inspections
- [ ] `usp_Schedule_GetByInspector` - Inspector's assigned schedules
- [ ] `usp_Schedule_AutoGenerate` - Auto-create schedules based on rules
- [ ] `usp_Reminder_GetPending` - Reminders to send
- [ ] `usp_Reminder_MarkSent` - Update reminder status

**Services:**
- [ ] Create `IScheduleService` and `ScheduleService`
- [ ] Create `IReminderService` and `ReminderService`
- [ ] Create `IEmailService` and `EmailService` (using SendGrid/Azure Communication Services)
- [ ] Implement schedule auto-generation logic
- [ ] Implement reminder scheduling logic

**Controllers:**
- [ ] `SchedulesController` with endpoints:
  - `GET /api/schedules` - List schedules
  - `GET /api/schedules/{id}` - Get schedule details
  - `POST /api/schedules` - Create schedule
  - `POST /api/schedules/batch` - Bulk create
  - `PUT /api/schedules/{id}` - Update schedule
  - `POST /api/schedules/auto-generate` - Auto-generate schedules
  - `GET /api/schedules/overdue` - Overdue inspections
  - `GET /api/schedules/calendar` - Calendar view data

**Background Jobs (Hangfire):**
- [ ] Daily job: Auto-generate upcoming schedules (30 days ahead)
- [ ] Hourly job: Send pending reminders
- [ ] Daily job: Mark overdue inspections
- [ ] Weekly job: Send manager summary emails

#### Frontend (5-7 days)

**New Views:**
- [ ] `ScheduleView.vue` - Main scheduling interface
  - Calendar view (month/week/day)
  - List view with filters
  - Bulk actions (assign, reschedule, delete)
- [ ] `ScheduleCreateView.vue` - Create schedule modal/page
  - Single or batch schedule creation
  - Auto-generate option with date range
- [ ] `CalendarView.vue` - Full calendar component
  - Integration with FullCalendar.js or custom
  - Drag-and-drop reschedule
  - Click to view/edit schedule
  - Color coding by status/type

**Components:**
- [ ] `ScheduleCard.vue` - Schedule item display
- [ ] `AssignInspectorModal.vue` - Assign inspector dialog
- [ ] `RescheduleModal.vue` - Quick reschedule dialog
- [ ] `ScheduleFilters.vue` - Filter panel

**Services:**
- [ ] `scheduleService.js` - API client for schedules
- [ ] `reminderService.js` - API client for reminders

**Stores:**
- [ ] `schedules.js` Pinia store:
  - State: schedules, selectedDate, filters
  - Actions: fetchSchedules, createSchedule, updateSchedule, autoGenerate
  - Getters: overdueSchedules, upcomingSchedules, scheduledByDate

**Router:**
- [ ] Add `/schedules` route
- [ ] Add `/schedules/calendar` route
- [ ] Add `/schedules/create` route

#### Testing (2-3 days)

- [ ] Unit tests for schedule generation logic
- [ ] Integration tests for reminder sending
- [ ] E2E tests for:
  - Creating schedules manually
  - Auto-generating schedules
  - Assigning inspectors
  - Viewing calendar
  - Receiving reminders (mock email)

### Success Criteria

- ✅ Auto-generate inspection schedules for all extinguishers
- ✅ Calendar view displays all scheduled inspections
- ✅ Email reminders sent 7/3/1 days before due date
- ✅ Overdue inspections clearly marked
- ✅ Inspectors can view their assigned inspections
- ✅ Managers can reassign inspections via drag-and-drop

---

## Phase 2.3: Advanced Reporting

**Timeline:** 2-3 weeks
**Priority:** 🟢 MEDIUM
**Status:** Pending Phase 2.2 completion

### Why This Phase

- **Regulatory compliance**: NFPA-compliant reports for audits
- **Management insights**: KPIs, trends, analytics
- **Customer value**: Export capabilities
- **Audit trail**: Comprehensive compliance documentation

### Requirements

1. **Compliance Dashboard**
   - Pass/fail rates (by location, type, inspector)
   - Inspection completion rates
   - Overdue inspection alerts
   - Deficiency counts and resolution status
   - Charts: line graphs, bar charts, pie charts

2. **NFPA Compliance Reports (PDF)**
   - Complete inspection history per extinguisher
   - Location-based compliance reports
   - Certification reports with digital signatures
   - Scheduled reports (auto-generate monthly)

3. **Export Capabilities**
   - Excel export for inspections (filtering, date range)
   - CSV export for all data tables
   - PDF export for individual inspection reports
   - Bulk export for audits

4. **Historical Analysis**
   - Pass/fail trends over time
   - Deficiency type analysis
   - Inspector performance metrics
   - Cost analysis (maintenance, replacements)

### Implementation Tasks

#### Backend (5-7 days)

**Database Schema:**
- [ ] Create `Reports` table (enhance existing):
  ```sql
  ReportId UNIQUEIDENTIFIER PK
  TenantId UNIQUEIDENTIFIER FK
  ReportType (Compliance, Inspection, Deficiency, Performance, Custom)
  ReportName NVARCHAR(200)
  Parameters NVARCHAR(MAX) -- JSON: filters, date range, etc.
  GeneratedDate DATETIME2
  GeneratedByUserId UNIQUEIDENTIFIER FK
  Format (PDF, Excel, CSV)
  BlobUrl NVARCHAR(500) -- Azure Blob Storage URL
  Status (Generating, Ready, Failed)
  ExpirationDate DATE -- Auto-delete after 30 days
  ```

**Stored Procedures:**
- [ ] `usp_Report_GetComplianceStats` - Aggregate compliance data
- [ ] `usp_Report_GetPassFailRates` - Pass/fail by location/type/inspector
- [ ] `usp_Report_GetDeficiencySummary` - Deficiency counts and types
- [ ] `usp_Report_GetInspectionHistory` - Full history for extinguisher/location
- [ ] `usp_Report_GetOverdueInspections` - Overdue report data
- [ ] `usp_Report_GetTrendData` - Historical trend analysis
- [ ] `usp_Report_Create` - Save report metadata
- [ ] `usp_Report_GetAll` - List generated reports

**Services:**
- [ ] Create `IReportingService` and `ReportingService`
- [ ] Create `IPdfGenerationService` and `PdfGenerationService`
  - Use QuestPDF or iTextSharp for PDF generation
  - NFPA-compliant templates
  - Digital signature support
- [ ] Create `IExcelExportService` and `ExcelExportService`
  - Use EPPlus or ClosedXML
  - Multiple sheets per workbook
  - Formatting and charts
- [ ] Implement report generation queue (Hangfire background jobs)

**Controllers:**
- [ ] Enhance `ReportsController` with endpoints:
  - `GET /api/reports/compliance` - Compliance dashboard data
  - `GET /api/reports/pass-fail-rates` - Pass/fail statistics
  - `GET /api/reports/deficiencies` - Deficiency summary
  - `POST /api/reports/generate-pdf` - Generate NFPA compliance PDF
  - `POST /api/reports/export-inspections` - Export inspections to Excel
  - `POST /api/reports/export-csv` - Export data to CSV
  - `GET /api/reports` - List generated reports
  - `GET /api/reports/{id}/download` - Download report file

**Background Jobs:**
- [ ] Report generation queue (async PDF/Excel generation)
- [ ] Scheduled reports (auto-generate monthly compliance reports)
- [ ] Report cleanup (delete expired reports after 30 days)

#### Frontend (5-7 days)

**Enhance Existing:**
- [ ] `ReportsView.vue` - Transform into comprehensive reporting hub:
  - Compliance dashboard at top
  - Quick actions (Generate PDF, Export Excel, etc.)
  - Recent reports list
  - Scheduled reports section

**New Views:**
- [ ] `ComplianceDashboardView.vue` - Visual analytics:
  - KPI cards (total inspections, pass rate, overdue count)
  - Charts (Chart.js or Apache ECharts)
  - Drill-down capabilities
  - Date range selector
- [ ] `ReportGeneratorView.vue` - Report configuration wizard:
  - Select report type
  - Configure parameters (date range, filters, locations)
  - Preview before generate
  - Schedule recurring reports

**Components:**
- [ ] `ComplianceStatsCard.vue` - KPI display cards
- [ ] `PassFailChart.vue` - Pass/fail visualization
- [ ] `DeficiencyChart.vue` - Deficiency breakdown
- [ ] `TrendChart.vue` - Historical trend line chart
- [ ] `ExportOptionsModal.vue` - Export configuration dialog
- [ ] `ReportCard.vue` - Generated report list item

**Services:**
- [ ] Enhance `reportService.js`:
  - Add methods for compliance stats
  - Add export methods (PDF, Excel, CSV)
  - Add report download method

**Stores:**
- [ ] Enhance `reports.js` Pinia store:
  - Add compliance stats state
  - Add chart data state
  - Add actions for fetching analytics
  - Add export actions

**Libraries:**
- [ ] Install Chart.js or Apache ECharts for charts
- [ ] Install date range picker component

#### Testing (2-3 days)

- [ ] Unit tests for report generation logic
- [ ] Integration tests for PDF generation
- [ ] E2E tests for:
  - Viewing compliance dashboard
  - Generating PDF report
  - Exporting to Excel
  - Downloading reports

### Success Criteria

- ✅ Compliance dashboard shows real-time KPIs
- ✅ Generate NFPA-compliant PDF reports
- ✅ Export inspection data to Excel with filtering
- ✅ Charts display pass/fail trends over time
- ✅ Deficiency summary shows breakdown by type
- ✅ Reports auto-generate on schedule (monthly)

---

## Phase 3: AI Features (Computer Vision & ML)

**Timeline:** 3-4 weeks
**Priority:** 🟣 INNOVATION
**Status:** Pending Phase 2.3 completion

### Why This Phase

- **Competitive differentiation**: No competitors have comprehensive AI
- **Reduce training time**: AI guides inspectors through process
- **Improve accuracy**: AI detects deficiencies humans might miss
- **Predictive maintenance**: ML predicts failures before they occur

### Requirements

1. **Photo-Based Deficiency Detection**
   - Azure Computer Vision API integration
   - Detect common deficiencies from photos:
     - Pressure gauge in red zone
     - Missing/broken seals
     - Corrosion/rust
     - Physical damage
     - Obstructed access
   - Confidence scores (Low/Medium/High)
   - Auto-flag failed items based on photo analysis

2. **Predictive Maintenance**
   - ML model to predict failure likelihood
   - Train on historical inspection data
   - Input features:
     - Extinguisher age
     - Last inspection results
     - Deficiency history
     - Environmental factors (location type)
   - Output: Probability of failure in next 30/60/90 days
   - Recommend proactive replacement/maintenance

3. **Smart Inspection Assistant**
   - Natural language processing for inspection notes
   - Auto-categorize deficiencies from free-text notes
   - Suggest checklist items based on photo context
   - Voice-to-text for inspector notes

4. **AI-Powered Recommendations**
   - Recommend inspection frequency adjustments
   - Suggest optimal inspection routes (traveling salesman)
   - Identify high-risk extinguishers (priority inspection)
   - Cost optimization recommendations

### Implementation Tasks

#### Backend (7-10 days)

**Azure Services Setup:**
- [ ] Provision Azure Computer Vision resource
- [ ] Provision Azure Cognitive Services (Text Analytics)
- [ ] Optional: Azure Machine Learning workspace for custom models
- [ ] Configure Azure Key Vault for AI service keys

**Database Schema:**
- [ ] Create `AIAnalysis` table:
  ```sql
  AnalysisId UNIQUEIDENTIFIER PK
  TenantId UNIQUEIDENTIFIER FK
  InspectionId UNIQUEIDENTIFIER FK (nullable)
  PhotoId UNIQUEIDENTIFIER FK (nullable)
  AnalysisType (DeficiencyDetection, PredictiveMaintenance, TextAnalysis)
  InputData NVARCHAR(MAX) -- JSON
  OutputData NVARCHAR(MAX) -- JSON: detected issues, confidence scores
  ConfidenceScore DECIMAL(5,2)
  Status (Processing, Completed, Failed)
  ProcessedDate DATETIME2
  ModelVersion NVARCHAR(50)
  ```

- [ ] Create `PredictiveMaintenanceScores` table:
  ```sql
  ScoreId UNIQUEIDENTIFIER PK
  TenantId UNIQUEIDENTIFIER FK
  ExtinguisherId UNIQUEIDENTIFIER FK
  CalculatedDate DATE
  FailureProbability30Days DECIMAL(5,2)
  FailureProbability60Days DECIMAL(5,2)
  FailureProbability90Days DECIMAL(5,2)
  RiskLevel (Low, Medium, High, Critical)
  RecommendedAction NVARCHAR(500)
  FactorsConsidered NVARCHAR(MAX) -- JSON
  ```

**Services:**
- [ ] Create `IAIService` and `AIService`:
  - `AnalyzePhotoForDeficienciesAsync(photoUrl)` - Computer Vision
  - `ExtractTextFromImageAsync(photoUrl)` - OCR for labels/tags
  - `AnalyzeInspectionNotesAsync(notes)` - NLP categorization
  - `TranscribeSpeechToTextAsync(audioBlob)` - Speech-to-text
- [ ] Create `IPredictiveMaintenanceService` and `PredictiveMaintenanceService`:
  - `CalculateFailureProbabilityAsync(extinguisherId)` - ML scoring
  - `GetHighRiskExtinguishersAsync(tenantId)` - Risk ranking
  - `GenerateMaintenanceRecommendationsAsync(tenantId)` - Recommendations
- [ ] Implement caching for AI analysis results (Redis or in-memory)

**ML Model Development (if custom models needed):**
- [ ] Data collection: Export historical inspection data
- [ ] Feature engineering: Create input features from data
- [ ] Model training: Logistic regression or random forest for failure prediction
- [ ] Model evaluation: Accuracy, precision, recall metrics
- [ ] Model deployment: Azure ML endpoint or containerized API
- [ ] A/B testing: Compare AI recommendations vs. baseline

**Controllers:**
- [ ] Create `AIController` with endpoints:
  - `POST /api/ai/analyze-photo` - Analyze photo for deficiencies
  - `POST /api/ai/analyze-notes` - Categorize inspection notes
  - `POST /api/ai/transcribe-audio` - Speech-to-text
  - `GET /api/ai/analysis/{id}` - Get analysis results
- [ ] Create `PredictiveMaintenanceController` with endpoints:
  - `GET /api/predictive-maintenance/extinguisher/{id}` - Failure probability
  - `GET /api/predictive-maintenance/high-risk` - High-risk extinguishers
  - `POST /api/predictive-maintenance/recalculate` - Trigger recalculation

**Background Jobs:**
- [ ] Daily job: Recalculate predictive maintenance scores for all extinguishers
- [ ] On inspection completion: Trigger AI analysis of uploaded photos
- [ ] Weekly job: Generate AI insights report for managers

#### Frontend (7-10 days)

**Photo Analysis Integration:**
- [ ] Update `PhotoCaptureComponent.vue`:
  - Add "Analyze Photo" button
  - Show AI analysis results overlay
  - Display detected deficiencies with confidence
  - Auto-populate checklist items based on AI findings
- [ ] Create `AIAnalysisResultsModal.vue`:
  - Visual display of detected issues
  - Annotate photo with bounding boxes (if available)
  - Accept/reject AI suggestions
  - Confidence score indicators

**Predictive Maintenance Dashboard:**
- [ ] Create `PredictiveMaintenanceView.vue`:
  - High-risk extinguisher list
  - Risk score visualization (heat map)
  - Recommended actions
  - Historical accuracy tracking
- [ ] Create `RiskScoreCard.vue` - Display risk scores with color coding

**Smart Assistant:**
- [ ] Update `InspectionChecklistView.vue`:
  - Add "Suggest Items" button (AI-powered)
  - Voice-to-text button for notes
  - Real-time categorization of notes
- [ ] Create `AIAssistantPanel.vue`:
  - Contextual suggestions
  - Quick actions based on AI recommendations

**Services:**
- [ ] Create `aiService.js`:
  - analyzePhoto(photoId)
  - analyzeNotes(notes)
  - transcribeAudio(audioBlob)
- [ ] Create `predictiveMaintenanceService.js`:
  - getFailureProbability(extinguisherId)
  - getHighRiskExtinguishers()

**Stores:**
- [ ] Create `ai.js` Pinia store:
  - State: aiAnalyses, loading
  - Actions: analyzePhoto, analyzeNotes
- [ ] Create `predictiveMaintenance.js` Pinia store:
  - State: riskScores, highRiskExtinguishers
  - Actions: fetchRiskScores, recalculateScores

**Router:**
- [ ] Add `/predictive-maintenance` route
- [ ] Add `/ai-insights` route

#### Testing (3-5 days)

- [ ] Unit tests for AI service integration
- [ ] Mock AI responses for E2E tests
- [ ] Integration tests:
  - Photo analysis workflow
  - Predictive maintenance calculation
  - Note categorization
- [ ] E2E tests:
  - Upload photo and view AI analysis
  - Accept AI suggestion for deficiency
  - View high-risk extinguishers
  - Generate AI insights report

### Success Criteria

- ✅ AI detects deficiencies from photos with 70%+ accuracy
- ✅ Predictive maintenance identifies high-risk extinguishers
- ✅ Voice-to-text works for inspector notes
- ✅ AI suggestions reduce inspection time by 20%
- ✅ Confidence scores displayed for all AI predictions
- ✅ Users can accept/reject AI suggestions

---

## Phase 4: Polish & Optimization

**Timeline:** 1-2 weeks
**Priority:** 🔵 QUALITY
**Status:** Pending Phase 3 completion

### Goals

1. **Performance Optimization**
   - Frontend bundle size reduction (code splitting, lazy loading)
   - Database query optimization (indexes, query plans)
   - API response time improvements (caching, compression)
   - Image optimization (WebP conversion, lazy loading)

2. **UX Improvements**
   - Responsive design polish (mobile, tablet, desktop)
   - Loading states and skeletons
   - Error handling and user feedback
   - Accessibility (WCAG 2.1 AA compliance)
   - Keyboard navigation
   - Dark mode support (optional)

3. **Documentation**
   - User guides (PDF/online help)
   - Admin documentation
   - API documentation (Swagger enhancements)
   - Video tutorials (Loom/YouTube)
   - Onboarding flow

4. **Testing & QA**
   - Achieve 80%+ E2E test pass rate
   - Load testing (Apache JMeter)
   - Security audit (OWASP Top 10)
   - Cross-browser testing (Chrome, Safari, Firefox, Edge)
   - Mobile device testing (iOS, Android)

5. **Deployment & DevOps**
   - CI/CD pipeline optimization
   - Automated database migrations
   - Blue-green deployment setup
   - Monitoring dashboards (Application Insights)
   - Error tracking (Sentry integration)

### Implementation Tasks

#### Performance (3-4 days)

- [ ] Frontend:
  - Analyze bundle size with Vite Rollup visualizer
  - Implement route-based code splitting
  - Lazy load heavy components (charts, modals)
  - Optimize images (convert to WebP, add srcset)
  - Implement virtual scrolling for large lists
  - Add service worker caching for offline assets
- [ ] Backend:
  - Review slow queries with SQL Server Profiler
  - Add missing indexes based on query plans
  - Implement Redis caching for frequently accessed data
  - Enable gzip compression on API responses
  - Optimize stored procedure execution plans

#### UX Polish (3-4 days)

- [ ] Design system consistency:
  - Audit all components for Tailwind consistency
  - Standardize spacing, colors, typography
  - Create reusable component library
- [ ] Loading states:
  - Add skeleton screens for all data-heavy views
  - Implement progressive loading for images
  - Add loading spinners with meaningful messages
- [ ] Error handling:
  - Consistent error message formatting
  - User-friendly error pages (404, 500)
  - Retry mechanisms for failed requests
- [ ] Accessibility:
  - Add ARIA labels to all interactive elements
  - Ensure keyboard navigation works everywhere
  - Test with screen readers (NVDA, JAWS)
  - Add focus indicators
  - Check color contrast ratios

#### Documentation (2-3 days)

- [ ] User documentation:
  - Getting started guide
  - Feature walkthroughs (inspections, scheduling, reports)
  - FAQ section
  - Troubleshooting guide
- [ ] Admin documentation:
  - Tenant setup guide
  - User management guide
  - Configuration reference
- [ ] Developer documentation:
  - Architecture overview
  - Database schema reference
  - API reference (enhance Swagger)
  - Deployment guide
- [ ] Video tutorials:
  - Record 5-10 minute walkthrough videos
  - Upload to YouTube/Vimeo
  - Embed in help section

#### Testing & QA (3-4 days)

- [ ] E2E test coverage:
  - Fix all failing E2E tests
  - Add missing test scenarios
  - Achieve 80%+ pass rate
- [ ] Load testing:
  - Set up Apache JMeter or k6
  - Test 100+ concurrent users
  - Identify bottlenecks
  - Optimize based on results
- [ ] Security audit:
  - Run OWASP ZAP scan
  - Fix identified vulnerabilities
  - Review authentication/authorization
  - Check for SQL injection, XSS, CSRF
- [ ] Cross-browser testing:
  - Test on Chrome, Safari, Firefox, Edge
  - Fix browser-specific issues
  - Test on iOS Safari and Android Chrome

#### Deployment (1-2 days)

- [ ] CI/CD enhancements:
  - Automated E2E tests in pipeline
  - Automated database migrations
  - Staging environment deployment
  - Production deployment with approval gate
- [ ] Monitoring:
  - Set up Application Insights dashboards
  - Configure alerts for errors and performance
  - Integrate Sentry for error tracking
  - Set up uptime monitoring

### Success Criteria

- ✅ Frontend bundle size < 500KB gzipped
- ✅ API response time < 200ms (p95)
- ✅ Lighthouse score > 90 (Performance, Accessibility)
- ✅ 80%+ E2E test pass rate
- ✅ Zero high/critical security vulnerabilities
- ✅ Works on Chrome, Safari, Firefox, Edge (latest versions)
- ✅ Mobile responsive on iOS and Android
- ✅ User documentation complete
- ✅ CI/CD pipeline automated

---

## Timeline Summary

| Phase | Duration | Start | End |
|-------|----------|-------|-----|
| Phase 1.3: Tenant Selector | 1-2 weeks | Nov 1 | Nov 15 |
| Phase 2.2: Scheduling & Reminders | 2-3 weeks | Nov 15 | Dec 6 |
| Phase 2.3: Advanced Reporting | 2-3 weeks | Dec 6 | Dec 27 |
| Phase 3: AI Features | 3-4 weeks | Dec 27 | Jan 24 |
| Phase 4: Polish & Optimization | 1-2 weeks | Jan 24 | Feb 7 |

**Total Timeline:** 10-15 weeks (2.5-3.5 months)

---

## Success Metrics

### Technical Metrics
- ✅ 80%+ E2E test pass rate
- ✅ < 200ms API response time (p95)
- ✅ 99.9% uptime
- ✅ Zero high/critical security vulnerabilities
- ✅ Lighthouse score > 90

### Product Metrics
- ✅ 100% NFPA 10 compliance features
- ✅ Feature parity with InspectNTrack, IMEC
- ✅ AI differentiation vs. all competitors
- ✅ Complete mobile inspector workflow
- ✅ Multi-tenant support with switching

### Business Metrics
- ✅ Production-ready for customer demos
- ✅ Scalable to 1000+ organizations
- ✅ Documented for customer onboarding
- ✅ Ready for beta customer trials
- ✅ Positioned for market launch

---

## Next Steps

1. ✅ **START Phase 1.3 - Tenant Selector** (THIS IS WHERE WE ARE)
2. Review and approve this roadmap
3. Set up tracking for each phase (GitHub Projects or similar)
4. Schedule weekly check-ins to review progress
5. Adjust timeline based on actual velocity

---

**Document Owner:** Development Team
**Last Updated:** October 31, 2025
**Next Review:** November 15, 2025
