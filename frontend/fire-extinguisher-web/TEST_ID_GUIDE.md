# Test ID Naming Conventions & E2E Testing Guide

## Test ID Naming Convention

### General Rules
- Use **kebab-case** for all test IDs
- Be **descriptive** and **specific**
- Follow pattern: `{component}-{element}-{action?}`
- Avoid implementation details (class names, IDs)

### Common Patterns

#### Navigation & Layout
```
header-logo
header-menu-toggle
header-notifications-button
header-user-menu-button
header-user-menu-dropdown
sidebar-nav-{page}
sidebar-collapse-button
```

#### Authentication
```
login-email-input
login-password-input
login-submit-button
login-error-message
register-firstname-input
register-submit-button
logout-button
```

#### Forms
```
{entity}-form
{entity}-{field}-input
{entity}-{field}-select
{entity}-{field}-error
{entity}-submit-button
{entity}-cancel-button
```

#### Lists & Tables
```
{entity}-list
{entity}-table
{entity}-table-row
{entity}-table-header
{entity}-empty-state
{entity}-loading-state
```

#### Actions
```
{entity}-create-button
{entity}-edit-button
{entity}-delete-button
{entity}-view-button
{entity}-save-button
```

#### Status & Feedback
```
{entity}-success-message
{entity}-error-message
{entity}-loading-spinner
{entity}-confirmation-dialog
```

### Component-Specific Examples

#### AppHeader
- `header-logo` - Main logo/brand link
- `header-menu-toggle` - Mobile menu button
- `header-tenant-display` - Current tenant/organization display
- `header-notifications-button` - Notifications bell icon
- `header-user-menu-button` - User avatar/dropdown trigger
- `header-user-menu-dropdown` - User menu dropdown container
- `header-user-menu-profile` - Profile link in dropdown
- `header-user-menu-settings` - Settings link in dropdown
- `header-user-menu-logout` - Logout button in dropdown

#### AppSidebar
- `sidebar-nav-dashboard` - Dashboard link
- `sidebar-nav-locations` - Locations link
- `sidebar-nav-extinguishers` - Extinguishers link
- `sidebar-nav-inspections` - Inspections link
- `sidebar-nav-reports` - Reports link
- `sidebar-nav-users` - Users link (admin)
- `sidebar-collapse-button` - Collapse/expand sidebar button

#### LoginView
- `login-heading` - Page heading
- `login-email-input` - Email input field
- `login-password-input` - Password input field
- `login-remember-checkbox` - Remember me checkbox
- `login-submit-button` - Login button
- `login-forgot-link` - Forgot password link
- `login-register-link` - Register link
- `login-error-message` - Error alert/message

#### DashboardView
- `dashboard-heading` - Page heading
- `dashboard-stats-cards` - Stats cards container
- `dashboard-stat-card-{metric}` - Individual stat card
- `dashboard-recent-inspections` - Recent inspections section
- `dashboard-upcoming-inspections` - Upcoming inspections section

#### LocationsView
- `locations-heading` - Page heading
- `locations-create-button` - Create new location button
- `locations-search-input` - Search input field
- `locations-filter-select` - Filter dropdown
- `locations-table` - Locations table
- `locations-table-row` - Table row (use with :data-location-id)
- `locations-empty-state` - Empty state message
- `location-edit-button` - Edit button for specific location
- `location-delete-button` - Delete button for specific location

#### TenantSelector (Already Implemented)
- `tenant-selector-banner` - Main banner container
- `tenant-selector-title` - Banner title
- `tenant-selector-description` - Banner description
- `tenant-selector-dropdown` - Dropdown container
- `tenant-selector-select` - Select element
- `tenant-selector-placeholder` - Placeholder option
- `tenant-option-{tenantId}` - Individual tenant option
- `tenant-selector-apply-button` - Apply button
- `tenant-selector-error` - Error message

## E2E Test Structure

### Directory Structure
```
tests/
├── e2e/
│   ├── auth/
│   │   ├── login.spec.ts
│   │   ├── register.spec.ts
│   │   └── logout.spec.ts
│   ├── tenant/
│   │   ├── tenant-selector.spec.ts
│   │   └── tenant-switching.spec.ts
│   ├── locations/
│   │   ├── locations-crud.spec.ts
│   │   └── locations-search.spec.ts
│   ├── extinguishers/
│   │   ├── extinguishers-crud.spec.ts
│   │   └── extinguishers-search.spec.ts
│   ├── inspections/
│   │   ├── inspections-create.spec.ts
│   │   └── inspections-view.spec.ts
│   └── fixtures/
│       ├── users.ts
│       ├── locations.ts
│       └── extinguishers.ts
└── playwright.config.ts
```

### Test File Template

```typescript
import { test, expect } from '@playwright/test'

test.describe('Feature Name', () => {
  test.beforeEach(async ({ page }) => {
    // Setup: Navigate to starting page, login if needed
    await page.goto('/login')
    await page.getByTestId('login-email-input').fill('user@example.com')
    await page.getByTestId('login-password-input').fill('password')
    await page.getByTestId('login-submit-button').click()
    await page.waitForURL('/dashboard')
  })

  test('should do something specific', async ({ page }) => {
    // Arrange: Navigate and setup
    await page.getByTestId('sidebar-nav-locations').click()
    await page.waitForURL('/locations')

    // Act: Perform action
    await page.getByTestId('locations-create-button').click()
    await page.getByTestId('location-name-input').fill('Test Location')
    await page.getByTestId('location-code-input').fill('LOC001')
    await page.getByTestId('location-submit-button').click()

    // Assert: Verify results
    await expect(page.getByTestId('location-success-message')).toBeVisible()
    await expect(page.getByText('Test Location')).toBeVisible()
  })

  test('should handle errors gracefully', async ({ page }) => {
    // Test error scenarios
    await page.getByTestId('locations-create-button').click()
    await page.getByTestId('location-submit-button').click()

    await expect(page.getByTestId('location-name-error')).toBeVisible()
    await expect(page.getByTestId('location-name-error')).toContainText('required')
  })
})
```

### Page Object Pattern (Optional but Recommended)

```typescript
// pages/LoginPage.ts
export class LoginPage {
  constructor(private page: Page) {}

  async goto() {
    await this.page.goto('/login')
  }

  async login(email: string, password: string) {
    await this.page.getByTestId('login-email-input').fill(email)
    await this.page.getByTestId('login-password-input').fill(password)
    await this.page.getByTestId('login-submit-button').click()
  }

  async expectLoginError(message: string) {
    await expect(this.page.getByTestId('login-error-message')).toContainText(message)
  }
}

// Usage in test:
const loginPage = new LoginPage(page)
await loginPage.goto()
await loginPage.login('user@example.com', 'password123')
```

## Priority Components for Test IDs

### Phase 1: Critical Path (Must Have)
1. ✅ TenantSelector.vue - Already complete
2. ⏳ AppHeader.vue - Navigation and user menu
3. ⏳ AppSidebar.vue - Main navigation
4. ⏳ LoginView.vue - Authentication
5. ⏳ DashboardView.vue - Landing page

### Phase 2: Core Features (Should Have)
6. ⏳ LocationsView.vue - CRUD operations
7. ⏳ ExtinguishersView.vue - CRUD operations
8. ⏳ InspectionsView.vue - View/list
9. ⏳ RegisterView.vue - User registration

### Phase 3: Additional Features (Nice to Have)
10. ⏳ ProfileView.vue - User profile
11. ⏳ SettingsView.vue - Settings
12. ⏳ ReportsView.vue - Reporting
13. ⏳ UsersView.vue - User management (admin)

## Test Scenarios

### Authentication Tests
- [x] Login with valid credentials
- [x] Login with invalid credentials
- [x] Logout
- [x] Remember me functionality
- [x] Password reset flow

### Tenant Selector Tests (SystemAdmin)
- [x] Banner appears for SystemAdmin
- [x] Banner does not appear for regular users
- [x] Select tenant from dropdown
- [x] Apply tenant selection
- [x] Tenant persists across page reload
- [x] Tenant persists across navigation

### CRUD Tests (Locations Example)
- [x] View list of locations
- [x] Search locations
- [x] Filter locations
- [x] Create new location
- [x] Edit existing location
- [x] Delete location
- [x] Validation errors display correctly

### Navigation Tests
- [x] Navigate between pages using sidebar
- [x] Breadcrumbs update correctly
- [x] Back button works
- [x] Direct URL navigation works

## Best Practices

1. **Selector Specificity**: Use test-ids for interactive elements and assertions
2. **Avoid Hard-Coding**: Use data attributes for dynamic content (`:data-location-id="location.id"`)
3. **Wait Strategies**: Use `waitForSelector`, `waitForURL`, `waitForResponse`
4. **Isolation**: Each test should be independent
5. **Cleanup**: Use `beforeEach` and `afterEach` for setup/teardown
6. **Assertions**: Be specific about what you're testing
7. **Error Messages**: Test both success and error states

## Running Tests

```bash
# Run all E2E tests
npm run test:e2e

# Run specific test file
npm run test:e2e -- tests/e2e/auth/login.spec.ts

# Run tests in headed mode (see browser)
npm run test:e2e -- --headed

# Run tests in debug mode
npm run test:e2e -- --debug

# Generate test report
npm run test:e2e -- --reporter=html
```

## Continuous Integration

Add to GitHub Actions workflow:
```yaml
- name: Run E2E tests
  run: npm run test:e2e
  env:
    VITE_API_BASE_URL: ${{ secrets.STAGING_API_BASE_URL }}
```
