import { defineStore } from 'pinia'
import locationService from '@/services/locationService'
import type { LocationDto, CreateLocationRequest, UpdateLocationRequest } from '@/types/api'

interface LocationState {
  locations: LocationDto[]
  currentLocation: LocationDto | null
  loading: boolean
  error: string | null
}

export const useLocationStore = defineStore('locations', {
  state: (): LocationState => ({
    locations: [],
    currentLocation: null,
    loading: false,
    error: null
  }),

  getters: {
    activeLocations: (state): LocationDto[] => {
      return state.locations.filter(location => location.isActive)
    },

    locationCount: (state): number => state.locations.length,

    getLocationById: (state) => (id: string): LocationDto | undefined => {
      return state.locations.find(location => location.locationId === id)
    },

    /**
     * Get locations grouped by city
     */
    locationsByCity: (state): Record<string, LocationDto[]> => {
      const grouped: Record<string, LocationDto[]> = {}
      state.locations.forEach(location => {
        const city = location.city || 'Unknown'
        if (!grouped[city]) {
          grouped[city] = []
        }
        grouped[city].push(location)
      })
      return grouped
    },

    /**
     * Get locations grouped by state/province
     */
    locationsByState: (state): Record<string, LocationDto[]> => {
      const grouped: Record<string, LocationDto[]> = {}
      state.locations.forEach(location => {
        const state = location.stateProvince || 'Unknown'
        if (!grouped[state]) {
          grouped[state] = []
        }
        grouped[state].push(location)
      })
      return grouped
    }
  },

  actions: {
    async fetchLocations(isActive: boolean | null = null): Promise<void> {
      this.loading = true
      this.error = null

      try {
        this.locations = await locationService.getAll(isActive)
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch locations'
        console.error('Error fetching locations:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchLocationById(id: string): Promise<LocationDto> {
      this.loading = true
      this.error = null

      try {
        this.currentLocation = await locationService.getById(id)
        return this.currentLocation
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch location'
        console.error('Error fetching location:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async createLocation(locationData: CreateLocationRequest): Promise<LocationDto> {
      this.loading = true
      this.error = null

      try {
        const newLocation = await locationService.create(locationData)
        this.locations.push(newLocation)
        return newLocation
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to create location'
        console.error('Error creating location:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async updateLocation(id: string, locationData: UpdateLocationRequest): Promise<LocationDto> {
      this.loading = true
      this.error = null

      try {
        const updatedLocation = await locationService.update(id, locationData)

        // Update in local state
        const index = this.locations.findIndex(location => location.locationId === id)
        if (index !== -1) {
          this.locations[index] = updatedLocation
        }

        if (this.currentLocation?.locationId === id) {
          this.currentLocation = updatedLocation
        }

        return updatedLocation
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to update location'
        console.error('Error updating location:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async deleteLocation(id: string): Promise<void> {
      this.loading = true
      this.error = null

      try {
        await locationService.delete(id)

        // Remove from local state
        this.locations = this.locations.filter(location => location.locationId !== id)

        if (this.currentLocation?.locationId === id) {
          this.currentLocation = null
        }
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to delete location'
        console.error('Error deleting location:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async generateLocationBarcode(id: string): Promise<string> {
      this.loading = true
      this.error = null

      try {
        const barcodeData = await locationService.generateBarcode(id)

        // Update location in state if we have it
        const index = this.locations.findIndex(location => location.locationId === id)
        if (index !== -1) {
          this.locations[index] = {
            ...this.locations[index],
            locationBarcodeData: barcodeData
          }
        }

        if (this.currentLocation?.locationId === id) {
          this.currentLocation = {
            ...this.currentLocation,
            locationBarcodeData: barcodeData
          }
        }

        return barcodeData
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to generate barcode'
        console.error('Error generating barcode:', error)
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
