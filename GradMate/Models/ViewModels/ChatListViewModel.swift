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
        print("[DEBUG] ChatListViewModel - Initializing for userId: \(userId)")
        
        // Show cached chats immediately if available
        if let cached = ChatListViewModel.chatCache[userId], !cached.isEmpty {
            print("[DEBUG] ChatListViewModel - Loading \(cached.count) cached chats")
            self.chats = sortChatsByRecentActivity(cached)
        }
        
        // Start real-time listener immediately
        startRealTimeListener()
    }
    
    /// Starts real-time listener for chat updates
    private func startRealTimeListener() {
        print("[DEBUG] ChatListViewModel - Starting real-time listener")
        chatService.loadChats(for: userId) { [weak self] chats, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("[DEBUG] ChatListViewModel - Error loading chats: \(error.localizedDescription)")
                    self.error = error.localizedDescription
                    // Don't clear existing chats on error
                } else {
                    print("[DEBUG] ChatListViewModel - Received \(chats.count) chats from real-time listener")
                    let sortedChats = self.sortChatsByRecentActivity(chats)
                    self.chats = sortedChats
                    
                    // Update cache
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
    
    /// Sorts chats by most recent activity (last message or creation time)
    private func sortChatsByRecentActivity(_ chats: [Chat]) -> [Chat] {
        return chats.sorted { chat1, chat2 in
            let time1 = chat1.lastMessage?.timestamp ?? chat1.createdAt
            let time2 = chat2.lastMessage?.timestamp ?? chat2.createdAt
            return time1 > time2
        }
    }
    
    /// Loads chats from cache if available and non-empty, otherwise fetches from Firestore. Use forceRefresh to ignore cache.
    func loadChats(forceRefresh: Bool = false) {
        print("[DEBUG] ChatListViewModel - loadChats called, forceRefresh: \(forceRefresh)")
        isLoading = true
        error = nil // Clear previous errors
        
        if userId.isEmpty {
            print("[DEBUG] ChatListViewModel - No userId, clearing chats")
            self.chats = []
            self.isLoading = false
            return
        }
        
        if !forceRefresh, let cached = ChatListViewModel.chatCache[userId], !cached.isEmpty {
            print("[DEBUG] ChatListViewModel - Loading \(cached.count) chats from cache")
            self.chats = sortChatsByRecentActivity(cached)
            self.isLoading = false
            return
        }
        
        print("[DEBUG] ChatListViewModel - Loading chats from Firestore")
        chatService.loadChats(for: userId) { [weak self] chats, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("[DEBUG] ChatListViewModel - Error loading chats: \(error.localizedDescription)")
                    self.error = error.localizedDescription
                    // Don't clear existing chats on error
                } else {
                    print("[DEBUG] ChatListViewModel - Loaded \(chats.count) chats from Firestore")
                    let sortedChats = self.sortChatsByRecentActivity(chats)
                    self.chats = sortedChats
                    
                    // Update cache
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
        print("[DEBUG] ChatListViewModel - Clearing cache for userId: \(userId)")
        ChatListViewModel.chatCache[userId] = nil
        chats = []
        error = nil
    }
    
    func stopListening() {
        print("[DEBUG] ChatListViewModel - Stopping listeners")
        chatService.stopListening()
    }
    
    // MARK: - Equatable
    static func == (lhs: ChatListViewModel, rhs: ChatListViewModel) -> Bool {
        return lhs.userId == rhs.userId && 
               lhs.isLoading == rhs.isLoading && 
               lhs.chats.count == rhs.chats.count
    }
} 
