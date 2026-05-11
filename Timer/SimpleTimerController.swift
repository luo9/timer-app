import AppKit

@MainActor
final class SimpleTimerController: NSWindowController {
  let timerView = SimpleTimerView(frame: NSRect(origin: .zero, size: SimpleTimerView.idealSize))

  private var notificationTasks: [Task<Void, Never>] = []
  private var statusItem: NSStatusItem?

  convenience init() {
    let window = SimpleWindow(size: SimpleTimerView.idealSize)
    self.init(window: window)

    window.contentView = self.timerView
    self.windowFrameAutosaveName = "SimpleTimerWindowFrame"
    window.makeKeyAndOrderFront(self)
    self.observeOcclusionState()
    self.observeSpaceChanges()
    self.setupStatusItem()
    self.timerView.onDisplayChanged = { [weak self] in self?.updateStatusItem() }
    self.updateStatusItem()
  }

  deinit {
    MainActor.assumeIsolated {
      self.notificationTasks.forEach { $0.cancel() }
      self.timerView.stop()
    }
  }

  private func setupStatusItem() {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    if let button = item.button {
      let image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Timer")
      image?.isTemplate = true
      button.image = image
    }
    item.menu = buildStatusMenu()
    statusItem = item
  }

  private static let toggleWindowMenuTag = 100
  private static let pauseResumeMenuTag = 101

  private func buildStatusMenu() -> NSMenu {
    let menu = NSMenu()
    menu.delegate = self

    let toggleItem = NSMenuItem(
      title: "隐藏计时窗口",
      action: #selector(toggleFloatWindow),
      keyEquivalent: ""
    )
    toggleItem.target = self
    toggleItem.tag = Self.toggleWindowMenuTag
    menu.addItem(toggleItem)

    let countUpItem = NSMenuItem(
      title: "启动正向计时",
      action: #selector(startCountingUp),
      keyEquivalent: ""
    )
    countUpItem.target = self
    menu.addItem(countUpItem)

    menu.addItem(.separator())

    let pauseItem = NSMenuItem(
      title: "暂停计时",
      action: #selector(togglePause),
      keyEquivalent: ""
    )
    pauseItem.target = self
    pauseItem.tag = Self.pauseResumeMenuTag
    menu.addItem(pauseItem)

    menu.addItem(.separator())

    for minutes in stride(from: 5, through: 30, by: 5) {
      let item = NSMenuItem(
        title: "倒计时\(minutes)分钟",
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
    return menu
  }

  @objc private func toggleFloatWindow() {
    guard let window else { return }
    if window.isVisible {
      window.orderOut(nil)
    } else {
      window.orderFrontRegardless()
    }
  }

  @objc private func startCountingUp() {
    timerView.startCountingUpFromZero()
  }

  @objc private func togglePause() {
    if timerView.timerTask != nil {
      timerView.paused = true
      timerView.stop()
    } else if timerView.paused, timerView.seconds > 0 {
      timerView.updateTimerTime()
      timerView.start()
    }
  }

  @objc private func selectPreset(_ sender: NSMenuItem) {
    timerView.startTimer(seconds: CGFloat(sender.tag))
  }

  private func updateStatusItem() {
    guard let button = statusItem?.button else { return }
    if timerView.isActive {
      let text = " " + TimerLogic.timerDisplayString(seconds: timerView.seconds)
      let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
      button.attributedTitle = NSAttributedString(string: text, attributes: [.font: font])
    } else {
      button.attributedTitle = NSAttributedString(string: "")
    }
  }

  // MARK: - Space / Occlusion observers

  private func observeSpaceChanges() {
    self.notificationTasks.append(
      Task { [weak self] in
        for await _ in NSWorkspace.shared.notificationCenter.notifications(
          named: NSWorkspace.activeSpaceDidChangeNotification
        ) {
          // Re-order immediately so the window is visible as soon as the Space
          // becomes active.
          self?.window?.orderFrontRegardless()
          // Full-screen transition animations take ~0.5 s and the entering app's
          // window can reset z-order after the notification fires.  A second
          // re-order after the animation settles ensures we stay on top.
          try? await Task.sleep(for: .milliseconds(600))
          self?.window?.orderFrontRegardless()
        }
      }
    )
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

extension SimpleTimerController: NSMenuDelegate {
  func menuWillOpen(_ menu: NSMenu) {
    if let toggleItem = menu.item(withTag: Self.toggleWindowMenuTag) {
      toggleItem.title = (window?.isVisible == true) ? "隐藏计时窗口" : "显示计时窗口"
    }
    if let pauseItem = menu.item(withTag: Self.pauseResumeMenuTag) {
      if timerView.timerTask != nil {
        pauseItem.title = "暂停计时"
        pauseItem.isEnabled = true
      } else if timerView.paused, timerView.seconds > 0 {
        pauseItem.title = "继续计时"
        pauseItem.isEnabled = true
      } else {
        pauseItem.title = "暂停计时"
        pauseItem.isEnabled = false
      }
    }
  }
}
