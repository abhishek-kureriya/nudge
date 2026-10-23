import XCTest

final class NudgeLifeUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    // MARK: - Tab Navigation

    func testTabBarExists() {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        XCTAssertTrue(tabBar.buttons["Today"].exists)
        XCTAssertTrue(tabBar.buttons["Upcoming"].exists)
        XCTAssertTrue(tabBar.buttons["Life"].exists)
        XCTAssertTrue(tabBar.buttons["Done"].exists)
        XCTAssertTrue(tabBar.buttons["Settings"].exists)
    }

    func testNavigateBetweenTabs() {
        let tabBar = app.tabBars.firstMatch

        tabBar.buttons["Upcoming"].tap()
        XCTAssertTrue(app.navigationBars["Upcoming"].waitForExistence(timeout: 3))

        tabBar.buttons["Life"].tap()
        XCTAssertTrue(app.navigationBars["Life"].waitForExistence(timeout: 3))

        tabBar.buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["Done"].waitForExistence(timeout: 3))

        tabBar.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))

        tabBar.buttons["Today"].tap()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 3))
    }

    // MARK: - Add Item Sheet

    func testAddButtonPresentsSheet() {
        // The + button should exist on the Today tab
        let addButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        // The sheet should show "New Item" title and both options
        XCTAssertTrue(app.staticTexts["Reminder"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Life Item"].exists)
    }
}
