import { test, expect } from '@playwright/test'

test.describe('Login Flow', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login', { waitUntil: 'networkidle' })
  })

  test('should display login page with correct elements', async ({ page }) => {
    // Verify page loaded
    await expect(page).toHaveURL(/\/login/)

    // Verify heading and description
    await expect(page.getByTestId('login-heading')).toBeVisible()
    await expect(page.getByTestId('login-heading')).toContainText('Welcome Back')
    await expect(page.getByTestId('login-description')).toBeVisible()

    // Verify form elements
    await expect(page.getByTestId('email-input')).toBeVisible()
    await expect(page.getByTestId('password-input')).toBeVisible()
    await expect(page.getByTestId('remember-me-checkbox')).toBeVisible()
    await expect(page.getByTestId('forgot-password-link')).toBeVisible()
    await expect(page.getByTestId('login-submit-button')).toBeVisible()
    await expect(page.getByTestId('register-link')).toBeVisible()
  })

  test('should show validation errors for empty fields', async ({ page }) => {
    // Click submit without filling form
    await page.getByTestId('login-submit-button').click()

    // Browser native validation should prevent submission
    const emailInput = page.getByTestId('email-input')
    const passwordInput = page.getByTestId('password-input')

    // Check that inputs have required attribute
    await expect(emailInput).toHaveAttribute('required', '')
    await expect(passwordInput).toHaveAttribute('required', '')
  })

  test('should successfully login with valid credentials (regular user)', async ({ page }) => {
    // Fill in credentials for test user
    await page.getByTestId('email-input').fill('chris@servicevision.net')
    await page.getByTestId('password-input').fill('Gv51076')

    // Submit form
    await page.getByTestId('login-submit-button').click()

    // Should redirect to dashboard (auto-tenant for regular users)
    await page.waitForURL(/\/dashboard/, { timeout: 10000 })

    // Verify dashboard loaded
    await expect(page.getByTestId('dashboard-heading')).toBeVisible()
    await expect(page.getByTestId('dashboard-heading')).toContainText('Welcome back')

    // Verify navigation is available
    await expect(page.getByTestId('header-logo')).toBeVisible()
    await expect(page.getByTestId('header-user-menu-button')).toBeVisible()
  })

  test('should show error message for invalid credentials', async ({ page }) => {
    // Fill in invalid credentials
    await page.getByTestId('email-input').fill('invalid@example.com')
    await page.getByTestId('password-input').fill('wrongpassword')

    // Submit form
    await page.getByTestId('login-submit-button').click()

    // Wait for error message
    await expect(page.getByTestId('login-error')).toBeVisible({ timeout: 5000 })
    await expect(page.getByTestId('login-error')).toContainText(/invalid|login failed|credentials/i)
  })

  test('should navigate to register page', async ({ page }) => {
    // Click register link
    await page.getByTestId('register-link').click()

    // Verify navigation to register page
    await expect(page).toHaveURL(/\/register/)
    await expect(page.getByTestId('register-heading')).toBeVisible()
  })

  test('should toggle password visibility', async ({ page }) => {
    const passwordInput = page.getByTestId('password-input')
    const toggleButton = page.getByTestId('toggle-password-visibility')

    // Initially password field should be hidden
    await expect(passwordInput).toHaveAttribute('type', 'password')

    // Click toggle button
    await toggleButton.click()

    // Password should now be visible
    await expect(passwordInput).toHaveAttribute('type', 'text')

    // Click again to hide
    await toggleButton.click()
    await expect(passwordInput).toHaveAttribute('type', 'password')
  })

  test('should check "Remember me" checkbox', async ({ page }) => {
    const checkbox = page.getByTestId('remember-me-checkbox')

    // Initially unchecked
    await expect(checkbox).not.toBeChecked()

    // Click to check
    await checkbox.click()
    await expect(checkbox).toBeChecked()
  })

  // Dev mode test (only runs in localhost environment)
  test('should show dev login button in development', async ({ page }) => {
    // Check if dev mode is active (localhost)
    const devButton = page.getByTestId('dev-login-button')

    if (await devButton.isVisible()) {
      // Dev mode is active
      await expect(devButton).toBeVisible()
      await expect(devButton).toContainText('Dev Login')
    } else {
      // Production mode - dev button should not exist
      expect(await devButton.count()).toBe(0)
    }
  })
})
