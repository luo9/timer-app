# Unified Timer Display Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace separate minutes/seconds labels with unified MM:SS format display including warning colors for urgency.

**Architecture:** Single timerDisplayLabel replaces dual label system. New TimerLogic functions handle unified formatting and warning state detection. Color asset system supports light orange warning state.

**Tech Stack:** Swift, AppKit, Xcode asset catalogs, XCTest

---

## File Structure

**Files to Create:**
- `Timer/Assets.xcassets/timer-warning-color.colorset/Contents.json`

**Files to Modify:**
- `Timer/TimerLogic.swift` - Add `timerDisplayString()` and `isWarningState()` functions
- `Timer/MVClockView.swift` - Replace dual labels with single `timerDisplayLabel`
- `TimerTests/TimerTests.swift` - Add tests for new TimerLogic functions

---

### Task 1: Add Warning Color Asset

**Files:**
- Create: `Timer/Assets.xcassets/timer-warning-color.colorset/Contents.json`

- [ ] **Step 1: Create color asset directory**

```bash
mkdir -p "Timer/Assets.xcassets/timer-warning-color.colorset"
```

- [ ] **Step 2: Create color definition file**

Create `Timer/Assets.xcassets/timer-warning-color.colorset/Contents.json`:

```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.000",
          "green" : "0.549",
          "red" : "1.000"
        }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.200",
          "green" : "0.600",
          "red" : "1.000"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 3: Build to verify color asset**

Run: `make build`
Expected: Build succeeds with no color asset errors

- [ ] **Step 4: Commit color asset**

```bash
git add Timer/Assets.xcassets/timer-warning-color.colorset/
git commit -m "Add timer-warning-color asset for unified display

- Light orange color for times under 1 minute
- Support both light and dark mode variants"
```

---

### Task 2: Add TimerLogic Functions with Tests (TDD)

**Files:**
- Modify: `TimerTests/TimerTests.swift:260-end`
- Modify: `Timer/TimerLogic.swift:125-end`

- [ ] **Step 1: Write failing tests for timerDisplayString**

Add to `TimerTests/TimerTests.swift` after line 259:

```swift
  // MARK: - timerDisplayString

  func testTimerDisplayStringZero() {
    XCTAssertEqual(TimerLogic.timerDisplayString(seconds: 0), "00:00")
  }

  func testTimerDisplayStringUnderOneMinute() {
    XCTAssertEqual(TimerLogic.timerDisplayString(seconds: 45), "00:45")
  }

  func testTimerDisplayStringExactlyOneMinute() {
    XCTAssertEqual(TimerLogic.timerDisplayString(seconds: 60), "01:00")
  }

  func testTimerDisplayStringMultipleMinutes() {
    XCTAssertEqual(TimerLogic.timerDisplayString(seconds: 150), "02:30")
  }

  func testTimerDisplayStringLargeValue() {
    XCTAssertEqual(TimerLogic.timerDisplayString(seconds: 3661), "61:01")
  }

  func testTimerDisplayStringDecimalSeconds() {
    XCTAssertEqual(TimerLogic.timerDisplayString(seconds: 90.7), "01:30")
  }
```

- [ ] **Step 2: Write failing tests for isWarningState**

Add to `TimerTests/TimerTests.swift` after the timerDisplayString tests:

```swift
  // MARK: - isWarningState

  func testIsWarningStateTrue() {
    XCTAssertTrue(TimerLogic.isWarningState(seconds: 0))
    XCTAssertTrue(TimerLogic.isWarningState(seconds: 30))
    XCTAssertTrue(TimerLogic.isWarningState(seconds: 59))
    XCTAssertTrue(TimerLogic.isWarningState(seconds: 59.9))
  }

  func testIsWarningStateFalse() {
    XCTAssertFalse(TimerLogic.isWarningState(seconds: 60))
    XCTAssertFalse(TimerLogic.isWarningState(seconds: 61))
    XCTAssertFalse(TimerLogic.isWarningState(seconds: 300))
    XCTAssertFalse(TimerLogic.isWarningState(seconds: 3600))
  }

  func testIsWarningStateExactBoundary() {
    XCTAssertTrue(TimerLogic.isWarningState(seconds: 59.999))
    XCTAssertFalse(TimerLogic.isWarningState(seconds: 60.0))
  }
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `make test`
Expected: FAIL with "Use of unresolved identifier 'timerDisplayString'" and "'isWarningState'"

- [ ] **Step 4: Implement TimerLogic functions**

Add to `Timer/TimerLogic.swift` after line 124:

```swift
  // MARK: - Unified Display

  static func timerDisplayString(seconds: CGFloat) -> String {
    let minutes = Int(floor(seconds / 60))
    let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
    return String(format: "%02d:%02d", minutes, secs)
  }

  static func isWarningState(seconds: CGFloat) -> Bool {
    return seconds < 60
  }
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `make test`
Expected: All new tests PASS

- [ ] **Step 6: Commit TimerLogic functions**

```bash
git add Timer/TimerLogic.swift TimerTests/TimerTests.swift
git commit -m "Add unified timer display functions to TimerLogic

- timerDisplayString() formats seconds as MM:SS
- isWarningState() detects times under 1 minute
- Comprehensive test coverage for edge cases"
```

---

### Task 3: Replace Dual Labels with Single Timer Display Label

**Files:**
- Modify: `Timer/MVClockView.swift:6-7` (font constants)
- Modify: `Timer/MVClockView.swift:28-43` (label definitions)  
- Modify: `Timer/MVClockView.swift:45-47` (suffix width properties)

- [ ] **Step 1: Update font constant**

Replace in `Timer/MVClockView.swift` lines 6-7:

```swift
  private static let minutesFont = NSFont.monospacedDigitSystemFont(ofSize: 35, weight: .medium)
  private static let secondsFont = NSFont.monospacedDigitSystemFont(ofSize: 15, weight: .regular)
```

With:

```swift
  private static let timerDisplayFont = NSFont.monospacedDigitSystemFont(ofSize: 30, weight: .medium)
```

- [ ] **Step 2: Replace dual labels with single timer display label**

Replace in `Timer/MVClockView.swift` lines 28-43:

```swift
  private let minutesLabel: MVLabel = {
    let label = MVLabel(frame: NSRect(x: 0, y: 57, width: 150, height: 30))
    label.string = ""
    label.font = MVClockView.minutesFont
    label.alignment = .center
    label.textColor = NSColor(resource: .minutes)
    return label
  }()

  private let secondsLabel: MVLabel = {
    let label = MVLabel(frame: NSRect(x: 0, y: 38, width: 150, height: 20))
    label.font = MVClockView.secondsFont
    label.alignment = .center
    label.textColor = NSColor(resource: .seconds)
    return label
  }()
```

With:

```swift
  private let timerDisplayLabel: MVLabel = {
    let label = MVLabel(frame: NSRect(x: 0, y: 57, width: 150, height: 25))
    label.string = ""
    label.font = MVClockView.timerDisplayFont
    label.alignment = .center
    label.textColor = NSColor(resource: .minutes)
    return label
  }()
```

- [ ] **Step 3: Remove suffix width properties**

Remove in `Timer/MVClockView.swift` lines 45-47:

```swift
  private let minutesLabelSuffixWidth = "'".size(withAttributes: [.font: MVClockView.minutesFont]).width
  private let minutesLabelSecondsSuffixWidth = "\"".size(withAttributes: [.font: MVClockView.minutesFont]).width
  private let secondsSuffixWidth = "'".size(withAttributes: [.font: MVClockView.secondsFont]).width
```

- [ ] **Step 4: Build to verify no syntax errors**

Run: `make build`
Expected: Build succeeds (some undefined references expected, will fix in next task)

- [ ] **Step 5: Commit label replacement**

```bash
git add Timer/MVClockView.swift
git commit -m "Replace dual timer labels with unified display label

- Single timerDisplayLabel with 30pt font
- Remove minutesLabel and secondsLabel
- Remove suffix width calculation properties"
```

---

### Task 4: Update Label Usage and Layout Logic

**Files:**
- Modify: `Timer/MVClockView.swift:124-126` (addSubview calls)
- Modify: `Timer/MVClockView.swift:248-264` (updateLabels method)

- [ ] **Step 1: Update addSubview calls**

Replace in `Timer/MVClockView.swift` lines 124-126:

```swift
    self.addSubview(self.timerTimeLabel)
    self.addSubview(self.minutesLabel)
    self.addSubview(self.secondsLabel)
```

With:

```swift
    self.addSubview(self.timerTimeLabel)
    self.addSubview(self.timerDisplayLabel)
```

- [ ] **Step 2: Replace updateLabels method implementation**

Replace in `Timer/MVClockView.swift` lines 248-264:

```swift
  private func updateLabels() {
    self.minutesLabel.string = TimerLogic.minutesDisplayString(seconds: self.seconds)
    let suffixWidth: CGFloat = self.seconds < 60 ? self.minutesLabelSecondsSuffixWidth : self.minutesLabelSuffixWidth
    self.minutesLabel.sizeToFit()

    var frame = self.minutesLabel.frame
    frame.origin.x = round((self.bounds.width - (frame.size.width - suffixWidth)) / 2)
    self.minutesLabel.frame = frame

    self.secondsLabel.string = TimerLogic.secondsDisplayString(seconds: self.seconds)
    if self.seconds >= 60 {
      self.secondsLabel.sizeToFit()

      frame = self.secondsLabel.frame
      frame.origin.x = round((self.bounds.width - (frame.size.width - self.secondsSuffixWidth)) / 2)
      self.secondsLabel.frame = frame
    }
  }
```

With:

```swift
  private func updateLabels() {
    self.timerDisplayLabel.string = TimerLogic.timerDisplayString(seconds: self.seconds)
    self.timerDisplayLabel.textColor = TimerLogic.isWarningState(seconds: self.seconds) 
      ? NSColor(resource: .timerWarning) 
      : NSColor(resource: .minutes)
    self.timerDisplayLabel.sizeToFit()
    
    var frame = self.timerDisplayLabel.frame
    frame.origin.x = round((self.bounds.width - frame.size.width) / 2)
    self.timerDisplayLabel.frame = frame
  }
```

- [ ] **Step 3: Build to verify implementation**

Run: `make build`
Expected: Build succeeds with no errors

- [ ] **Step 4: Run tests to verify functionality**

Run: `make test`
Expected: All tests PASS

- [ ] **Step 5: Commit layout logic updates**

```bash
git add Timer/MVClockView.swift
git commit -m "Update timer display layout and coloring logic

- Use unified timerDisplayString() format
- Add dynamic color switching for warning state
- Simplified centering logic for single label"
```

---

### Task 5: Manual UI Testing and Verification

**Files:**
- Test: Built Timer.app

- [ ] **Step 1: Build and launch app**

Run: `make`
Expected: App launches with new MM:SS timer display format

- [ ] **Step 2: Test normal state display**

1. Set timer to 5 minutes (drag arrow or type "5")
2. Verify display shows "05:00" in normal color
3. Start timer and verify countdown shows "04:59", "04:58", etc.

Expected: Unified MM:SS format with normal color

- [ ] **Step 3: Test warning state transition**

1. Set timer to 1 minute and 30 seconds  
2. Start timer and let it count down
3. Watch transition at 1:00 → 0:59

Expected: Color changes to light orange at 0:59

- [ ] **Step 4: Test very short timers**

1. Set timer to 30 seconds
2. Verify shows "00:30" in light orange
3. Start and verify countdown "00:29", "00:28", etc.

Expected: Light orange color throughout countdown

- [ ] **Step 5: Test dock badge unchanged**

1. Start a timer
2. Check dock badge format
3. Verify it still shows MM:SS format as before

Expected: Dock badge behavior unchanged

- [ ] **Step 6: Commit UI testing verification**

```bash
git commit --allow-empty -m "Verify unified timer display UI behavior

Manual testing confirms:
- MM:SS format displays correctly
- Color changes to orange under 1 minute  
- Dock badge format unchanged
- Timer functionality preserved"
```

---

### Task 6: Deprecate Old Functions (Future Cleanup)

**Files:**
- Modify: `Timer/TimerLogic.swift:32-44` (add deprecation warnings)

- [ ] **Step 1: Add deprecation warnings to old functions**

Replace in `Timer/TimerLogic.swift` lines 32-44:

```swift
  static func minutesDisplayString(seconds: CGFloat) -> String {
    if seconds < 60 {
      return "\(Int(seconds))\""
    }
    return "\(Int(floor(seconds / 60)))'"
  }

  static func secondsDisplayString(seconds: CGFloat) -> String {
    if seconds < 60 {
      return ""
    }
    return "\(Int(seconds.truncatingRemainder(dividingBy: 60)))\""
  }
```

With:

```swift
  @available(*, deprecated, message: "Use timerDisplayString() instead for unified MM:SS format")
  static func minutesDisplayString(seconds: CGFloat) -> String {
    if seconds < 60 {
      return "\(Int(seconds))\""
    }
    return "\(Int(floor(seconds / 60)))'"
  }

  @available(*, deprecated, message: "Use timerDisplayString() instead for unified MM:SS format")
  static func secondsDisplayString(seconds: CGFloat) -> String {
    if seconds < 60 {
      return ""
    }
    return "\(Int(seconds.truncatingRemainder(dividingBy: 60)))\""
  }
```

- [ ] **Step 2: Build to verify deprecation warnings appear for tests**

Run: `make build`
Expected: Build succeeds, deprecation warnings may appear for test usage

- [ ] **Step 3: Run full test suite**

Run: `make test`
Expected: All tests PASS (existing tests still use deprecated functions but work)

- [ ] **Step 4: Commit deprecation markers**

```bash
git add Timer/TimerLogic.swift
git commit -m "Mark old display functions as deprecated

- minutesDisplayString() and secondsDisplayString() deprecated
- Point developers to unified timerDisplayString() function
- Functions remain for backward compatibility"
```

---

### Task 7: Final Integration Testing

**Files:**
- Test: Complete Timer.app functionality

- [ ] **Step 1: Run complete test suite**

Run: `make test && make uitest`
Expected: All unit and UI tests PASS

- [ ] **Step 2: Test input methods work with new display**

1. Test keyboard input (type numbers)
2. Test arrow dragging to set time
3. Test various timer durations

Expected: All input methods work, new display updates correctly

- [ ] **Step 3: Test timer completion behavior**

1. Set 10-second timer
2. Let it count down to 0:00
3. Verify notification and sound work

Expected: Timer completion behavior unchanged

- [ ] **Step 4: Test multiple windows**

1. Create new timer window (Cmd+N) 
2. Set different times in each window
3. Verify each shows correct format and colors

Expected: Multi-window behavior preserved

- [ ] **Step 5: Final commit**

```bash
git commit --allow-empty -m "Complete unified timer display implementation

Feature complete:
✅ Unified MM:SS format replaces separate labels  
✅ 30pt monospaced font for consistent sizing
✅ Light orange warning color for times < 1 minute
✅ All existing functionality preserved
✅ Comprehensive test coverage"
```

---

## Self-Review

**Spec Coverage Check:**
- ✅ Unified Display Format: Task 2 (timerDisplayString) + Task 4 (integration)
- ✅ Consistent Font Size: Task 3 (30pt timerDisplayFont)
- ✅ Warning State: Task 1 (color asset) + Task 2 (isWarningState) + Task 4 (color logic)
- ✅ Instant Color Change: Task 4 (direct textColor assignment)
- ✅ Preserve Normal Color: Task 4 (existing .minutes color for normal state)
- ✅ Testing Requirements: Task 2 (unit tests) + Task 5 & 7 (UI testing)
- ✅ Cleanup: Task 6 (deprecation markers)

**Type Consistency Check:**
- `timerDisplayString(seconds: CGFloat) -> String` - consistent usage
- `isWarningState(seconds: CGFloat) -> Bool` - consistent usage  
- `timerDisplayLabel: MVLabel` - consistent property name
- Color assets `.timerWarning` and `.minutes` - consistent resource names

**No Placeholders:** All code blocks contain complete implementations, all commands specify exact expected outputs.