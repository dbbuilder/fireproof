import { defineStore } from 'pinia'
import inspectionPhase1Service from '@/services/inspectionPhase1Service'
import type {
  InspectionPhase1Dto,
  CreateInspectionPhase1Request,
  UpdateInspectionPhase1Request,
  CompleteInspectionRequest,
  InspectionChecklistResponseDto,
  SaveChecklistResponsesRequest,
  InspectionPhase1VerificationResponse,
  InspectionPhase1StatsDto
} from '@/types/api'

interface InspectionPhase1State {
  inspections: InspectionPhase1Dto[]
  currentInspection: InspectionPhase1Dto | null
  checklistResponses: Record<string, InspectionChecklistResponseDto[]> // Keyed by inspectionId
  stats: InspectionPhase1StatsDto | null
  loading: boolean
  error: string | null
}

export const useInspectionPhase1Store = defineStore('inspectionsPhase1', {
  state: (): InspectionPhase1State => ({
    inspections: [],
    currentInspection: null,
    checklistResponses: {},
    stats: null,
    loading: false,
    error: null
  }),

  getters: {
    inspectionCount: (state): number => state.inspections.length,

    getInspectionById: (state) => (id: string): InspectionPhase1Dto | undefined => {
      return state.inspections.find(inspection => inspection.inspectionId === id)
    },

    /**
     * Get inspections by status
     */
    getInspectionsByStatus: (state) => (status: string): InspectionPhase1Dto[] => {
      return state.inspections.filter(inspection => inspection.status === status)
    },

    /**
     * Get inspections grouped by status
     */
    inspectionsByStatus: (state): Record<string, InspectionPhase1Dto[]> => {
      const grouped: Record<string, InspectionPhase1Dto[]> = {}
      state.inspections.forEach(inspection => {
        const status = inspection.status
        if (!grouped[status]) {
          grouped[status] = []
        }
        grouped[status].push(inspection)
      })
      return grouped
    },

    /**
     * Get in-progress inspections
     */
    inProgressInspections: (state): InspectionPhase1Dto[] => {
      return state.inspections.filter(inspection => inspection.status === 'InProgress')
    },

    /**
     * Get completed inspections
     */
    completedInspections: (state): InspectionPhase1Dto[] => {
      return state.inspections.filter(inspection => inspection.status === 'Completed')
    },

    /**
     * Get scheduled inspections
     */
    scheduledInspections: (state): InspectionPhase1Dto[] => {
      return state.inspections.filter(inspection => inspection.status === 'Scheduled')
    },

    /**
     * Get passed inspections
     */
    passedInspections: (state): InspectionPhase1Dto[] => {
      return state.inspections.filter(inspection => inspection.overallResult === 'Pass')
    },

    /**
     * Get failed inspections
     */
    failedInspections: (state): InspectionPhase1Dto[] => {
      return state.inspections.filter(inspection => inspection.overallResult === 'Fail')
    },

    /**
     * Get checklist responses for a specific inspection
     */
    getResponsesForInspection: (state) => (inspectionId: string): InspectionChecklistResponseDto[] | undefined => {
      return state.checklistResponses[inspectionId]
    }
  },

  actions: {
    async fetchInspections(filters: {
      extinguisherId?: string | null
      inspectorUserId?: string | null
      startDate?: string | null
      endDate?: string | null
      status?: string | null
      inspectionType?: string | null
    } = {}): Promise<void> {
      this.loading = true
      this.error = null

      try {
        this.inspections = await inspectionPhase1Service.getAll(filters)
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch inspections'
        console.error('Error fetching inspections:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchInspectionById(id: string, includeDetails: boolean = true): Promise<InspectionPhase1Dto> {
      this.loading = true
      this.error = null

      try {
        this.currentInspection = await inspectionPhase1Service.getById(id, includeDetails)

        // Store checklist responses if included
        if (this.currentInspection.checklistResponses) {
          this.checklistResponses[id] = this.currentInspection.checklistResponses
        }

        return this.currentInspection
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch inspection'
        console.error('Error fetching inspection:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async createInspection(inspectionData: CreateInspectionPhase1Request): Promise<InspectionPhase1Dto> {
      this.loading = true
      this.error = null

      try {
        const newInspection = await inspectionPhase1Service.create(inspectionData)
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

    async updateInspection(id: string, inspectionData: UpdateInspectionPhase1Request): Promise<InspectionPhase1Dto> {
      this.loading = true
      this.error = null

      try {
        const updatedInspection = await inspectionPhase1Service.update(id, inspectionData)

        // Update in local state
        const index = this.inspections.findIndex(inspection => inspection.inspectionId === id)
        if (index !== -1) {
          this.inspections[index] = updatedInspection
        }

        if (this.currentInspection?.inspectionId === id) {
          this.currentInspection = updatedInspection
        }

        return updatedInspection
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to update inspection'
        console.error('Error updating inspection:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async completeInspection(id: string, completionData: CompleteInspectionRequest): Promise<InspectionPhase1Dto> {
      this.loading = true
      this.error = null

      try {
        const completedInspection = await inspectionPhase1Service.complete(id, completionData)

        // Update in local state
        const index = this.inspections.findIndex(inspection => inspection.inspectionId === id)
        if (index !== -1) {
          this.inspections[index] = completedInspection
        }

        if (this.currentInspection?.inspectionId === id) {
          this.currentInspection = completedInspection
        }

        return completedInspection
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to complete inspection'
        console.error('Error completing inspection:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async deleteInspection(id: string): Promise<void> {
      this.loading = true
      this.error = null

      try {
        await inspectionPhase1Service.delete(id)

        // Remove from local state
        this.inspections = this.inspections.filter(inspection => inspection.inspectionId !== id)

        if (this.currentInspection?.inspectionId === id) {
          this.currentInspection = null
        }

        // Remove checklist responses
        delete this.checklistResponses[id]
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to delete inspection'
        console.error('Error deleting inspection:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async saveChecklistResponses(
      inspectionId: string,
      responsesData: SaveChecklistResponsesRequest
    ): Promise<InspectionChecklistResponseDto[]> {
      this.loading = true
      this.error = null

      try {
        const responses = await inspectionPhase1Service.saveChecklistResponses(inspectionId, responsesData)
        this.checklistResponses[inspectionId] = responses
        return responses
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to save checklist responses'
        console.error('Error saving checklist responses:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchChecklistResponses(inspectionId: string): Promise<InspectionChecklistResponseDto[]> {
      this.loading = true
      this.error = null

      try {
        const responses = await inspectionPhase1Service.getChecklistResponses(inspectionId)
        this.checklistResponses[inspectionId] = responses
        return responses
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch checklist responses'
        console.error('Error fetching checklist responses:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchExtinguisherHistory(extinguisherId: string, limit: number = 20): Promise<InspectionPhase1Dto[]> {
      this.loading = true
      this.error = null

      try {
        const history = await inspectionPhase1Service.getExtinguisherHistory(extinguisherId, limit)
        // Merge with existing inspections (avoid duplicates)
        history.forEach(inspection => {
          const index = this.inspections.findIndex(i => i.inspectionId === inspection.inspectionId)
          if (index === -1) {
            this.inspections.push(inspection)
          } else {
            this.inspections[index] = inspection
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
      filters: {
        startDate?: string | null
        endDate?: string | null
        status?: string | null
      } = {}
    ): Promise<InspectionPhase1Dto[]> {
      this.loading = true
      this.error = null

      try {
        const inspections = await inspectionPhase1Service.getInspectorInspections(inspectorUserId, filters)
        // Merge with existing inspections (avoid duplicates)
        inspections.forEach(inspection => {
          const index = this.inspections.findIndex(i => i.inspectionId === inspection.inspectionId)
          if (index === -1) {
            this.inspections.push(inspection)
          } else {
            this.inspections[index] = inspection
          }
        })
        return inspections
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch inspector inspections'
        console.error('Error fetching inspector inspections:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchDueInspections(startDate?: string | null, endDate?: string | null): Promise<InspectionPhase1Dto[]> {
      this.loading = true
      this.error = null

      try {
        const inspections = await inspectionPhase1Service.getDueInspections(startDate, endDate)
        // Merge with existing inspections (avoid duplicates)
        inspections.forEach(inspection => {
          const index = this.inspections.findIndex(i => i.inspectionId === inspection.inspectionId)
          if (index === -1) {
            this.inspections.push(inspection)
          } else {
            this.inspections[index] = inspection
          }
        })
        return inspections
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch due inspections'
        console.error('Error fetching due inspections:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchScheduledInspections(startDate?: string | null, endDate?: string | null): Promise<InspectionPhase1Dto[]> {
      this.loading = true
      this.error = null

      try {
        const inspections = await inspectionPhase1Service.getScheduledInspections(startDate, endDate)
        // Merge with existing inspections (avoid duplicates)
        inspections.forEach(inspection => {
          const index = this.inspections.findIndex(i => i.inspectionId === inspection.inspectionId)
          if (index === -1) {
            this.inspections.push(inspection)
          } else {
            this.inspections[index] = inspection
          }
        })
        return inspections
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch scheduled inspections'
        console.error('Error fetching scheduled inspections:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async verifyIntegrity(inspectionId: string): Promise<InspectionPhase1VerificationResponse> {
      this.loading = true
      this.error = null

      try {
        const verification = await inspectionPhase1Service.verifyIntegrity(inspectionId)
        return verification
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to verify inspection integrity'
        console.error('Error verifying inspection integrity:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchStats(
      startDate?: string | null,
      endDate?: string | null,
      inspectorUserId?: string | null
    ): Promise<InspectionPhase1StatsDto> {
      this.loading = true
      this.error = null

      try {
        this.stats = await inspectionPhase1Service.getStats(startDate, endDate, inspectorUserId)
        return this.stats
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch inspection stats'
        console.error('Error fetching inspection stats:', error)
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
