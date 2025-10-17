import { test, expect } from '@playwright/test'
import {
  navigateTo,
  waitForLoading,
  setupConsoleErrorListener,
  loginAndSelectTenant,
} from './helpers'

test.describe('Inspections View', () => {
  // Fresh login before each test (no relying on saved auth state)
  test.beforeEach(async ({ page }) => {
    await loginAndSelectTenant(page)
  })

  test('should display inspections page without errors', async ({ page }) => {
    // Set up console error listener
    const consoleErrors = setupConsoleErrorListener(page)

    // Navigate to inspections
    await navigateTo(page, '/inspections')

    // Wait for loading to complete
    await waitForLoading(page)

    // Verify page loaded using test ID
    await expect(page.locator('[data-testid="inspections-heading"]')).toBeVisible()

    // Check for console errors (specifically the .toFixed() error we fixed)
    const toFixedErrors = consoleErrors.filter((error) =>
      error.includes('toFixed')
    )
    expect(toFixedErrors).toHaveLength(0)
  })

  test('should display statistics cards with valid numbers', async ({ page }) => {
    await navigateTo(page, '/inspections')
    await waitForLoading(page)

    // Verify stat cards using test IDs
    await expect(page.locator('[data-testid="stat-card-total"]')).toBeVisible()
    await expect(page.locator('[data-testid="stat-card-passed"]')).toBeVisible()
    await expect(page.locator('[data-testid="stat-card-failed"]')).toBeVisible()
    await expect(page.locator('[data-testid="stat-card-passrate"]')).toBeVisible()

    // Check that pass rate is displayed with percentage using test ID
    const passRateValue = page.locator('[data-testid="pass-rate"]')
    await expect(passRateValue).toBeVisible()
    const passRateText = await passRateValue.textContent()
    // Allow optional trailing whitespace
    expect(passRateText).toMatch(/\d+\.\d%\s*/)
  })

  test('should handle empty state gracefully', async ({ page }) => {
    // Set up console error listener
    const consoleErrors = setupConsoleErrorListener(page)

    await navigateTo(page, '/inspections')
    await waitForLoading(page)

    // Even with no data, stats should show 0.0% without errors using test ID
    const passRateValue = page.locator('[data-testid="pass-rate"]')
    if (await passRateValue.isVisible()) {
      const passRateText = await passRateValue.textContent()

      // Should be a valid percentage (allow optional trailing whitespace)
      expect(passRateText).toMatch(/^\d+\.\d%\s*$/)
    }

    // No .toFixed errors should occur
    const toFixedErrors = consoleErrors.filter((error) =>
      error.includes('toFixed')
    )
    expect(toFixedErrors).toHaveLength(0)
  })

  test('should display inspections table', async ({ page }) => {
    await navigateTo(page, '/inspections')
    await waitForLoading(page)

    // Check if table exists using test ID
    const table = page.locator('[data-testid="inspections-table"]')
    const tableVisible = await table.isVisible().catch(() => false)

    if (tableVisible) {
      // Verify table exists
      await expect(table).toBeVisible()
    } else {
      // If no table, should show empty state using test ID
      await expect(
        page.locator('[data-testid="inspections-empty-state"]')
      ).toBeVisible()
    }
  })

  test('should filter inspections', async ({ page }) => {
    await navigateTo(page, '/inspections')
    await waitForLoading(page)

    // Look for filter controls
    const filterControls = page.locator('select, input[type="date"], input[type="search"]')
    const hasFilters = (await filterControls.count()) > 0

    if (hasFilters) {
      // Try changing a filter
      const dateFilter = page.locator('input[type="date"]').first()
      if (await dateFilter.isVisible()) {
        await dateFilter.fill('2025-01-01')
        await waitForLoading(page)

        // Page should not crash
        await expect(page.locator('h1')).toBeVisible()
      }
    }
  })

  test('should navigate to inspection details', async ({ page }) => {
    await navigateTo(page, '/inspections')
    await waitForLoading(page)

    // Look for inspection rows
    const inspectionRows = page.locator('table tbody tr')
    const rowCount = await inspectionRows.count().catch(() => 0)

    if (rowCount > 0) {
      // Click first inspection
      await inspectionRows.first().click()

      // Should navigate to details page
      await expect(page).toHaveURL(/\/inspections\/.*/)
    }
  })

  test('should create new inspection button be visible', async ({ page }) => {
    await navigateTo(page, '/inspections')
    await waitForLoading(page)

    // Look for "Start Inspection" button using test ID
    const newInspectionButton = page.locator('[data-testid="new-inspection-button"]')

    // Button should exist
    await expect(newInspectionButton).toBeVisible()
  })
})
