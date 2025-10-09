# TypeScript Migration - FireProof Frontend

## Overview

The FireProof frontend has been enhanced with TypeScript type definitions to provide compile-time type safety and better developer experience. This document outlines the TypeScript implementation.

## Files Created

### Type Definitions

**`src/types/api.ts`**
- Central location for all API type definitions
- Provides TypeScript interfaces for DTOs, requests, and responses
- Includes type guards for runtime validation
- Supports both Location and ExtinguisherType entities

### TypeScript Services

**`src/services/locationService.ts`**
- Fully typed location management service
- Type-safe API calls with proper return types
- Replaces `locationService.js`

**`src/services/extinguisherTypeService.ts`**
- Fully typed extinguisher type management service
- Type-safe API calls with proper return types
- Replaces `extinguisherTypeService.js`

### TypeScript Stores

**`src/stores/locations.ts`**
- Pinia store with full TypeScript support
- Typed state, getters, and actions
- Replaces `locations.js`

**`src/stores/extinguisherTypes.ts`**
- Pinia store with full TypeScript support
- Typed state, getters, and actions
- Replaces `extinguisherTypes.js`

## Configuration Files

**`tsconfig.json`**
- Main TypeScript configuration
- Enables strict mode for maximum type safety
- Configures path aliases (@/* → src/*)
- ES2020 target with modern JavaScript features

**`tsconfig.node.json`**
- Node-specific TypeScript configuration
- For build tooling (Vite, etc.)

**`package.json` (updated)**
- Added TypeScript dependencies:
  - `typescript`: ^5.3.3
  - `vue-tsc`: ^1.8.27
  - `@types/node`: ^20.10.6

## Type Definitions

### Location Types

```typescript
interface LocationDto {
  locationId: string
  tenantId: string
  locationCode: string
  locationName: string
  addressLine1?: string | null
  addressLine2?: string | null
  city?: string | null
  stateProvince?: string | null
  postalCode?: string | null
  country?: string | null
  latitude?: number | null
  longitude?: number | null
  locationBarcodeData?: string | null
  isActive: boolean
  createdDate: string
  modifiedDate: string
}

interface CreateLocationRequest {
  locationCode: string
  locationName: string
  // ... optional fields
}

interface UpdateLocationRequest {
  locationName: string
  // ... optional fields
  isActive: boolean
}
```

### Extinguisher Type Types

```typescript
interface ExtinguisherTypeDto {
  extinguisherTypeId: string
  tenantId: string
  typeCode: string
  typeName: string
  description?: string | null
  agentType?: string | null
  capacity?: number | null
  capacityUnit?: string | null
  fireClassRating?: string | null
  serviceLifeYears?: number | null
  hydroTestIntervalYears?: number | null
  isActive: boolean
  createdDate: string
  modifiedDate: string
}

interface CreateExtinguisherTypeRequest {
  typeCode: string
  typeName: string
  // ... optional fields
}

interface UpdateExtinguisherTypeRequest {
  typeName: string
  // ... optional fields
  isActive: boolean
}
```

### Enums

```typescript
enum FireClass {
  A = 'A',
  B = 'B',
  C = 'C',
  D = 'D',
  K = 'K'
}

enum AgentType {
  DryChemical = 'Dry Chemical',
  CO2 = 'CO2',
  Water = 'Water',
  Foam = 'Foam',
  CleanAgent = 'Clean Agent',
  WetChemical = 'Wet Chemical'
}
```

### Common Types

```typescript
interface ApiError {
  message: string
  statusCode?: number
  errors?: Record<string, string[]>
}

interface PaginatedResponse<T> {
  items: T[]
  totalCount: number
  pageNumber: number
  pageSize: number
  totalPages: number
}
```

## Type Guards

Type guards provide runtime validation to ensure objects match expected types:

```typescript
function isLocationDto(obj: any): obj is LocationDto {
  return (
    obj &&
    typeof obj.locationId === 'string' &&
    typeof obj.locationCode === 'string' &&
    typeof obj.locationName === 'string' &&
    typeof obj.isActive === 'boolean'
  )
}

function isExtinguisherTypeDto(obj: any): obj is ExtinguisherTypeDto {
  return (
    obj &&
    typeof obj.extinguisherTypeId === 'string' &&
    typeof obj.typeCode === 'string' &&
    typeof obj.typeName === 'string' &&
    typeof obj.isActive === 'boolean'
  )
}
```

## Benefits

### Type Safety
- Catch type errors at compile time instead of runtime
- IDE autocomplete for all API objects
- Prevent invalid API calls

### Developer Experience
- IntelliSense support in VS Code
- Better refactoring capabilities
- Self-documenting code

### Maintainability
- Easier to understand data structures
- Reduces bugs related to property typos
- Clear contracts between frontend and backend

## Migration Strategy

### Coexistence Period
The TypeScript files coexist with JavaScript files. Both can be used simultaneously:
- Old: `import locationService from '@/services/locationService.js'`
- New: `import locationService from '@/services/locationService'` (TypeScript version)

### Gradual Migration
1. ✅ Type definitions created (`src/types/api.ts`)
2. ✅ Services migrated to TypeScript
3. ✅ Stores migrated to TypeScript
4. ⏳ Vue components to be migrated (future)
5. ⏳ Remove old JavaScript files (future)

### Component Migration Example

When migrating Vue components:

```vue
<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useLocationStore } from '@/stores/locations'
import type { LocationDto } from '@/types/api'

const locationStore = useLocationStore()
const locations = ref<LocationDto[]>([])

onMounted(async () => {
  await locationStore.fetchLocations()
  locations.value = locationStore.activeLocations
})
</script>
```

## Next Steps

1. Update Vue components to use TypeScript services and stores
2. Add `.ts` extension to `<script setup>` blocks in Vue components
3. Gradually remove old JavaScript service/store files
4. Add TypeScript build check to CI/CD pipeline
5. Document TypeScript conventions in team guidelines

## Notes

- JavaScript files remain functional during transition
- No breaking changes to existing functionality
- TypeScript is opt-in - can be adopted incrementally
- All existing tests continue to work
