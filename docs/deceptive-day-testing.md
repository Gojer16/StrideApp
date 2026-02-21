# Deceptive Day Feature - Testing Guide

## Manual Testing Scenarios

### Scenario 1: Default Behavior (Midnight Boundary)
**Setup:**
1. Launch Stride
2. Navigate to Settings
3. Verify "Day starts at" is set to "Midnight (12:00 AM)"

**Expected:**
- Today tab shows current calendar date
- No "(extended)" indicator
- No "LATE NIGHT" badge
- Behavior identical to pre-feature implementation

---

### Scenario 2: Setting Custom Day Start Hour
**Setup:**
1. Navigate to Settings
2. Change "Day starts at" to "4:00 AM"

**Expected:**
- Dropdown shows "4:00 AM"
- Live preview appears below picker
- If current time is before 4:00 AM:
  - Preview shows: "Right now, you're in extended mode. Today tab shows [yesterday's date]."
- If current time is after 4:00 AM:
  - Preview shows: "Sessions before 4:00 AM will count as the previous day."

---

### Scenario 3: Extended Mode Active (Before Day Start Hour)
**Setup:**
1. Set day start hour to 4:00 AM
2. Test between 12:00 AM - 3:59 AM
3. Navigate to Today tab

**Expected:**
- Header shows: "[YESTERDAY'S DATE] (EXTENDED)"
- Purple "LATE NIGHT" badge with moon icon appears
- All metrics (Active Time, App Switches, Total Apps) show data from yesterday's logical day
- Category distribution includes sessions from yesterday 4:00 AM to now
- Top apps list shows yesterday's usage + current late-night session

**Example:**
- Current time: 2:30 AM on Saturday, Feb 22
- Day start: 4:00 AM
- Display: "FRIDAY, FEBRUARY 21 (EXTENDED)" with moon badge
- Data range: Friday 4:00 AM → Saturday 2:30 AM

---

### Scenario 4: Normal Mode (After Day Start Hour)
**Setup:**
1. Set day start hour to 4:00 AM
2. Test after 4:00 AM
3. Navigate to Today tab

**Expected:**
- Header shows current date without "(extended)"
- No "LATE NIGHT" badge
- All metrics show data from today's logical day (4:00 AM onwards)
- Category distribution starts from 4:00 AM today
- Top apps list shows only today's usage (since 4:00 AM)

**Example:**
- Current time: 10:00 AM on Saturday, Feb 22
- Day start: 4:00 AM
- Display: "SATURDAY, FEBRUARY 22"
- Data range: Saturday 4:00 AM → Saturday 10:00 AM

---

### Scenario 5: Boundary Transition (Exactly at Day Start Hour)
**Setup:**
1. Set day start hour to 4:00 AM
2. Test at exactly 4:00 AM
3. Navigate to Today tab

**Expected:**
- Extended mode ends (current day is used)
- Header shows current date without "(extended)"
- No "LATE NIGHT" badge
- Data range starts from 4:00 AM today

---

### Scenario 6: Extreme Value (23:00 Start Time)
**Setup:**
1. Set day start hour to "11:00 PM"
2. Test between 12:00 AM - 10:59 PM

**Expected:**
- Extended mode active for 23 hours per day
- Only 11:00 PM - 11:59 PM shows current date
- Most of the day shows previous date with "(extended)"

---

### Scenario 7: Other Tabs Unaffected
**Setup:**
1. Set day start hour to 4:00 AM
2. Test before 4:00 AM (extended mode active)
3. Navigate to each tab

**Expected:**
- **Today tab:** Shows extended mode (yesterday's date)
- **This Week tab:** Shows calendar week (Monday-Sunday)
- **All Apps tab:** Shows all-time data (no filtering)
- **Habit Tracker:** Uses calendar days
- **Weekly Log:** Uses calendar days
- **Live tab:** Shows current session (no date display)

---

### Scenario 8: Setting Persistence
**Setup:**
1. Set day start hour to 6:00 AM
2. Quit Stride completely
3. Relaunch Stride
4. Navigate to Settings

**Expected:**
- "Day starts at" still shows "6:00 AM"
- Today tab respects the saved setting
- No reset to default (midnight)

---

### Scenario 9: Mid-Day Setting Change
**Setup:**
1. Set day start hour to 4:00 AM at 10:00 AM
2. Note Today tab data
3. Change to 8:00 AM
4. Navigate back to Today tab

**Expected:**
- Data immediately updates to reflect new boundary
- If before 8:00 AM: Shows extended mode
- If after 8:00 AM: Shows normal mode
- No app restart required

---

### Scenario 10: Real-World Late Night Session
**Setup:**
1. Set day start hour to 4:00 AM
2. Work from 11:00 PM Friday to 2:00 AM Saturday
3. Check Today tab at 1:00 AM Saturday

**Expected:**
- Header shows: "FRIDAY, FEBRUARY 21 (EXTENDED)"
- Active Time includes entire session (11 PM - 1 AM)
- Session is NOT split across two days
- All apps used during this time appear in Friday's data

---

## Automated Testing (Future)

### Unit Tests Needed
```swift
// UserPreferences Tests
testLogicalStartOfToday_WithMidnightBoundary()
testLogicalStartOfToday_WithCustomBoundary_BeforeHour()
testLogicalStartOfToday_WithCustomBoundary_AfterHour()
testIsInExtendedDay_WithMidnightBoundary()
testIsInExtendedDay_WithCustomBoundary()
testLogicalDate_InExtendedMode()
testLogicalDate_InNormalMode()

// UsageDatabase Tests
testGetTodayTime_WithMidnightBoundary()
testGetTodayTime_WithCustomBoundary()
testGetTodayTime_AtBoundaryTransition()

// TodayView Tests
testFormattedDate_InExtendedMode()
testFormattedDate_InNormalMode()
testExtendedModeBadge_Visibility()
```

---

## Visual Regression Testing

### Screenshots to Capture
1. Settings view with default (midnight) setting
2. Settings view with custom (4:00 AM) setting
3. Settings view with live preview in extended mode
4. Today tab header in normal mode
5. Today tab header in extended mode (with badge)
6. Today tab full view in extended mode
7. Sidebar with Settings item highlighted

---

## Performance Testing

### Metrics to Monitor
- **Date calculation time:** Should be < 1ms
- **Database query time:** Should be unchanged from baseline
- **UI render time:** Should be unchanged from baseline
- **Memory usage:** Should be unchanged from baseline

### Load Testing
- Change day start hour 100 times rapidly
- Navigate between Today tab and other tabs 100 times
- Verify no memory leaks or performance degradation

---

## Edge Cases to Verify

1. **Timezone changes:** Does the feature work correctly after traveling?
2. **Daylight saving time:** Does the hour offset remain correct?
3. **Leap days:** Does Feb 29 work correctly?
4. **Year boundary:** Does Dec 31 → Jan 1 work correctly?
5. **First launch:** Does default (midnight) work without explicit setting?
6. **Database migration:** Does existing data work with new feature?
7. **Concurrent sessions:** Multiple windows open, setting changed in one
8. **System sleep:** Mac sleeps at 1 AM, wakes at 5 AM with 4 AM boundary

---

## Acceptance Criteria

✅ **Functional Requirements**
- [ ] User can set day start hour (0-23) in Settings
- [ ] Setting persists across app restarts
- [ ] Today tab shows logical date based on setting
- [ ] Extended mode indicator appears when appropriate
- [ ] Database queries respect logical day boundary
- [ ] Other tabs remain unaffected

✅ **UX Requirements**
- [ ] Settings UI is intuitive and clear
- [ ] Hour picker shows readable labels (not just numbers)
- [ ] Live preview provides immediate feedback
- [ ] Extended mode badge is visible but not distracting
- [ ] Date format remains consistent with app style

✅ **Performance Requirements**
- [ ] No noticeable performance impact
- [ ] Date calculations are instant
- [ ] Database queries are not slower
- [ ] UI remains responsive

✅ **Quality Requirements**
- [ ] Code compiles without errors
- [ ] No new warnings introduced
- [ ] Documentation is complete
- [ ] CHANGELOG is updated
- [ ] README is updated

---

## Known Limitations

1. **Today tab only:** Feature does not apply to other views
2. **No per-view configuration:** Cannot have different boundaries for different tabs
3. **No weekend/weekday profiles:** Same boundary applies every day
4. **No automatic detection:** User must manually set preferred hour
5. **No timezone awareness:** Uses system timezone without special handling

---

## Future Enhancement Ideas

1. **Smart suggestions:** Analyze sleep patterns and suggest optimal day start hour
2. **Weekend mode:** Different boundaries for weekdays vs weekends
3. **Global toggle:** Quick switch between calendar days and logical days
4. **Visual timeline:** Show day boundary on activity charts
5. **Export with logical days:** CSV/JSON exports respect custom boundaries
