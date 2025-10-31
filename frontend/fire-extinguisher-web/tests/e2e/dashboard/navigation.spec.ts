import { test, expect } from '@playwright/test'

test.describe('Navigation and Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    // Login as regular user before each test (using dev login)
    await page.goto('/login', { waitUntil: 'networkidle' })
    await page.getByTestId('email-input').fill('alice.admin@fireproof.local')
    await page.getByTestId('dev-login-button').click()

    // Wait for dashboard to load
    await page.waitForURL(/\/dashboard/, { timeout: 10000 })
  })

  test('should display dashboard with correct elements', async ({ page }) => {
    // Verify dashboard heading
    await expect(page.getByTestId('dashboard-heading')).toBeVisible()
    await expect(page.getByTestId('dashboard-heading')).toContainText('Welcome back')

    // Verify stats cards
    await expect(page.getByTestId('dashboard-stats-cards')).toBeVisible()
    await expect(page.getByTestId('dashboard-stat-card-locations')).toBeVisible()
    await expect(page.getByTestId('dashboard-stat-card-extinguishers')).toBeVisible()
    await expect(page.getByTestId('dashboard-stat-card-inspections')).toBeVisible()
    await expect(page.getByTestId('dashboard-stat-card-compliance')).toBeVisible()

    // Verify quick actions
    await expect(page.getByTestId('dashboard-quick-actions-heading')).toBeVisible()
    await expect(page.getByTestId('dashboard-action-add-location')).toBeVisible()
    await expect(page.getByTestId('dashboard-action-add-extinguisher')).toBeVisible()
    await expect(page.getByTestId('dashboard-action-start-inspection')).toBeVisible()
    await expect(page.getByTestId('dashboard-action-generate-report')).toBeVisible()
  })

  test('should navigate between pages using sidebar', async ({ page }) => {
    // Navigate to Locations
    await page.getByTestId('sidebar-nav-locations').click()
    await expect(page).toHaveURL(/\/locations/)

    // Navigate to Extinguishers
    await page.getByTestId('sidebar-nav-extinguishers').click()
    await expect(page).toHaveURL(/\/extinguishers/)

    // Navigate to Inspections
    await page.getByTestId('sidebar-nav-inspections').click()
    await expect(page).toHaveURL(/\/inspections/)

    // Navigate to Reports
    await page.getByTestId('sidebar-nav-reports').click()
    await expect(page).toHaveURL(/\/reports/)

    // Navigate back to Dashboard
    await page.getByTestId('sidebar-nav-dashboard').click()
    await expect(page).toHaveURL(/\/dashboard/)
    await expect(page.getByTestId('dashboard-heading')).toBeVisible()
  })

  test('should navigate using header logo', async ({ page }) => {
    // Navigate away from dashboard
    await page.getByTestId('sidebar-nav-locations').click()
    await expect(page).toHaveURL(/\/locations/)

    // Click logo to return to dashboard
    await page.getByTestId('header-logo').click()
    await expect(page).toHaveURL(/\/dashboard/)
    await expect(page.getByTestId('dashboard-heading')).toBeVisible()
  })

  test('should open and close user menu', async ({ page }) => {
    // Click user menu button
    await page.getByTestId('header-user-menu-button').click()

    // Dropdown should be visible
    await expect(page.getByTestId('header-user-menu-dropdown')).toBeVisible()

    // Verify menu items
    await expect(page.getByTestId('header-user-menu-profile')).toBeVisible()
    await expect(page.getByTestId('header-user-menu-settings')).toBeVisible()
    await expect(page.getByTestId('header-user-menu-help')).toBeVisible()
    await expect(page.getByTestId('header-user-menu-logout')).toBeVisible()

    // Click outside to close (click on dashboard heading)
    await page.getByTestId('dashboard-heading').click()

    // Dropdown should be hidden
    expect(await page.getByTestId('header-user-menu-dropdown').count()).toBe(0)
  })

  test('should navigate to profile from user menu', async ({ page }) => {
    // Open user menu
    await page.getByTestId('header-user-menu-button').click()
    await expect(page.getByTestId('header-user-menu-dropdown')).toBeVisible()

    // Click profile link
    await page.getByTestId('header-user-menu-profile').click()

    // Should navigate to profile page
    await expect(page).toHaveURL(/\/profile/)
  })

  test('should navigate to settings from user menu', async ({ page }) => {
    // Open user menu
    await page.getByTestId('header-user-menu-button').click()
    await expect(page.getByTestId('header-user-menu-dropdown')).toBeVisible()

    // Click settings link
    await page.getByTestId('header-user-menu-settings').click()

    // Should navigate to settings page
    await expect(page).toHaveURL(/\/settings/)
  })

  test('should logout successfully', async ({ page }) => {
    // Open user menu
    await page.getByTestId('header-user-menu-button').click()
    await expect(page.getByTestId('header-user-menu-dropdown')).toBeVisible()

    // Click logout
    await page.getByTestId('header-user-menu-logout').click()

    // Should redirect to login page
    await expect(page).toHaveURL(/\/login/, { timeout: 5000 })
    await expect(page.getByTestId('login-heading')).toBeVisible()
  })

  test('should navigate using quick action buttons', async ({ page }) => {
    // Click "Add Location" quick action
    await page.getByTestId('dashboard-action-add-location').click()
    await expect(page).toHaveURL(/\/locations/)

    // Navigate back to dashboard
    await page.getByTestId('sidebar-nav-dashboard').click()

    // Click "Add Extinguisher" quick action
    await page.getByTestId('dashboard-action-add-extinguisher').click()
    await expect(page).toHaveURL(/\/extinguishers/)

    // Navigate back to dashboard
    await page.getByTestId('sidebar-nav-dashboard').click()

    // Click "Start Inspection" quick action
    await page.getByTestId('dashboard-action-start-inspection').click()
    await expect(page).toHaveURL(/\/inspections/)

    // Navigate back to dashboard
    await page.getByTestId('sidebar-nav-dashboard').click()

    // Click "Generate Report" quick action
    await page.getByTestId('dashboard-action-generate-report').click()
    await expect(page).toHaveURL(/\/reports/)
  })

  test('should display correct stats on dashboard', async ({ page }) => {
    // Verify stat cards display numbers
    const locationsCount = page.getByTestId('dashboard-locations-count')
    const extinguishersCount = page.getByTestId('dashboard-extinguishers-count')
    const inspectionsCount = page.getByTestId('dashboard-inspections-count')

    await expect(locationsCount).toBeVisible()
    await expect(extinguishersCount).toBeVisible()
    await expect(inspectionsCount).toBeVisible()

    // Verify counts are numbers
    const locationText = await locationsCount.textContent()
    const extinguisherText = await extinguishersCount.textContent()
    const inspectionText = await inspectionsCount.textContent()

    expect(locationText).toMatch(/^\d+$/)
    expect(extinguisherText).toMatch(/^\d+$/)
    expect(inspectionText).toMatch(/^\d+$/)
  })

  test('should open mobile menu on small screens', async ({ page }) => {
    // Set viewport to mobile size
    await page.setViewportSize({ width: 375, height: 667 })

    // Mobile menu toggle should be visible
    const menuToggle = page.getByTestId('header-menu-toggle')
    await expect(menuToggle).toBeVisible()

    // Click to open sidebar
    await menuToggle.click()

    // Sidebar should open (navigation items should be visible)
    await expect(page.getByTestId('sidebar-nav-dashboard')).toBeVisible()

    // Click close button
    await page.getByTestId('sidebar-close-button').click()

    // Sidebar should close (wait for animation)
    await page.waitForTimeout(500)
  })
})
