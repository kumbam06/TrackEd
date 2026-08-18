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
            DispatchQueue.main.async {
                guard let self = self else { return }
                print("[DEBUG] ChatDetailViewModel - Received \(messages.count) messages for chat \(self.chatId)")
                self.messages = messages
                ChatDetailViewModel.messageCache[self.chatId] = messages
                self.isLoading = false
                self.error = nil
            }
        }
    }
    
    func sendMessage(_ text: String) {
        print("[DEBUG] ChatDetailViewModel - Sending message: \(text)")
        chatService.sendMessage(chatId: chatId, text: text, senderId: userId) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[DEBUG] ChatDetailViewModel - Error sending message: \(error.localizedDescription)")
                    self?.error = error.localizedDescription
                } else {
                    print("[DEBUG] ChatDetailViewModel - Message sent successfully")
                    print("[DEBUG] ChatDetailViewModel - This should trigger chat list update")
                    self?.error = nil
                    
                    // Force a small delay to ensure the message is processed
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        print("[DEBUG] ChatDetailViewModel - Message processing completed")
                    }
                }
            }
        }
    }
    
    func clearMessages() {
        chatService.clearMessages(chatId: chatId) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.error = error.localizedDescription
                } else {
                    self?.messages = []
                    self?.clearCache()
                }
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