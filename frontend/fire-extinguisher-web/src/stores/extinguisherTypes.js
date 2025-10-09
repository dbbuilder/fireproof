import { defineStore } from 'pinia'
import extinguisherTypeService from '@/services/extinguisherTypeService'

export const useExtinguisherTypeStore = defineStore('extinguisherTypes', {
  state: () => ({
    types: [],
    currentType: null,
    loading: false,
    error: null
  }),

  getters: {
    activeTypes: (state) => {
      return state.types.filter(type => type.isActive)
    },

    typeCount: (state) => state.types.length,

    getTypeById: (state) => (id) => {
      return state.types.find(type => type.extinguisherTypeId === id)
    },

    /**
     * Get types grouped by agent type
     */
    typesByAgent: (state) => {
      const grouped = {}
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
    async fetchTypes(isActive = null) {
      this.loading = true
      this.error = null

      try {
        this.types = await extinguisherTypeService.getAll(isActive)
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to fetch extinguisher types'
        console.error('Error fetching extinguisher types:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchTypeById(id) {
      this.loading = true
      this.error = null

      try {
        this.currentType = await extinguisherTypeService.getById(id)
        return this.currentType
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to fetch extinguisher type'
        console.error('Error fetching extinguisher type:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async createType(typeData) {
      this.loading = true
      this.error = null

      try {
        const newType = await extinguisherTypeService.create(typeData)
        this.types.push(newType)
        return newType
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to create extinguisher type'
        console.error('Error creating extinguisher type:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async updateType(id, typeData) {
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
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to update extinguisher type'
        console.error('Error updating extinguisher type:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async deleteType(id) {
      this.loading = true
      this.error = null

      try {
        await extinguisherTypeService.delete(id)

        // Remove from local state
        this.types = this.types.filter(type => type.extinguisherTypeId !== id)

        if (this.currentType?.extinguisherTypeId === id) {
          this.currentType = null
        }
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to delete extinguisher type'
        console.error('Error deleting extinguisher type:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    clearError() {
      this.error = null
    }
  }
})
