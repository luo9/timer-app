import AppKit

private final class MVCloseButton: NSButton {
  override init(frame: NSRect) {
    super.init(frame: frame)
    self.bezelStyle = .regularSquare
    self.isBordered = false
  }

  required init?(coder: NSCoder) { nil }

  override var isHighlighted: Bool {
    didSet { self.needsDisplay = true }
  }

  override func draw(_ dirtyRect: NSRect) {
    let size: CGFloat = 12
    let rect = NSRect(
      x: (self.bounds.width - size) / 2,
      y: (self.bounds.height - size) / 2,
      width: size,
      height: size
    )
    let circle = NSBezierPath(ovalIn: rect)

    if self.isHighlighted {
      NSColor(srgbRed: 0.75, green: 0.18, blue: 0.13, alpha: 1).setFill()
    } else {
      NSColor(srgbRed: 1.0, green: 0.37, blue: 0.34, alpha: 1).setFill()
    }
    circle.fill()

    if self.isMouseInside {
      NSColor(srgbRed: 0.55, green: 0.10, blue: 0.08, alpha: 0.6).setStroke()
      let crossSize: CGFloat = 5
      let cx = rect.midX
      let cy = rect.midY
      let cross = NSBezierPath()
      cross.move(to: NSPoint(x: cx - crossSize / 2, y: cy - crossSize / 2))
      cross.line(to: NSPoint(x: cx + crossSize / 2, y: cy + crossSize / 2))
      cross.move(to: NSPoint(x: cx + crossSize / 2, y: cy - crossSize / 2))
      cross.line(to: NSPoint(x: cx - crossSize / 2, y: cy + crossSize / 2))
      cross.lineWidth = 1.5
      cross.stroke()
    }
  }

  private var isMouseInside = false {
    didSet { self.needsDisplay = true }
  }

  override func mouseEntered(with event: NSEvent) { self.isMouseInside = true }
  override func mouseExited(with event: NSEvent) { self.isMouseInside = false }

  override func mouseUp(with event: NSEvent) {
    if self.bounds.contains(self.convert(event.locationInWindow, from: nil)) {
      NSApplication.shared.terminate(self)
    }
  }

  override func updateTrackingAreas() {
    super.updateTrackingAreas()
    self.trackingAreas.forEach { self.removeTrackingArea($0) }
    self.addTrackingArea(NSTrackingArea(
      rect: self.bounds,
      options: [.mouseEnteredAndExited, .activeAlways],
      owner: self,
      userInfo: nil
    ))
  }
}

final class MVWindow: NSWindow {
  convenience init(mainView: NSView) {
    let styleMask: NSWindow.StyleMask = [.closable, .titled]
    let size: CGFloat = 150.0
    let titleBarHeight = Self.frameRect(
      forContentRect: NSRect(x: 0, y: 0, width: size, height: size),
      styleMask: styleMask
    ).size.height - size

    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
    let windowFrame = NSRect(
      x: screenFrame.width / 2 - size / 2,
      y: screenFrame.height / 2 - size / 2,
      width: size,
      height: size - titleBarHeight
    )

    self.init(
      contentRect: windowFrame,
      styleMask: styleMask,
      backing: .buffered,
      defer: true
    )

    mainView.frame = NSRect(x: 0, y: 0, width: size, height: size)

    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true

    // Create a transparent titlebar accessory to overlay the window (to capture drag events)
    let titleBarController = MVTitlebarAccessoryViewController()
    titleBarController.view.frame = NSRect(x: 0, y: 0, width: size, height: windowFrame.size.height)
    self.addTitlebarAccessoryViewController(titleBarController)

    // Hide some of the default window buttons
    self.standardWindowButton(.miniaturizeButton)?.isHidden = true
    self.standardWindowButton(.zoomButton)?.isHidden = true

    // Adjust the close button
    if let closeButton = self.standardWindowButton(.closeButton) {
      var closeFrame = closeButton.frame
      closeFrame.origin.y -= 2
      closeButton.frame = closeFrame

      // Replace with always-active close button so it doesn't gray out on focus loss
      let alwaysActiveButton = MVCloseButton(frame: closeButton.frame)
      closeButton.superview?.replaceSubview(closeButton, with: alwaysActiveButton)

      // Add the main clock view as a sibling underneath the close button
      alwaysActiveButton.superview?.addSubview(mainView, positioned: .below, relativeTo: alwaysActiveButton)
    }
  }
}
