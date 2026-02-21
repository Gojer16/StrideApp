# Changelog

All notable changes to the Stride project will be documented in this file.

## [Unreleased] - 2026-02-21

### 🚀 Major Changes

- **Sparklines for Top Apps:** Added temporal context to reveal usage patterns throughout the day.
  - **Hourly Visualization:** Tiny line graphs next to top 3 apps showing when they were used (24-hour breakdown).
  - **Pattern Recognition:** Reveals "Deep Work" in morning vs "Social Media" in afternoon patterns.
  - **Smart Loading:** Only loads hourly data for top 3 apps (performance optimization).
  - **Category-Colored:** Sparklines match app category colors for visual consistency.
  - **Minimal Design:** 70×20px sparklines with gradient fill, non-intrusive and elegant.
  - **Actionable Insights:** Transforms "Xcode: 3hrs" into "Xcode: 3hrs ▁▂▅█▇▃▁" showing morning focus.

- **Browser Domain Parsing:** Transformed generic browser time into granular domain-level insights.
  - **Domain Extraction:** Intelligent parser extracts domains from browser window titles (Chrome, Safari, Firefox, Edge, Brave, Arc).
  - **Web Activity Section:** New section in Today tab showing top domains with time breakdown (e.g., "github.com: 2hrs | stackoverflow.com: 1hr").
  - **Domain Aggregation:** Combines time across multiple windows and browsers for same domain.
  - **Smart Parsing:** Handles URLs, common site names, and domain patterns with 20+ site mappings.
  - **Browser Exclusion:** Browsers removed from app list to avoid duplication (shown as domains instead).
  - **Actionable Insights:** Transforms "Google Chrome: 4hrs" into specific website breakdown.

- **Today Tab Performance Optimization:** Eliminated main thread blocking for instant load times.
  - **Batch Query:** Replaced 200+ individual database queries with single GROUP BY query.
  - **Background Loading:** All database work moved to background threads, UI never blocks.
  - **In-Memory Cache:** 2-second cache for repeated visits (<1ms load time).
  - **Database Indexes:** Added indexes on sessions(start_time) and windows(app_id) for 50%+ faster queries.
  - **Performance Gain:** 40x faster first load (2000ms → 50ms), 2000x faster cached loads.
  - **User Experience:** Today tab now appears instantly, preserving "Editorial feel."

- **Idle Detection & Active vs Passive Time Tracking:** Introduced system-wide idle detection to distinguish between actual user activity and passive window focus.
  - **Active Time Metric**: Now accurately reflects keyboard/mouse activity, not just window focus time.
  - **Passive Time Metric**: New KPI card in Today tab showing time spent watching videos, reading, or away from computer.
  - **Configurable Threshold**: Set idle threshold in Settings (15-300 seconds, default: 65s).
  - **Session Pause/Resume**: Sessions automatically pause when idle, resume when user returns (same session continues).
  - **IOKit Integration**: Uses macOS HIDIdleTime for lightweight, system-wide idle detection.
  - **Database Migration**: Added passive_duration column to sessions table.
  - **Raw Truth Philosophy**: Ensures metrics reflect actual engagement, not inflated window focus time.

- **Deceptive Day Mode:** Introduced customizable day boundaries for the Today tab.
  - **Custom Day Start Hour:** Users can now define when their day starts (e.g., 4:00 AM instead of midnight).
  - **Extended Mode Indicator:** When viewing data before the day start hour, the Today tab shows "(extended)" with a "LATE NIGHT" badge.
  - **Logical Day Grouping:** Late-night work sessions (e.g., 11 PM - 2 AM) now stay grouped with the logical work day they belong to.
  - **Settings Panel:** New Settings view accessible from the sidebar for configuring preferences.
  - **Scope:** Feature applies only to Today tab; other views (This Week, All Apps) continue using calendar days.

### ✨ Features

- **Habit Tracker Performance & Reliability Improvements:**
  - **Debounced Clicks:** 200ms debounce on increment actions prevents rapid-fire database writes
  - **Date Normalization:** Explicit date normalization in all database operations handles DST/timezone shifts
  - **Thread Safety:** Serial DispatchQueue ensures no race conditions on rapid clicks
  - **Optimistic UI:** Animations trigger immediately while database writes happen asynchronously
  - **Performance Notes:** Added documentation for future scaling to 50+ habits

- **Habit Tracker Tooltip Improvements:**
  - **Streak Badge Tooltip:** Explains "active" status (completed today or yesterday, resets after 2 days)
  - **Grid Cell Tooltips:** Shows session count AND target progress (e.g., "3 sessions • 15/30 min (50%)")
  - **Status Clarity:** Displays "Completed today" vs "Completed yesterday" for active streaks
  - **Inactive Streak Info:** Shows when streak is inactive and how to reactivate
  - **Better UX:** Clarifies streak logic without changing existing behavior

- **Collapsible Habit Cards:**
  - **Chevron Button:** Each habit card has a collapse/expand button in the header
  - **Minimal Collapsed State:** Shows only icon, name, streak, and success rate (single row, ~80pt)
  - **Per-Habit Memory:** Collapse state persists across app restarts
  - **Smart Default:** Habits with activity today expand, inactive habits collapse
  - **Global Toggle:** "Collapse All" / "Expand All" button in filter section
  - **Bounce Animation:** Smooth spring animations with staggered cascade effect
  - **Reduces Clutter:** Makes it easy to focus on active habits while keeping others accessible

- **Habit Tracker History Sidebar:**
  - **Info Icon on Hover:** Grid cells now show ℹ️ icon alongside +/− icons
  - **Slide-in Sidebar:** Click info icon to view habit history in elegant right-side panel
  - **30-Day Sparkline Chart:** Visual trend showing last month of activity
  - **14 Recent Entries:** Scrollable list with dates, values, and notes
  - **Read-Only View:** Clean, distraction-free history browsing
  - **Removed Long-Press:** Replaced confusing long-press gesture with discoverable info icon

- **Habit Tracker UX Improvements:**
  - **Hover Icons:** Grid cells now show contextual +/− icons on hover (+ for empty cells, − for filled cells)
  - **Option+Click Decrement:** Hold Option key while clicking to quickly undo/decrement sessions
  - **Smart Deletion:** Decrementing to zero now removes the entry from database (keeps data clean)
  - **Shrink Animation:** Decrement actions have a satisfying "shrink" effect (opposite of increment's "pop")
  - **First-Time Hint:** After 3 increments, users see a dismissible banner teaching the Option+Click shortcut
  - **Enhanced Tooltips:** Hover tooltips now show "Click to add • Option+Click to remove • ℹ️ for history"
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
