# Graph Report - generator-ledger-mobile-v2  (2026-07-02)

## Corpus Check
- 147 files · ~124,352 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 972 nodes · 1168 edges · 111 communities (96 shown, 15 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 8 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `4126302b`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 32|Community 32]]
- [[_COMMUNITY_Community 33|Community 33]]
- [[_COMMUNITY_Community 34|Community 34]]
- [[_COMMUNITY_Community 35|Community 35]]
- [[_COMMUNITY_Community 36|Community 36]]
- [[_COMMUNITY_Community 37|Community 37]]
- [[_COMMUNITY_Community 38|Community 38]]
- [[_COMMUNITY_Community 39|Community 39]]
- [[_COMMUNITY_Community 40|Community 40]]
- [[_COMMUNITY_Community 41|Community 41]]
- [[_COMMUNITY_Community 42|Community 42]]
- [[_COMMUNITY_Community 43|Community 43]]
- [[_COMMUNITY_Community 44|Community 44]]
- [[_COMMUNITY_Community 45|Community 45]]
- [[_COMMUNITY_Community 46|Community 46]]
- [[_COMMUNITY_Community 47|Community 47]]
- [[_COMMUNITY_Community 48|Community 48]]
- [[_COMMUNITY_Community 49|Community 49]]
- [[_COMMUNITY_Community 50|Community 50]]
- [[_COMMUNITY_Community 51|Community 51]]
- [[_COMMUNITY_Community 52|Community 52]]
- [[_COMMUNITY_Community 53|Community 53]]
- [[_COMMUNITY_Community 54|Community 54]]
- [[_COMMUNITY_Community 55|Community 55]]
- [[_COMMUNITY_Community 56|Community 56]]
- [[_COMMUNITY_Community 57|Community 57]]
- [[_COMMUNITY_Community 58|Community 58]]
- [[_COMMUNITY_Community 59|Community 59]]
- [[_COMMUNITY_Community 60|Community 60]]
- [[_COMMUNITY_Community 61|Community 61]]
- [[_COMMUNITY_Community 62|Community 62]]
- [[_COMMUNITY_Community 63|Community 63]]
- [[_COMMUNITY_Community 64|Community 64]]
- [[_COMMUNITY_Community 65|Community 65]]
- [[_COMMUNITY_Community 66|Community 66]]
- [[_COMMUNITY_Community 67|Community 67]]
- [[_COMMUNITY_Community 68|Community 68]]
- [[_COMMUNITY_Community 69|Community 69]]
- [[_COMMUNITY_Community 70|Community 70]]
- [[_COMMUNITY_Community 71|Community 71]]
- [[_COMMUNITY_Community 72|Community 72]]
- [[_COMMUNITY_Community 73|Community 73]]
- [[_COMMUNITY_Community 74|Community 74]]
- [[_COMMUNITY_Community 75|Community 75]]
- [[_COMMUNITY_Community 76|Community 76]]
- [[_COMMUNITY_Community 77|Community 77]]
- [[_COMMUNITY_Community 78|Community 78]]
- [[_COMMUNITY_Community 79|Community 79]]
- [[_COMMUNITY_Community 80|Community 80]]
- [[_COMMUNITY_Community 81|Community 81]]
- [[_COMMUNITY_Community 82|Community 82]]

## God Nodes (most connected - your core abstractions)
1. `package:flutter/material.dart` - 65 edges
2. `../../core/theme/app_colors.dart` - 49 edges
3. `../../core/theme/app_typography.dart` - 45 edges
4. `package:flutter_riverpod/flutter_riverpod.dart` - 24 edges
5. `../../core/theme/app_dimensions.dart` - 23 edges
6. `../../../shared/widgets/modal_scaffold.dart` - 14 edges
7. `../../../data/mock/mock_vendors.dart` - 13 edges
8. `../../../data/mock/mock_bookings.dart` - 12 edges
9. `../../../data/mock/mock_generators.dart` - 12 edges
10. `package:go_router/go_router.dart` - 11 edges

## Surprising Connections (you probably didn't know these)
- `my_application_activate()` --calls--> `fl_register_plugins()`  [INFERRED]
  linux/runner/my_application.cc → linux/flutter/generated_plugin_registrant.cc
- `main()` --calls--> `my_application_new()`  [INFERRED]
  linux/runner/main.cc → linux/runner/my_application.cc
- `OnCreate()` --calls--> `RegisterPlugins()`  [INFERRED]
  windows/runner/flutter_window.cpp → windows/flutter/generated_plugin_registrant.cc
- `OnCreate()` --calls--> `GetClientArea()`  [INFERRED]
  windows/runner/flutter_window.cpp → windows/runner/win32_window.cpp
- `OnCreate()` --calls--> `SetChildContent()`  [INFERRED]
  windows/runner/flutter_window.cpp → windows/runner/win32_window.cpp

## Communities (111 total, 15 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.04
Nodes (42): ../../core/theme/app_colors.dart, metric_sparkline.dart, package:flutter_slidable/flutter_slidable.dart, build, DeleteUserDialog, Icon, ModalScaffold, SizedBox (+34 more)

### Community 1 - "Community 1"
Cohesion: 0.05
Nodes (38): app.dart, booking_provider.dart, ../../../core/providers/booking_provider.dart, ../../../core/providers/drawer_provider.dart, ../../../core/providers/generator_provider.dart, ../../../core/providers/vendor_provider.dart, package:flutter_riverpod/flutter_riverpod.dart, package:flutter/widgets.dart (+30 more)

### Community 2 - "Community 2"
Cohesion: 0.06
Nodes (33): dart:ui, ../../features/admin/screens/integrations_screen.dart, ../../features/admin/screens/system_health_screen.dart, ../../features/admin/screens/user_management_screen.dart, ../../features/auth/screens/login_screen.dart, ../../features/billing/screens/billing_preview_screen.dart, ../../features/bookings/screens/bookings_directory_screen.dart, ../../features/dashboard/screens/dashboard_screen.dart (+25 more)

### Community 3 - "Community 3"
Cohesion: 0.06
Nodes (28): dart:math, ../../data/mock/mock_system_health.dart, ../../data/mock/mock_users.dart, ../modals/add_user_modal.dart, ../providers/user_management_provider.dart, ../services/mock_data_service.dart, ../../shared/models/system_health.dart, ../../../shared/models/user.dart (+20 more)

### Community 4 - "Community 4"
Cohesion: 0.06
Nodes (31): 1. Color Palette (Strictly Enforced), 2. Typography, 3. Shapes & Radii, 4. Components & Elevation, 5. Layout, 6. Reference Material (stitch_generator_ledger_design), Authority Model, Behavioral Contract Rules (+23 more)

### Community 5 - "Community 5"
Cohesion: 0.07
Nodes (29): Executive Summary, Findings, Graphify Notes, P0: Create/Edit/Detail Modal Flows Are Missing, P0: Designed Screens Are Routed to Placeholders, P0: Some Visible Admin Actions Are UI-Only Placeholders, P1: Admin Shell Is Underimplemented, P1: Create/Add CTA Color Is Inconsistent (+21 more)

### Community 6 - "Community 6"
Cohesion: 0.11
Nodes (19): RegisterPlugins(), FlutterWindow(), OnCreate(), Create(), Destroy(), EnableFullDpiSupportIfAvailable(), GetClientArea(), GetThisFromHandle() (+11 more)

### Community 7 - "Community 7"
Cohesion: 0.08
Nodes (23): 1. Product Vision, 2. Screen Inventory (18 Screens), 3. Navigation Architecture, 4. Data Entities, 5. Milestones, 6. Shared Component Catalog, 7. Technology Decisions, 8. Quality Gates (+15 more)

### Community 8 - "Community 8"
Cohesion: 0.1
Nodes (19): 1. System Overview, 2. Project Structure, 3. Design System → Flutter Mapping, 4. Navigation Graph, 5. State Management, 6. Key Dependencies, 7. Constraints & Decisions, ARCHITECTURE.md — Genset Industrial Ledger (Mobile v2) (+11 more)

### Community 9 - "Community 9"
Cohesion: 0.11
Nodes (18): ../../bookings/providers/bookings_provider.dart, ../providers/billing_provider.dart, BillingPreviewScreen, _BillingPreviewScreenState, build, Column, Container, dispose (+10 more)

### Community 10 - "Community 10"
Cohesion: 0.11
Nodes (18): ../providers/generators_provider.dart, ../../../shared/widgets/expandable_fab_menu.dart, ../../../shared/widgets/floating_search_fab.dart, build, dispose, GeneratorsDirectoryScreen, _GeneratorsDirectoryScreenState, initState (+10 more)

### Community 11 - "Community 11"
Cohesion: 0.11
Nodes (18): ../providers/vendors_provider.dart, build, dispose, initState, _onSearchChanged, _openAddVendorModal, Scaffold, SectionHeader (+10 more)

### Community 12 - "Community 12"
Cohesion: 0.11
Nodes (18): ../providers/bookings_provider.dart, ../../shared/widgets/app_bottom_nav_bar.dart, ../../../shared/widgets/section_header.dart, ../../vendors/providers/vendors_provider.dart, BookingsDirectoryScreen, _BookingsDirectoryScreenState, build, dispose (+10 more)

### Community 13 - "Community 13"
Cohesion: 0.11
Nodes (16): ../../../core/routing/app_router.dart, core/theme/app_theme.dart, build, LedgerApp, build, Column, dispose, _handleSignIn (+8 more)

### Community 14 - "Community 14"
Cohesion: 0.12
Nodes (16): build, Card, Container, GeneratorDetailScreen, _GeneratorDetailScreenState, _handleCreateBooking, Icon, initState (+8 more)

### Community 15 - "Community 15"
Cohesion: 0.12
Nodes (15): Acceptance Checklist, Mobile Dashboard Screenshot Drift Report, P0: Drawer Menu Contents Do Not Match Screenshot Target, P0: Side Drawer Theme Is Inverted, P1: Calendar Header Layout Is Different, P1: Calendar View Density Does Not Match Stitch, P1: Drawer Width And Corner Treatment Are Different, P1: Overlay Blur/Dim Is Too Heavy In Flutter (+7 more)

### Community 16 - "Community 16"
Cohesion: 0.13
Nodes (14): build, _buildFieldLabel, dispose, EditBookingModal, _EditBookingModalState, Function, GestureDetector, Icon (+6 more)

### Community 17 - "Community 17"
Cohesion: 0.14
Nodes (13): package:table_calendar/table_calendar.dart, build, CalendarView, _CalendarViewState, Container, _daysInMonth, Divider, Expanded (+5 more)

### Community 18 - "Community 18"
Cohesion: 0.14
Nodes (13): AddBookingModal, _AddBookingModalState, build, _buildFieldLabel, dispose, Function, GestureDetector, Icon (+5 more)

### Community 19 - "Community 19"
Cohesion: 0.14
Nodes (4): fl_register_plugins(), main(), my_application_activate(), my_application_new()

### Community 20 - "Community 20"
Cohesion: 0.15
Nodes (11): package:ledger/features/bookings/screens/bookings_directory_screen.dart, package:ledger/features/bookings/widgets/vendor_booking_group.dart, package:ledger/features/generators/screens/generators_directory_screen.dart, package:ledger/features/generators/widgets/inventory_group_section.dart, package:ledger/features/vendors/screens/vendor_directory_screen.dart, package:ledger/features/vendors/widgets/vendor_card.dart, package:ledger/shared/widgets/expandable_fab_menu.dart, package:ledger/shared/widgets/floating_search_fab.dart (+3 more)

### Community 21 - "Community 21"
Cohesion: 0.15
Nodes (12): ../../../shared/widgets/directory_card.dart, build, _buildKeyValuePair, Column, Container, DailyBookingsList, DirectoryCard, Divider (+4 more)

### Community 22 - "Community 22"
Cohesion: 0.15
Nodes (12): build, _buildFieldLabel, dispose, EditGeneratorModal, _EditGeneratorModalState, Function, GestureDetector, initState (+4 more)

### Community 23 - "Community 23"
Cohesion: 0.15
Nodes (12): AddGeneratorModal, _AddGeneratorModalState, build, _buildFieldLabel, dispose, Function, GestureDetector, initState (+4 more)

### Community 24 - "Community 24"
Cohesion: 0.15
Nodes (12): package:ledger/shared/widgets/admin_bottom_nav_bar.dart, package:ledger/shared/widgets/app_bottom_nav_bar.dart, package:ledger/shared/widgets/backdrop_blur_overlay.dart, package:ledger/shared/widgets/dark_header_card.dart, package:ledger/shared/widgets/directory_card.dart, package:ledger/shared/widgets/modal_scaffold.dart, package:ledger/shared/widgets/section_header.dart, package:ledger/shared/widgets/side_navigation_drawer.dart (+4 more)

### Community 25 - "Community 25"
Cohesion: 0.15
Nodes (12): Alert Boxes, Brand & Style, Buttons, Colors, Components, Data Tables, Elevation & Depth, Inputs (+4 more)

### Community 26 - "Community 26"
Cohesion: 0.15
Nodes (12): Alert Boxes, Brand & Style, Buttons, Colors, Components, Data Tables, Elevation & Depth, Inputs (+4 more)

### Community 27 - "Community 27"
Cohesion: 0.15
Nodes (12): Alert Boxes, Brand & Style, Buttons, Colors, Components, Data Tables, Elevation & Depth, Inputs (+4 more)

### Community 28 - "Community 28"
Cohesion: 0.17
Nodes (11): AddVendorModal, _AddVendorModalState, build, _buildFieldLabel, dispose, Function, initState, _inputDecoration (+3 more)

### Community 29 - "Community 29"
Cohesion: 0.17
Nodes (11): build, _buildFieldLabel, dispose, EditVendorModal, _EditVendorModalState, Function, initState, _inputDecoration (+3 more)

### Community 30 - "Community 30"
Cohesion: 0.17
Nodes (11): build, _buildFieldLabel, dispose, EditUserModal, _EditUserModalState, Function, initState, _inputDecoration (+3 more)

### Community 31 - "Community 31"
Cohesion: 0.17
Nodes (11): build, _buildItem, dispose, ExpandableFABItem, ExpandableFABMenu, _ExpandableFABMenuState, initState, ScaleTransition (+3 more)

### Community 32 - "Community 32"
Cohesion: 0.18
Nodes (10): build, _buildFieldLabel, CreateUserModal, _CreateUserModalState, dispose, Function, _inputDecoration, ModalScaffold (+2 more)

### Community 33 - "Community 33"
Cohesion: 0.18
Nodes (10): build, Column, Container, didUpdateWidget, Function, _getPermissionDescription, initState, PermissionMatrix (+2 more)

### Community 34 - "Community 34"
Cohesion: 0.18
Nodes (10): AddUserModal, _AddUserModalState, build, _buildFieldLabel, dispose, Function, _inputDecoration, ModalScaffold (+2 more)

### Community 35 - "Community 35"
Cohesion: 0.18
Nodes (10): 1. Design Overview, 2. Screen Inventory & Component Mapping, 3. Frontend Architecture Recommendations, 4. Next Steps, A. Authentication, B. Core Management (Directories), C. Interaction Modals (Floating Forms), Core Visual Language: (+2 more)

### Community 36 - "Community 36"
Cohesion: 0.2
Nodes (9): BoxShadow, build, dispose, FloatingSearchFAB, _FloatingSearchFABState, initState, _onFocusChange, Padding (+1 more)

### Community 37 - "Community 37"
Cohesion: 0.2
Nodes (8): ../../core/theme/app_typography.dart, AdminBottomNavBar, BottomNavigationBar, build, build, Container, DirectoryCard, SizedBox

### Community 38 - "Community 38"
Cohesion: 0.22
Nodes (8): booking_list_item.dart, ../../../shared/widgets/dark_header_card.dart, build, Column, DarkHeaderCard, Divider, Function, VendorBookingGroup

### Community 39 - "Community 39"
Cohesion: 0.22
Nodes (8): package:intl/intl.dart, BookingListItem, build, GestureDetector, _getStatusBadgeType, Padding, SizedBox, TextSpan

### Community 40 - "Community 40"
Cohesion: 0.22
Nodes (8): 1. Global Navigation Components, 2. Shared UI Patterns, 3. High-Density Form Modals, Bottom Action Zone (Directories), Component Specification: Genset Industrial Ledger, Directory Cards (Vendors, Bookings, Gensets), Side Navigation Drawer (Global), Status Badges

### Community 41 - "Community 41"
Cohesion: 0.25
Nodes (7): build, _buildDetailRow, Column, Divider, GeneratorDetailModal, ModalScaffold, SizedBox

### Community 42 - "Community 42"
Cohesion: 0.25
Nodes (7): package:go_router/go_router.dart, ../../../shared/widgets/side_navigation_drawer.dart, build, Icon, IntegrationsScreen, Scaffold, SizedBox

### Community 43 - "Community 43"
Cohesion: 0.25
Nodes (7): generator_card.dart, build, Container, Function, GeneratorCard, InventoryGroupSection, SizedBox

### Community 44 - "Community 44"
Cohesion: 0.25
Nodes (6): package:flutter_test/flutter_test.dart, package:ledger/features/admin/screens/integrations_screen.dart, package:ledger/features/auth/screens/login_screen.dart, main, MaterialApp, main

### Community 46 - "Community 46"
Cohesion: 0.29
Nodes (6): ../../../shared/widgets/swipe_action_card.dart, build, GeneratorCard, SizedBox, StatusBadge, SwipeActionCard

### Community 47 - "Community 47"
Cohesion: 0.29
Nodes (6): build, _buildStatCard, Container, Row, SizedBox, StatsGrid

### Community 48 - "Community 48"
Cohesion: 0.33
Nodes (5): build, DeleteVendorDialog, Icon, ModalScaffold, SizedBox

### Community 49 - "Community 49"
Cohesion: 0.33
Nodes (5): build, Container, Icon, SizedBox, VendorCard

### Community 50 - "Community 50"
Cohesion: 0.33
Nodes (5): ../../../data/mock/mock_vendors.dart, addVendor, deleteVendor, updateVendor, VendorNotifier

### Community 51 - "Community 51"
Cohesion: 0.33
Nodes (5): ../../../data/mock/mock_bookings.dart, addBooking, BookingNotifier, deleteBooking, updateBooking

### Community 52 - "Community 52"
Cohesion: 0.33
Nodes (5): ../../../data/mock/mock_generators.dart, addGenerator, deleteGenerator, GeneratorNotifier, updateGenerator

### Community 53 - "Community 53"
Cohesion: 0.33
Nodes (5): ../../../shared/widgets/modal_scaffold.dart, build, Divider, GeneratorActionMenu, ModalScaffold

### Community 54 - "Community 54"
Cohesion: 0.33
Nodes (5): ../../../shared/widgets/status_badge.dart, build, Container, SizedBox, UserCard

### Community 55 - "Community 55"
Cohesion: 0.33
Nodes (5): ../../core/theme/app_dimensions.dart, build, Container, SizedBox, StatusBadge

### Community 56 - "Community 56"
Cohesion: 0.33
Nodes (5): backdrop_blur_overlay.dart, build, ModalScaffold, SizedBox, Stack

### Community 57 - "Community 57"
Cohesion: 0.33
Nodes (3): RegisterGeneratedPlugins(), NSWindow, MainFlutterWindow

### Community 58 - "Community 58"
Cohesion: 0.33
Nodes (5): app_colors.dart, app_dimensions.dart, app_typography.dart, lightTheme, ThemeData

### Community 59 - "Community 59"
Cohesion: 0.33
Nodes (5): package:ledger/features/dashboard/screens/dashboard_screen.dart, package:ledger/features/dashboard/widgets/calendar_view.dart, package:ledger/features/dashboard/widgets/daily_bookings_list.dart, package:ledger/features/dashboard/widgets/stats_grid.dart, main

### Community 60 - "Community 60"
Cohesion: 0.47
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 62 - "Community 62"
Cohesion: 0.4
Nodes (4): build, Divider, ModalScaffold, VendorActionMenu

### Community 63 - "Community 63"
Cohesion: 0.4
Nodes (4): copyWith, _date, fromMap, User

### Community 64 - "Community 64"
Cohesion: 0.4
Nodes (4): package:ledger/features/admin/modals/add_user_modal.dart, package:ledger/features/admin/screens/user_management_screen.dart, main, ProviderScope

### Community 66 - "Community 66"
Cohesion: 0.4
Nodes (4): build, Column, SectionHeader, SizedBox

### Community 67 - "Community 67"
Cohesion: 0.4
Nodes (4): package:ledger/features/admin/screens/system_health_screen.dart, package:ledger/features/admin/widgets/health_metric_card.dart, main, ProviderScope

### Community 68 - "Community 68"
Cohesion: 0.4
Nodes (4): directory_card.dart, build, DarkHeaderCard, DirectoryCard

### Community 69 - "Community 69"
Cohesion: 0.4
Nodes (4): generator-ledger-mobile-v2, Getting Started, Project Structure, Runtime Notes

### Community 71 - "Community 71"
Cohesion: 0.5
Nodes (3): booking.dart, BillingLine, BillingSummary

## Knowledge Gaps
- **701 isolated node(s):** `MainActivity`, `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `-registerWithRegistry`, `LedgerApp`, `build` (+696 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **15 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Community 65` to `Community 0`, `Community 1`, `Community 2`, `Community 3`, `Community 9`, `Community 10`, `Community 11`, `Community 12`, `Community 13`, `Community 14`, `Community 16`, `Community 17`, `Community 18`, `Community 20`, `Community 21`, `Community 22`, `Community 23`, `Community 24`, `Community 28`, `Community 29`, `Community 30`, `Community 31`, `Community 32`, `Community 33`, `Community 34`, `Community 36`, `Community 37`, `Community 38`, `Community 39`, `Community 41`, `Community 42`, `Community 43`, `Community 44`, `Community 46`, `Community 47`, `Community 48`, `Community 49`, `Community 53`, `Community 54`, `Community 55`, `Community 56`, `Community 58`, `Community 59`, `Community 62`, `Community 64`, `Community 66`, `Community 67`, `Community 68`?**
  _High betweenness centrality (0.188) - this node is a cross-community bridge._
- **Why does `../../core/theme/app_colors.dart` connect `Community 0` to `Community 1`, `Community 2`, `Community 3`, `Community 9`, `Community 10`, `Community 11`, `Community 12`, `Community 13`, `Community 14`, `Community 16`, `Community 17`, `Community 18`, `Community 21`, `Community 22`, `Community 23`, `Community 28`, `Community 29`, `Community 30`, `Community 31`, `Community 32`, `Community 33`, `Community 34`, `Community 36`, `Community 37`, `Community 38`, `Community 39`, `Community 41`, `Community 42`, `Community 43`, `Community 46`, `Community 47`, `Community 48`, `Community 49`, `Community 53`, `Community 54`, `Community 55`, `Community 56`, `Community 62`, `Community 66`?**
  _High betweenness centrality (0.081) - this node is a cross-community bridge._
- **Why does `../../core/theme/app_typography.dart` connect `Community 37` to `Community 0`, `Community 1`, `Community 2`, `Community 3`, `Community 9`, `Community 10`, `Community 11`, `Community 12`, `Community 13`, `Community 14`, `Community 16`, `Community 17`, `Community 18`, `Community 21`, `Community 22`, `Community 23`, `Community 28`, `Community 29`, `Community 30`, `Community 31`, `Community 32`, `Community 33`, `Community 34`, `Community 36`, `Community 38`, `Community 39`, `Community 41`, `Community 42`, `Community 43`, `Community 46`, `Community 47`, `Community 48`, `Community 49`, `Community 53`, `Community 54`, `Community 55`, `Community 56`, `Community 62`, `Community 66`?**
  _High betweenness centrality (0.068) - this node is a cross-community bridge._
- **What connects `MainActivity`, `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `-registerWithRegistry` to the rest of the system?**
  _701 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.06 - nodes in this community are weakly interconnected._