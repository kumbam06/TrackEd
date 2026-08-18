import Foundation

enum ChatModerationStore {
    private static let mutedKey = "mutedChatIds"
    private static let blockedKey = "blockedUserIds"
    
    static func isMuted(chatId: String) -> Bool {
        mutedChatIds.contains(chatId)
    }
    
    static func toggleMute(chatId: String) -> Bool {
        var ids = mutedChatIds
        if ids.contains(chatId) {
            ids.remove(chatId)
        } else {
            ids.insert(chatId)
        }
        UserDefaults.standard.set(Array(ids), forKey: mutedKey)
        return ids.contains(chatId)
    }
    
    static func isBlocked(userId: String) -> Bool {
        blockedUserIds.contains(userId)
    }
    
    static func block(userId: String) {
        var ids = blockedUserIds
        ids.insert(userId)
        UserDefaults.standard.set(Array(ids), forKey: blockedKey)
    }
    
    private static var mutedChatIds: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: mutedKey) ?? [])
    }
    
    private static var blockedUserIds: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: blockedKey) ?? [])
    }
}
