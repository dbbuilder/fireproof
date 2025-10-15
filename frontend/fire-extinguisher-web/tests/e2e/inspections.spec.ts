import { test, expect } from '@playwright/test'
import {
  loginAndSelectTenant,
  navigateTo,
  waitForLoading,
  setupConsoleErrorListener,
} from './helpers'

test.describe('Inspections View', () => {
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

    // Verify page loaded
    await expect(page.locator('h1', { hasText: 'Inspections' })).toBeVisible()

    // Check for console errors (specifically the .toFixed() error we fixed)
    const toFixedErrors = consoleErrors.filter((error) =>
      error.includes('toFixed')
    )
    expect(toFixedErrors).toHaveLength(0)
  })

  test('should display statistics cards with valid numbers', async ({ page }) => {
    await navigateTo(page, '/inspections')
    await waitForLoading(page)

    // Find all stat cards
    const statCards = page.locator('.card').filter({ hasText: /Total|Pass Rate|Pending|Overdue/ })

    // Verify at least 4 stat cards are visible
    await expect(statCards).toHaveCount(4)

    // Check that pass rate is displayed with percentage
    const passRateCard = page.locator('.card').filter({ hasText: 'Pass Rate' })
    await expect(passRateCard).toBeVisible()

    // The pass rate should have a percentage value (even if 0.0%)
    const passRateValue = passRateCard.locator('div.text-2xl, div.text-3xl')
    await expect(passRateValue).toBeVisible()
    const passRateText = await passRateValue.textContent()
    expect(passRateText).toMatch(/\d+\.\d%/)
  })

  test('should handle empty state gracefully', async ({ page }) => {
    // Set up console error listener
    const consoleErrors = setupConsoleErrorListener(page)

    await navigateTo(page, '/inspections')
    await waitForLoading(page)

    // Even with no data, stats should show 0.0% without errors
    const passRateCard = page.locator('.card').filter({ hasText: 'Pass Rate' })
    if (await passRateCard.isVisible()) {
      const passRateValue = await passRateCard
        .locator('div.text-2xl, div.text-3xl')
        .textContent()

      // Should be a valid percentage
      expect(passRateValue).toMatch(/^\d+\.\d%$/)
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

    // Check if table exists
    const table = page.locator('table').first()
    const tableVisible = await table.isVisible().catch(() => false)

    if (tableVisible) {
      // Verify table headers
      await expect(
        page.locator('th', { hasText: /Extinguisher|Date|Type|Status/i })
      ).toHaveCount(4)
    } else {
      // If no table, should show empty state
      await expect(
        page.locator('text=/No inspections found|No data/i')
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

    // Look for "New Inspection" or similar button
    const newInspectionButton = page.locator(
      'button:has-text("New Inspection"), a:has-text("New Inspection")'
    )

    // Button should exist
    await expect(newInspectionButton).toBeVisible()
  })
})
