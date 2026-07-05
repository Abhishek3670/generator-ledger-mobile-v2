# ARCHITECTURE.md — Genset Industrial Ledger (Mobile v2)

> **Architect:** Claude
> **Last Updated:** 2026-07-05

---

## 1. System Overview

```
┌─────────────────────────────────────────────────────┐
│                    Flutter App                       │
│                                                     │
│  ┌─────────────┐  ┌──────────┐  ┌───────────────┐  │
│  │ Presentation │  │  State   │  │   Data/Svc    │  │
│  │   (Screens)  │←→│(Riverpod)│←→│ (Repositories)│  │
│  └─────────────┘  └──────────┘  └───────────────┘  │
│         │                              │            │
│  ┌──────┴──────┐              ┌────────┴────────┐  │
│  │   Widgets   │              │  Mock Data Svc  │  │
│  │ (Components)│              │  (Phase 1)      │  │
│  └─────────────┘              └─────────────────┘  │
└─────────────────────────────────────────────────────┘
```

---

## 2. Project Structure

```
lib/
├── main.dart                        # App entry point
├── app.dart                         # MaterialApp + GoRouter setup
│
├── core/
│   ├── theme/
│   │   ├── app_theme.dart           # ThemeData builder
│   │   ├── app_colors.dart          # Color constants from design tokens
│   │   ├── app_typography.dart      # TextStyle definitions
│   │   └── app_dimensions.dart      # Radii, spacing, elevation tokens
│   ├── routing/
│   │   ├── app_router.dart          # GoRouter configuration
│   │   └── route_names.dart         # Named route constants
│   └── constants/
│       └── app_constants.dart       # App-wide constants
│
├── shared/
│   ├── widgets/
│   │   ├── app_bottom_nav_bar.dart  # 4-tab operational nav
│   │   ├── admin_bottom_nav_bar.dart# 3-tab admin nav
│   │   ├── floating_search_fab.dart # Search bar + FAB combo
│   │   ├── expandable_fab_menu.dart # FAB with expanding options
│   │   ├── status_badge.dart        # Pill badge with prefix icon
│   │   ├── directory_card.dart      # Standard card with dark header
│   │   ├── section_header.dart      # Label-caps + headline + desc
│   │   ├── modal_scaffold.dart      # Floating modal container
│   │   ├── swipe_action_card.dart   # Slidable card wrapper
│   │   ├── backdrop_blur_overlay.dart # Blur overlay for modals/menus
│   │   └── side_navigation_drawer.dart # Hamburger menu drawer
│   └── models/
│       ├── vendor.dart
│       ├── generator.dart
│       ├── booking.dart
│       ├── user.dart
│       ├── billing.dart
│       └── system_health.dart
│
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   │   └── login_screen.dart
│   │   └── providers/
│   │       └── auth_provider.dart
│   │
│   ├── dashboard/
│   │   ├── screens/
│   │   │   └── dashboard_screen.dart
│   │   ├── widgets/
│   │   │   ├── stats_grid.dart
│   │   │   ├── calendar_view.dart
│   │   │   └── daily_bookings_list.dart
│   │   └── providers/
│   │       └── dashboard_provider.dart
│   │
│   ├── bookings/
│   │   ├── screens/
│   │   │   └── bookings_directory_screen.dart
│   │   ├── widgets/
│   │   │   ├── vendor_booking_group.dart
│   │   │   ├── booking_list_item.dart
│   │   │   ├── add_booking_modal.dart
│   │   │   └── edit_booking_modal.dart
│   │   └── providers/
│   │       └── bookings_provider.dart
│   │
│   ├── generators/
│   │   ├── screens/
│   │   │   ├── generators_directory_screen.dart
│   │   │   └── generator_detail_screen.dart
│   │   ├── widgets/
│   │   │   ├── inventory_group_section.dart
│   │   │   ├── generator_card.dart
│   │   │   ├── add_generator_modal.dart
│   │   │   └── generator_detail_modal.dart
│   │   └── providers/
│   │       └── generators_provider.dart
│   │
│   ├── vendors/
│   │   ├── screens/
│   │   │   └── vendor_directory_screen.dart
│   │   ├── widgets/
│   │   │   ├── vendor_card.dart
│   │   │   └── add_vendor_modal.dart
│   │   └── providers/
│   │       └── vendors_provider.dart
│   │
│   ├── billing/
│   │   ├── screens/
│   │   │   └── billing_preview_screen.dart
│   │   ├── widgets/
│   │   │   ├── date_range_filter.dart
│   │   │   ├── capacity_pricing_card.dart
│   │   │   └── billing_line_item.dart
│   │   └── providers/
│   │       └── billing_provider.dart
│   │
│   └── admin/
│       ├── screens/
│       │   ├── system_health_screen.dart
│       │   ├── user_management_screen.dart
│       │   └── integrations_screen.dart
│       ├── widgets/
│       │   ├── metric_card.dart
│       │   ├── sparkline_chart.dart
│       │   ├── user_card.dart
│       │   └── permission_matrix.dart
│       └── providers/
│           ├── system_health_provider.dart
│           └── user_management_provider.dart
│
└── data/
    ├── mock/
    │   ├── mock_vendors.dart
    │   ├── mock_generators.dart
    │   ├── mock_bookings.dart
    │   ├── mock_users.dart
    │   └── mock_system_health.dart
    └── repositories/
        ├── vendor_repository.dart
        ├── generator_repository.dart
        ├── booking_repository.dart
        ├── user_repository.dart
        └── billing_repository.dart
```

---

## 3. Design System → Flutter Mapping

### Colors (AppColors)
| Token | Hex | Flutter Constant |
|-------|-----|-----------------|
| primary | `#0f172a` | `AppColors.primary` |
| primary_dark | `#1e293b` | `AppColors.primaryDark` |
| accent | `#fbbf24` | `AppColors.accent` |
| success | `#059669` | `AppColors.success` |
| warning | `#d97706` | `AppColors.warning` |
| danger | `#dc2626` | `AppColors.danger` |
| surface | `#f9f9f9` | `AppColors.surface` |
| surface_container | `#f3f3f3` | `AppColors.surfaceContainer` |
| background | `#fafafa` | `AppColors.background` |
| border | `#cbd5e1` | `AppColors.border` |
| text_secondary | `#475569` | `AppColors.textSecondary` |

### Typography (AppTypography)
| Token | Font | Size | Weight | Usage |
|-------|------|------|--------|-------|
| display-lg | Space Grotesk | 32 | 600 | Page titles |
| headline-md | Space Grotesk | 24 | 700 | Section headers |
| headline-sm | Space Grotesk | 18 | 600 | Card headers |
| body-md | Inter | 16 | 400 | Body text |
| body-sm | Inter | 14 | 400 | Secondary text |
| label-caps | Space Grotesk | 11 | 600 | Category labels (uppercase, 0.2em tracking) |

### Shapes (AppDimensions)
| Element | Radius | Flutter |
|---------|--------|---------|
| Structural panels | 16px | `BorderRadius.circular(16)` |
| Functional elements | 8px | `BorderRadius.circular(8)` |
| Pill (buttons/badges) | 9999px | `BorderRadius.circular(9999)` or `StadiumBorder()` |
| Modal | 12px | `BorderRadius.circular(12)` |

### Elevation
| Style | Flutter Implementation |
|-------|----------------------|
| Card border | `Border.all(color: AppColors.border, width: 1)` |
| Stats card shadow | `BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x0D0F172A))` |
| No heavy shadows | Flat aesthetic — borders only |

---

## 4. Navigation Graph

```
                    ┌──────────┐
                    │  Login   │
                    └────┬─────┘
                         │ auth success
                    ┌────▼─────┐
              ┌─────│ App Shell│──────┐
              │     └────┬─────┘      │
              │          │            │
         ┌────▼────┐ ┌───▼───┐  ┌────▼─────┐
         │Dashboard│ │Bottom │  │  Drawer   │
         │         │ │ Nav   │  │  Menu     │
         └────┬────┘ └───┬───┘  └────┬──────┘
              │          │           │
    ┌─────────┼──────────┼───────────┼──────────┐
    │         │          │           │           │
┌───▼──┐ ┌───▼──┐  ┌────▼───┐ ┌────▼───┐ ┌────▼────┐
│Dash  │ │Book  │  │Gensets │ │Vendors │ │Billing  │
│board │ │ings  │  │Dir     │ │Dir     │ │Preview  │
└──┬───┘ └──┬───┘  └───┬────┘ └───┬────┘ └─────────┘
   │        │          │          │
   │   ┌────┴────┐  ┌──┴───┐  ┌──┴──────┐
   │   │Add/Edit │  │Detail│  │Add      │
   │   │Booking  │  │View  │  │Vendor   │
   │   │Modals   │  │+Modal│  │Modal    │
   │   └─────────┘  │+Add  │  └─────────┘
   │                │Modal │
   │                └──────┘
   │
   └──────── Settings ──────┐
                             │
              ┌──────────────┼──────────────┐
              │              │              │
         ┌────▼───┐   ┌─────▼────┐  ┌──────▼──────┐
         │System  │   │User Mgmt │  │Integrations │
         │Health  │   │+Perms    │  │(Coming Soon)│
         └────────┘   └──────────┘  └─────────────┘
```

### GoRouter Structure
```dart
GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: → LoginScreen),
    GoRoute(path: '/billing', builder: → BillingPreviewScreen),
    StatefulShellRoute.indexedStack(
      builder: → _OperationalShell (with AppBottomNavBar & SideNavigationDrawer),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/dashboard', builder: → DashboardScreen)]),
        StatefulShellBranch(routes: [GoRoute(path: '/bookings', builder: → BookingsDirectoryScreen)]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/generators',
            builder: → GeneratorsDirectoryScreen,
            routes: [GoRoute(path: ':id', builder: → GeneratorDetailScreen)],
          )
        ]),
        StatefulShellBranch(routes: [GoRoute(path: '/vendors', builder: → VendorDirectoryScreen)]),
      ],
    ),
    StatefulShellRoute.indexedStack(
      builder: → _AdminShell (with AdminBottomNavBar & SideNavigationDrawer),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/admin/health', builder: → SystemHealthScreen)]),
        StatefulShellBranch(routes: [GoRoute(path: '/admin/users', builder: → UserManagementScreen)]),
        StatefulShellBranch(routes: [GoRoute(path: '/admin/integrations', builder: → IntegrationsScreen)]),
      ],
    ),
  ],
)
```

---

## 5. State Management

### Provider Architecture (Riverpod)
```
┌──────────────────────────────────────────┐
│              UI Layer                     │
│  Screens consume providers via ref.watch │
└──────────────┬───────────────────────────┘
               │
┌──────────────▼───────────────────────────┐
│         State Notifiers                   │
│  BookingsNotifier, VendorsNotifier, etc. │
│  Manage loading/error/data states        │
└──────────────┬───────────────────────────┘
               │
┌──────────────▼───────────────────────────┐
│          Repositories                     │
│  Abstract interface → Mock implementation│
│  Future: swap in API implementations     │
└──────────────────────────────────────────┘
```

---

## 6. Key Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.5.0
  go_router: ^14.0.0
  google_fonts: ^6.0.0
  table_calendar: ^3.1.0
  fl_chart: ^0.68.0
  flutter_slidable: ^3.1.0
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
  flutter_lints: ^4.0.0
```

---

## 7. Constraints & Decisions

| ID | Decision | Rationale |
|----|----------|-----------|
| D-ARCH-001 | Feature-first folder structure | Scales better than layer-first for this screen count |
| D-ARCH-002 | Modals as widgets, not routes | Modals overlay existing screens per design |
| D-ARCH-003 | Mock data in v1.0 | No backend API yet; repository pattern enables future swap |
| D-ARCH-004 | Shared components in `shared/widgets/` | 12 components reused across 3+ screens |
| D-ARCH-005 | Bottom nav as ShellRoute | Preserves nav state across tab switches |

---

*This document is the architectural source of truth. Changes require Claude approval.*
