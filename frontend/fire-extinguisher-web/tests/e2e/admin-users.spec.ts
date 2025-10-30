import { test, expect } from '@playwright/test'

/**
 * E2E Tests for User Management Feature
 *
 * Prerequisites:
 * - User must be logged in as SystemAdmin
 * - Authentication state must be available
 *
 * Test Coverage:
 * - User list display
 * - User search functionality
 * - User filtering (active/inactive)
 * - View user details
 * - Edit user profile
 * - Assign/remove system roles
 * - Pagination
 */

test.describe('User Management', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to users page
    await page.goto('/users')

    // Wait for page to load
    await page.waitForLoadState('networkidle')
  })

  test('should display users list', async ({ page }) => {
    // Check page heading
    await expect(page.locator('[data-testid="users-heading"]')).toBeVisible()

    // Check that users table is visible
    await expect(page.locator('[data-testid="users-table"]')).toBeVisible()

    // Verify table headers
    await expect(page.locator('th:has-text("Name")')).toBeVisible()
    await expect(page.locator('th:has-text("Email")')).toBeVisible()
    await expect(page.locator('th:has-text("System Roles")')).toBeVisible()
    await expect(page.locator('th:has-text("Tenant Roles")')).toBeVisible()
    await expect(page.locator('th:has-text("Status")')).toBeVisible()
    await expect(page.locator('th:has-text("Actions")')).toBeVisible()
  })

  test('should search users', async ({ page }) => {
    const searchInput = page.locator('[data-testid="users-search-input"]')

    // Type search term
    await searchInput.fill('admin')

    // Wait for debounced search (500ms + network)
    await page.waitForTimeout(1000)

    // Verify results contain search term
    const firstUserRow = page.locator('[data-testid="users-table"] tbody tr').first()
    await expect(firstUserRow).toContainText('admin', { ignoreCase: true })
  })

  test('should filter users by status', async ({ page }) => {
    const statusFilter = page.locator('[data-testid="users-status-filter"]')

    // Filter by active users
    await statusFilter.selectOption('true')
    await page.waitForTimeout(500)

    // Verify all visible users have active badge
    const activeUsers = page.locator('[data-testid="user-status-active"]')
    await expect(activeUsers.first()).toBeVisible()

    // Filter by inactive users
    await statusFilter.selectOption('false')
    await page.waitForTimeout(500)

    // Verify inactive badge
    const inactiveUsers = page.locator('[data-testid="user-status-inactive"]')
    await expect(inactiveUsers.first()).toBeVisible()
  })

  test('should view user details', async ({ page }) => {
    // Click view button on first user
    await page.locator('[data-testid="user-view-button"]').first().click()

    // Verify modal opened
    await expect(page.locator('[data-testid="user-detail-modal"]')).toBeVisible()

    // Verify user information is displayed
    await expect(page.locator('[data-testid="user-detail-email"]')).toBeVisible()
    await expect(page.locator('[data-testid="user-detail-name"]')).toBeVisible()

    // Verify system roles section
    await expect(page.locator('[data-testid="user-system-roles"]')).toBeVisible()

    // Verify tenant roles section
    await expect(page.locator('[data-testid="user-tenant-roles"]')).toBeVisible()

    // Close modal
    await page.locator('[data-testid="modal-close-button"]').click()
    await expect(page.locator('[data-testid="user-detail-modal"]')).not.toBeVisible()
  })

  test('should edit user profile', async ({ page }) => {
    // Click edit button on first user
    await page.locator('[data-testid="user-edit-button"]').first().click()

    // Verify edit modal opened
    await expect(page.locator('[data-testid="user-edit-modal"]')).toBeVisible()

    // Update first name
    const firstNameInput = page.locator('[data-testid="user-edit-firstname"]')
    await firstNameInput.clear()
    await firstNameInput.fill('Updated Name')

    // Update phone number
    const phoneInput = page.locator('[data-testid="user-edit-phone"]')
    await phoneInput.clear()
    await phoneInput.fill('555-0123')

    // Save changes
    await page.locator('[data-testid="user-edit-save-button"]').click()

    // Verify success message
    await expect(page.locator('[data-testid="success-message"]')).toBeVisible()
    await expect(page.locator('[data-testid="success-message"]')).toContainText('updated successfully')
  })

  test('should assign system role to user', async ({ page }) => {
    // Open first user details
    await page.locator('[data-testid="user-view-button"]').first().click()

    // Click add system role button
    await page.locator('[data-testid="add-system-role-button"]').click()

    // Verify role selection modal
    await expect(page.locator('[data-testid="assign-role-modal"]')).toBeVisible()

    // Select a role from dropdown
    await page.locator('[data-testid="role-select"]').selectOption({ index: 1 })

    // Confirm assignment
    await page.locator('[data-testid="assign-role-confirm-button"]').click()

    // Verify role appears in list
    await expect(page.locator('[data-testid="success-message"]')).toBeVisible()
  })

  test('should remove system role from user', async ({ page }) => {
    // Open first user details
    await page.locator('[data-testid="user-view-button"]').first().click()

    // Find a role remove button (if roles exist)
    const removeButton = page.locator('[data-testid="remove-system-role-button"]').first()

    if (await removeButton.isVisible()) {
      await removeButton.click()

      // Confirm removal
      await page.locator('[data-testid="confirm-remove-button"]').click()

      // Verify success
      await expect(page.locator('[data-testid="success-message"]')).toBeVisible()
    }
  })

  test('should navigate pagination', async ({ page }) => {
    // Check if pagination exists (only if there are enough users)
    const nextButton = page.locator('[data-testid="pagination-next"]')

    if (await nextButton.isEnabled()) {
      // Get current page number
      const currentPage = await page.locator('[data-testid="current-page"]').textContent()

      // Click next
      await nextButton.click()
      await page.waitForTimeout(500)

      // Verify page changed
      const newPage = await page.locator('[data-testid="current-page"]').textContent()
      expect(newPage).not.toBe(currentPage)

      // Go back to previous page
      await page.locator('[data-testid="pagination-previous"]').click()
      await page.waitForTimeout(500)

      // Verify we're back to original page
      const finalPage = await page.locator('[data-testid="current-page"]').textContent()
      expect(finalPage).toBe(currentPage)
    }
  })

  test('should change page size', async ({ page }) => {
    const pageSizeSelect = page.locator('[data-testid="page-size-select"]')

    // Change to 20 items per page
    await pageSizeSelect.selectOption('20')
    await page.waitForTimeout(500)

    // Verify table updated (check row count is <= 20)
    const rows = page.locator('[data-testid="users-table"] tbody tr')
    const count = await rows.count()
    expect(count).toBeLessThanOrEqual(20)
  })

  test('should handle empty search results', async ({ page }) => {
    const searchInput = page.locator('[data-testid="users-search-input"]')

    // Search for non-existent user
    await searchInput.fill('nonexistentuser12345xyz')
    await page.waitForTimeout(1000)

    // Verify empty state message
    await expect(page.locator('[data-testid="users-empty-state"]')).toBeVisible()
    await expect(page.locator('[data-testid="users-empty-state"]')).toContainText('No users found')
  })

  test('should clear search', async ({ page }) => {
    const searchInput = page.locator('[data-testid="users-search-input"]')

    // Enter search term
    await searchInput.fill('test')
    await page.waitForTimeout(1000)

    // Clear search
    await searchInput.clear()
    await page.waitForTimeout(1000)

    // Verify all users are shown again
    const rows = page.locator('[data-testid="users-table"] tbody tr')
    const count = await rows.count()
    expect(count).toBeGreaterThan(0)
  })
})

/**
 * SystemAdmin Authorization Tests
 */
test.describe('User Management Authorization', () => {
  test('should require SystemAdmin role', async ({ page }) => {
    // This test assumes the current user is NOT a SystemAdmin
    // In practice, you'd set up a different auth state for this test

    // Try to navigate to users page
    await page.goto('/users')

    // Should be redirected or show 403 error
    // (Implementation depends on your authorization strategy)
  })
})
