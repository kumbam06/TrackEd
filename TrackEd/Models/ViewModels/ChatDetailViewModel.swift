import Foundation
import Combine

class ChatDetailViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let chatService: ChatServiceProtocol
    private let chatId: String
    private let userId: String
    
    init(chatService: ChatServiceProtocol, chatId: String, userId: String) {
        self.chatService = chatService
        self.chatId = chatId
        self.userId = userId
        listenForMessages()
    }
    
    func listenForMessages() {
        isLoading = true
        chatService.listenForMessages(chatId: chatId) { [weak self] messages in
            guard let self = self else { return }
            self.messages = messages
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
    
    func stopListening() {
        chatService.stopListening()
    }
} 