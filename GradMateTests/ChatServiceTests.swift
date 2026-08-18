import XCTest
@testable import GradMate

final class ChatModerationStoreTests: XCTestCase {
    func testMuteToggle() {
        let chatId = "test-chat-\(UUID().uuidString)"
        XCTAssertFalse(ChatModerationStore.isMuted(chatId: chatId))
        XCTAssertTrue(ChatModerationStore.toggleMute(chatId: chatId))
        XCTAssertTrue(ChatModerationStore.isMuted(chatId: chatId))
        XCTAssertFalse(ChatModerationStore.toggleMute(chatId: chatId))
        XCTAssertFalse(ChatModerationStore.isMuted(chatId: chatId))
    }
    
    func testBlockUser() {
        let userId = "user-\(UUID().uuidString)"
        XCTAssertFalse(ChatModerationStore.isBlocked(userId: userId))
        ChatModerationStore.block(userId: userId)
        XCTAssertTrue(ChatModerationStore.isBlocked(userId: userId))
    }
}
