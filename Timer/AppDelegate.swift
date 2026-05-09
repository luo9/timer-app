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

    let parsed = Self.parseLaunchArguments(CommandLine.arguments)
    if let command = parsed.command {
      self.handleTimerCommand(command)
    }
  }

  func application(_: NSApplication, open urls: [URL]) {
    guard let url = urls.first, url.scheme == "timer" else { return }
    var raw = url.absoluteString
      .replacingOccurrences(of: "timer://", with: "")
      .removingPercentEncoding ?? ""
    if let queryStart = raw.firstIndex(of: "?") {
      raw = String(raw[..<queryStart])
    }
    while raw.hasSuffix("/") { raw.removeLast() }
    self.handleTimerCommand(raw)
  }

  func handleTimerCommand(_ input: String) {
    guard let timerView = controller?.timerView else { return }
    switch input.lowercased() {
    case "stop":
      timerView.paused = false
      timerView.stop()

    case "reset":
      timerView.paused = false
      timerView.stop()
      timerView.seconds = 0
      timerView.updateTimerTime()

    case "pause":
      if timerView.timerTask != nil {
        timerView.paused = true
        timerView.stop()
      } else if timerView.paused, timerView.seconds > 0 {
        timerView.updateTimerTime()
        timerView.start()
      }

    default:
      guard let seconds = parseTimeInput(input), seconds > 0 else { return }
      timerView.startTimer(seconds: seconds)
    }
    controller?.window?.makeKeyAndOrderFront(nil)
    NSApplication.shared.activate(ignoringOtherApps: true)
  }

  static func parseLaunchArguments(_ args: [String]) -> (command: String?, window: Int?) {
    var command: String?
    var skip = false
    for idx in 1..<args.count {
      if skip { skip = false; continue }
      if args[idx] == "--window" {
        skip = true
      } else {
        command = args[idx]
      }
    }
    return (command, nil)
  }

  private static let maxTimerSeconds: CGFloat = 24 * 60 * 60

  private func parseTimeInput(_ input: String) -> CGFloat? {
    let seconds: CGFloat
    if input.contains(":") {
      let parts = input.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
      guard parts.count == 2,
            let minutes = Double(parts[0]),
            let secs = Double(parts[1]) else { return nil }
      seconds = CGFloat(minutes * 60 + secs)
    } else if let value = Double(input) {
      seconds = CGFloat(value * 60)
    } else {
      return nil
    }
    guard seconds.isFinite, seconds <= Self.maxTimerSeconds else { return nil }
    return seconds
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
