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
