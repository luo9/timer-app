import AppKit

@MainActor
final class SimpleTimerView: NSView {
  private static let displayFont = NSFont.monospacedDigitSystemFont(ofSize: 44, weight: .bold)

  static let idealSize: NSSize = {
    let font = NSFont.monospacedDigitSystemFont(ofSize: 44, weight: .bold)
    let str = NSAttributedString(string: "00:00", attributes: [.font: font])
    let bounds = str.boundingRect(with: NSSize(width: 600, height: 200), options: [])
    return NSSize(width: ceil(bounds.width) + 32, height: ceil(bounds.height) + 16)
  }()

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

  private var isEditing = false
  private var inputBuffer: [Int] = []

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

  override var acceptsFirstResponder: Bool { true }

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
    let labelHeight = timeLabel.intrinsicContentSize.height
    let y = (bounds.height - labelHeight) / 2
    timeLabel.frame = NSRect(x: 0, y: y, width: bounds.width, height: labelHeight)
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
    enterEditMode()
  }

  override func rightMouseDown(with event: NSEvent) {
    if isEditing { cancelEdit() }
    showPresetMenu(event: event)
  }

  // MARK: - Edit Mode

  override func keyDown(with event: NSEvent) {
    guard isEditing else {
      super.keyDown(with: event)
      return
    }
    switch event.keyCode {
    case 36, 76:  // Return, numpad Enter
      commitEdit()
    case 53:  // Escape
      cancelEdit()
    case 51, 117:  // Delete, forward delete
      if !inputBuffer.isEmpty {
        inputBuffer.removeLast()
        updateDisplay()
      }
    default:
      if let char = event.characters?.first, let digit = Int(String(char)) {
        guard inputBuffer.count < 4 else { return }
        // tens-of-seconds slot: only 0–5 valid
        if inputBuffer.count == 2, digit > 5 { return }
        inputBuffer.append(digit)
        updateDisplay()
      }
    }
  }

  override func resignFirstResponder() -> Bool {
    if isEditing { finishEdit() }
    return super.resignFirstResponder()
  }

  private func enterEditMode() {
    stop()
    paused = false
    isEditing = true
    inputBuffer = []
    updateDisplay()
    window?.makeFirstResponder(self)
  }

  private func finishEdit() {
    isEditing = false
    let digits = inputBuffer + Array(repeating: 0, count: 4 - inputBuffer.count)
    let total = CGFloat(digits[0] * 10 + digits[1]) * 60 + CGFloat(digits[2] * 10 + digits[3])
    inputBuffer = []
    if total > 0 {
      startTimer(seconds: total)
    } else {
      seconds = 0
      updateDisplay()
    }
  }

  private func commitEdit() {
    finishEdit()
    window?.makeFirstResponder(nil)
  }

  private func cancelEdit() {
    isEditing = false
    inputBuffer = []
    updateDisplay()
    window?.makeFirstResponder(nil)
  }

  // MARK: - Preset Menu

  private func showPresetMenu(event: NSEvent) {
    let menu = NSMenu()
    for minutes in stride(from: 5, through: 30, by: 5) {
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
    if isEditing {
      showEditDisplay()
    } else {
      timeLabel.string = TimerLogic.timerDisplayString(seconds: seconds)
      if seconds <= 0 {
        timeLabel.textColor = .red
      } else if TimerLogic.isWarningState(seconds: seconds) {
        timeLabel.textColor = NSColor(red: 1.0, green: 0.5, blue: 0, alpha: 1)
      } else {
        timeLabel.textColor = .black
      }
    }
  }

  private func showEditDisplay() {
    let full = inputBuffer + Array(repeating: -1, count: 4 - inputBuffer.count)
    let typed = NSColor.systemBlue
    let placeholder = NSColor(white: 0.75, alpha: 1)
    let font = SimpleTimerView.displayFont
    let para = NSMutableParagraphStyle()
    para.alignment = .center

    let result = NSMutableAttributedString()
    func append(_ text: String, color: NSColor) {
      result.append(NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color]))
    }
    for i in 0..<4 {
      if i == 2 { append(":", color: placeholder) }
      let d = full[i]
      append(d >= 0 ? "\(d)" : "0", color: d >= 0 ? typed : placeholder)
    }
    result.addAttribute(.paragraphStyle, value: para, range: NSRange(location: 0, length: result.length))
    timeLabel.attributedStringValue = result
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
