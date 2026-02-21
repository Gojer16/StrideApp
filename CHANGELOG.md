# Changelog

All notable changes to the Stride project will be documented in this file.

## [Unreleased] - 2026-02-21

### 🚀 Major Changes

- **Deceptive Day Mode:** Introduced customizable day boundaries for the Today tab.
  - **Custom Day Start Hour:** Users can now define when their day starts (e.g., 4:00 AM instead of midnight).
  - **Extended Mode Indicator:** When viewing data before the day start hour, the Today tab shows "(extended)" with a "LATE NIGHT" badge.
  - **Logical Day Grouping:** Late-night work sessions (e.g., 11 PM - 2 AM) now stay grouped with the logical work day they belong to.
  - **Settings Panel:** New Settings view accessible from the sidebar for configuring preferences.
  - **Scope:** Feature applies only to Today tab; other views (This Week, All Apps) continue using calendar days.

### ✨ Features

- **Habit Tracker UX Improvements:**
  - **Hover Icons:** Grid cells now show contextual +/− icons on hover (+ for empty cells, − for filled cells)
  - **Option+Click Decrement:** Hold Option key while clicking to quickly undo/decrement sessions
  - **Smart Deletion:** Decrementing to zero now removes the entry from database (keeps data clean)
  - **Shrink Animation:** Decrement actions have a satisfying "shrink" effect (opposite of increment's "pop")
  - **First-Time Hint:** After 3 increments, users see a dismissible banner teaching the Option+Click shortcut
  - **Enhanced Tooltips:** Hover tooltips now show "Click to add • Option+Click to remove"
  - **User Preferences System:** New persistent settings manager for app-wide preferences

## [Unreleased] - 2026-02-12

### 🚀 Major Changes

- **Tactile Habit Tracker:** Transformed the habit tracking experience from data entry to a satisfying, high-speed interaction.
  - **Poppable Grid:** Implemented "Tactile Toggle" allowing users to increment sessions with a single left-click on any grid square.
  - **5-Level Intensity:** Rebuilt the visualization to use 5 distinct levels (0 to 4+ sessions), making high-effort days visually rewarding.
  - **Any session > 0:** Updated logic so that even a single session counts as a "Completed Day" for all statistics and streaks.
  - **Bento Dashboard:** Redesigned the main habit view with a professional Bento-grid for overall statistics.

- **This Week Tab Redesign:** Transformed the weekly trends view into a professional **Weekly Reflection** dashboard.
  - **Removed Noise:** Deleted the "Insights" section to focus on clean, factual data visualization.
  - **Interactive Activity Chart:** Implemented a new bar chart with interactive day selection and brand-aligned styling.

- **Today Tab Redesign:** Replaced the asymmetric daily goal view with a professional **Editorial Summary Dashboard**.
  - **Removed Daily Goal:** Shifted focus to pure usage transparency by removing the 8-hour goal logic and UI.
  - **KPI Grid:** Added a balanced row of core metrics: Active Time, App Switches, and Total Apps Used.

- **Project Rename:** Transformed `ScreenDetector` into **Stride**.
  - Updated all branding, documentation, and internal symbols.
  - Migrated data storage to `~/Library/Application Support/Stride/`.

- **New "Live" Tab:** Replaced the static "Now" dashboard with a dynamic **Ambient Status** experience.
  - **Atmospheric Background:** Background color now shifts and pulses based on the active app's category.

### ✨ Features

- **Improved App Management:**
  - **Selection in All Apps:** Enabled clicking on app cards to open a detailed sidebar.
  - **Sidebar Category Editing:** Change an app's category directly from the sidebar with instant UI refreshes.

- **Enhanced Weekly Log:**
  - **Easy Day Selector:** Replaced the bulky calendar with high-tap-target day chips.
  - **Win Descriptions:** Added a dedicated text field for "Win of the Day" achievement notes.
  - **Premium Deletion:** Implemented a custom, polished confirmation overlay for destructive actions.

### 🔧 Improvements

- **Reliability & Consistency:**
  - **Crash Resolution:** Fixed multiple database deadlocks by refactoring `WeeklyLogDatabase` and `HabitDatabase` for safe thread-safe patterns.
  - **Standardized IDs:** All category IDs are now forced to lowercase to prevent case-sensitivity mismatches.
  - **Hitbox Optimization:** Ensured all buttons and input fields have large, responsive click targets.

### 📝 Documentation

- **System-Wide Comments:** Added comprehensive architectural and data-flow documentation to all core and UI files.
- **Project Structure:** Updated `README.md` and `COLORS.md` to reflect the current state of the Stride ecosystem.
