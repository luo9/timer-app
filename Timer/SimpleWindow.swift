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
    self.collectionBehavior = [.managed, .fullScreenAuxiliary]
  }

  override var canBecomeKey: Bool { true }
}
