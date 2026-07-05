# Backend API Additions for Mobile Integration

**Target File**: `W:\Aatish\Stuff\generator-ledger\web\app.py`  
**Backend Version**: 4.0.4  
**Estimated Effort**: 4-6 hours

---

## 🎯 Missing Endpoints to Add

These endpoints are needed for full mobile app functionality. They follow the same patterns as existing endpoints in `web/app.py`.

---

## 1. Generators - Update & Delete

### PUT /api/generators/{generator_id}
**Purpose**: Update generator details (capacity, status, inventory group, assigned vendor)

```python
@app.put("/api/generators/{generator_id}")
async def update_generator(
    generator_id: str,
    request: Request,
    conn: Connection = Depends(get_connection_dependency),
    user: User = Depends(get_session_user_dependency),
):
    """Update an existing generator."""
    if not user:
        raise HTTPException(status_code=401, detail="Unauthorized")
    
    # Admin-only for now (can add operator permissions later)
    if user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    try:
        body = await request.json()
        generator = GeneratorRepository(conn).get_generator(generator_id)
        
        if not generator:
            raise HTTPException(status_code=404, detail="Generator not found")
        
        # Update fields
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
        
        return JSONResponse({
            "status": "success",
            "generator": {
                "generator_id": updated_generator.generator_id,
                "capacity": updated_generator.capacity,
                "type_name": updated_generator.type_name,
                "operational_status": updated_generator.operational_status,
                "inventory_type": updated_generator.inventory_type,
                "rental_vendor_id": updated_generator.rental_vendor_id,
                "notes": updated_generator.notes,
            }
        })
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        logger.error(f"Error updating generator: {e}")
        raise HTTPException(status_code=500, detail=str(e))
```

**Required Repository Method** (add to `core/repositories.py` if missing):
```python
def update_generator(self, generator: Generator) -> None:
    """Update an existing generator."""
    self.conn.execute(
        """
        UPDATE generators
        SET capacity = ?,
            type_name = ?,
            operational_status = ?,
            inventory_type = ?,
            rental_vendor_id = ?,
            notes = ?
        WHERE generator_id = ?
        """,
        (
            generator.capacity,
            generator.type_name,
            generator.operational_status,
            generator.inventory_type,
            generator.rental_vendor_id,
            generator.notes,
            generator.generator_id,
        ),
    )
```

---

### DELETE /api/generators/{generator_id}
**Purpose**: Delete a generator (admin only)

```python
@app.delete("/api/generators/{generator_id}")
async def delete_generator(
    generator_id: str,
    conn: Connection = Depends(get_connection_dependency),
    user: User = Depends(get_session_user_dependency),
):
    """Delete a generator."""
    if not user:
        raise HTTPException(status_code=401, detail="Unauthorized")
    
    if user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    try:
        generator = GeneratorRepository(conn).get_generator(generator_id)
        if not generator:
            raise HTTPException(status_code=404, detail="Generator not found")
        
        # Check if generator has active bookings
        bookings = GeneratorRepository(conn).get_generator_bookings(generator_id)
        active_bookings = [b for b in bookings if b.status != "Cancelled"]
        
        if active_bookings:
            raise HTTPException(
                status_code=400,
                detail=f"Cannot delete generator with {len(active_bookings)} active booking(s)"
            )
        
        GeneratorRepository(conn).delete_generator(generator_id)
        conn.commit()
        
        return JSONResponse({
            "status": "success",
            "message": f"Generator {generator_id} deleted"
        })
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        logger.error(f"Error deleting generator: {e}")
        raise HTTPException(status_code=500, detail=str(e))
```

**Required Repository Method**:
```python
def delete_generator(self, generator_id: str) -> None:
    """Delete a generator."""
    self.conn.execute(
        "DELETE FROM generators WHERE generator_id = ?",
        (generator_id,)
    )
```

---

## 2. Vendors - Get Single & Update

### GET /api/vendors/{vendor_id}
**Purpose**: Get details of a single vendor

```python
@app.get("/api/vendors/{vendor_id}")
async def get_vendor(
    vendor_id: str,
    conn: Connection = Depends(get_connection_dependency),
    user: User = Depends(get_session_user_dependency),
):
    """Get a single vendor by ID."""
    if not user:
        raise HTTPException(status_code=401, detail="Unauthorized")
    
    vendor = VendorRepository(conn).get_vendor(vendor_id)
    if not vendor:
        raise HTTPException(status_code=404, detail="Vendor not found")
    
    return JSONResponse({
        "vendor": {
            "vendor_id": vendor.vendor_id,
            "name": vendor.name,
            "location": vendor.location,
            "phone": vendor.phone,
            "notes": vendor.notes,
        }
    })
```

**Required Repository Method** (add if missing):
```python
def get_vendor(self, vendor_id: str) -> Optional[Vendor]:
    """Get a vendor by ID."""
    row = self.conn.execute(
        "SELECT * FROM vendors WHERE vendor_id = ?",
        (vendor_id,)
    ).fetchone()
    return Vendor(*row) if row else None
```

---

### PUT /api/vendors/{vendor_id}
**Purpose**: Update vendor details

```python
@app.put("/api/vendors/{vendor_id}")
async def update_vendor(
    vendor_id: str,
    request: Request,
    conn: Connection = Depends(get_connection_dependency),
    user: User = Depends(get_session_user_dependency),
):
    """Update an existing vendor."""
    if not user:
        raise HTTPException(status_code=401, detail="Unauthorized")
    
    if user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    try:
        body = await request.json()
        vendor = VendorRepository(conn).get_vendor(vendor_id)
        
        if not vendor:
            raise HTTPException(status_code=404, detail="Vendor not found")
        
        updated_vendor = Vendor(
            vendor_id=vendor_id,
            name=body.get("name", vendor.name),
            location=body.get("location", vendor.location),
            phone=body.get("phone", vendor.phone),
            notes=body.get("notes", vendor.notes),
        )
        
        VendorRepository(conn).update_vendor(updated_vendor)
        conn.commit()
        
        return JSONResponse({
            "status": "success",
            "vendor": {
                "vendor_id": updated_vendor.vendor_id,
                "name": updated_vendor.name,
                "location": updated_vendor.location,
                "phone": updated_vendor.phone,
                "notes": updated_vendor.notes,
            }
        })
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        logger.error(f"Error updating vendor: {e}")
        raise HTTPException(status_code=500, detail=str(e))
```

**Required Repository Method**:
```python
def update_vendor(self, vendor: Vendor) -> None:
    """Update an existing vendor."""
    self.conn.execute(
        """
        UPDATE vendors
        SET name = ?, location = ?, phone = ?, notes = ?
        WHERE vendor_id = ?
        """,
        (vendor.name, vendor.location, vendor.phone, vendor.notes, vendor.vendor_id),
    )
```

---

## 3. Bookings - Update

### PUT /api/bookings/{booking_id}
**Purpose**: Update booking details (vendor, date range, status)

```python
@app.put("/api/bookings/{booking_id}")
async def update_booking(
    booking_id: int,
    request: Request,
    conn: Connection = Depends(get_connection_dependency),
    user: User = Depends(get_session_user_dependency),
):
    """Update an existing booking."""
    if not user:
        raise HTTPException(status_code=401, detail="Unauthorized")
    
    try:
        body = await request.json()
        booking = BookingRepository(conn).get_booking(booking_id)
        
        if not booking:
            raise HTTPException(status_code=404, detail="Booking not found")
        
        # Update booking fields
        updated_booking = Booking(
            booking_id=booking_id,
            vendor_name=body.get("vendor_name", booking.vendor_name),
            start_datetime=body.get("start_datetime", booking.start_datetime),
            end_datetime=body.get("end_datetime", booking.end_datetime),
            status=body.get("status", booking.status),
            notes=body.get("notes", booking.notes),
            created_at=booking.created_at,
            created_by=booking.created_by,
        )
        
        BookingRepository(conn).update_booking(updated_booking)
        conn.commit()
        
        return JSONResponse({
            "status": "success",
            "booking": {
                "booking_id": updated_booking.booking_id,
                "vendor_name": updated_booking.vendor_name,
                "start_datetime": updated_booking.start_datetime,
                "end_datetime": updated_booking.end_datetime,
                "status": updated_booking.status,
                "notes": updated_booking.notes,
            }
        })
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        logger.error(f"Error updating booking: {e}")
        raise HTTPException(status_code=500, detail=str(e))
```

**Required Repository Method**:
```python
def update_booking(self, booking: Booking) -> None:
    """Update an existing booking."""
    self.conn.execute(
        """
        UPDATE bookings
        SET vendor_name = ?,
            start_datetime = ?,
            end_datetime = ?,
            status = ?,
            notes = ?
        WHERE booking_id = ?
        """,
        (
            booking.vendor_name,
            booking.start_datetime,
            booking.end_datetime,
            booking.status,
            booking.notes,
            booking.booking_id,
        ),
    )
```

---

## 4. Billing - Preview with Filters

### GET /api/billing/preview
**Purpose**: Get billing preview with date range and vendor filters

```python
@app.get("/api/billing/preview")
async def get_billing_preview(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    vendor_id: Optional[str] = None,
    conn: Connection = Depends(get_connection_dependency),
    user: User = Depends(get_session_user_dependency),
):
    """Get billing preview with optional filters."""
    if not user:
        raise HTTPException(status_code=401, detail="Unauthorized")
    
    try:
        # Get all billing lines
        billing_lines = BillingRepository(conn).get_billing_lines()
        
        # Filter by date range if provided
        if start_date:
            billing_lines = [
                line for line in billing_lines
                if line.start_datetime >= start_date
            ]
        
        if end_date:
            billing_lines = [
                line for line in billing_lines
                if line.end_datetime <= end_date
            ]
        
        # Filter by vendor if provided
        if vendor_id:
            billing_lines = [
                line for line in billing_lines
                if line.vendor_name == vendor_id  # Adjust based on your schema
            ]
        
        # Group by vendor and calculate totals
        vendor_totals = {}
        for line in billing_lines:
            vendor = line.vendor_name
            if vendor not in vendor_totals:
                vendor_totals[vendor] = {
                    "vendor_name": vendor,
                    "total_amount": 0,
                    "paid_amount": 0,
                    "line_count": 0,
                }
            vendor_totals[vendor]["total_amount"] += line.amount or 0
            vendor_totals[vendor]["paid_amount"] += line.paid_amount or 0
            vendor_totals[vendor]["line_count"] += 1
        
        grand_total = sum(v["total_amount"] for v in vendor_totals.values())
        grand_paid = sum(v["paid_amount"] for v in vendor_totals.values())
        
        return JSONResponse({
            "billing": {
                "vendor_summaries": list(vendor_totals.values()),
                "grand_total": grand_total,
                "grand_paid": grand_paid,
                "grand_balance": grand_total - grand_paid,
                "line_count": len(billing_lines),
            }
        })
    except Exception as e:
        logger.error(f"Error generating billing preview: {e}")
        raise HTTPException(status_code=500, detail=str(e))
```

---

## 5. Admin - Users List & Permissions

### GET /api/users
**Purpose**: List all users (admin only)

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
    
    users = UserRepository(conn).get_all_users()
    
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

**Required Repository Method**:
```python
def get_all_users(self) -> List[User]:
    """Get all users."""
    rows = self.conn.execute("SELECT * FROM users ORDER BY username").fetchall()
    return [User(*row) for row in rows]
```

---

### GET /api/permissions
**Purpose**: Get permission matrix for roles

```python
@app.get("/api/permissions")
async def get_permissions(
    conn: Connection = Depends(get_connection_dependency),
    user: User = Depends(get_session_user_dependency),
):
    """Get permission matrix (admin only)."""
    if not user:
        raise HTTPException(status_code=401, detail="Unauthorized")
    
    if user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    # Return the permission matrix from core/permissions.py
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

## 6. CORS Configuration Update

**Add to backend `.env` file**:

```env
# CORS Configuration - Add mobile app origins
CORS_ALLOWED_ORIGINS=http://localhost:8082,http://127.0.0.1:8082,http://192.162.29.71:8000,http://192.162.29.60:8000

# For development with Flutter on same network:
# May need to add: http://<your-dev-machine-ip>:*
```

**Or in `web/app.py`**, update the CORS middleware:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:8082",
        "http://127.0.0.1:8082",
        "http://192.162.29.71:8000",
        "http://192.162.29.60:8000",
        # Add wildcard for local network during development (remove in production)
        "http://192.162.29.*",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

---

## ✅ Testing Checklist

After adding endpoints, test with curl or Postman:

```bash
# 1. Login to get JWT token
curl -X POST http://192.162.29.60:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"<password>"}'

# 2. Test GET /api/users (use token from step 1)
curl -X GET http://192.162.29.60:8000/api/users \
  -H "Authorization: Bearer <token>"

# 3. Test PUT /api/vendors/{id}
curl -X PUT http://192.162.29.60:8000/api/vendors/V001 \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"name":"Updated Vendor","location":"New Location"}'

# 4. Test DELETE /api/generators/{id}
curl -X DELETE http://192.162.29.60:8000/api/generators/G001 \
  -H "Authorization: Bearer <token>"
```

---

## 📝 Implementation Steps

1. **Backup** `web/app.py` before making changes
2. **Add endpoint functions** to `web/app.py` (copy from above)
3. **Add repository methods** to `core/repositories.py` if missing
4. **Update CORS** configuration in `.env` or `web/app.py`
5. **Restart backend** server: `python main.py`
6. **Test endpoints** with curl/Postman
7. **Deploy to DEV** server first
8. **Test from mobile app** once WO-054 is complete
9. **Deploy to PROD** after mobile integration verified

---

**Estimated Implementation Time**: 4-6 hours  
**Priority**: Complete before assigning WO-054 to Codex
