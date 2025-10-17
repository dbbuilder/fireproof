import { defineConfig, devices } from '@playwright/test'

/**
 * Read environment variables from file.
 * https://github.com/motdotla/dotenv
 */
// require('dotenv').config();

/**
 * See https://playwright.dev/docs/test-configuration.
 */
export default defineConfig({
  testDir: './tests/e2e',
  /* Run tests in files in parallel */
  fullyParallel: true,
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,
  /* Retry failed tests - production needs retries for reliability */
  retries: process.env.CI ? 2 : 1,
  /* Opt out of parallel tests on CI. */
  workers: process.env.CI ? 1 : undefined,
  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: 'html',
  /* Increase timeout for production testing (network latency) */
  timeout: 60000, // 60 seconds per test
  /* Increase expect assertion timeout for production */
  expect: {
    timeout: 15000, // 15 seconds for expect assertions (toBeVisible, etc.)
  },
  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Base URL to use in actions like `await page.goto('/')`. */
    baseURL: process.env.PLAYWRIGHT_BASE_URL || 'https://www.fireproofapp.net',
    /* Increase action timeout for production */
    actionTimeout: 15000, // 15 seconds for actions like click, fill
    /* Increase navigation timeout for production */
    navigationTimeout: 30000, // 30 seconds for page loads
    /* Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer */
    trace: 'on-first-retry',
    /* Screenshot on failure */
    screenshot: 'only-on-failure',
    /* Video on failure */
    video: 'retain-on-failure',
  },

  /* Configure projects for major browsers */
  projects: [
    // Setup project - runs once to authenticate (kept for compatibility)
    {
      name: 'setup',
      testMatch: /.*\.setup\.ts/,
    },

    // Authenticated tests - use fresh login via beforeEach (no saved state)
    {
      name: 'chromium-authenticated',
      use: {
        ...devices['Desktop Chrome'],
        // Removed storageState - using fresh login in beforeEach instead
      },
      dependencies: ['setup'], // Keep dependency for test ordering
      testIgnore: ['**/auth.spec.ts', '**/smoke.spec.ts'], // Exclude auth and smoke tests
    },

    // Unauthenticated tests (smoke tests)
    {
      name: 'chromium-unauthenticated',
      use: { ...devices['Desktop Chrome'] },
      testMatch: ['**/smoke.spec.ts'], // Only run smoke tests without auth
    },

    // {
    //   name: 'firefox',
    //   use: { ...devices['Desktop Firefox'] },
    // },

    // {
    //   name: 'webkit',
    //   use: { ...devices['Desktop Safari'] },
    // },

    /* Test against mobile viewports. */
    // {
    //   name: 'Mobile Chrome',
    //   use: { ...devices['Pixel 5'] },
    // },
    // {
    //   name: 'Mobile Safari',
    //   use: { ...devices['iPhone 12'] },
    // },
  ],

  /* Run your local dev server before starting the tests (disabled for production testing) */
  // webServer: {
  //   command: 'npm run dev',
  //   url: 'http://localhost:5173',
  //   reuseExistingServer: !process.env.CI,
  //   timeout: 120 * 1000,
  // },
})
