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
        loadChats()
    }
    
    /// Loads chats from cache if available, otherwise fetches from Firestore. Use forceRefresh to ignore cache.
    func loadChats(forceRefresh: Bool = false) {
        isLoading = true
        print("[DEBUG] ChatListViewModel.loadChats() called for userId: \(userId), forceRefresh: \(forceRefresh)")
        if userId.isEmpty {
            print("[DEBUG] No userId provided, skipping chat load.")
            self.chats = []
            self.isLoading = false
            return
        }
        if !forceRefresh, let cached = ChatListViewModel.chatCache[userId], !cached.isEmpty {
            print("[DEBUG] Using cached chats for userId: \(userId)")
            self.chats = cached
            self.isLoading = false
            return
        }
        chatService.loadChats(for: userId) { [weak self] chats, error in
            guard let self = self else { return }
            print("[DEBUG] loadChats completion: error=\(String(describing: error)), chatCount=\(chats.count)")
            DispatchQueue.main.async {
                self.chats = chats
                ChatListViewModel.chatCache[self.userId] = chats
                if let error = error {
                    self.error = error.localizedDescription
                    print("[DEBUG] Error loading chats: \(error.localizedDescription)")
                }
                self.isLoading = false
                print("[DEBUG] ChatListViewModel - isLoading set to false, chatCount: \(self.chats.count)")
            }
        }
    }
    
    /// Clears the chat cache for this user (e.g., on logout or manual refresh)
    func clearCache() {
        ChatListViewModel.chatCache[userId] = nil
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
