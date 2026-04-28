# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Timer is a macOS application that provides an elegant visual timer interface. The app features a circular clock design with draggable arrow control, sound notifications, dock integration, and multi-window support.

## Build & Development Commands

All development tasks are managed through the Makefile:

```bash
# Full build and launch cycle (default)
make

# Individual commands
make clean          # Clean build artifacts
make build          # Build app without signing
make open           # Launch Timer.app from build directory
make test           # Run unit tests (TimerTests scheme)
make uitest         # Run UI tests (TimerUITests scheme)
make lint           # Run SwiftLint
make analyze        # Run SwiftLint analyzer with compiler logs
make format         # Auto-fix SwiftLint issues
make install-cli    # Install timer CLI to /usr/local/bin
```

The project uses Xcode build system with code signing disabled for development builds (`CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO`).

## Architecture Overview

### Core Components

**AppDelegate**: Central coordinator managing:
- Multiple timer window instances (`MVTimerController` array)
- Dock badge display (only one timer shows in dock at a time)
- Notification authorization and handling
- Command-line/URL scheme timer commands (`timer://2:30?window=2`)
- Window-level management for "stays on top" functionality

**MVTimerController**: Per-window controller managing:
- Clock view instance and timer completion callbacks  
- Audio playback for alarm sounds (AVFoundation)
- Window positioning and frame autosave
- Dock menu integration

**MVClockView**: Main UI component containing:
- Circular progress visualization (`MVClockProgressView`)
- Draggable arrow control (`MVClockArrowView`) 
- Clock face background (`MVClockFaceView`)
- Time display labels (minutes/seconds with custom fonts)
- Timer state management and animations

### Key Architecture Patterns

**Timer Logic Separation**: `TimerLogic` enum contains pure functions for:
- Progress scale conversion (special scaling for timers ≤60min)
- Time formatting and display strings
- Keyboard input processing with digit/backspace handling
- Accessibility descriptions

**Async Task Management**: Modern Swift concurrency using:
- `Task` for timer countdown and current time updates
- `NotificationCenter.notifications()` async sequences for window events
- Proper task cancellation in `deinit` methods

**Multi-Window State**: Each window maintains independent timer state, but dock badge shows only the "active" timer (last interacted with).

## Testing Structure

**TimerTests**: Unit tests for `TimerLogic` pure functions
- Progress scale conversion validation
- Time formatting edge cases
- Keyboard input processing logic

**TimerUITests**: UI automation tests organized by functionality:
- `TimerKeyboardInputTests`: Digit entry and editing
- `TimerInteractionTests`: Click/drag behaviors  
- `TimerDockAndCompletionTests`: Dock integration and completion flows
- `TimerStateTransitionTests`: Timer state changes
- `TimerInputEdgeCaseTests`: Edge cases and validation

## Key Implementation Details

**Progress Scaling**: Timers ≤60 minutes use non-linear progress scaling to provide finer control for shorter durations (implemented in `TimerLogic.convertProgressToScale`).

**Time Input Formats**:
- `2:30` → 2 minutes 30 seconds (colon = literal minutes:seconds)
- `2.5` → 2.5 minutes = 2m30s (decimal = fractional minutes)
- Keyboard digits set minutes by default, decimal point switches to seconds mode

**Sound Management**: Three built-in alert sounds (`alert-sound.caf`, `alert-sound-2.caf`, `alert-sound-3.caf`) with user preference persistence.

**AppleScript Support**: Timer supports AppleScript automation via `TimerScriptCommand` and `Timer.sdef` definition file.

## Development Requirements

- macOS 14 (Sonoma) minimum target
- Xcode with Swift 6 support  
- SwiftLint (installed via `mise` or direct install)
- No external dependencies beyond system frameworks

## CI/CD

GitHub Actions workflow (`.github/workflows/swift.yml`) runs on `macos-26` runners:
- Clean, build, and test on every push/PR to main branch
- Uses same build flags as local development (no code signing)
- SwiftLint validation in separate workflow