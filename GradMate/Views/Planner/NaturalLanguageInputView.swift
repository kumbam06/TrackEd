//
//  NaturalLanguageInputView.swift
//  GradMate
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
                Color("appScreenBG").ignoresSafeArea()
                
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color("appPrimaryAccent").opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "text.bubble.fill")
                            .font(.title)
                            .foregroundColor(Color("appPrimaryAccent"))
                            .shadow(color: Color("appPrimaryAccent"), radius: 8, x: 0, y: 0)
                    }
                    
                    Text("Describe your task in natural language")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color("appTextPrimary"))
                        .kerning(1)
                        .multilineTextAlignment(.center)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Task Description")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color("appTextPrimary"))
                        
                        TextEditor(text: $inputText)
                            .focused($isTextFieldFocused)
                            .frame(height: 100)
                            .padding(12)
                            .background(Color("appStrokeGray"))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color("appStrokeGray"), lineWidth: 1)
                            )
                            .overlay(
                                Group {
                                    if inputText.isEmpty {
                                        Text("Describe your task in natural language...")
                                            .foregroundColor(Color("appTextSecondary"))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .allowsHitTesting(false)
                                    }
                                },
                                alignment: .topLeading
                            )
                            .foregroundColor(Color("appTextPrimary"))
                            .font(.body)
                    }
                    
                    // Example suggestions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Examples")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color("appTextSecondary"))
                        
                        VStack(spacing: 8) {
                            ExampleButton(text: "Complete the project presentation by Friday") {
                                inputText = "Complete the project presentation by Friday"
                            }
                            
                            ExampleButton(text: "Review and update my resume") {
                                inputText = "Review and update my resume"
                            }
                            
                            ExampleButton(text: "Prepare for the technical interview") {
                                inputText = "Prepare for the technical interview"
                            }
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(role: .cancel, action: { dismiss() }) {
                            Text("Cancel")
                                .fontWeight(.medium)
                                .foregroundColor(Color("appTextSecondary"))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("appStrokeGray"))
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            onSubmit(inputText)
                            dismiss()
                        }) {
                            Text("Add Task")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("appPrimaryAccent"))
                                .cornerRadius(12)
                        }
                        .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(24)
            }
            .navigationTitle("Natural Language Input")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ExampleButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color("appPrimaryAccent").opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "lightbulb")
                        .font(.caption)
                        .foregroundColor(Color("appPrimaryAccent"))
                }
                
                Text(text)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color("appTextPrimary"))
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color("appCardBG"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("appStrokeGray"), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
} 