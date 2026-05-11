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
    // kCGMaximumWindowLevel (2147483631) is the highest level the window system
    // exposes; it sits above screenSaver (1000) and may bypass full-screen Space
    // isolation that blocked lower levels.
    self.level = NSWindow.Level(rawValue: 2147483631)
    self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
  }

  override var canBecomeKey: Bool { true }
}
