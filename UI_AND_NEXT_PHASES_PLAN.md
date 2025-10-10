# FireProof UI Completion & Next Phases Plan

**Created**: October 10, 2025
**Status**: Active Planning
**Current Phase**: Backend Complete ✅ → UI Development

---

## Current Status

### ✅ Completed (Backend API)
- ASP.NET Core 8.0 API with Entity Framework
- JWT authentication with role-based authorization
- Azure Key Vault integration for secrets
- Complete REST API endpoints for:
  - Authentication (login, register, logout)
  - Locations (CRUD)
  - Extinguisher Types (CRUD)
  - Extinguishers (CRUD with barcode support)
  - Inspections (full workflow)
  - Reports (monthly, annual, compliance)
- Tamper-proofing with digital signatures
- Database schema deployed to SQL Server
- All 93 backend tests passing
- Production deployment successful
  - App Service: https://fireproof-api-test-2025.azurewebsites.net
  - Application Insights configured
  - Health check: ✅ HEALTHY

### 🔄 In Progress (Frontend Vue.js)
- Vue 3 + Vite project created
- Dependencies installed (Vue Router, Pinia, Axios, Tailwind)
- Basic routing configured
- Auth store started
- Location service (TypeScript) defined
- Views created:
  - HomeView (placeholder)
  - LoginView (basic)
  - DashboardView (placeholder)
  - LocationsView (basic)

### ⏳ Not Started
- Complete authentication UI
- Extinguisher management UI
- Inspection workflow UI
- Reporting and dashboard UI
- Settings and user management UI
- Offline/PWA support
- Mobile apps (iOS/Android)
- Service Provider multi-tenancy

---

## Phase 1: Complete Web Application UI (2-3 Weeks)

### Week 1: Core Features UI

#### 1. Authentication & User Management (3 days)
**Priority**: 🔴 Critical

**Tasks**:
- [ ] Complete Login view
  - Email/password form
  - "Remember me" checkbox
  - Error handling
  - Redirect after login
  - Loading states

- [ ] Create Register view
  - Registration form (email, password, first name, last name)
  - Password strength indicator
  - Terms of service checkbox
  - Success confirmation
  - Email verification (future)

- [ ] Create User Profile view
  - View/edit profile
  - Change password
  - Avatar upload
  - Preferences

- [ ] Enhance auth store
  - Login/logout actions
  - Token refresh
  - User info persistence
  - Role management

- [ ] Create auth service
  - API integration for all auth endpoints
  - Error handling
  - Token interceptor

**Components Needed**:
- `components/auth/LoginForm.vue`
- `components/auth/RegisterForm.vue`
- `components/auth/UserProfile.vue`
- `components/auth/ChangePassword.vue`

**API Endpoints**:
- `POST /api/authentication/register`
- `POST /api/authentication/login`
- `POST /api/authentication/logout`
- `GET /api/authentication/me`
- `PUT /api/users/{id}`

---

#### 2. Location Management UI (2 days)
**Priority**: 🔴 Critical

**Tasks**:
- [ ] Complete LocationsView
  - Location list table
  - Search and filter
  - Add location button
  - Edit/delete actions
  - Pagination

- [ ] Create LocationForm component
  - Create/edit mode
  - Form validation
  - GPS coordinate input
  - Address fields
  - Submit/cancel actions

- [ ] Create LocationDetails component
  - View location info
  - List extinguishers at location
  - Quick actions (add extinguisher, view inspections)
  - Delete confirmation modal

**Components**:
- `components/locations/LocationList.vue`
- `components/locations/LocationForm.vue`
- `components/locations/LocationDetails.vue`
- `components/locations/LocationFilters.vue`

**Store**: `stores/locations.ts` (enhance existing)

---

#### 3. Extinguisher Management UI (2 days)
**Priority**: 🔴 Critical

**Tasks**:
- [ ] Create ExtinguishersView
  - Extinguisher list table
  - Status indicators (due, overdue, good)
  - Search, filter, sort
  - Scan barcode button
  - Add extinguisher button

- [ ] Create ExtinguisherForm component
  - Create/edit form
  - Location dropdown
  - Type dropdown
  - Serial number, barcode
  - Installation date
  - Last inspection display

- [ ] Create ExtinguisherDetails component
  - Full extinguisher details
  - Inspection history timeline
  - QR code display
  - Quick inspect button
  - Edit/delete actions

- [ ] Create BarcodeScanner component
  - HTML5-QRCode integration
  - Camera access request
  - Scan success/failure feedback
  - Manual entry fallback

**Components**:
- `components/extinguishers/ExtinguisherList.vue`
- `components/extinguishers/ExtinguisherForm.vue`
- `components/extinguishers/ExtinguisherDetails.vue`
- `components/extinguishers/BarcodeScanner.vue`
- `components/extinguishers/InspectionHistory.vue`

**Store**: `stores/extinguishers.ts` (create)

---

### Week 2: Inspection Workflow & Dashboard

#### 4. Inspection Workflow UI (3 days)
**Priority**: 🔴 Critical

**Tasks**:
- [ ] Create InspectionsView
  - Inspection list
  - Filter by status, date, location
  - Due inspections widget
  - Start inspection button

- [ ] Create InspectionWizard component (multi-step)
  - Step 1: Scan extinguisher barcode
  - Step 2: Select inspection type
  - Step 3: Complete checklist
  - Step 4: Add photos and notes
  - Step 5: Review and submit
  - Progress indicator
  - Save draft functionality

- [ ] Create ChecklistItem component
  - Pass/Fail/NA radio buttons
  - Required field indicator
  - Photo capture button
  - Notes textarea

- [ ] Create PhotoCapture component
  - Camera access
  - Capture photo
  - Preview
  - Multiple photos
  - Compress before upload

- [ ] Create InspectionDetails component
  - View completed inspection
  - All checklist responses
  - Photos gallery
  - GPS coordinates
  - Tamper-proof verification
  - PDF export button

**Components**:
- `components/inspections/InspectionList.vue`
- `components/inspections/InspectionWizard.vue`
- `components/inspections/ChecklistItem.vue`
- `components/inspections/PhotoCapture.vue`
- `components/inspections/InspectionDetails.vue`
- `components/inspections/InspectionSummary.vue`

**Store**: `stores/inspections.ts` (enhance existing)

---

#### 5. Dashboard UI (2 days)
**Priority**: 🔴 Critical

**Tasks**:
- [ ] Complete DashboardView
  - KPI cards (total extinguishers, inspections due, overdue count, compliance %)
  - Compliance gauge chart
  - Recent inspections list
  - Upcoming inspections widget
  - Quick action buttons
  - Location breakdown chart

- [ ] Create ComplianceGauge component
  - Circular progress gauge
  - Color-coded (green, yellow, red)
  - Percentage display

- [ ] Create RecentActivity component
  - Timeline of recent inspections
  - Filter by date range
  - Link to details

**Components**:
- `components/dashboard/KPICard.vue`
- `components/dashboard/ComplianceGauge.vue`
- `components/dashboard/RecentActivity.vue`
- `components/dashboard/UpcomingInspections.vue`
- `components/charts/ComplianceChart.vue` (use Chart.js or similar)

**Dependencies**:
```bash
npm install chart.js vue-chartjs
```

---

### Week 3: Reporting, Settings & Polish

#### 6. Reporting UI (2 days)
**Priority**: 🟠 High

**Tasks**:
- [ ] Create ReportsView
  - Report type selector
  - Date range picker
  - Generate button
  - Preview section
  - Export buttons (PDF, Excel)

- [ ] Create MonthlyReport component
  - Summary stats
  - Inspection list table
  - Compliance breakdown
  - Export functionality

- [ ] Create AnnualReport component
  - Year selector
  - Compliance trend chart
  - Month-by-month breakdown
  - Location comparison

- [ ] Create ComplianceReport component
  - Real-time compliance dashboard
  - Filter by location
  - Due vs completed chart
  - Deficiency list

**Components**:
- `components/reports/ReportGenerator.vue`
- `components/reports/MonthlyReport.vue`
- `components/reports/AnnualReport.vue`
- `components/reports/ComplianceReport.vue`
- `components/reports/DateRangePicker.vue`

---

#### 7. Settings & User Management (1 day)
**Priority**: 🟠 High

**Tasks**:
- [ ] Create SettingsView
  - Tab navigation (Profile, Users, Preferences, About)
  - Profile tab (user profile component)
  - Users tab (user list, invite users)
  - Preferences tab (notifications, defaults)
  - About tab (version, support)

- [ ] Create UserManagement component
  - User list table
  - Invite user button
  - Edit roles
  - Deactivate user

**Components**:
- `components/settings/SettingsView.vue`
- `components/settings/UserManagement.vue`
- `components/settings/InviteUserModal.vue`
- `components/settings/PreferencesForm.vue`

---

#### 8. Common Components & UX Polish (2 days)
**Priority**: 🟠 High

**Tasks**:
- [ ] Create AppHeader component
  - Logo
  - Navigation menu
  - User dropdown (profile, settings, logout)
  - Notifications icon (future)
  - Tenant switcher (future)

- [ ] Create AppSidebar component
  - Navigation links
  - Active link highlighting
  - Role-based menu items
  - Collapse/expand

- [ ] Create common components
  - LoadingSpinner
  - ErrorAlert
  - SuccessToast
  - ConfirmDialog
  - EmptyState
  - Pagination
  - SearchInput
  - FilterDropdown

- [ ] Add loading states to all views
- [ ] Add error handling to all API calls
- [ ] Add success feedback for all actions
- [ ] Implement responsive design (mobile-friendly)
- [ ] Add keyboard navigation
- [ ] Test all user flows

**Components**:
- `components/layout/AppHeader.vue`
- `components/layout/AppSidebar.vue`
- `components/layout/AppFooter.vue`
- `components/common/LoadingSpinner.vue`
- `components/common/ErrorAlert.vue`
- `components/common/SuccessToast.vue`
- `components/common/ConfirmDialog.vue`
- `components/common/EmptyState.vue`
- `components/common/Pagination.vue`

---

#### 9. Offline Support (PWA) (1 day)
**Priority**: 🟡 Medium

**Tasks**:
- [ ] Configure Vite PWA plugin
- [ ] Create service worker
- [ ] Implement IndexedDB for offline storage
- [ ] Add offline inspection queue
- [ ] Create sync indicator
- [ ] Test offline functionality

**Files**:
- `vite.config.js` (PWA configuration)
- `src/services/offline.service.ts`
- `src/utils/indexeddb.ts`

---

## Phase 2: Mobile Applications (6-8 Weeks)

### iOS App (3-4 weeks)
**Priority**: 🟡 Medium

**Tech Stack**: Swift + SwiftUI + Core Data

**Features**:
- Native iOS app for iPhone/iPad
- Barcode scanning with AVFoundation
- Offline-first with Core Data
- GPS tracking with Core Location
- Photo capture with native camera
- Background sync
- Push notifications (APNs)
- Biometric authentication (Face ID/Touch ID)

**Key Screens**:
- Login
- Dashboard
- Location list/details
- Extinguisher list/details/scan
- Inspection wizard
- Reports

**Timeline**:
- Week 1: Project setup, authentication, networking
- Week 2: Core Data models, offline sync
- Week 3: Barcode scanning, inspection workflow
- Week 4: Testing, App Store submission

---

### Android App (3-4 weeks)
**Priority**: 🟡 Medium

**Tech Stack**: Kotlin + Jetpack Compose + Room

**Features**:
- Native Android app
- Barcode scanning with CameraX + ML Kit
- Offline-first with Room database
- GPS tracking with Location Services
- Photo capture with CameraX
- Background sync with WorkManager
- Push notifications (FCM)
- Biometric authentication

**Key Screens**: Same as iOS

**Timeline**: Same as iOS

---

## Phase 3: Service Provider Multi-Tenancy (8-10 Weeks)

### Overview
Enable 3rd-party inspection companies to manage multiple customer tenants through the platform.

### Key Features
1. **Hierarchical Multi-Tenancy**
   - Service Provider entity
   - Provider-Tenant relationships
   - Provider users can access multiple tenants
   - Tenant switching in UI

2. **Service Provider Dashboard**
   - Consolidated view across all tenants
   - Cross-tenant compliance metrics
   - Revenue analytics
   - Inspector workload balancing

3. **Billing & Invoicing**
   - Multiple billing models (per-inspection, monthly, annual)
   - Automated invoice generation
   - Stripe integration for payments
   - Commission tracking

4. **Inspector Management**
   - Assign inspectors to tenants
   - Cross-tenant scheduling
   - Route optimization
   - Performance tracking

5. **White-Label Branding**
   - Custom logo and colors
   - Custom domain
   - Branded reports
   - Email templates

### Database Changes
- `dbo.ServiceProviders` table
- `dbo.ServiceProviderTenants` table
- `dbo.ServiceProviderUsers` table
- `dbo.ServiceProviderInvoices` table
- `dbo.ServiceProviderContracts` table
- Update authorization policies

### API Endpoints
- `/api/service-providers/*`
- `/api/service-providers/{id}/tenants/*`
- `/api/service-providers/{id}/invoices/*`
- `/api/service-providers/{id}/dashboard`

### UI Components
- Provider registration/onboarding
- Provider dashboard
- Tenant management
- Billing dashboard
- Inspector assignment
- Cross-tenant reporting

**Timeline**:
- Weeks 1-2: Database schema, stored procedures
- Weeks 3-4: Backend services and API
- Weeks 5-6: Provider portal UI
- Weeks 7-8: Billing integration (Stripe)
- Weeks 9-10: Testing, documentation

---

## Phase 4: Advanced Features (Future)

### AI-Powered Defect Detection
- Computer vision for extinguisher inspection
- Automatic pressure gauge reading (OCR)
- Rust and corrosion detection
- Seal integrity verification

### Predictive Maintenance
- ML model to predict failures
- Maintenance scheduling optimization
- Budget forecasting
- Anomaly detection

### IoT Integration
- BLE smart tags for extinguishers
- Tamper detection sensors
- Pressure monitoring
- Automatic location tracking

### Advanced Analytics
- Power BI embedded dashboards
- Custom report builder
- Trend analysis
- Forecasting

### Additional Integrations
- QuickBooks/Xero (accounting)
- Salesforce (CRM)
- Microsoft Teams/Slack (notifications)
- Zapier (workflow automation)

---

## Implementation Strategy

### Immediate Next Steps (This Week)

1. **Authentication UI** (Day 1-2)
   - Complete login/register views
   - Add error handling
   - Test authentication flow

2. **Location Management** (Day 2-3)
   - Build location CRUD UI
   - Test API integration

3. **Extinguisher Management** (Day 3-5)
   - Build extinguisher CRUD UI
   - Implement barcode scanner
   - Test workflow

4. **Inspection Workflow** (Week 2)
   - Build inspection wizard
   - Photo capture
   - Test complete workflow

5. **Dashboard & Reporting** (Week 3)
   - Build dashboard with charts
   - Implement reports
   - Polish UI/UX

### Resource Allocation

**Frontend Developer** (You + AI):
- Focus on UI components
- API integration
- Testing

**Time Estimate**:
- Phase 1 (Web UI): 2-3 weeks
- Phase 2 (Mobile): 6-8 weeks (can be parallel)
- Phase 3 (Service Provider): 8-10 weeks

### Development Approach

1. **Component-First Development**
   - Build reusable components
   - Use Storybook for component development (optional)
   - Test components in isolation

2. **API-First Integration**
   - All API endpoints already working
   - Focus on proper error handling
   - Use TypeScript for type safety

3. **Iterative Testing**
   - Test each feature as you build
   - User acceptance testing with stakeholders
   - Fix bugs immediately

4. **Continuous Deployment**
   - Deploy to Vercel or Azure Static Web Apps
   - Set up CI/CD for frontend
   - Automated testing in pipeline

---

## Technical Decisions

### Frontend Technology
- ✅ Vue 3 with Composition API
- ✅ TypeScript for type safety
- ✅ Tailwind CSS for styling
- ✅ Pinia for state management
- ✅ Axios for HTTP requests
- Add: Chart.js for visualizations
- Add: date-fns for date handling
- Add: Headless UI for accessible components

### State Management Strategy
- **Auth store**: User authentication, tokens, permissions
- **Locations store**: Location CRUD, filtering
- **Extinguishers store**: Extinguisher CRUD, search
- **Inspections store**: Inspection workflow, offline queue
- **Reports store**: Report data, caching

### API Integration Pattern
```typescript
// Service layer (e.g., locationService.ts)
export const locationService = {
  async getLocations() {
    const response = await api.get('/api/locations')
    return response.data
  },
  // ... more methods
}

// Store (e.g., locations.ts)
export const useLocationStore = defineStore('locations', {
  state: () => ({ locations: [], loading: false }),
  actions: {
    async fetchLocations() {
      this.loading = true
      try {
        this.locations = await locationService.getLocations()
      } catch (error) {
        // Handle error
      } finally {
        this.loading = false
      }
    }
  }
})
```

### Error Handling Strategy
- Display toast notifications for errors
- Log errors to Application Insights
- Provide user-friendly error messages
- Retry mechanisms for transient failures

---

## Success Criteria

### Phase 1 (Web UI) Complete When:
- [ ] Users can register and login
- [ ] Users can manage locations
- [ ] Users can manage extinguishers
- [ ] Users can scan barcodes
- [ ] Users can complete inspections (full workflow)
- [ ] Users can view dashboard with metrics
- [ ] Users can generate and export reports
- [ ] All features work offline
- [ ] Application is responsive (mobile-friendly)
- [ ] No critical bugs
- [ ] Application deployed to production
- [ ] User acceptance testing passed

### Phase 2 (Mobile Apps) Complete When:
- [ ] iOS app in App Store
- [ ] Android app in Google Play Store
- [ ] Native barcode scanning working
- [ ] Offline sync reliable
- [ ] Push notifications working
- [ ] 5-star user reviews
- [ ] Crash rate < 0.5%

### Phase 3 (Service Provider) Complete When:
- [ ] Service providers can register
- [ ] Providers can manage multiple tenants
- [ ] Billing and invoicing automated
- [ ] Cross-tenant dashboards working
- [ ] Inspector assignment optimized
- [ ] At least 3 service providers onboarded
- [ ] Revenue tracking accurate

---

## Questions to Answer

1. **Frontend Deployment**: Deploy to Vercel, Azure Static Web Apps, or Azure App Service?
   - **Recommendation**: Vercel (easiest) or Azure Static Web Apps (integrated)

2. **Chart Library**: Chart.js, Recharts, or ApexCharts?
   - **Recommendation**: Chart.js (well-documented, Vue integration)

3. **UI Component Library**: Build custom components or use Headless UI, PrimeVue, etc.?
   - **Recommendation**: Headless UI (accessible, unstyled) + Tailwind

4. **Testing Strategy**: Jest + Vue Test Utils for unit tests? Playwright/Cypress for E2E?
   - **Recommendation**: Vitest + Vue Test Utils (unit), Playwright (E2E)

5. **Mobile App Priority**: iOS first, Android first, or parallel development?
   - **Recommendation**: Parallel development if resources allow, or iOS first (higher revenue)

6. **Service Provider Phase**: Build now or wait for more users?
   - **Recommendation**: Wait until Phase 1 & 2 complete and validated with real users

---

## Risk Mitigation

### Technical Risks
- **Risk**: Offline sync conflicts
  - **Mitigation**: Last-write-wins strategy with timestamps, conflict UI

- **Risk**: Barcode scanning not working in all browsers
  - **Mitigation**: Use HTML5-QRCode library (well-tested), manual entry fallback

- **Risk**: Large photo uploads fail
  - **Mitigation**: Client-side compression, chunked uploads, retry logic

### Product Risks
- **Risk**: Users don't adopt mobile apps
  - **Mitigation**: Ensure web app works well on mobile browsers, progressive enhancement

- **Risk**: Service provider feature too complex
  - **Mitigation**: Start with MVP, iterate based on customer feedback

---

## Next Actions

### Immediate (Today)
1. Review this plan with stakeholders
2. Prioritize which features to build first
3. Start building authentication UI components

### This Week
1. Complete authentication UI
2. Build location management UI
3. Build extinguisher management UI
4. Start inspection workflow

### Next Week
1. Complete inspection workflow
2. Build dashboard
3. Build reporting UI
4. Test and polish

### This Month
1. Complete web application UI
2. Deploy to production
3. User acceptance testing
4. Fix bugs and iterate

---

**Document Owner**: Development Team
**Last Updated**: October 10, 2025
**Next Review**: Weekly during active development
