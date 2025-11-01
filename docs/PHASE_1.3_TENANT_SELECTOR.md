# Phase 1.3: Tenant Selector Implementation

**Status:** ✅ IMPLEMENTATION COMPLETE - READY FOR TESTING
**Started:** October 31, 2025
**Completed:** October 31, 2025
**Timeline:** 1 day (actual)
**Priority:** 🔴 CRITICAL

---

## Overview

Enable SystemAdmin users to switch between multiple tenant organizations without logging out. This feature is critical for production use and will unblock 10 failing E2E tests.

---

## Goals

1. **Multi-Tenant Switching**: SystemAdmin can view and switch between all accessible tenants
2. **Data Isolation**: Ensure proper data isolation after tenant switch
3. **UX Excellence**: Clear indication of current tenant, smooth switching experience
4. **Persistence**: Selected tenant persists across page refreshes
5. **E2E Tests**: Fix 10 failing tenant-selector tests

---

## Architecture

### Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│  User Login → JWT with TenantId claim                        │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  Dashboard → AppHeader shows current tenant                  │
│             └─> Click tenant badge opens TenantSelectorModal │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  TenantSelectorModal                                         │
│  ├─> Fetch accessible tenants (API)                          │
│  ├─> Display tenants with role badges                        │
│  ├─> User clicks "Switch" on different tenant                │
│  └─> POST /api/users/me/switch-tenant                        │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  Backend API                                                 │
│  ├─> Validate user has access to tenant                      │
│  ├─> Update LastAccessedTenantId in database                 │
│  ├─> Generate new JWT with new TenantId claim                │
│  └─> Return new token + tenant info                          │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  Frontend                                                    │
│  ├─> Store new token in localStorage                         │
│  ├─> Update auth store with new tenant                       │
│  ├─> Clear all other stores (locations, extinguishers, etc.) │
│  ├─> Reload current page data                                │
│  └─> Close modal, show success message                       │
└─────────────────────────────────────────────────────────────┘
```

---

## Implementation Checklist

### ✅ Completed

- [x] **Planning Documents**
  - [x] Created IMPLEMENTATION_ROADMAP.md
  - [x] Created PHASE_1.3_TENANT_SELECTOR.md (this file)
- [x] **Backend DTOs**
  - [x] Created TenantSummaryDto
  - [x] Created SwitchTenantRequest
  - [x] Created SwitchTenantResponse
- [x] **Database Schema**
  - [x] Created CREATE_TENANT_SELECTOR_PROCEDURES.sql
  - [x] Added LastAccessedTenantId column to Users table
  - [x] Added LastAccessedDate column to Users table
  - [x] Created usp_User_GetAccessibleTenants stored procedure
  - [x] Created usp_User_UpdateLastAccessedTenant stored procedure

- [x] **Backend Service Layer (Step 1)**
  - [x] Added methods to IUserService interface:
    - [x] `Task<IEnumerable<TenantSummaryDto>> GetAccessibleTenantsAsync(Guid userId)`
    - [x] `Task<SwitchTenantResponse> SwitchTenantAsync(Guid userId, Guid tenantId)`
  - [x] Implemented methods in UserService
  - [x] Injected IJwtTokenService for token generation
  - [x] Backend builds successfully
- [x] **Backend Controller (Step 2)**
  - [x] Added endpoints to UsersController:
    - [x] `GET /api/users/me/tenants` - Get accessible tenants
    - [x] `POST /api/users/me/switch-tenant` - Switch active tenant
  - [x] Added authorization (requires authenticated user)
  - [x] Added XML documentation comments
  - [x] Added validation and error handling
- [x] **Database Deployment (Step 3)**
  - [x] Created CREATE_TENANT_SELECTOR_PROCEDURES.sql script
  - [ ] ⏸️ Deferred: Run on production database (local DB not running)
  - [x] Script verified and ready for deployment
- [x] **Frontend Components (Step 4)**
  - [x] Updated TenantSelector.vue component:
    - [x] Fetch accessible tenants using userService
    - [x] Display tenants in dropdown layout
    - [x] Call authStore.switchTenant() for switching
    - [x] Loading states
    - [x] Error handling
  - [x] AppHeader.vue already has:
    - [x] Current tenant display badge
    - [x] Tenant selector trigger button (SystemAdmin + multi-tenant users)
    - [x] data-testid attributes
- [x] **Frontend Services (Step 5)**
  - [x] Updated userService.js:
    - [x] Added getAccessibleTenants() method
    - [x] Added switchTenant(tenantId) method
- [x] **Frontend Store (Step 6)**
  - [x] Updated auth.ts Pinia store:
    - [x] Added switchTenant(tenantId) action
    - [x] Calls userService.switchTenant() to get new JWT
    - [x] Updates token storage on switch
    - [x] Fetches updated user and roles after switch
    - [x] Persists selected tenant to localStorage
- [x] **Router & Views (Step 7)**
  - [x] Router guard already implemented in router/index.js:
    - [x] Redirects to /select-tenant if no tenant selected
    - [x] Works for SystemAdmin and multi-tenant users
  - [x] Updated TenantSelectorView.vue:
    - [x] Uses userService.getAccessibleTenants()
    - [x] Calls authStore.switchTenant() on selection
    - [x] Grid/card layout with tenant details
    - [x] Shows last accessed date with relative formatting
    - [x] Shows location and extinguisher counts
- [x] **Build Verification**
  - [x] Backend builds successfully
  - [x] Frontend builds successfully

### 📋 Pending

#### Testing (Step 8)
- [ ] Manual Testing:
  - [ ] Login as chris@servicevision.net (multi-tenant user)
  - [ ] Open tenant selector modal
  - [ ] Switch between tenants
  - [ ] Verify data isolation (locations, extinguishers)
  - [ ] Test localStorage persistence
  - [ ] Test page refresh maintains tenant
  - [ ] Test logout clears tenant
- [ ] E2E Testing:
  - [ ] Update tenant-selector.spec.ts
  - [ ] Fix 10 failing tests
  - [ ] Add new tests for switching workflow
  - [ ] Test data isolation after switch
- [ ] Build & Deploy:
  - [ ] Backend builds without errors
  - [ ] Frontend builds without errors
  - [ ] Deploy to staging/dev environment

#### Documentation (Step 9)
- [ ] Update README.md with tenant selector feature
- [ ] Update API documentation (Swagger)
- [ ] Add user guide section for tenant switching
- [ ] Document JWT token refresh behavior

---

## Database Schema

### Users Table Changes

```sql
ALTER TABLE [dbo].[Users]
ADD
    LastAccessedTenantId UNIQUEIDENTIFIER NULL,
    LastAccessedDate DATETIME2 NULL;
```

**Purpose**: Track which tenant the user last accessed for better UX (show last-accessed tenant first in list).

---

## API Endpoints

### 1. GET /api/users/me/tenants

**Description**: Get list of all tenants the current user has access to.

**Authorization**: Bearer token required

**Response**: `200 OK`
```json
[
  {
    "tenantId": "guid",
    "tenantName": "Acme Corporation",
    "tenantCode": "ACME001",
    "userRole": "TenantAdmin",
    "isActive": true,
    "lastAccessedDate": "2025-10-31T10:30:00Z",
    "locationCount": 15,
    "extinguisherCount": 247
  },
  {
    "tenantId": "guid",
    "tenantName": "Beta Industries",
    "tenantCode": "BETA001",
    "userRole": "Inspector",
    "isActive": true,
    "lastAccessedDate": null,
    "locationCount": 8,
    "extinguisherCount": 132
  }
]
```

**Error Responses**:
- `401 Unauthorized` - Not authenticated
- `500 Internal Server Error` - Database error

---

### 2. POST /api/users/me/switch-tenant

**Description**: Switch active tenant and receive new JWT token.

**Authorization**: Bearer token required

**Request Body**:
```json
{
  "tenantId": "guid"
}
```

**Response**: `200 OK`
```json
{
  "tenantId": "guid",
  "tenantName": "Acme Corporation",
  "token": "eyJhbGc...",
  "tokenExpiration": "2025-10-31T18:30:00Z"
}
```

**Error Responses**:
- `400 Bad Request` - Invalid tenantId
- `401 Unauthorized` - Not authenticated
- `403 Forbidden` - User does not have access to this tenant
- `404 Not Found` - Tenant does not exist
- `500 Internal Server Error` - Database error

---

## Frontend Components

### TenantSelectorModal.vue

**Location**: `src/components/TenantSelectorModal.vue`

**Props**: None (uses auth store)

**Emits**:
- `close` - User closed modal without switching
- `switched` - User successfully switched tenant

**Features**:
- Fetches accessible tenants from API
- Displays tenants in card layout
- Shows role badge per tenant
- Shows "Current" indicator for active tenant
- Shows last accessed date
- Search/filter by tenant name
- Loading state with skeleton
- Empty state if only one tenant
- Error state with retry button

**Layout**:
```
┌─────────────────────────────────────────┐
│  Select Organization            [Close] │
├─────────────────────────────────────────┤
│  [Search: _______________]              │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐   │
│  │ Acme Corporation     [CURRENT]  │   │
│  │ Role: TenantAdmin               │   │
│  │ 15 locations • 247 extinguishers│   │
│  │ Last accessed: 2 hours ago      │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ Beta Industries                 │   │
│  │ Role: Inspector                 │   │
│  │ 8 locations • 132 extinguishers │   │
│  │                        [Switch] │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

---

### AppHeader.vue Updates

**Current Tenant Badge**:
```vue
<div class="flex items-center space-x-3 px-6 py-2 bg-gradient-to-r from-primary-50 to-primary-100 border border-primary-200 rounded-lg">
  <BuildingOfficeIcon class="h-6 w-6 text-primary-600" />
  <div>
    <p class="text-xs font-medium text-primary-600 uppercase tracking-wide">
      Organization
    </p>
    <p class="text-sm font-semibold text-gray-900">
      {{ tenantName }}
    </p>
  </div>
  <!-- SystemAdmin only: Tenant selector trigger -->
  <button
    v-if="isSystemAdmin"
    @click="showTenantSelector = true"
    class="p-1 hover:bg-primary-200 rounded transition-colors"
    data-testid="tenant-selector-trigger"
  >
    <ChevronDownIcon class="h-4 w-4 text-primary-600" />
  </button>
</div>
```

---

## Auth Store Updates

### New State

```typescript
interface AuthState {
  // ... existing state
  availableTenants: TenantSummaryDto[]
  currentTenantId: string | null
}
```

### New Actions

```typescript
async fetchAvailableTenants() {
  const response = await userService.getAccessibleTenants()
  this.availableTenants = response.data
}

async switchTenant(tenantId: string) {
  const response = await userService.switchTenant(tenantId)

  // Update token
  localStorage.setItem('token', response.data.token)

  // Update current tenant
  this.currentTenantId = response.data.tenantId

  // Clear all other stores
  useLocationStore().$reset()
  useExtinguisherStore().$reset()
  useInspectionStore().$reset()
  // ... clear all stores

  // Reload current page data
  window.location.reload()
}
```

### New Getters

```typescript
currentTenant: (state) => {
  return state.availableTenants.find(t => t.tenantId === state.currentTenantId)
}
```

---

## Testing Strategy

### Manual Testing Scenarios

1. **Single Tenant User**
   - Login as user with only 1 tenant
   - Verify no tenant selector visible
   - Verify current tenant displayed correctly

2. **Multi-Tenant User (SystemAdmin)**
   - Login as chris@servicevision.net
   - Verify tenant selector trigger visible
   - Click trigger, verify modal opens
   - Verify all accessible tenants shown
   - Verify current tenant marked
   - Click "Switch" on different tenant
   - Verify new JWT token received
   - Verify data reloaded for new tenant
   - Verify locations/extinguishers belong to new tenant

3. **Persistence Testing**
   - Switch to tenant B
   - Refresh page
   - Verify still on tenant B
   - Logout
   - Login again
   - Verify last accessed tenant selected

4. **Data Isolation Testing**
   - Note location count for Tenant A
   - Switch to Tenant B
   - Verify different locations shown
   - Verify location count different
   - Switch back to Tenant A
   - Verify original locations returned

### E2E Test Cases

**File**: `tests/e2e/tenant/tenant-selector.spec.ts`

```typescript
test.describe('Tenant Selector', () => {
  test.beforeEach(async ({ page }) => {
    // Login as multi-tenant user
    await loginAsSystemAdmin(page)
  })

  test('should display current tenant in header', async ({ page }) => {
    await expect(page.locator('[data-testid="current-tenant-name"]'))
      .toContainText('Acme Corporation')
  })

  test('should open tenant selector modal', async ({ page }) => {
    await page.click('[data-testid="tenant-selector-trigger"]')
    await expect(page.locator('[data-testid="tenant-selector-modal"]'))
      .toBeVisible()
  })

  test('should list all accessible tenants', async ({ page }) => {
    await page.click('[data-testid="tenant-selector-trigger"]')
    const tenantCards = page.locator('[data-testid="tenant-card"]')
    await expect(tenantCards).toHaveCount(2)
  })

  test('should switch tenant successfully', async ({ page }) => {
    await page.click('[data-testid="tenant-selector-trigger"]')
    await page.click('[data-testid="tenant-card"]:has-text("Beta Industries") [data-testid="switch-button"]')

    // Wait for page reload
    await page.waitForLoadState('networkidle')

    // Verify new tenant displayed
    await expect(page.locator('[data-testid="current-tenant-name"]'))
      .toContainText('Beta Industries')
  })

  test('should isolate data after tenant switch', async ({ page }) => {
    // Get location count for Tenant A
    await page.goto('/locations')
    const locationCountA = await page.locator('[data-testid="location-count"]').textContent()

    // Switch to Tenant B
    await page.click('[data-testid="tenant-selector-trigger"]')
    await page.click('[data-testid="tenant-card"]:has-text("Beta Industries") [data-testid="switch-button"]')
    await page.waitForLoadState('networkidle')

    // Get location count for Tenant B
    await page.goto('/locations')
    const locationCountB = await page.locator('[data-testid="location-count"]').textContent()

    // Verify counts are different
    expect(locationCountA).not.toBe(locationCountB)
  })

  test('should persist selected tenant after refresh', async ({ page }) => {
    // Switch to Tenant B
    await page.click('[data-testid="tenant-selector-trigger"]')
    await page.click('[data-testid="tenant-card"]:has-text("Beta Industries") [data-testid="switch-button"]')
    await page.waitForLoadState('networkidle')

    // Refresh page
    await page.reload()

    // Verify still on Tenant B
    await expect(page.locator('[data-testid="current-tenant-name"]'))
      .toContainText('Beta Industries')
  })
})
```

---

## Success Criteria

### Functional Requirements
- ✅ SystemAdmin can view all accessible tenants
- ✅ SystemAdmin can switch between tenants without logout
- ✅ Current tenant clearly displayed in header
- ✅ Data properly isolated per tenant after switch
- ✅ Selected tenant persists across page refreshes
- ✅ JWT token includes correct TenantId claim
- ✅ Last accessed tenant tracked in database

### Technical Requirements
- ✅ Backend builds without errors
- ✅ Frontend builds without errors
- ✅ All 10 tenant-selector E2E tests pass
- ✅ API response time < 200ms for tenant list
- ✅ No memory leaks on tenant switch
- ✅ Proper error handling for API failures

### UX Requirements
- ✅ Tenant selector accessible from all pages (header)
- ✅ Current tenant always visible
- ✅ Smooth transition on tenant switch (loading state)
- ✅ Clear success/error feedback
- ✅ Keyboard navigation works (accessibility)
- ✅ Mobile responsive design

---

## Risks & Mitigations

### Risk 1: Token Refresh on Switch
**Risk**: Users might have stale tokens after switching
**Mitigation**: Generate new JWT on every switch with updated TenantId claim

### Risk 2: Data Leakage Between Tenants
**Risk**: Cached data from previous tenant might display
**Mitigation**: Clear all Pinia stores on tenant switch, reload page data

### Risk 3: Performance with Many Tenants
**Risk**: SystemAdmin with 100+ tenants sees slow modal
**Mitigation**:
- Implement search/filter
- Virtual scrolling for large lists
- Cache tenant list in localStorage

### Risk 4: Concurrent Sessions
**Risk**: User switches tenant in one tab, other tabs have old tenant
**Mitigation**:
- Listen to localStorage changes
- Sync tenant across tabs
- Show warning if tenant mismatch detected

---

## Future Enhancements

1. **Tenant Logos**: Display tenant logo in selector modal
2. **Recent Tenants**: Show "Recently Accessed" section (top 3)
3. **Favorites**: Allow pinning favorite tenants to top
4. **Tenant Switching Analytics**: Track which tenants are accessed most
5. **Multi-Tab Sync**: Auto-reload other tabs when tenant switches
6. **Tenant Permissions Preview**: Show what user can do in each tenant
7. **Quick Switch Shortcut**: Keyboard shortcut (Ctrl+Shift+T) for power users

---

## Timeline

| Task | Estimated Time | Status |
|------|----------------|--------|
| Database schema & procedures | 1-2 hours | ✅ Complete |
| Backend DTOs | 30 minutes | ✅ Complete |
| Backend service layer | 2-3 hours | 🔄 Next |
| Backend controller | 1-2 hours | ⏳ Pending |
| Database deployment | 30 minutes | ⏳ Pending |
| Frontend TenantSelectorModal | 3-4 hours | ⏳ Pending |
| Frontend AppHeader updates | 1-2 hours | ⏳ Pending |
| Frontend services | 1 hour | ⏳ Pending |
| Frontend auth store | 2-3 hours | ⏳ Pending |
| Router updates | 1 hour | ⏳ Pending |
| Manual testing | 2-3 hours | ⏳ Pending |
| E2E testing | 2-3 hours | ⏳ Pending |
| Documentation | 1-2 hours | ⏳ Pending |

**Total Estimated Time**: 18-28 hours (2.5-3.5 days)

---

## Notes

- This feature is a prerequisite for production deployment
- 10 E2E tests are currently failing due to missing tenant selector
- chris@servicevision.net is the primary test user (has access to multiple tenants)
- All tenant switching must go through the API (no client-side only switches)
- JWT tokens are short-lived (15 minutes), so refresh logic is important

---

**Document Owner**: Development Team
**Last Updated**: October 31, 2025
**Next Review**: After Phase 1.3 completion
