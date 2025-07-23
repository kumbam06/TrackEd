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
    @State private var showAskAI = false
    @Binding var isChatDetailActive: Bool
    @State private var incomingRequests: [DocumentSnapshot] = []
    @State private var isLoadingRequests = false
    
    // Batch preload user info for all chat participants (batched)
    private func preloadUserInfos(for chats: [Chat], myId: String) {
        let partnerIds = Set(chats.compactMap { $0.participants.first(where: { $0 != myId }) })
        let uncachedIds = partnerIds.filter { UserCache.shared.getUserInfo(uid: $0) == nil && userInfos[$0] == nil }
        guard !uncachedIds.isEmpty else { return }
        let db = Firestore.firestore()
        // Firestore allows up to 10 'in' values per query, so batch if needed
        let batchSize = 10
        let uncachedIdsArray = Array(uncachedIds)
        let batches = stride(from: 0, to: uncachedIdsArray.count, by: batchSize).map { Array(uncachedIdsArray[$0..<min($0+batchSize, uncachedIdsArray.count)]) }
        for batch in batches {
            db.collection("users").whereField(FieldPath.documentID(), in: batch).getDocuments { snapshot, error in
                guard let docs = snapshot?.documents else { return }
                for doc in docs {
                    let data = doc.data()
                    let uid = doc.documentID
                    let username = data["username"] as? String ?? "User"
                    let displayName = data["name"] as? String
                    let photoURL = data["photoURL"] as? String
                    UserCache.shared.setUserInfo(uid: uid, username: username, displayName: displayName, photoURL: photoURL)
                    DispatchQueue.main.async {
                        userInfos[uid] = (username, displayName, photoURL)
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
            .whereField("recipientId", isEqualTo: userId)
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
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            chatRequestsSection
            mainContentSection
        }
        .background(Color("appScreenBG"))
        .navigationBarHidden(true)
        .sheet(isPresented: $showNewChat) {
            NewChatView()
                .environmentObject(authViewModel)
        }
        .onAppear {
            loadIncomingRequests()
        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        HStack {
            Text("Chats")
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundColor(Color("appTextPrimary"))
                .kerning(1.5)
            Spacer()
            Button(action: { showNewChat = true }) {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundColor(Color("appPrimaryAccent"))
                    .padding(10)
                    .background(Color("appPrimaryAccent").opacity(0.08))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 8)
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
                        ChatRequestRowView(requestDoc: doc)
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
            LazyVStack(spacing: 0) {
                ForEach(viewModel.chats) { chat in
                    ChatRowView(
                        chat: chat,
                        userInfos: userInfos,
                        onTap: {
                            selectedChat = chat
                            navigateToChat = true
                        },
                        onDelete: {
                            deleteChat(chat)
                        }
                    )
                }
            }
            .padding(.bottom, 100) // Padding for tab bar
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
                    chatService.acceptChatRequest(from: fromUserId, to: authViewModel.user?.uid ?? "") { success in
                        isProcessing = false
                        // Optionally, show a toast or feedback
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
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 16) {
                let myId = authViewModel.user?.uid ?? ""
                let partnerId = chat.participants.first(where: { $0 != myId }) ?? ""
                let userInfo = userInfos[partnerId]
                
                if let userInfo = userInfo, let url = userInfo.2, let imageURL = URL(string: url) {
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
                } else {
                    Circle().fill(Color("appPrimaryAccent").opacity(0.12))
                        .frame(width: 48, height: 48)
                        .overlay(Image(systemName: "person.fill").foregroundColor(Color("appPrimaryAccent")))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(userInfo?.1 ?? userInfo?.0 ?? "...")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("appTextPrimary"))
                        .lineLimit(1)
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
            .padding(.horizontal, 18)
            .background(Color("appCardBG"))
            .cornerRadius(18)
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
