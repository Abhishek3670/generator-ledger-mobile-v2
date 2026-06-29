# Graph Report - generator-ledger-mobile-v2  (2026-06-29)

## Corpus Check
- 132 files · ~115,330 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 833 nodes · 987 edges · 103 communities (92 shown, 11 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 8 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `713a2c98`
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

## God Nodes (most connected - your core abstractions)
1. `package:flutter/material.dart` - 59 edges
2. `../../core/theme/app_colors.dart` - 46 edges
3. `../../core/theme/app_typography.dart` - 43 edges
4. `../../core/theme/app_dimensions.dart` - 21 edges
5. `../../../shared/widgets/modal_scaffold.dart` - 13 edges
6. `package:go_router/go_router.dart` - 11 edges
7. `../../../data/mock/mock_vendors.dart` - 11 edges
8. `Findings` - 11 edges
9. `../../../data/mock/mock_bookings.dart` - 10 edges
10. `../../../data/mock/mock_generators.dart` - 10 edges

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

## Communities (103 total, 11 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.04
Nodes (42): ../../../data/mock/mock_generators.dart, generator_card.dart, ../../../shared/widgets/status_badge.dart, ../../../shared/widgets/swipe_action_card.dart, build, Container, SizedBox, UserCard (+34 more)

### Community 1 - "Community 1"
Cohesion: 0.05
Nodes (38): ../../../data/mock/mock_vendors.dart, ../../../shared/widgets/modal_scaffold.dart, AddVendorModal, _AddVendorModalState, build, _buildFieldLabel, dispose, Function (+30 more)

### Community 2 - "Community 2"
Cohesion: 0.06
Nodes (33): package:flutter_test/flutter_test.dart, package:ledger/app.dart, package:ledger/features/auth/screens/login_screen.dart, package:ledger/features/bookings/screens/bookings_directory_screen.dart, package:ledger/features/bookings/widgets/vendor_booking_group.dart, package:ledger/features/dashboard/screens/dashboard_screen.dart, package:ledger/features/dashboard/widgets/calendar_view.dart, package:ledger/features/dashboard/widgets/daily_bookings_list.dart (+25 more)

### Community 3 - "Community 3"
Cohesion: 0.06
Nodes (31): 1. Color Palette (Strictly Enforced), 2. Typography, 3. Shapes & Radii, 4. Components & Elevation, 5. Layout, 6. Reference Material (stitch_generator_ledger_design), Authority Model, Behavioral Contract Rules (+23 more)

### Community 4 - "Community 4"
Cohesion: 0.07
Nodes (29): Executive Summary, Findings, Graphify Notes, P0: Create/Edit/Detail Modal Flows Are Missing, P0: Designed Screens Are Routed to Placeholders, P0: Some Visible Admin Actions Are UI-Only Placeholders, P1: Admin Shell Is Underimplemented, P1: Create/Add CTA Color Is Inconsistent (+21 more)

### Community 5 - "Community 5"
Cohesion: 0.11
Nodes (19): RegisterPlugins(), FlutterWindow(), OnCreate(), Create(), Destroy(), EnableFullDpiSupportIfAvailable(), GetClientArea(), GetThisFromHandle() (+11 more)

### Community 6 - "Community 6"
Cohesion: 0.08
Nodes (23): 1. Product Vision, 2. Screen Inventory (18 Screens), 3. Navigation Architecture, 4. Data Entities, 5. Milestones, 6. Shared Component Catalog, 7. Technology Decisions, 8. Quality Gates (+15 more)

### Community 7 - "Community 7"
Cohesion: 0.09
Nodes (21): ../../features/admin/screens/integrations_screen.dart, ../../features/admin/screens/system_health_screen.dart, ../../features/admin/screens/user_management_screen.dart, ../../features/auth/screens/login_screen.dart, ../../features/billing/screens/billing_preview_screen.dart, ../../features/bookings/screens/bookings_directory_screen.dart, ../../features/dashboard/screens/dashboard_screen.dart, ../../features/generators/screens/generator_detail_screen.dart (+13 more)

### Community 8 - "Community 8"
Cohesion: 0.1
Nodes (19): 1. System Overview, 2. Project Structure, 3. Design System → Flutter Mapping, 4. Navigation Graph, 5. State Management, 6. Key Dependencies, 7. Constraints & Decisions, ARCHITECTURE.md — Genset Industrial Ledger (Mobile v2) (+11 more)

### Community 9 - "Community 9"
Cohesion: 0.11
Nodes (16): ../../../core/routing/app_router.dart, core/theme/app_theme.dart, build, LedgerApp, build, Column, dispose, _handleSignIn (+8 more)

### Community 10 - "Community 10"
Cohesion: 0.11
Nodes (17): build, dispose, initState, _onSearchChanged, _openAddVendorModal, Scaffold, SectionHeader, SizedBox (+9 more)

### Community 11 - "Community 11"
Cohesion: 0.11
Nodes (17): ../../../shared/widgets/expandable_fab_menu.dart, ../../../shared/widgets/floating_search_fab.dart, build, dispose, GeneratorsDirectoryScreen, _GeneratorsDirectoryScreenState, initState, _onDateFocusChange (+9 more)

### Community 12 - "Community 12"
Cohesion: 0.12
Nodes (16): BillingPreviewScreen, _BillingPreviewScreenState, build, Column, Container, dispose, Divider, _getRateForCapacity (+8 more)

### Community 13 - "Community 13"
Cohesion: 0.12
Nodes (16): build, Card, Container, GeneratorDetailScreen, _GeneratorDetailScreenState, _handleCreateBooking, Icon, initState (+8 more)

### Community 14 - "Community 14"
Cohesion: 0.12
Nodes (16): ../../shared/widgets/app_bottom_nav_bar.dart, ../../../shared/widgets/section_header.dart, BookingsDirectoryScreen, _BookingsDirectoryScreenState, build, dispose, initState, _onSearchChanged (+8 more)

### Community 15 - "Community 15"
Cohesion: 0.13
Nodes (14): build, _buildFieldLabel, dispose, EditBookingModal, _EditBookingModalState, Function, GestureDetector, Icon (+6 more)

### Community 16 - "Community 16"
Cohesion: 0.14
Nodes (13): AddBookingModal, _AddBookingModalState, build, _buildFieldLabel, dispose, Function, GestureDetector, Icon (+5 more)

### Community 17 - "Community 17"
Cohesion: 0.14
Nodes (4): fl_register_plugins(), main(), my_application_activate(), my_application_new()

### Community 18 - "Community 18"
Cohesion: 0.15
Nodes (12): build, _buildMetricCard, Container, Icon, Padding, paint, Scaffold, shouldRepaint (+4 more)

### Community 19 - "Community 19"
Cohesion: 0.15
Nodes (12): build, Container, Divider, Icon, Scaffold, SizedBox, SnackBar, UserManagementScreen (+4 more)

### Community 20 - "Community 20"
Cohesion: 0.15
Nodes (12): AddGeneratorModal, _AddGeneratorModalState, build, _buildFieldLabel, dispose, Function, GestureDetector, initState (+4 more)

### Community 21 - "Community 21"
Cohesion: 0.15
Nodes (12): Alert Boxes, Brand & Style, Buttons, Colors, Components, Data Tables, Elevation & Depth, Inputs (+4 more)

### Community 22 - "Community 22"
Cohesion: 0.15
Nodes (12): Alert Boxes, Brand & Style, Buttons, Colors, Components, Data Tables, Elevation & Depth, Inputs (+4 more)

### Community 23 - "Community 23"
Cohesion: 0.15
Nodes (12): Alert Boxes, Brand & Style, Buttons, Colors, Components, Data Tables, Elevation & Depth, Inputs (+4 more)

### Community 24 - "Community 24"
Cohesion: 0.17
Nodes (11): build, _buildFieldLabel, dispose, EditUserModal, _EditUserModalState, Function, initState, _inputDecoration (+3 more)

### Community 25 - "Community 25"
Cohesion: 0.17
Nodes (11): build, _buildItem, dispose, ExpandableFABItem, ExpandableFABMenu, _ExpandableFABMenuState, initState, ScaleTransition (+3 more)

### Community 26 - "Community 26"
Cohesion: 0.2
Nodes (9): ../../core/theme/app_colors.dart, dart:ui, AppBottomNavBar, build, ClipRRect, GestureDetector, SizedBox, BackdropBlurOverlay (+1 more)

### Community 27 - "Community 27"
Cohesion: 0.18
Nodes (10): build, Column, Container, didUpdateWidget, Function, _getPermissionDescription, initState, PermissionMatrix (+2 more)

### Community 28 - "Community 28"
Cohesion: 0.18
Nodes (10): ../../../shared/widgets/directory_card.dart, build, _buildKeyValuePair, Column, DailyBookingsList, DirectoryCard, _getStatusBadgeType, Icon (+2 more)

### Community 29 - "Community 29"
Cohesion: 0.18
Nodes (10): build, _buildFieldLabel, CreateUserModal, _CreateUserModalState, dispose, Function, _inputDecoration, ModalScaffold (+2 more)

### Community 30 - "Community 30"
Cohesion: 0.18
Nodes (10): 1. Design Overview, 2. Screen Inventory & Component Mapping, 3. Frontend Architecture Recommendations, 4. Next Steps, A. Authentication, B. Core Management (Directories), C. Interaction Modals (Floating Forms), Core Visual Language: (+2 more)

### Community 31 - "Community 31"
Cohesion: 0.2
Nodes (9): booking_list_item.dart, ../../../data/mock/mock_bookings.dart, ../../../shared/widgets/dark_header_card.dart, build, Column, DarkHeaderCard, Divider, Function (+1 more)

### Community 32 - "Community 32"
Cohesion: 0.2
Nodes (9): build, DashboardScreen, _DashboardScreenState, Scaffold, SizedBox, StatsGrid, ../widgets/calendar_view.dart, ../widgets/daily_bookings_list.dart (+1 more)

### Community 33 - "Community 33"
Cohesion: 0.2
Nodes (9): BoxShadow, build, dispose, FloatingSearchFAB, _FloatingSearchFABState, initState, _onFocusChange, Padding (+1 more)

### Community 34 - "Community 34"
Cohesion: 0.22
Nodes (8): build, _buildNavLink, Divider, Drawer, Function, Padding, SideNavigationDrawer, SizedBox

### Community 35 - "Community 35"
Cohesion: 0.22
Nodes (8): package:intl/intl.dart, BookingListItem, build, GestureDetector, _getStatusBadgeType, Padding, SizedBox, TextSpan

### Community 36 - "Community 36"
Cohesion: 0.22
Nodes (8): package:table_calendar/table_calendar.dart, build, CalendarView, _CalendarViewState, Container, initState, Positioned, SizedBox

### Community 37 - "Community 37"
Cohesion: 0.22
Nodes (8): 1. Global Navigation Components, 2. Shared UI Patterns, 3. High-Density Form Modals, Bottom Action Zone (Directories), Component Specification: Genset Industrial Ledger, Directory Cards (Vendors, Bookings, Gensets), Side Navigation Drawer (Global), Status Badges

### Community 38 - "Community 38"
Cohesion: 0.25
Nodes (7): package:go_router/go_router.dart, ../../../shared/widgets/side_navigation_drawer.dart, build, Icon, IntegrationsScreen, Scaffold, SizedBox

### Community 40 - "Community 40"
Cohesion: 0.29
Nodes (6): build, paint, shouldRepaint, SizedBox, SparklineChart, _SparklinePainter

### Community 41 - "Community 41"
Cohesion: 0.29
Nodes (6): build, _buildStatCard, Container, Row, SizedBox, StatsGrid

### Community 42 - "Community 42"
Cohesion: 0.33
Nodes (5): app_colors.dart, app_dimensions.dart, app_typography.dart, lightTheme, ThemeData

### Community 43 - "Community 43"
Cohesion: 0.33
Nodes (5): build, DeleteUserDialog, Icon, ModalScaffold, SizedBox

### Community 44 - "Community 44"
Cohesion: 0.33
Nodes (5): ../../core/theme/app_dimensions.dart, build, Container, DirectoryCard, SizedBox

### Community 45 - "Community 45"
Cohesion: 0.33
Nodes (5): backdrop_blur_overlay.dart, build, ModalScaffold, SizedBox, Stack

### Community 46 - "Community 46"
Cohesion: 0.33
Nodes (3): RegisterGeneratedPlugins(), NSWindow, MainFlutterWindow

### Community 47 - "Community 47"
Cohesion: 0.47
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 49 - "Community 49"
Cohesion: 0.4
Nodes (4): app.dart, package:flutter_riverpod/flutter_riverpod.dart, package:flutter/widgets.dart, main

### Community 51 - "Community 51"
Cohesion: 0.4
Nodes (4): build, Container, MetricCard, SizedBox

### Community 52 - "Community 52"
Cohesion: 0.4
Nodes (4): directory_card.dart, build, DarkHeaderCard, DirectoryCard

### Community 53 - "Community 53"
Cohesion: 0.4
Nodes (4): build, Column, SectionHeader, SizedBox

### Community 54 - "Community 54"
Cohesion: 0.4
Nodes (4): package:flutter_slidable/flutter_slidable.dart, build, Slidable, SwipeActionCard

### Community 55 - "Community 55"
Cohesion: 0.4
Nodes (4): ../../core/theme/app_typography.dart, AdminBottomNavBar, BottomNavigationBar, build

### Community 56 - "Community 56"
Cohesion: 0.4
Nodes (4): build, Container, SizedBox, StatusBadge

### Community 57 - "Community 57"
Cohesion: 0.4
Nodes (4): generator-ledger-mobile-v2, Getting Started, Project Structure, Runtime Notes

## Knowledge Gaps
- **584 isolated node(s):** `MainActivity`, `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `-registerWithRegistry`, `LedgerApp`, `build` (+579 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **11 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Community 50` to `Community 0`, `Community 1`, `Community 2`, `Community 7`, `Community 9`, `Community 10`, `Community 11`, `Community 12`, `Community 13`, `Community 14`, `Community 15`, `Community 16`, `Community 18`, `Community 19`, `Community 20`, `Community 24`, `Community 25`, `Community 26`, `Community 27`, `Community 28`, `Community 29`, `Community 31`, `Community 32`, `Community 33`, `Community 34`, `Community 35`, `Community 36`, `Community 38`, `Community 40`, `Community 41`, `Community 42`, `Community 43`, `Community 44`, `Community 45`, `Community 51`, `Community 52`, `Community 53`, `Community 54`, `Community 55`, `Community 56`?**
  _High betweenness centrality (0.187) - this node is a cross-community bridge._
- **Why does `../../core/theme/app_colors.dart` connect `Community 26` to `Community 0`, `Community 1`, `Community 9`, `Community 10`, `Community 11`, `Community 12`, `Community 13`, `Community 14`, `Community 15`, `Community 16`, `Community 18`, `Community 19`, `Community 20`, `Community 24`, `Community 25`, `Community 27`, `Community 28`, `Community 29`, `Community 31`, `Community 32`, `Community 33`, `Community 34`, `Community 35`, `Community 36`, `Community 38`, `Community 40`, `Community 41`, `Community 43`, `Community 44`, `Community 45`, `Community 51`, `Community 53`, `Community 54`, `Community 55`, `Community 56`?**
  _High betweenness centrality (0.081) - this node is a cross-community bridge._
- **Why does `../../core/theme/app_typography.dart` connect `Community 55` to `Community 0`, `Community 1`, `Community 9`, `Community 10`, `Community 11`, `Community 12`, `Community 13`, `Community 14`, `Community 15`, `Community 16`, `Community 18`, `Community 19`, `Community 20`, `Community 24`, `Community 25`, `Community 26`, `Community 27`, `Community 28`, `Community 29`, `Community 31`, `Community 32`, `Community 33`, `Community 34`, `Community 35`, `Community 36`, `Community 38`, `Community 41`, `Community 43`, `Community 44`, `Community 45`, `Community 51`, `Community 53`, `Community 56`?**
  _High betweenness centrality (0.071) - this node is a cross-community bridge._
- **What connects `MainActivity`, `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `-registerWithRegistry` to the rest of the system?**
  _584 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.06 - nodes in this community are weakly interconnected._