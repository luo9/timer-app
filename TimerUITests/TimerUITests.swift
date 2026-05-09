import XCTest

// Interaction tests are in TimerSimpleUITests (TimerKeyboardInputTests.swift)
final class TimerUITests: TimerUITestCase {
  func testAppLaunches() {
    XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 3))
  }
}
