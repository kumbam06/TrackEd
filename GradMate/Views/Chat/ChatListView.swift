import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import SDWebImageSwiftUI

// Simple in-memory user info cache
class UserCache {
    static var shared = UserCache()
    private var cache: [String: (username: String, displayName: String?, photoURL: String?)] = [:]
    private let userDefaultsKey = "UserCacheData"
    
    init() {
        loadFromUserDefaults()
    }
    
    func getUserInfo(uid: String) -> (String, String?, String?)? {
        if let (username, displayName, photoURL) = cache[uid] {
            return (username, displayName, photoURL)
        }
        return nil
    }
    func setUserInfo(uid: String, username: String, displayName: String?, photoURL: String?) {
        cache[uid] = (username, displayName, photoURL)
        saveToUserDefaults()
    }
    
    private func saveToUserDefaults() {
        let dict = cache.mapValues { [ $0.0, $0.1 ?? "", $0.2 ?? "" ] }
        UserDefaults.standard.set(dict, forKey: userDefaultsKey)
    }
    
    private func loadFromUserDefaults() {
        guard let dict = UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: [String]] else { return }
        for (uid, arr) in dict {
            let username = arr.count > 0 ? arr[0] : "User"
            let displayName = arr.count > 1 ? (arr[1].isEmpty ? nil : arr[1]) : nil
            let photoURL = arr.count > 2 ? (arr[2].isEmpty ? nil : arr[2]) : nil
            cache[uid] = (username, displayName, photoURL)
        }
    }
}

struct ChatListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var chatService: FirestoreChatService
    @State private var viewModel: ChatListViewModel? = nil
    @State private var showNewChat = false
    @State private var selectedChat: Chat? = nil
    @State private var navigateToChat = false
    @State private var userInfos: [String: (username: String, displayName: String?, photoURL: String?)] = [:]
    @State private var hasInitializedViewModel = false
    @Binding var isChatDetailActive: Bool
    @State private var incomingRequests: [DocumentSnapshot] = []
    @State private var isLoadingRequests = false
    @State private var shouldRefreshChats = false
    @State private var userInfoUpdateTrigger = false
    @State private var searchText = ""
    
    // Batch preload user info for all chat participants (batched)
    private func preloadUserInfos(for chats: [Chat], myId: String) {
        let partnerIds = Set(chats.compactMap { $0.participants.first(where: { $0 != myId }) })
        print("[DEBUG] preloadUserInfos - partnerIds: \(partnerIds)")
        
        // First, load any cached data into userInfos
        for partnerId in partnerIds {
            if let cachedInfo = UserCache.shared.getUserInfo(uid: partnerId) {
                userInfos[partnerId] = cachedInfo
                print("[DEBUG] preloadUserInfos - Loaded cached info for \(partnerId): \(cachedInfo)")
            }
        }
        
        let uncachedIds = partnerIds.filter { UserCache.shared.getUserInfo(uid: $0) == nil && userInfos[$0] == nil }
        print("[DEBUG] preloadUserInfos - uncachedIds: \(uncachedIds)")
        guard !uncachedIds.isEmpty else { 
            print("[DEBUG] preloadUserInfos - No uncached IDs to load")
            return 
        }
        let db = Firestore.firestore()
        // Firestore allows up to 10 'in' values per query, so batch if needed
        let batchSize = 10
        let uncachedIdsArray = Array(uncachedIds)
        let batches = stride(from: 0, to: uncachedIdsArray.count, by: batchSize).map { Array(uncachedIdsArray[$0..<min($0+batchSize, uncachedIdsArray.count)]) }
        print("[DEBUG] preloadUserInfos - Loading \(uncachedIdsArray.count) users in \(batches.count) batches")
        for batch in batches {
            db.collection("users").whereField(FieldPath.documentID(), in: batch).getDocuments { snapshot, error in
                if let error = error {
                    print("[DEBUG] preloadUserInfos - Error loading users: \(error.localizedDescription)")
                    return
                }
                guard let docs = snapshot?.documents else { 
                    print("[DEBUG] preloadUserInfos - No documents returned")
                    return 
                }
                print("[DEBUG] preloadUserInfos - Loaded \(docs.count) user documents")
                for doc in docs {
                    let data = doc.data()
                    let uid = doc.documentID
                    let username = data["username"] as? String ?? "User"
                    let displayName = data["name"] as? String
                    let photoURL = data["photoURL"] as? String
                    print("[DEBUG] preloadUserInfos - User \(uid): username=\(username), displayName=\(displayName ?? "nil"), photoURL=\(photoURL ?? "nil")")
                    UserCache.shared.setUserInfo(uid: uid, username: username, displayName: displayName, photoURL: photoURL)
                    DispatchQueue.main.async {
                        userInfos[uid] = (username, displayName, photoURL)
                        print("[DEBUG] preloadUserInfos - Updated userInfos for \(uid)")
                        // Force UI update by toggling the trigger
                        userInfoUpdateTrigger.toggle()
                    }
                }
            }
        }
    }
    
    private func deleteChat(_ chat: Chat) {
        let db = Firestore.firestore()
        db.collection("chats").document(chat.id).delete { error in
            if let error = error {
                print("Failed to delete chat: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    viewModel?.chats.removeAll { $0.id == chat.id }
                }
            }
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func loadIncomingRequests() {
        guard let userId = authViewModel.user?.uid else { return }
        isLoadingRequests = true
        let db = Firestore.firestore()
        db.collection("chatRequests")
            .whereField("toUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { snapshot, error in
                DispatchQueue.main.async {
                    isLoadingRequests = false
                    if let error = error {
                        print("Error loading requests: \(error)")
                        return
                    }
                    incomingRequests = snapshot?.documents ?? []
                }
            }
    }
    
    private func loadChatById(chatId: String) {
        let db = Firestore.firestore()
        db.collection("chats").document(chatId).getDocument { document, error in
            if let error = error {
                print("[Push] Error loading chat: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data() else {
                print("[Push] Chat document not found")
                return
            }
            
            let participants = data["participants"] as? [String] ?? []
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            let isGroup = data["isGroup"] as? Bool ?? false
            let name = data["name"] as? String
            
            let lastMessageData = data["lastMessage"] as? [String: Any]
            let lastMessage: Message?
            if let lastMessageData = lastMessageData {
                let messageId = lastMessageData["id"] as? String ?? ""
                let senderId = lastMessageData["senderId"] as? String ?? ""
                let text = lastMessageData["text"] as? String ?? ""
                let timestamp = (lastMessageData["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                lastMessage = Message(id: messageId, senderId: senderId, text: text, timestamp: timestamp)
            } else {
                lastMessage = nil
            }
            
            let chat = Chat(
                id: chatId,
                participants: participants,
                createdAt: createdAt,
                isGroup: isGroup,
                name: name,
                lastMessage: lastMessage
            )
            
            DispatchQueue.main.async {
                self.selectedChat = chat
                self.navigateToChat = true
                self.isChatDetailActive = true
                // Add to viewModel chats if not already present
                if !(self.viewModel?.chats.contains { $0.id == chatId } ?? false) {
                    self.viewModel?.chats.insert(chat, at: 0)
                }
            }
        }
    }
    
    private func initializeViewModel() {
        guard let userId = authViewModel.user?.uid else {
            print("[DEBUG] ChatListView - No user ID available, clearing viewModel")
            viewModel = nil
            return
        }
        
        print("[DEBUG] ChatListView - Initializing viewModel for userId: \(userId)")
        
        // Only initialize if we don't have a viewModel or if the userId changed
        if viewModel == nil || viewModel?.userId != userId {
            print("[DEBUG] ChatListView - Creating new ChatListViewModel")
            viewModel = ChatListViewModel(chatService: chatService, userId: userId)
            hasInitializedViewModel = true
        } else {
            print("[DEBUG] ChatListView - ViewModel already exists for userId: \(userId)")
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                searchSection
                chatRequestsSection
                mainContentSection
            }
            .padding(.bottom, 100) // Padding for tab bar
        }
        .background(Color("appScreenBG"))
        .navigationTitle("Chats")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showNewChat = true }) {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundColor(Color("appPrimaryAccent"))
                }
            }
        }
        .sheet(isPresented: $showNewChat) {
            NewChatView()
                .environmentObject(authViewModel)
        }
                                .background(
                    NavigationLink(
                        destination: Group {
                            if let selectedChat = selectedChat {
                                ChatDetailView(
                                    chat: selectedChat,
                                    userId: authViewModel.user?.uid ?? "",
                                    chatService: chatService,
                                    isChatDetailActive: $isChatDetailActive
                                )
                                .environmentObject(authViewModel)
                                .environmentObject(chatService)
                            }
                        },
                        isActive: $navigateToChat
                    ) {
                        EmptyView()
                    }
                    .opacity(0)
                )
        .onAppear {
            loadIncomingRequests()
            initializeViewModel()
        }
        .onChange(of: authViewModel.user?.uid) { newValue in
            if newValue != nil {
                initializeViewModel()
            } else {
                viewModel = nil
            }
        }
        .onChange(of: shouldRefreshChats) { newValue in
            if newValue {
                print("[DEBUG] Refreshing chats due to accepted request")
                viewModel?.loadChats(forceRefresh: true)
                shouldRefreshChats = false
            }
        }
        .onChange(of: viewModel?.chats) { newValue in
            if let chats = newValue, let myId = authViewModel.user?.uid {
                print("[DEBUG] Chats changed, preloading user info for \(chats.count) chats")
                preloadUserInfos(for: chats, myId: myId)
            }
        }
        .onChange(of: navigateToChat) { newValue in
            if !newValue {
                // Reset selected chat when navigation is dismissed
                selectedChat = nil
                isChatDetailActive = false
            }
        }
        .onDisappear {
            print("[DEBUG] ChatListView disappearing, cleaning up listeners")
            viewModel?.stopListening()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToChat"))) { notification in
            if let chatId = notification.userInfo?["chatId"] as? String {
                print("[Push] Navigating to chat: \(chatId)")
                // Find the chat in the current list
                if let chat = viewModel?.chats.first(where: { $0.id == chatId }) {
                    selectedChat = chat
                    navigateToChat = true
                    isChatDetailActive = true
                } else {
                    // If chat not found in current list, try to load it
                    print("[Push] Chat not found in current list, attempting to load")
                    loadChatById(chatId: chatId)
                }
            }
        }
    }
    
    @ViewBuilder
    private var searchSection: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(Color("appTextSecondary"))
                TextField("Search chats...", text: $searchText)
                    .font(.body)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color("appCardBG"))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    @ViewBuilder
    private var chatRequestsSection: some View {
        if isLoadingRequests {
            HStack {
                ProgressView()
                Text("Loading requests...")
                    .font(.subheadline)
                    .foregroundColor(Color("appTextSecondary"))
            }
            .padding(.vertical, 8)
        } else if !incomingRequests.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Chat Requests")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color("appPrimaryAccent"))
                    .padding(.leading, 8)
                ForEach(incomingRequests, id: \.documentID) { doc in
                    ChatRequestRowView(requestDoc: doc, shouldRefreshChats: $shouldRefreshChats)
                        .environmentObject(authViewModel)
                        .environmentObject(chatService)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
    
    @ViewBuilder
    private var mainContentSection: some View {
        if let viewModel = viewModel {
            if let error = viewModel.error {
                errorView(error: error, viewModel: viewModel)
            } else if viewModel.chats.isEmpty {
                emptyStateView
            } else {
                chatListView(viewModel: viewModel)
            }
        } else {
            loadingView
        }
    }
    
    @ViewBuilder
    private func errorView(error: String, viewModel: ChatListViewModel) -> some View {
        Spacer()
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(Color("appError"))
            Text("Failed to load chats")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color("appTextPrimary"))
            Text(error)
                .font(.body)
                .foregroundColor(Color("appTextSecondary"))
            Button(action: { viewModel.loadChats(forceRefresh: true) }) {
                Text("Retry")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color("appPrimaryAccent"))
                    .cornerRadius(12)
            }
        }
        Spacer()
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        Spacer()
        if authViewModel.user?.uid == nil {
            loginRequiredView
        } else {
            EmptyChatListView()
        }
    }
    
    @ViewBuilder
    private var loginRequiredView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color("appPrimaryAccent").opacity(0.08))
                    .frame(width: 120, height: 120)
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .font(.system(size: 48))
                    .foregroundColor(Color("appPrimaryAccent"))
            }
            Text("Please Log In")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color("appTextPrimary"))
            Text("You need to be logged in to view your chats.")
                .font(.body)
                .foregroundColor(Color("appTextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 32)
    }
    
    @ViewBuilder
    private var loadingView: some View {
        Spacer()
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading chats...")
                .font(.subheadline)
                .foregroundColor(Color("appTextSecondary"))
        }
        Spacer()
    }
    
    @ViewBuilder
    private func chatListView(viewModel: ChatListViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredChats(viewModel.chats)) { chat in
                    ChatRowView(
                        chat: chat,
                        userInfos: userInfos,
                        onTap: {
                            print("[DEBUG] Chat tapped: \(chat.id)")
                            selectedChat = chat
                            navigateToChat = true
                            isChatDetailActive = true
                        },
                        onDelete: {
                            deleteChat(chat)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100) // Padding for tab bar
        }
    }
    
    private func filteredChats(_ chats: [Chat]) -> [Chat] {
        guard !searchText.isEmpty else { return chats }
        
        return chats.filter { chat in
            let myId = authViewModel.user?.uid ?? ""
            let partnerId = chat.participants.first(where: { $0 != myId }) ?? ""
            let userInfo = userInfos[partnerId]
            
            let displayName = userInfo?.1 ?? userInfo?.0 ?? ""
            let username = userInfo?.0 ?? ""
            
            return displayName.localizedCaseInsensitiveContains(searchText) ||
                   username.localizedCaseInsensitiveContains(searchText) ||
                   chat.lastMessage?.text.localizedCaseInsensitiveContains(searchText) == true
        }
    }
    


    private func fetchRequests() {
        guard let myId = authViewModel.user?.uid else { return }
        isLoadingRequests = true
        chatService.fetchIncomingChatRequests(for: myId) { docs in
            incomingRequests = docs
            isLoadingRequests = false
        }
    }

}

struct ChatRequestRowView: View {
    let requestDoc: DocumentSnapshot
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var chatService: FirestoreChatService
    @State private var isProcessing = false
    @State private var showSuccessMessage = false
    @Binding var shouldRefreshChats: Bool
    
    var body: some View {
        let data = requestDoc.data() ?? [:]
        let fromUserId = data["fromUserId"] as? String ?? ""
        let displayName = data["fromDisplayName"] as? String ?? "User"
        let username = data["fromUsername"] as? String ?? ""
        let photoURL = data["fromPhotoURL"] as? String
        
        HStack(spacing: 12) {
            if let url = photoURL, let imageURL = URL(string: url) {
                WebImage(url: imageURL)
                    .resizable()
                    .clipShape(Circle())
                    .frame(width: 36, height: 36)
            } else {
                Circle().fill(Color("appPrimaryAccent").opacity(0.12))
                    .frame(width: 36, height: 36)
                    .overlay(Image(systemName: "person.fill").foregroundColor(Color("appPrimaryAccent")))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("appTextPrimary"))
                Text("@\(username)")
                    .font(.caption2)
                    .foregroundColor(Color("appTextSecondary"))
            }
            Spacer()
            if isProcessing {
                ProgressView()
            } else {
                Button(action: {
                    isProcessing = true
                    print("[DEBUG] Accepting chat request from \(fromUserId)")
                    chatService.acceptChatRequest(from: fromUserId, to: authViewModel.user?.uid ?? "") { success in
                        DispatchQueue.main.async {
                            isProcessing = false
                            if success {
                                print("[DEBUG] Chat request accepted successfully")
                                showSuccessMessage = true
                                // Force refresh the chat list after a short delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    shouldRefreshChats = true
                                }
                            } else {
                                print("[DEBUG] Failed to accept chat request")
                            }
                        }
                    }
                }) {
                    Text("Accept")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color("appPrimaryAccent"))
                        .cornerRadius(8)
                }
                Button(action: {
                    isProcessing = true
                    chatService.declineChatRequest(from: fromUserId, to: authViewModel.user?.uid ?? "") { success in
                        isProcessing = false
                    }
                }) {
                    Text("Decline")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color("appError"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color("appError").opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color("appCardBG"))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
    }
}

struct EmptyChatListView: View {
    var body: some View {
        Spacer()
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color("appPrimaryAccent").opacity(0.08))
                    .frame(width: 120, height: 120)
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .shadow(color: Color("appPrimaryAccent").opacity(0.10), radius: 8, x: 0, y: 4)
            }
            Text("No Chats Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color("appTextPrimary"))
            Text("Start a conversation with your friends or classmates.")
                .font(.body)
                .foregroundColor(Color("appTextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 32)
        Spacer()
    }
}

// MARK: - Chat Row View
struct ChatRowView: View {
    let chat: Chat
    let userInfos: [String: (username: String, displayName: String?, photoURL: String?)]
    let onTap: () -> Void
    let onDelete: () -> Void
    @EnvironmentObject var authViewModel: AuthViewModel
    
    private func formatTimeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        
        // Safety check for invalid dates
        let now = Date()
        if date > now || date.timeIntervalSince1970 < 0 {
            return "now"
        }
        
        return formatter.localizedString(for: date, relativeTo: now)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 16) {
                let myId = authViewModel.user?.uid ?? ""
                let partnerId = chat.participants.first(where: { $0 != myId }) ?? ""
                let userInfo = userInfos[partnerId]
                
                if let userInfo = userInfo, let url = userInfo.2, !url.isEmpty, let imageURL = URL(string: url) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 48, height: 48)
                        WebImage(url: imageURL)
                            .resizable()
                            .indicator(.activity)
                            .clipShape(Circle())
                            .frame(width: 48, height: 48)
                    }
                    .onAppear {
                        print("[DEBUG] ChatRowView - Loading image for \(partnerId): \(url)")
                    }
                } else {
                    Circle().fill(Color("appPrimaryAccent").opacity(0.12))
                        .frame(width: 48, height: 48)
                        .overlay(Image(systemName: "person.fill").foregroundColor(Color("appPrimaryAccent")))
                        .onAppear {
                            print("[DEBUG] ChatRowView - No image URL for \(partnerId), userInfo: \(String(describing: userInfo))")
                        }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(userInfo?.1 ?? userInfo?.0 ?? "Loading...")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("appTextPrimary"))
                        .lineLimit(1)
                        .onAppear {
                            print("[DEBUG] ChatRowView - partnerId: \(partnerId)")
                            print("[DEBUG] ChatRowView - userInfo: \(String(describing: userInfo))")
                        }
                    if let last = chat.lastMessage {
                        Text("\(last.senderId == myId ? "You: " : "")\(last.text)")
                            .font(.subheadline)
                            .foregroundColor(Color("appTextSecondary"))
                            .lineLimit(1)
                    }
                }
                Spacer()
                if let last = chat.lastMessage {
                    Text(formatTimeAgo(last.timestamp))
                        .font(.caption)
                        .foregroundColor(Color("appTextSecondary"))
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(Color("appCardBG"))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
} 
