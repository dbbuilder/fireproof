import { test as setup, expect } from '@playwright/test'
import { TEST_CONFIG } from './helpers'

const authFile = 'playwright/.auth/user.json'

setup('authenticate', async ({ page }) => {
  console.log('Starting authentication setup...')

  // Listen for console messages and errors
  page.on('console', msg => console.log(`BROWSER ${msg.type()}: ${msg.text()}`))
  page.on('pageerror', error => console.error(`PAGE ERROR: ${error.message}`))

  // Navigate to homepage
  await page.goto('/')
  await page.waitForLoadState('networkidle')

  console.log('Homepage loaded, navigating to login...')

  // Check if we're on the homepage (with "Get Started" button) or already on login
  const getStartedButton = page.locator('button:has-text("Get Started")')
  const emailInput = page.locator('[data-testid="email-input"]')

  if (await getStartedButton.isVisible().catch(() => false)) {
    // Click "Get Started" to go to login/register
    await getStartedButton.click()
    await page.waitForLoadState('networkidle')
  }

  // If still not on login page, navigate directly
  if (!(await emailInput.isVisible().catch(() => false))) {
    await page.goto('/login')
    await page.waitForLoadState('networkidle')
  }

  // Wait for email input to appear
  await page.waitForSelector('[data-testid="email-input"]', { timeout: 15000 })

  console.log('Login page loaded, filling credentials...')

  // Fill in credentials
  await page.fill('[data-testid="email-input"]', TEST_CONFIG.email)
  await page.fill('[data-testid="password-input"]', TEST_CONFIG.password)

  console.log('Submitting login form...')

  // Click submit button
  await page.click('[data-testid="login-submit-button"]')
  console.log('Login button clicked')

  // Wait a moment for the request to be sent
  await page.waitForTimeout(1000)

  // Wait for one of several possible outcomes
  try {
    // Option 1: Navigation away from login (with longer timeout)
    await Promise.race([
      page.waitForURL(url => !url.pathname.includes('/login'), { timeout: 10000 }),
      // Option 2: Tenant selection page appears
      page.waitForSelector('[data-testid="tenant-card"]', { timeout: 10000 }),
      // Option 3: Dashboard or other authenticated page indicators
      page.waitForSelector('[aria-label="User menu"]', { timeout: 10000 })
    ]);
    console.log('Login response received, current URL:', page.url())
  } catch (error) {
    console.log('No immediate navigation, checking for errors...')

    // Check if there's an error message on the page
    const errorMessage = await page.locator('[role="alert"], .alert-danger, .error-message').textContent().catch(() => null)
    if (errorMessage) {
      console.error('Login error message:', errorMessage)
      await page.screenshot({ path: 'test-results/login-error-debug.png', fullPage: true })
      throw new Error(`Login failed with error: ${errorMessage}`)
    }

    // Check if still on login page
    if (page.url().includes('/login')) {
      console.log('Still on login page after 10s, this might be normal - continuing...')
      await page.waitForTimeout(2000) // Give it more time
    }
  }

  await page.waitForLoadState('networkidle')
  console.log('After login, current URL:', page.url())

  // Check if we're on tenant selection page
  const onTenantSelection = page.url().includes('select-tenant')

  if (onTenantSelection) {
    console.log('On tenant selection page, selecting tenant...')

    // Wait for tenant cards to load
    await page.waitForSelector('[data-tenant-id]', { timeout: 10000 }).catch(async () => {
      // If specific tenant button doesn't exist, try clicking any tenant card
      await page.waitForSelector('.card', { timeout: 10000 })
    })

    // Try to click the specific tenant or first available tenant
    const tenantCard = page.locator('[data-testid="tenant-card"]').first()
    await tenantCard.click()
    console.log('Tenant card clicked')

    // Wait a moment for the selection to register
    await page.waitForTimeout(500)

    // Now click the Continue button
    const continueButton = page.locator('[data-testid="continue-button"]')
    await continueButton.waitFor({ state: 'visible', timeout: 5000 })
    console.log('Continue button found, clicking...')

    await continueButton.click()
    console.log('Continue button clicked, waiting for navigation...')

    // Wait for navigation away from tenant selection
    await page.waitForURL(url => !url.pathname.includes('select-tenant'), { timeout: 30000 })
    await page.waitForLoadState('networkidle')
    console.log('Navigated away from tenant selection, current URL:', page.url())
  }

  // Verify we're authenticated (should be on dashboard or similar)
  const currentUrl = page.url()
  console.log('Final URL after auth:', currentUrl)

  // Check for authentication indicators
  const isAuthenticated =
    currentUrl.includes('dashboard') ||
    currentUrl.includes('inspections') ||
    currentUrl.includes('extinguishers') ||
    await page.locator('text=Logout').isVisible().catch(() => false) ||
    await page.locator('[aria-label="User menu"]').isVisible().catch(() => false)

  if (!isAuthenticated) {
    console.error('Authentication may have failed. Current URL:', currentUrl)
    throw new Error('Failed to authenticate - not on expected page')
  }

  console.log('Authentication successful! Saving state...')

  // Save authentication state
  await page.context().storageState({ path: authFile })

  console.log('Authentication state saved to:', authFile)
})
