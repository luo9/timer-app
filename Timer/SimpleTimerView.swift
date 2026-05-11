import AppKit

@MainActor
final class SimpleTimerView: NSView {
  private static let displayFont = NSFont.monospacedSystemFont(ofSize: 29, weight: .bold)

  static let idealSize: NSSize = {
    let font = NSFont.monospacedSystemFont(ofSize: 29, weight: .bold)
    let str = NSAttributedString(string: "00:00", attributes: [.font: font])
    let bounds = str.boundingRect(with: NSSize(width: 600, height: 200), options: [])
    return NSSize(width: ceil(bounds.width) + 20, height: ceil(bounds.height) + 10)
  }()

  var onTimerComplete: (() -> Void)?
  var onDisplayChanged: (() -> Void)?

  var isActive: Bool { seconds > 0 || countingUp }

  var seconds: CGFloat = 0 {
    didSet { updateDisplay() }
  }

  var paused = false
  var timerTask: Task<Void, Never>?
  private var currentTimeTask: Task<Void, Never>?
  private var notificationTasks: [Task<Void, Never>] = []
  var timerTime: Date?
  var lastTimerSeconds: CGFloat?

  private var countingUp = false
  private var countUpStartTime: Date?
  private var pausedFromCountUp = false

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
    layer?.cornerRadius = 10
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
        if inputBuffer.count == 2, digit > 5 { return }  // tens-of-seconds: 0–5 only
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
    window?.makeKey()
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
    seconds = 0
    updateDisplay()
    window?.makeFirstResponder(nil)
  }

  // MARK: - Display

  private func updateDisplay() {
    if isEditing {
      showEditDisplay()
      return
    }
    timeLabel.string = TimerLogic.timerDisplayString(seconds: seconds)
    if paused {
      timeLabel.textColor = .systemGray
    } else if countingUp || seconds <= 0 {
      timeLabel.textColor = .red
    } else if TimerLogic.isWarningState(seconds: seconds) {
      timeLabel.textColor = NSColor(red: 1.0, green: 0.5, blue: 0, alpha: 1)
    } else {
      timeLabel.textColor = .black
    }
    onDisplayChanged?()
  }

  // Cursor `_` at inputBuffer.count (blue). Typed digits black. Untyped slots gray "0".
  private func showEditDisplay() {
    let cursorPos = inputBuffer.count
    let font = SimpleTimerView.displayFont
    let para = NSMutableParagraphStyle()
    para.alignment = .center

    let result = NSMutableAttributedString()
    func append(_ text: String, color: NSColor) {
      result.append(NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color]))
    }

    for i in 0..<4 {
      if i == 2 { append(":", color: NSColor(white: 0.75, alpha: 1)) }
      if i < cursorPos {
        append("\(inputBuffer[i])", color: .black)
      } else if i == cursorPos {
        append("_", color: .systemBlue)
      } else {
        append("0", color: NSColor(white: 0.75, alpha: 1))
      }
    }

    result.addAttribute(.paragraphStyle, value: para, range: NSRange(location: 0, length: result.length))
    timeLabel.attributedStringValue = result
  }

  // MARK: - Timer

  func startCountingUpFromZero() {
    paused = false
    stop()
    seconds = 0
    countingUp = true
    countUpStartTime = Date()
    timerTask = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(1), tolerance: .milliseconds(30))
        self?.tick()
      }
    }
    updateDisplay()
  }

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
    countingUp = false
    countUpStartTime = nil
    pausedFromCountUp = false
  }

  func pause() {
    guard timerTask != nil else { return }
    pausedFromCountUp = countingUp
    paused = true
    timerTask?.cancel()
    timerTask = nil
    countingUp = false
    countUpStartTime = nil
    updateDisplay()
  }

  func resume() {
    guard paused else { return }
    paused = false
    if pausedFromCountUp {
      pausedFromCountUp = false
      countingUp = true
      countUpStartTime = Date(timeIntervalSinceNow: -Double(seconds))
      timerTask = Task { [weak self] in
        while !Task.isCancelled {
          try? await Task.sleep(for: .seconds(1), tolerance: .milliseconds(30))
          self?.tick()
        }
      }
      updateDisplay()
    } else {
      pausedFromCountUp = false
      updateTimerTime()
      start()
      updateDisplay()
    }
  }

  private func tick() {
    guard !paused else { return }
    if countingUp {
      guard let countUpStartTime else { return }
      seconds = round(CGFloat(Date().timeIntervalSince(countUpStartTime)))
    } else {
      guard let timerTime else { return }
      seconds = max(0, round(CGFloat(timerTime.timeIntervalSinceNow)))
      if seconds <= 0 {
        stop()
        startCountUp()
      }
    }
  }

  private func startCountUp() {
    countingUp = true
    countUpStartTime = Date()
    timerTask = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(1), tolerance: .milliseconds(30))
        self?.tick()
      }
    }
    updateDisplay()
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
