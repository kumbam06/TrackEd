//
//  SharedFormComponents.swift
//  GradMate
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI

// MARK: - Shared Form Components
struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color("appTextPrimary"))
            
            TextField(placeholder, text: $text)
                .textFieldStyle(CustomTextFieldStyle())
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit { hideKeyboard() }
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .background(Color("appStrokeGray"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("appStrokeGray"), lineWidth: 1)
            )
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("appTextPrimary"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color("appCardBG"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("appStrokeGray"), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
    }
} 