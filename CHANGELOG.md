# Changelog

All notable changes to the Stride project will be documented in this file.

## [Unreleased] - 2026-02-12

### 🚀 Major Changes

- **Project Rename:** Transformed `ScreenDetector` into **Stride**.
  - Updated all branding, documentation, and internal symbols.
  - Migrated data storage to `~/Library/Application Support/Stride/`.
  - Renamed main app entry point to `StrideApp`.

- **New "Live" Tab:** Replaced the static "Now" dashboard with a dynamic **Ambient Status** experience.
  - **Atmospheric Background:** Background color now shifts and pulses based on the active app's category (e.g., Moss Green for Productivity, Slate for Dev).
  - **Editorial Typography:** Introduced magazine-style headers and a high-impact, thin-weight session timer.
  - **Glassmorphism Cards:** Secondary stats and recent activity are now housed in blurred, ultra-thin material cards.
  - **Real-Time Context:** Added a "Recent Context" section showing the last 3 apps used for immediate workflow awareness.

### ✨ Features

- **Ambient Intelligence:**
  - Added `currentCategoryColor` to `AppState` to drive UI theming.
  - Implemented `getRecentApplications` in `UsageDatabase` to fetch real user history.
  - Added smart icon guessing for common apps (Xcode, Safari, Slack, etc.).

- **UI Polish:**
  - Updated `QuickStatCard` to use the new "Glass" aesthetic with hover elevation.
  - Renamed "Now" tab to "Live" with a `bolt.fill` icon to reflect energy and real-time tracking.
  - Added smooth spring animations for all entry transitions.

### 🔧 Improvements

- **Performance:**
  - Optimized `AppMonitor` to use event-driven detection for app switches and 2s polling for windows.
  - Reduced CPU usage by caching window titles and checking for changes before notifying the delegate.

- **Architecture:**
  - Consolidated `CurrentSessionView` logic into a single, cohesive struct.
  - Added comprehensive documentation to `AppMonitor`, `SessionManager`, and `WindowTitleProvider`.
