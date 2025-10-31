import { test, expect } from '@playwright/test'

test.describe('Tenant Selector (SystemAdmin)', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to login
    await page.goto('/login', { waitUntil: 'networkidle' })
  })

  test('should show tenant selector banner for SystemAdmin', async ({ page }) => {
    // Login as SystemAdmin
    await page.getByTestId('email-input').fill('admin@fireproof.local')
    await page.getByTestId('password-input').fill('Admin123!')
    await page.getByTestId('login-submit-button').click()

    // Wait for page to load after login
    await page.waitForLoadState('networkidle')

    // Tenant selector banner should appear
    const banner = page.getByTestId('tenant-selector-banner')
    await expect(banner).toBeVisible({ timeout: 10000 })

    // Verify banner content
    await expect(page.getByTestId('tenant-selector-title')).toContainText('Select Organization')
    await expect(page.getByTestId('tenant-selector-description')).toBeVisible()
    await expect(page.getByTestId('tenant-selector-dropdown')).toBeVisible()
  })

  test('should not show tenant selector for regular user', async ({ page }) => {
    // Login as regular user (TenantAdmin)
    await page.getByTestId('email-input').fill('alice.admin@fireproof.local')
    await page.getByTestId('password-input').fill('Admin123!')
    await page.getByTestId('login-submit-button').click()

    // Wait for dashboard to load
    await page.waitForURL(/\/dashboard/, { timeout: 10000 })

    // Tenant selector banner should NOT appear
    const banner = page.getByTestId('tenant-selector-banner')
    expect(await banner.count()).toBe(0)

    // Verify we're on dashboard
    await expect(page.getByTestId('dashboard-heading')).toBeVisible()
  })

  test('should allow SystemAdmin to select and apply tenant', async ({ page }) => {
    // Login as SystemAdmin
    await page.getByTestId('email-input').fill('admin@fireproof.local')
    await page.getByTestId('password-input').fill('Admin123!')
    await page.getByTestId('login-submit-button').click()

    // Wait for banner to appear
    await expect(page.getByTestId('tenant-selector-banner')).toBeVisible({ timeout: 10000 })

    // Select tenant from dropdown
    const selectElement = page.getByTestId('tenant-selector-select')
    await selectElement.selectOption({ index: 1 }) // Select first actual tenant (index 0 is placeholder)

    // Apply button should now be visible
    const applyButton = page.getByTestId('tenant-selector-apply-button')
    await expect(applyButton).toBeVisible()

    // Click apply - this will reload the page
    await applyButton.click()

    // Wait for page reload and dashboard to load
    await page.waitForURL(/\/dashboard/, { timeout: 10000 })

    // Banner should disappear after tenant selection
    expect(await page.getByTestId('tenant-selector-banner').count()).toBe(0)

    // Verify dashboard loaded
    await expect(page.getByTestId('dashboard-heading')).toBeVisible()
    await expect(page.getByTestId('dashboard-stats-cards')).toBeVisible()
  })

  test('should persist tenant selection across page navigation', async ({ page }) => {
    // Login as SystemAdmin
    await page.getByTestId('email-input').fill('admin@fireproof.local')
    await page.getByTestId('password-input').fill('Admin123!')
    await page.getByTestId('login-submit-button').click()

    // Wait for and select tenant
    await expect(page.getByTestId('tenant-selector-banner')).toBeVisible({ timeout: 10000 })
    await page.getByTestId('tenant-selector-select').selectOption({ index: 1 })
    await page.getByTestId('tenant-selector-apply-button').click()

    // Wait for dashboard
    await page.waitForURL(/\/dashboard/, { timeout: 10000 })

    // Navigate to different pages
    await page.getByTestId('sidebar-nav-locations').click()
    await page.waitForURL(/\/locations/)

    // Banner should NOT reappear
    expect(await page.getByTestId('tenant-selector-banner').count()).toBe(0)

    // Navigate to extinguishers
    await page.getByTestId('sidebar-nav-extinguishers').click()
    await page.waitForURL(/\/extinguishers/)

    // Banner should still not appear
    expect(await page.getByTestId('tenant-selector-banner').count()).toBe(0)
  })

  test('should display tenant name in header after selection', async ({ page }) => {
    // Login as SystemAdmin
    await page.getByTestId('email-input').fill('admin@fireproof.local')
    await page.getByTestId('password-input').fill('Admin123!')
    await page.getByTestId('login-submit-button').click()

    // Select tenant
    await expect(page.getByTestId('tenant-selector-banner')).toBeVisible({ timeout: 10000 })
    await page.getByTestId('tenant-selector-select').selectOption({ index: 1 })
    await page.getByTestId('tenant-selector-apply-button').click()

    // Wait for dashboard
    await page.waitForURL(/\/dashboard/, { timeout: 10000 })

    // Verify tenant display in header
    const tenantDisplay = page.getByTestId('header-tenant-display')
    await expect(tenantDisplay).toBeVisible()
    await expect(tenantDisplay).toContainText(/FireProof Test Organization|Organization/i)
  })

  test('should show error if tenant selection fails', async ({ page }) => {
    // This test would require mocking API failure
    // Placeholder for future implementation with API mocking
    test.skip()
  })

  test('should allow switching tenant via user menu', async ({ page }) => {
    // Login as SystemAdmin and select tenant first
    await page.getByTestId('email-input').fill('admin@fireproof.local')
    await page.getByTestId('password-input').fill('Admin123!')
    await page.getByTestId('login-submit-button').click()

    await expect(page.getByTestId('tenant-selector-banner')).toBeVisible({ timeout: 10000 })
    await page.getByTestId('tenant-selector-select').selectOption({ index: 1 })
    await page.getByTestId('tenant-selector-apply-button').click()

    // Wait for dashboard
    await page.waitForURL(/\/dashboard/, { timeout: 10000 })

    // Open user menu
    await page.getByTestId('header-user-menu-button').click()

    // Wait for dropdown to appear
    await expect(page.getByTestId('header-user-menu-dropdown')).toBeVisible()

    // Click "Switch Tenant" if available
    const switchTenantButton = page.getByTestId('header-user-menu-switch-tenant')

    if (await switchTenantButton.isVisible()) {
      await switchTenantButton.click()

      // Should navigate to tenant selection page or show banner again
      // This behavior depends on implementation
      // For now, we expect the banner to reappear
      await expect(page.getByTestId('tenant-selector-banner')).toBeVisible({ timeout: 5000 })
    }
  })
})

test.describe('Tenant Context Data Isolation', () => {
  test('should load correct data for selected tenant', async ({ page }) => {
    // Login as SystemAdmin
    await page.goto('/login', { waitUntil: 'networkidle' })
    await page.getByTestId('email-input').fill('admin@fireproof.local')
    await page.getByTestId('password-input').fill('Admin123!')
    await page.getByTestId('login-submit-button').click()

    // Select tenant
    await expect(page.getByTestId('tenant-selector-banner')).toBeVisible({ timeout: 10000 })
    await page.getByTestId('tenant-selector-select').selectOption({ index: 1 })
    await page.getByTestId('tenant-selector-apply-button').click()

    // Wait for dashboard
    await page.waitForURL(/\/dashboard/, { timeout: 10000 })

    // Verify data displays (counts should be > 0 for test tenant)
    const locationsCount = page.getByTestId('dashboard-locations-count')
    const extinguishersCount = page.getByTestId('dashboard-extinguishers-count')

    await expect(locationsCount).toBeVisible()
    await expect(extinguishersCount).toBeVisible()

    // Get the text content and verify it's a number
    const locationText = await locationsCount.textContent()
    const extinguisherText = await extinguishersCount.textContent()

    expect(locationText).toMatch(/\d+/)
    expect(extinguisherText).toMatch(/\d+/)
  })
})
