//
//  LanguageListView.swift
//  GradMate
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI

struct LanguageListView: View {
    @EnvironmentObject private var profileManager: ProfileManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var languages: [Language] = []
    @State private var showingAddLanguage = false
    @State private var editingLanguage: Language?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("appScreenBG").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundColor(Color("appPrimaryAccent"))
                                    .padding(10)
                                    .background(Color("appPrimaryAccent").opacity(0.1))
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                        
                        Text("Languages")
                            .font(.title2)
                            .fontWeight(.heavy)
                            .foregroundColor(Color("appTextPrimary"))
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Content
                    if languages.isEmpty {
                        emptyStateView
                    } else {
                        languageListView
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadLanguages()
            }
            .sheet(isPresented: $showingAddLanguage) {
                LanguageEditView(language: nil) { newLanguage in
                    languages.append(newLanguage)
                    saveLanguages()
                }
            }
            .sheet(item: $editingLanguage) { language in
                LanguageEditView(language: language) { updatedLanguage in
                    if let index = languages.firstIndex(where: { $0.id == language.id }) {
                        languages[index] = updatedLanguage
                        saveLanguages()
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color("appPrimaryAccent").opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "globe")
                        .font(.title)
                        .foregroundColor(Color("appPrimaryAccent"))
                }
                
                VStack(spacing: 8) {
                    Text("No Languages Added")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("appTextPrimary"))
                    
                    Text("Add your spoken languages to showcase your communication skills")
                        .font(.subheadline)
                        .foregroundColor(Color("appTextSecondary"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            
            Button(action: { showingAddLanguage = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Add Language")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("appPrimaryAccent"))
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Language List
    private var languageListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(languages) { language in
                    LanguageCard(language: language) {
                        editingLanguage = language
                    } onDelete: {
                        deleteLanguage(language)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .overlay(
            VStack {
                Spacer()
                Button(action: { showingAddLanguage = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Add Language")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("appPrimaryAccent"))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        )
    }
    
    // MARK: - Helper Methods
    private func loadLanguages() {
        // Load from profile manager or user defaults
        if let data = UserDefaults.standard.data(forKey: "userLanguages"),
           let decoded = try? JSONDecoder().decode([Language].self, from: data) {
            languages = decoded
        }
    }
    
    private func saveLanguages() {
        if let encoded = try? JSONEncoder().encode(languages) {
            UserDefaults.standard.set(encoded, forKey: "userLanguages")
        }
    }
    
    private func deleteLanguage(_ language: Language) {
        languages.removeAll { $0.id == language.id }
        saveLanguages()
    }
}

// MARK: - Language Card
struct LanguageCard: View {
    let language: Language
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color("appPrimaryAccent").opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "globe")
                    .font(.title2)
                    .foregroundColor(Color("appPrimaryAccent"))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(language.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("appTextPrimary"))
                
                Text(language.proficiency.rawValue)
                    .font(.subheadline)
                    .foregroundColor(Color("appTextSecondary"))
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("appPrimaryAccent"))
                        .padding(8)
                        .background(Color("appPrimaryAccent").opacity(0.1))
                        .clipShape(Circle())
                }
                
                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("appError"))
                        .padding(8)
                        .background(Color("appError").opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding(16)
        .background(Color("appCardBG"))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .alert("Delete Language", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("Are you sure you want to delete \(language.name)? This action cannot be undone.")
        }
    }
}

// MARK: - Language Edit View
struct LanguageEditView: View {
    let language: Language?
    let onSave: (Language) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var proficiency: Language.ProficiencyLevel = .beginner
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("appScreenBG").ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Language Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Language Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color("appTextPrimary"))
                        
                        TextField("e.g., English, Spanish, French", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                    }
                    
                    // Proficiency Level
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Proficiency Level")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color("appTextPrimary"))
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(Language.ProficiencyLevel.allCases, id: \.self) { level in
                                ProficiencyButton(
                                    level: level,
                                    isSelected: proficiency == level
                                ) {
                                    proficiency = level
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle(language == nil ? "Add Language" : "Edit Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newLanguage = Language(
                            id: language?.id ?? UUID(),
                            name: name,
                            proficiency: proficiency
                        )
                        onSave(newLanguage)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let language = language {
                    name = language.name
                    proficiency = language.proficiency
                }
            }
        }
    }
}

// MARK: - Proficiency Button
struct ProficiencyButton: View {
    let level: Language.ProficiencyLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(level.emoji)
                    .font(.title2)
                
                Text(level.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : Color("appTextPrimary"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color("appPrimaryAccent") : Color("appStrokeGray"))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Proficiency Level Extensions
extension Language.ProficiencyLevel {
    var emoji: String {
        switch self {
        case .beginner: return "🌱"
        case .intermediate: return "🌿"
        case .advanced: return "🌳"
        case .fluent: return "🎯"
        case .native: return "👑"
        }
    }
}

#Preview {
    LanguageListView()
        .environmentObject(ProfileManager())
} 