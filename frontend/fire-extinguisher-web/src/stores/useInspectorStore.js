import { defineStore } from 'pinia'
import { ref } from 'vue'
import api from '@/services/api'

export const useInspectorStore = defineStore('inspector', () => {
  // State
  const user = ref(null)
  const token = ref(localStorage.getItem('inspector_token') || null)
  const isAuthenticated = ref(!!localStorage.getItem('inspector_token'))
  const isLoading = ref(false)
  const error = ref(null)

  // Current inspection context
  const currentLocation = ref(null)
  const currentExtinguisher = ref(null)
  const currentInspection = ref(null)
  const checklistResponses = ref([])

  // Offline queue
  const draftInspections = ref([])
  const isOnline = ref(navigator.onLine)

  /**
   * Login as inspector
   * @param {string} email
   * @param {string} password
   * @returns {Promise<Object>} User object
   */
  async function login(email, password) {
    isLoading.value = true
    error.value = null

    try {
      const response = await api.post('/api/authentication/login', {
        email,
        password
      })

      const { token: authToken, user: userData } = response.data

      // Verify user has Inspector role
      if (!userData.roles || !userData.roles.includes('Inspector')) {
        throw new Error('Access denied. Inspector role required.')
      }

      // Store token and user
      token.value = authToken
      user.value = userData
      isAuthenticated.value = true

      // Persist token
      localStorage.setItem('inspector_token', authToken)
      localStorage.setItem('inspector_user', JSON.stringify(userData))

      // Set default auth header
      api.defaults.headers.common['Authorization'] = `Bearer ${authToken}`

      return userData
    } catch (err) {
      error.value = err.response?.data?.message || err.message || 'Login failed'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Logout inspector
   */
  function logout() {
    token.value = null
    user.value = null
    isAuthenticated.value = false

    // Clear storage
    localStorage.removeItem('inspector_token')
    localStorage.removeItem('inspector_user')

    // Clear auth header
    delete api.defaults.headers.common['Authorization']

    // Clear inspection context
    clearInspectionContext()
  }

  /**
   * Initialize auth from storage
   */
  function initializeAuth() {
    const storedToken = localStorage.getItem('inspector_token')
    const storedUser = localStorage.getItem('inspector_user')

    if (storedToken && storedUser) {
      token.value = storedToken
      user.value = JSON.parse(storedUser)
      isAuthenticated.value = true
      api.defaults.headers.common['Authorization'] = `Bearer ${storedToken}`
    }
  }

  /**
   * Set current location (after scanning)
   */
  function setCurrentLocation(location) {
    currentLocation.value = location
  }

  /**
   * Set current extinguisher (after scanning)
   */
  function setCurrentExtinguisher(extinguisher) {
    currentExtinguisher.value = extinguisher
  }

  /**
   * Start new inspection
   */
  function startInspection(inspection) {
    currentInspection.value = inspection
    checklistResponses.value = []
  }

  /**
   * Add checklist response
   */
  function addChecklistResponse(response) {
    const existingIndex = checklistResponses.value.findIndex(
      r => r.checklistItemId === response.checklistItemId
    )

    if (existingIndex >= 0) {
      checklistResponses.value[existingIndex] = response
    } else {
      checklistResponses.value.push(response)
    }
  }

  /**
   * Save draft inspection to offline queue
   */
  function saveDraft() {
    const draft = {
      id: crypto.randomUUID(),
      location: currentLocation.value,
      extinguisher: currentExtinguisher.value,
      inspection: currentInspection.value,
      responses: [...checklistResponses.value],
      timestamp: Date.now()
    }

    draftInspections.value.push(draft)
    localStorage.setItem('inspector_drafts', JSON.stringify(draftInspections.value))
  }

  /**
   * Clear inspection context
   */
  function clearInspectionContext() {
    currentLocation.value = null
    currentExtinguisher.value = null
    currentInspection.value = null
    checklistResponses.value = []
  }

  /**
   * Update online status
   */
  function updateOnlineStatus(online) {
    isOnline.value = online
  }

  // Initialize auth on store creation
  initializeAuth()

  return {
    // State
    user,
    token,
    isAuthenticated,
    isLoading,
    error,
    currentLocation,
    currentExtinguisher,
    currentInspection,
    checklistResponses,
    draftInspections,
    isOnline,

    // Actions
    login,
    logout,
    initializeAuth,
    setCurrentLocation,
    setCurrentExtinguisher,
    startInspection,
    addChecklistResponse,
    saveDraft,
    clearInspectionContext,
    updateOnlineStatus
  }
})
