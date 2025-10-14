import { defineStore } from 'pinia'
import deficiencyService from '@/services/deficiencyService'
import type {
  InspectionDeficiencyDto,
  CreateDeficiencyRequest,
  UpdateDeficiencyRequest,
  ResolveDeficiencyRequest
} from '@/types/api'

interface DeficiencyState {
  deficiencies: InspectionDeficiencyDto[]
  currentDeficiency: InspectionDeficiencyDto | null
  loading: boolean
  error: string | null
}

export const useDeficiencyStore = defineStore('deficiencies', {
  state: (): DeficiencyState => ({
    deficiencies: [],
    currentDeficiency: null,
    loading: false,
    error: null
  }),

  getters: {
    deficiencyCount: (state): number => state.deficiencies.length,

    getDeficiencyById: (state) => (id: string): InspectionDeficiencyDto | undefined => {
      return state.deficiencies.find(deficiency => deficiency.deficiencyId === id)
    },

    /**
     * Get deficiencies by status
     */
    getDeficienciesByStatus: (state) => (status: string): InspectionDeficiencyDto[] => {
      return state.deficiencies.filter(deficiency => deficiency.status === status)
    },

    /**
     * Get open deficiencies (unresolved)
     */
    openDeficiencies: (state): InspectionDeficiencyDto[] => {
      return state.deficiencies.filter(deficiency => deficiency.status === 'Open' || deficiency.status === 'InProgress')
    },

    /**
     * Get resolved deficiencies
     */
    resolvedDeficiencies: (state): InspectionDeficiencyDto[] => {
      return state.deficiencies.filter(deficiency => deficiency.status === 'Resolved')
    },

    /**
     * Get deficiencies by severity
     */
    getDeficienciesBySeverity: (state) => (severity: string): InspectionDeficiencyDto[] => {
      return state.deficiencies.filter(deficiency => deficiency.severity === severity)
    },

    /**
     * Get critical deficiencies
     */
    criticalDeficiencies: (state): InspectionDeficiencyDto[] => {
      return state.deficiencies.filter(deficiency => deficiency.severity === 'Critical')
    },

    /**
     * Get high severity deficiencies
     */
    highSeverityDeficiencies: (state): InspectionDeficiencyDto[] => {
      return state.deficiencies.filter(deficiency => deficiency.severity === 'High')
    },

    /**
     * Get deficiencies grouped by severity
     */
    deficienciesBySeverity: (state): Record<string, InspectionDeficiencyDto[]> => {
      const grouped: Record<string, InspectionDeficiencyDto[]> = {}
      state.deficiencies.forEach(deficiency => {
        const severity = deficiency.severity
        if (!grouped[severity]) {
          grouped[severity] = []
        }
        grouped[severity].push(deficiency)
      })
      return grouped
    },

    /**
     * Get deficiencies grouped by status
     */
    deficienciesByStatus: (state): Record<string, InspectionDeficiencyDto[]> => {
      const grouped: Record<string, InspectionDeficiencyDto[]> = {}
      state.deficiencies.forEach(deficiency => {
        const status = deficiency.status
        if (!grouped[status]) {
          grouped[status] = []
        }
        grouped[status].push(deficiency)
      })
      return grouped
    },

    /**
     * Get overdue deficiencies
     */
    overdueDeficiencies: (state): InspectionDeficiencyDto[] => {
      const now = new Date()
      return state.deficiencies.filter(deficiency => {
        if (!deficiency.dueDate || deficiency.status === 'Resolved') return false
        const dueDate = new Date(deficiency.dueDate)
        return dueDate < now
      })
    }
  },

  actions: {
    async createDeficiency(deficiencyData: CreateDeficiencyRequest): Promise<InspectionDeficiencyDto> {
      this.loading = true
      this.error = null

      try {
        const newDeficiency = await deficiencyService.create(deficiencyData)
        this.deficiencies.push(newDeficiency)
        return newDeficiency
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to create deficiency'
        console.error('Error creating deficiency:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchDeficiencyById(id: string): Promise<InspectionDeficiencyDto> {
      this.loading = true
      this.error = null

      try {
        this.currentDeficiency = await deficiencyService.getById(id)
        return this.currentDeficiency
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch deficiency'
        console.error('Error fetching deficiency:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async updateDeficiency(id: string, deficiencyData: UpdateDeficiencyRequest): Promise<InspectionDeficiencyDto> {
      this.loading = true
      this.error = null

      try {
        const updatedDeficiency = await deficiencyService.update(id, deficiencyData)

        // Update in local state
        const index = this.deficiencies.findIndex(deficiency => deficiency.deficiencyId === id)
        if (index !== -1) {
          this.deficiencies[index] = updatedDeficiency
        }

        if (this.currentDeficiency?.deficiencyId === id) {
          this.currentDeficiency = updatedDeficiency
        }

        return updatedDeficiency
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to update deficiency'
        console.error('Error updating deficiency:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async resolveDeficiency(id: string, resolutionData: ResolveDeficiencyRequest): Promise<InspectionDeficiencyDto> {
      this.loading = true
      this.error = null

      try {
        const resolvedDeficiency = await deficiencyService.resolve(id, resolutionData)

        // Update in local state
        const index = this.deficiencies.findIndex(deficiency => deficiency.deficiencyId === id)
        if (index !== -1) {
          this.deficiencies[index] = resolvedDeficiency
        }

        if (this.currentDeficiency?.deficiencyId === id) {
          this.currentDeficiency = resolvedDeficiency
        }

        return resolvedDeficiency
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to resolve deficiency'
        console.error('Error resolving deficiency:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async deleteDeficiency(id: string): Promise<void> {
      this.loading = true
      this.error = null

      try {
        await deficiencyService.delete(id)

        // Remove from local state
        this.deficiencies = this.deficiencies.filter(deficiency => deficiency.deficiencyId !== id)

        if (this.currentDeficiency?.deficiencyId === id) {
          this.currentDeficiency = null
        }
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to delete deficiency'
        console.error('Error deleting deficiency:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchDeficienciesByInspection(inspectionId: string): Promise<InspectionDeficiencyDto[]> {
      this.loading = true
      this.error = null

      try {
        const deficiencies = await deficiencyService.getByInspection(inspectionId)
        // Merge with existing deficiencies (avoid duplicates)
        deficiencies.forEach(deficiency => {
          const index = this.deficiencies.findIndex(d => d.deficiencyId === deficiency.deficiencyId)
          if (index === -1) {
            this.deficiencies.push(deficiency)
          } else {
            this.deficiencies[index] = deficiency
          }
        })
        return deficiencies
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch deficiencies by inspection'
        console.error('Error fetching deficiencies by inspection:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchOpenDeficiencies(startDate?: string | null, endDate?: string | null): Promise<InspectionDeficiencyDto[]> {
      this.loading = true
      this.error = null

      try {
        this.deficiencies = await deficiencyService.getOpen(startDate, endDate)
        return this.deficiencies
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch open deficiencies'
        console.error('Error fetching open deficiencies:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchDeficienciesBySeverity(
      severity: string,
      startDate?: string | null,
      endDate?: string | null
    ): Promise<InspectionDeficiencyDto[]> {
      this.loading = true
      this.error = null

      try {
        const deficiencies = await deficiencyService.getBySeverity(severity, startDate, endDate)
        // Merge with existing deficiencies (avoid duplicates)
        deficiencies.forEach(deficiency => {
          const index = this.deficiencies.findIndex(d => d.deficiencyId === deficiency.deficiencyId)
          if (index === -1) {
            this.deficiencies.push(deficiency)
          } else {
            this.deficiencies[index] = deficiency
          }
        })
        return deficiencies
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch deficiencies by severity'
        console.error('Error fetching deficiencies by severity:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchDeficienciesByAssignee(userId: string, openOnly: boolean = true): Promise<InspectionDeficiencyDto[]> {
      this.loading = true
      this.error = null

      try {
        const deficiencies = await deficiencyService.getByAssignee(userId, openOnly)
        // Merge with existing deficiencies (avoid duplicates)
        deficiencies.forEach(deficiency => {
          const index = this.deficiencies.findIndex(d => d.deficiencyId === deficiency.deficiencyId)
          if (index === -1) {
            this.deficiencies.push(deficiency)
          } else {
            this.deficiencies[index] = deficiency
          }
        })
        return deficiencies
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch deficiencies by assignee'
        console.error('Error fetching deficiencies by assignee:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    clearError(): void {
      this.error = null
    }
  }
})
