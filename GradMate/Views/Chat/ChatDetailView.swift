//
//  ChatDetailView.swift
//  GradMate
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI
import FirebaseFirestore
import SDWebImageSwiftUI

// Animated waving hand icon for empty state
struct AnimatedWaveHand: View {
    @State private var wave = false
    var body: some View {
        Image(systemName: "hand.wave")
            .font(.system(size: 40, weight: .light))
            .foregroundColor(Color("appPrimaryAccent"))
            .rotationEffect(.degrees(wave ? 20 : -20), anchor: .bottomTrailing)
            .animation(
                Animation.easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true),
                value: wave
            )
            .onAppear { wave = true }
    }
}



struct ChatMessagesView: View {
    let messages: [Message]
    let userId: String
    let messageGradient: LinearGradient
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    if messages.isEmpty {
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color("appPrimaryAccent").opacity(0.10))
                                    .frame(width: 90, height: 90)
                                AnimatedWaveHand()
                            }
                            Text("No messages yet. Say hi to start your conversation!")
                                .font(.body)
                                .foregroundColor(Color("appTextSecondary"))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        .padding(.vertical, 40)
                    } else {
                        ForEach(messages, id: \.id) { message in
                            MessageRowView(message: message, userId: userId, messageGradient: messageGradient)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

struct MessageRowView: View {
    let message: Message
    let userId: String
    let messageGradient: LinearGradient
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.senderId == userId {
                Spacer(minLength: 60)
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.text)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(messageGradient)
                        .cornerRadius(20)
                    Text(timeString(from: message.timestamp))
                        .font(.caption2)
                        .foregroundColor(Color("appTextSecondary"))
                        .padding(.trailing, 8)
                }
                .padding(.trailing, 8)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.text)
                        .font(.body)
                        .foregroundColor(Color("appTextPrimary"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color("appCardBG"))
                        .cornerRadius(20)
                    Text(timeString(from: message.timestamp))
                        .font(.caption2)
                        .foregroundColor(Color("appTextSecondary"))
                        .padding(.leading, 8)
                }
                .padding(.leading, 8)
                Spacer(minLength: 60)
            }
        }
        .id(message.id)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ChatDetailView: View {
    let chat: Chat
    let userId: String
    let chatService: ChatServiceProtocol
    @StateObject private var viewModel: ChatDetailViewModel
    @State private var messageText = ""
    @State private var showErrorAlert = false
    @State private var showMenu = false
    @State private var partnerDisplayName: String = ""
    @State private var partnerUsername: String = ""
    @State private var partnerPhotoURL: String? = nil
    @State private var partnerStatus: String = "online"
    @State private var partnerId: String? = nil
    @Environment(\.dismiss) var dismiss
    @Binding var isChatDetailActive: Bool
    @State private var debouncedMessageText = ""
    @State private var debounceWorkItem: DispatchWorkItem?
    private let debounceDelay = 0.25
    @State private var isRefreshing = false
    
    init(chat: Chat, userId: String, chatService: ChatServiceProtocol, isChatDetailActive: Binding<Bool>) {
        self.chat = chat
        self.userId = userId
        self.chatService = chatService
        self._isChatDetailActive = isChatDetailActive
        _viewModel = StateObject(wrappedValue: ChatDetailViewModel(chatService: chatService, chatId: chat.id, userId: userId))
    }
    
    var body: some View {
        ZStack {
            Color("appScreenBG").ignoresSafeArea()
            VStack(spacing: 0) {
                // Custom Header as part of content
                HStack(spacing: 12) {
                    Button(action: {
                        isChatDetailActive = false
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(Color("appTextSecondary"))
                    }
                    
                    if let photoURL = partnerPhotoURL, let url = URL(string: photoURL) {
                        WebImage(url: url)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color("appPrimaryAccent").opacity(0.2), lineWidth: 1))
                    } else {
                        Circle()
                            .fill(Color("appPrimaryAccent").opacity(0.1))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color("appPrimaryAccent"))
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(partnerDisplayName.isEmpty ? partnerUsername : partnerDisplayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("appTextPrimary"))
                        Text("online")
                            .font(.caption2)
                            .foregroundColor(Color("appPrimaryAccent").opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Button(action: viewProfile) {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                            .font(.title2)
                            .foregroundColor(Color("appPrimaryAccent"))
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color("appPrimaryAccent").opacity(0.1)))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color("appScreenBG"))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color("appPrimaryAccent")))
                        .scaleEffect(1.2)
                    Spacer()
                } else if let error = viewModel.error {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color("appError"))
                        Text("Failed to load messages")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("appTextPrimary"))
                        Text(error)
                            .font(.body)
                            .foregroundColor(Color("appTextSecondary"))
                        Button(action: { viewModel.loadMessages(forceRefresh: true) }) {
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
                } else {
                    ChatMessagesView(
                        messages: viewModel.messages,
                        userId: userId,
                        messageGradient: messageGradient
                    )
                    .refreshable {
                        isRefreshing = true
                        viewModel.loadMessages(forceRefresh: true)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            isRefreshing = false
                        }
                    }
                }
                // Message Input Bar
                HStack(spacing: 12) {
                    TextField("Message...", text: $messageText)
                        .font(.body)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(.ultraThinMaterial)
                        .cornerRadius(22)
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                        .frame(minHeight: 40)
                        .onChange(of: messageText) { newValue in debounceInput(newValue) }
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(sendButtonGradient)
                            .clipShape(Circle())
                            .shadow(color: Color("appPrimaryAccent").opacity(0.18), radius: 8, x: 0, y: 3)
                    }
                    .disabled(debouncedMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .background(Color("appScreenBG").opacity(0.98))
            }
        }
        .onDisappear {
            viewModel.stopListening()
        }
        .onAppear {
            if let pid = chat.participants.first(where: { $0 != userId }) {
                partnerId = pid
                if let cached = UserCache.shared.getUserInfo(uid: pid) {
                    partnerUsername = cached.0
                    partnerDisplayName = cached.1 ?? ""
                    partnerPhotoURL = cached.2
                } else {
                    fetchPartnerInfoFromBackend(partnerId: pid)
                }
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 {
                        isChatDetailActive = false
                        dismiss()
                    }
                }
        )
        .onChange(of: viewModel.error) { newValue in
            showErrorAlert = newValue != nil
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.error ?? "Unknown error"),
                dismissButton: .default(Text("OK")) {
                    viewModel.error = nil
                }
            )
        }
        .navigationBarHidden(true)
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        viewModel.sendMessage(text)
        messageText = ""
    }
    
    private func fetchPartnerInfoFromBackend(partnerId: String) {
        let db = FirebaseFirestore.Firestore.firestore()
        db.collection("users").document(partnerId).getDocument { doc, error in
            guard let data = doc?.data() else { return }
            let newDisplayName = data["name"] as? String ?? ""
            let newUsername = data["username"] as? String ?? "User"
            let newPhotoURL = data["photoURL"] as? String
            partnerDisplayName = newDisplayName
            partnerUsername = newUsername
            partnerPhotoURL = newPhotoURL
            UserCache.shared.setUserInfo(uid: partnerId, username: newUsername, displayName: newDisplayName, photoURL: newPhotoURL)
        }
    }
    
    private func viewProfile() {
        // TODO: Implement profile view or menu
        print("[DEBUG] View profile tapped for user: \(partnerUsername)")
    }
    private func muteChat() {}
    private func blockUser() {}
    private func clearChat() {}
    
    private func debounceInput(_ value: String) {
        debounceWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            debouncedMessageText = value
        }
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceDelay, execute: workItem)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Helper to group messages by day
    private func groupMessagesByDay(_ messages: [Message]) -> [(date: Date, messages: [Message])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: messages) { message in
            calendar.startOfDay(for: message.timestamp)
        }
        return grouped.keys.sorted().map { date in
            (date, grouped[date]!.sorted { $0.timestamp < $1.timestamp })
        }
    }
    
    // Helper to format date header
    private func dateHeaderString(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
    
    private var messageGradient: LinearGradient {
        LinearGradient(
            colors: [Color("appPrimaryAccent"), Color("appPrimaryAccent").opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var sendButtonGradient: LinearGradient {
        LinearGradient(
            colors: [Color("appPrimaryAccent"), Color("appPrimaryAccent").opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var partnerImageURL: URL? {
        partnerPhotoURL.flatMap { URL(string: $0) }
    }
    
    private var partnerDisplayText: String {
        partnerDisplayName.isEmpty ? partnerUsername : partnerDisplayName
    }
    
    private var circleBackground: Color {
        Color("appPrimaryAccent").opacity(0.12)
    }
    
    private var personIcon: some View {
        Image(systemName: "person.fill").foregroundColor(Color("appPrimaryAccent"))
    }
}

// Checklist for light mode polish:
// - All colors (background, card, accent, text) use color assets with light/dark variants.
// - Input bar and message bubbles have enough contrast in both modes.
// - Test in both light and dark mode and adjust asset catalog if needed. 