import Foundation
import Combine

class ChatListViewModel: ObservableObject, Equatable {
    @Published var chats: [Chat] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let chatService: ChatServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    var userId: String
    
    // Simple in-memory cache for chats
    private static var chatCache: [String: [Chat]] = [:] // userId -> chats
    
    init(chatService: ChatServiceProtocol, userId: String) {
        self.chatService = chatService
        self.userId = userId
        // Show cached chats immediately if available
        if let cached = ChatListViewModel.chatCache[userId], !cached.isEmpty {
            self.chats = cached
        }
        loadChats()
    }
    
    /// Loads chats from cache if available and non-empty, otherwise fetches from Firestore. Use forceRefresh to ignore cache.
    func loadChats(forceRefresh: Bool = false) {
        isLoading = true
        error = nil // Clear previous errors
        
        if userId.isEmpty {
            self.chats = []
            self.isLoading = false
            return
        }
        
        if !forceRefresh, let cached = ChatListViewModel.chatCache[userId], !cached.isEmpty {
            self.chats = cached
            self.isLoading = false
            return
        }
        
        chatService.loadChats(for: userId) { [weak self] chats, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.error = error.localizedDescription
                    // Don't clear existing chats on error
                } else {
                    self.chats = chats
                    // Only cache if chats is non-empty
                    if !chats.isEmpty {
                        ChatListViewModel.chatCache[self.userId] = chats
                    } else {
                        ChatListViewModel.chatCache[self.userId] = nil
                    }
                }
                self.isLoading = false
            }
        }
    }
    
    /// Clears the chat cache for this user (e.g., on logout or manual refresh)
    func clearCache() {
        ChatListViewModel.chatCache[userId] = nil
        chats = []
        error = nil
    }
    
    func stopListening() {
        chatService.stopListening()
    }
    
    // MARK: - Equatable
    static func == (lhs: ChatListViewModel, rhs: ChatListViewModel) -> Bool {
        return lhs.userId == rhs.userId && 
               lhs.isLoading == rhs.isLoading && 
               lhs.chats.count == rhs.chats.count
    }
} 
