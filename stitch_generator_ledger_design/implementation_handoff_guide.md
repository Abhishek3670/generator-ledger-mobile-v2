# Implementation Handoff Guide: Genset Industrial Ledger (Mobile)

## 1. Design Overview
The **Genset Industrial Ledger** mobile application is a high-density industrial management tool. It utilizes a technical aesthetic defined by the **Genset Industrial Ledger Design System**.

### Core Visual Language:
- **Typography:** Space Grotesk (Headings/Technical Labels), System Sans-Serif (Body Copy).
- **Color Palette:**
  - **Surface:** Slate-900 (`#0f172a`) for Top App Bars and dark-themed components.
  - **Accent:** Amber-400 (`#fbbf24`) for primary actions and active states.
  - **Status:** Emerald-600 (Success), Amber-600 (Warning), Red-600 (Danger).
  - **Background:** Neutral Slates (`#f8fafc`, `#fafafa`) for high-legibility light mode.
- **Shapes:** 8px (`rounded-md`) for standard cards, fully rounded (`rounded-full`) for buttons and badges.

## 2. Screen Inventory & Component Mapping

### A. Authentication
- **Minimalist Mobile Login ({{DATA:SCREEN:SCREEN_73}}):** Clean, centered entry point with high-contrast inputs.

### B. Core Management (Directories)
- **Mobile Dashboard ({{DATA:SCREEN:SCREEN_40}}):** Unified metrics row, high-density calendar, and date-specific booking details.
- **Vendor Directory ({{DATA:SCREEN:SCREEN_45}}):** Card-based retailer/rental vendor lists with bottom-anchored "Action Zone" and backdrop blur.
- **Bookings Directory ({{DATA:SCREEN:SCREEN_56}}):** Aligned with the vendor layout for ergonomic consistency.
- **Generators Directory ({{DATA:SCREEN:SCREEN_48}}):** Multi-category fleet listing (Retailer, Permanent, Emergency).

### C. Interaction Modals (Floating Forms)
- **Add Flows:** Floating Add Vendor ({{DATA:SCREEN:SCREEN_74}}), Add Booking ({{DATA:SCREEN:SCREEN_67}}), and Add Generator ({{DATA:SCREEN:SCREEN_4}}).
- **Edit/Detail Flows:** Edit Booking ({{DATA:SCREEN:SCREEN_2}}), Generator Detail ({{DATA:SCREEN:SCREEN_75}}), and Detail Modal ({{DATA:SCREEN:SCREEN_60}}).

### D. Settings & Admin
- **System Health ({{DATA:SCREEN:SCREEN_76}}):** Real-time CPU/Memory charts and postgres connection status.
- **User Management ({{DATA:SCREEN:SCREEN_64}}):** Permission matrix for Admin/Operator roles.
- **Integrations ({{DATA:SCREEN:SCREEN_42}}):** Placeholder for future extensibility.

## 3. Frontend Architecture Recommendations
- **Styling:** Tailwind CSS (consistent with the design system tokens).
- **Icons:** Material Design Icons or SVG-based custom sets.
- **Components:** Modularize the "Bottom Action Bar" and "Side Navigation Drawer" ({{DATA:SCREEN:SCREEN_59}}) as they are shared across multiple views.
- **State Management:** Critical for real-time status updates (Healthy/Active/Confirmed) and complex filtering across directories.

## 4. Next Steps
1. **Export Code:** You can inspect and copy the HTML/CSS for each screen to build your component library.
2. **Asset Extraction:** Download all custom SVG icons and brand assets.
3. **Prototype Logic:** Implement the "Slide to Modify" and "Backdrop Blur" interactions using CSS transitions and simple JavaScript.
