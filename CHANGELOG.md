# Changelog

All notable changes to the Stride project will be documented in this file.

## [Unreleased] - 2026-02-12

### 🚀 Major Changes

- **This Week Tab Redesign:** Transformed the weekly trends view into a professional **Weekly Reflection** dashboard.
  - **Removed Noise:** Deleted the "Insights" section to focus on clean, factual data visualization.
  - **Interactive Activity Chart:** Implemented a new bar chart with interactive day selection and brand-aligned styling.
  - **Historical Log:** Added a refined "Detailed Log" section for easy day-by-day comparisons.

- **Today Tab Redesign:** Replaced the asymmetric daily goal view with a professional **Editorial Summary Dashboard**.
  - **Removed Daily Goal:** Shifted focus to pure usage transparency by removing the 8-hour goal logic and UI.
  - **KPI Grid:** Added a balanced row of core metrics: Active Time, App Switches, and Total Apps Used.
  - **Enhanced Visuals:** Updated the Category Mix donut chart and app rows with a high-contrast editorial aesthetic.

- **Project Rename:** Transformed `ScreenDetector` into **Stride**.
  - Updated all branding, documentation, and internal symbols.
  - Migrated data storage to `~/Library/Application Support/Stride/`.
  - Renamed main app entry point to `StrideApp`.

- **New "Live" Tab:** Replaced the static "Now" dashboard with a dynamic **Ambient Status** experience.
  - **Atmospheric Background:** Background color now shifts and pulses based on the active app's category.
  - **Editorial Typography:** Introduced magazine-style headers and high-impact session timers.
  - **Glassmorphism Cards:** Secondary stats and recent activity are now housed in blurred, ultra-thin material cards.

### ✨ Features

- **Improved App Management:**
  - **Selection in All Apps:** Enabled clicking on app cards to open a detailed sidebar for granular inspection.
  - **Sidebar Category Editing:** Users can now change an app's category directly from the detail sidebar with instant UI refreshes.
  - **Standardized Categories:** Fixed a bug where "Uncategorized" apps were missing from counts by standardizing on a single UUID system.

- **Ambient Intelligence:**
  - Added `currentCategoryColor` to `AppState` to drive UI theming.
  - Implemented `getRecentApplications` in `UsageDatabase` to fetch real user history.
  - Added smart icon guessing for common apps (Xcode, Safari, Slack, etc.).

### 🔧 Improvements

- **Reliability & Consistency:**
  - **Standardized IDs:** All category IDs are now forced to lowercase in the database and code to prevent case-sensitivity mismatches.
  - **Thread-Safe Updates:** Standardized database update operations to ensure immediate and reliable data persistence.
  - **Data Synchronization:** Implemented callback systems to ensure all tabs (Live, All Apps, Categories) stay perfectly in sync.

- **Performance:**
  - Optimized `AppMonitor` to use event-driven detection for app switches and 2s polling for windows.
  - Reduced CPU usage by caching window titles and checking for changes before notifying the delegate.

### 📝 Documentation

- **System-Wide Comments:** Added comprehensive architectural and data-flow documentation to all core and UI files.
- **Project Structure:** Updated `README.md` and `COLORS.md` to reflect the current state of the Stride ecosystem.
