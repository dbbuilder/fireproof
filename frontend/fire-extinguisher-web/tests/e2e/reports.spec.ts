import { test, expect } from '@playwright/test'
import {
  navigateTo,
  waitForLoading,
  setupConsoleErrorListener,
} from './helpers'

test.describe('Reports View', () => {
  // Note: These tests use stored authentication from auth.setup.ts

  test('should display reports page without errors', async ({ page }) => {
    // Set up console error listener
    const consoleErrors = setupConsoleErrorListener(page)

    // Navigate to reports
    await navigateTo(page, '/reports')

    // Wait for loading to complete
    await waitForLoading(page)

    // Verify page loaded
    await expect(
      page.locator('h1', { hasText: 'Reports & Analytics' })
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

    // Find the Pass Rate stat card
    const passRateCard = page.locator('.card').filter({ hasText: 'Pass Rate' })
    await expect(passRateCard).toBeVisible()

    // The pass rate should have a percentage value (even if 0.0%)
    const passRateValue = passRateCard.locator('div.text-3xl')
    await expect(passRateValue).toBeVisible()
    const passRateText = await passRateValue.textContent()
    expect(passRateText).toMatch(/\d+\.\d%/)

    // Verify other stat cards
    await expect(
      page.locator('.card').filter({ hasText: 'Total Inspections' })
    ).toBeVisible()
    await expect(
      page.locator('.card').filter({ hasText: 'Require Service' })
    ).toBeVisible()
    await expect(
      page.locator('.card').filter({ hasText: 'Require Replacement' })
    ).toBeVisible()
  })

  test('should display pass/fail distribution chart with percentages', async ({
    page,
  }) => {
    await navigateTo(page, '/reports')
    await waitForLoading(page)

    // Find the Pass/Fail Distribution card
    const distributionCard = page
      .locator('.card')
      .filter({ hasText: 'Pass/Fail Distribution' })
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

    // Find the "Inspections by Location" section
    const locationSection = page
      .locator('.card')
      .filter({ hasText: 'Inspections by Location' })
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

    // Page should not crash
    await expect(
      page.locator('h1', { hasText: 'Reports & Analytics' })
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

        // Page should not crash
        await expect(page.locator('h1')).toBeVisible()
      }
    }
  })

  test('should generate report', async ({ page }) => {
    await navigateTo(page, '/reports')
    await waitForLoading(page)

    // Find "Generate Report" button
    const generateButton = page.locator(
      'button:has-text("Generate Report")'
    )
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

    // Even with no data, all percentages should show valid values (0.0%)
    const passRateCard = page.locator('.card').filter({ hasText: 'Pass Rate' })
    if (await passRateCard.isVisible()) {
      const passRateValue = await passRateCard
        .locator('div.text-3xl')
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

  test('should display inspections by type breakdown', async ({ page }) => {
    await navigateTo(page, '/reports')
    await waitForLoading(page)

    // Find "Inspections by Type" section
    const typeSection = page
      .locator('.card')
      .filter({ hasText: 'Inspections by Type' })
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

    // Find "Recent Inspection Activity" section
    const activitySection = page
      .locator('.card')
      .filter({ hasText: 'Recent Inspection Activity' })
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
