import { test, expect } from '@playwright/test'

/**
 * Inspector Login E2E Test
 * Tests the inspector app login flow at inspect.fireproofapp.net
 */

test.describe('Inspector Login', () => {
  // Use inspector app URL
  const inspectorUrl = 'https://inspect.fireproofapp.net'
  const testCredentials = {
    email: 'chris@servicevision.net',
    password: 'Gv51076'
  }

  test.beforeEach(async ({ page }) => {
    // Clear all storage before each test
    await page.context().clearCookies()
    await page.evaluate(() => {
      localStorage.clear()
      sessionStorage.clear()
    })
  })

  test('should display inspector login page', async ({ page }) => {
    console.log('🔍 Test: Navigating to inspector app...')

    // Navigate to inspector app
    await page.goto(inspectorUrl)

    // Should redirect to /inspector/login
    await expect(page).toHaveURL(/\/inspector\/login/)
    console.log('✅ Redirected to login page:', page.url())

    // Check page title
    const title = await page.title()
    console.log('📄 Page title:', title)

    // Should show inspector branding
    await expect(page.getByTestId('app-title')).toContainText('FireProof Inspector')
    console.log('✅ App title found')

    // Should show login form
    await expect(page.getByTestId('login-form')).toBeVisible()
    console.log('✅ Login form visible')

    // Should show email and password inputs
    await expect(page.getByTestId('email-input')).toBeVisible()
    await expect(page.getByTestId('password-input')).toBeVisible()
    console.log('✅ Email and password inputs visible')

    // Should show sign in button
    await expect(page.getByTestId('login-button')).toBeVisible()
    await expect(page.getByTestId('login-button')).toContainText('Sign In')
    console.log('✅ Sign In button visible')

    // Take screenshot
    await page.screenshot({ path: 'test-results/01-inspector-login-page.png', fullPage: true })
    console.log('📸 Screenshot saved: 01-inspector-login-page.png')
  })

  test('should attempt login and capture API response', async ({ page }) => {
    console.log('🔍 Test: Attempting login...')

    // Set up network monitoring
    const apiRequests: any[] = []
    const apiResponses: any[] = []

    page.on('request', request => {
      if (request.url().includes('api.fireproofapp.net')) {
        console.log('🌐 API Request:', request.method(), request.url())
        apiRequests.push({
          method: request.method(),
          url: request.url(),
          headers: request.headers(),
          postData: request.postData()
        })
      }
    })

    page.on('response', async response => {
      if (response.url().includes('api.fireproofapp.net')) {
        const status = response.status()
        const statusText = response.statusText()
        console.log(`🌐 API Response: ${status} ${statusText} - ${response.url()}`)

        try {
          const body = await response.text()
          apiResponses.push({
            status,
            statusText,
            url: response.url(),
            headers: response.headers(),
            body: body.substring(0, 500) // First 500 chars
          })

          if (status !== 200) {
            console.error(`❌ Non-200 response body: ${body}`)
          }
        } catch (e) {
          console.log('Could not read response body')
        }
      }
    })

    // Listen to console messages from the page
    page.on('console', msg => {
      const type = msg.type()
      const text = msg.text()

      if (text.includes('[Inspector Login]')) {
        console.log(`📱 Browser Console [${type}]: ${text}`)
      }

      if (type === 'error') {
        console.error(`📱 Browser Error: ${text}`)
      }
    })

    // Navigate to inspector app
    await page.goto(inspectorUrl)
    await expect(page).toHaveURL(/\/inspector\/login/)

    await page.screenshot({ path: 'test-results/02-before-login.png', fullPage: true })

    // Fill in credentials
    console.log('📝 Filling in credentials...')
    await page.getByTestId('email-input').fill(testCredentials.email)
    console.log(`   Email: ${testCredentials.email}`)

    await page.getByTestId('password-input').fill(testCredentials.password)
    console.log('   Password: ********')

    await page.screenshot({ path: 'test-results/03-credentials-filled.png', fullPage: true })

    // Click sign in button
    console.log('🔘 Clicking Sign In button...')
    await page.getByTestId('login-button').click()

    // Wait a bit for API call
    await page.waitForTimeout(3000)

    await page.screenshot({ path: 'test-results/04-after-submit.png', fullPage: true })

    // Check current URL
    const currentUrl = page.url()
    console.log('📍 Current URL:', currentUrl)

    // Check for error message
    const errorAlert = page.getByTestId('error-alert')
    const hasError = await errorAlert.isVisible().catch(() => false)

    if (hasError) {
      const errorText = await errorAlert.textContent()
      console.error('❌ Error message displayed:', errorText)
      await page.screenshot({ path: 'test-results/05-error-state.png', fullPage: true })
    }

    // Check if redirected to dashboard
    if (currentUrl.includes('/inspector/dashboard')) {
      console.log('✅ Successfully redirected to dashboard!')
      await page.screenshot({ path: 'test-results/06-dashboard.png', fullPage: true })

      // Check for localStorage token
      const token = await page.evaluate(() => localStorage.getItem('inspector_token'))
      console.log('🔑 Token in localStorage:', token ? 'YES (length: ' + token.length + ')' : 'NO')
    } else if (currentUrl.includes('/inspector/login')) {
      console.log('⚠️  Still on login page - login likely failed')
    }

    // Print API summary
    console.log('\n📊 API Request Summary:')
    console.log('Total API requests:', apiRequests.length)
    apiRequests.forEach((req, i) => {
      console.log(`  ${i + 1}. ${req.method} ${req.url}`)
      if (req.postData) {
        console.log(`     Body: ${req.postData}`)
      }
    })

    console.log('\n📊 API Response Summary:')
    console.log('Total API responses:', apiResponses.length)
    apiResponses.forEach((res, i) => {
      console.log(`  ${i + 1}. ${res.status} ${res.statusText} - ${res.url}`)
      if (res.body) {
        console.log(`     Body: ${res.body}`)
      }
    })

    // Fail the test if we got a 401 or if login failed
    if (apiResponses.some(r => r.status === 401)) {
      throw new Error('Login failed with 401 Unauthorized')
    }

    if (currentUrl.includes('/inspector/login')) {
      throw new Error('Login failed - still on login page')
    }

    // If we get here, login should have succeeded
    expect(currentUrl).toContain('/inspector/dashboard')
  })

  test('should show validation errors for empty fields', async ({ page }) => {
    console.log('🔍 Test: Validation for empty fields...')

    await page.goto(inspectorUrl)

    // Try to submit without filling anything
    const submitButton = page.getByTestId('login-button')

    // Button should be disabled when fields are empty
    await expect(submitButton).toBeDisabled()
    console.log('✅ Submit button disabled when fields empty')

    // Fill only email
    await page.getByTestId('email-input').fill(testCredentials.email)
    await expect(submitButton).toBeDisabled()
    console.log('✅ Submit button disabled when only email filled')

    // Clear email and fill only password
    await page.getByTestId('email-input').clear()
    await page.getByTestId('password-input').fill(testCredentials.password)
    await expect(submitButton).toBeDisabled()
    console.log('✅ Submit button disabled when only password filled')

    // Fill both fields
    await page.getByTestId('email-input').fill(testCredentials.email)
    await page.getByTestId('password-input').fill(testCredentials.password)
    await expect(submitButton).toBeEnabled()
    console.log('✅ Submit button enabled when both fields filled')
  })
})
