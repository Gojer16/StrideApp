# Deceptive Day Feature - Implementation Summary

## Overview
The "Deceptive Day" feature allows users to define a custom day boundary (e.g., 4:00 AM instead of midnight) so that late-night work sessions remain grouped with the logical "work day" they belong to.

## Problem Solved
Traditional time trackers reset at midnight, which breaks psychological continuity for:
- Developers working late into the night
- Night owls with non-traditional schedules
- Anyone doing deep work past midnight

A session from 11:00 PM to 2:00 AM would be artificially split across two days, and the Today tab would show a blank slate at 12:01 AM, killing momentum.

## Solution
Users can set a "day start hour" (0-23) in Settings. When the current time is before this hour, the app treats it as an extension of the previous calendar day.

### Example
- User sets day start to 4:00 AM
- At 2:00 AM on Feb 22, the app shows "Friday, Feb 21 (extended)"
- Today tab queries sessions from Feb 21 4:00 AM to Feb 22 4:00 AM
- Late-night work stays grouped with the previous day

## Implementation Details

### Files Modified

**1. UserPreferences.swift**
- Added `@AppStorage("dayStartHour")` property (default: 0)
- Added `logicalStartOfToday` computed property for adjusted day boundary
- Added `isInExtendedDay` to check if in extended mode
- Added `logicalDate` for display purposes

**2. SettingsView.swift** (NEW)
- Created settings UI with hour picker (0-23)
- Live preview showing current mode
- Glassmorphism design matching Stride aesthetic

**3. MainWindowView.swift**
- Added "Settings" navigation item
- Wired up SettingsView in navigation switch

**4. Models.swift (UsageDatabase)**
- Modified `getTodayTime()` to use `UserPreferences.shared.logicalStartOfToday`
- Replaced `Calendar.current.startOfDay()` with logical boundary

**5. TodayView.swift**
- Updated `formattedDate()` to show logical date with "(extended)" indicator
- Added visual "LATE NIGHT" badge when in extended mode
- Badge uses moon icon and purple color for night-time aesthetic

## User Experience

### Settings Flow
1. User navigates to Settings from sidebar
2. Selects day start hour from dropdown (e.g., "4:00 AM")
3. Live preview shows: "Right now, you're in extended mode. Today tab shows Friday, Feb 21."
4. Setting persists via UserDefaults

### Today Tab Experience
**Normal Mode (after day start hour):**
- Header shows: "SATURDAY, FEBRUARY 22"
- No special indicators

**Extended Mode (before day start hour):**
- Header shows: "FRIDAY, FEBRUARY 21 (EXTENDED)" with moon badge
- Purple "LATE NIGHT" badge appears next to date
- All data shows previous day's sessions

### Scope
- **Applies to:** Today tab only
- **Does NOT affect:** This Week, All Apps, Habit Tracker, Weekly Log
- These views continue using calendar days for consistency

## Technical Notes

### Date Calculation Logic
```swift
// If current hour < day start hour, use yesterday's boundary
if currentHour < dayStartHour {
    let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
    var components = calendar.dateComponents([.year, .month, .day], from: yesterday)
    components.hour = dayStartHour
    return calendar.date(from: components)!
}
```

### Database Query
The SQL query in `getTodayTime()` filters sessions where:
```sql
sessions.start_time >= logicalStartOfToday.timeIntervalSince1970
```

This ensures sessions are grouped by logical day, not calendar day.

### Edge Cases Handled
1. **Day start hour = 0**: Behaves exactly like original implementation (midnight boundary)
2. **Changing setting mid-day**: Immediately affects Today tab on next load
3. **Exactly at boundary hour**: Uses current day (e.g., at 4:00 AM, day has started)
4. **Day start hour = 23**: Only 1 hour per day is "extended mode" (23:00-00:00)

## Testing Checklist

- [x] Build succeeds without errors
- [x] Settings view accessible from sidebar
- [x] Hour picker displays all 24 hours with readable labels
- [x] Setting persists across app restarts
- [x] Today tab shows correct logical date
- [x] Extended mode badge appears when appropriate
- [x] Database queries respect logical day boundary
- [x] Other tabs unaffected (This Week, All Apps, etc.)

## Future Enhancements (Not Implemented)

1. **Per-view configuration**: Allow users to apply offset to other views
2. **Multiple profiles**: Different day boundaries for weekdays vs weekends
3. **Smart detection**: Auto-detect typical sleep patterns and suggest day start hour
4. **Timezone handling**: Ensure correct behavior across timezone changes

## Design Decisions

### Why Today Tab Only?
- **Consistency**: Historical data (This Week, All Apps) should use calendar days for accurate reporting
- **Simplicity**: Applying offset globally would complicate weekly/monthly aggregations
- **User expectation**: "This Week" means Monday-Sunday, not shifted boundaries

### Why Show "(extended)" Indicator?
- **Transparency**: User should know they're viewing adjusted data
- **Debugging**: Makes it obvious when the feature is active
- **Aesthetic**: Purple "LATE NIGHT" badge adds personality without being intrusive

### Why UserDefaults Instead of Database?
- **Performance**: No database query needed for every date calculation
- **Simplicity**: @AppStorage provides automatic persistence and observation
- **Scope**: This is a UI preference, not usage data

## Conclusion

The Deceptive Day feature successfully solves the "midnight trap" problem by allowing users to define their own day boundaries. The implementation is minimal, performant, and scoped to the Today tab where it provides the most value.

**Total lines of code added:** ~150
**Files created:** 1 (SettingsView.swift)
**Files modified:** 4
**Build time impact:** Negligible
**Runtime performance impact:** None (single date calculation per view load)
