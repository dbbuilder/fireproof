import { test, expect } from '@playwright/test'
import { login, selectTenant, loginAndSelectTenant, TEST_CONFIG } from './helpers'

test.describe('Authentication', () => {
  test('should load login page', async ({ page }) => {
    await page.goto('/login')

    // Check for login form elements
    await expect(page.locator('h1', { hasText: 'Welcome Back' })).toBeVisible()
    await expect(page.locator('[data-testid="email-input"]')).toBeVisible()
    await expect(page.locator('[data-testid="password-input"]')).toBeVisible()
    await expect(page.locator('[data-testid="login-submit-button"]')).toBeVisible()
  })

  test('should show validation errors for empty form', async ({ page }) => {
    await page.goto('/login')

    // Try to submit without filling form
    await page.click('[data-testid="login-submit-button"]')

    // HTML5 validation should prevent submission
    const emailInput = page.locator('[data-testid="email-input"]')
    const isInvalid = await emailInput.evaluate((el: HTMLInputElement) => !el.validity.valid)
    expect(isInvalid).toBeTruthy()
  })

  test('should login successfully', async ({ page }) => {
    await login(page)

    // Should either be on dashboard or tenant selection
    const url = page.url()
    expect(url).toMatch(/\/(dashboard|select-tenant)/)
  })

  test('should select tenant and navigate to dashboard', async ({ page }) => {
    await loginAndSelectTenant(page)

    // Verify we're on dashboard
    await expect(page).toHaveURL(/\/dashboard/)
    await expect(page.locator('h1', { hasText: 'Dashboard' })).toBeVisible()

    // Verify tenant name is displayed in header
    await expect(
      page.locator('text=' + TEST_CONFIG.tenantName)
    ).toBeVisible()
  })

  test('should persist authentication across page reload', async ({ page }) => {
    await loginAndSelectTenant(page)

    // Reload the page
    await page.reload()

    // Should still be authenticated
    await expect(page).toHaveURL(/\/dashboard/)
  })

  test('should logout successfully', async ({ page }) => {
    await loginAndSelectTenant(page)

    // Click user menu
    await page.click('button[aria-label="User menu"]').catch(() => {
      // Try alternative selector if aria-label doesn't exist
      return page.click('button:has-text("' + TEST_CONFIG.email + '")')
    })

    // Click logout
    await page.click('text=Logout')

    // Should redirect to login
    await expect(page).toHaveURL(/\/login/)
  })
})
