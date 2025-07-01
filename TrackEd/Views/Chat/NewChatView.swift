import SwiftUI
import FirebaseAuth

struct NewChatView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var chatService: FirestoreChatService
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var userId = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var showErrorAlert = false
    @State private var createdChat: Chat? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Start New Chat")
                    .font(.title)
                    .fontWeight(.bold)
                TextField("Enter user ID or email", text: $userId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: startChat) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Start Chat")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                Spacer()
            }
            .padding()
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
            .sheet(item: $createdChat) { chat in
                if let myId = authViewModel.user?.uid {
                    ChatDetailView(chat: chat, userId: myId, chatService: chatService)
                }
            }
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
    }
    
    func startChat() {
        let trimmed = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let myId = authViewModel.user?.uid, !trimmed.isEmpty else { return }
        // Validate input: must be a valid email, user ID, or username
        if isValidEmail(trimmed) {
            // Email-based chat creation (not implemented, fallback to error)
            error = "Searching by email is not supported. Please use username or user ID."
            showErrorAlert = true
            return
        } else if isValidUserId(trimmed) {
            // Try as username first
            isLoading = true
            chatService.lookupUserId(byUsername: trimmed) { foundUid in
                DispatchQueue.main.async {
                    if let foundUid = foundUid {
                        if foundUid == myId {
                            self.error = "You cannot start a chat with yourself."
                            self.showErrorAlert = true
                            self.isLoading = false
                            return
                        }
                        self.createChatWith(participantId: foundUid)
                    } else {
                        // If not found as username, try as user ID
                        if trimmed == myId {
                            self.error = "You cannot start a chat with yourself."
                            self.showErrorAlert = true
                            self.isLoading = false
                            return
                        }
                        self.createChatWith(participantId: trimmed)
                    }
                }
            }
            return
        } else {
            error = "Please enter a valid username or user ID (at least 4 alphanumeric characters)."
            showErrorAlert = true
            return
        }
    }
    
    private func createChatWith(participantId: String) {
        guard let myId = authViewModel.user?.uid else { return }
        chatService.createChat(participants: [myId, participantId], isGroup: false, name: nil) { chatId in
            isLoading = false
            if let chatId = chatId {
                chatService.fetchChatById(chatId) { chat in
                    if let chat = chat {
                        createdChat = chat
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
    
    func isValidEmail(_ input: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: input)
    }
    
    func isValidUserId(_ input: String) -> Bool {
        let userIdRegEx = "[A-Za-z0-9]{4,}"
        let userIdPred = NSPredicate(format: "SELF MATCHES %@", userIdRegEx)
        return userIdPred.evaluate(with: input)
    }
} 

