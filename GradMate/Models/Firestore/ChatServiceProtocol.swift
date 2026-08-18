import Foundation

struct Chat: Identifiable, Codable, Equatable {
    let id: String
    let participants: [String]
    let createdAt: Date
    let isGroup: Bool
    let name: String?
    let lastMessage: Message?
}

struct Message: Identifiable, Codable, Equatable {
    let id: String
    let senderId: String
    let text: String
    let timestamp: Date
}

protocol ChatServiceProtocol {
    func loadChats(for userId: String, completion: @escaping ([Chat], Error?) -> Void)
    func listenForMessages(chatId: String, onUpdate: @escaping ([Message]) -> Void)
    func sendMessage(chatId: String, text: String, senderId: String, completion: ((Error?) -> Void)?)
    func createChat(participants: [String], isGroup: Bool, name: String?, completion: @escaping (String?) -> Void)
    func clearMessages(chatId: String, completion: ((Error?) -> Void)?)
    func stopListening()
} 
