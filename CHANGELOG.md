# Changelog

All notable changes to the generator-ledger-mobile-v2 project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.3] - 2026-07-16

### Added
- **Custom Top Toast Notifications** — Slides from top, 4 variants (success, warning, error, info), replaces all Material snackbars
- **Billing: Dynamic Capacity Tiers** — Pricing grid now auto-populated from API response (WO-100)
- **Billing: Grouped Vendor Cards** — Mobile-friendly card layout replaces desktop table
- **Billing: Compact Date Range Picker** — Single field "DD-MM-YYYY / DD-MM-YYYY" with range picker
- **Billing: Screenshot Prevention** — FLAG_SECURE on Android, detection on iOS (billing screen only)
- **Generators: Booking Status Badges** — "Booked" / "Free" per generator when date filter active
- **Generators: Filter Bottom Sheet** — Single filter icon opens sheet with Booking Status + Sort options
- **Generators: "Show More" Pattern** — 5 items per category, expandable
- **Generators: Detail Modal** — Tap row opens read-only modal with pencil to edit
- **Vendors: Detail Modal** — Tap row opens read-only modal with pencil to edit
- **Vendors: "Show More" Pattern** — 5 items per category, expandable
- **401 Auto-Redirect** — Token expired automatically navigates to login with toast notification

### Changed
- **Edit Booking Modal** — Full redesign: generator list editor with swipe-to-delete, FAB adds new (WO-099)
- **AddBookingModal** — Accepts `lockedVendorId` to disable vendor dropdown when opened from Edit modal
- **Booking Detail Modal** — Simplified info card, vendor as heading, pencil icon edit, capacity column added
- **Dashboard** — Removed redundant calendar section header
- **Generators Directory** — Removed description text, compact date filter pill, Type "N/A" fallback
- **Generators: Edit Modal** — Generator ID and Capacity now read-only; dropdown crash fixed (case mismatch)
- **Vendors Directory** — Removed description text, "nan" → "N/A", both Retailer + Rental sections
- **Vendor Detail Modal** — Phone icon prefix, tighter spacing
- **Billing** — Removed Load/Print buttons, auto-loads on date selection, no default dates
- **Billing** — "X lines" → "X Bookings", dark card header, PAID input overflow fixed
- **Billing** — Removed duplicate vendor search field
- **Billing** — "INCLUDE GRAND TOTAL" checkbox moved to right side

### Fixed
- Edit Generator dropdown assertion crash (status/category case mismatch)
- Billing PAID input "0" overflowing container
- Vendor location showing "nan" for null values

## [1.0.0] - 2026-07-07

### Added

#### Core Management Features
- **Dashboard Screen** with calendar view, stats cards, and daily bookings overview
- **Bookings Directory** with vendor-grouped booking list and floating search
- **Generators Directory** with inventory categorization (Retailer, Permanent, Emergency)
- **Vendor Directory** with retailer/rental sections and search functionality
- **Side Navigation Drawer** with user profile, menu links, and logout

#### Booking Management
- Add Booking modal with vendor search and calendar range picker
- Edit Booking modal with generator assignment (ID or capacity-based)
- Multi-generator booking support with individual capacity display
- Status tracking (Confirmed, Pending, Cancelled)
- Date range selection with native date pickers

#### Generator Management
- Add Generator modal with capacity selection and inventory grouping
- Generator detail view with specifications and recent history
- Operational status tracking (Active, Maintenance, Retired)
- Capacity-based filtering and search
- Multi-generator booking display (separate lines with individual capacity)

#### Vendor Management
- Add Vendor modal with type selection (Retailer/Rental)
- Vendor profiles with contact information and location
- Vendor-grouped booking views
- Search and filter functionality

#### Billing & Reporting
- Billing Preview screen with date range filtering
- Capacity-based pricing calculations
- Vendor-wise billing summaries
- Rate per kVA input
- Paid amount tracking with remainder calculation
- Grand total with sticky header and footer

#### Admin Features
- System Health Monitor with real-time metrics (CPU, memory, temperature)
- User Management with permission matrix
- Role-based access control (Admin, Operator)
- User status management
- Integrations placeholder screen

#### Backend API Integration
- RESTful API client with Dio HTTP library
- JWT authentication with secure token storage
- Repository pattern for all entities (Vendors, Generators, Bookings, Billing, Users)
- Automatic token refresh on authentication
- API error handling with typed exceptions
- Request/response interceptors

#### State Management
- Riverpod providers for all features
- FutureProvider for async data loading
- StateProvider for filters and date ranges
- StreamProvider for real-time updates
- Offline data caching with connectivity detection

#### Error Handling & UX
- Loading states with spinners for all async operations
- Error screens with retry buttons
- User-friendly error messages
- Offline mode with cached data
- Network status indicators
- Form validation with inline errors

#### Design System
- Genset Industrial Ledger Design System implementation
- Flat, corporate-modern aesthetic
- Deep Slate Navy (#0f172a) primary color
- Industrial Amber (#fbbf24) accent color
- Space Grotesk typography for headlines
- Inter typography for body text
- Pill-shaped buttons (9999px radius)
- Consistent 8px/16px border radius for cards
- Status badges with accessibility prefixes (✓, ⏱, ✕)
- 1px solid borders (#cbd5e1)
- Backdrop blur overlays for modals
- Floating search FAB (56×56px)

#### Testing & Quality
- 98 automated widget tests
- Unit tests for repositories
- Provider testing with mocked data
- Widget testing with test harness
- Test coverage for all core features
- Static analysis with 0 issues

### Changed
- Moved from mock data to live API integration
- Updated booking display to show all generators for multi-generator bookings
- Improved date selection with native date pickers
- Enhanced dropdown error handling for edge cases
- Standardized FloatingSearchFAB size across all screens
- Unified admin navigation bar styling

### Fixed
- Booking details screen dropdown error for multi-generator bookings (WO-066)
- Multi-generator booking display showing only first generator (WO-065)
- Billing screen date picker not opening (WO-064)
- Billing endpoint 404 errors with correct API path
- Booking capacity display using database values instead of regex parsing
- Dropdown assertion errors with defensive item composition

### Technical
- **Platform**: Flutter 3.35.5
- **Language**: Dart 3.9.x
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **HTTP Client**: Dio
- **Local Storage**: SharedPreferences
- **Connectivity**: connectivity_plus
- **Date/Time**: intl
- **Testing**: flutter_test
- **Architecture**: Repository pattern, Provider architecture
- **API Base URL**: http://192.168.29.60:8001/api/

### Known Issues
- Multi-generator bookings: Edit modal shows only first generator (full edit support planned for M13)
- Billing export: PDF/CSV export not yet implemented
- Offline mode: Limited to view-only, no offline create/update operations

### Security
- JWT token-based authentication
- Secure token storage with SharedPreferences
- Automatic token refresh on 401 responses
- API request authentication with Bearer tokens
- Input validation on all forms

## [1.0.2] - 2026-07-13

### Added
- **Booking Detail View Modal** — tap a booking to see read-only details (vendor, status, dates, assigned generators), Edit button opens edit modal (WO-098)
- **Custom app icon** — Genset amber generator logo on navy adaptive background
- **Native splash screen** — centered logo with optical centering on navy background
- **App renamed** from "ledger" to "Genset"

### Fixed
- **Critical: Connection pool exhaustion** — replaced 30+ per-vendor API calls with single batch endpoint `/api/vendors/bookings/all`
- **Critical: Calendar wrong data** — now uses dedicated `/api/calendar/events` and `/api/calendar/day` endpoints (matches web exactly)
- **Booking creation** — `toMap()` now sends proper `items[]` array matching backend's `CreateBookingRequest` schema
- **Booking creation response** — handles `{success, booking_id}` response instead of trying to parse as full Booking
- **Calendar day status** — injected 'confirmed' status for calendar-day bookings (endpoint only returns confirmed but had no status field)
- **Calendar overcount** — deduplicated bookings by ID before counting
- **Logout** — corrected endpoint from `DELETE /logout` to `POST /api/logout`
- **Release build networking** — added INTERNET permission and cleartext traffic flag for HTTP API access
- **Discard draft** — now clears pre-selected vendor from SharedPreferences

### Changed
- **Assets organized** into proper `assets/icons/` and `assets/images/` structure
- **Removed unnecessary files** from repo (.docs/, planning docs, UI verification reports)

### Technical
- 143 automated tests passing
- Flutter analyze: 0 issues
- App icon generation via `flutter_launcher_icons`
- Splash screen via `flutter_native_splash`
- Optical centering with visual weight point compensation

## [1.0.1] - 2026-07-12

### M13 Post-Launch Remediation (Batch 1 + Batch 2)

#### Fixed
- **Dashboard stat cards** uneven height when category breakdowns present — enforced uniform height via IntrinsicHeight + 16px padding (WO-089, WO-093, WO-094)
- **Generator assignment toggle** inverted Switch value logic corrected (WO-089)
- **Vendor 3-dot menu** removed, swipe state no longer persists across navigation (WO-090)
- **Calendar date-range counting** — bookings spanning multiple days now counted on every day in range (WO-091)
- **Booking list display** — per-generator capacity shown, date ranges displayed, vendor sort applied (WO-092)
- **Billing buttons** — replaced text labels ("PRINT"/"LOAD") with icon-only buttons (Icons.print/Icons.download), moved inline with "Include Grand Total" checkbox (WO-096)
- **Status badge** — "CONFIRMED" text removed, replaced with ✓ icon-only pill badge (WO-095)

#### Changed
- **Booking list** now groups gensets by individual per-item `start_dt` instead of showing all generators under a single date range (WO-095, WO-097)
- **Booking data source** switched from `/api/bookings` (minimal) to `/api/vendors/{id}/bookings` (full items with per-item dates) via new `vendorBookingsProvider` (WO-097)
- **Emergency gensets** rendered in red text using `is_emergency` flag from API (WO-095)
- **Dashboard stat cards** now show category breakdowns: gensets by type (retailer + permanent + emergency), vendors by type (retailer + rental) (WO-093)

#### Added
- `BookingItem` data model preserving per-item `start_dt`, `is_emergency`, `capacity_kva` (WO-097)
- `Booking.groupItemsByDate()` method for date-grouped rendering (WO-097)
- `vendorBookingsProvider` Riverpod family provider for per-vendor API calls (WO-097)
- `BookingRepository.getVendorBookings()` calling `/api/vendors/{id}/bookings` (WO-097)

#### Technical
- 142 automated tests passing
- Flutter analyze: 0 issues
- All changes on `release/v1.0.0` branch

## [Unreleased]

### Planned
- Empty states & onboarding (ON HOLD per CEO decision)
- PDF/CSV export functionality for billing
- Enhanced offline mode with create/update support
- Dark mode support
- Push notifications for booking reminders
- Advanced filtering and search
- Performance optimizations

---

## Version History

- **1.0.2** (2026-07-13) - Booking detail modal, calendar API fix, app branding, critical bugfixes
- **1.0.1** (2026-07-12) - Post-launch remediation (9 fixes across 2 batches)
- **1.0.0** (2026-07-07) - Initial production release ("Genesis")
- **1.0.0-rc.1** (2026-07-07) - Release candidate 1

## Contributors

- **Codex** - Backend API integration, authentication, repositories
- **Gemini** - Frontend screens, modals, UI components, API integration
- **Gemma** - Quality assurance, testing, reviews
- **Claude** - Architecture, planning, coordination
- **Local-LLM** - GitOps, release management

---

[1.0.2]: https://github.com/Abhishek3670/generator-ledger-mobile-v2/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/Abhishek3670/generator-ledger-mobile-v2/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/Abhishek3670/generator-ledger-mobile-v2/releases/tag/v1.0.0
