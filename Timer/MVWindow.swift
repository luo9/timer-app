import AppKit

final class MVWindow: NSWindow {
  convenience init(mainView: NSView) {
    let styleMask: NSWindow.StyleMask = [.closable, .titled]
    let size: CGFloat = 130.0
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

    // Hide all window buttons
    if let closeButton = self.standardWindowButton(.closeButton) {
      closeButton.isHidden = true
      closeButton.superview?.addSubview(mainView, positioned: .below, relativeTo: closeButton)
    }
    self.standardWindowButton(.miniaturizeButton)?.isHidden = true
    self.standardWindowButton(.zoomButton)?.isHidden = true
  }
}
