import { test as base, expect as baseExpect, Browser } from '@playwright/test'
import fs from 'fs'
import path from 'path'

/**
 * Custom test fixture that ensures localStorage is set BEFORE page loads.
 *
 * This solves the timing issue where Vue Router guards execute before
 * Playwright's storageState is fully loaded. By using addInitScript,
 * we inject localStorage values into the browser context before any
 * navigation occurs.
 *
 * Based on Playwright best practices:
 * https://playwright.dev/docs/auth#reuse-authentication-state
 */
export const test = base.extend({
  context: async ({ browser }, use) => {
    // Read the saved storage state
    const storageStatePath = path.join(process.cwd(), 'playwright/.auth/user.json')

    // Create a new context with storage state loaded
    const context = await browser.newContext({
      storageState: fs.existsSync(storageStatePath) ? storageStatePath : undefined
    })

    if (fs.existsSync(storageStatePath)) {
      const storageState = JSON.parse(fs.readFileSync(storageStatePath, 'utf-8'))

      // Extract localStorage from storageState
      const origin = storageState.origins?.find((o: any) =>
        o.origin === process.env.PLAYWRIGHT_BASE_URL || o.origin === 'http://localhost:5600'
      )

      if (origin?.localStorage) {
        // Use addInitScript to set localStorage BEFORE any page loads
        // This ensures Vue Router guards see the auth state immediately
        await context.addInitScript((storage) => {
          for (const item of storage) {
            window.localStorage.setItem(item.name, item.value)
          }
          // Set a custom flag for router guard to detect E2E test mode
          window.__PLAYWRIGHT_E2E__ = true
        }, origin.localStorage)
      }
    }

    await use(context)
    await context.close()
  }
})

export const expect = baseExpect
