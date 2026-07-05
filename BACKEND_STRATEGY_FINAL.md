# Backend API Strategy - Updated Analysis

**Updated**: 2026-07-05T20:27  
**Based On**: CEO's endpoint audit of `/home/aatish/app/genset`  
**Policy**: 🔒 **Zero modification of existing APIs** — Only additive or use existing alternates

---

## 📊 Endpoint Analysis Summary

Based on audit of backend codebase, here's what mobile app should do:

| Mobile Need | Backend Status | Solution | Work Required |
|-------------|---------------|----------|---------------|
| GET vendor by ID | Missing dedicated endpoint | Use `GET /api/vendors` + filter client-side | ✅ No backend work |
| PUT vendor | Has `PATCH /api/vendors/{id}` | Mobile use PATCH instead of PUT | ✅ No backend work |
| PUT generator | Has `PATCH /api/generators/{id}` | Mobile use PATCH instead of PUT | ✅ No backend work |
| DELETE generator | No hard delete | Soft delete: PATCH status to "inactive" | ✅ No backend work |
| PUT booking | Has granular endpoints | Use bulk-update + cancel endpoints | ✅ No backend work |
| GET billing preview | Has `GET /api/billing/lines` | Filter/aggregate client-side | ✅ No backend work |
| GET users list | Missing | **ADD**: New additive endpoint | ⚠️ Backend work needed |
| GET permissions | Missing | **ADD**: New additive endpoint | ⚠️ Backend work needed |

---

## ✅ VERDICT: Only 2 Endpoints Needed

**Good news**: Only **2 new endpoints** need to be added to backend:

1. `GET /api/users` — List all users (admin only)
2. `GET /api/permissions` — Return capability matrix

**All other needs** can be solved with:
- Existing `PATCH` endpoints (instead of `PUT`)
- Client-side filtering/aggregation
- Soft-delete patterns

---

## 🎯 Recommended Mobile Implementation

### 1. Vendors

#### Get Single Vendor
```dart
// Use existing GET /api/vendors and filter
Future<Vendor> getVendorById(String id) async {
  final vendors = await getVendors();  // GET /api/vendors (exists)
  return vendors.firstWhere(
    (v) => v.vendorId == id,
    orElse: () => throw Exception('Vendor not found'),
  );
}
```

#### Update Vendor
```dart
// Use existing PATCH endpoint (app.py:L3386)
Future<Vendor> updateVendor(String id, Vendor vendor) async {
  return await _apiClient.patch<Vendor>(  // ← PATCH not PUT
    '/vendors/$id',
    data: vendor.toMap(),
    fromJson: (json) => Vendor.fromMap(json['vendor']),
  );
}
```

---

### 2. Generators

#### Update Generator
```dart
// Use existing PATCH endpoint (app.py:L2978)
Future<Generator> updateGenerator(String id, Generator generator) async {
  return await _apiClient.patch<Generator>(  // ← PATCH not PUT
    '/generators/$id',
    data: generator.toMap(),
    fromJson: (json) => Generator.fromMap(json['generator']),
  );
}
```

#### Delete Generator (Soft Delete)
```dart
// Use PATCH to set status to "inactive"
Future<void> deleteGenerator(String id) async {
  await _apiClient.patch(
    '/generators/$id',
    data: {'operational_status': 'Inactive'},  // Soft delete
  );
}
```

---

### 3. Bookings

#### Update Booking
```dart
// Use existing bulk-update endpoint (app.py:L3857)
Future<void> updateBooking(int bookingId, Booking booking) async {
  // Update items via bulk-update
  await _apiClient.post(
    '/bookings/$bookingId/items/bulk-update',
    data: {
      'items': booking.items.map((i) => i.toMap()).toList(),
    },
  );
}

// For status changes, use cancel endpoint (app.py:L3745)
Future<void> cancelBooking(int bookingId) async {
  await _apiClient.post('/bookings/$bookingId/cancel');
}
```

---

### 4. Billing

#### Get Billing Preview
```dart
// Use existing billing/lines endpoint (app.py:L3211) + client-side aggregation
Future<BillingPreview> getBillingPreview({
  String? startDate,
  String? endDate,
  String? vendorId,
}) async {
  final response = await _apiClient.get(
    '/billing/lines',
    queryParameters: {
      if (startDate != null) 'from': startDate,
      if (endDate != null) 'to': endDate,
    },
  );
  
  final lines = (response['lines'] as List)
      .map((line) => BillingLine.fromMap(line))
      .toList();
  
  // Filter by vendor client-side
  if (vendorId != null) {
    lines.removeWhere((line) => line.vendorId != vendorId);
  }
  
  // Aggregate client-side
  final vendorTotals = <String, double>{};
  for (var line in lines) {
    vendorTotals[line.vendorId] = 
        (vendorTotals[line.vendorId] ?? 0) + line.amount;
  }
  
  return BillingPreview(
    lines: lines,
    vendorTotals: vendorTotals,
    grandTotal: lines.fold(0, (sum, line) => sum + line.amount),
  );
}
```

---

### 5. Admin Users & Permissions

**These require backend additions** (only 2 endpoints):

#### Backend: Add GET /api/users

```python
@app.get("/api/users")
async def get_users(
    conn: Connection = Depends(get_connection_dependency),
    user: User = Depends(get_session_user_dependency),
):
    """Get all users (admin only)."""
    if not user:
        raise HTTPException(status_code=401, detail="Unauthorized")
    
    if user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    users = UserRepository(conn).list_all()  # Add this method to repository
    
    return JSONResponse({
        "users": [
            {
                "user_id": u.user_id,
                "username": u.username,
                "role": u.role,
                "status": u.status,
                "created_at": u.created_at,
                "last_login": u.last_login,
            }
            for u in users
        ]
    })
```

**Repository method** (add to `core/repositories.py`):
```python
def list_all(self) -> List[User]:
    """Get all users."""
    rows = self.conn.execute("SELECT * FROM users ORDER BY username").fetchall()
    return [User(*row) for row in rows]
```

---

#### Backend: Add GET /api/permissions

```python
@app.get("/api/permissions")
async def get_permissions(
    user: User = Depends(get_session_user_dependency),
):
    """Get permission matrix."""
    if not user:
        raise HTTPException(status_code=401, detail="Unauthorized")
    
    if user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    from core.permissions import CAPABILITY_MATRIX
    
    return JSONResponse({
        "permissions": [
            {
                "capability": cap,
                "admin": perms.get("admin", False),
                "operator": perms.get("operator", False),
            }
            for cap, perms in CAPABILITY_MATRIX.items()
        ]
    })
```

---

## 📋 Updated Work Order Strategy

### No Changes Needed:
- ✅ WO-054 (API Client) — Proceed as planned
- ✅ WO-055 (Auth) — Use existing login endpoint
- ✅ WO-056 (Vendors) — Use PATCH, client-side filtering
- ✅ WO-057 (Generators) — Use PATCH, soft delete
- ✅ WO-058 (Bookings) — Use bulk-update endpoint
- ✅ WO-059 (Billing) — Client-side aggregation
- ✅ WO-061 (System Health) — Use existing monitor/live endpoint
- ✅ WO-062 (Error Handling) — No changes

### Needs Update:
- ⚠️ **WO-060 (Users & Permissions)** — Backend needs 2 endpoints first

---

## 🚀 Execution Plan (Updated)

### Phase 1: Add 2 Backend Endpoints (30 minutes)

Add to `/home/aatish/app/genset/web/app.py`:

1. `GET /api/users` (15 minutes)
   - Add endpoint function
   - Add `UserRepository.list_all()` method
   - Test with curl

2. `GET /api/permissions` (15 minutes)
   - Add endpoint function
   - Import CAPABILITY_MATRIX
   - Test with curl

**Test**:
```bash
# Test users endpoint
curl -X GET http://192.162.29.60:8000/api/users \
  -H "Authorization: Bearer <token>"

# Test permissions endpoint
curl -X GET http://192.162.29.60:8000/api/permissions \
  -H "Authorization: Bearer <token>"
```

---

### Phase 2: Update Mobile Work Orders (10 minutes)

Update work order docs:
- WO-056: Use PATCH, client-side filter
- WO-057: Use PATCH, soft delete pattern
- WO-058: Use bulk-update endpoint
- WO-059: Client-side aggregation
- WO-060: Wait for 2 backend endpoints (30 min work)

---

### Phase 3: Mobile Implementation (5-7 days)

1. **Day 1-2**: WO-054 (API Client with PATCH support) + WO-055 (Auth)
2. **Day 3**: WO-056 (Vendors) + WO-057 (Generators)
3. **Day 4**: WO-058 (Bookings) + WO-059 (Billing)
4. **Day 5**: Add 2 backend endpoints → WO-060 (Users/Permissions)
5. **Day 6**: WO-061 (System Health)
6. **Day 7**: WO-062 (Error handling + UX polish)

---

## ✅ Decision Required

### Option A: Add 2 Endpoints Now (Recommended)
- Add `GET /api/users` and `GET /api/permissions` (30 minutes)
- Mobile team unblocked completely
- Clean implementation, no workarounds

### Option B: Mock Users/Permissions
- Use `mock_users.dart` in mobile app
- Add backend endpoints later
- WO-060 uses mocks temporarily

**Which do you prefer?**

---

## 📊 Summary

| Original Assessment | Updated Reality | Backend Work |
|---------------------|-----------------|--------------|
| 8 endpoints missing | 2 endpoints missing | 30 minutes |
| Mock-first approach | Use existing PATCH + filters | Mostly solved |
| 4-6 hours backend work | 30 minutes backend work | 94% reduction |

**Bottom line**: Your backend is more complete than I initially thought! Only 2 small additive endpoints needed.

---

**Recommendation**: Spend 30 minutes adding 2 endpoints, then mobile team has zero blockers. Much cleaner than mocks.

**Your call?**
