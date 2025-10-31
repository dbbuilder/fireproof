import { test as setup, expect } from '@playwright/test'

const authFile = 'playwright/.auth/user.json'

// Test credentials
const testUser = {
  email: 'chris@servicevision.net',
  password: 'Gv51076',
}

setup('authenticate with real credentials', async ({ page }) => {
  console.log('Starting authentication setup...')

  // Navigate to login page
  await page.goto('/login', { waitUntil: 'networkidle' })

  // Fill in credentials
  await page.getByTestId('email-input').fill(testUser.email)
  await page.getByTestId('password-input').fill(testUser.password)

  // Submit login form
  await page.getByTestId('login-submit-button').click()

  // Wait for navigation to complete (either dashboard or tenant selector)
  await page.waitForURL(/\/(dashboard|select-tenant)/, { timeout: 10000 })

  // If tenant selector appears, select first tenant
  const tenantSelector = page.getByTestId('tenant-selector-banner')
  if (await tenantSelector.isVisible({ timeout: 2000 }).catch(() => false)) {
    console.log('Tenant selector detected, selecting tenant...')
    await page.getByTestId('tenant-selector-select').selectOption({ index: 1 })
    await page.getByTestId('tenant-selector-apply-button').click()
    await page.waitForURL(/\/dashboard/, { timeout: 10000 })
  }

  // Verify we're logged in by checking for user menu
  await expect(page.getByTestId('header-user-menu-button')).toBeVisible({ timeout: 5000 })

  console.log('Authentication successful!')

  // Save authentication state
  await page.context().storageState({ path: authFile })

  console.log('Authentication state saved to:', authFile)
})
