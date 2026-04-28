# Unified Timer Display Design

**Date:** 2026-04-28  
**Feature:** Replace separate minutes/seconds labels with unified MM:SS format display

## Overview

Transform the Timer app's countdown display from separate `5'` and `30"` labels to a unified `5:30` format with warning color for urgency when under 1 minute.

## Current State

The timer currently uses two separate labels:
- `minutesLabel`: 35pt font showing `5'` (large, upper position)
- `secondsLabel`: 15pt font showing `30"` (small, lower position)  
- Times under 60 seconds show `45"` in minutes label, seconds label empty
- Dock badge already uses `MM:SS` format

## Requirements

1. **Unified Display Format**: Show `MM:SS` format (e.g., `5:30`, `0:45`)
2. **Consistent Font Size**: 30pt monospaced font for entire display
3. **Warning State**: Light orange color when time < 1 minute
4. **Instant Color Change**: Direct switch at 60-second threshold
5. **Preserve Normal Color**: Keep current minutes color for times ≥ 1 minute

## Design

### UI Component Changes

**Replace dual label system:**
- **Remove**: `minutesLabel` and `secondsLabel` from `MVClockView`
- **Add**: Single `timerDisplayLabel` with:
  - Font: 30pt monospaced (`NSFont.monospacedDigitSystemFont(ofSize: 30, weight: .medium)`)
  - Position: Where `minutesLabel` currently sits (x: 0, y: 57, width: 150, height: 25)
  - Alignment: Center
  - Color: Dynamic based on time remaining

**Color Assets:**
- **Normal**: Use existing `NSColor(resource: .minutes)` 
- **Warning**: New color asset `timer-warning-color` (light orange)

### Display Logic Changes

**New TimerLogic Functions:**
```swift
static func timerDisplayString(seconds: CGFloat) -> String {
  let minutes = Int(floor(seconds / 60))
  let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
  return String(format: "%02d:%02d", minutes, secs)
}

static func isWarningState(seconds: CGFloat) -> Bool {
  return seconds < 60
}
```

**Behavior:**
- `300 seconds` → `"05:00"` (normal color)
- `90 seconds` → `"01:30"` (normal color)
- `45 seconds` → `"00:45"` (light orange)
- Always zero-padded for consistent width

### Integration Changes

**MVClockView Updates:**
- Remove `minutesLabel`, `secondsLabel`, and related suffix width properties
- Replace `updateLabels()` logic with single label update:
  ```swift
  timerDisplayLabel.string = TimerLogic.timerDisplayString(seconds: self.seconds)
  timerDisplayLabel.textColor = TimerLogic.isWarningState(seconds: self.seconds) 
    ? NSColor(resource: .timerWarning) 
    : NSColor(resource: .minutes)
  ```

**Unchanged Systems:**
- Timer countdown functionality remains identical
- Dock badge display (already uses MM:SS format)  
- Accessibility announcements (will naturally read "5 minutes 30 seconds")
- Input handling and arrow controls
- Sound and notification systems

## Testing Requirements

**Unit Tests (TimerLogic):**
- `timerDisplayString()` output validation
- `isWarningState()` threshold accuracy  
- Edge cases: 0 seconds, 59 seconds, 60 seconds, large values

**UI Tests:**
- Visual verification of unified display format
- Color change behavior at 60-second threshold
- Layout positioning and sizing
- Font rendering consistency

**Regression Tests:**
- Ensure all existing timer functionality works unchanged
- Verify dock badge format remains correct
- Test input methods still work with new display

## Implementation Notes

**Cleanup:**
- Mark `minutesDisplayString()` and `secondsDisplayString()` as deprecated
- Remove in future version after confirming no external dependencies
- Clean up related test cases that test the old separate format

**Color Asset:**
- Add `timer-warning-color.colorset` to Assets.xcassets
- Light orange value: approximately `#FF8C00` or similar
- Support both light and dark mode variants

**Backward Compatibility:**
- No API changes affecting external integrations  
- Dock badge format unchanged
- Timer URL scheme and CLI commands unaffected