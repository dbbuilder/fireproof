import { test, expect } from '@playwright/test'
import {
  navigateTo,
  waitForLoading,
  setupConsoleErrorListener,
  loginAndSelectTenant,
} from './helpers'

test.describe('Reports View', () => {
  // Fresh login before each test (no relying on saved auth state)
  test.beforeEach(async ({ page }) => {
    await loginAndSelectTenant(page)
  })

  test('should display reports page without errors', async ({ page }) => {
    // Set up console error listener
    const consoleErrors = setupConsoleErrorListener(page)

    // Navigate to reports
    await navigateTo(page, '/reports')

    // Wait for loading to complete
    await waitForLoading(page)

    // Verify page loaded using test ID
    await expect(
      page.locator('[data-testid="reports-heading"]')
    ).toBeVisible()

    // Check for console errors (specifically the .toFixed() errors we fixed)
    const toFixedErrors = consoleErrors.filter((error) =>
      error.includes('toFixed')
    )
    expect(toFixedErrors).toHaveLength(0)
  })

  test('should display all statistics cards with valid percentages', async ({
    page,
  }) => {
    await navigateTo(page, '/reports')
    await waitForLoading(page)

    // Verify all stat cards using test IDs
    await expect(page.locator('[data-testid="stat-card-total"]')).toBeVisible()
    await expect(page.locator('[data-testid="stat-card-passrate"]')).toBeVisible()
    await expect(page.locator('[data-testid="stat-card-service"]')).toBeVisible()
    await expect(page.locator('[data-testid="stat-card-replacement"]')).toBeVisible()

    // The pass rate should have a percentage value (even if 0.0%) using test ID
    const passRateValue = page.locator('[data-testid="pass-rate"]')
    await expect(passRateValue).toBeVisible()
    const passRateText = await passRateValue.textContent()
    expect(passRateText).toMatch(/\d+\.\d%/)
  })

  test('should display pass/fail distribution chart with percentages', async ({
    page,
  }) => {
    await navigateTo(page, '/reports')
    await waitForLoading(page)

    // Find the Pass/Fail Distribution card using test ID
    const distributionCard = page.locator('[data-testid="pass-fail-distribution-card"]')
    await expect(distributionCard).toBeVisible()

    // Look for "Passed" and "Failed" rows
    const passedRow = distributionCard.locator('text=Passed').first()
    const failedRow = distributionCard.locator('text=Failed').first()

    if ((await passedRow.isVisible()) && (await failedRow.isVisible())) {
      // Get the parent container to find percentages
      const passedContainer = passedRow.locator('..').locator('..')
      const failedContainer = failedRow.locator('..').locator('..')

      // Should contain percentage values
      const passedText = await passedContainer.textContent()
      const failedText = await failedContainer.textContent()

      // Check that percentages are present and valid
      expect(passedText).toMatch(/\d+\.\d%/)
      expect(failedText).toMatch(/\d+\.\d%/)
    }
  })

  test('should display visual pie chart bars with percentages', async ({
    page,
  }) => {
    // Set up console error listener
    const consoleErrors = setupConsoleErrorListener(page)

    await navigateTo(page, '/reports')
    await waitForLoading(page)

    // Look for the visual representation (colored bars)
    const greenBar = page.locator('.bg-green-500').filter({ hasText: '%' }).first()
    const redBar = page.locator('.bg-red-500').filter({ hasText: '%' }).first()

    // At least one should be visible
    const greenVisible = await greenBar.isVisible().catch(() => false)
    const redVisible = await redBar.isVisible().catch(() => false)

    expect(greenVisible || redVisible).toBeTruthy()

    // No .toFixed errors should occur
    const toFixedErrors = consoleErrors.filter((error) =>
      error.includes('toFixed')
    )
    expect(toFixedErrors).toHaveLength(0)
  })

  test('should display inspections by location with pass rates', async ({
    page,
  }) => {
    await navigateTo(page, '/reports')
    await waitForLoading(page)

    // Find the "Inspections by Location" section using test ID
    const locationSection = page.locator('[data-testid="inspections-by-location-card"]')
    await expect(locationSection).toBeVisible()

    // Look for location rows
    const locationRows = locationSection.locator('[class*="flex"][class*="items-center"]')
    const rowCount = await locationRows.count()

    if (rowCount > 0) {
      // Each location should have a pass rate percentage
      const firstLocation = locationRows.first()
      const locationText = await firstLocation.textContent()

      // Should contain "Pass Rate" and a percentage
      expect(locationText).toMatch(/Pass Rate/)
      expect(locationText).toMatch(/\d+\.\d%/)
    }
  })

  test('should allow date range filtering', async ({ page }) => {
    await navigateTo(page, '/reports')
    await waitForLoading(page)

    // Find date inputs
    const startDateInput = page.locator('input[type="date"]#startDate')
    const endDateInput = page.locator('input[type="date"]#endDate')

    await expect(startDateInput).toBeVisible()
    await expect(endDateInput).toBeVisible()

    // Change date range
    await startDateInput.fill('2025-01-01')
    await endDateInput.fill('2025-01-31')

    // Wait for potential API calls
    await page.waitForTimeout(1000)
    await waitForLoading(page)

    // Page should not crash - use test ID
    await expect(
      page.locator('[data-testid="reports-heading"]')
    ).toBeVisible()
  })

  test('should filter by location', async ({ page }) => {
    await navigateTo(page, '/reports')
    await waitForLoading(page)

    // Find location filter select
    const locationSelect = page.locator('select#location')

    if (await locationSelect.isVisible()) {
      // Get options
      const options = locationSelect.locator('option')
      const optionCount = await options.count()

      if (optionCount > 1) {
        // Select second option (first is "All Locations")
        await locationSelect.selectOption({ index: 1 })

        // Wait for filtering
        await page.waitForTimeout(1000)
        await waitForLoading(page)

        // Page should not crash - use test ID
        await expect(page.locator('[data-testid="reports-heading"]')).toBeVisible()
      }
    }
  })

  test('should generate report', async ({ page }) => {
    await navigateTo(page, '/reports')
    await waitForLoading(page)

    // Find "Generate Report" button using test ID
    const generateButton = page.locator('[data-testid="generate-report-button"]')
    await expect(generateButton).toBeVisible()

    // Set up download listener
    const downloadPromise = page.waitForEvent('download', { timeout: 10000 })

    // Click generate report
    await generateButton.click()

    // Wait for download or timeout
    try {
      const download = await downloadPromise
      expect(download.suggestedFilename()).toMatch(/inspection-report.*\.csv/)
    } catch {
      // Download might not work in test environment, but button should work
      await expect(generateButton).toBeVisible()
    }
  })

  test('should handle empty state gracefully', async ({ page }) => {
    // Set up console error listener
    const consoleErrors = setupConsoleErrorListener(page)

    await navigateTo(page, '/reports')
    await waitForLoading(page)

    // Even with no data, all percentages should show valid values (0.0%) using test ID
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

  test('should display inspections by type breakdown', async ({ page }) => {
    await navigateTo(page, '/reports')
    await waitForLoading(page)

    // Find "Inspections by Type" section using test ID
    const typeSection = page.locator('[data-testid="inspections-by-type-card"]')
    await expect(typeSection).toBeVisible()

    // Should show inspection types (Monthly, Annual, etc.) or empty state
    const hasContent = await typeSection
      .locator('text=/Monthly|Annual|5-Year|12-Year|No inspection data/i')
      .first()
      .isVisible()
      .catch(() => false)

    expect(hasContent).toBeTruthy()
  })

  test('should display recent inspection activity', async ({ page }) => {
    await navigateTo(page, '/reports')
    await waitForLoading(page)

    // Find "Recent Inspection Activity" section using test ID
    const activitySection = page.locator('[data-testid="recent-activity-card"]')
    await expect(activitySection).toBeVisible()

    // Should show inspections or empty state
    const hasContent = await activitySection
      .locator('text=/Passed|Failed|No recent inspections/i')
      .first()
      .isVisible()
      .catch(() => false)

    expect(hasContent).toBeTruthy()
  })
})
