//
//  TrackEdUITests.swift
//  TrackEdUITests
//
//  Created by Pradeep Reddy Kumbam on 10/06/2025.
//

import XCTest

final class TrackEdUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testTabBarNavigation() throws {
        let app = XCUIApplication()
        app.launch()
        
        let homeTab = app.buttons["Home"]
        XCTAssertTrue(homeTab.exists)
        homeTab.tap()
        
        let plannerTab = app.buttons["Planner"]
        XCTAssertTrue(plannerTab.exists)
        plannerTab.tap()
        
        let chatsTab = app.buttons["Chats"]
        XCTAssertTrue(chatsTab.exists)
        chatsTab.tap()
        
        let chatsText = app.staticTexts["Chats View"]
        XCTAssertTrue(chatsText.exists)
        
        let askAITab = app.buttons["Ask AI"]
        XCTAssertTrue(askAITab.exists)
        askAITab.tap()
        
        let profileTab = app.buttons["Profile"]
        XCTAssertTrue(profileTab.exists)
        profileTab.tap()
        
    }
    
    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
