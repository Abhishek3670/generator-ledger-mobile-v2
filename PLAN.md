# PLAN.md — Genset Industrial Ledger (Mobile v2)

> **Product Owner:** CEO
> **Architect:** Claude
> **Release Target:** 1.0.0
> **Platform:** Flutter (Android + iOS)
> **Last Updated:** 2026-06-28

---

## 1. Product Vision

A **high-density industrial management mobile application** for generator fleet operators and logistics managers. The app enables real-time tracking of generators (gensets), vendor relationships, booking workflows, billing calculations, and system health monitoring.

Built as a **Flutter mobile app** with the **Genset Industrial Ledger Design System** — a flat, corporate-modern aesthetic using Deep Slate Navy (#0f172a) primary, Industrial Amber (#fbbf24) accent, and a dual-font strategy (Space Grotesk headlines + Inter body).

---

## 2. Screen Inventory (18 Screens)

### A. Authentication
| # | Screen | Design Reference |
|---|--------|-----------------|
| 1 | Login | `screens/login/` |

### B. Core Management (Directories)
| # | Screen | Design Reference |
|---|--------|-----------------|
| 2 | Dashboard (w/ Side Nav) | `screens/mobile_dashboard_with_side_navigation/` |
| 3 | Dashboard (Refined v2) | `screens/refined_mobile_dashboard_v2/` |
| 4 | Bookings Directory | `screens/aligned_mobile_bookings_directory/` |
| 5 | Generators Directory | `screens/updated_generators_directory_with_vertical_action_menu/` |
| 6 | Vendor Directory | `screens/mobile_vendor_directory_with_backdrop_blur/` |

### C. Interaction Modals (Floating Forms)
| # | Screen | Design Reference |
|---|--------|-----------------|
| 7 | Add Booking Modal | `screens/floating_add_booking_modal/` |
| 8 | Add Booking Modal (Updated) | `screens/floating_add_booking_modal_updated/` |
| 9 | Add Generator Modal | `screens/floating_add_generator_modal/` |
| 10 | Add Vendor Modal | `screens/floating_add_vendor_modal/` |
| 11 | Edit Booking Modal | `screens/floating_edit_booking_modal/` |
| 12 | Generator Detail Modal | `screens/floating_generator_detail_modal/` |

### D. Detail Views
| # | Screen | Design Reference |
|---|--------|-----------------|
| 13 | Generator Detail View | `screens/generator_detail_view/` |
| 14 | Billing Preview | `screens/mobile_billing_preview/` |

### E. Settings & Admin
| # | Screen | Design Reference |
|---|--------|-----------------|
| 15 | System Health Monitor | `screens/updated_system_monitor/` |
| 16 | User Management + Permissions | `screens/user_management_with_permission_matrix/` |
| 17 | Integrations (Coming Soon) | `screens/integrations_coming_soon/` |

### F. Design System Reference (Not a screen)
| # | Screen | Design Reference |
|---|--------|-----------------|
| 18 | Design System Spec | `screens/genset_industrial_ledger/` |

---

## 3. Navigation Architecture

### Primary Bottom Nav (4 tabs — Operational)
1. **Dashboard** → Screens 2, 3
2. **Bookings** → Screens 4, 7, 8, 11
3. **Genset** → Screens 5, 9, 12, 13
4. **Vendors** → Screens 6, 10

### Admin Bottom Nav (3 tabs — Settings)
1. **Health** → Screen 15
2. **Users** → Screen 16
3. **Integrations** → Screen 17

### Standalone
- **Login** → Screen 1 (pre-auth)
- **Billing Preview** → Screen 14 (from side drawer)

### Side Navigation Drawer
- Accessed via hamburger menu on Dashboard
- Links: Dashboard, Billing Preview, Settings, Logout
- User avatar, name, role display

---

## 4. Data Entities

| Entity | Key Fields |
|--------|------------|
| **User** | username, password, role (admin/operator), status, last_login, created_at |
| **Vendor** | vendor_id, name, type (Retailer/Rental), location, phone |
| **Generator** | generator_id, capacity (kVA), type, inventory_group (Retailer/Permanent/Emergency), operational_status (Active/Maintenance/Retired), assigned_vendor (for Permanent) |
| **Booking** | booking_id, vendor, generators[], date_range, status (Confirmed/Pending/Cancelled), notes |
| **Billing** | vendor, bookings[], price_per_capacity, line_amount, vendor_total, paid, remainder |
| **SystemHealth** | cpu, memory, temperature, db_connection, app_version, build_info |
| **Permission** | capability, admin_access, operator_access |

---

## 5. Milestones

### M1: Foundation (WO-001 through WO-004)
**Goal:** Flutter project scaffold, design system, shared components, navigation shell.

| WO | Task | Assignee | Dependencies |
|----|------|----------|--------------|
| WO-001 | Flutter project creation + folder structure + dependencies | Codex | None |
| WO-002 | Design system implementation (AppTheme, colors, typography, tokens) | Gemini | WO-001 |
| WO-003 | Shared components (BottomNavBar, FAB, StatusBadge, SearchBar, DirectoryCard, SectionHeader, ModalScaffold) | Gemini | WO-002 |
| WO-004 | Navigation shell (GoRouter: auth flow, bottom nav tabs, admin tabs, drawer) | Gemini | WO-003 |

### M2: Core Screens (WO-005 through WO-009)
**Goal:** All 5 directory/primary screens implemented with mock data.

| WO | Task | Assignee | Dependencies |
|----|------|----------|--------------|
| WO-005 | Login screen | Gemini | WO-002, WO-004 |
| WO-006 | Dashboard screen (calendar, stats, daily bookings, side drawer) | Gemini | WO-003, WO-004 |
| WO-007 | Bookings Directory screen (vendor-grouped booking list, floating search+FAB) | Gemini | WO-003, WO-004 |
| WO-008 | Generators Directory screen (inventory groups, swipe-to-modify, date filter) | Gemini | WO-003, WO-004 |
| WO-009 | Vendor Directory screen (retailer/rental sections, expandable FAB, backdrop blur) | Gemini | WO-003, WO-004 |

### M3: Modals & Detail Views (WO-010 through WO-015)
**Goal:** All interaction modals and detail screens implemented.

| WO | Task | Assignee | Dependencies |
|----|------|----------|--------------|
| WO-010 | Add Booking Modal (vendor search, calendar range, capacity toggle) | Gemini | WO-007 |
| WO-011 | Edit Booking Modal (inline generator editing, swipe-to-delete, reorder) | Gemini | WO-007 |
| WO-012 | Add Generator Modal (capacity chips, inventory group, status dropdown) | Gemini | WO-008 |
| WO-013 | Generator Detail View + Detail Modal (quick booking, recent history) | Gemini | WO-008 |
| WO-014 | Add Vendor Modal (type selector, form fields) | Gemini | WO-009 |
| WO-015 | Billing Preview screen (date range filter, capacity pricing, vendor totals) | Gemini | WO-006 |

### M4: Admin & Polish (WO-016 through WO-019)
**Goal:** Admin screens, state management, polish.

| WO | Task | Assignee | Dependencies |
|----|------|----------|--------------|
| WO-016 | System Health Monitor (metrics cards, sparklines, status indicators) | Gemini | WO-004 |
| WO-017 | User Management + Permission Matrix (CRUD, role matrix) | Gemini | WO-004 |
| WO-018 | Integrations Coming Soon (placeholder) | Gemini | WO-004 |
| WO-019 | State management layer (Riverpod providers, mock data service) | Codex | WO-005 through WO-018 |

---

## 6. Shared Component Catalog

These components are reused across 3+ screens and must be built in WO-003:

| Component | Used In |
|-----------|---------|
| `AppBottomNavBar` | All operational screens (4-tab) |
| `AdminBottomNavBar` | All admin screens (3-tab) |
| `FloatingSearchFAB` | Bookings, Generators, Vendors directories |
| `ExpandableFABMenu` | Generators, Vendors directories |
| `StatusBadge` | Bookings, Generators, Users, System Health |
| `DirectoryCard` | Bookings, Generators, Vendors |
| `DarkHeaderCard` | Bookings (vendor groups), Generators (inventory groups) |
| `SectionHeader` | All directory screens |
| `ModalScaffold` | All floating modal screens |
| `SwipeActionCard` | Bookings (edit), Generators directory |
| `BackdropBlurOverlay` | Vendor FAB menu, All modals |
| `SideNavigationDrawer` | Dashboard |

---

## 7. Technology Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Framework | Flutter | Cross-platform mobile, CEO decision |
| State Mgmt | Riverpod | Recommended for Flutter, scalable |
| Navigation | GoRouter | Declarative routing, deep link support |
| Fonts | google_fonts package | Space Grotesk + Inter |
| Charts | fl_chart | Sparkline charts for System Health |
| Swipe Actions | flutter_slidable | Swipe-to-modify/delete on cards |
| Calendar | table_calendar | Month view with booking counts |
| Icons | Material Icons | Per design system spec |

---

## 8. Quality Gates

- All screens must match design system specs (AGENTS.md §DESIGN_SYSTEM_RULES)
- Each screen validated against HTML reference in `stitch_generator_ledger_design/screens/`
- Gemma reviews each WO before completion
- No screen ships without status badge accessibility prefixes (✓, ⏱, ✕)
- All buttons must be pill-shaped per spec
- All borders must use #cbd5e1, 1px solid

---

*This plan is the source of truth for milestone tracking and work order creation.*
