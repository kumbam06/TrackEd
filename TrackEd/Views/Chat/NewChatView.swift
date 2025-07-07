import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserSuggestion: Identifiable {
    let id: String // UID
    let username: String
    let displayName: String?
    let photoURL: String?
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
    var onChatCreated: ((Chat) -> Void)? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("appScreenBG").ignoresSafeArea()
                VStack(spacing: 28) {
                    HStack {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(Color("appPrimaryAccent"))
                                .padding(8)
                                .background(Color("appPrimaryAccent").opacity(0.08))
                                .clipShape(Circle())
                        }
                        Spacer()
                        Text("Start New Chat")
                            .font(.title2)
                            .fontWeight(.heavy)
                            .foregroundColor(Color("appTextPrimary"))
                        Spacer(minLength: 32)
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 8)
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color("appPrimaryAccent"))
                        TextField("Search username...", text: $searchText)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color("appTextPrimary"))
                            .onChange(of: searchText) { newValue in
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
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color("appPrimaryAccent")))
                            .scaleEffect(1.1)
                    }
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(suggestions) { user in
                                Button(action: { createChatWith(participantId: user.id) }) {
                                    HStack(spacing: 16) {
                                        if let url = user.photoURL, let imageURL = URL(string: url) {
                                            AsyncImage(url: imageURL) { image in
                                                image.resizable().frame(width: 44, height: 44).clipShape(Circle())
                                            } placeholder: {
                                                Circle().fill(Color.gray.opacity(0.2)).frame(width: 44, height: 44)
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
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(Color("appCardBG"))
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                                }
                                .buttonStyle(PlainButtonStyle())
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
        db.collection("users")
            .order(by: "username")
            .limit(to: 30)
            .getDocuments { snapshot, error in
                isLoadingSuggestions = false
                guard let docs = snapshot?.documents else {
                    suggestions = []
                    return
                }
                let lowerInput = input.lowercased()
                suggestions = docs.compactMap { doc in
                    let data = doc.data()
                    let uid = doc.documentID
                    let username = data["username"] as? String ?? ""
                    let displayName = data["name"] as? String
                    // Don't show yourself in suggestions
                    if uid == authViewModel.user?.uid { return nil }
                    // Match username or display name
                    if username.lowercased().contains(lowerInput) || (displayName?.lowercased().contains(lowerInput) ?? false) {
                        return UserSuggestion(
                            id: uid,
                            username: username,
                            displayName: displayName,
                            photoURL: data["photoURL"] as? String
                        )
                    }
                    return nil
                }
            }
    }
    
    private func createChatWith(participantId: String) {
        guard let myId = authViewModel.user?.uid else { return }
        if participantId == myId {
            self.error = "You cannot start a chat with yourself."
            self.showErrorAlert = true
            self.isLoading = false
            return
        }
        isLoading = true
        chatService.findDirectChat(between: myId, and: participantId) { existingChat in
            if let chat = existingChat {
                isLoading = false
                onChatCreated?(chat)
                presentationMode.wrappedValue.dismiss()
            } else {
                chatService.createChat(participants: [myId, participantId], isGroup: false, name: nil) { chatId in
                    isLoading = false
                    if let chatId = chatId {
                        chatService.fetchChatById(chatId) { chat in
                            if let chat = chat {
                                onChatCreated?(chat)
                                presentationMode.wrappedValue.dismiss()
                            } else {
                                error = "Chat created, but not found. Try again."
                                showErrorAlert = true
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

