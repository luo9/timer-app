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
    self.observeSpaceChanges()
  }

  deinit {
    MainActor.assumeIsolated {
      self.notificationTasks.forEach { $0.cancel() }
      self.timerView.stop()
    }
  }

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
