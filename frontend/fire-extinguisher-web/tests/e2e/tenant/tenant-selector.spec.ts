import { test, expect } from '@playwright/test'

test.describe('Tenant Selector (Single Tenant User)', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to login
    await page.goto('/login', { waitUntil: 'networkidle' })
  })

  test('should redirect directly to dashboard for single-tenant user', async ({ page }) => {
    // Login as chris@servicevision.net (has only one tenant)
    await page.getByTestId('email-input').fill('chris@servicevision.net')
    await page.getByTestId('password-input').fill('Gv51076')
    await page.getByTestId('login-submit-button').click()

    // Should go directly to dashboard (auto-selected tenant)
    await page.waitForURL(/\/dashboard/, { timeout: 10000 })

    // Verify dashboard loaded
    await expect(page.getByTestId('dashboard-heading')).toBeVisible()
  })

  test('should display tenant name in header', async ({ page }) => {
    // Login
    await page.getByTestId('email-input').fill('chris@servicevision.net')
    await page.getByTestId('password-input').fill('Gv51076')
    await page.getByTestId('login-submit-button').click()

    // Wait for dashboard
    await page.waitForURL(/\/dashboard/, { timeout: 10000 })

    // Verify tenant display in header
    const tenantDisplay = page.getByTestId('header-tenant-display')
    await expect(tenantDisplay).toBeVisible()
    await expect(tenantDisplay).toContainText(/Organization/i)
  })

  test('should persist tenant selection across page navigation', async ({ page }) => {
    // Login
    await page.getByTestId('email-input').fill('chris@servicevision.net')
    await page.getByTestId('password-input').fill('Gv51076')
    await page.getByTestId('login-submit-button').click()

    // Wait for dashboard
    await page.waitForURL(/\/dashboard/, { timeout: 10000 })

    // Navigate to different pages
    await page.getByTestId('sidebar-nav-locations').first().click()
    await page.waitForURL(/\/locations/)

    // Tenant should still be selected (visible in header)
    const tenantDisplay = page.getByTestId('header-tenant-display')
    await expect(tenantDisplay).toBeVisible()

    // Navigate to extinguishers
    await page.getByTestId('sidebar-nav-extinguishers').first().click()
    await page.waitForURL(/\/extinguishers/)

    // Tenant should still be selected
    await expect(tenantDisplay).toBeVisible()
  })
})

test.describe('Tenant Context Data Isolation', () => {
  test('should load correct data for selected tenant', async ({ page }) => {
    // Login
    await page.goto('/login', { waitUntil: 'networkidle' })
    await page.getByTestId('email-input').fill('chris@servicevision.net')
    await page.getByTestId('password-input').fill('Gv51076')
    await page.getByTestId('login-submit-button').click()

    // Wait for dashboard
    await page.waitForURL(/\/dashboard/, { timeout: 10000 })

    // Verify data displays (counts should be >= 0 for test tenant)
    const statsCards = page.getByTestId('dashboard-stats-cards')
    await expect(statsCards).toBeVisible()

    // Dashboard should have location and extinguisher stats
    await expect(page.locator('text=/Locations|Extinguishers/i').first()).toBeVisible()
  })

  test('should display tenant-specific data in locations view', async ({ page }) => {
    // Login
    await page.goto('/login', { waitUntil: 'networkidle' })
    await page.getByTestId('email-input').fill('chris@servicevision.net')
    await page.getByTestId('password-input').fill('Gv51076')
    await page.getByTestId('login-submit-button').click()

    // Navigate to locations
    await page.waitForURL(/\/dashboard/, { timeout: 10000 })
    await page.getByTestId('sidebar-nav-locations').first().click()
    await page.waitForURL(/\/locations/)

    // Verify page loaded
    await expect(page.getByTestId('locations-heading')).toBeVisible()

    // Locations should be visible or empty state should show
    const hasLocations = await page.getByTestId('locations-table').isVisible().catch(() => false)
    const hasEmptyState = await page.getByTestId('locations-empty-state').isVisible().catch(() => false)

    expect(hasLocations || hasEmptyState).toBeTruthy()
  })
})

test.describe('Tenant Switching (User Menu)', () => {
  test('should show switch tenant option for SystemAdmin', async ({ page }) => {
    // Login as SystemAdmin
    await page.goto('/login', { waitUntil: 'networkidle' })
    await page.getByTestId('email-input').fill('chris@servicevision.net')
    await page.getByTestId('password-input').fill('Gv51076')
    await page.getByTestId('login-submit-button').click()

    // Wait for dashboard
    await page.waitForURL(/\/dashboard/, { timeout: 10000 })

    // Open user menu
    await page.getByTestId('header-user-menu-button').click()

    // Wait for dropdown to appear
    await expect(page.getByTestId('header-user-menu-dropdown')).toBeVisible()

    // Check if "Switch Tenant" button exists
    // It should be visible for SystemAdmin or multi-tenant users
    const switchTenantButton = page.getByTestId('header-user-menu-switch-tenant')
    const isVisible = await switchTenantButton.isVisible().catch(() => false)

    // chris@servicevision.net is SystemAdmin, so should have switch tenant option
    expect(isVisible).toBeTruthy()
  })

  test('should navigate to tenant selector when switch tenant is clicked', async ({ page }) => {
    // Login
    await page.goto('/login', { waitUntil: 'networkidle' })
    await page.getByTestId('email-input').fill('chris@servicevision.net')
    await page.getByTestId('password-input').fill('Gv51076')
    await page.getByTestId('login-submit-button').click()

    // Wait for dashboard
    await page.waitForURL(/\/dashboard/, { timeout: 10000 })

    // Open user menu
    await page.getByTestId('header-user-menu-button').click()
    await expect(page.getByTestId('header-user-menu-dropdown')).toBeVisible()

    // Click "Switch Tenant"
    const switchTenantButton = page.getByTestId('header-user-menu-switch-tenant')
    if (await switchTenantButton.isVisible()) {
      await switchTenantButton.click()

      // Should navigate to tenant selection page
      await page.waitForURL(/\/select-tenant/, { timeout: 5000 })

      // Verify tenant selector page loaded
      await expect(page.locator('text=/Select Organization/i').first()).toBeVisible()
    }
  })
})

test.describe('Tenant Selector View', () => {
  test('should display tenant list on selector page', async ({ page }) => {
    // Navigate directly to tenant selector (after login)
    await page.goto('/login', { waitUntil: 'networkidle' })
    await page.getByTestId('email-input').fill('chris@servicevision.net')
    await page.getByTestId('password-input').fill('Gv51076')
    await page.getByTestId('login-submit-button').click()

    // Clear current tenant to force selection
    await page.evaluate(() => {
      localStorage.removeItem('currentTenantId')
    })

    // Navigate to select-tenant page
    await page.goto('/select-tenant')

    // Tenant list should be visible
    const tenantList = page.getByTestId('tenant-list')
    await expect(tenantList).toBeVisible({ timeout: 10000 })

    // At least one tenant card should be visible
    const tenantCards = page.getByTestId('tenant-card')
    expect(await tenantCards.count()).toBeGreaterThan(0)
  })

  test('should allow selecting a tenant from the list', async ({ page }) => {
    // Login and go to tenant selector
    await page.goto('/login', { waitUntil: 'networkidle' })
    await page.getByTestId('email-input').fill('chris@servicevision.net')
    await page.getByTestId('password-input').fill('Gv51076')
    await page.getByTestId('login-submit-button').click()

    // Clear tenant selection
    await page.evaluate(() => {
      localStorage.removeItem('currentTenantId')
    })

    // Go to selector page
    await page.goto('/select-tenant')

    // Wait for tenant list
    await expect(page.getByTestId('tenant-list')).toBeVisible({ timeout: 10000 })

    // Click on first tenant card
    const firstTenant = page.getByTestId('tenant-card').first()
    await firstTenant.click()

    // Continue button should be visible
    const continueButton = page.getByTestId('continue-button')
    await expect(continueButton).toBeVisible()
    await expect(continueButton).toBeEnabled()

    // Click continue
    await continueButton.click()

    // Should redirect to dashboard
    await page.waitForURL(/\/dashboard/, { timeout: 10000 })
    await expect(page.getByTestId('dashboard-heading')).toBeVisible()
  })
})
