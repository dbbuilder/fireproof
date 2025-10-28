# FireProof - Development Phases Roadmap

**Last Updated:** October 18, 2025
**Current Phase:** ✅ Foundation Complete → Moving to Phase 1A (Inspection Workflow)

---

## Phase Overview

```
Phase 0: Foundation ✅ COMPLETE
  └─> Phase 1A: Inspection Workflow (2 weeks)
      └─> Phase 1B: Reporting & Scheduling (2 weeks)
          └─> Phase 2A: Business Features (3 weeks)
              └─> Phase 2B: Analytics & Integration (2 weeks)
                  └─> Phase 3: AI Features (4 weeks)
                      └─> Phase 4: Native Mobile Apps (6 weeks)
                          └─> Phase 5: Enterprise Features (4 weeks)
```

---

## Phase 0: Foundation ✅ COMPLETE

**Status:** ✅ Completed October 18, 2025
**Duration:** 4 weeks

### What Was Built:
- ✅ Database schema (18 tables, 69 stored procedures)
- ✅ Backend API (.NET 8.0) with authentication
- ✅ Frontend (Vue 3) with basic views
- ✅ Multi-tenant infrastructure with RLS
- ✅ Azure deployment (API + Frontend)
- ✅ 3 super admin users
- ✅ CRUD operations for Locations, Extinguishers, Extinguisher Types

### Key Deliverables:
- ✅ Production API: https://api.fireproofapp.net
- ✅ Production Frontend: https://fireproofapp.net
- ✅ Schema archived and documented
- ✅ Comprehensive documentation (8 documents)

---

## Phase 1A: Inspection Workflow (Weeks 1-2)

**Goal:** Complete the end-to-end inspection workflow for mobile inspectors
**Priority:** 🔴 CRITICAL - Core product functionality
**Duration:** 2 weeks
**Status:** ⏳ Next Up

### Week 1: Mobile Inspection UI

#### Frontend Components (5 days)

**Day 1-2: Barcode Scanner Component**
- [ ] Install `html5-qrcode` library
- [ ] Create `BarcodeScanner.vue` component
  - [ ] Camera preview with targeting box
  - [ ] Scan success feedback (sound + visual)
  - [ ] Manual entry fallback
  - [ ] Permission handling
  - [ ] Error states
- [ ] Test on mobile devices (iOS Safari, Android Chrome)
- [ ] Add to Extinguisher detail view

**Day 2-3: Inspection Wizard Component**
- [ ] Create `InspectionWizard.vue` component
  - [ ] Step 1: Scan/Select Extinguisher
  - [ ] Step 2: Select Inspection Type
  - [ ] Step 3: Capture GPS Location
  - [ ] Step 4: Begin Inspection
- [ ] Create `InspectionProgress.vue` (progress bar)
- [ ] Create `InspectionStepIndicator.vue` (step indicator)
- [ ] Navigation between steps
- [ ] Form validation for each step

**Day 4: GPS Location Capture**
- [ ] Create `GPSCapture.vue` component
  - [ ] Request geolocation permission
  - [ ] Display current coordinates
  - [ ] Show accuracy (meters)
  - [ ] Map view with expected location (Leaflet.js)
  - [ ] Distance calculation from expected location
  - [ ] Warning if location mismatch
  - [ ] Override option with reason
- [ ] Install `leaflet` and `@vue-leaflet/vue-leaflet`
- [ ] Test GPS accuracy on mobile devices

**Day 5: Checklist Component**
- [ ] Create `ChecklistItem.vue` component
  - [ ] Item number and category badge
  - [ ] Item text (large, readable font)
  - [ ] Help icon with popover
  - [ ] Visual aid image (if available)
  - [ ] Pass/Fail/NA button group
  - [ ] Comment textarea (expandable)
  - [ ] Photo thumbnail (if captured)
  - [ ] "Required" badge
- [ ] Create `ChecklistView.vue` (swipeable cards)
- [ ] Mobile-optimized touch interactions
- [ ] Save progress on each item

### Week 2: Photo, Signature & Completion

**Day 6-7: Photo Capture**
- [ ] Create `PhotoCapture.vue` component
  - [ ] Native camera integration (HTML5 Media Capture)
  - [ ] Camera preview
  - [ ] Capture button
  - [ ] Retake/confirm buttons
  - [ ] Photo preview before adding
  - [ ] Compression for mobile upload
  - [ ] GPS coordinates in EXIF data
  - [ ] Timestamp in EXIF data
- [ ] Create `PhotoGallery.vue` component
  - [ ] Thumbnail grid
  - [ ] Full-size preview
  - [ ] Delete photo
  - [ ] Photo type categorization
- [ ] Backend: Photo upload endpoint
  - [ ] Azure Blob Storage integration
  - [ ] Generate thumbnail
  - [ ] Extract EXIF data
  - [ ] Save to InspectionPhotos table

**Day 8: Digital Signature**
- [ ] Create `SignaturePad.vue` component
  - [ ] HTML5 Canvas for drawing
  - [ ] Touch-optimized (finger drawing)
  - [ ] Clear button
  - [ ] Signature preview
  - [ ] Inspector name confirmation
  - [ ] Date/time stamp
  - [ ] Convert to base64 PNG
- [ ] Signature validation (not empty)

**Day 9: Inspection Completion**
- [ ] Create `InspectionReview.vue` component
  - [ ] Summary of all responses
  - [ ] Overall Pass/Fail determination
  - [ ] Deficiency count
  - [ ] Photo count
  - [ ] GPS location verification
  - [ ] Inspector signature
- [ ] Complete inspection endpoint
  - [ ] Generate tamper-proof hash (HMAC-SHA256)
  - [ ] Link to previous inspection (hash chain)
  - [ ] Calculate inspection duration
  - [ ] Update extinguisher NextServiceDueDate
  - [ ] Create deficiencies from failed items

**Day 10: Offline Support**
- [ ] IndexedDB schema for offline inspections
  - [ ] draftInspections table
  - [ ] offlinePhotos table (base64)
  - [ ] syncQueue table
- [ ] Save draft inspection to IndexedDB
- [ ] Resume draft inspection
- [ ] Background sync when online
  - [ ] Upload photos to blob storage
  - [ ] Submit inspection data
  - [ ] Mark as synced
- [ ] Offline indicator in UI
- [ ] Sync progress indicator
- [ ] Conflict resolution (if inspection modified server-side)

### Backend API Updates (Days 1-10)

**Inspection Endpoints:**
- [ ] POST `/api/inspections/{id}/photos` - Upload photo
- [ ] GET `/api/inspections/{id}/photos` - List photos
- [ ] DELETE `/api/inspections/{id}/photos/{photoId}` - Delete photo
- [ ] POST `/api/inspections/{id}/checklist` - Save checklist responses
- [ ] GET `/api/inspections/{id}/checklist` - Get checklist responses
- [ ] POST `/api/inspections/{id}/deficiencies` - Create deficiency
- [ ] GET `/api/inspections/{id}/deficiencies` - List deficiencies
- [ ] POST `/api/inspections/{id}/verify` - Verify hash chain

**Services:**
- [ ] `IPhotoService` + `AzureBlobPhotoService`
  - [ ] UploadPhotoAsync (with compression)
  - [ ] GenerateThumbnailAsync
  - [ ] ExtractEXIFDataAsync
  - [ ] GetPhotoAsync
  - [ ] DeletePhotoAsync
- [ ] Update `InspectionService`
  - [ ] CalculateInspectionHashAsync
  - [ ] VerifyHashChainAsync
  - [ ] GetPreviousInspectionHashAsync

**Azure Resources:**
- [ ] Create Azure Storage Account (if not exists)
- [ ] Create blob container: `inspection-photos`
- [ ] Configure CORS for blob storage
- [ ] Update connection string in Key Vault

### Success Criteria:
- [ ] ✅ Inspector can scan extinguisher barcode
- [ ] ✅ Inspector can complete full inspection on mobile device
- [ ] ✅ GPS location captured and validated
- [ ] ✅ Photos uploaded to blob storage
- [ ] ✅ Digital signature captured
- [ ] ✅ Inspection saved offline when no connectivity
- [ ] ✅ Offline inspections sync when online
- [ ] ✅ Tamper-proof hash generated and verified
- [ ] ✅ Complete 10 test inspections on mobile devices

---

## Phase 1B: Reporting & Scheduling (Weeks 3-4)

**Goal:** Enable automated scheduling and professional reporting
**Priority:** 🔴 CRITICAL - Customer-facing deliverables
**Duration:** 2 weeks
**Status:** ⏳ After Phase 1A

### Week 3: PDF Report Generation

**Day 11-12: QuestPDF Setup**
- [ ] Install QuestPDF NuGet package
- [ ] Create `ReportService.cs`
- [ ] Design report templates (PDF layout)
  - [ ] Inspection report template
  - [ ] Compliance summary template
  - [ ] Deficiency report template

**Day 13-14: Inspection Report**
- [ ] Create `InspectionReportGenerator.cs`
  - [ ] Company logo/branding
  - [ ] Extinguisher details section
  - [ ] Inspection metadata (date, inspector, location)
  - [ ] Checklist results table (Pass/Fail/NA)
  - [ ] Photos embedded (grid layout)
  - [ ] Deficiencies section (if any)
  - [ ] Inspector signature
  - [ ] Tamper-proof hash QR code
  - [ ] Footer with generated date
- [ ] API endpoint: GET `/api/reports/inspection/{inspectionId}`
- [ ] Frontend: "Download PDF" button on inspection detail view
- [ ] Email delivery option (SendGrid)

**Day 15: Compliance & Deficiency Reports**
- [ ] Create `ComplianceReportGenerator.cs`
  - [ ] Summary statistics (total, compliant, overdue)
  - [ ] Compliance rate by location
  - [ ] Inspection trends chart (12 months)
  - [ ] Overdue inspections list
- [ ] Create `DeficiencyReportGenerator.cs`
  - [ ] Open deficiencies by severity
  - [ ] Deficiencies by location
  - [ ] Aging report (days open)
  - [ ] Assigned vs. unassigned
- [ ] API endpoints for both reports
- [ ] Frontend: Reports view with filters

### Week 4: Automated Scheduling

**Day 16-17: Hangfire Setup**
- [ ] Install Hangfire NuGet packages
  - [ ] Hangfire.Core
  - [ ] Hangfire.SqlServer
  - [ ] Hangfire.AspNetCore
- [ ] Configure Hangfire in Program.cs
  - [ ] SQL Server storage
  - [ ] Dashboard at `/hangfire`
  - [ ] Authorization policy (admin only)
- [ ] Create `Jobs/` folder for background jobs

**Day 18: Due Date Calculation Job**
- [ ] Create `CalculateNextDueDatesJob.cs`
  - [ ] Run daily at 2 AM
  - [ ] Calculate next inspection due dates based on:
    - [ ] Last inspection date
    - [ ] Inspection type frequency (monthly = 30 days, annual = 365 days)
    - [ ] Extinguisher type requirements
    - [ ] NFPA 10 standards
  - [ ] Update Extinguishers.NextServiceDueDate
  - [ ] Log results to AuditLog
- [ ] Schedule recurring job
- [ ] Test manually via Hangfire dashboard

**Day 19: Reminder & Escalation Jobs**
- [ ] Configure SendGrid (or Azure Communication Services)
  - [ ] Create account
  - [ ] Get API key
  - [ ] Store in Azure Key Vault
  - [ ] Configure sender email (noreply@fireproofapp.net)
- [ ] Create email templates
  - [ ] Inspection due in 7 days
  - [ ] Inspection due in 3 days
  - [ ] Inspection due in 1 day
  - [ ] Inspection overdue
  - [ ] Critical deficiency alert
- [ ] Create `InspectionReminderJob.cs`
  - [ ] Run daily at 8 AM
  - [ ] Find inspections due in 7, 3, 1 days
  - [ ] Send email to inspectors and client contacts
  - [ ] Log reminder sent
- [ ] Create `OverdueInspectionEscalationJob.cs`
  - [ ] Run daily at 9 AM
  - [ ] Find inspections overdue by 1 week, 2 weeks, 1 month
  - [ ] Escalate to manager/admin
  - [ ] Send critical alerts

**Day 20: Testing & Refinement**
- [ ] Test all jobs manually
- [ ] Verify email delivery
- [ ] Check due date calculations
- [ ] Monitor job execution in Hangfire dashboard
- [ ] Add error handling and retries
- [ ] Create job monitoring alerts

### Success Criteria:
- [ ] ✅ Professional PDF inspection reports generated
- [ ] ✅ Compliance reports with charts and statistics
- [ ] ✅ Deficiency reports by severity and location
- [ ] ✅ Email delivery working (test with real emails)
- [ ] ✅ Automated due date calculation running daily
- [ ] ✅ Email reminders sent at correct intervals
- [ ] ✅ Overdue escalations working
- [ ] ✅ Hangfire dashboard accessible to admins
- [ ] ✅ 100% job success rate in Hangfire

### Phase 1 Complete Criteria:
- [ ] ✅ End-to-end inspection workflow operational
- [ ] ✅ Mobile-optimized UI tested on iOS and Android
- [ ] ✅ Offline inspections working
- [ ] ✅ PDF reports professional quality
- [ ] ✅ Automated scheduling reliable
- [ ] ✅ 10 beta testers complete 100 inspections combined
- [ ] ✅ Zero critical bugs
- [ ] ✅ Customer feedback collected and prioritized

**Timeline:** 4 weeks total
**Go/No-Go Decision:** Must pass all criteria before Phase 2

---

## Phase 2A: Business Features (Weeks 5-7)

**Goal:** Enable contractor business management capabilities
**Priority:** 🟠 HIGH - Required for contractor market
**Duration:** 3 weeks
**Status:** ⏳ After Phase 1B

### Week 5: Customer Portal

**Customer Management:**
- [ ] Create Customers table
- [ ] Create Contacts table (multiple per customer)
- [ ] Create stored procedures
  - [ ] usp_Customer_Create, GetAll, GetById, Update, Delete
  - [ ] usp_Contact_Create, GetAll, GetById, Update, Delete, GetByCustomer
- [ ] Backend services: `ICustomerService`, `IContactService`
- [ ] API controllers: `CustomersController`, `ContactsController`
- [ ] Frontend: CustomersView (CRUD)
  - [ ] Customer list
  - [ ] Customer detail with contacts
  - [ ] Add/edit customer
  - [ ] Add/edit contacts

**Customer-Facing Portal:**
- [ ] Separate route: `/portal/*`
- [ ] Customer login (separate from admin login)
- [ ] Customer dashboard
  - [ ] Equipment register (read-only)
  - [ ] Inspection history
  - [ ] Upcoming inspections
  - [ ] Deficiency status
  - [ ] Download inspection reports
- [ ] Customer profile management
- [ ] Contact management
- [ ] Notifications (email preferences)

### Week 6: Service Agreements

**Database:**
- [ ] Create ServiceAgreements table
- [ ] Create ServiceAgreementLineItems table (optional)
- [ ] Stored procedures
  - [ ] usp_ServiceAgreement_Create, GetAll, GetById, Update, Delete
  - [ ] usp_ServiceAgreement_GetByCustomer
  - [ ] usp_ServiceAgreement_Activate, Cancel, Renew

**Backend:**
- [ ] `IServiceAgreementService` + `ServiceAgreementService`
  - [ ] CreateServiceAgreementAsync
  - [ ] ActivateServiceAgreementAsync
  - [ ] GenerateRecurringInspectionsAsync
  - [ ] CancelServiceAgreementAsync
  - [ ] RenewServiceAgreementAsync

**Frontend:**
- [ ] ServiceAgreementsView
  - [ ] List all agreements
  - [ ] Filter by customer, status
  - [ ] Create new agreement
  - [ ] Edit agreement
  - [ ] Activate/cancel/renew
  - [ ] Link to customer
  - [ ] Generate recurring inspections

**Automated Inspections:**
- [ ] Background job: `ServiceAgreementInspectionJob`
  - [ ] Run daily
  - [ ] Find active service agreements
  - [ ] Generate scheduled inspections based on frequency
  - [ ] Assign to inspectors (manual or auto)

### Week 7: Quoting & Invoicing

**Database:**
- [ ] Create Quotes table
- [ ] Create QuoteLineItems table
- [ ] Create Invoices table
- [ ] Create InvoiceLineItems table
- [ ] Create Payments table
- [ ] Stored procedures for all CRUD operations

**Backend:**
- [ ] `IQuoteService` + `QuoteService`
  - [ ] CreateQuoteFromDeficiencyAsync (auto-populate)
  - [ ] ConvertQuoteToInvoiceAsync
  - [ ] SendQuoteAsync (email)
  - [ ] ApproveQuoteAsync (customer portal)
- [ ] `IInvoiceService` + `InvoiceService`
  - [ ] GenerateInvoiceAsync
  - [ ] SendInvoiceAsync (email)
  - [ ] RecordPaymentAsync
  - [ ] GetOutstandingBalanceAsync

**Frontend:**
- [ ] QuotesView
  - [ ] List quotes
  - [ ] Create quote (manual or from deficiency)
  - [ ] Add/remove line items
  - [ ] Apply discounts/taxes
  - [ ] Send to customer
  - [ ] Track approval status
  - [ ] Convert to invoice
- [ ] InvoicesView
  - [ ] List invoices
  - [ ] Generate from quote or service agreement
  - [ ] Track payment status (Unpaid, Partial, Paid)
  - [ ] Record payment
  - [ ] Send invoice (email)
  - [ ] Aging report (30/60/90 days)

**PDF Templates:**
- [ ] Quote PDF template (QuestPDF)
- [ ] Invoice PDF template (QuestPDF)
- [ ] Email templates for quote/invoice delivery

### Success Criteria:
- [ ] ✅ Customer portal live and functional
- [ ] ✅ Customers can view inspections and download reports
- [ ] ✅ Service agreements generating recurring inspections
- [ ] ✅ Quotes auto-generated from deficiencies
- [ ] ✅ Invoices generated and tracked
- [ ] ✅ Payment tracking working
- [ ] ✅ 5 test customers created
- [ ] ✅ 10 service agreements created
- [ ] ✅ 20 quotes/invoices processed

---

## Phase 2B: Analytics & Integration (Weeks 8-9)

**Goal:** Advanced analytics and accounting integration
**Priority:** 🟠 HIGH - Competitive differentiation
**Duration:** 2 weeks
**Status:** ⏳ After Phase 2A

### Week 8: Analytics Dashboard

**Backend:**
- [ ] Create `IDashboardService` + `DashboardService`
- [ ] Stored procedures
  - [ ] usp_Dashboard_ComplianceMetrics
  - [ ] usp_Dashboard_InspectionTrends
  - [ ] usp_Dashboard_DeficiencyMetrics
  - [ ] usp_Dashboard_RevenueMetrics
  - [ ] usp_Dashboard_InspectorPerformance

**Frontend:**
- [ ] Install Chart.js (or Recharts)
- [ ] Create reusable chart components
  - [ ] LineChart.vue
  - [ ] BarChart.vue
  - [ ] PieChart.vue
  - [ ] DonutChart.vue
- [ ] Enhanced DashboardView
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

### Week 9: QuickBooks Integration

**Setup:**
- [ ] Create QuickBooks developer account
- [ ] Create QuickBooks app (OAuth)
- [ ] Configure OAuth redirect URIs
- [ ] Store credentials in Azure Key Vault

**Backend:**
- [ ] Install QuickBooks SDK NuGet package
- [ ] Create `IQuickBooksService` + `QuickBooksService`
  - [ ] OAuth authentication flow
  - [ ] SyncCustomersAsync
  - [ ] CreateInvoiceInQuickBooksAsync
  - [ ] SyncPaymentsAsync
  - [ ] GetChartOfAccountsAsync
- [ ] Create QuickBooksController
  - [ ] GET `/api/quickbooks/connect` - Initiate OAuth
  - [ ] GET `/api/quickbooks/callback` - OAuth callback
  - [ ] POST `/api/quickbooks/sync/customers`
  - [ ] POST `/api/quickbooks/sync/invoices`
  - [ ] POST `/api/quickbooks/sync/payments`

**Frontend:**
- [ ] Settings view: QuickBooks Integration section
  - [ ] "Connect to QuickBooks" button
  - [ ] Connection status indicator
  - [ ] Last sync date
  - [ ] Manual sync button
  - [ ] Disconnect button
- [ ] Auto-sync options
  - [ ] Sync new invoices automatically
  - [ ] Sync payments automatically

**Background Job:**
- [ ] Create `QuickBooksSyncJob`
  - [ ] Run daily at 11 PM
  - [ ] Sync invoices created today
  - [ ] Sync payments received today
  - [ ] Log sync results

### Success Criteria:
- [ ] ✅ Dashboard with 8+ visualizations
- [ ] ✅ Real-time data (< 5 second load time)
- [ ] ✅ Date range filtering working
- [ ] ✅ Dashboard export to PDF
- [ ] ✅ QuickBooks OAuth working
- [ ] ✅ Customers syncing to QuickBooks
- [ ] ✅ Invoices syncing to QuickBooks
- [ ] ✅ Payments syncing from QuickBooks
- [ ] ✅ Auto-sync running daily

### Phase 2 Complete Criteria:
- [ ] ✅ Customer portal operational
- [ ] ✅ Service agreements generating inspections
- [ ] ✅ Quoting and invoicing functional
- [ ] ✅ Analytics dashboard live
- [ ] ✅ QuickBooks integration tested
- [ ] ✅ 5 paying customers acquired
- [ ] ✅ $1,000 MRR (Monthly Recurring Revenue)
- [ ] ✅ Customer satisfaction > 8/10

**Timeline:** 5 weeks total (Weeks 5-9)
**Go/No-Go Decision:** Must achieve $1,000 MRR before Phase 3

---

## Phase 3: AI Features (Weeks 10-13)

**Goal:** AI-powered scheduling and predictive maintenance (UNIQUE in market)
**Priority:** 🟠 MEDIUM-HIGH - Competitive differentiator
**Duration:** 4 weeks
**Status:** ⏳ After Phase 2B

### Week 10: Data Collection & Feature Engineering

**Database:**
- [ ] Create InspectionMetrics table (for ML training)
- [ ] Create EnvironmentalFactors table
- [ ] Stored procedures
  - [ ] usp_InspectionMetrics_Populate (daily job)
  - [ ] usp_EnvironmentalFactors_GetByLocation

**Background Job:**
- [ ] Create `PopulateInspectionMetricsJob`
  - [ ] Run daily at 3 AM
  - [ ] Extract inspection data for ML training
  - [ ] Calculate metrics (days since last, deficiency count, etc.)
  - [ ] Store in InspectionMetrics table

**Python Environment:**
- [ ] Setup Azure ML workspace
- [ ] Create Azure Function (Python) or Container App
- [ ] Install dependencies
  - [ ] scikit-learn
  - [ ] pandas
  - [ ] numpy
  - [ ] azure-ml-sdk
  - [ ] sqlalchemy (for SQL Server connection)

**Data Extraction:**
- [ ] Create Python script: `extract_training_data.py`
  - [ ] Connect to SQL Server
  - [ ] Query inspection history
  - [ ] Query environmental factors
  - [ ] Query extinguisher metadata
  - [ ] Create training dataset CSV/Parquet

**Feature Engineering:**
- [ ] Create Python script: `feature_engineering.py`
  - [ ] equipment_age_years
  - [ ] days_since_last_inspection
  - [ ] historical_deficiency_count
  - [ ] location_risk_score (0-100)
  - [ ] avg_temperature
  - [ ] avg_humidity
  - [ ] indoor_outdoor (binary)
  - [ ] exposure_to_chemicals (binary)
  - [ ] manufacturer_reliability (historical fail rate)
  - [ ] extinguisher_type (categorical, one-hot encoded)
  - [ ] capacity

### Week 11: Model Training

**Model Development:**
- [ ] Create Python script: `train_model.py`
  - [ ] Load training data
  - [ ] Split train/validation/test sets
  - [ ] Train regression model (optimal inspection interval)
    - [ ] Random Forest Regressor
    - [ ] Gradient Boosting Regressor
    - [ ] Compare performance
  - [ ] Train classification model (risk level: low/medium/high/critical)
    - [ ] Random Forest Classifier
    - [ ] XGBoost Classifier
  - [ ] Hyperparameter tuning (GridSearchCV)
  - [ ] Cross-validation (5-fold)
  - [ ] Model evaluation metrics
    - [ ] Regression: RMSE, MAE, R²
    - [ ] Classification: Accuracy, Precision, Recall, F1

**Model Versioning:**
- [ ] Setup MLflow
- [ ] Log experiments
- [ ] Track model performance
- [ ] Save best model

### Week 12: Model Deployment & API

**Model Deployment:**
- [ ] Deploy to Azure ML endpoint (or Azure Function)
- [ ] Create inference API (Flask or FastAPI)
  - [ ] POST `/predict/optimal-interval`
  - [ ] POST `/predict/risk-score`
  - [ ] POST `/predict/batch`
  - [ ] GET `/model/info` (version, metrics)

**Backend Integration:**
- [ ] Create `IAISchedulingService` + `AISchedulingService`
  - [ ] GetRecommendedInspectionDateAsync(extinguisherId)
  - [ ] CalculateRiskScoreAsync(extinguisherId)
  - [ ] GetHighRiskExtinguishersAsync(tenantId)
  - [ ] OptimizeInspectionScheduleAsync(tenantId, locationId)
  - [ ] GetRouteOptimizationAsync(inspectionIds[])

**Background Job:**
- [ ] Create `UpdateRiskScoresJob`
  - [ ] Run daily at 4 AM
  - [ ] Call AI service for all extinguishers
  - [ ] Update ExtinguisherMetrics table with risk scores
  - [ ] Generate alerts for high-risk equipment (>80)
  - [ ] Email alerts to admins

### Week 13: AI Frontend & Route Optimization

**Frontend:**
- [ ] Create AIInsightsView
  - [ ] High-risk extinguisher list (top 10)
  - [ ] Risk score heat map by location
  - [ ] Recommended inspection schedule (AI-optimized)
  - [ ] Predicted failure timeline chart
  - [ ] Inspection efficiency metrics (AI vs. manual)
  - [ ] Estimated cost savings
- [ ] Create InspectionScheduleOptimizer
  - [ ] "Auto-Schedule with AI" button
  - [ ] Show AI vs. manual schedule comparison
  - [ ] Route optimization map (GPS-based)
  - [ ] Estimated time savings display
  - [ ] Accept/reject AI recommendations

**Route Optimization:**
- [ ] Integrate Google Maps Directions API (or Azure Maps)
- [ ] Calculate optimal routes for multiple inspections
- [ ] Consider:
  - [ ] Inspector location (start point)
  - [ ] Inspection locations
  - [ ] Traffic conditions
  - [ ] Inspection priority (overdue first)
  - [ ] Time windows (business hours)
- [ ] Display on map with numbered waypoints

### Success Criteria:
- [ ] ✅ ML model accuracy > 85% (risk prediction)
- [ ] ✅ AI recommendations accepted > 60% of time
- [ ] ✅ Risk scores updated daily
- [ ] ✅ High-risk alerts sent correctly
- [ ] ✅ Route optimization reduces travel time by 20%
- [ ] ✅ AI insights dashboard live
- [ ] ✅ 100+ inspections used for training
- [ ] ✅ Model versioning and monitoring in place

**Timeline:** 4 weeks (Weeks 10-13)

---

## Phase 4: Native Mobile Apps (Weeks 14-19)

**Goal:** Native iOS and Android apps for better performance
**Priority:** 🟡 MEDIUM - Enhanced user experience
**Duration:** 6 weeks
**Status:** ⏳ After Phase 3

### Week 14-16: iOS App (Swift/SwiftUI)

**Setup:**
- [ ] Create Xcode project
- [ ] Configure app signing
- [ ] Setup App Store Connect

**Core Infrastructure:**
- [ ] Networking layer (URLSession)
- [ ] Core Data models (offline storage)
- [ ] Authentication service (JWT)
- [ ] Offline sync manager
- [ ] Keychain for secure token storage

**Features:**
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

**Offline Sync:**
- [ ] Offline inspection queue
- [ ] Background sync (BackgroundTasks framework)
- [ ] Conflict resolution

**Push Notifications:**
- [ ] Setup APNs (Apple Push Notification service)
- [ ] Inspection reminders
- [ ] Deficiency alerts

**Testing:**
- [ ] Unit tests (XCTest)
- [ ] UI tests (XCUITest)
- [ ] TestFlight beta testing

**Submission:**
- [ ] App Store submission
- [ ] Screenshots
- [ ] App description
- [ ] Privacy policy

### Week 17-19: Android App (Kotlin/Jetpack Compose)

**Setup:**
- [ ] Create Android Studio project
- [ ] Configure app signing
- [ ] Setup Google Play Console

**Core Infrastructure:**
- [ ] Networking layer (Retrofit + OkHttp)
- [ ] Room database (offline storage)
- [ ] Authentication service (JWT)
- [ ] Offline sync manager (WorkManager)
- [ ] Encrypted SharedPreferences

**Features:**
- [ ] Login screen (Composable)
- [ ] Dashboard
- [ ] Locations, Extinguishers
- [ ] Barcode scanner (CameraX + ML Kit)
- [ ] Inspection form
- [ ] Photo capture (CameraX)
- [ ] GPS (Location Services)
- [ ] Digital signature (Canvas)
- [ ] Reports

**Offline Sync:**
- [ ] Offline queue
- [ ] Background sync (WorkManager)
- [ ] Conflict resolution

**Push Notifications:**
- [ ] Setup FCM (Firebase Cloud Messaging)
- [ ] Inspection reminders
- [ ] Deficiency alerts

**Testing:**
- [ ] Unit tests (JUnit)
- [ ] UI tests (Espresso)
- [ ] Internal testing track

**Submission:**
- [ ] Google Play Store submission
- [ ] Screenshots
- [ ] Store listing
- [ ] Privacy policy

### Success Criteria:
- [ ] ✅ iOS app approved on App Store
- [ ] ✅ Android app approved on Google Play
- [ ] ✅ 500 inspections completed via native apps
- [ ] ✅ Offline sync working reliably
- [ ] ✅ Push notifications delivered
- [ ] ✅ 4.5+ star rating on both stores
- [ ] ✅ < 5% crash rate

**Timeline:** 6 weeks (Weeks 14-19)

---

## Phase 5: Enterprise Features (Weeks 20-23)

**Goal:** Enterprise-grade features for large organizations
**Priority:** 🟡 MEDIUM - Enterprise market
**Duration:** 4 weeks
**Status:** ⏳ After Phase 4

### Week 20: Multi-System Support

**Fire Alarms (NFPA 72):**
- [ ] Create FireAlarms table
- [ ] Create AlarmInspections table
- [ ] NFPA 72 checklist templates
- [ ] Stored procedures
- [ ] Backend services
- [ ] Frontend views

**Fire Sprinklers (NFPA 25):**
- [ ] Create FireSprinklerSystems table
- [ ] Create SprinklerInspections table
- [ ] NFPA 25 checklist templates
- [ ] Stored procedures
- [ ] Backend services
- [ ] Frontend views

**Emergency Lighting:**
- [ ] Create EmergencyLights table
- [ ] Create EmergencyLightInspections table
- [ ] Checklist templates (30-second, 90-minute tests)
- [ ] Stored procedures
- [ ] Backend services
- [ ] Frontend views

### Week 21: White-Label & SSO

**White-Label:**
- [ ] Create TenantBranding table
- [ ] Logo upload (Azure Blob Storage)
- [ ] Favicon upload
- [ ] Primary/secondary color configuration
- [ ] Custom domain support (DNS CNAME)
- [ ] "Powered by" hide option (enterprise tier)
- [ ] Frontend: Dynamic branding from tenant config

**SSO Integration:**
- [ ] SAML 2.0 support
- [ ] Azure AD integration
- [ ] Okta integration
- [ ] Google Workspace
- [ ] Custom OIDC providers
- [ ] Backend: SAML/OIDC middleware
- [ ] Frontend: SSO login button

### Week 22: Technician Management

**Database:**
- [ ] Create Technicians table
- [ ] Create TechnicianSchedule table
- [ ] Create TechnicianCertifications table
- [ ] Stored procedures

**Backend:**
- [ ] `ITechnicianService` + `TechnicianService`
- [ ] Route optimization algorithm
  - [ ] Assign inspections to technicians
  - [ ] Optimize travel routes
  - [ ] Estimated completion time
  - [ ] Real-time GPS tracking

**Frontend:**
- [ ] TechniciansView
  - [ ] List technicians
  - [ ] Calendar view (availability)
  - [ ] Assign inspections
  - [ ] Track certifications
  - [ ] Performance metrics

### Week 23: Advanced Reporting

**Report Templates:**
- [ ] Compliance audit report
- [ ] Customer invoice report
- [ ] Technician performance report
- [ ] Revenue by location report
- [ ] Equipment lifecycle report
- [ ] Deficiency trends report

**Scheduled Reports:**
- [ ] Background job: `ScheduledReportsJob`
- [ ] Email reports on schedule (daily, weekly, monthly)
- [ ] Auto-generate compliance reports for AHJs
- [ ] Customer automatic delivery

**Custom Report Builder:**
- [ ] Drag-and-drop interface
- [ ] Select data sources
- [ ] Choose visualizations
- [ ] Save custom reports
- [ ] Schedule automated delivery

### Success Criteria:
- [ ] ✅ Multi-system support live (alarms, sprinklers, lighting)
- [ ] ✅ White-label customer deployed
- [ ] ✅ SSO integration tested (Azure AD + Okta)
- [ ] ✅ Technician routing reduces travel time by 30%
- [ ] ✅ Custom reports working
- [ ] ✅ Scheduled reports delivered
- [ ] ✅ 1 enterprise customer ($500+/month)
- [ ] ✅ $10,000 MRR
- [ ] ✅ 20 total paying customers

**Timeline:** 4 weeks (Weeks 20-23)

---

## Post-Phase 5: Continuous Improvement

### Ongoing Work:
- [ ] Performance optimization
- [ ] Security audits
- [ ] GDPR compliance
- [ ] SOC 2 Type II certification
- [ ] Customer feedback implementation
- [ ] Bug fixes and patches
- [ ] Feature requests
- [ ] Scaling (database, API, infrastructure)
- [ ] Documentation updates
- [ ] User training materials
- [ ] Marketing website
- [ ] Sales enablement materials

---

## Revenue Targets

**Phase 1 Complete (Week 4):**
- Target: 10 beta testers
- MRR: $0 (free beta)

**Phase 2A Complete (Week 7):**
- Target: 5 paying customers
- MRR: $1,000
- Average: $200/customer

**Phase 2B Complete (Week 9):**
- Target: 10 paying customers
- MRR: $2,500
- Average: $250/customer

**Phase 3 Complete (Week 13):**
- Target: 15 paying customers
- MRR: $5,000
- Average: $333/customer

**Phase 4 Complete (Week 19):**
- Target: 25 paying customers
- MRR: $8,000
- Average: $320/customer

**Phase 5 Complete (Week 23):**
- Target: 30 paying customers (including 1 enterprise)
- MRR: $10,000+
- Average: $333/customer

---

## Risk Management

### Phase 1 Risks:
- **Mobile compatibility issues** → Mitigation: Test on multiple devices early
- **Offline sync complexity** → Mitigation: Use proven libraries (Dexie.js)
- **GPS accuracy problems** → Mitigation: Allow manual override

### Phase 2 Risks:
- **QuickBooks API changes** → Mitigation: Monitor API changelog, have fallback
- **Email deliverability** → Mitigation: Use reputable service (SendGrid)
- **Customer adoption** → Mitigation: Excellent onboarding, free trial

### Phase 3 Risks:
- **Insufficient training data** → Mitigation: Start with 100+ inspections minimum
- **Model accuracy** → Mitigation: A/B test AI vs. manual scheduling
- **Cost of AI infrastructure** → Mitigation: Use serverless (Azure Functions)

### Phase 4 Risks:
- **App Store rejection** → Mitigation: Follow guidelines strictly, use TestFlight
- **Native app development timeline** → Mitigation: Consider React Native if falling behind
- **Platform-specific bugs** → Mitigation: Thorough testing on both platforms

### Phase 5 Risks:
- **Enterprise sales cycle** → Mitigation: Start enterprise conversations early
- **SSO complexity** → Mitigation: Use proven libraries (Sustainsys.Saml2)
- **Multi-system complexity** → Mitigation: Reuse inspection infrastructure

---

## Success Metrics Summary

| Phase | Duration | MRR Target | Customers | Key Deliverable |
|-------|----------|------------|-----------|-----------------|
| 0: Foundation | 4 weeks | $0 | 0 | Database + API + Frontend |
| 1A: Inspection | 2 weeks | $0 | 10 beta | Mobile inspection workflow |
| 1B: Reporting | 2 weeks | $0 | 10 beta | PDF reports + scheduling |
| 2A: Business | 3 weeks | $1,000 | 5 | Customer portal + invoicing |
| 2B: Analytics | 2 weeks | $2,500 | 10 | Dashboard + QuickBooks |
| 3: AI Features | 4 weeks | $5,000 | 15 | AI scheduling + risk scoring |
| 4: Native Apps | 6 weeks | $8,000 | 25 | iOS + Android apps |
| 5: Enterprise | 4 weeks | $10,000+ | 30 | Multi-system + white-label |

**Total Timeline:** 23 weeks (~5.5 months) from Phase 0 complete to full enterprise platform

---

**Last Updated:** October 18, 2025
**Next Review:** Weekly during active development
