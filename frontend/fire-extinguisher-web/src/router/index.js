import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useInspectorStore } from '@/stores/useInspectorStore'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    // ============================================
    // Inspector Routes (Subdomain: inspect.fireproofapp.net)
    // ============================================
    {
      path: '/inspector/login',
      name: 'inspector-login',
      component: () => import('../views/inspector/InspectorLoginView.vue'),
      meta: { requiresInspectorGuest: true }
    },
    {
      path: '/inspector',
      component: () => import('../views/inspector/InspectorLayoutView.vue'),
      meta: { requiresInspector: true },
      children: [
        {
          path: 'dashboard',
          name: 'inspector-dashboard',
          component: () => import('../views/inspector/InspectorDashboardView.vue'),
          meta: { requiresInspector: true }
        },
        {
          path: 'scan-location',
          name: 'inspector-scan-location',
          component: () => import('../views/inspector/ScanLocationView.vue'),
          meta: { requiresInspector: true }
        },
        {
          path: 'scan-extinguisher',
          name: 'inspector-scan-extinguisher',
          component: () => import('../views/inspector/ScanExtinguisherView.vue'),
          meta: { requiresInspector: true }
        }
        // Additional inspector routes to be added:
        // - inspection-checklist
        // - inspection-photos
        // - inspection-signature
      ]
    },

    // ============================================
    // Admin Routes (Main App)
    // ============================================
    {
      path: '/',
      name: 'home',
      component: () => import('../views/HomeView.vue'),
      meta: { requiresGuest: true }
    },
    {
      path: '/login',
      name: 'login',
      component: () => import('../views/LoginView.vue'),
      meta: { requiresGuest: true }
    },
    {
      path: '/register',
      name: 'register',
      component: () => import('../views/RegisterView.vue'),
      meta: { requiresGuest: true }
    },
    {
      path: '/select-tenant',
      name: 'select-tenant',
      component: () => import('../views/TenantSelectorView.vue'),
      meta: { requiresAuth: true, skipTenantCheck: true }
    },
    {
      path: '/dashboard',
      name: 'dashboard',
      component: () => import('../views/DashboardView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/locations',
      name: 'locations',
      component: () => import('../views/LocationsView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/extinguishers',
      name: 'extinguishers',
      component: () => import('../views/ExtinguishersViewGrid.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/extinguishers-cards',
      name: 'extinguishers-cards',
      component: () => import('../views/ExtinguishersView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/extinguisher-types',
      name: 'extinguisher-types',
      component: () => import('../views/ExtinguisherTypesView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/inspections',
      name: 'inspections',
      component: () => import('../views/InspectionsView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/inspections/new',
      name: 'inspection-create',
      component: () => import('../views/InspectionPhase1CreateView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/inspections/:id',
      name: 'inspection-detail',
      component: () => import('../views/InspectionPhase1DetailView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/inspections/:id/checklist',
      name: 'inspection-checklist',
      component: () => import('../views/InspectionPhase1ChecklistView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/inspections/:id/complete',
      name: 'inspection-complete',
      component: () => import('../views/InspectionPhase1CompleteView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/reports',
      name: 'reports',
      component: () => import('../views/ReportsView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/settings',
      name: 'settings',
      component: () => import('../views/SettingsView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/profile',
      name: 'profile',
      component: () => import('../views/ProfileView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/:pathMatch(.*)*',
      name: 'not-found',
      component: () => import('../views/NotFoundView.vue')
    }
  ]
})

// Track if auth initialization has been attempted
let authInitStarted = false

// Navigation guard for authentication
router.beforeEach(async (to, from, next) => {
  // ============================================
  // Inspector Routes Guard
  // ============================================
  const isInspectorRoute = to.path.startsWith('/inspector')

  if (isInspectorRoute) {
    const inspectorStore = useInspectorStore()

    // Protect inspector routes that require authentication
    if (to.meta.requiresInspector && !inspectorStore.isAuthenticated) {
      next({
        name: 'inspector-login',
        query: { redirect: to.fullPath }
      })
      return
    }

    // Redirect authenticated inspectors away from login page
    if (to.meta.requiresInspectorGuest && inspectorStore.isAuthenticated) {
      next({ name: 'inspector-dashboard' })
      return
    }

    next()
    return
  }

  // ============================================
  // Admin Routes Guard
  // ============================================
  const authStore = useAuthStore()

  // Initialize auth on first navigation if needed, but don't block
  if (!authInitStarted && !authStore.isAuthenticated && authStore.accessToken) {
    authInitStarted = true
    // Initialize in background - don't block navigation
    authStore.initializeAuth().catch(() => {
      // Silent failure - auth store handles cleanup
    })
  }

  const isAuthenticated = authStore.isLoggedIn

  // Protect routes that require authentication
  if (to.meta.requiresAuth && !isAuthenticated) {
    next({
      name: 'login',
      query: { redirect: to.fullPath }
    })
    return
  }

  // Check if tenant selection is needed (SystemAdmin or multi-tenant users without tenant selected)
  if (
    isAuthenticated &&
    to.meta.requiresAuth &&
    !to.meta.skipTenantCheck &&
    authStore.needsTenantSelection
  ) {
    next({
      name: 'select-tenant',
      query: { redirect: to.fullPath }
    })
    return
  }

  // Redirect authenticated users away from guest-only pages (login, register)
  if (to.meta.requiresGuest && isAuthenticated) {
    // Check if they need to select a tenant first
    if (authStore.needsTenantSelection) {
      next({ name: 'select-tenant' })
    } else {
      next({ name: 'dashboard' })
    }
    return
  }

  next()
})

export default router
