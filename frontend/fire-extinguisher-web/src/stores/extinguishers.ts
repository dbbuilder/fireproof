import { defineStore } from 'pinia'
import extinguisherService from '@/services/extinguisherService'
import type {
  ExtinguisherDto,
  CreateExtinguisherRequest,
  UpdateExtinguisherRequest,
  BarcodeResponse
} from '@/types/api'

interface ExtinguisherFilters {
  locationId?: string
  typeId?: string
  isActive?: boolean
  isOutOfService?: boolean
}

interface ExtinguisherState {
  extinguishers: ExtinguisherDto[]
  currentExtinguisher: ExtinguisherDto | null
  loading: boolean
  error: string | null
}

export const useExtinguisherStore = defineStore('extinguishers', {
  state: (): ExtinguisherState => ({
    extinguishers: [],
    currentExtinguisher: null,
    loading: false,
    error: null
  }),

  getters: {
    activeExtinguishers: (state): ExtinguisherDto[] => {
      return state.extinguishers.filter(ext => ext.isActive && !ext.isOutOfService)
    },

    outOfServiceExtinguishers: (state): ExtinguisherDto[] => {
      return state.extinguishers.filter(ext => ext.isOutOfService)
    },

    extinguisherCount: (state): number => state.extinguishers.length,

    getExtinguisherById: (state) => (id: string): ExtinguisherDto | undefined => {
      return state.extinguishers.find(ext => ext.extinguisherId === id)
    },

    /**
     * Get extinguishers grouped by location
     */
    extinguishersByLocation: (state): Record<string, ExtinguisherDto[]> => {
      const grouped: Record<string, ExtinguisherDto[]> = {}
      state.extinguishers.forEach(ext => {
        const location = ext.locationName || 'Unknown'
        if (!grouped[location]) {
          grouped[location] = []
        }
        grouped[location].push(ext)
      })
      return grouped
    },

    /**
     * Get extinguishers grouped by type
     */
    extinguishersByType: (state): Record<string, ExtinguisherDto[]> => {
      const grouped: Record<string, ExtinguisherDto[]> = {}
      state.extinguishers.forEach(ext => {
        const type = ext.typeName || 'Unknown'
        if (!grouped[type]) {
          grouped[type] = []
        }
        grouped[type].push(ext)
      })
      return grouped
    },

    /**
     * Get extinguishers needing attention (service or hydro test due soon)
     */
    needingAttention: (state): ExtinguisherDto[] => {
      const now = new Date()
      const thirtyDaysFromNow = new Date()
      thirtyDaysFromNow.setDate(now.getDate() + 30)

      return state.extinguishers.filter(ext => {
        if (!ext.isActive || ext.isOutOfService) return false

        const nextService = ext.nextServiceDueDate ? new Date(ext.nextServiceDueDate) : null
        const nextHydro = ext.nextHydroTestDueDate ? new Date(ext.nextHydroTestDueDate) : null

        const serviceDue = nextService && nextService <= thirtyDaysFromNow
        const hydroDue = nextHydro && nextHydro <= thirtyDaysFromNow

        return serviceDue || hydroDue
      })
    }
  },

  actions: {
    async fetchExtinguishers(filters?: ExtinguisherFilters): Promise<void> {
      this.loading = true
      this.error = null

      try {
        this.extinguishers = await extinguisherService.getAll(filters)
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch extinguishers'
        console.error('Error fetching extinguishers:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchExtinguisherById(id: string): Promise<ExtinguisherDto> {
      this.loading = true
      this.error = null

      try {
        this.currentExtinguisher = await extinguisherService.getById(id)
        return this.currentExtinguisher
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch extinguisher'
        console.error('Error fetching extinguisher:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchExtinguisherByBarcode(barcodeData: string): Promise<ExtinguisherDto> {
      this.loading = true
      this.error = null

      try {
        this.currentExtinguisher = await extinguisherService.getByBarcode(barcodeData)
        return this.currentExtinguisher
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch extinguisher by barcode'
        console.error('Error fetching extinguisher by barcode:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async createExtinguisher(extinguisherData: CreateExtinguisherRequest): Promise<ExtinguisherDto> {
      this.loading = true
      this.error = null

      try {
        const newExtinguisher = await extinguisherService.create(extinguisherData)
        this.extinguishers.push(newExtinguisher)
        return newExtinguisher
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to create extinguisher'
        console.error('Error creating extinguisher:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async updateExtinguisher(id: string, extinguisherData: UpdateExtinguisherRequest): Promise<ExtinguisherDto> {
      this.loading = true
      this.error = null

      try {
        const updatedExtinguisher = await extinguisherService.update(id, extinguisherData)

        // Update in local state
        const index = this.extinguishers.findIndex(ext => ext.extinguisherId === id)
        if (index !== -1) {
          this.extinguishers[index] = updatedExtinguisher
        }

        if (this.currentExtinguisher?.extinguisherId === id) {
          this.currentExtinguisher = updatedExtinguisher
        }

        return updatedExtinguisher
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to update extinguisher'
        console.error('Error updating extinguisher:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async deleteExtinguisher(id: string): Promise<void> {
      this.loading = true
      this.error = null

      try {
        await extinguisherService.delete(id)

        // Remove from local state
        this.extinguishers = this.extinguishers.filter(ext => ext.extinguisherId !== id)

        if (this.currentExtinguisher?.extinguisherId === id) {
          this.currentExtinguisher = null
        }
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to delete extinguisher'
        console.error('Error deleting extinguisher:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async generateBarcode(id: string): Promise<BarcodeResponse> {
      this.loading = true
      this.error = null

      try {
        const barcodeResponse = await extinguisherService.generateBarcode(id)

        // Update extinguisher in state with new barcode data
        const index = this.extinguishers.findIndex(ext => ext.extinguisherId === id)
        if (index !== -1) {
          this.extinguishers[index] = {
            ...this.extinguishers[index],
            barcodeData: barcodeResponse.barcodeData,
            qrCodeData: barcodeResponse.qrCodeData
          }
        }

        if (this.currentExtinguisher?.extinguisherId === id) {
          this.currentExtinguisher = {
            ...this.currentExtinguisher,
            barcodeData: barcodeResponse.barcodeData,
            qrCodeData: barcodeResponse.qrCodeData
          }
        }

        return barcodeResponse
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to generate barcode'
        console.error('Error generating barcode:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async markOutOfService(id: string, reason: string): Promise<ExtinguisherDto> {
      this.loading = true
      this.error = null

      try {
        const updatedExtinguisher = await extinguisherService.markOutOfService(id, reason)

        // Update in local state
        const index = this.extinguishers.findIndex(ext => ext.extinguisherId === id)
        if (index !== -1) {
          this.extinguishers[index] = updatedExtinguisher
        }

        if (this.currentExtinguisher?.extinguisherId === id) {
          this.currentExtinguisher = updatedExtinguisher
        }

        return updatedExtinguisher
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to mark extinguisher out of service'
        console.error('Error marking extinguisher out of service:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async returnToService(id: string): Promise<ExtinguisherDto> {
      this.loading = true
      this.error = null

      try {
        const updatedExtinguisher = await extinguisherService.returnToService(id)

        // Update in local state
        const index = this.extinguishers.findIndex(ext => ext.extinguisherId === id)
        if (index !== -1) {
          this.extinguishers[index] = updatedExtinguisher
        }

        if (this.currentExtinguisher?.extinguisherId === id) {
          this.currentExtinguisher = updatedExtinguisher
        }

        return updatedExtinguisher
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to return extinguisher to service'
        console.error('Error returning extinguisher to service:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchNeedingService(daysAhead: number = 30): Promise<ExtinguisherDto[]> {
      this.loading = true
      this.error = null

      try {
        return await extinguisherService.getNeedingService(daysAhead)
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch extinguishers needing service'
        console.error('Error fetching extinguishers needing service:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchNeedingHydroTest(daysAhead: number = 30): Promise<ExtinguisherDto[]> {
      this.loading = true
      this.error = null

      try {
        return await extinguisherService.getNeedingHydroTest(daysAhead)
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch extinguishers needing hydro test'
        console.error('Error fetching extinguishers needing hydro test:', error)
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
