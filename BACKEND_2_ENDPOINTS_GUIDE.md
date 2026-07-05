# Implementation Guide: 2 Missing JSON APIs

**Target File**: `/home/aatish/app/genset/web/app.py`  
**Estimated Time**: 30 minutes  
**Status**: Ready to implement

---

## 🎯 What We're Adding

Two new **additive** JSON REST endpoints to expose existing backend functionality to mobile:

1. `GET /api/users` — Return user list as JSON (already rendered in HTML)
2. `GET /api/permissions` — Return capability matrix as JSON (already built for HTML)

**Zero changes to existing logic** — just exposing what's already there.

---

## 📋 Implementation Steps

### Step 1: Add GET /api/users (15 minutes)

**Location**: Add after line ~2800 in `web/app.py` (near other `/api/` endpoints)

```python
@app.get("/api/users")
async def api_get_users(
    conn: Connection = Depends(get_connection_dependency),
    user: User = Depends(get_session_user_dependency),
):
    """
    Get all users as JSON (admin only).
    
    Mobile equivalent of the user list rendered in /admin/settings.
    """
    require_role(user, ROLE_ADMIN)
    
    users = UserRepository(conn).list_all()
    
    return JSONResponse({
        "users": [
            {
                "user_id": u.user_id,
                "username": u.username,
                "role": u.role,
                "status": "active" if u.is_active else "inactive",
                "created_at": u.created_at.isoformat() if u.created_at else None,
                "last_login": u.last_login.isoformat() if u.last_login else None,
            }
            for u in users
        ]
    })
```

**Notes**:
- Reuses existing `UserRepository(conn).list_all()` method
- Same access control as HTML settings page (`require_role(ROLE_ADMIN)`)
- Converts datetime to ISO 8601 strings for JSON compatibility

---

### Step 2: Add GET /api/permissions (15 minutes)

**Location**: Add right after the `/api/users` endpoint

```python
@app.get("/api/permissions")
async def api_get_permissions(
    user: User = Depends(get_session_user_dependency),
):
    """
    Get permission capability matrix as JSON (admin only).
    
    Mobile equivalent of the permission matrix rendered in /admin/settings.
    """
    require_role(user, ROLE_ADMIN)
    
    from core.permissions import PERMISSION_MATRIX_CAPABILITIES
    
    # Build capability list with role defaults
    capabilities = []
    for cap_key, cap_meta in PERMISSION_MATRIX_CAPABILITIES.items():
        capabilities.append({
            "capability": cap_key,
            "label": cap_meta.get("label", cap_key),
            "description": cap_meta.get("description", ""),
            "admin": cap_meta.get("admin", False),
            "operator": cap_meta.get("operator", False),
        })
    
    return JSONResponse({
        "capabilities": capabilities
    })
```

**Notes**:
- Reuses existing `PERMISSION_MATRIX_CAPABILITIES` from `core/permissions.py`
- Same structure as `_build_permission_matrix_rows()` but returns JSON
- Mobile app will display this in the permission matrix UI

---

## 🧪 Testing

### Test 1: Login and Get Token

```bash
# Get JWT token
TOKEN=$(curl -s -X POST http://192.162.29.60:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"owner","password":"Qwerty@345"}' \
  | jq -r '.token')

echo "Token: $TOKEN"
```

### Test 2: GET /api/users

```bash
curl -X GET http://192.162.29.60:8000/api/users \
  -H "Authorization: Bearer $TOKEN" \
  | jq
```

**Expected Response**:
```json
{
  "users": [
    {
      "user_id": 1,
      "username": "owner",
      "role": "admin",
      "status": "active",
      "created_at": "2025-02-09T00:00:00",
      "last_login": "2026-07-05T20:00:00"
    },
    ...
  ]
}
```

### Test 3: GET /api/permissions

```bash
curl -X GET http://192.162.29.60:8000/api/permissions \
  -H "Authorization: Bearer $TOKEN" \
  | jq
```

**Expected Response**:
```json
{
  "capabilities": [
    {
      "capability": "view_generators",
      "label": "View Generators",
      "description": "Can view generator inventory",
      "admin": true,
      "operator": true
    },
    {
      "capability": "edit_generators",
      "label": "Edit Generators",
      "description": "Can create/update generators",
      "admin": true,
      "operator": false
    },
    ...
  ]
}
```

---

## ✅ Verification Checklist

After adding endpoints:

- [ ] Endpoints added to `web/app.py`
- [ ] No syntax errors (check with `python -m py_compile web/app.py`)
- [ ] Restart backend: `python main.py` or `uvicorn web.app:app --reload`
- [ ] Test login gets valid JWT token
- [ ] Test `GET /api/users` returns user list
- [ ] Test `GET /api/permissions` returns capability matrix
- [ ] Test with non-admin user (should get 403 Forbidden)
- [ ] Deploy to PROD server (192.162.29.71)

---

## 📝 Deployment Steps

### DEV Server (192.162.29.60)

```bash
# SSH to DEV server
ssh aatish@192.162.29.60

# Navigate to app directory
cd /home/aatish/app/genset

# Edit web/app.py
nano web/app.py
# (Add the 2 endpoints from above)

# Restart app
systemctl restart genset
# OR if running manually:
pkill -f "python main.py"
python main.py
```

### PROD Server (192.162.29.71)

Same steps as DEV, but:
```bash
ssh aatish@192.162.29.71
cd /home/aatish/app/genset
# ... rest same as DEV
```

---

## 🔒 Security Notes

Both endpoints:
- ✅ Require authentication (JWT token)
- ✅ Require admin role (`require_role(ROLE_ADMIN)`)
- ✅ Return 401 if not authenticated
- ✅ Return 403 if not admin
- ✅ No PII exposure (passwords not included)
- ✅ Same access control as existing HTML settings page

**No new security surface** — just JSON format of existing admin features.

---

## 📊 Before vs After

### Before (HTML Only)
```
Mobile App → ❌ No access to users/permissions
Admin Panel → ✅ HTML table in /admin/settings
```

### After (JSON + HTML)
```
Mobile App → ✅ GET /api/users, GET /api/permissions (JSON)
Admin Panel → ✅ HTML table in /admin/settings (unchanged)
```

---

## 🚀 Impact on Mobile Development

### Without These Endpoints
- WO-060 must use `mock_users.dart`
- Permission matrix hardcoded in mobile app
- Must add endpoints later + refactor mobile code

### With These Endpoints
- WO-060 uses real API immediately
- No mocks needed
- Clean integration from day 1

**30 minutes saves hours of mobile rework later.**

---

## ⏱️ Time Breakdown

| Task | Time |
|------|------|
| Add GET /api/users endpoint | 10 min |
| Add GET /api/permissions endpoint | 10 min |
| Test both endpoints with curl | 5 min |
| Deploy to DEV server | 3 min |
| Deploy to PROD server | 2 min |
| **Total** | **30 min** |

---

## ✅ Ready to Proceed?

Once you confirm, I'll:
1. Update WO-060 to use real endpoints (not mocks)
2. Update Codex inbox message with final backend status
3. Mobile team has **zero blockers**

**Shall we proceed with adding these 2 endpoints?**
