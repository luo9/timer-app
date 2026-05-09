import XCTest

final class TimerSimpleUITests: TimerUITestCase {
  func testInitialStateShowsZero() {
    let label = app.staticTexts["00:00"]
    XCTAssertTrue(label.waitForExistence(timeout: 2))
  }

  func testDoubleClickOpensMenu() {
    let window = app.windows.firstMatch
    window.doubleClick()
    XCTAssertTrue(app.menuItems["1:00"].waitForExistence(timeout: 2))
  }

  func testSelectPresetStartsCountdown() {
    let window = app.windows.firstMatch
    window.doubleClick()
    app.menuItems["5:00"].click()
    let running = app.staticTexts.matching(
      NSPredicate(format: "label BEGINSWITH '04' OR label == '05:00'")
    ).firstMatch
    XCTAssertTrue(running.waitForExistence(timeout: 3))
  }

  func testDoubleClickPausesRunningTimer() {
    let window = app.windows.firstMatch
    window.doubleClick()
    app.menuItems["5:00"].click()
    sleep(2)
    window.doubleClick()
    let displayAfterPause = app.staticTexts.firstMatch.label
    sleep(2)
    XCTAssertEqual(
      app.staticTexts.firstMatch.label,
      displayAfterPause,
      "Display should not change while paused"
    )
  }

  func testDoubleClickResumesFromPause() {
    let window = app.windows.firstMatch
    window.doubleClick()
    app.menuItems["5:00"].click()
    sleep(2)
    window.doubleClick()
    let pausedValue = app.staticTexts.firstMatch.label
    window.doubleClick()
    sleep(2)
    XCTAssertNotEqual(
      app.staticTexts.firstMatch.label,
      pausedValue,
      "Timer should resume counting down"
    )
  }
}
