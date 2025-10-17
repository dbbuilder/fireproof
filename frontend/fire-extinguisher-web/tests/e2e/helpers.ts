import { Page, expect } from '@playwright/test'

/**
 * Test credentials and configuration
 */
export const TEST_CONFIG = {
  email: 'chris@servicevision.net',
  password: 'Gv51076', // Original password without exclamation mark
  tenantId: '634f2b52-d32a-46dd-a045-d158e793adcb',
  tenantName: 'Demo Company Inc',
  apiBaseUrl: 'https://fireproof-api-test-2025.azurewebsites.net/api',
}

/**
 * Login to the application
 * @param page - Playwright page object
 * @param email - User email (default: TEST_CONFIG.email)
 * @param password - User password (default: TEST_CONFIG.password)
 */
export async function login(
  page: Page,
  email: string = TEST_CONFIG.email,
  password: string = TEST_CONFIG.password
) {
  await page.goto('/login')

  // Wait for login page to load
  await expect(page.locator('h1', { hasText: 'Welcome Back' })).toBeVisible()

  // Fill in credentials
  await page.fill('[data-testid="email-input"]', email)
  await page.fill('[data-testid="password-input"]', password)

  // Submit login
  await page.click('[data-testid="login-submit-button"]')

  // Wait for navigation (either to dashboard or tenant selection)
  await page.waitForLoadState('networkidle')
}

/**
 * Select a tenant after login
 * @param page - Playwright page object
 * @param tenantId - Tenant ID to select (default: TEST_CONFIG.tenantId)
 */
export async function selectTenant(
  page: Page,
  tenantId: string = TEST_CONFIG.tenantId
) {
  // Check if we're on tenant selection page
  const tenantSelectionVisible = await page
    .locator('h1', { hasText: 'Select Organization' })
    .isVisible()
    .catch(() => false)

  if (tenantSelectionVisible) {
    // Click the tenant card or button with the matching tenant ID
    await page.click(`button[data-tenant-id="${tenantId}"]`)
    await page.waitForLoadState('networkidle')
  }
}

/**
 * Complete login flow including tenant selection
 * @param page - Playwright page object
 */
export async function loginAndSelectTenant(page: Page) {
  await login(page)
  await selectTenant(page)

  // Verify we're on the dashboard
  await expect(page).toHaveURL(/\/dashboard/)
}

/**
 * Navigate to a specific route
 * @param page - Playwright page object
 * @param route - Route to navigate to (e.g., '/inspections')
 */
export async function navigateTo(page: Page, route: string) {
  await page.goto(route)
  await page.waitForLoadState('networkidle')
}

/**
 * Wait for API response
 * @param page - Playwright page object
 * @param endpoint - API endpoint to wait for (e.g., '/inspections')
 */
export async function waitForApiResponse(page: Page, endpoint: string) {
  return page.waitForResponse(
    (response) =>
      response.url().includes(endpoint) && response.status() === 200
  )
}

/**
 * Check if element exists and is visible
 * @param page - Playwright page object
 * @param selector - Element selector
 */
export async function isVisible(page: Page, selector: string): Promise<boolean> {
  try {
    const element = await page.locator(selector)
    return await element.isVisible()
  } catch {
    return false
  }
}

/**
 * Wait for loading to complete
 * @param page - Playwright page object
 */
export async function waitForLoading(page: Page) {
  // Wait for any spinners to disappear
  await page.waitForSelector('.spinner-lg', { state: 'hidden', timeout: 10000 }).catch(() => {})
  await page.waitForSelector('[role="status"]', { state: 'hidden', timeout: 10000 }).catch(() => {})
}

/**
 * Take a screenshot with a descriptive name
 * @param page - Playwright page object
 * @param name - Screenshot name
 */
export async function takeScreenshot(page: Page, name: string) {
  await page.screenshot({
    path: `tests/screenshots/${name}-${Date.now()}.png`,
    fullPage: true,
  })
}

/**
 * Check for console errors
 * @param page - Playwright page object
 */
export function setupConsoleErrorListener(page: Page): string[] {
  const errors: string[] = []

  page.on('console', (msg) => {
    if (msg.type() === 'error') {
      errors.push(msg.text())
    }
  })

  page.on('pageerror', (error) => {
    errors.push(error.message)
  })

  return errors
}
