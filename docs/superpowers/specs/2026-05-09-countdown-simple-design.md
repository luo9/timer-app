# countdown-simple UI Design

**Branch:** `countdown-simple`  
**Date:** 2026-05-09

## Overview

Replace the circular clock UI with a minimal floating rectangle that shows a large `MM:SS` countdown. The only interaction is double-click: choose a preset time when idle, pause when running, resume when paused.

## Visual Design

- **Window:** Borderless, 260 × 72 pt, transparent background, system shadow, movable by background drag
- **View:** White fill, `cornerRadius = 14` on CALayer; no title bar, no standard buttons
- **Font:** `NSFont.monospacedDigitSystemFont(ofSize: 52, weight: .bold)`, center-aligned, fills the view
- **No icons:** No pause indicator, no progress ring

### Color states

| Condition | Color |
|-----------|-------|
| `seconds == 0` (startup or finished) | Red |
| Running or paused, `seconds >= 60` | Black |
| Running or paused, `0 < seconds < 60` | Orange |

## State Machine

```
idle      seconds=0, timerTask=nil, paused=false   → 00:00 red
running   timerTask exists                          → countdown, black/orange
paused    paused=true, timerTask=nil, seconds>0    → frozen display, black/orange
finished  seconds=0, timerTask=nil, paused=false   → 00:00 red (same as idle)
```

### Double-click transitions

| Current state | Action |
|---------------|--------|
| idle / finished | Show preset menu |
| running | → paused (cancel task, keep seconds) |
| paused | → running (resume countdown) |

### Preset menu

15 items: **1:00 through 15:00**. Tapping any item immediately starts the countdown.  
Separator, then **Quit** at the bottom.  
Positioned via `NSMenu.popUpContextMenu(_:with:for:)` at the click location.

### Single-click + drag

Moves the window. Handled entirely by `isMovableByWindowBackground = true` — no code needed.

### Timer completion

`seconds` reaches zero, task ends, state becomes `finished`. No sound, no notification.

## Architecture

### Deleted files (old circular UI)

- `MVClockView.swift`, `MVClockView+Behavior.swift`
- `MVClockProgressView.swift`, `MVClockArrowView.swift`, `MVClockFaceView.swift`
- `MVMainView.swift`, `MVWindow.swift`, `MVTimerController.swift`

### Retained files

- `TimerLogic.swift` — `timerDisplayString(_:)` and `isWarningState(_:)` reused directly
- `MVLabel.swift` — reused as the time label
- `MVUserDefaultsKeys.swift` — `staysOnTop` key retained
- `AppDelegate.swift` — simplified: single controller, no multi-window, no keyboard input, no AppleScript

### New files

| File | Responsibility |
|------|----------------|
| `SimpleTimerView.swift` | View rendering + state machine + countdown Task + double-click / menu interaction |
| `SimpleWindow.swift` | Borderless window init (size, transparency, shadow, drag) |
| `SimpleTimerController.swift` | `NSWindowController` subclass; holds `timerView`, manages window lifecycle and visibility callbacks |

### Dependency graph

```
AppDelegate
  └── SimpleTimerController
        ├── SimpleWindow
        └── SimpleTimerView
              └── TimerLogic, MVLabel
```

### Public interface of SimpleTimerView

Used by `AppDelegate` for URL scheme commands:

```swift
var seconds: CGFloat
var paused: Bool
func startTimer(seconds: CGFloat)
func start()
func stop()
func updateTimerTime()
```

## Out of Scope

- Sound / notifications on completion
- Multiple windows
- Keyboard digit input
- AppleScript / URL scheme (AppDelegate retains the parsing code but the simple view exposes the minimum needed to support it)
- Dock badge
- Stays-on-top preference UI — window always uses `NSWindow.Level.floating` (the existing default); no user toggle in this UI
