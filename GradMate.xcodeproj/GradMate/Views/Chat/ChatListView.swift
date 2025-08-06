import SwiftUI
import SDWebImageSwiftUI

struct ChatListView: View {
    @StateObject private var chatViewModel = ChatViewModel()
    @State private var searchText = ""
    @State private var showingNewChat = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    searchBar
                    chatList
                }
            }
            .navigationTitle("Chats")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    newChatButton
                }
            }
            .sheet(isPresented: $showingNewChat) {
                NewChatView()
            }
        }
    }
    
    // MARK: - Search Bar
    @ViewBuilder
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search chats...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button("Clear") {
                    searchText = ""
                }
                .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Chat List
    @ViewBuilder
    private var chatList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredChats) { chat in
                    ChatRowView(chat: chat)
                        .onTapGesture {
                            // Navigate to chat details
                        }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - New Chat Button
    @ViewBuilder
    private var newChatButton: some View {
        Button(action: { showingNewChat = true }) {
            Image(systemName: "square.and.pencil")
                .font(.title2)
                .foregroundColor(.accentColor)
        }
    }
    
    // MARK: - Computed Properties
    private var filteredChats: [Chat] {
        if searchText.isEmpty {
            return chatViewModel.chats
        } else {
            return chatViewModel.chats.filter { chat in
                chat.participantName.localizedCaseInsensitiveContains(searchText) ||
                chat.lastMessage.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - Chat Row View
struct ChatRowView: View {
    let chat: Chat
    
    var body: some View {
        HStack(spacing: 12) {
            avatarSection
            chatInfoSection
            timestampSection
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var avatarSection: some View {
        WebImage(url: URL(string: chat.participantAvatar))
            .resizable()
            .placeholder {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .overlay(
                        Text(String(chat.participantName.prefix(1)))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.accentColor)
                    )
            }
            .indicator(.activity)
            .transition(.fade(duration: 0.5))
            .scaledToFill()
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.accentColor, lineWidth: chat.isOnline ? 2 : 0)
            )
    }
    
    @ViewBuilder
    private var chatInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(chat.participantName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if chat.unreadCount > 0 {
                    Text("\(chat.unreadCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                }
            }
            
            Text(chat.lastMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
    }
    
    @ViewBuilder
    private var timestampSection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(chat.lastMessageTime.timeAgoDisplay())
                .font(.caption)
                .foregroundColor(.secondary)
            
            if chat.lastMessageStatus == .sent {
                Image(systemName: "checkmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if chat.lastMessageStatus == .delivered {
                Image(systemName: "checkmark.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if chat.lastMessageStatus == .read {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ChatListView()
} 