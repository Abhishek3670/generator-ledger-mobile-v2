# Mobile Dashboard Screenshot Drift Report

Generated: 2026-06-30  
Compared image: `docs/mobile_dashboard_with_side_navigation_comparison.png`  
Design source: `stitch_generator_ledger_design/screens/mobile_dashboard_with_side_navigation/code.html`  
Implementation sources: dashboard screen/widgets, `SideNavigationDrawer`, `AppBottomNavBar`, router shell.

## Read Of The Comparison

The comparison screenshot shows two materially different dashboard compositions.

Assumption from the visible UI and Stitch HTML: the **left side is the Stitch target** and the **right side is the current Flutter implementation**. The target has a light drawer, blurred dashboard background, compact dashboard header, dense calendar grid, compact booking cards, and a dark bottom nav. The current Flutter implementation has a dark drawer, a darker/heavier overlay, larger drawer width/visual weight, different calendar structure, and booking cards that occupy much more vertical height.

Overall dashboard drift: **high for side navigation and calendar/list density, moderate for bottom nav, low for stats tokens**.

## Priority Fixes

### P0: Side Drawer Theme Is Inverted

Observed drift:

- Stitch target drawer is light: white/surface background, dark text, black avatar circle, subtle border.
- Current Flutter drawer is dark slate: navy background, amber avatar, white text, amber selected pill.
- Screenshot impact is severe because the drawer is the dominant opened state.

Design evidence:

- Stitch drawer: `bg-surface-container-lowest`, `bg-surface-light`, `text-primary`, `text-text-secondary`.
- Current implementation: `lib/shared/widgets/side_navigation_drawer.dart` uses `Drawer(backgroundColor: AppColors.primary)` and white text throughout.

Agent task:

- Convert `SideNavigationDrawer` to the light Stitch variant for this dashboard drawer state.
- Use white/surface drawer background, dark primary text, muted secondary text, and black/primary avatar circle.
- Active/hover state should be subtle surface fill unless the Stitch selected state explicitly requires amber.
- Keep `Billing Preview`, `Settings`, and `Logout` visible as in the target.

Files:

- `lib/shared/widgets/side_navigation_drawer.dart`

### P0: Drawer Menu Contents Do Not Match Screenshot Target

Observed drift:

- Stitch screenshot drawer only exposes `Billing Preview` in the main navigation area, with Settings/Logout pinned at the bottom.
- Current Flutter drawer exposes Dashboard, Bookings, Gensets, Vendors, and Billing Preview.

UI impact:

The opened drawer reads like a full navigation menu in Flutter, but the Stitch dashboard target reads like a contextual side sheet focused on secondary actions.

Agent task:

- Decide whether `SideNavigationDrawer` should support variants.
- Recommended implementation: add a `variant` or `items` parameter so dashboard can render the Stitch target without breaking other screens.
- Dashboard variant should show profile, title `Genset Ledger`, `Billing Preview`, bottom Settings/Logout.

Files:

- `lib/shared/widgets/side_navigation_drawer.dart`
- `lib/features/dashboard/screens/dashboard_screen.dart`

### P1: Drawer Width And Corner Treatment Are Different

Observed drift:

- Target drawer is about 280px wide, square-edged, and flush with the left side.
- Flutter drawer in the screenshot is visually wider/heavier and has a large rounded top-right corner.

UI impact:

The current drawer looks like a full dark app rail/panel rather than the Stitch side drawer.

Agent task:

- Set drawer width to about `280`.
- Remove large rounded outer corner for the Stitch dashboard drawer.
- Use flat surface + border/shadow only as in the HTML target.

Files:

- `lib/shared/widgets/side_navigation_drawer.dart`

### P1: Overlay Blur/Dim Is Too Heavy In Flutter

Observed drift:

- Stitch target uses a blurred/dimmed dashboard backdrop, but the underlying page remains visually readable.
- Current screenshot makes the dashboard very dark and low-contrast behind the drawer.

Design evidence:

- Stitch overlay: `bg-black/50 backdrop-blur-sm`.
- Current Flutter drawer is rendered by the native `Drawer`/`Scaffold` scrim, likely without matching blur behavior and with heavy dimming.

Agent task:

- Replace or supplement native drawer behavior with a custom drawer overlay if exact Stitch parity is required.
- Target: black scrim around 50% with blur around `sigma 4`, not a near-opaque gray/dark wash.
- Ensure bottom nav is also blurred/dimmed behind the overlay.

Files:

- `lib/features/dashboard/screens/dashboard_screen.dart`
- Optional shared component: `lib/shared/widgets/side_navigation_drawer.dart`

### P1: Top App Bar Is Wrong For Dashboard Target

Observed drift:

- Stitch target top bar is light: white/surface, menu icon, title `Genset Industrial Ledger`, border bottom.
- Flutter dashboard top app bar is dark navy with title `DASHBOARD`.

Design evidence:

- Stitch header: `bg-surface-container-lowest border-b border-border-slate`, title `Genset Industrial Ledger`.
- Current Flutter: `DashboardScreen` uses `AppBar(backgroundColor: AppColors.primary)` and title `DASHBOARD`.

Agent task:

- For dashboard only, change the `AppBar` to light mode.
- Title should be `Genset Industrial Ledger`.
- Menu icon should be dark primary, not white.
- Keep border bottom/elevation flat.

Files:

- `lib/features/dashboard/screens/dashboard_screen.dart`

### P1: Calendar View Density Does Not Match Stitch

Observed drift:

- Stitch target calendar is a dense bordered 7-column grid with visible cell borders and booking-count bars inside day cells.
- Flutter current view uses `TableCalendar` with a cleaner month layout, circular selected day, and small count marker dots/pills.
- In the screenshot, actual day cells are much airier and booking counts are reduced to tiny badges.

Design evidence:

- Stitch cells use `grid grid-cols-7 gap-px`, `min-h-[80px]`, bordered cells, and dark booking-count bars such as `10 bk`.
- Flutter `CalendarView` uses `TableCalendar` with default calendar layout and `markerBuilder` for small count pills.

Agent task:

- Replace `TableCalendar` rendering for this dashboard with a custom dense grid, or heavily customize `CalendarBuilders`.
- Show booking count as dark horizontal bar text (`1 bk`, `10 bk`) inside each day cell.
- Preserve cell borders and alternating surface fills.
- Match the Stitch order/header style: S M T W T F S.

Files:

- `lib/features/dashboard/widgets/calendar_view.dart`

### P1: Calendar Header Layout Is Different

Observed drift:

- Stitch calendar card has a top section: `CALENDAR`, `Vendor Bookings`, `Confirmed bookings by date`, and right-side helper copy.
- Controls sit below: left/right/today on the left, month label centered, month/list segmented control on wider screens.
- Flutter puts the navigation controls in the same row as the title and omits the helper copy and month/list control.

Agent task:

- Split `CalendarView` into:
  1. card title/header row,
  2. controls row,
  3. bordered grid.
- Add helper copy `Click a date to view details.` on larger widths.
- Add month/list segmented control if desktop/tablet parity is required.

Files:

- `lib/features/dashboard/widgets/calendar_view.dart`

### P2: Daily Booking List Card Layout Is Too Heavy

Observed drift:

- Stitch target daily list is one white bordered section with a header row: `Bookings: 2026-04-20` and `10 Total`.
- Booking rows are compact cards inside the section with vendor/status on one row, booking ID, generator ID, and chevron.
- Flutter uses a separate section title `BOOKINGS / Daily Schedule`, then dark-header `DirectoryCard` cards. This creates larger vertical chunks and a different hierarchy.

Agent task:

- Rebuild `DailyBookingsList` to match the Stitch section container.
- Header should be inside the bordered container.
- Use compact booking rows, not dark-header directory cards.
- Use date format like `Bookings: yyyy-MM-dd`.
- Show total count on the right.

Files:

- `lib/features/dashboard/widgets/daily_bookings_list.dart`

### P2: Bottom Navigation Is Close But Active Styling Needs Tuning

Observed drift:

- Both target and Flutter use a dark bottom nav with rounded top corners and amber active tab.
- Flutter active pill appears taller/larger and the nav is visually very dark/heavy in the screenshot.
- Stitch target inactive labels/icons are smaller and lower contrast; active tab has compact amber rounded rectangle.

Agent task:

- Keep the same component, but tune dimensions:
  - active tab padding closer to `px-3 py-1`,
  - icon size and label size slightly smaller,
  - nav height `80` is acceptable,
  - maintain top radius `12`.

Files:

- `lib/shared/widgets/app_bottom_nav_bar.dart`

### P2: Stats Cards Are Mostly Correct But Need Header Context

Observed drift:

- Stats values and card style are close.
- Target stats sit below the light top app bar and within the main content canvas.
- Flutter screenshot positions stats behind the open dark drawer and dark app chrome, changing visual hierarchy.

Agent task:

- Leave `StatsGrid` mostly intact.
- Re-evaluate only after top app bar and drawer are corrected.

Files:

- `lib/features/dashboard/widgets/stats_grid.dart`

## Suggested Implementation Plan For Agent

1. Add a dashboard-specific light drawer variant to `SideNavigationDrawer`.
2. Update `DashboardScreen` to use the Stitch light top app bar and pass the drawer variant/items.
3. If Flutter native drawer cannot match blur/dim behavior, replace dashboard drawer with a custom `Stack` overlay.
4. Rework `CalendarView` into a custom dense grid matching the Stitch HTML.
5. Rework `DailyBookingsList` into the compact bordered section.
6. Tune `AppBottomNavBar` active tab padding/scale after screenshot review.
7. Capture a new comparison screenshot and verify the drawer-open state first, then closed dashboard state.

## Acceptance Checklist

- Drawer background is light, not navy.
- Drawer width is approximately 280px.
- Drawer title reads `Genset Ledger`.
- Drawer shows `Billing Preview` plus bottom Settings/Logout in the dashboard-open state.
- Dashboard app bar is light and titled `Genset Industrial Ledger`.
- Overlay blur/dim leaves the underlying dashboard recognizable.
- Calendar uses bordered day cells and dark booking-count bars.
- Daily booking list uses compact rows inside one bordered section.
- Bottom nav active tab is amber but compact.
- New screenshot visually matches `docs/mobile_dashboard_with_side_navigation_comparison.png` target side within small spacing differences.

