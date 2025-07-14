import Foundation
import Combine

class ChatDetailViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let chatService: ChatServiceProtocol
    private let chatId: String
    private let userId: String
    
    // Simple in-memory cache for messages per chatId
    private static var messageCache: [String: [Message]] = [:] // chatId -> messages
    
    init(chatService: ChatServiceProtocol, chatId: String, userId: String) {
        self.chatService = chatService
        self.chatId = chatId
        self.userId = userId
        loadMessages()
    }
    
    /// Loads messages from cache if available, otherwise listens to Firebase. Use forceRefresh to ignore cache.
    func loadMessages(forceRefresh: Bool = false) {
        isLoading = true
        if !forceRefresh, let cached = ChatDetailViewModel.messageCache[chatId], !cached.isEmpty {
            self.messages = cached
            self.isLoading = false
            return
        }
        listenForMessages()
    }
    
    func listenForMessages() {
        isLoading = true
        chatService.listenForMessages(chatId: chatId) { [weak self] messages in
            guard let self = self else { return }
            self.messages = messages
            ChatDetailViewModel.messageCache[self.chatId] = messages
            self.isLoading = false
        }
    }
    
    func sendMessage(_ text: String) {
        chatService.sendMessage(chatId: chatId, text: text, senderId: userId) { [weak self] error in
            if let error = error {
                self?.error = error.localizedDescription
            }
        }
    }
    
    /// Clears the message cache for this chat (e.g., on manual refresh)
    func clearCache() {
        ChatDetailViewModel.messageCache[chatId] = nil
    }
    
    func stopListening() {
        chatService.stopListening()
    }
} 