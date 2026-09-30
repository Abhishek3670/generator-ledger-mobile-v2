# Backend API Enhancement Request

**Date**: 2026-07-06  
**Requestor**: Mobile Team (Flutter App)  
**Priority**: Medium (Post-v1.0 Enhancement)  
**Status**: ✅ **COMPLETED** (2026-07-06)

## Implementation Summary

The backend `/api/bookings` endpoint has been successfully enhanced to include generator details in the list response. The mobile app now displays actual generator IDs and capacities instead of "N/A".

### What Was Implemented

Backend now returns:
```json
[
  {
    "id": "BKG-20260227-00001",
    "vendor_id": "VEN005",
    "vendor_name": "Mallu",
    "created_at": "2026-02-27 23:56",
    "status": "Confirmed",
    "items": [
      {
        "generator_id": "GEN-30KVA-PL-RBHA-04",
        "capacity_kva": 30
      }
    ]
  }
]
```

### Verification

Mobile app successfully displays:
- ✅ Real generator IDs (e.g., "GEN-30KVA-PL-RBHA-04")
- ✅ Real capacities (e.g., "30 kVA", "190 kVA")
- ✅ Summed capacities for multi-generator bookings (e.g., "315 kVA" for 3 generators)

### Technical Notes

- Backend reuses existing `get_items_with_capacity()` query
- Vendor names resolved via in-memory lookup to avoid N+1 queries
- Mobile app maintains backward compatibility with legacy format
- All 84 tests passing

---

## Original Request (Archive)

## Summary

The mobile app successfully integrates with the backend API, but the `/api/bookings` list endpoint returns minimal data compared to what the web UI displays. This document requests an enhancement to include generator details in the bookings list response.

## Current State

### What Works
- `/api/bookings` returns basic booking metadata:
  ```json
  [
    {
      "id": "BKG-20260227-00001",
      "vendor_id": "VEN005",
      "created_at": "2026-02-27 23:56",
      "status": "Confirmed"
    }
  ]
  ```

- `/api/bookings/{id}` returns full details including items:
  ```json
  {
    "booking": {
      "id": "BKG-20260227-00001",
      "vendor_id": "VEN005",
      "created_at": "2026-02-27 23:56",
      "status": "Confirmed"
    },
    "items": [
      {
        "id": 105,
        "generator_id": "GEN001",
        "capacity_kva": 125,
        "inventory_type": "retailer",
        "start_dt": "2026-02-28 08:00",
        "end_dt": "2026-02-28 18:00",
        "status": "Confirmed"
      }
    ]
  }
  ```

### What the Web UI Has

The web UI's `/bookings` page displays generator IDs and capacities by calling:
```python
booking_repo.get_items_with_capacity(booking_id)
```

This query retrieves items from `booking_items` joined with the `generators` table, and formats labels like:
```python
label = f"{generator_id} ({capacity_kva} kVA)"
```

## Problem

The mobile app bookings list currently shows:
- ✅ Vendor name
- ✅ Date
- ✅ Status
- ❌ Generator details (shows "N/A")

Users cannot see which generators are booked without tapping each booking.

## Requested Enhancement

### Option 1: Enhance `/api/bookings` List Response (Recommended)

Add an embedded `items` array or summary fields to the list response:

```json
[
  {
    "id": "BKG-20260227-00001",
    "vendor_id": "VEN005",
    "vendor_name": "Mallu",
    "created_at": "2026-02-27 23:56",
    "status": "Confirmed",
    "items": [
      {
        "generator_id": "GEN001",
        "capacity_kva": 125
      }
    ],
    "total_capacity": 125,
    "generator_count": 1
  }
]
```

**Benefits**:
- Single API call for list view
- Consistent with web UI display
- Better mobile performance

**Implementation**: Reuse existing `get_items_with_capacity()` query in the list endpoint.

### Option 2: Add Summary Fields Only

If embedding full items is too heavy, add just summary fields:

```json
[
  {
    "id": "BKG-20260227-00001",
    "vendor_id": "VEN005",
    "vendor_name": "Mallu",
    "created_at": "2026-02-27 23:56",
    "status": "Confirmed",
    "generator_ids": ["GEN001", "GEN002"],
    "total_capacity": 225
  }
]
```

## Workaround (Current Mobile Implementation)

The mobile app currently:
1. Fetches `/api/bookings` (minimal data)
2. Displays "N/A (N/A)" for generator/capacity
3. Users must tap booking to see full details

This works but provides a degraded user experience compared to the web UI.

## Alternative Workaround (Not Recommended)

Mobile app could make N+1 API calls:
1. Fetch `/api/bookings` (list)
2. For each booking, fetch `/api/bookings/{id}` (details)

**Downside**: Poor performance, especially on slow networks.

## Impact Assessment

- **Mobile App**: Medium priority - app functions but UX is degraded
- **Backend Effort**: Low - reuse existing query logic
- **API Breaking Change**: No - this is additive only
- **Version**: Target for v1.1 or post-v1.0 patch

## Questions

1. Is there a performance concern with including items in the list response?
2. Should we paginate the bookings list if it grows large?
3. Would you prefer Option 1 (full items) or Option 2 (summary only)?

## Contact

For questions or clarification, contact the mobile dev team.
