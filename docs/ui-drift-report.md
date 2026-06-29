# UI Drift Report: Flutter UI vs Stitch Design Exports

Generated: 2026-06-29  
Scope: UI only: `lib/features/**/screens`, `lib/features/**/widgets`, `lib/shared/widgets`, `lib/core/theme`, and `stitch_generator_ledger_design/`  
Method: static UI source comparison against Stitch `code.html` exports and design tokens. No screenshot/golden comparison was run.

## Executive Summary

The Flutter UI is broadly aligned with the Stitch visual system. The main palette, typography families, mobile gutters, pill buttons, bordered cards, bottom navigation, side drawer, floating search/action zones, blur overlays, and modal scaffold are all represented in the implementation.

The remaining drift is UI-specific and concentrated in visible behavior and fidelity: some designed edit/create affordances still look clickable but do not open matching UI, several modals are simpler than the Stitch exports, create/add CTA colors are inconsistent, and a few local colors/radii/shadows bypass the strict token set.

Overall UI assessment: **good screen coverage, moderate component fidelity drift, moderate visible interaction drift**.

## UI Coverage Matrix

| UI surface | Stitch source | Flutter UI | UI drift |
|---|---|---|---|
| Login | `screens/login/code.html` | `lib/features/auth/screens/login_screen.dart` | Low |
| Dashboard | `screens/mobile_dashboard_with_side_navigation/code.html`, `screens/refined_mobile_dashboard_v2/code.html` | `lib/features/dashboard/screens/dashboard_screen.dart` | Low to moderate |
| Bookings directory | `screens/aligned_mobile_bookings_directory/code.html` | `lib/features/bookings/screens/bookings_directory_screen.dart` | Low to moderate |
| Add booking modal | `screens/floating_add_booking_modal_updated/code.html` | `lib/features/bookings/widgets/add_booking_modal.dart` | Moderate |
| Edit booking modal | `screens/floating_edit_booking_modal/code.html` | `lib/features/bookings/widgets/edit_booking_modal.dart` | Moderate |
| Vendor directory | `screens/mobile_vendor_directory_with_backdrop_blur/code.html` | `lib/features/vendors/screens/vendor_directory_screen.dart` | Moderate |
| Add vendor modal | `screens/floating_add_vendor_modal/code.html` | `lib/features/vendors/widgets/add_vendor_modal.dart` | Moderate |
| Generators directory | `screens/updated_generators_directory_with_vertical_action_menu/code.html` | `lib/features/generators/screens/generators_directory_screen.dart` | Moderate |
| Add generator modal | `screens/floating_add_generator_modal/code.html` | `lib/features/generators/widgets/add_generator_modal.dart` | Moderate |
| Generator detail | `screens/generator_detail_view/code.html`, `screens/floating_generator_detail_modal/code.html` | `lib/features/generators/screens/generator_detail_screen.dart`, `lib/features/generators/widgets/generator_detail_modal.dart` | Moderate |
| Billing preview | `screens/mobile_billing_preview/code.html` | `lib/features/billing/screens/billing_preview_screen.dart` | Low to moderate |
| System monitor | `screens/updated_system_monitor/code.html` | `lib/features/admin/screens/system_health_screen.dart` | Low to moderate |
| User management | `screens/user_management_with_permission_matrix/code.html` | `lib/features/admin/screens/user_management_screen.dart` | Moderate to high |
| Integrations coming soon | `screens/integrations_coming_soon/code.html` | `lib/features/admin/screens/integrations_screen.dart` | Low |

## UI Drift Findings

### P0: Some Visible Admin Actions Are UI-Only Placeholders

Evidence:

- `lib/features/admin/screens/user_management_screen.dart:108` shows a snackbar from the create-user button instead of opening a visible create-user modal.
- `lib/features/admin/screens/user_management_screen.dart:247` and `:262` render edit/delete buttons with empty callbacks.
- `lib/features/admin/screens/user_management_screen.dart:367` renders a floating add button with an empty callback.

UI impact:

The user-management screen visually promises create, edit, delete, and add interactions, but those controls do not reveal the modal or confirmation UI implied by the Stitch design.

UI recommendation:

Add visible create/edit user modals and a delete confirmation surface, or remove/disable the controls until their UI exists.

### P1: Directory Edit/Detail Affordances Do Not Always Open Matching UI

Evidence:

- Vendor more buttons show snackbars in `lib/features/vendors/screens/vendor_directory_screen.dart:171` and `:230`.
- Generator modify shows a snackbar in `lib/features/generators/screens/generators_directory_screen.dart:260`.
- Generator detail modal edit shows a snackbar in `lib/features/generators/screens/generators_directory_screen.dart:337`.
- The generator detail page overflow button is visually present but empty at `lib/features/generators/screens/generator_detail_screen.dart:153`.

UI impact:

The visual language suggests menus, modify sheets, or edit modals. Snackbars and empty callbacks create visible interaction drift from the Stitch exports.

UI recommendation:

Route these affordances to visible menus/modals using the existing `ModalScaffold` and blur overlay.

### P1: Modals Match the Shell Pattern but Not Full Stitch Form Density

Evidence:

- Stitch booking modal includes vendor search, assignment mode buttons, capacity chips, booking date controls, notes, and sticky actions.
- Flutter booking modals provide date, vendor, generator, and capacity fields, but omit assignment mode, capacity chips, date range, and notes.
- Stitch add-generator modal uses capacity radio chips and a notes textarea; Flutter uses text fields/dropdowns in `lib/features/generators/widgets/add_generator_modal.dart`.

UI impact:

The modal container, blur, close button, and footer are aligned, but the internal form layout is less dense and less guided than the Stitch UI.

UI recommendation:

Add the missing visible controls: segmented assignment mode, capacity chips, notes fields, and date-range controls where shown in Stitch.

### P1: Create/Add CTA Color Is Inconsistent

Evidence:

- Stitch/AGENTS reserve amber `#fbbf24` for create/add CTAs.
- `ExpandableFABMenu` uses amber for the collapsed action button.
- `FloatingSearchFAB` uses navy for the add FAB.
- Modal CREATE/SAVE buttons use navy in add/edit modal files.

UI impact:

Equivalent create/add actions do not share one visual priority color.

UI recommendation:

Use amber background with navy text for create/add buttons and FABs. Keep navy for app bars, structural navigation, and non-create primary actions.

### P2: Token Usage Is Mostly Correct, With Some Local Visual Values

Aligned:

- Core colors match Stitch: primary, primary dark, accent, success, warning, danger, background, surface, surface container, border.
- Core dimensions match: 16px mobile gutter, 8px functional radius, 12px modal radius, 9999px pill radius.
- Typography families match: Space Grotesk for display/headline/labels, Inter for body.

Drift evidence:

- `SystemHealthScreen` uses `Colors.blue` for the memory chart line.
- `StatusBadge` overrides letter spacing locally.
- Some cards use radius `12`, which is between the specified 8px functional and 16px structural radii.
- Several widgets use direct shadow literals instead of shared visual tokens.

UI impact:

These are small individually, but they make the UI harder to keep visually consistent across screens.

UI recommendation:

Replace local visual values with design tokens or promote approved derived values into `AppColors`/theme constants.

### P2: Bottom Navigation and Drawer Are Close, but Need Visual Screenshot Validation

Evidence:

- The app has a dark bottom nav, side drawer, bottom search/action zone, FAB expansion, and blur overlay.
- Stitch exports rely heavily on fixed bottom safe-area behavior, z-index layering, and blur/backdrop stacking.

UI impact:

Static review suggests alignment, but bottom UI is where visual overlap, safe-area padding, and z-order bugs usually show up.

UI recommendation:

Run screenshots/goldens for dashboard, bookings, vendors, generators, and modal-open states against Stitch `screen.png`.

## UI Remediation Order

1. Add visible user-management create/edit/delete UI.
2. Replace snackbar-only vendor/generator edit affordances with visible modals or menus.
3. Enrich booking/generator modals to match Stitch form density.
4. Normalize all create/add CTA surfaces to amber.
5. Remove ad hoc UI colors, radii, shadows, and letter-spacing overrides.
6. Run screenshot comparison against Stitch `screen.png` exports.

## Verification

This is a UI-only report update. No Dart files were modified and no Flutter tests were run.
