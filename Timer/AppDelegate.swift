import AppKit
import UserNotifications

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
  private var controller: SimpleTimerController?

  override init() {
    super.init()
    UserDefaults.standard.register(defaults: [MVUserDefaultsKeys.staysOnTop: true])
  }

  func applicationDidFinishLaunching(_: Notification) {
    let controller = SimpleTimerController()
    self.controller = controller

    UNUserNotificationCenter.current().delegate = self
  }

  func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
    controller?.window?.makeKeyAndOrderFront(self)
    return true
  }

  nonisolated func userNotificationCenter(
    _: UNUserNotificationCenter,
    willPresent _: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound])
  }
}
