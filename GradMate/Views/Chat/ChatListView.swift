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
    
    var body: some View {
        ZStack {
            Color("appScreenBG").ignoresSafeArea()
            VStack(spacing: 0) {
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
                
                if let viewModel = viewModel {
                    if let error = viewModel.error {
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
                    } else if viewModel.chats.isEmpty {
                        Spacer()
                        if authViewModel.user?.uid == nil {
                            // User is not logged in
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
                        } else {
                            EmptyChatListView()
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 18) {
                                ForEach(viewModel.chats) { chat in
                                    let myId = authViewModel.user?.uid ?? ""
                                    let partnerId = chat.participants.first(where: { $0 != myId }) ?? ""
                                    let userInfo = userInfos[partnerId] ?? UserCache.shared.getUserInfo(uid: partnerId)
                                    ChatRowView(
                                        chat: chat,
                                        myId: myId,
                                        userInfo: userInfo,
                                        timeAgo: timeAgo,
                                        onSelect: { 
                                            selectedChat = chat
                                            navigateToChat = true
                                        },
                                        onDelete: { deleteChat(chat) }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 24)
                        }
                        .bottomFadeMask(fadeHeight: 80)
                        .safeAreaInset(edge: .bottom) {
                            Spacer().frame(height: 80)
                        }
                        .refreshable {
                            viewModel.loadChats(forceRefresh: true)
                        }
                        .onAppear {
                            let myId = authViewModel.user?.uid ?? ""
                            preloadUserInfos(for: viewModel.chats, myId: myId)
                        }
                    }
                } else {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color("appPrimaryAccent")))
                        .scaleEffect(1.3)
                    Spacer()
                }
            }
            
            // Navigation to chat detail
            NavigationLink(
                destination: Group {
                    if let chat = selectedChat, let userId = authViewModel.user?.uid {
                        ChatDetailView(chat: chat, userId: userId, chatService: chatService)
                            .onDisappear {
                                selectedChat = nil
                                navigateToChat = false
                            }
                    }
                },
                isActive: $navigateToChat,
                label: { EmptyView() }
            )
            
            // Floating AskAI Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showAskAI = true }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color("appPrimaryAccent"), Color("appSecondaryAccent")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                                .shadow(color: Color("appPrimaryAccent").opacity(0.3), radius: 12, x: 0, y: 6)
                            
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showAskAI)
                    .padding(.trailing, 20)
                    .padding(.bottom, 100) // Position above tab bar
                }
            }
        }
        .sheet(isPresented: $showNewChat) {
            NewChatView(onChatCreated: { chat in
                selectedChat = chat
                navigateToChat = true
            })
        }
        .sheet(isPresented: $showAskAI) {
            AskAIView()
        }
        .onAppear {
            if viewModel == nil && !hasInitializedViewModel {
                hasInitializedViewModel = true
                if let userId = authViewModel.user?.uid {
                    viewModel = ChatListViewModel(chatService: chatService, userId: userId)
                } else {
                    viewModel = ChatListViewModel(chatService: chatService, userId: "")
                }
            }
        }
        .onChange(of: authViewModel.user?.uid) { newUid in
            if newUid == nil {
                viewModel?.clearCache()
            }
        }
    }
    
    func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
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
    let myId: String
    let userInfo: (String, String?, String?)?
    let timeAgo: (Date) -> String
    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .center, spacing: 16) {
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
                    Text(timeAgo(last.timestamp))
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
