import XCTest

class ChatUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSearchAndStartChat() throws {
        let app = XCUIApplication()
        app.launch()
        // Navigate to chat tab (assume tab bar exists)
        app.tabBars.buttons["Chat"].tap()
        // Tap new chat button (assume accessibility identifier is set)
        app.buttons["NewChatButton"].tap()
        // Enter username in search field
        let searchField = app.textFields["Search username..."]
        XCTAssertTrue(searchField.exists)
        searchField.tap()
        searchField.typeText("testuser")
        // Wait for suggestions
        let suggestion = app.staticTexts["@testuser"]
        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith: suggestion, handler: nil)
        waitForExpectations(timeout: 5)
        // Tap the suggestion
        suggestion.tap()
        // Optionally: verify chat screen appears
        let chatTitle = app.staticTexts["testuser"]
        expectation(for: exists, evaluatedWith: chatTitle, handler: nil)
        waitForExpectations(timeout: 5)
    }
} 