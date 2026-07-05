# Backend API Strategy for Mobile Integration

**Status**: 🔄 **MOCK-FIRST APPROACH**  
**Updated**: 2026-07-05  
**Decision**: Use mocks now, add real APIs later

---

## 📋 Strategy Overview

After analyzing the live backend app, the decision is to **NOT add new endpoints immediately**. Instead:

### Phase 1: Mock Implementation (Current Sprint - M11)
- Mobile app repositories will include **mock implementations** for missing endpoints
- Mock data uses same models/structure as real API responses
- No backend changes required
- Mobile development unblocked immediately

### Phase 2: Backend API Addition (Future Sprint)
- Add real endpoints to `web/app.py` when backend development is scheduled
- Use specifications in this document as reference
- Deploy to DEV → test → deploy to PROD

### Phase 3: Switch to Real APIs (Simple Update)
- Update mobile repository implementations to call real endpoints
- Remove mock logic
- No UI changes needed (repository pattern abstracts API)

**Benefits**:
- ✅ Mobile development starts immediately
- ✅ No backend work blocking mobile team
- ✅ Clean separation via repository pattern
- ✅ Easy migration path to real APIs

---

## 🎯 Missing Endpoints (To Mock in Mobile)

### 1. Generators
- ❌ `PUT /api/generators/{id}` — Update generator
- ❌ `DELETE /api/generators/{id}` — Delete generator
- ❌ `GET /api/generators?inventoryGroup=...` — Filter by group

**Mobile Mock Strategy**:
- Store generators in local state (Riverpod)
- Update/delete locally
- Filter in-memory
- Persist to API when endpoint is added

---

### 2. Vendors
- ❌ `PUT /api/vendors/{id}` — Update vendor
- ❌ `GET /api/vendors/{id}` — Get single vendor

**Mobile Mock Strategy**:
- Fetch all vendors from `GET /api/vendors` (exists)
- Find single vendor by ID in-memory
- Update locally, call real API when available

---

### 3. Bookings
- ❌ `PUT /api/bookings/{id}` — Update booking

**Mobile Mock Strategy**:
- Use existing `POST /api/bookings/{id}/items/bulk-update` as workaround
- Store full booking state locally
- Update locally until real PUT endpoint is added

---

### 4. Billing
- ❌ `GET /api/billing/preview?startDate=...&endDate=...&vendorId=...` — Filtered preview
- ❌ `POST /api/billing/payments` — Record payment

**Mobile Mock Strategy**:
- Fetch all billing lines from `GET /api/billing/lines` (exists)
- Filter client-side by date range and vendor
- Calculate totals in-memory
- Mock payment tracking locally

---

### 5. Admin Users
- ❌ `GET /api/users` — List all users
- ❌ `GET /api/permissions` — Permission matrix

**Mobile Mock Strategy**:
- Use mock user list from `mock_users.dart` (already exists)
- Use mock permissions from app constants
- Switch to real API when backend is ready

---

## 🔧 Implementation Pattern: Repository with Mocks

### Example: VendorRepository with Mock PUT

```dart
// lib/data/repositories/vendor_repository.dart

class VendorRepository {
  final ApiClient _apiClient;
  final bool _useMocks;  // Toggle for mock vs real API
  
  VendorRepository({
    ApiClient? apiClient,
    bool useMocks = true,  // Default to mocks for now
  }) : _apiClient = apiClient ?? ApiClient(),
       _useMocks = useMocks;
  
  Future<List<Vendor>> getVendors() async {
    // This endpoint EXISTS in backend
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/vendors',
      fromJson: (json) => json,
    );
    
    final vendorList = response['vendors'] as List;
    return vendorList.map((v) => Vendor.fromMap(v)).toList();
  }
  
  Future<Vendor> getVendorById(String id) async {
    if (_useMocks) {
      // MOCK: Fetch all and filter locally
      final vendors = await getVendors();
      final vendor = vendors.firstWhere(
        (v) => v.vendorId == id,
        orElse: () => throw Exception('Vendor not found'),
      );
      return vendor;
    } else {
      // REAL API (when endpoint is added)
      return await _apiClient.get<Vendor>(
        '/vendors/$id',
        fromJson: (json) => Vendor.fromMap(json['vendor']),
      );
    }
  }
  
  Future<Vendor> updateVendor(String id, Vendor vendor) async {
    if (_useMocks) {
      // MOCK: Simulate update with delay
      await Future.delayed(Duration(milliseconds: 300));
      
      // In real scenario, provider will handle local state update
      // This just returns the updated vendor
      return vendor;
    } else {
      // REAL API (when endpoint is added)
      return await _apiClient.put<Vendor>(
        '/vendors/$id',
        data: vendor.toMap(),
        fromJson: (json) => Vendor.fromMap(json['vendor']),
      );
    }
  }
}
```

### Provider Usage (Notifier handles local state)

```dart
// lib/features/vendors/providers/vendors_provider.dart

class VendorNotifier extends StateNotifier<AsyncValue<List<Vendor>>> {
  final VendorRepository _repository;
  List<Vendor> _cachedVendors = [];
  
  VendorNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadVendors();
  }
  
  Future<void> loadVendors() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final vendors = await _repository.getVendors();
      _cachedVendors = vendors;
      return vendors;
    });
  }
  
  Future<void> updateVendor(Vendor vendor) async {
    // Optimistic update: update local state immediately
    final index = _cachedVendors.indexWhere((v) => v.vendorId == vendor.vendorId);
    if (index != -1) {
      _cachedVendors[index] = vendor;
      state = AsyncValue.data([..._cachedVendors]);
    }
    
    try {
      // Call repository (mock or real)
      await _repository.updateVendor(vendor.vendorId, vendor);
      
      // Reload from server when real API is available
      // For mocks, skip reload since we updated locally
      if (!_repository._useMocks) {
        await loadVendors();
      }
    } catch (e) {
      // Revert optimistic update on error
      await loadVendors();
      rethrow;
    }
  }
}
```

---

## 🚀 Migration Path (Mock → Real API)

When backend endpoints are added:

### Step 1: Add Endpoint to Backend
Use specifications from the "Original Endpoint Specs" section below.

### Step 2: Test Endpoint
```bash
curl -X PUT http://192.162.29.60:8000/api/vendors/V001 \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"name":"Updated Vendor","location":"New Location"}'
```

### Step 3: Update Mobile Repository
Change the toggle:
```dart
VendorRepository({
  ApiClient? apiClient,
  bool useMocks = false,  // ← Change to false
})
```

### Step 4: Remove Mock Logic (Optional Cleanup)
Once all endpoints are real, remove the `if (_useMocks)` branches entirely.

---

## 📝 Work Order Updates

### WO-056, WO-057, WO-058, WO-059, WO-060
**Updated Implementation Approach**:
1. Implement repositories with mock logic for missing endpoints
2. Use existing backend endpoints where available
3. Add `useMocks` toggle to each repository
4. Document which methods are mocked vs real
5. Add TODO comments for future API migration

**Acceptance Criteria Update**:
- ✅ Repository implements all CRUD methods
- ✅ Methods use existing API endpoints where available
- ✅ Methods use local mocks for missing endpoints
- ✅ Mock implementations provide realistic delays
- ✅ Code includes migration path documentation
- ✅ Tests cover both mock and real API scenarios

---

## ✅ Available Backend Endpoints (Use These)

These endpoints EXIST in backend and should be used:

### Authentication
✅ `POST /api/login` → `{token, user}`  
✅ `POST /api/auth/refresh`  
✅ `POST /api/logout`

### Generators
✅ `GET /api/generators` → List all  
✅ `POST /api/generators` → Create  
✅ `GET /api/generators/{id}/bookings`

### Vendors
✅ `GET /api/vendors` → List all  
✅ `POST /api/vendors` → Create  
✅ `DELETE /api/vendors/{id}`  
✅ `GET /api/vendors/{id}/bookings`

### Bookings
✅ `GET /api/bookings` → List all  
✅ `GET /api/bookings/{id}` → Get single  
✅ `POST /api/bookings` → Create  
✅ `POST /api/bookings/{id}/cancel`  
✅ `DELETE /api/bookings/{id}`  
✅ `POST /api/bookings/{id}/items` → Add item  
✅ `POST /api/bookings/{id}/items/bulk-update`

### Billing
✅ `GET /api/billing/lines` → All billing lines

### System Health
✅ `GET /api/monitor/live` → Live metrics

### Admin Users
✅ `POST /admin/users/create`  
✅ `POST /admin/users/{id}/update`  
✅ `POST /admin/users/{id}/delete`  
✅ `POST /admin/users/{id}/password`  
✅ `POST /admin/users/{id}/permissions`

---

## 🔮 Future: Real Endpoint Specifications

When ready to add backend endpoints, use these specifications:

<details>
<summary>Click to expand: PUT /api/generators/{id}</summary>

```python
@app.put("/api/generators/{generator_id}")
async def update_generator(
    generator_id: str,
    request: Request,
    conn: Connection = Depends(get_connection_dependency),
    user: User = Depends(get_session_user_dependency),
):
    """Update an existing generator."""
    if not user or user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    body = await request.json()
    generator = GeneratorRepository(conn).get_generator(generator_id)
    if not generator:
        raise HTTPException(status_code=404, detail="Generator not found")
    
    updated_generator = Generator(
        generator_id=generator_id,
        capacity=body.get("capacity", generator.capacity),
        type_name=body.get("type_name", generator.type_name),
        operational_status=body.get("operational_status", generator.operational_status),
        inventory_type=body.get("inventory_type", generator.inventory_type),
        rental_vendor_id=body.get("rental_vendor_id", generator.rental_vendor_id),
        notes=body.get("notes", generator.notes),
    )
    
    GeneratorRepository(conn).update_generator(updated_generator)
    conn.commit()
    
    return JSONResponse({"status": "success", "generator": updated_generator.to_dict()})
```
</details>

<details>
<summary>Click to expand: Other endpoint specs</summary>

See original `BACKEND_API_ADDITIONS.md` backup for:
- DELETE /api/generators/{id}
- GET /api/vendors/{id}
- PUT /api/vendors/{id}
- PUT /api/bookings/{id}
- GET /api/billing/preview
- GET /api/users
- GET /api/permissions

All specifications preserved for future reference.
</details>

---

## 📊 Summary

| Endpoint | Status | Mobile Implementation |
|----------|--------|----------------------|
| PUT /api/generators/{id} | ❌ Missing | Mock in repository |
| DELETE /api/generators/{id} | ❌ Missing | Mock in repository |
| GET /api/vendors/{id} | ❌ Missing | Filter in-memory |
| PUT /api/vendors/{id} | ❌ Missing | Mock in repository |
| PUT /api/bookings/{id} | ❌ Missing | Mock in repository |
| GET /api/billing/preview | ❌ Missing | Calculate client-side |
| GET /api/users | ❌ Missing | Use mock_users.dart |
| GET /api/permissions | ❌ Missing | Use app constants |

**Mobile development**: ✅ Unblocked  
**Backend work**: ⏸️ Deferred to future sprint  
**Migration effort**: 🟢 Low (repository pattern enables easy switch)

---

**Last Updated**: 2026-07-05T20:05:00+05:30  
**Decision By**: CEO  
**Status**: Ready for mobile implementation with mocks
