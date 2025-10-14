/**
 * Offline Sync Manager
 * Handles synchronization of offline data when connection is restored
 * Mobile-optimized for unreliable network conditions
 */

import {
  db,
  STORES,
  getPendingSyncOperations,
  getPendingPhotoUploads,
  queueSyncOperation,
  queuePhotoUpload,
  type QueueItem,
  type PhotoQueueItem
} from './indexedDB'
import inspectionPhase1Service from '@/services/inspectionPhase1Service'
import photoService from '@/services/photoService'

class OfflineSyncManager {
  private syncInterval: number | null = null
  private isSyncing: boolean = false
  private listeners: Array<(event: SyncEvent) => void> = []

  /**
   * Initialize sync manager with network listeners
   */
  init(): void {
    // Listen for online/offline events
    window.addEventListener('online', () => this.handleOnline())
    window.addEventListener('offline', () => this.handleOffline())

    // Start periodic sync check if online
    if (navigator.onLine) {
      this.startPeriodicSync()
    }

    console.log('OfflineSyncManager initialized', { online: navigator.onLine })
  }

  /**
   * Handle device coming online
   */
  private handleOnline(): void {
    console.log('Device is online - starting sync')
    this.emit({ type: 'online', timestamp: Date.now() })
    this.startPeriodicSync()
    this.syncAll() // Immediate sync when coming online
  }

  /**
   * Handle device going offline
   */
  private handleOffline(): void {
    console.log('Device is offline')
    this.emit({ type: 'offline', timestamp: Date.now() })
    this.stopPeriodicSync()
  }

  /**
   * Start periodic sync check (every 30 seconds)
   */
  private startPeriodicSync(): void {
    if (this.syncInterval) return

    this.syncInterval = window.setInterval(() => {
      if (navigator.onLine && !this.isSyncing) {
        this.syncAll()
      }
    }, 30000) // 30 seconds
  }

  /**
   * Stop periodic sync check
   */
  private stopPeriodicSync(): void {
    if (this.syncInterval) {
      clearInterval(this.syncInterval)
      this.syncInterval = null
    }
  }

  /**
   * Sync all pending operations
   */
  async syncAll(): Promise<void> {
    if (this.isSyncing || !navigator.onLine) {
      return
    }

    this.isSyncing = true
    this.emit({ type: 'sync-start', timestamp: Date.now() })

    try {
      // Sync in order: inspections, responses, photos
      await this.syncInspections()
      await this.syncPhotos()

      this.emit({ type: 'sync-complete', timestamp: Date.now() })
    } catch (error) {
      console.error('Sync error:', error)
      this.emit({ type: 'sync-error', timestamp: Date.now(), error })
    } finally {
      this.isSyncing = false
    }
  }

  /**
   * Sync pending inspection operations
   */
  private async syncInspections(): Promise<void> {
    const pending = await getPendingSyncOperations()

    if (pending.length === 0) {
      return
    }

    console.log(`Syncing ${pending.length} inspection operations`)
    this.emit({
      type: 'sync-progress',
      timestamp: Date.now(),
      message: `Syncing ${pending.length} inspections...`
    })

    for (const item of pending) {
      try {
        await this.syncQueueItem(item)
        await db.delete(STORES.SYNC_QUEUE, item.id)

        this.emit({
          type: 'item-synced',
          timestamp: Date.now(),
          itemType: item.type,
          itemId: item.id
        })
      } catch (error: any) {
        console.error('Error syncing item:', item, error)

        // Update retry count
        item.retryCount++
        item.lastError = error.message
        item.status = item.retryCount >= 3 ? 'failed' : 'pending'

        await db.put(STORES.SYNC_QUEUE, item)

        this.emit({
          type: 'item-failed',
          timestamp: Date.now(),
          itemType: item.type,
          itemId: item.id,
          error
        })
      }
    }
  }

  /**
   * Sync a single queue item
   */
  private async syncQueueItem(item: QueueItem): Promise<void> {
    switch (item.type) {
      case 'inspection':
        return this.syncInspectionItem(item)
      case 'response':
        return this.syncResponseItem(item)
      case 'deficiency':
        return this.syncDeficiencyItem(item)
      default:
        console.warn('Unknown queue item type:', item.type)
    }
  }

  /**
   * Sync inspection item
   */
  private async syncInspectionItem(item: QueueItem): Promise<void> {
    switch (item.action) {
      case 'create':
        await inspectionPhase1Service.create(item.data)
        break
      case 'update':
        await inspectionPhase1Service.update(item.data.inspectionId, item.data)
        break
      case 'delete':
        await inspectionPhase1Service.delete(item.data.inspectionId)
        break
    }
  }

  /**
   * Sync response item
   */
  private async syncResponseItem(item: QueueItem): Promise<void> {
    if (item.action === 'create') {
      await inspectionPhase1Service.saveChecklistResponses(
        item.data.inspectionId,
        item.data
      )
    }
  }

  /**
   * Sync deficiency item
   */
  private async syncDeficiencyItem(item: QueueItem): Promise<void> {
    // TODO: Implement deficiency sync when deficiency service is available
    console.log('Deficiency sync not yet implemented')
  }

  /**
   * Sync pending photo uploads
   */
  private async syncPhotos(): Promise<void> {
    const pending = await getPendingPhotoUploads()

    if (pending.length === 0) {
      return
    }

    console.log(`Syncing ${pending.length} photos`)
    this.emit({
      type: 'sync-progress',
      timestamp: Date.now(),
      message: `Uploading ${pending.length} photos...`
    })

    for (const item of pending) {
      try {
        // Mark as uploading
        item.status = 'uploading'
        await db.put(STORES.UPLOAD_QUEUE, item)

        // Create File from Blob
        const file = new File([item.blob], `photo-${item.id}.jpg`, {
          type: 'image/jpeg'
        })

        // Upload photo
        const response = await photoService.uploadPhoto(
          item.inspectionId,
          item.photoType,
          file,
          item.captureDate || null
        )

        // Mark as uploaded
        item.status = 'uploaded'
        item.uploadedPhotoId = response.photoId
        await db.put(STORES.UPLOAD_QUEUE, item)

        // Remove from queue after short delay (for UI feedback)
        setTimeout(async () => {
          await db.delete(STORES.UPLOAD_QUEUE, item.id)
        }, 2000)

        this.emit({
          type: 'photo-uploaded',
          timestamp: Date.now(),
          photoId: item.id,
          uploadedPhotoId: response.photoId
        })
      } catch (error: any) {
        console.error('Error uploading photo:', item, error)

        // Update retry count
        item.retryCount++
        item.error = error.message
        item.status = item.retryCount >= 3 ? 'failed' : 'pending'

        await db.put(STORES.UPLOAD_QUEUE, item)

        this.emit({
          type: 'photo-failed',
          timestamp: Date.now(),
          photoId: item.id,
          error
        })
      }
    }
  }

  /**
   * Queue inspection for sync
   */
  async queueInspection(action: 'create' | 'update' | 'delete', data: any): Promise<void> {
    const item: QueueItem = {
      id: `inspection-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      type: 'inspection',
      action,
      data,
      retryCount: 0,
      timestamp: Date.now(),
      status: 'pending'
    }

    await queueSyncOperation(item)
    this.emit({ type: 'item-queued', timestamp: Date.now(), itemType: 'inspection' })

    // Attempt immediate sync if online
    if (navigator.onLine) {
      this.syncAll()
    }
  }

  /**
   * Queue photo for upload
   */
  async queuePhoto(
    inspectionId: string,
    photoType: string,
    blob: Blob,
    captureDate?: string
  ): Promise<string> {
    const item: PhotoQueueItem = {
      id: `photo-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      inspectionId,
      photoType,
      blob,
      captureDate,
      retryCount: 0,
      timestamp: Date.now(),
      status: 'pending'
    }

    await queuePhotoUpload(item)
    this.emit({ type: 'photo-queued', timestamp: Date.now(), photoId: item.id })

    // Attempt immediate upload if online
    if (navigator.onLine) {
      this.syncPhotos()
    }

    return item.id
  }

  /**
   * Get sync status
   */
  async getStatus(): Promise<SyncStatus> {
    const [pendingOps, pendingPhotos] = await Promise.all([
      getPendingSyncOperations(),
      getPendingPhotoUploads()
    ])

    return {
      online: navigator.onLine,
      syncing: this.isSyncing,
      pendingOperations: pendingOps.length,
      pendingPhotos: pendingPhotos.length,
      failedOperations: pendingOps.filter(op => op.status === 'failed').length,
      failedPhotos: pendingPhotos.filter(p => p.status === 'failed').length
    }
  }

  /**
   * Add event listener
   */
  on(listener: (event: SyncEvent) => void): void {
    this.listeners.push(listener)
  }

  /**
   * Remove event listener
   */
  off(listener: (event: SyncEvent) => void): void {
    this.listeners = this.listeners.filter(l => l !== listener)
  }

  /**
   * Emit event to all listeners
   */
  private emit(event: SyncEvent): void {
    this.listeners.forEach(listener => {
      try {
        listener(event)
      } catch (error) {
        console.error('Error in sync listener:', error)
      }
    })
  }

  /**
   * Cleanup on destroy
   */
  destroy(): void {
    this.stopPeriodicSync()
    window.removeEventListener('online', () => this.handleOnline())
    window.removeEventListener('offline', () => this.handleOffline())
    this.listeners = []
  }
}

// Types
export interface SyncStatus {
  online: boolean
  syncing: boolean
  pendingOperations: number
  pendingPhotos: number
  failedOperations: number
  failedPhotos: number
}

export interface SyncEvent {
  type:
    | 'online'
    | 'offline'
    | 'sync-start'
    | 'sync-complete'
    | 'sync-error'
    | 'sync-progress'
    | 'item-queued'
    | 'item-synced'
    | 'item-failed'
    | 'photo-queued'
    | 'photo-uploaded'
    | 'photo-failed'
  timestamp: number
  message?: string
  error?: any
  itemType?: string
  itemId?: string
  photoId?: string
  uploadedPhotoId?: string
}

// Singleton instance
export const offlineSync = new OfflineSyncManager()

export default offlineSync
