import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import SDWebImageSwiftUI

struct UserSuggestion: Identifiable {
    let id: String // UID
    let username: String
    let displayName: String?
    var photoURL: String?
}

struct NewChatView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var chatService: FirestoreChatService
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var searchText = ""
    @State private var suggestions: [UserSuggestion] = []
    @State private var isLoadingSuggestions = false
    @State private var isLoading = false
    @State private var error: String?
    @State private var showErrorAlert = false
    @State private var createdChat: Chat? = nil
    @FocusState private var isSearchFocused: Bool
    @State private var sentRequests: [UserSuggestion] = []
    var onChatCreated: ((Chat) -> Void)? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("appScreenBG").ignoresSafeArea()
                VStack(spacing: 28) {
                    // Top bar with close button and title
                    ZStack {
                        HStack {
                            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundColor(Color("appPrimaryAccent"))
                                    .padding(10)
                                    .background(Color("appPrimaryAccent").opacity(0.08))
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                        Text("Start New Chat")
                            .font(.title2)
                            .fontWeight(.heavy)
                            .foregroundColor(Color("appTextPrimary"))
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 8)
                    // Sent Requests List (move to top)
                    if !sentRequests.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sent Requests")
                                .font(.headline)
                                .foregroundColor(Color("appPrimaryAccent"))
                                .padding(.leading, 8)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(sentRequests) { user in
                                        HStack(spacing: 8) {
                                            if let url = user.photoURL, let imageURL = URL(string: url) {
                                                WebImage(url: imageURL)
                                                    .resizable()
                                                    .indicator(.activity)
                                                    .clipShape(Circle())
                                                    .frame(width: 36, height: 36)
                                            } else {
                                                Circle().fill(Color("appPrimaryAccent").opacity(0.12)).frame(width: 36, height: 36)
                                                    .overlay(Image(systemName: "person.fill").foregroundColor(Color("appPrimaryAccent")))
                                            }
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(user.displayName ?? user.username)
                                                    .font(.subheadline)
                                                    .foregroundColor(Color("appTextPrimary"))
                                                Text("@\(user.username)")
                                                    .font(.caption2)
                                                    .foregroundColor(Color("appTextSecondary"))
                                            }
                                        }
                                        .padding(8)
                                        .background(Color("appCardBG"))
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
                                    }
                                }
                                .padding(.horizontal, 8)
                            }
                        }
                        .padding(.bottom, 12)
                        .padding(.top, 8)
                    }
                    // Search bar and rest of UI follows
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color("appPrimaryAccent"))
                        TextField("Search username...", text: $searchText)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color("appTextPrimary"))
                            .onChange(of: searchText) { oldValue, newValue in
                                fetchUserSuggestions(for: newValue)
                            }
                            .focused($isSearchFocused)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color("appCardBG"))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                    .padding(.horizontal, 8)
                    
                    if isLoadingSuggestions {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color("appPrimaryAccent")))
                                .scaleEffect(0.8)
                            Text("Searching...")
                                .font(.subheadline)
                                .foregroundColor(Color("appTextSecondary"))
                        }
                        .padding(.vertical, 8)
                    }
                    
                    if suggestions.isEmpty && !searchText.isEmpty && !isLoadingSuggestions {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(Color("appTextSecondary").opacity(0.5))
                            Text("No users found")
                                .font(.headline)
                                .foregroundColor(Color("appTextSecondary"))
                            Text("Try searching with a different username")
                                .font(.subheadline)
                                .foregroundColor(Color("appTextSecondary").opacity(0.7))
                        }
                        .padding(.vertical, 32)
                    }
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(suggestions.filter { suggestion in !sentRequests.contains(where: { $0.id == suggestion.id }) }) { user in
                                UserRequestRow(user: user)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                    }
                    .frame(maxHeight: 320)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                .alert(isPresented: $showErrorAlert) {
                    Alert(
                        title: Text("Error"),
                        message: Text(error ?? "Unknown error"),
                        dismissButton: .default(Text("OK")) {
                            error = nil
                        }
                    )
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSearchFocused = true
                }
                fetchSentRequests()
            }
        }
    }
    
    func fetchUserSuggestions(for input: String) {
        guard !input.isEmpty else {
            suggestions = []
            return
        }
        isLoadingSuggestions = true
        let db = Firestore.firestore()
        let lowerInput = input.lowercased()
        var results: [UserSuggestion] = []
        let group = DispatchGroup()
        // Username prefix search
        group.enter()
        db.collection("users")
            .order(by: "username")
            .start(at: [lowerInput])
            .end(at: [lowerInput + "\u{f8ff}"])
            .limit(to: 20)
            .getDocuments { snapshot, error in
                if let docs = snapshot?.documents {
                    results.append(contentsOf: docs.compactMap { doc in
                        let data = doc.data()
                        let uid = doc.documentID
                        let username = data["username"] as? String ?? ""
                        let displayName = data["name"] as? String
                        if uid == authViewModel.user?.uid { return nil }
                        if username.lowercased().hasPrefix(lowerInput) {
                            return UserSuggestion(
                                id: uid,
                                username: username,
                                displayName: displayName,
                                photoURL: data["photoURL"] as? String
                            )
                        }
                        return nil
                    })
                }
                group.leave()
            }
        // Name prefix search
        group.enter()
        db.collection("users")
            .order(by: "name")
            .start(at: [lowerInput])
            .end(at: [lowerInput + "\u{f8ff}"])
            .limit(to: 20)
            .getDocuments { snapshot, error in
                if let docs = snapshot?.documents {
                    results.append(contentsOf: docs.compactMap { doc in
                        let data = doc.data()
                        let uid = doc.documentID
                        let username = data["username"] as? String ?? ""
                        let displayName = data["name"] as? String
                        if uid == authViewModel.user?.uid { return nil }
                        if let displayName = displayName, displayName.lowercased().hasPrefix(lowerInput) {
                            return UserSuggestion(
                                id: uid,
                                username: username,
                                displayName: displayName,
                                photoURL: data["photoURL"] as? String
                            )
                        }
                        return nil
                    })
                }
                group.leave()
            }
        group.notify(queue: .main) {
            // Deduplicate by user id
            let unique = Dictionary(grouping: results, by: { $0.id }).compactMap { $0.value.first }
            suggestions = unique
            isLoadingSuggestions = false
        }
    }
    
    private func createChatWith(participantId: String) {
        guard let myId = authViewModel.user?.uid else { return }
        if participantId == myId {
            self.error = "You cannot start a chat with yourself."
            self.showErrorAlert = true
            return
        }
        isLoading = true
        // Check chat request status before proceeding
        chatService.checkChatRequestStatus(from: myId, to: participantId) { status in
            if status == "accepted" {
                // Only allow chat if request is accepted
                chatService.findDirectChat(between: myId, and: participantId) { existingChat in
                    DispatchQueue.main.async {
                        if let chat = existingChat {
                            isLoading = false
                            onChatCreated?(chat)
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            chatService.createChat(participants: [myId, participantId], isGroup: false, name: nil) { chatId in
                                DispatchQueue.main.async {
                                    isLoading = false
                                    if let chatId = chatId {
                                        chatService.fetchChatById(chatId) { chat in
                                            DispatchQueue.main.async {
                                                if let chat = chat {
                                                    onChatCreated?(chat)
                                                    presentationMode.wrappedValue.dismiss()
                                                } else {
                                                    error = "Chat created, but not found. Try again."
                                                    showErrorAlert = true
                                                }
                                            }
                                        }
                                    } else {
                                        error = "Failed to create chat."
                                        showErrorAlert = true
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                isLoading = false
                error = status == "pending" ? "Your request is still pending." : "You must send a chat request and wait for it to be accepted."
                showErrorAlert = true
            }
        }
    }

    private func fetchSentRequests() {
        guard let myId = authViewModel.user?.uid else { return }
        let db = Firestore.firestore()
        db.collection("chatRequests")
            .whereField("fromUserId", isEqualTo: myId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments { snapshot, error in
                guard let docs = snapshot?.documents else { sentRequests = []; return }
                let userIds = docs.compactMap { $0.data()["toUserId"] as? String }
                if userIds.isEmpty { sentRequests = []; return }
                db.collection("users").whereField(FieldPath.documentID(), in: userIds).getDocuments { userSnap, _ in
                    guard let userDocs = userSnap?.documents else { sentRequests = []; return }
                    sentRequests = userDocs.map { doc in
                        let data = doc.data()
                        return UserSuggestion(
                            id: doc.documentID,
                            username: data["username"] as? String ?? "",
                            displayName: data["name"] as? String,
                            photoURL: data["photoURL"] as? String
                        )
                    }
                }
            }
    }

    @ViewBuilder
    private func UserRequestRow(user: UserSuggestion) -> some View {
        @State var requestStatus: String? = nil
        @State var isLoading = false
        let myId = authViewModel.user?.uid ?? ""
        HStack(spacing: 16) {
            if let url = user.photoURL, let imageURL = URL(string: url) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 44, height: 44)
                    WebImage(url: imageURL)
                        .resizable()
                        .indicator(.activity)
                        .clipShape(Circle())
                        .frame(width: 44, height: 44)
                }
            } else {
                Circle().fill(Color("appPrimaryAccent").opacity(0.12)).frame(width: 44, height: 44)
                    .overlay(Image(systemName: "person.fill").foregroundColor(Color("appPrimaryAccent")))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName ?? user.username)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("appTextPrimary"))
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundColor(Color("appTextSecondary"))
            }
            Spacer()
            if isLoading {
                ProgressView()
            } else if requestStatus == "accepted" {
                Button(action: { createChatWith(participantId: user.id) }) {
                    Text("Start Chat")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color("appPrimaryAccent"))
                        .cornerRadius(8)
                }
            } else if requestStatus == "pending" {
                Text("Request Sent")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("appTextSecondary"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color("appStrokeGray"))
                    .cornerRadius(8)
            } else {
                Button(action: {
                    isLoading = true
                    chatService.sendChatRequest(from: myId, to: user.id) { success in
                        isLoading = false
                        if success {
                            requestStatus = "pending"
                            fetchSentRequests()
                        }
                    }
                }) {
                    Text("Send Request")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color("appPrimaryAccent"))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color("appCardBG"))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        .onAppear {
            chatService.checkChatRequestStatus(from: myId, to: user.id) { status in
                requestStatus = status
            }
        }
    }
} 

