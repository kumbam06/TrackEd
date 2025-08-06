//
//  TaskCategoryManagementView.swift
//  GradMate
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI

struct TaskCategoryManagementView: View {
    @EnvironmentObject private var taskCategoryManager: TaskCategoryManager
    @Environment(\.dismiss) private var dismiss
    
    let category: TaskCategory?
    let onSave: (TaskCategory) -> Void
    
    @State private var name = ""
    @State private var selectedColor = "#007AFF"
    @State private var selectedIcon = "tag.fill"
    
    private let colors = [
        "#007AFF", "#34C759", "#FF9500", "#FF3B30", "#AF52DE",
        "#5856D6", "#FF2D92", "#5AC8FA", "#FFCC02", "#FF6B35"
    ]
    
    private let icons = [
        "tag.fill", "book.fill", "star.fill", "heart.fill", "flag.fill",
        "bookmark.fill", "gift.fill", "crown.fill", "diamond.fill", "bolt.fill"
    ]
    
    init(category: TaskCategory? = nil, onSave: @escaping (TaskCategory) -> Void) {
        self.category = category
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Name Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Category Name")
                            .font(.headline)
                            .foregroundColor(Color("appTextPrimary"))
                        
                        TextField("Enter category name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                    }
                    .padding(.horizontal, 20)
                    
                    // Color Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.headline)
                            .foregroundColor(Color("appTextPrimary"))
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(colors, id: \.self) { color in
                                ColorButton(
                                    color: color,
                                    isSelected: selectedColor == color
                                ) {
                                    selectedColor = color
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Icon Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Icon")
                            .font(.headline)
                            .foregroundColor(Color("appTextPrimary"))
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(icons, id: \.self) { icon in
                                IconButton(
                                    icon: icon,
                                    isSelected: selectedIcon == icon
                                ) {
                                    selectedIcon = icon
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 100)
                }
                .padding(.vertical, 20)
            }
            .background(Color("appScreenBG"))
            .navigationTitle(category == nil ? "New Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color("appTextSecondary"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCategory()
                    }
                    .font(.headline)
                    .foregroundColor(Color("appPrimaryAccent"))
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                loadCategoryData()
            }
        }
    }
    
    private func loadCategoryData() {
        guard let category = category else { return }
        
        name = category.name ?? ""
        selectedColor = category.color ?? "#007AFF"
        selectedIcon = category.icon ?? "tag.fill"
    }
    
    private func saveCategory() {
        let newCategory = TaskCategory(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            color: selectedColor,
            icon: selectedIcon
        )
        
        onSave(newCategory)
        dismiss()
    }
}

struct ColorButton: View {
    let color: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(hex: color) ?? .blue)
                    .frame(width: 40, height: 40)
                
                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct IconButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color("appPrimaryAccent") : Color("appScreenBG"))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : Color("appTextSecondary"))
                
                if isSelected {
                    Circle()
                        .stroke(Color("appPrimaryAccent"), lineWidth: 2)
                        .frame(width: 40, height: 40)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TaskCategoryManagementView(category: nil) { _ in }
        .environmentObject(TaskCategoryManager())
} 