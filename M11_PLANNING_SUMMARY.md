# M11: Release Preparation — Backend API Integration

**Branch**: `feature/api-integration`  
**Status**: ACTIVE  
**Created**: 2026-07-05  
**Target Release**: v1.0.0

---

## Overview

Milestone M11 transitions the Genset Industrial Ledger mobile app from a mock-data prototype to a production-ready application with full backend API integration. This milestone replaces all mock data sources with REST API calls, implements JWT authentication, and adds comprehensive error handling and offline resilience.

---

## Work Orders (9 Total)

### Foundation Layer (P0)

#### WO-054: API Client Architecture & HTTP Service Layer
**Assignee**: Codex  
**Priority**: P0  
**Dependencies**: None  

Establish HTTP client infrastructure using Dio package with:
- Base API client with interceptors
- Token storage (flutter_secure_storage)
- Error handling abstractions (ApiException)
- Request/response serialization
- Automatic token injection and 401 handling

**Files**:
- `lib/core/services/api_client.dart`
- `lib/core/services/token_storage.dart`
- `lib/core/exceptions/api_exception.dart`
- `lib/core/config/api_config.dart`

**Estimated Effort**: 4-6 hours

---

#### WO-055: Authentication API Integration
**Assignee**: Codex  
**Priority**: P0  
**Dependencies**: WO-054  

Replace mock authentication with real API-based login:
- AuthRepository with login()/logout() methods
- JWT token management
- Update AuthProvider to async state management
- Update LoginScreen for API error handling
- Update AppRouter redirect logic to check token presence

**API Endpoints**:
- `POST /api/auth/login` → returns `{token, user}`
- `DELETE /api/auth/logout` (optional)

**Estimated Effort**: 4-5 hours

---

### Data Layer (P0)

#### WO-056: Vendors API Integration
**Assignee**: Codex  
**Priority**: P0  
**Dependencies**: WO-054, WO-055  

Replace mock vendors data with VendorRepository:
- CRUD operations (GET/POST/PUT/DELETE /api/vendors)
- Update VendorNotifier to use AsyncValue pattern
- Add loading/error states to VendorDirectoryScreen

**Estimated Effort**: 3-4 hours

---

#### WO-057: Generators API Integration
**Assignee**: Codex  
**Priority**: P0  
**Dependencies**: WO-054, WO-055  

Replace mock generators data with GeneratorRepository:
- CRUD operations with inventory group filtering
- Update GeneratorNotifier to use AsyncValue pattern
- Add loading/error states to GeneratorsDirectoryScreen

**Estimated Effort**: 3-4 hours

---

#### WO-058: Bookings API Integration
**Assignee**: Codex  
**Priority**: P0  
**Dependencies**: WO-054, WO-055, WO-056, WO-057  

Replace mock bookings data with BookingRepository:
- CRUD operations with vendor/generator relations
- Support date range, vendor, status filtering
- Update BookingNotifier to use AsyncValue pattern

**Estimated Effort**: 4-5 hours

---

#### WO-059: Billing API Integration
**Assignee**: Codex  
**Priority**: P0  
**Dependencies**: WO-058  

Replace client-side billing calculations with BillingRepository:
- Server-calculated totals and subtotals
- Payment tracking
- Date range and vendor filtering

**API Endpoints**:
- `GET /api/billing/preview?startDate=...&endDate=...&vendorId=...`
- `POST /api/billing/payments`

**Estimated Effort**: 3-4 hours

---

#### WO-060: Users & Permissions API Integration
**Assignee**: Codex  
**Priority**: P0  
**Dependencies**: WO-055  

Replace mock user management with UserRepository:
- Admin CRUD operations for user management
- Permission matrix API integration
- Role-based access control

**API Endpoints**:
- `GET/POST/PUT/DELETE /api/users`
- `GET /api/permissions`

**Estimated Effort**: 3-4 hours

---

#### WO-061: System Health API Integration
**Assignee**: Codex  
**Priority**: P1  
**Dependencies**: WO-055  

Replace mock system health with SystemHealthRepository:
- Real server metrics (CPU, memory, database health)
- Periodic polling (every 30 seconds)
- Historical data for sparkline charts

**API Endpoint**:
- `GET /api/system/health`

**Estimated Effort**: 2-3 hours

---

### UX Polish Layer (P0)

#### WO-062: Error Handling, Loading States, & Offline Resilience
**Assignee**: Gemini  
**Priority**: P0  
**Dependencies**: WO-054 through WO-061  

Comprehensive UX improvements for API integration:
- Global error handling and retry mechanisms
- Loading states for all directory screens
- Offline detection and graceful degradation
- Pull-to-refresh on all directory screens
- Modal loading indicators and error messages
- Connectivity monitoring (connectivity_plus package)

**Files**:
- `lib/shared/widgets/error_screen.dart` (new)
- `lib/shared/widgets/loading_overlay.dart` (new)
- `lib/core/utils/connectivity_service.dart` (new)
- Update all directory screens and modals

**Estimated Effort**: 6-8 hours

---

## Total Effort Estimate

**Backend Work (Codex)**: 26-33 hours  
**Frontend Work (Gemini)**: 6-8 hours  
**Total**: 32-41 hours

---

## Backend API Requirements

The mobile app expects the following REST API endpoints:

### Authentication
- `POST /api/auth/login` → `{token: string, user: {...}}`
- `DELETE /api/auth/logout` (optional)

### Vendors
- `GET /api/vendors` → `{vendors: [...]}`
- `GET /api/vendors/:id` → `{vendor: {...}}`
- `POST /api/vendors` → `{vendor: {...}}`
- `PUT /api/vendors/:id` → `{vendor: {...}}`
- `DELETE /api/vendors/:id`

### Generators
- `GET /api/generators?inventoryGroup=...` → `{generators: [...]}`
- `GET /api/generators/:id` → `{generator: {...}}`
- `POST /api/generators` → `{generator: {...}}`
- `PUT /api/generators/:id` → `{generator: {...}}`
- `DELETE /api/generators/:id`

### Bookings
- `GET /api/bookings?startDate=...&endDate=...&vendorId=...` → `{bookings: [...]}`
- `GET /api/bookings/:id` → `{booking: {...}}`
- `POST /api/bookings` → `{booking: {...}}`
- `PUT /api/bookings/:id` → `{booking: {...}}`
- `DELETE /api/bookings/:id`

### Billing
- `GET /api/billing/preview?startDate=...&endDate=...&vendorId=...` → `{billing: {...}}`
- `POST /api/billing/payments` → `{payment: {...}}`

### Users (Admin)
- `GET /api/users` → `{users: [...]}`
- `GET /api/users/:id` → `{user: {...}}`
- `POST /api/users` → `{user: {...}}`
- `PUT /api/users/:id` → `{user: {...}}`
- `DELETE /api/users/:id`
- `GET /api/permissions` → `{permissions: [...]}`

### System Health (Admin)
- `GET /api/system/health` → `{cpu: ..., memory: ..., ...}`

**Authentication**: All endpoints (except `/auth/login`) require `Authorization: Bearer <token>` header.

---

## Success Criteria

✅ All mock data sources replaced with API calls  
✅ JWT authentication fully functional  
✅ Loading states on all screens  
✅ Error handling with retry mechanisms  
✅ Offline mode detection  
✅ Pull-to-refresh on directory screens  
✅ All 47 existing tests passing  
✅ flutter analyze clean  
✅ Ready for backend deployment

---

## Next Steps After M11

1. **Backend API Development** (if not yet complete)
2. **Integration Testing** with real backend
3. **Performance Optimization** (caching, pagination)
4. **Security Audit** (token storage, HTTPS enforcement)
5. **App Store Preparation** (icons, screenshots, metadata)
6. **Release v1.0.0**

---

**Branch**: `feature/api-integration`  
**Created by**: Claude (Session 20)  
**Date**: 2026-07-05T17:41:00+05:30
