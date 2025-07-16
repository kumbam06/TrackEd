import XCTest
@testable import GradMate

class ChatServiceTests: XCTestCase {
    var chatService: FirestoreChatService!

    override func setUpWithError() throws {
        chatService = FirestoreChatService()
        // Optionally: inject a mock Firestore instance here
    }

    override func tearDownWithError() throws {
        chatService = nil
    }

    func testLookupUserIdByUsername() throws {
        let expectation = self.expectation(description: "User lookup")
        chatService.lookupUserId(byUsername: "testuser") { userId in
            // This will fail unless you have a test user in Firestore
            // For real tests, use a mock or test Firestore instance
            XCTAssertNotNil(userId, "User ID should not be nil for existing username")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testCreateAndFetchChat() throws {
        let expectation = self.expectation(description: "Chat creation and fetch")
        let user1 = "user1"
        let user2 = "user2"
        chatService.createChat(participants: [user1, user2], isGroup: false, name: nil) { chatId in
            XCTAssertNotNil(chatId, "Chat ID should not be nil after creation")
            if let chatId = chatId {
                self.chatService.fetchChatById(chatId) { chat in
                    XCTAssertNotNil(chat, "Chat should be fetched after creation")
                    expectation.fulfill()
                }
            } else {
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }
} 