//
//  ChatDetailView.swift
//  TrackEd
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI

struct ChatDetailView: View {
    let chat: Chat
    let userId: String
    let chatService: ChatServiceProtocol
    @StateObject private var viewModel: ChatDetailViewModel
    @State private var messageText = ""
    @State private var showErrorAlert = false
    
    init(chat: Chat, userId: String, chatService: ChatServiceProtocol) {
        self.chat = chat
        self.userId = userId
        self.chatService = chatService
        _viewModel = StateObject(wrappedValue: ChatDetailViewModel(chatService: chatService, chatId: chat.id, userId: userId))
    }
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading messages...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                VStack(spacing: 16) {
                    Text("Failed to load messages: \(error)")
                        .foregroundColor(.red)
                    Button("Retry") {
                        viewModel.listenForMessages()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            if viewModel.messages.isEmpty {
                                HStack {
                                    Spacer()
                                    Text("No messages yet. Say hello!")
                                        .foregroundColor(.secondary)
                                        .font(.subheadline)
                                        .padding(.vertical, 32)
                                    Spacer()
                                }
                            }
                            ForEach(viewModel.messages) { message in
                                HStack {
                                    if message.senderId == userId {
                                        Spacer()
                                        Text(message.text)
                                            .padding(10)
                                            .background(Color.accentColor)
                                            .foregroundColor(.white)
                                            .cornerRadius(16)
                                    } else {
                                        Text(message.text)
                                            .padding(10)
                                            .background(Color(.systemGray4))
                                            .foregroundColor(.primary)
                                            .cornerRadius(16)
                                        Spacer()
                                    }
                                }
                                .id(message.id)
                            }
                        }
                        .padding(.vertical)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.separator), lineWidth: 1))
                    }
                    .onChange(of: viewModel.messages.count) {
                        if let last = viewModel.messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            HStack {
                TextField("Message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.accentColor)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.separator), lineWidth: 1))
        }
        .navigationTitle(chat.name ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            viewModel.stopListening()
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
    }
    
    func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        viewModel.sendMessage(text)
        messageText = ""
    }
} 