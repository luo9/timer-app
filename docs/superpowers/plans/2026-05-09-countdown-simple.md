# countdown-simple Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the circular clock timer UI with a minimal white rounded-rectangle floating window showing a large `MM:SS` countdown, operated by double-click.

**Architecture:** Delete 8 old UI files, create 3 new ones (`SimpleWindow`, `SimpleTimerView`, `SimpleTimerController`), simplify `AppDelegate` to single-window. Reuse `TimerLogic` and `MVLabel` unchanged. Update UITests to cover the new interaction model.

**Tech Stack:** Swift 6, AppKit, macOS 14+, `Timer.xcodeproj` (xcodebuild)

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| DELETE | `Timer/MVClockView.swift` | old circular clock |
| DELETE | `Timer/MVClockView+Behavior.swift` | old event handling |
| DELETE | `Timer/MVClockProgressView.swift` | old progress ring |
| DELETE | `Timer/MVClockArrowView.swift` | old drag arrow |
| DELETE | `Timer/MVClockFaceView.swift` | old clock face |
| DELETE | `Timer/MVMainView.swift` | old gradient background |
| DELETE | `Timer/MVWindow.swift` | old titled window |
| DELETE | `Timer/MVTimerController.swift` | old window controller |
| CREATE | `Timer/SimpleWindow.swift` | borderless window init |
| CREATE | `Timer/SimpleTimerView.swift` | view + state machine + timer tasks + double-click |
| CREATE | `Timer/SimpleTimerController.swift` | NSWindowController, owns timerView |
| MODIFY | `Timer/AppDelegate.swift` | simplified single-window app delegate |
| KEEP   | `Timer/TimerLogic.swift` | reused as-is |
| KEEP   | `Timer/MVLabel.swift` | reused as-is |
| KEEP   | `Timer/MVUserDefaultsKeys.swift` | reused as-is |
| REPLACE | `TimerUITests/TimerKeyboardInputTests.swift` | replaced with new double-click tests |
| DELETE | `TimerUITests/TimerInteractionTests.swift` | drag/arrow tests no longer relevant |
| DELETE | `TimerUITests/TimerDockAndCompletionTests.swift` | dock badge tests removed |
| DELETE | `TimerUITests/TimerStateTransitionTests.swift` | replaced by new tests |
| DELETE | `TimerUITests/TimerInputEdgeCaseTests.swift` | digit input removed |

---

## Known pbxproj UUIDs (old files to remove)

| File | PBXFileReference UUID | PBXBuildFile UUID |
|------|-----------------------|-------------------|
| MVWindow.swift | `4C30BC081CA7C81C00C45EBF` | `4C30BC091CA7C81C00C45EBF` |
| MVMainView.swift | `4C30BC0A1CA7C96700C45EBF` | `4C30BC0B1CA7C96700C45EBF` |
| MVClockView.swift | `4C30BC151CA7D94500C45EBF` | `4C30BC161CA7D94500C45EBF` |
| MVTimerController.swift | `4C6F0F2B1CACF4B500E9A6F7` | `4C6F0F2C1CACF4B500E9A6F7` |
| MVClockProgressView.swift | `AA000010AAAA001000000000` | `AA000010AAAA001000000001` |
| MVClockArrowView.swift | `AA000011AAAA001100000000` | `AA000011AAAA001100000001` |
| MVClockFaceView.swift | `AA000012AAAA001200000000` | `AA000012AAAA001200000001` |
| MVClockView+Behavior.swift | `CC000001CCCC000100000000` | `CC000001CCCC000100000001` |
| TimerInteractionTests.swift | `CC000012CCCC001200000000` | `CC000012CCCC001200000001` |
| TimerDockAndCompletionTests.swift | `CC000013CCCC001300000000` | `CC000013CCCC001300000001` |
| TimerStateTransitionTests.swift | `CC000014CCCC001400000000` | `CC000014CCCC001400000001` |
| TimerInputEdgeCaseTests.swift | `CC000015CCCC001500000000` | `CC000015CCCC001500000001` |

## Reserved pbxproj UUIDs (new files)

| File | PBXFileReference UUID | PBXBuildFile UUID |
|------|-----------------------|-------------------|
| SimpleWindow.swift | `DD000001DDDD000100000000` | `DD000001DDDD000100000001` |
| SimpleTimerView.swift | `DD000002DDDD000200000000` | `DD000002DDDD000200000001` |
| SimpleTimerController.swift | `DD000003DDDD000300000000` | `DD000003DDDD000300000001` |

---

## Task 1: Remove old UI source files from disk and pbxproj

**Files:**
- Delete: `Timer/MV{ClockView,ClockView+Behavior,ClockProgressView,ClockArrowView,ClockFaceView,MainView,Window,TimerController}.swift`
- Delete: `TimerUITests/Timer{InteractionTests,DockAndCompletionTests,StateTransitionTests,InputEdgeCaseTests}.swift`
- Modify: `Timer.xcodeproj/project.pbxproj`

- [ ] **Step 1: Remove source files from disk**

```bash
git rm Timer/MVClockView.swift \
       Timer/MVClockView+Behavior.swift \
       Timer/MVClockProgressView.swift \
       Timer/MVClockArrowView.swift \
       Timer/MVClockFaceView.swift \
       Timer/MVMainView.swift \
       Timer/MVWindow.swift \
       Timer/MVTimerController.swift \
       TimerUITests/TimerInteractionTests.swift \
       TimerUITests/TimerDockAndCompletionTests.swift \
       TimerUITests/TimerStateTransitionTests.swift \
       TimerUITests/TimerInputEdgeCaseTests.swift
```

- [ ] **Step 2: Remove all old-file UUIDs from pbxproj**

Every UUID listed in the "Known pbxproj UUIDs" table above appears on exactly one line in each of three locations: `PBXBuildFile` section, `PBXFileReference` section, and as a child reference in `PBXGroup` / `PBXSourcesBuildPhase`. Remove all lines containing any of these UUIDs from `Timer.xcodeproj/project.pbxproj`.

UUIDs to remove (all occurrences of each):
```
4C30BC081CA7C81C00C45EBF  4C30BC091CA7C81C00C45EBF
4C30BC0A1CA7C96700C45EBF  4C30BC0B1CA7C96700C45EBF
4C30BC151CA7D94500C45EBF  4C30BC161CA7D94500C45EBF
4C6F0F2B1CACF4B500E9A6F7  4C6F0F2C1CACF4B500E9A6F7
AA000010AAAA001000000000  AA000010AAAA001000000001
AA000011AAAA001100000000  AA000011AAAA001100000001
AA000012AAAA001200000000  AA000012AAAA001200000001
CC000001CCCC000100000000  CC000001CCCC000100000001
CC000012CCCC001200000000  CC000012CCCC001200000001
CC000013CCCC001300000000  CC000013CCCC001300000001
CC000014CCCC001400000000  CC000014CCCC001400000001
CC000015CCCC001500000000  CC000015CCCC001500000001
```

- [ ] **Step 3: Confirm deletion**

```bash
grep -c "MVClockView\|MVWindow\|MVTimerController\|MVMainView\|MVClockProgress\|MVClockArrow\|MVClockFace" Timer.xcodeproj/project.pbxproj
```

Expected output: `0`

- [ ] **Step 4: Commit**

```bash
git add Timer.xcodeproj/project.pbxproj
git commit -m "Remove old circular-clock UI files"
```

---

## Task 2: Create SimpleWindow.swift

**Files:**
- Create: `Timer/SimpleWindow.swift`
- Modify: `Timer.xcodeproj/project.pbxproj`

- [ ] **Step 1: Write the file**

`Timer/SimpleWindow.swift`:
```swift
import AppKit

final class SimpleWindow: NSWindow {
  convenience init(size: NSSize) {
    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
    let origin = NSPoint(
      x: (screenFrame.width - size.width) / 2,
      y: (screenFrame.height - size.height) / 2
    )
    self.init(
      contentRect: NSRect(origin: origin, size: size),
      styleMask: [.borderless, .fullSizeContentView],
      backing: .buffered,
      defer: true
    )
    self.backgroundColor = .clear
    self.isOpaque = false
    self.hasShadow = true
    self.isMovableByWindowBackground = true
    self.level = .floating
  }
}
```

- [ ] **Step 2: Add to pbxproj — PBXFileReference section**

Find the line: `/* End PBXFileReference section */`

Insert immediately before it:
```
		DD000001DDDD000100000000 /* SimpleWindow.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SimpleWindow.swift; sourceTree = "<group>"; };
```

- [ ] **Step 3: Add to pbxproj — PBXBuildFile section**

Find the line: `/* End PBXBuildFile section */`

Insert immediately before it:
```
		DD000001DDDD000100000001 /* SimpleWindow.swift in Sources */ = {isa = PBXBuildFile; fileRef = DD000001DDDD000100000000 /* SimpleWindow.swift */; };
```

- [ ] **Step 4: Add to pbxproj — PBXGroup children (Timer source group)**

Find the line: `4C30BBFB1CA7C56500C45EBF /* AppDelegate.swift */,`

Insert immediately after it:
```
				DD000001DDDD000100000000 /* SimpleWindow.swift */,
```

- [ ] **Step 5: Add to pbxproj — PBXSourcesBuildPhase**

Find the line: `4C30BBFC1CA7C56500C45EBF /* AppDelegate.swift in Sources */,`

Insert immediately after it:
```
				DD000001DDDD000100000001 /* SimpleWindow.swift in Sources */,
```

- [ ] **Step 6: Verify build still fails predictably**

```bash
make build 2>&1 | grep "error:" | head -5
```

Expected: errors about `MVTimerController` / `SimpleTimerView` not found (correct — AppDelegate still references them).

---

## Task 3: Create SimpleTimerView.swift

**Files:**
- Create: `Timer/SimpleTimerView.swift`
- Modify: `Timer.xcodeproj/project.pbxproj`

- [ ] **Step 1: Write the file**

`Timer/SimpleTimerView.swift`:
```swift
import AppKit

final class SimpleTimerView: NSView {
  private static let displayFont = NSFont.monospacedDigitSystemFont(ofSize: 52, weight: .bold)

  var onTimerComplete: (() -> Void)?

  var seconds: CGFloat = 0 {
    didSet { updateDisplay() }
  }

  var paused = false
  var timerTask: Task<Void, Never>?
  private var currentTimeTask: Task<Void, Never>?
  private var notificationTasks: [Task<Void, Never>] = []
  var timerTime: Date?
  var lastTimerSeconds: CGFloat?

  var windowIsVisible = false {
    didSet {
      if windowIsVisible {
        startClockTimer()
        updateDisplay()
      } else {
        stopClockTimer()
      }
    }
  }

  private let timeLabel: MVLabel = {
    let label = MVLabel(frame: .zero)
    label.font = SimpleTimerView.displayFont
    label.alignment = .center
    label.string = "00:00"
    label.textColor = .red
    return label
  }()

  override init(frame: NSRect) {
    super.init(frame: frame)
    wantsLayer = true
    layer?.backgroundColor = NSColor.white.cgColor
    layer?.cornerRadius = 14
    addSubview(timeLabel)
  }

  required init?(coder: NSCoder) { fatalError() }

  override func layout() {
    super.layout()
    timeLabel.frame = bounds
  }

  deinit {
    MainActor.assumeIsolated {
      notificationTasks.forEach { $0.cancel() }
      timerTask?.cancel()
      currentTimeTask?.cancel()
    }
  }

  // MARK: - Interaction

  override func mouseUp(with event: NSEvent) {
    guard event.clickCount >= 2 else { return }
    handleDoubleClick(event: event)
  }

  private func handleDoubleClick(event: NSEvent) {
    if timerTask != nil {
      paused = true
      stop()
    } else if paused, seconds > 0 {
      updateTimerTime()
      start()
    } else {
      showPresetMenu(event: event)
    }
  }

  private func showPresetMenu(event: NSEvent) {
    let menu = NSMenu()
    for minutes in 1...15 {
      let item = NSMenuItem(
        title: String(format: "%d:00", minutes),
        action: #selector(selectPreset(_:)),
        keyEquivalent: ""
      )
      item.tag = minutes * 60
      item.target = self
      menu.addItem(item)
    }
    menu.addItem(.separator())
    menu.addItem(NSMenuItem(
      title: "Quit",
      action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: ""
    ))
    NSMenu.popUpContextMenu(menu, with: event, for: self)
  }

  @objc private func selectPreset(_ sender: NSMenuItem) {
    startTimer(seconds: CGFloat(sender.tag))
  }

  // MARK: - Display

  private func updateDisplay() {
    timeLabel.string = TimerLogic.timerDisplayString(seconds: seconds)
    if seconds <= 0 {
      timeLabel.textColor = .red
    } else if TimerLogic.isWarningState(seconds: seconds) {
      timeLabel.textColor = NSColor(red: 1.0, green: 0.5, blue: 0, alpha: 1)
    } else {
      timeLabel.textColor = .black
    }
  }

  // MARK: - Timer

  func startTimer(seconds: CGFloat) {
    paused = false
    stop()
    self.seconds = seconds
    updateTimerTime()
    start()
  }

  func start() {
    guard seconds > 0 else { return }
    lastTimerSeconds = seconds
    paused = false
    stop()
    timerTask = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(1), tolerance: .milliseconds(30))
        self?.tick()
      }
    }
  }

  func stop() {
    timerTask?.cancel()
    timerTask = nil
  }

  private func tick() {
    guard let timerTime else { return }
    seconds = max(0, round(CGFloat(timerTime.timeIntervalSinceNow)))
    if seconds <= 0 {
      stop()
      onTimerComplete?()
    }
  }

  func updateTimerTime() {
    timerTime = Date(timeIntervalSinceNow: Double(seconds))
  }

  func startClockTimer() {
    guard currentTimeTask == nil else { return }
    if timerTask == nil { timerTime = Date() }
    currentTimeTask = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(1), tolerance: .milliseconds(500))
        self?.maintainCurrentTime()
      }
    }
  }

  func stopClockTimer() {
    currentTimeTask?.cancel()
    currentTimeTask = nil
  }

  private func maintainCurrentTime() {
    guard timerTask == nil else { return }
    let time = Date()
    if Calendar.current.component(.second, from: time) == 0 {
      timerTime = time
    }
  }
}
```

- [ ] **Step 2: Add to pbxproj — PBXFileReference section**

Find: `/* End PBXFileReference section */`

Insert immediately before it:
```
		DD000002DDDD000200000000 /* SimpleTimerView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SimpleTimerView.swift; sourceTree = "<group>"; };
```

- [ ] **Step 3: Add to pbxproj — PBXBuildFile section**

Find: `/* End PBXBuildFile section */`

Insert immediately before it:
```
		DD000002DDDD000200000001 /* SimpleTimerView.swift in Sources */ = {isa = PBXBuildFile; fileRef = DD000002DDDD000200000000 /* SimpleTimerView.swift */; };
```

- [ ] **Step 4: Add to pbxproj — PBXGroup children**

Find: `DD000001DDDD000100000000 /* SimpleWindow.swift */,`

Insert immediately after it:
```
				DD000002DDDD000200000000 /* SimpleTimerView.swift */,
```

- [ ] **Step 5: Add to pbxproj — PBXSourcesBuildPhase**

Find: `DD000001DDDD000100000001 /* SimpleWindow.swift in Sources */,`

Insert immediately after it:
```
				DD000002DDDD000200000001 /* SimpleTimerView.swift in Sources */,
```

---

## Task 4: Create SimpleTimerController.swift

**Files:**
- Create: `Timer/SimpleTimerController.swift`
- Modify: `Timer.xcodeproj/project.pbxproj`

- [ ] **Step 1: Write the file**

`Timer/SimpleTimerController.swift`:
```swift
import AppKit

final class SimpleTimerController: NSWindowController {
  let timerView = SimpleTimerView(frame: NSRect(x: 0, y: 0, width: 260, height: 72))

  private var notificationTasks: [Task<Void, Never>] = []

  convenience init() {
    let window = SimpleWindow(size: NSSize(width: 260, height: 72))
    self.init(window: window)

    window.contentView = self.timerView
    self.windowFrameAutosaveName = "SimpleTimerWindowFrame"
    window.makeKeyAndOrderFront(self)
    self.observeOcclusionState()
  }

  deinit {
    MainActor.assumeIsolated {
      self.notificationTasks.forEach { $0.cancel() }
      self.timerView.stop()
    }
  }

  private func observeOcclusionState() {
    self.notificationTasks.append(
      Task { [weak self] in
        for await notification in NotificationCenter.default.notifications(
          named: NSWindow.didChangeOcclusionStateNotification
        ) {
          guard let window = notification.object as? NSWindow,
                window === self?.window else { continue }
          self?.timerView.windowIsVisible = window.occlusionState.contains(.visible)
        }
      }
    )
  }
}
```

- [ ] **Step 2: Add to pbxproj — PBXFileReference section**

Find: `/* End PBXFileReference section */`

Insert immediately before it:
```
		DD000003DDDD000300000000 /* SimpleTimerController.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SimpleTimerController.swift; sourceTree = "<group>"; };
```

- [ ] **Step 3: Add to pbxproj — PBXBuildFile section**

Find: `/* End PBXBuildFile section */`

Insert immediately before it:
```
		DD000003DDDD000300000001 /* SimpleTimerController.swift in Sources */ = {isa = PBXBuildFile; fileRef = DD000003DDDD000300000000 /* SimpleTimerController.swift */; };
```

- [ ] **Step 4: Add to pbxproj — PBXGroup children**

Find: `DD000002DDDD000200000000 /* SimpleTimerView.swift */,`

Insert immediately after it:
```
				DD000003DDDD000300000000 /* SimpleTimerController.swift */,
```

- [ ] **Step 5: Add to pbxproj — PBXSourcesBuildPhase**

Find: `DD000002DDDD000200000001 /* SimpleTimerView.swift in Sources */,`

Insert immediately after it:
```
				DD000003DDDD000300000001 /* SimpleTimerController.swift in Sources */,
```

---

## Task 5: Rewrite AppDelegate.swift

**Files:**
- Modify: `Timer/AppDelegate.swift`

- [ ] **Step 1: Replace the entire file content**

`Timer/AppDelegate.swift`:
```swift
import AppKit
import UserNotifications

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
  private var controller: SimpleTimerController?

  override init() {
    super.init()
    UserDefaults.standard.register(defaults: [MVUserDefaultsKeys.staysOnTop: true])
  }

  func applicationDidFinishLaunching(_: Notification) {
    let controller = SimpleTimerController()
    self.controller = controller

    UNUserNotificationCenter.current().delegate = self

    let parsed = Self.parseLaunchArguments(CommandLine.arguments)
    if let command = parsed.command {
      self.handleTimerCommand(command)
    }
  }

  func application(_: NSApplication, open urls: [URL]) {
    guard let url = urls.first, url.scheme == "timer" else { return }
    var raw = url.absoluteString
      .replacingOccurrences(of: "timer://", with: "")
      .removingPercentEncoding ?? ""
    if let queryStart = raw.firstIndex(of: "?") {
      raw = String(raw[..<queryStart])
    }
    while raw.hasSuffix("/") { raw.removeLast() }
    self.handleTimerCommand(raw)
  }

  func handleTimerCommand(_ input: String) {
    guard let timerView = controller?.timerView else { return }
    switch input.lowercased() {
    case "stop":
      timerView.paused = false
      timerView.stop()

    case "reset":
      timerView.paused = false
      timerView.stop()
      timerView.seconds = 0
      timerView.updateTimerTime()

    case "pause":
      if timerView.timerTask != nil {
        timerView.paused = true
        timerView.stop()
      } else if timerView.paused, timerView.seconds > 0 {
        timerView.updateTimerTime()
        timerView.start()
      }

    default:
      guard let seconds = parseTimeInput(input), seconds > 0 else { return }
      timerView.startTimer(seconds: seconds)
    }
    controller?.window?.makeKeyAndOrderFront(nil)
    NSApplication.shared.activate(ignoringOtherApps: true)
  }

  static func parseLaunchArguments(_ args: [String]) -> (command: String?, window: Int?) {
    var command: String?
    var skip = false
    for idx in 1..<args.count {
      if skip { skip = false; continue }
      if args[idx] == "--window" {
        skip = true
      } else {
        command = args[idx]
      }
    }
    return (command, nil)
  }

  private static let maxTimerSeconds: CGFloat = 24 * 60 * 60

  private func parseTimeInput(_ input: String) -> CGFloat? {
    let seconds: CGFloat
    if input.contains(":") {
      let parts = input.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
      guard parts.count == 2,
            let minutes = Double(parts[0]),
            let secs = Double(parts[1]) else { return nil }
      seconds = CGFloat(minutes * 60 + secs)
    } else if let value = Double(input) {
      seconds = CGFloat(value * 60)
    } else {
      return nil
    }
    guard seconds.isFinite, seconds <= Self.maxTimerSeconds else { return nil }
    return seconds
  }

  func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
    controller?.window?.makeKeyAndOrderFront(self)
    return true
  }

  nonisolated func userNotificationCenter(
    _: UNUserNotificationCenter,
    willPresent _: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound])
  }
}
```

- [ ] **Step 2: Build — expect success**

```bash
make build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

If there are Swift 6 concurrency errors about `timerTask` being accessed from non-isolated contexts, add `@MainActor` to `SimpleTimerView` class declaration.

- [ ] **Step 3: Commit**

```bash
git add Timer/SimpleWindow.swift Timer/SimpleTimerView.swift \
        Timer/SimpleTimerController.swift Timer/AppDelegate.swift \
        Timer.xcodeproj/project.pbxproj
git commit -m "Add SimpleTimerView, SimpleWindow, SimpleTimerController; simplify AppDelegate"
```

---

## Task 6: Update UITests

**Files:**
- Modify: `TimerUITests/TimerKeyboardInputTests.swift` (repurpose as simple UI tests)
- Modify: `TimerUITests/TimerUITests.swift` (clear or keep as smoke test)

- [ ] **Step 1: Replace TimerKeyboardInputTests.swift with new double-click tests**

`TimerUITests/TimerKeyboardInputTests.swift`:
```swift
import XCTest

final class TimerSimpleUITests: TimerUITestCase {
  func testInitialStateShowsZero() {
    let label = app.staticTexts["00:00"]
    XCTAssertTrue(label.waitForExistence(timeout: 2))
  }

  func testDoubleClickOpensMenu() {
    let window = app.windows.firstMatch
    window.doubleClick()
    XCTAssertTrue(app.menuItems["1:00"].waitForExistence(timeout: 2))
  }

  func testSelectPresetStartsCountdown() {
    let window = app.windows.firstMatch
    window.doubleClick()
    app.menuItems["5:00"].click()
    // After selecting 5:00 the display should show 04:59 or 05:00 within 3s
    let running = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH '04' OR label == '05:00'")).firstMatch
    XCTAssertTrue(running.waitForExistence(timeout: 3))
  }

  func testDoubleClickPausesRunningTimer() {
    // Start a 5-minute timer
    let window = app.windows.firstMatch
    window.doubleClick()
    app.menuItems["5:00"].click()
    // Let it tick once
    sleep(2)
    // Double-click to pause — display should stop changing
    window.doubleClick()
    let displayAfterPause = app.staticTexts.firstMatch.label
    sleep(2)
    XCTAssertEqual(app.staticTexts.firstMatch.label, displayAfterPause, "Display should not change while paused")
  }

  func testDoubleClickResumesFromPause() {
    // Start then pause
    let window = app.windows.firstMatch
    window.doubleClick()
    app.menuItems["5:00"].click()
    sleep(2)
    window.doubleClick() // pause
    let pausedValue = app.staticTexts.firstMatch.label
    // Resume
    window.doubleClick()
    sleep(2)
    XCTAssertNotEqual(app.staticTexts.firstMatch.label, pausedValue, "Timer should resume counting down")
  }
}
```

- [ ] **Step 2: Clear the old TimerUITests.swift smoke test (keep file for project structure)**

`TimerUITests/TimerUITests.swift`:
```swift
import XCTest

// Smoke tests are in TimerSimpleUITests.swift
final class TimerUITests: TimerUITestCase {
  func testAppLaunches() {
    XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 3))
  }
}
```

- [ ] **Step 3: Run unit tests (TimerLogic tests must still pass)**

```bash
make test 2>&1 | tail -10
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add TimerUITests/TimerKeyboardInputTests.swift TimerUITests/TimerUITests.swift
git commit -m "Replace UITests with simple double-click interaction tests"
```

---

## Task 7: Visual Verification

- [ ] **Step 1: Launch the app**

```bash
make open
```

- [ ] **Step 2: Verify initial state**
- Window appears as a white floating pill (260 × 72 pt) with rounded corners and shadow
- Displays `00:00` in large bold monospaced red font
- No title bar, no traffic-light buttons

- [ ] **Step 3: Verify double-click menu**
- Double-click the window → a menu appears with items `1:00` through `15:00` and `Quit`
- Click `5:00` → timer starts counting down from `05:00`
- Color is black while ≥ 1 minute remains

- [ ] **Step 4: Verify orange state**
- Start a `1:00` timer → observe color change to orange when display reaches `00:59`

- [ ] **Step 5: Verify pause / resume**
- While running, double-click → countdown freezes (color unchanged, no ⏸ icon)
- Double-click again → countdown resumes

- [ ] **Step 6: Verify finished state**
- Start a `1:00` timer, wait for it to reach `00:00` → display shows `00:00` in red
- Double-click → preset menu appears again (same as initial state)

- [ ] **Step 7: Verify drag to move**
- Single-click and drag → window moves on screen

- [ ] **Step 8: Final commit**

```bash
git add -A
git status  # confirm no untracked files worth committing
git commit -m "countdown-simple: complete minimal rectangular timer UI" --allow-empty
```

Push:
```bash
git push origin countdown-simple
```
