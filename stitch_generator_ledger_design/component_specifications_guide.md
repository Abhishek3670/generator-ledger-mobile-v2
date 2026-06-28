# Component Specification: Genset Industrial Ledger

## 1. Global Navigation Components

### Side Navigation Drawer (Global)
- **Background:** `bg-slate-900`
- **Text:** `text-slate-100`
- **Header:** User Profile Avatar with Name and Role.
- **Links:** Dashboard, Bookings, Vendors, Gensets.
- **Bottom Actions:** Settings (Icon + Label), Logout (Icon).
- **Interaction:** Triggered via Menu Icon in Top Bar or slide from left. Overlaps bottom navigation.

### Bottom Action Zone (Directories)
- **Container:** `fixed bottom-0 left-0 w-full p-4 flex gap-4 items-center`
- **Search Bar:** `flex-1 bg-white/90 backdrop-blur border border-slate-200 rounded-full px-4 h-12 shadow-sm`
- **Floating Action Button (FAB):** `w-12 h-12 bg-slate-900 text-white rounded-full flex items-center justify-center shadow-lg`
- **Expansion Logic:** On click, expands vertically to show "Add" sub-options. Main page triggers a backdrop blur (`backdrop-blur-md`).

## 2. Shared UI Patterns

### Directory Cards (Vendors, Bookings, Gensets)
- **Shape:** `rounded-lg border border-slate-200 bg-white`
- **Header:** `bg-slate-900 text-white p-3 rounded-t-lg flex justify-between`
- **Content:** Key-value pairs using `text-slate-500` for labels and `text-slate-900` for values.
- **Interactions:** 
  - **Slide-to-Modify:** Swipe left to reveal Amber "Modify" action.
  - **Slide-to-Delete:** Swipe right to reveal Red "Delete" action.

### Status Badges
- **Confirmed/Healthy:** `bg-emerald-100 text-emerald-800 rounded-full px-3 py-1 text-xs font-bold`
- **Active:** `bg-emerald-500/10 text-emerald-600 rounded-full px-3 py-1 text-xs font-bold`
- **Pending:** `bg-amber-100 text-amber-800 rounded-full px-3 py-1 text-xs font-bold`

## 3. High-Density Form Modals
- **Layout:** Floating centered card with `rounded-xl` and `shadow-2xl`.
- **Z-Index:** Highest priority over backdrop blur.
- **Header:** Centered Title with a close (X) icon in the top right.
- **Fields:** Stacked vertically on mobile. Side-by-side only for short identifiers (e.g., ID and Date).
- **Actions:** Primary (Save) and Secondary (Cancel/Delete) sticky to the bottom of the modal.