import Foundation
import Combine

class ChatListViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let chatService: ChatServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    var userId: String
    
    init(chatService: ChatServiceProtocol, userId: String) {
        self.chatService = chatService
        self.userId = userId
        loadChats()
    }
    
    func loadChats() {
        isLoading = true
        chatService.loadChats(for: userId) { [weak self] chats in
            guard let self = self else { return }
            self.chats = chats
            self.isLoading = false
        }
    }
    
    func stopListening() {
        chatService.stopListening()
    }
} 