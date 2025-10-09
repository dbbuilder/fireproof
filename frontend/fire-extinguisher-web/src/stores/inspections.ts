import { defineStore } from 'pinia'
import inspectionService from '@/services/inspectionService'
import type {
  InspectionDto,
  CreateInspectionRequest,
  InspectionVerificationResponse,
  InspectionStatsDto
} from '@/types/api'

interface InspectionFilters {
  extinguisherId?: string
  inspectorUserId?: string
  startDate?: string
  endDate?: string
  inspectionType?: string
  passed?: boolean
}

interface InspectionState {
  inspections: InspectionDto[]
  currentInspection: InspectionDto | null
  stats: InspectionStatsDto | null
  loading: boolean
  error: string | null
}

export const useInspectionStore = defineStore('inspections', {
  state: (): InspectionState => ({
    inspections: [],
    currentInspection: null,
    stats: null,
    loading: false,
    error: null
  }),

  getters: {
    passedInspections: (state): InspectionDto[] => {
      return state.inspections.filter(inspection => inspection.passed)
    },

    failedInspections: (state): InspectionDto[] => {
      return state.inspections.filter(inspection => !inspection.passed)
    },

    inspectionsRequiringService: (state): InspectionDto[] => {
      return state.inspections.filter(inspection => inspection.requiresService)
    },

    inspectionsRequiringReplacement: (state): InspectionDto[] => {
      return state.inspections.filter(inspection => inspection.requiresReplacement)
    },

    inspectionCount: (state): number => state.inspections.length,

    getInspectionById: (state) => (id: string): InspectionDto | undefined => {
      return state.inspections.find(inspection => inspection.inspectionId === id)
    },

    /**
     * Get inspections grouped by extinguisher
     */
    inspectionsByExtinguisher: (state): Record<string, InspectionDto[]> => {
      const grouped: Record<string, InspectionDto[]> = {}
      state.inspections.forEach(inspection => {
        const key = inspection.extinguisherCode || inspection.extinguisherId
        if (!grouped[key]) {
          grouped[key] = []
        }
        grouped[key].push(inspection)
      })
      return grouped
    },

    /**
     * Get inspections grouped by inspector
     */
    inspectionsByInspector: (state): Record<string, InspectionDto[]> => {
      const grouped: Record<string, InspectionDto[]> = {}
      state.inspections.forEach(inspection => {
        const key = inspection.inspectorName || inspection.inspectorUserId
        if (!grouped[key]) {
          grouped[key] = []
        }
        grouped[key].push(inspection)
      })
      return grouped
    },

    /**
     * Get inspections grouped by type
     */
    inspectionsByType: (state): Record<string, InspectionDto[]> => {
      const grouped: Record<string, InspectionDto[]> = {}
      state.inspections.forEach(inspection => {
        const type = inspection.inspectionType || 'Unknown'
        if (!grouped[type]) {
          grouped[type] = []
        }
        grouped[type].push(inspection)
      })
      return grouped
    },

    /**
     * Get recent inspections (last 30 days)
     */
    recentInspections: (state): InspectionDto[] => {
      const thirtyDaysAgo = new Date()
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)

      return state.inspections.filter(inspection => {
        const inspectionDate = new Date(inspection.inspectionDate)
        return inspectionDate >= thirtyDaysAgo
      }).sort((a, b) => new Date(b.inspectionDate).getTime() - new Date(a.inspectionDate).getTime())
    },

    /**
     * Get pass rate as percentage
     */
    passRatePercentage: (state): number => {
      if (state.inspections.length === 0) return 0
      const passedCount = state.inspections.filter(i => i.passed).length
      return (passedCount / state.inspections.length) * 100
    }
  },

  actions: {
    async createInspection(inspectionData: CreateInspectionRequest): Promise<InspectionDto> {
      this.loading = true
      this.error = null

      try {
        const newInspection = await inspectionService.create(inspectionData)
        this.inspections.push(newInspection)
        this.currentInspection = newInspection
        return newInspection
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to create inspection'
        console.error('Error creating inspection:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchInspections(filters?: InspectionFilters): Promise<void> {
      this.loading = true
      this.error = null

      try {
        this.inspections = await inspectionService.getAll(filters)
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch inspections'
        console.error('Error fetching inspections:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchInspectionById(id: string): Promise<InspectionDto> {
      this.loading = true
      this.error = null

      try {
        this.currentInspection = await inspectionService.getById(id)
        return this.currentInspection
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch inspection'
        console.error('Error fetching inspection:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchExtinguisherHistory(extinguisherId: string): Promise<InspectionDto[]> {
      this.loading = true
      this.error = null

      try {
        const history = await inspectionService.getExtinguisherHistory(extinguisherId)
        // Update local state with these inspections
        history.forEach(inspection => {
          const index = this.inspections.findIndex(i => i.inspectionId === inspection.inspectionId)
          if (index === -1) {
            this.inspections.push(inspection)
          }
        })
        return history
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch extinguisher history'
        console.error('Error fetching extinguisher history:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchInspectorInspections(
      inspectorUserId: string,
      startDate?: string,
      endDate?: string
    ): Promise<InspectionDto[]> {
      this.loading = true
      this.error = null

      try {
        return await inspectionService.getInspectorInspections(inspectorUserId, startDate, endDate)
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch inspector inspections'
        console.error('Error fetching inspector inspections:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async verifyInspectionIntegrity(inspectionId: string): Promise<InspectionVerificationResponse> {
      this.loading = true
      this.error = null

      try {
        const verificationResult = await inspectionService.verifyIntegrity(inspectionId)

        // Update inspection IsVerified status if it's in our state
        const index = this.inspections.findIndex(i => i.inspectionId === inspectionId)
        if (index !== -1) {
          this.inspections[index] = {
            ...this.inspections[index],
            isVerified: verificationResult.isValid
          }
        }

        if (this.currentInspection?.inspectionId === inspectionId) {
          this.currentInspection = {
            ...this.currentInspection,
            isVerified: verificationResult.isValid
          }
        }

        return verificationResult
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to verify inspection integrity'
        console.error('Error verifying inspection integrity:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchStats(startDate?: string, endDate?: string): Promise<InspectionStatsDto> {
      this.loading = true
      this.error = null

      try {
        this.stats = await inspectionService.getStats(startDate, endDate)
        return this.stats
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch inspection statistics'
        console.error('Error fetching inspection statistics:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchOverdueInspections(inspectionType: string = 'Monthly'): Promise<InspectionDto[]> {
      this.loading = true
      this.error = null

      try {
        return await inspectionService.getOverdue(inspectionType)
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch overdue inspections'
        console.error('Error fetching overdue inspections:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async deleteInspection(id: string): Promise<void> {
      this.loading = true
      this.error = null

      try {
        await inspectionService.delete(id)

        // Remove from local state
        this.inspections = this.inspections.filter(inspection => inspection.inspectionId !== id)

        if (this.currentInspection?.inspectionId === id) {
          this.currentInspection = null
        }
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to delete inspection'
        console.error('Error deleting inspection:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    clearError(): void {
      this.error = null
    },

    clearStats(): void {
      this.stats = null
    }
  }
})
