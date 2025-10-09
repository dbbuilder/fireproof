import { defineStore } from 'pinia'
import extinguisherTypeService from '@/services/extinguisherTypeService'
import type {
  ExtinguisherTypeDto,
  CreateExtinguisherTypeRequest,
  UpdateExtinguisherTypeRequest
} from '@/types/api'

interface ExtinguisherTypeState {
  types: ExtinguisherTypeDto[]
  currentType: ExtinguisherTypeDto | null
  loading: boolean
  error: string | null
}

export const useExtinguisherTypeStore = defineStore('extinguisherTypes', {
  state: (): ExtinguisherTypeState => ({
    types: [],
    currentType: null,
    loading: false,
    error: null
  }),

  getters: {
    activeTypes: (state): ExtinguisherTypeDto[] => {
      return state.types.filter(type => type.isActive)
    },

    typeCount: (state): number => state.types.length,

    getTypeById: (state) => (id: string): ExtinguisherTypeDto | undefined => {
      return state.types.find(type => type.extinguisherTypeId === id)
    },

    /**
     * Get types grouped by agent type
     */
    typesByAgent: (state): Record<string, ExtinguisherTypeDto[]> => {
      const grouped: Record<string, ExtinguisherTypeDto[]> = {}
      state.types.forEach(type => {
        const agent = type.agentType || 'Other'
        if (!grouped[agent]) {
          grouped[agent] = []
        }
        grouped[agent].push(type)
      })
      return grouped
    }
  },

  actions: {
    async fetchTypes(isActive: boolean | null = null): Promise<void> {
      this.loading = true
      this.error = null

      try {
        this.types = await extinguisherTypeService.getAll(isActive)
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch extinguisher types'
        console.error('Error fetching extinguisher types:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchTypeById(id: string): Promise<ExtinguisherTypeDto> {
      this.loading = true
      this.error = null

      try {
        this.currentType = await extinguisherTypeService.getById(id)
        return this.currentType
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch extinguisher type'
        console.error('Error fetching extinguisher type:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async createType(typeData: CreateExtinguisherTypeRequest): Promise<ExtinguisherTypeDto> {
      this.loading = true
      this.error = null

      try {
        const newType = await extinguisherTypeService.create(typeData)
        this.types.push(newType)
        return newType
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to create extinguisher type'
        console.error('Error creating extinguisher type:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async updateType(id: string, typeData: UpdateExtinguisherTypeRequest): Promise<ExtinguisherTypeDto> {
      this.loading = true
      this.error = null

      try {
        const updatedType = await extinguisherTypeService.update(id, typeData)

        // Update in local state
        const index = this.types.findIndex(type => type.extinguisherTypeId === id)
        if (index !== -1) {
          this.types[index] = updatedType
        }

        if (this.currentType?.extinguisherTypeId === id) {
          this.currentType = updatedType
        }

        return updatedType
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to update extinguisher type'
        console.error('Error updating extinguisher type:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async deleteType(id: string): Promise<void> {
      this.loading = true
      this.error = null

      try {
        await extinguisherTypeService.delete(id)

        // Remove from local state
        this.types = this.types.filter(type => type.extinguisherTypeId !== id)

        if (this.currentType?.extinguisherTypeId === id) {
          this.currentType = null
        }
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to delete extinguisher type'
        console.error('Error deleting extinguisher type:', error)
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
