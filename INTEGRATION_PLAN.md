# Mobile-Backend Integration Plan

**Date**: 2026-07-05  
**Branch**: feature/api-integration  
**Backend**: FastAPI + PostgreSQL (Flask-based web app)  
**Backend Codebase**: W:\Aatish\Stuff\generator-ledger

---

## 🔍 Discovery Summary

### Backend Architecture (Confirmed)
- **Framework**: FastAPI (via `web/app.py`)
- **Database**: PostgreSQL (running in Docker on PROD server)
- **Auth**: JWT tokens + session cookies
- **API Prefix**: All mobile APIs at `/api/*`
- **Current Version**: 4.0.4
- **Servers**: PROD and DEV

### API Endpoints Available (From web/app.py)

#### Authentication
✅ `POST /api/login` → `{token, user}`  
✅ `POST /api/auth/refresh` → refresh JWT  
✅ `POST /api/logout`  

#### Generators
✅ `GET /api/generators` → List all generators  
✅ `GET /api/generators/{id}/bookings` → Generator booking history  
✅ `POST /api/generators` → Create generator  

#### Vendors
✅ `GET /api/vendors` → List all vendors  
✅ `GET /api/vendors/{id}/bookings` → Vendor booking history  
✅ `POST /api/vendors` → Create vendor  
✅ `DELETE /api/vendors/{id}` → Delete vendor  

#### Bookings
✅ `GET /api/bookings` → List all bookings  
✅ `GET /api/bookings/{id}` → Get booking details  
✅ `POST /api/bookings` → Create booking  
✅ `POST /api/bookings/{id}/cancel` → Cancel booking  
✅ `DELETE /api/bookings/{id}` → Delete booking  
✅ `POST /api/bookings/{id}/items` → Add booking item  
✅ `POST /api/bookings/{id}/items/bulk-update` → Bulk update items  

#### Billing
✅ `GET /api/billing/lines` → Billing lines (for billing preview)

#### System Health
✅ `GET /api/monitor/live` → Live system metrics  
✅ `GET /health` → Health check  
✅ `GET /api/info` → API version info

#### Admin (Users)
✅ `POST /admin/users/create` → Create user  
✅ `POST /admin/users/{id}/update` → Update user  
✅ `POST /admin/users/{id}/password` → Change password  
✅ `POST /admin/users/{id}/permissions` → Update permissions  
✅ `POST /admin/users/{id}/delete` → Delete user

---

## 📋 Gap Analysis

### ✅ Available Endpoints (No Changes Needed)
1. Authentication (login, logout, refresh)
2. Vendors (GET, POST, DELETE)
3. Generators (GET, POST)
4. Bookings (GET, POST, CANCEL, DELETE)
5. Billing (GET lines)
6. System Health (GET monitor/live)
7. Admin Users (CRUD)

### ⚠️ Missing Endpoints (Need Backend Updates)

#### Generators
- ❌ `PUT /api/generators/{id}` — Update generator
- ❌ `DELETE /api/generators/{id}` — Delete generator
- ❌ `GET /api/generators?inventoryGroup=...` — Filter by inventory group

#### Vendors
- ❌ `PUT /api/vendors/{id}` — Update vendor
- ❌ `GET /api/vendors/{id}` — Get single vendor details

#### Bookings
- ❌ `PUT /api/bookings/{id}` — Update booking details

#### Billing
- ❌ `GET /api/billing/preview?startDate=...&endDate=...&vendorId=...` — Filtered billing preview
- ❌ `POST /api/billing/payments` — Record payment

#### Admin
- ❌ `GET /api/users` — List all users (for user management screen)
- ❌ `GET /api/permissions` — Get permission matrix

---

## 🎯 Integration Strategy

### Phase 1: Environment Configuration (Pre-Work)

**Before starting WO-054, we need:**

#### 1.1 Backend Configuration
- [ ] **PROD Server URL**: What is the PROD server IP/domain?
- [ ] **DEV Server URL**: What is the DEV server IP/domain?
- [ ] **API Port**: Is the FastAPI running on port 8000?
- [ ] **HTTPS**: Is HTTPS enabled on PROD? (recommended for mobile app)
- [ ] **CORS**: Add mobile app origins to `CORS_ALLOWED_ORIGINS` in backend `.env`
  - Example: `http://localhost:8082` (for Flutter web testing)
  - May need wildcard or specific Flutter app scheme for mobile

#### 1.2 Mobile App Configuration
Create `lib/core/config/api_config.dart` with environment-specific URLs:

```dart
class ApiConfig {
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );
  
  static String get baseUrl {
    switch (environment) {
      case 'prod':
        return 'https://<PROD_SERVER_URL>/api';  // ← Need this from you
      case 'dev':
        return 'http://<DEV_SERVER_URL>:8000/api';  // ← Need this from you
      default:
        return 'http://localhost:8000/api';  // Local development
    }
  }
  
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
}
```

#### 1.3 Authentication Flow Verification
- [ ] Test `POST /api/login` with credentials
- [ ] Verify JWT token format (Bearer token expected)
- [ ] Check token expiry (JWT_EXPIRE_MINUTES = 60 in backend)
- [ ] Test `POST /api/auth/refresh` for token renewal

---

### Phase 2: Backend API Gaps (Parallel Track or Pre-Work)

**Two options:**

#### Option A: Add Missing Endpoints to Backend (Recommended)
Modify `W:\Aatish\Stuff\generator-ledger\web\app.py` to add:

1. **Generator Update/Delete**
   ```python
   @app.put("/api/generators/{generator_id}")
   async def update_generator(...) -> JSONResponse:
       # Update generator in DB
       
   @app.delete("/api/generators/{generator_id}")
   async def delete_generator(...) -> JSONResponse:
       # Delete generator from DB
   ```

2. **Vendor Update/Get Single**
   ```python
   @app.get("/api/vendors/{vendor_id}")
   async def get_vendor(...) -> JSONResponse:
       # Return single vendor
       
   @app.put("/api/vendors/{vendor_id}")
   async def update_vendor(...) -> JSONResponse:
       # Update vendor in DB
   ```

3. **Booking Update**
   ```python
   @app.put("/api/bookings/{booking_id}")
   async def update_booking(...) -> JSONResponse:
       # Update booking details
   ```

4. **Billing Preview with Filters**
   ```python
   @app.get("/api/billing/preview")
   async def get_billing_preview(
       start_date: str,
       end_date: str,
       vendor_id: Optional[str] = None
   ) -> JSONResponse:
       # Calculate billing with filters
   ```

5. **Admin Users List & Permissions**
   ```python
   @app.get("/api/users")
   async def get_users(...) -> JSONResponse:
       # List all users
       
   @app.get("/api/permissions")
   async def get_permissions(...) -> JSONResponse:
       # Return permission matrix
   ```

**Estimated Backend Work**: 4-6 hours (straightforward CRUD operations)

#### Option B: Use Existing Endpoints with Workarounds
- Generator update: Use `POST /api/generators` with existing ID (if backend supports upsert)
- Vendor update: Delete + recreate (not ideal, but functional)
- Booking update: Use `POST /api/bookings/{id}/items/bulk-update` (limited)
- Billing: Fetch all bookings client-side and calculate (slower, not recommended)
- Users: Scrape from HTML pages (NOT RECOMMENDED)

**Recommendation**: **Option A** is better for production quality.

---

### Phase 3: Mobile Work Order Adjustments

#### WO-054: API Client Architecture (No Changes)
Proceed as planned. Just configure `ApiConfig.baseUrl` with correct server URLs.

#### WO-055: Authentication API (Minor Adjustments)
- Endpoint exists: `POST /api/login`
- Response format: Check actual response structure from backend
- Expected: `{token: "...", user: {username, role, ...}}`
- Token refresh: `POST /api/auth/refresh` available

**Action**: Test `/api/login` endpoint first to confirm response structure matches expectations.

#### WO-056: Vendors API (Needs Backend Update)
- `PUT /api/vendors/{id}` — **MISSING** (add to backend)
- `GET /api/vendors/{id}` — **MISSING** (add to backend)
- Workaround: Skip edit functionality temporarily, or use delete+recreate

#### WO-057: Generators API (Needs Backend Update)
- `PUT /api/generators/{id}` — **MISSING** (add to backend)
- `DELETE /api/generators/{id}` — **MISSING** (add to backend)
- `GET /api/generators?inventoryGroup=...` — **MISSING** (add filter support)
- Workaround: Client-side filtering of full generator list

#### WO-058: Bookings API (Needs Backend Update)
- `PUT /api/bookings/{id}` — **MISSING** (add to backend)
- Workaround: Use bulk-update endpoint for partial updates

#### WO-059: Billing API (Needs Backend Update)
- `GET /api/billing/preview?filters` — **MISSING** (add to backend)
- `POST /api/billing/payments` — **MISSING** (add to backend)
- Current: `GET /api/billing/lines` exists (list all billing lines)
- Workaround: Fetch all billing lines and filter client-side (slower)

#### WO-060: Users API (Needs Backend Update)
- `GET /api/users` — **MISSING** (add to backend)
- `GET /api/permissions` — **MISSING** (add to backend)
- Current: Only POST endpoints exist for CRUD operations
- Workaround: None (must add GET endpoints)

#### WO-061: System Health API (Exists)
- `GET /api/monitor/live` — ✅ Available
- No changes needed

#### WO-062: Error Handling (No Changes)
Proceed as planned.

---

## 🚀 Recommended Execution Plan

### Option 1: Backend First (Safest)
**Timeline**: 1-2 days backend + 5-7 days mobile

1. **Day 1**: Add missing backend endpoints (4-6 hours)
2. **Day 1-2**: Test backend endpoints with Postman/curl
3. **Day 2-3**: WO-054 + WO-055 (API Client + Auth)
4. **Day 3-5**: WO-056 through WO-061 (All repositories)
5. **Day 6-7**: WO-062 (Error handling + UX polish)

**Pros**: Clean integration, no workarounds  
**Cons**: Delays mobile work by 1-2 days

---

### Option 2: Parallel Development (Faster)
**Timeline**: 5-7 days (backend and mobile in parallel)

1. **Day 1**: 
   - Backend: Start adding missing endpoints
   - Mobile: WO-054 (API Client foundation)
2. **Day 2**: 
   - Backend: Complete missing endpoints + test
   - Mobile: WO-055 (Auth integration)
3. **Day 3-4**: 
   - Backend: Deploy to DEV
   - Mobile: WO-056, WO-057 (Vendors, Generators)
4. **Day 5**: 
   - Mobile: WO-058, WO-059 (Bookings, Billing)
5. **Day 6**: 
   - Mobile: WO-060, WO-061 (Users, System Health)
6. **Day 7**: 
   - Mobile: WO-062 (Error handling + UX polish)

**Pros**: Faster to v1.0.0  
**Cons**: Requires coordination, potential rework

---

### Option 3: Mobile-First with Mocks (Riskiest)
**Timeline**: 4-6 days mobile + 2-3 days integration fixes

1. **Days 1-4**: Complete all mobile WOs with client-side workarounds
2. **Days 5-6**: Add backend endpoints
3. **Days 7-8**: Integration testing + fixes

**Pros**: Mobile team not blocked  
**Cons**: High rework risk, workarounds may need removal

---

## ✅ CEO Decision Points

Before proceeding with WO-054, please confirm:

### 1. Server Configuration
- [ ] **PROD Server URL/IP**: _______________________
- [ ] **DEV Server URL/IP**: _______________________
- [ ] **API Port**: _______ (default: 8000)
- [ ] **HTTPS Enabled on PROD**: Yes / No
- [ ] **Backend Version**: 4.0.4 (current) or upgrade needed?

### 2. CORS Configuration
- [ ] Add mobile app origins to backend `CORS_ALLOWED_ORIGINS`
- [ ] For Flutter mobile: May need `*` wildcard or specific scheme (e.g., `app://`)

### 3. Backend API Gaps
**Which option do you prefer?**
- [ ] **Option A**: Add missing endpoints first (1-2 day delay, clean integration)
- [ ] **Option B**: Use workarounds in mobile (faster, but less optimal)
- [ ] **Option C**: Parallel development (fastest, requires coordination)

### 4. Testing Credentials
- [ ] **Test Username**: _______________________
- [ ] **Test Password**: _______________________
- [ ] **Test User Role**: admin / operator

### 5. Database Access (Optional)
- [ ] Do you want mobile app to connect directly to Postgres? (NOT RECOMMENDED)
- [ ] Or all data access via API? (RECOMMENDED)

---

## 📝 Next Steps After CEO Confirmation

1. **Create `.env` file** for mobile app with server URLs
2. **Update WO-054** with confirmed API base URLs
3. **Test backend `/api/login`** endpoint with Postman
4. **Choose execution plan** (Option 1, 2, or 3)
5. **Send assignment message to Codex** with context
6. **Track progress** via work order completion

---

**Questions? Need clarification on any section?**

This document will be updated based on your responses.
