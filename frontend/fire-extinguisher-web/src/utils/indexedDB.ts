/**
 * IndexedDB Wrapper for Offline Storage
 * Provides structured storage for inspections, photos, and queue items
 * Mobile-optimized for offline inspection workflow
 */

const DB_NAME = 'FireProofDB'
const DB_VERSION = 1

// Object Store Names
export const STORES = {
  INSPECTIONS: 'inspections',
  INSPECTION_RESPONSES: 'inspection_responses',
  PHOTOS: 'photos',
  UPLOAD_QUEUE: 'upload_queue',
  SYNC_QUEUE: 'sync_queue',
  TEMPLATES: 'templates',
  EXTINGUISHERS: 'extinguishers'
} as const

export interface QueueItem {
  id: string
  type: 'inspection' | 'photo' | 'response' | 'deficiency'
  action: 'create' | 'update' | 'delete'
  data: any
  retryCount: number
  lastError?: string
  timestamp: number
  status: 'pending' | 'processing' | 'failed'
}

export interface PhotoQueueItem {
  id: string
  inspectionId: string
  photoType: string
  blob: Blob
  captureDate?: string
  retryCount: number
  timestamp: number
  status: 'pending' | 'uploading' | 'failed' | 'uploaded'
  uploadedPhotoId?: string
  error?: string
}

class IndexedDBManager {
  private db: IDBDatabase | null = null
  private initPromise: Promise<void> | null = null

  /**
   * Initialize the database with object stores
   */
  async init(): Promise<void> {
    if (this.initPromise) {
      return this.initPromise
    }

    this.initPromise = new Promise((resolve, reject) => {
      const request = indexedDB.open(DB_NAME, DB_VERSION)

      request.onerror = () => {
        console.error('IndexedDB initialization error:', request.error)
        reject(request.error)
      }

      request.onsuccess = () => {
        this.db = request.result
        console.log('IndexedDB initialized successfully')
        resolve()
      }

      request.onupgradeneeded = (event: IDBVersionChangeEvent) => {
        const db = (event.target as IDBOpenDBRequest).result

        // Inspections store (drafts and pending sync)
        if (!db.objectStoreNames.contains(STORES.INSPECTIONS)) {
          const inspectionStore = db.createObjectStore(STORES.INSPECTIONS, { keyPath: 'inspectionId' })
          inspectionStore.createIndex('status', 'status', { unique: false })
          inspectionStore.createIndex('timestamp', 'timestamp', { unique: false })
        }

        // Inspection responses store (checklist responses)
        if (!db.objectStoreNames.contains(STORES.INSPECTION_RESPONSES)) {
          const responsesStore = db.createObjectStore(STORES.INSPECTION_RESPONSES, { keyPath: 'id', autoIncrement: true })
          responsesStore.createIndex('inspectionId', 'inspectionId', { unique: false })
        }

        // Photos store (blob storage for pending uploads)
        if (!db.objectStoreNames.contains(STORES.PHOTOS)) {
          const photoStore = db.createObjectStore(STORES.PHOTOS, { keyPath: 'id' })
          photoStore.createIndex('inspectionId', 'inspectionId', { unique: false })
          photoStore.createIndex('status', 'status', { unique: false })
          photoStore.createIndex('timestamp', 'timestamp', { unique: false })
        }

        // Upload queue (for photos)
        if (!db.objectStoreNames.contains(STORES.UPLOAD_QUEUE)) {
          const uploadQueue = db.createObjectStore(STORES.UPLOAD_QUEUE, { keyPath: 'id' })
          uploadQueue.createIndex('status', 'status', { unique: false })
          uploadQueue.createIndex('timestamp', 'timestamp', { unique: false })
        }

        // Sync queue (for inspection operations)
        if (!db.objectStoreNames.contains(STORES.SYNC_QUEUE)) {
          const syncQueue = db.createObjectStore(STORES.SYNC_QUEUE, { keyPath: 'id' })
          syncQueue.createIndex('type', 'type', { unique: false })
          syncQueue.createIndex('status', 'status', { unique: false })
          syncQueue.createIndex('timestamp', 'timestamp', { unique: false })
        }

        // Templates cache (for offline template access)
        if (!db.objectStoreNames.contains(STORES.TEMPLATES)) {
          const templateStore = db.createObjectStore(STORES.TEMPLATES, { keyPath: 'templateId' })
          templateStore.createIndex('inspectionType', 'inspectionType', { unique: false })
        }

        // Extinguishers cache (for offline extinguisher selection)
        if (!db.objectStoreNames.contains(STORES.EXTINGUISHERS)) {
          const extinguisherStore = db.createObjectStore(STORES.EXTINGUISHERS, { keyPath: 'extinguisherId' })
          extinguisherStore.createIndex('locationId', 'locationId', { unique: false })
        }

        console.log('IndexedDB object stores created')
      }
    })

    return this.initPromise
  }

  /**
   * Generic get operation
   */
  async get<T>(storeName: string, key: string): Promise<T | null> {
    await this.init()
    if (!this.db) throw new Error('Database not initialized')

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([storeName], 'readonly')
      const store = transaction.objectStore(storeName)
      const request = store.get(key)

      request.onsuccess = () => resolve(request.result || null)
      request.onerror = () => reject(request.error)
    })
  }

  /**
   * Generic getAll operation
   */
  async getAll<T>(storeName: string): Promise<T[]> {
    await this.init()
    if (!this.db) throw new Error('Database not initialized')

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([storeName], 'readonly')
      const store = transaction.objectStore(storeName)
      const request = store.getAll()

      request.onsuccess = () => resolve(request.result || [])
      request.onerror = () => reject(request.error)
    })
  }

  /**
   * Generic getByIndex operation
   */
  async getByIndex<T>(storeName: string, indexName: string, value: any): Promise<T[]> {
    await this.init()
    if (!this.db) throw new Error('Database not initialized')

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([storeName], 'readonly')
      const store = transaction.objectStore(storeName)
      const index = store.index(indexName)
      const request = index.getAll(value)

      request.onsuccess = () => resolve(request.result || [])
      request.onerror = () => reject(request.error)
    })
  }

  /**
   * Generic put operation
   */
  async put(storeName: string, data: any): Promise<void> {
    await this.init()
    if (!this.db) throw new Error('Database not initialized')

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([storeName], 'readwrite')
      const store = transaction.objectStore(storeName)
      const request = store.put(data)

      request.onsuccess = () => resolve()
      request.onerror = () => reject(request.error)
    })
  }

  /**
   * Generic delete operation
   */
  async delete(storeName: string, key: string): Promise<void> {
    await this.init()
    if (!this.db) throw new Error('Database not initialized')

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([storeName], 'readwrite')
      const store = transaction.objectStore(storeName)
      const request = store.delete(key)

      request.onsuccess = () => resolve()
      request.onerror = () => reject(request.error)
    })
  }

  /**
   * Clear all data from a store
   */
  async clear(storeName: string): Promise<void> {
    await this.init()
    if (!this.db) throw new Error('Database not initialized')

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([storeName], 'readwrite')
      const store = transaction.objectStore(storeName)
      const request = store.clear()

      request.onsuccess = () => resolve()
      request.onerror = () => reject(request.error)
    })
  }

  /**
   * Count items in a store
   */
  async count(storeName: string): Promise<number> {
    await this.init()
    if (!this.db) throw new Error('Database not initialized')

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([storeName], 'readonly')
      const store = transaction.objectStore(storeName)
      const request = store.count()

      request.onsuccess = () => resolve(request.result)
      request.onerror = () => reject(request.error)
    })
  }

  /**
   * Close the database connection
   */
  close(): void {
    if (this.db) {
      this.db.close()
      this.db = null
      this.initPromise = null
    }
  }
}

// Singleton instance
export const db = new IndexedDBManager()

// Convenience methods for common operations

/**
 * Save inspection draft to IndexedDB
 */
export async function saveInspectionDraft(inspection: any): Promise<void> {
  await db.put(STORES.INSPECTIONS, {
    ...inspection,
    timestamp: Date.now(),
    status: 'draft'
  })
}

/**
 * Get inspection draft from IndexedDB
 */
export async function getInspectionDraft(inspectionId: string): Promise<any | null> {
  return db.get(STORES.INSPECTIONS, inspectionId)
}

/**
 * Save photo to upload queue
 */
export async function queuePhotoUpload(item: PhotoQueueItem): Promise<void> {
  await db.put(STORES.UPLOAD_QUEUE, item)
}

/**
 * Get pending photo uploads
 */
export async function getPendingPhotoUploads(): Promise<PhotoQueueItem[]> {
  return db.getByIndex<PhotoQueueItem>(STORES.UPLOAD_QUEUE, 'status', 'pending')
}

/**
 * Queue sync operation
 */
export async function queueSyncOperation(item: QueueItem): Promise<void> {
  await db.put(STORES.SYNC_QUEUE, item)
}

/**
 * Get pending sync operations
 */
export async function getPendingSyncOperations(): Promise<QueueItem[]> {
  return db.getByIndex<QueueItem>(STORES.SYNC_QUEUE, 'status', 'pending')
}

/**
 * Cache template for offline access
 */
export async function cacheTemplate(template: any): Promise<void> {
  await db.put(STORES.TEMPLATES, template)
}

/**
 * Get cached templates
 */
export async function getCachedTemplates(): Promise<any[]> {
  return db.getAll(STORES.TEMPLATES)
}

/**
 * Cache extinguisher for offline access
 */
export async function cacheExtinguisher(extinguisher: any): Promise<void> {
  await db.put(STORES.EXTINGUISHERS, extinguisher)
}

/**
 * Get cached extinguishers
 */
export async function getCachedExtinguishers(): Promise<any[]> {
  return db.getAll(STORES.EXTINGUISHERS)
}

/**
 * Clear all offline data (useful for logout)
 */
export async function clearAllOfflineData(): Promise<void> {
  await Promise.all([
    db.clear(STORES.INSPECTIONS),
    db.clear(STORES.INSPECTION_RESPONSES),
    db.clear(STORES.PHOTOS),
    db.clear(STORES.UPLOAD_QUEUE),
    db.clear(STORES.SYNC_QUEUE),
    db.clear(STORES.TEMPLATES),
    db.clear(STORES.EXTINGUISHERS)
  ])
}

export default db
