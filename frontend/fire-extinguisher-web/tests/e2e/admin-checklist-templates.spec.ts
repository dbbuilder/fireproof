import { test, expect } from '../fixtures/authenticated'

/**
 * E2E Tests for Checklist Template Management Feature
 *
 * Prerequisites:
 * - User must be logged in (any authenticated user can view)
 * - TenantAdmin or above required for create/edit/delete
 * - Authentication state must be available
 *
 * Test Coverage:
 * - Template list display with tabs
 * - View system templates (read-only)
 * - Create custom templates
 * - Edit custom templates
 * - Delete custom templates
 * - Duplicate templates (system and custom)
 * - Template item management
 * - Search and filtering
 */

test.describe('Checklist Template Management', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to templates page
    await page.goto('/checklist-templates')

    // Wait for page to load
    await page.waitForLoadState('networkidle')
  })

  test('should display templates page with tabs', async ({ page }) => {
    // Check page heading
    await expect(page.locator('[data-testid="templates-heading"]')).toBeVisible()

    // Verify tab navigation is present
    await expect(page.locator('[data-testid="tab-all"]')).toBeVisible()
    await expect(page.locator('[data-testid="tab-system"]')).toBeVisible()
    await expect(page.locator('[data-testid="tab-custom"]')).toBeVisible()

    // Verify "All Templates" tab is active by default
    await expect(page.locator('[data-testid="tab-all"]')).toHaveClass(/tab-active/)
  })

  test('should show all templates in All tab', async ({ page }) => {
    // Ensure we're on All tab
    await page.locator('[data-testid="tab-all"]').click()

    // Verify template cards are displayed
    const templateCards = page.locator('[data-testid="template-card"]')
    await expect(templateCards.first()).toBeVisible()

    // Verify system templates have system badge
    await expect(page.locator('[data-testid="template-badge-system"]').first()).toBeVisible()
  })

  test('should filter system templates in System tab', async ({ page }) => {
    // Click System tab
    await page.locator('[data-testid="tab-system"]').click()
    await page.waitForTimeout(300)

    // Verify only system templates are shown
    const templateCards = page.locator('[data-testid="template-card"]')
    const count = await templateCards.count()

    // All visible templates should have system badge
    for (let i = 0; i < count; i++) {
      await expect(templateCards.nth(i).locator('[data-testid="template-badge-system"]')).toBeVisible()
    }
  })

  test('should filter custom templates in Custom tab', async ({ page }) => {
    // Click Custom tab
    await page.locator('[data-testid="tab-custom"]').click()
    await page.waitForTimeout(300)

    // Custom templates should have "Custom" badge
    const customBadges = page.locator('[data-testid="template-badge-custom"]')

    // If no custom templates exist, show empty state
    if (await customBadges.count() === 0) {
      await expect(page.locator('[data-testid="templates-empty-state"]')).toBeVisible()
    }
  })

  test('should view system template details', async ({ page }) => {
    // Click System tab
    await page.locator('[data-testid="tab-system"]').click()

    // Click View button on first template
    await page.locator('[data-testid="template-view-button"]').first().click()

    // Verify modal opened
    await expect(page.locator('[data-testid="template-view-modal"]')).toBeVisible()

    // Verify template name
    await expect(page.locator('[data-testid="template-detail-name"]')).toBeVisible()

    // Verify description
    await expect(page.locator('[data-testid="template-detail-description"]')).toBeVisible()

    // Verify checklist items are shown
    await expect(page.locator('[data-testid="template-items-list"]')).toBeVisible()

    // Verify item count
    const itemCount = await page.locator('[data-testid="template-item"]').count()
    expect(itemCount).toBeGreaterThan(0)

    // Close modal
    await page.locator('[data-testid="modal-close-button"]').click()
  })

  test('should create new custom template', async ({ page }) => {
    // Click create button
    await page.locator('[data-testid="create-template-button"]').click()

    // Verify create modal opened
    await expect(page.locator('[data-testid="template-create-modal"]')).toBeVisible()

    // Fill template name
    const templateName = `Test Template ${Date.now()}`
    await page.locator('[data-testid="template-name-input"]').fill(templateName)

    // Fill description
    await page.locator('[data-testid="template-description-input"]').fill('Test template description')

    // Select template type
    await page.locator('[data-testid="template-type-select"]').selectOption('Monthly')

    // Add first checklist item
    await page.locator('[data-testid="add-item-button"]').click()
    await page.locator('[data-testid="item-text-0"]').fill('Check pressure gauge')
    await page.locator('[data-testid="item-required-0"]').check()

    // Add second checklist item
    await page.locator('[data-testid="add-item-button"]').click()
    await page.locator('[data-testid="item-text-1"]').fill('Inspect hose and nozzle')

    // Save template
    await page.locator('[data-testid="template-save-button"]').click()

    // Verify success message
    await expect(page.locator('[data-testid="success-message"]')).toBeVisible()
    await expect(page.locator('[data-testid="success-message"]')).toContainText('created successfully')

    // Verify template appears in custom tab
    await page.locator('[data-testid="tab-custom"]').click()
    await expect(page.locator(`text=${templateName}`)).toBeVisible()
  })

  test('should edit custom template', async ({ page }) => {
    // Navigate to Custom tab
    await page.locator('[data-testid="tab-custom"]').click()

    // Check if custom templates exist
    const templateCards = page.locator('[data-testid="template-card"]')
    if (await templateCards.count() === 0) {
      test.skip()
      return
    }

    // Click edit button on first custom template
    await page.locator('[data-testid="template-edit-button"]').first().click()

    // Verify edit modal opened
    await expect(page.locator('[data-testid="template-edit-modal"]')).toBeVisible()

    // Update template name
    const updatedName = `Updated Template ${Date.now()}`
    const nameInput = page.locator('[data-testid="template-name-input"]')
    await nameInput.clear()
    await nameInput.fill(updatedName)

    // Update description
    const descInput = page.locator('[data-testid="template-description-input"]')
    await descInput.clear()
    await descInput.fill('Updated description')

    // Save changes
    await page.locator('[data-testid="template-save-button"]').click()

    // Verify success
    await expect(page.locator('[data-testid="success-message"]')).toBeVisible()
  })

  test('should not allow editing system templates', async ({ page }) => {
    // Click System tab
    await page.locator('[data-testid="tab-system"]').click()

    // Verify edit button is not present for system templates
    const editButtons = page.locator('[data-testid="template-edit-button"]')
    expect(await editButtons.count()).toBe(0)

    // Verify view button is present
    await expect(page.locator('[data-testid="template-view-button"]').first()).toBeVisible()
  })

  test('should duplicate system template', async ({ page }) => {
    // Click System tab
    await page.locator('[data-testid="tab-system"]').click()

    // Click duplicate button on first system template
    await page.locator('[data-testid="template-duplicate-button"]').first().click()

    // Verify duplicate modal
    await expect(page.locator('[data-testid="template-duplicate-modal"]')).toBeVisible()

    // Enter new template name
    const newName = `Duplicated Template ${Date.now()}`
    await page.locator('[data-testid="duplicate-name-input"]').fill(newName)

    // Confirm duplication
    await page.locator('[data-testid="duplicate-confirm-button"]').click()

    // Verify success
    await expect(page.locator('[data-testid="success-message"]')).toBeVisible()

    // Verify duplicated template appears in custom tab
    await page.locator('[data-testid="tab-custom"]').click()
    await expect(page.locator(`text=${newName}`)).toBeVisible()
  })

  test('should duplicate custom template', async ({ page }) => {
    // Navigate to Custom tab
    await page.locator('[data-testid="tab-custom"]').click()

    // Check if custom templates exist
    const templateCards = page.locator('[data-testid="template-card"]')
    if (await templateCards.count() === 0) {
      test.skip()
      return
    }

    // Get original template name
    const originalName = await templateCards.first().locator('h3').textContent()

    // Click duplicate button
    await page.locator('[data-testid="template-duplicate-button"]').first().click()

    // Enter new name
    const newName = `${originalName} (Copy 2)`
    await page.locator('[data-testid="duplicate-name-input"]').fill(newName)

    // Confirm
    await page.locator('[data-testid="duplicate-confirm-button"]').click()

    // Verify success
    await expect(page.locator('[data-testid="success-message"]')).toBeVisible()
  })

  test('should delete custom template', async ({ page }) => {
    // Navigate to Custom tab
    await page.locator('[data-testid="tab-custom"]').click()

    // Check if custom templates exist
    const templateCards = page.locator('[data-testid="template-card"]')
    const initialCount = await templateCards.count()

    if (initialCount === 0) {
      test.skip()
      return
    }

    // Click delete button on last custom template
    await page.locator('[data-testid="template-delete-button"]').last().click()

    // Verify confirmation modal
    await expect(page.locator('[data-testid="delete-confirm-modal"]')).toBeVisible()

    // Confirm deletion
    await page.locator('[data-testid="confirm-delete-button"]').click()

    // Verify success
    await expect(page.locator('[data-testid="success-message"]')).toBeVisible()

    // Verify template count decreased
    await page.waitForTimeout(500)
    const newCount = await page.locator('[data-testid="template-card"]').count()
    expect(newCount).toBe(initialCount - 1)
  })

  test('should not allow deleting system templates', async ({ page }) => {
    // Click System tab
    await page.locator('[data-testid="tab-system"]').click()

    // Verify delete button is not present for system templates
    const deleteButtons = page.locator('[data-testid="template-delete-button"]')
    expect(await deleteButtons.count()).toBe(0)
  })

  test('should display template item count', async ({ page }) => {
    // Get first template card
    const firstCard = page.locator('[data-testid="template-card"]').first()

    // Verify item count badge is visible
    await expect(firstCard.locator('[data-testid="template-item-count"]')).toBeVisible()

    // Verify format (e.g., "12 items")
    const countText = await firstCard.locator('[data-testid="template-item-count"]').textContent()
    expect(countText).toMatch(/\d+ items?/)
  })

  test('should display template type badges', async ({ page }) => {
    // Check different template types
    const templates = page.locator('[data-testid="template-card"]')
    const count = await templates.count()

    // Verify at least one template has a type badge
    let foundBadge = false
    for (let i = 0; i < count; i++) {
      const badge = templates.nth(i).locator('[data-testid="template-type-badge"]')
      if (await badge.isVisible()) {
        foundBadge = true
        break
      }
    }

    expect(foundBadge).toBe(true)
  })

  test('should show required items in template details', async ({ page }) => {
    // View first template
    await page.locator('[data-testid="template-view-button"]').first().click()

    // Find required items
    const requiredItems = page.locator('[data-testid="item-required-badge"]')

    // If required items exist, verify they're marked
    if (await requiredItems.count() > 0) {
      await expect(requiredItems.first()).toBeVisible()
      await expect(requiredItems.first()).toContainText('Required')
    }
  })

  test('should handle empty custom templates state', async ({ page }) => {
    // Navigate to Custom tab
    await page.locator('[data-testid="tab-custom"]').click()

    // If no custom templates, should show empty state
    const templateCards = page.locator('[data-testid="template-card"]')

    if (await templateCards.count() === 0) {
      await expect(page.locator('[data-testid="templates-empty-state"]')).toBeVisible()
      await expect(page.locator('[data-testid="templates-empty-state"]')).toContainText('No custom templates')
    }
  })
})

/**
 * Template Validation Tests
 */
test.describe('Checklist Template Validation', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/checklist-templates')
    await page.waitForLoadState('networkidle')
  })

  test('should validate required template name', async ({ page }) => {
    // Click create button
    await page.locator('[data-testid="create-template-button"]').click()

    // Try to save without name
    await page.locator('[data-testid="template-save-button"]').click()

    // Verify validation error
    await expect(page.locator('[data-testid="name-error"]')).toBeVisible()
    await expect(page.locator('[data-testid="name-error"]')).toContainText('required')
  })

  test('should require at least one checklist item', async ({ page }) => {
    // Click create button
    await page.locator('[data-testid="create-template-button"]').click()

    // Fill required fields
    await page.locator('[data-testid="template-name-input"]').fill('Test Template')

    // Try to save without items
    await page.locator('[data-testid="template-save-button"]').click()

    // Verify validation error
    await expect(page.locator('[data-testid="items-error"]')).toBeVisible()
  })
})
