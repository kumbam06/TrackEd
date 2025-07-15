//
//  AddSkillView.swift
//  GradMate
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI

struct AddSkillView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var skillManager: SkillManager
    
    @State private var skillName = ""
    @State private var category = "General"
    @State private var description = ""
    @State private var proficiency: Int16 = 1
    
    private let categories = ["General", "Programming", "Design", "Management", "Communication", "Tools", "Frameworks", "Databases", "Cloud", "Other"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("appScreenBG").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Skill Details Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Skill Details")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("appTextPrimary"))
                            
                            VStack(spacing: 16) {
                                CustomTextField(title: "Skill Name", text: $skillName, placeholder: "e.g., Swift, Python, UI/UX Design")
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Category")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color("appTextPrimary"))
                                    
                                    Picker("Category", selection: $category) {
                                        ForEach(categories, id: \.self) { cat in
                                            Text(cat).tag(cat)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .padding(16)
                                    .background(Color("appStrokeGray"))
                                    .cornerRadius(12)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Description")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color("appTextPrimary"))
                                    
                                    TextEditor(text: $description)
                                        .frame(height: 80)
                                        .padding(12)
                                        .background(Color("appStrokeGray"))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color("appStrokeGray"), lineWidth: 1)
                                        )
                                        .overlay(
                                            Group {
                                                if description.isEmpty {
                                                    Text("Describe your experience with this skill...")
                                                        .foregroundColor(Color("appTextSecondary"))
                                                        .padding(.horizontal, 16)
                                                        .padding(.vertical, 12)
                                                        .allowsHitTesting(false)
                                                }
                                            },
                                            alignment: .topLeading
                                        )
                                }
                            }
                        }
                        .padding(20)
                        .background(Color("appCardBG"))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("appStrokeGray"), lineWidth: 1))
                        
                        // Proficiency Level Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Proficiency Level")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("appTextPrimary"))
                            
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Level \(proficiency)")
                                        .fontWeight(.medium)
                                        .foregroundColor(Color("appTextPrimary"))
                                    Spacer()
                                    Stepper(value: $proficiency, in: 1...5) {
                                        EmptyView()
                                    }
                                }
                                
                                HStack(spacing: 4) {
                                    ForEach(1...5, id: \.self) { level in
                                        Image(systemName: level <= proficiency ? "star.fill" : "star")
                                            .font(.title3)
                                            .foregroundColor(level <= proficiency ? Color("appWarning") : Color("appTextSecondary"))
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .padding(20)
                        .background(Color("appCardBG"))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("appStrokeGray"), lineWidth: 1))
                        
                        // Quick Add Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quick Add")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("appTextPrimary"))
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                                QuickSkillButton(name: "Swift", category: "Programming") {
                                    skillName = "Swift"
                                    category = "Programming"
                                }
                                
                                QuickSkillButton(name: "SwiftUI", category: "Frameworks") {
                                    skillName = "SwiftUI"
                                    category = "Frameworks"
                                }
                                
                                QuickSkillButton(name: "Core Data", category: "Databases") {
                                    skillName = "Core Data"
                                    category = "Databases"
                                }
                                
                                QuickSkillButton(name: "Git", category: "Tools") {
                                    skillName = "Git"
                                    category = "Tools"
                                }
                                
                                QuickSkillButton(name: "Xcode", category: "Tools") {
                                    skillName = "Xcode"
                                    category = "Tools"
                                }
                                
                                QuickSkillButton(name: "UI/UX Design", category: "Design") {
                                    skillName = "UI/UX Design"
                                    category = "Design"
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .padding(20)
                        .background(Color("appCardBG"))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("appStrokeGray"), lineWidth: 1))
                    }
                    .padding(20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Add Skill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color("appTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSkill()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color("appPrimaryAccent"))
                    .disabled(skillName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveSkill() {
        skillManager.addSkill(
            name: skillName.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            proficiency: proficiency
        )
        dismiss()
    }
}

struct QuickSkillButton: View {
    let name: String
    let category: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color("appTextPrimary"))
                    .lineLimit(1)
                
                Text(category)
                    .font(.caption2)
                    .foregroundColor(Color("appTextSecondary"))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color("appStrokeGray"))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Note: CustomTextFieldStyle is now defined in SharedFormComponents.swift 
