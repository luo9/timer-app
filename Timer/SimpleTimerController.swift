import AppKit

@MainActor
final class SimpleTimerController: NSWindowController {
  let timerView = SimpleTimerView(frame: NSRect(origin: .zero, size: SimpleTimerView.idealSize))

  private var notificationTasks: [Task<Void, Never>] = []

  convenience init() {
    let window = SimpleWindow(size: SimpleTimerView.idealSize)
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
