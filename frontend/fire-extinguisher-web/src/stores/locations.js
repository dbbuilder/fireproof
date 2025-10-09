import { defineStore } from 'pinia'
import locationService from '@/services/locationService'

export const useLocationStore = defineStore('locations', {
  state: () => ({
    locations: [],
    currentLocation: null,
    loading: false,
    error: null
  }),

  getters: {
    activeLocations: (state) => {
      return state.locations.filter(loc => loc.isActive)
    },

    locationCount: (state) => state.locations.length,

    getLocationById: (state) => (id) => {
      return state.locations.find(loc => loc.locationId === id)
    }
  },

  actions: {
    async fetchLocations(isActive = null) {
      this.loading = true
      this.error = null

      try {
        this.locations = await locationService.getAll(isActive)
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to fetch locations'
        console.error('Error fetching locations:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchLocationById(id) {
      this.loading = true
      this.error = null

      try {
        this.currentLocation = await locationService.getById(id)
        return this.currentLocation
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to fetch location'
        console.error('Error fetching location:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async createLocation(locationData) {
      this.loading = true
      this.error = null

      try {
        const newLocation = await locationService.create(locationData)
        this.locations.push(newLocation)
        return newLocation
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to create location'
        console.error('Error creating location:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async updateLocation(id, locationData) {
      this.loading = true
      this.error = null

      try {
        const updatedLocation = await locationService.update(id, locationData)

        // Update in local state
        const index = this.locations.findIndex(loc => loc.locationId === id)
        if (index !== -1) {
          this.locations[index] = updatedLocation
        }

        if (this.currentLocation?.locationId === id) {
          this.currentLocation = updatedLocation
        }

        return updatedLocation
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to update location'
        console.error('Error updating location:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async deleteLocation(id) {
      this.loading = true
      this.error = null

      try {
        await locationService.delete(id)

        // Remove from local state
        this.locations = this.locations.filter(loc => loc.locationId !== id)

        if (this.currentLocation?.locationId === id) {
          this.currentLocation = null
        }
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to delete location'
        console.error('Error deleting location:', error)
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
