//
//  ChatDetailView.swift
//  TrackEd
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

struct ChatDetailView: View {
    let chat: Chat
    let userId: String
    let chatService: ChatServiceProtocol
    @StateObject private var viewModel: ChatDetailViewModel
    @State private var messageText = ""
    @State private var showErrorAlert = false
    @State private var showMenu = false
    @State private var partnerUsername: String = ""
    @State private var partnerPhotoURL: String? = nil
    @State private var partnerStatus: String = "online"
    @Environment(\.presentationMode) var presentationMode
    @State private var debouncedMessageText = ""
    @State private var debounceWorkItem: DispatchWorkItem?
    private let debounceDelay = 0.25
    @State private var isRefreshing = false
    
    init(chat: Chat, userId: String, chatService: ChatServiceProtocol) {
        self.chat = chat
        self.userId = userId
        self.chatService = chatService
        _viewModel = StateObject(wrappedValue: ChatDetailViewModel(chatService: chatService, chatId: chat.id, userId: userId))
    }
    
    var body: some View {
        ZStack {
            Color("appScreenBG").ignoresSafeArea()
            VStack(spacing: 0) {
                // Custom Navigation Bar
                HStack(spacing: 16) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(Color("appPrimaryAccent"))
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                    }
                    if let url = partnerPhotoURL, let imageURL = URL(string: url) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 40, height: 40)
                            WebImage(url: imageURL)
                                .resizable()
                                .indicator(.activity)
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color("appPrimaryAccent"), lineWidth: 2))
                                .shadow(color: Color("appPrimaryAccent").opacity(0.10), radius: 6, x: 0, y: 2)
                        }
                    } else {
                        Circle().fill(Color("appPrimaryAccent").opacity(0.12))
                            .frame(width: 40, height: 40)
                            .overlay(Image(systemName: "person.fill").foregroundColor(Color("appPrimaryAccent")))
                            .overlay(Circle().stroke(Color("appPrimaryAccent"), lineWidth: 2))
                            .shadow(color: Color("appPrimaryAccent").opacity(0.10), radius: 6, x: 0, y: 2)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(partnerUsername.isEmpty ? "Chat" : partnerUsername)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color("appTextPrimary"))
                        Text(partnerStatus)
                            .font(.caption2)
                            .foregroundColor(Color("appPrimaryAccent").opacity(0.8))
                    }
                    Spacer()
                    Menu {
                        Button("View Profile", action: viewProfile)
                        Button("Mute Chat", action: muteChat)
                        Button("Block User", action: blockUser)
                        Button("Clear Chat", action: clearChat)
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                            .font(.title2)
                            .foregroundColor(Color("appPrimaryAccent"))
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                
                Divider().opacity(0.05)
                
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
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 14) {
                                if viewModel.messages.isEmpty {
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
                                }
                                ForEach(viewModel.messages) { message in
                                    HStack(alignment: .bottom, spacing: 8) {
                                        if message.senderId == userId {
                                            Spacer(minLength: 60)
                                            VStack(alignment: .trailing, spacing: 4) {
                                                Text(message.text)
                                                    .font(.body)
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 12)
                                                    .background(
                                                        LinearGradient(colors: [Color("appPrimaryAccent"), Color("appPrimaryAccent").opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                                    )
                                                    .cornerRadius(20)
                                                    .shadow(color: Color("appPrimaryAccent").opacity(0.08), radius: 4, x: 0, y: 2)
                                            }
                                        } else {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(message.text)
                                                    .font(.body)
                                                    .foregroundColor(Color("appTextPrimary"))
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 12)
                                                    .background(Color("appCardBG"))
                                                    .cornerRadius(20)
                                                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                                            }
                                            Spacer(minLength: 60)
                                        }
                                    }
                                    .id(message.id)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .refreshable {
                            isRefreshing = true
                            viewModel.loadMessages(forceRefresh: true)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                isRefreshing = false
                            }
                        }
                    }
                }
                // Message Input Bar
                HStack(spacing: 12) {
                    TextField("Message...", text: $messageText, axis: .vertical)
                        .font(.body)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(.ultraThinMaterial)
                        .cornerRadius(22)
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                        .lineLimit(1...4)
                        .onChange(of: messageText) { debounceInput($0) }
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(
                                LinearGradient(colors: [Color("appPrimaryAccent"), Color("appPrimaryAccent").opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
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
            loadPartnerInfo()
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
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
    
    private func loadPartnerInfo() {
        guard let partnerId = chat.participants.first(where: { $0 != userId }) else { return }
        let db = FirebaseFirestore.Firestore.firestore()
        db.collection("users").document(partnerId).getDocument { doc, error in
            guard let data = doc?.data() else { return }
            partnerUsername = data["username"] as? String ?? "User"
            partnerPhotoURL = data["photoURL"] as? String
            // If you have online status, set partnerStatus here
        }
    }
    
    private func viewProfile() {}
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
}

// Checklist for light mode polish:
// - All colors (background, card, accent, text) use color assets with light/dark variants.
// - Input bar and message bubbles have enough contrast in both modes.
// - Test in both light and dark mode and adjust asset catalog if needed. 