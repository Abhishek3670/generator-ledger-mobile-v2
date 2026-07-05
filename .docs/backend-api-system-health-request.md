# Backend API Enhancement Request: System Health Endpoint

**Date**: 2026-07-06T02:28:00+05:30  
**Requestor**: Mobile App Team  
**Priority**: P1  
**Status**: ✅ IMPLEMENTED (2026-07-06T02:50:00+05:30)

---

## Issue

Mobile app WO-061 (System Health API Integration) has been completed and deployed, but the backend endpoint is returning 404:

```
GET http://192.168.29.60:8001/api/system/health
Status: 404 Not Found
```

## Actual Backend Implementation

**Implemented**: 2026-07-06T02:50:00+05:30

The backend team implemented the endpoint with the following format:

```json
{
  "status": "healthy",
  "app": "Generator Booking Ledger",
  "version": "4.0.4",
  "database": {
    "status": "connected",
    "type": "postgresql",
    "latency_ms": 9.27,
    "pool": null
  }
}
```

**Mobile App Adaptation**: The mobile app has been updated to parse this format. It maps:
- `version` → `appVersion`
- `database.status` → `dbConnection` ("connected" → "healthy")
- `database.latency_ms` → used as a health metric proxy

The app handles both the original mock format (for tests) and this actual backend format seamlessly.

---

## Required Endpoint (Original Request)

### GET /api/system/health

**Description**: Returns real-time system metrics for admin dashboard monitoring.

**Authentication**: Required (admin role)

**Response Format** (one of these formats):

#### Option 1: Flat structure
```json
{
  "cpu_usage": 45.2,
  "memory_usage": 67.8,
  "disk_usage": 32.1,
  "database_status": "healthy",
  "active_connections": 12,
  "uptime_seconds": 86400,
  "app_version": "1.0.0"
}
```

#### Option 2: Wrapped structure
```json
{
  "health": {
    "cpu_usage": 45.2,
    "memory_usage": 67.8,
    "disk_usage": 32.1,
    "database_status": "healthy",
    "active_connections": 12,
    "uptime_seconds": 86400,
    "app_version": "1.0.0"
  }
}
```

**Note**: Mobile app already supports both formats via the SystemHealthRepository parser.

## Required Fields

| Field | Type | Description | Required |
|-------|------|-------------|----------|
| cpu_usage | float | CPU usage percentage (0-100) | Yes |
| memory_usage | float | Memory usage percentage (0-100) | Yes |
| disk_usage | float | Disk usage percentage (0-100) | Optional |
| database_status | string | "healthy", "degraded", "down" | Yes |
| active_connections | int | Current active database connections | Optional |
| uptime_seconds | int | Server uptime in seconds | Optional |
| app_version | string | Backend application version | Optional |

## Mobile App Implementation

The mobile app will:
1. Poll this endpoint every 30 seconds when System Health screen is active
2. Display metrics in real-time cards
3. Track last 20 samples for sparkline charts
4. Handle both response formats automatically

## Current State

- ✅ Mobile app code: COMPLETED (commit 95aee0b)
- ✅ Mobile app tests: 89/89 passing
- ❌ Backend endpoint: **NOT IMPLEMENTED** (404)

## Request

Please implement the `/api/system/health` endpoint with the above specification. The mobile app is ready to consume it as soon as it's available.

---

## Testing

Once implemented, test with:

```bash
# Login first (admin user)
curl -X POST http://192.168.29.60:8001/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"abhishek","password":"<password>"}'

# Get token from response, then:
curl -X GET http://192.168.29.60:8001/api/system/health \
  -H "Authorization: Bearer <token>"
```

Expected: 200 OK with health metrics JSON

---

**Contact**: Mobile team ready to test as soon as endpoint is live.
