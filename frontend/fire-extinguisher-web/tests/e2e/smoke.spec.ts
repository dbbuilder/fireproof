import { test, expect } from '@playwright/test'
import { setupConsoleErrorListener } from './helpers'

test.describe('Smoke Tests - No JavaScript Errors', () => {
  test('login page should load without errors', async ({ page }) => {
    // Set up console error listener
    const consoleErrors = setupConsoleErrorListener(page)

    // Navigate to login page
    await page.goto('/')

    // Wait for page to load
    await page.waitForLoadState('networkidle')

    // Verify page loaded
    await expect(page.locator('h1', { hasText: 'Welcome Back' })).toBeVisible()

    // Check for critical JavaScript errors
    const criticalErrors = consoleErrors.filter(
      (error) =>
        error.includes('toFixed') ||
        error.includes('Cannot read properties of undefined') ||
        error.includes('TypeError')
    )

    if (criticalErrors.length > 0) {
      console.log('Console errors found:', criticalErrors)
    }

    expect(criticalErrors).toHaveLength(0)
  })

  test('homepage should load without errors', async ({ page }) => {
    // Set up console error listener
    const consoleErrors = setupConsoleErrorListener(page)

    // Navigate to homepage
    await page.goto('/')

    // Wait for page to load
    await page.waitForLoadState('networkidle')

    // Check for critical JavaScript errors
    const criticalErrors = consoleErrors.filter(
      (error) =>
        error.includes('toFixed') ||
        error.includes('Cannot read properties of undefined') ||
        error.includes('TypeError')
    )

    expect(criticalErrors).toHaveLength(0)
  })

  test('register page should load without errors', async ({ page }) => {
    // Set up console error listener
    const consoleErrors = setupConsoleErrorListener(page)

    // Navigate to register page
    await page.goto('/register')

    // Wait for page to load
    await page.waitForLoadState('networkidle')

    // Verify page loaded (look for any register-related text)
    const hasRegisterContent = await page
      .locator('h1, h2').filter({ hasText: /create|register|sign up/i })
      .first()
      .isVisible()
      .catch(() => false)

    expect(hasRegisterContent).toBeTruthy()

    // Check for critical JavaScript errors
    const criticalErrors = consoleErrors.filter(
      (error) =>
        error.includes('toFixed') ||
        error.includes('Cannot read properties of undefined') ||
        error.includes('TypeError')
    )

    expect(criticalErrors).toHaveLength(0)
  })

  test('404 page should load without errors', async ({ page }) => {
    // Set up console error listener
    const consoleErrors = setupConsoleErrorListener(page)

    // Navigate to non-existent page
    await page.goto('/this-page-does-not-exist')

    // Wait for page to load
    await page.waitForLoadState('networkidle')

    // Check for critical JavaScript errors
    const criticalErrors = consoleErrors.filter(
      (error) =>
        error.includes('toFixed') ||
        error.includes('Cannot read properties of undefined') ||
        error.includes('TypeError')
    )

    expect(criticalErrors).toHaveLength(0)
  })
})

test.describe('Visual Regression - Basic Page Structure', () => {
  test('login page has expected structure', async ({ page }) => {
    await page.goto('/')
    await page.waitForLoadState('networkidle')

    // Check for key elements
    await expect(page.locator('h1')).toBeVisible()
    await expect(page.locator('input#email')).toBeVisible()
    await expect(page.locator('input#password')).toBeVisible()
    await expect(page.locator('button[type="submit"]')).toBeVisible()

    // Take screenshot for visual comparison
    await page.screenshot({ path: 'test-results/screenshots/login-page.png', fullPage: true })
  })
})
