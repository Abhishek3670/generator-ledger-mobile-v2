---
name: Genset Industrial Ledger
colors:
  surface: '#f9f9f9'
  surface-dim: '#dadada'
  surface-bright: '#f9f9f9'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3f3'
  surface-container: '#eeeeee'
  surface-container-high: '#e8e8e8'
  surface-container-highest: '#e2e2e2'
  on-surface: '#1a1c1c'
  on-surface-variant: '#45464d'
  inverse-surface: '#2f3131'
  inverse-on-surface: '#f0f1f1'
  outline: '#76777d'
  outline-variant: '#c6c6cd'
  surface-tint: '#565e74'
  primary: '#000000'
  on-primary: '#ffffff'
  primary-container: '#131b2e'
  on-primary-container: '#7c839b'
  inverse-primary: '#bec6e0'
  secondary: '#545f73'
  on-secondary: '#ffffff'
  secondary-container: '#d5e0f8'
  on-secondary-container: '#586377'
  tertiary: '#000000'
  on-tertiary: '#ffffff'
  tertiary-container: '#261a00'
  on-tertiary-container: '#a87d00'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dae2fd'
  primary-fixed-dim: '#bec6e0'
  on-primary-fixed: '#131b2e'
  on-primary-fixed-variant: '#3f465c'
  secondary-fixed: '#d8e3fb'
  secondary-fixed-dim: '#bcc7de'
  on-secondary-fixed: '#111c2d'
  on-secondary-fixed-variant: '#3c475a'
  tertiary-fixed: '#ffdf9f'
  tertiary-fixed-dim: '#f9bd22'
  on-tertiary-fixed: '#261a00'
  on-tertiary-fixed-variant: '#5c4300'
  background: '#f9f9f9'
  on-background: '#1a1c1c'
  surface-variant: '#e2e2e2'
  success-emerald: '#059669'
  warning-amber: '#d97706'
  danger-rose: '#dc2626'
  border-slate: '#cbd5e1'
  surface-light: '#f8fafc'
  text-secondary: '#475569'
typography:
  display-lg:
    fontFamily: Space Grotesk
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Space Grotesk
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Space Grotesk
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 26px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
  label-caps:
    fontFamily: Space Grotesk
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.2em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 24px
  container-max: 1200px
---

## Brand & Style

The design system is engineered for **industrial-grade precision** and robust technical management. It targets fleet operators and logistics managers who require high-density data visualization and real-time status tracking.

The visual style is **Corporate / Modern** with a focus on technical utility. It utilizes a deep slate framework to establish an authoritative, stable environment, punctuated by vibrant amber accents that signal interactivity and forward momentum. The interface is characterized by ultra-clean data density, crisp structural borders, and flat-color surface layers, ensuring that operational metrics remain the primary focus.

## Colors

The color palette is built on a foundation of **Deep Slate Navy** for core structural elements like navbars and headers. 

- **Primary & Secondary**: Used for the foundational UI shell and high-contrast text.
- **Industrial Amber (Tertiary)**: Reserved strictly for primary call-to-actions (CTAs) and active navigational indicators.
- **Semantic States**: Success (Emerald), Warning (Amber), and Danger (Rose) are used for status badges and left-accented alert boxes. 
- **Surface Strategy**: The background uses a very light neutral gray (`#fafafa`), while internal cards use pure white. Alternating table rows and secondary sections utilize a soft slate-50 (`#f8fafc`) to maintain separation without heavy shadows.

## Typography

This design system employs a dual-font strategy to balance technical posture with legibility. 

**Space Grotesk** is the primary display face, used for all headings, navigation links, and numeric statistics to convey a futuristic, structured aesthetic. **Inter** (or the system sans-serif stack) handles all body copy, form inputs, and tabular data to ensure maximum readability and platform-native performance. 

- **Hierarchy**: Headlines use tighter letter-spacing for a compact look.
- **Scanning**: Small utility labels use `label-caps` with significant tracking (0.2em) to facilitate rapid visual scanning of category types.

## Layout & Spacing

The layout follows a **Fixed Grid** philosophy for desktop, centered on the viewport with a maximum content width of 1200px.

- **Rhythm**: All spacing is derived from a 4px base unit. 
- **Density**: The system favors a high-density layout. Main container margins are 32px on desktop and 16px on mobile. 
- **Grid Strategy**: A 2-column layout is used for dashboards (sidebar + main content) on screens above 1024px. Below this breakpoint, the layout collapses into a single-column stack with the sidebar transforming into a hidden drawer or top-level menu.

## Elevation & Depth

Hierarchy is established through **Tonal Layers** and **Low-Contrast Outlines** rather than heavy shadows.

- **Surface Tiers**: The master background is neutral (`#fafafa`). Interactive cards and panels are elevated using a white background and a 1px solid slate-200 border.
- **Shadow Character**: A single, ultra-soft shadow token is used for stats cards and forms: `0 1px 2px 0 rgba(15, 23, 42, 0.05)`. This provides a subtle "lift" without breaking the technical, flat aesthetic.
- **Glassmorphism**: The sticky navbar utilizes a 95% opacity blur (`backdrop-blur bg-slate-900/95`) to maintain context while scrolling through dense data logs.

## Shapes

The shape language combines structured containers with highly approachable interactive elements.

- **Structural Panels**: Large cards and dashboard containers use **16px (2xl)** rounded corners.
- **Functional Elements**: Form inputs, small cards, and internal sections use **8px (md)** rounded corners.
- **Interactive Widgets**: All buttons, status badges, and user avatars are **strictly pill-shaped** (rounded-full). This creates a clear visual distinction between static layout containers and clickable interface objects.

## Components

### Buttons
- **Primary**: Pill-shaped, Slate-900 background with white text.
- **Accent**: Pill-shaped, Amber-400 background with dark navy text. Used for "Create" or "Add" actions.
- **Ghost/Secondary**: Pill-shaped, 1px slate-200 border, slate-600 text.

### Status Badges
Badges are pill-shaped with light background tints and dark text. They **must** include prefix icons for accessibility:
- **Confirmed**: Emerald theme with "✓" prefix.
- **Pending**: Amber theme with "⏱" prefix.
- **Cancelled**: Rose theme with "✕" prefix.

### Data Tables
Tables use Slate-900 headers with white, uppercase Space Grotesk labels. Rows utilize alternating backgrounds (Slate-50) for horizontal scanning legibility.

### Inputs
Fields use a 1px border and 8px radius. On focus, they should transition to a solid Slate-900 border with a soft glow: `box-shadow: 0 0 0 3px rgba(15, 23, 42, 0.1)`.

### Alert Boxes
Left-accented containers with a 4px solid vertical border. Info boxes use a blue accent, while Error boxes use a red accent, both with highly desaturated background tints of the same hue.