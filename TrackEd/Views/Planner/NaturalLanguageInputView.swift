//
//  NaturalLanguageInputView.swift
//  TrackEd
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI

struct NaturalLanguageInputView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var inputText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var onSubmit: (String) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "text.bubble.fill")
                            .font(.title)
                            .foregroundColor(.accentColor)
                            .shadow(color: .primary, radius: 8, x: 0, y: 0)
                    }
                    Text("Describe your task in natural language")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .kerning(1)
                        .shadow(color: .primary, radius: 8, x: 0, y: 0)
                    TextEditor(text: $inputText)
                        .focused($isTextFieldFocused)
                        .frame(height: 100)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.08))
                        )
                        .foregroundColor(.primary)
                        .font(.body)
                    HStack(spacing: 12) {
                        Button(role: .cancel, action: { dismiss() }) {
                            Text("Cancel")
                        }
                        Button(action: {
                            onSubmit(inputText)
                            dismiss()
                        }) {
                            Text("Add Task")
                        }
                        .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(24)
            }
        }
    }
}

struct ExampleButton5D: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "lightbulb")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .shadow(color: .accentColor, radius: 4, x: 0, y: 0)
                }
                
                Text(text)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground).opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: Color.accentColor.opacity(0.1), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
} 