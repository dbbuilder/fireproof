import { test as setup, expect } from '@playwright/test'
import { TEST_CONFIG } from './helpers'

const authFile = 'playwright/.auth/user.json'

setup('authenticate', async ({ page }) => {
  console.log('Starting authentication setup...')

  // Navigate to login page (root redirects to login if not authenticated)
  await page.goto('/')

  // Wait for login page to load (it might be at root or /login depending on router)
  await page.waitForLoadState('networkidle')

  // Wait for email input to appear
  await page.waitForSelector('input#email', { timeout: 15000 })

  console.log('Login page loaded, filling credentials...')

  // Fill in credentials
  await page.fill('input#email', TEST_CONFIG.email)
  await page.fill('input#password', TEST_CONFIG.password)

  console.log('Submitting login form...')

  // Submit login
  await page.click('button[type="submit"]')

  // Wait for navigation after login (could be dashboard or tenant selection)
  await page.waitForLoadState('networkidle', { timeout: 30000 })

  console.log('Login submitted, current URL:', page.url())

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
    const tenantButton = page.locator(`[data-tenant-id="${TEST_CONFIG.tenantId}"]`)
    const tenantButtonExists = await tenantButton.count() > 0

    if (tenantButtonExists) {
      await tenantButton.click()
    } else {
      // Click first tenant card
      console.log('Specific tenant not found, clicking first available tenant...')
      await page.locator('.card').first().click()
    }

    await page.waitForLoadState('networkidle', { timeout: 30000 })
    console.log('Tenant selected, current URL:', page.url())
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
