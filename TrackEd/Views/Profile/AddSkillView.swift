//
//  AddSkillView.swift
//  TrackEd
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
            Form {
                Section(header: Text("Skill Details")) {
                    TextField("Skill Name", text: $skillName)
                        .accessibilityLabel(Text("Skill name"))
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    TextEditor(text: $description)
                        .frame(height: 80)
                        .accessibilityLabel(Text("Skill description"))
                }
                
                Section(header: Text("Proficiency Level")) {
                    HStack {
                        Text("Level \(proficiency)")
                            .fontWeight(.medium)
                        Spacer()
                        Stepper(value: $proficiency, in: 1...5) {
                            EmptyView()
                        }
                    }
                    
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { level in
                            Image(systemName: level <= proficiency ? "star.fill" : "star")
                                .font(.title3)
                                .foregroundColor(level <= proficiency ? .yellow : .secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Quick Add")) {
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
            }
            .navigationTitle("Add Skill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSkill()
                    }
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
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(category)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
} 
