import SwiftUI
import FirebaseAuth

struct ChatListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var chatService: FirestoreChatService
    @State private var viewModel: ChatListViewModel? = nil
    @State private var showNewChat = false
    @State private var selectedChat: Chat? = nil
    
    var body: some View {
        NavigationView {
            Group {
                if let viewModel = viewModel {
                    if viewModel.isLoading {
                        ProgressView("Loading chats...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = viewModel.error {
                        VStack(spacing: 16) {
                            Text("Failed to load chats: \(error)")
                                .foregroundColor(.red)
                            Button("Retry") {
                                viewModel.loadChats()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(viewModel.chats) { chat in
                                Button(action: { selectedChat = chat }) {
                                    HStack {
                                        Image(systemName: chat.isGroup ? "person.3.fill" : "person.fill")
                                            .foregroundColor(.accentColor)
                                        VStack(alignment: .leading) {
                                            Text(chat.name ?? chat.participants.filter { $0 != authViewModel.user?.uid }.joined(separator: ", "))
                                                .font(.headline)
                                            if let last = chat.lastMessage {
                                                Text("\(last.senderId == authViewModel.user?.uid ? "You: " : "")\(last.text)")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        Spacer()
                                        if let last = chat.lastMessage {
                                            Text(timeAgo(last.timestamp))
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .background(Color(.systemGray6))
                                    .cornerRadius(16)
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.separator), lineWidth: 1))
                                }
                            }
                        }
                    }
                } else {
                    ProgressView("Loading chats...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showNewChat = true }) {
                        Text("New Chat")
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray5))
                            .cornerRadius(12)
                            .shadow(color: .accentColor.opacity(0.18), radius: 8, x: 0, y: 4)
                    }
                    .disabled(viewModel == nil)
                }
            }
            .sheet(item: $selectedChat) { chat in
                if let userId = authViewModel.user?.uid {
                    ChatDetailView(chat: chat, userId: userId, chatService: chatService)
                }
            }
            .sheet(isPresented: $showNewChat) {
                NewChatView()
            }
        }
        .onAppear {
            if viewModel == nil, let userId = authViewModel.user?.uid {
                viewModel = ChatListViewModel(chatService: chatService, userId: userId)
            }
        }
    }
    
    func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
} 