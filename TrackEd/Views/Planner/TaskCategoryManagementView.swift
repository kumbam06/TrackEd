import SwiftUI

struct TaskCategoryManagementView: View {
    @EnvironmentObject private var categoryManager: TaskCategoryManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddCategory = false
    @State private var selectedCategory: TaskCategoryEntity?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("appScreenBG")
                    .ignoresSafeArea()
                
                if categoryManager.categories.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tag.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Categories Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("appTextPrimary"))
                        
                        Text("Create your first category to organize tasks")
                            .font(.body)
                            .foregroundColor(Color("appTextSecondary"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button(action: {
                            showingAddCategory = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Category")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color("appPrimaryAccent"))
                            .cornerRadius(12)
                        }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(categoryManager.categories, id: \.id) { category in
                                CategoryCard(category: category) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Task Categories")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color("appTextSecondary"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button("Reset") {
                            categoryManager.resetToDefaults()
                        }
                        .foregroundColor(Color("appTextSecondary"))
                        
                        Button(action: {
                            showingAddCategory = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(Color("appPrimaryAccent"))
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                CategoryEditView(category: nil) { newCategory in
                    categoryManager.addCategory(newCategory)
                }
            }
            .sheet(item: $selectedCategory) { category in
                CategoryEditView(category: category) { updatedCategory in
                    categoryManager.updateCategory(updatedCategory)
                }
            }
        }
    }
}

struct CategoryCard: View {
    let category: TaskCategoryEntity
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(category.color ?? "#007AFF").opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: category.icon ?? "tag.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(category.color ?? "#007AFF"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name ?? "Category")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("appTextPrimary"))
                    
                    if category.isDefault {
                        Text("Default Category")
                            .font(.caption)
                            .foregroundColor(Color("appTextSecondary"))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color("appTextSecondary"))
            }
            .padding()
            .background(Color("appCardBG"))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryEditView: View {
    let category: TaskCategoryEntity?
    let onSave: (TaskCategory) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedColor = "#007AFF"
    @State private var selectedIcon = "tag.fill"
    
    private let colors = [
        "#007AFF", "#34C759", "#FF9500", "#FF3B30", "#AF52DE", "#FFCC00",
        "#5856D6", "#FF2D92", "#5AC8FA", "#FF6B35", "#4CD964", "#FFD60A"
    ]
    
    private let icons = [
        "tag.fill", "book.fill", "briefcase.fill", "person.fill", "heart.fill",
        "person.2.fill", "dollarsign.circle.fill", "house.fill", "car.fill",
        "gamecontroller.fill", "camera.fill", "music.note", "leaf.fill",
        "flame.fill", "star.fill", "bolt.fill", "drop.fill", "sun.max.fill"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("appScreenBG")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Basic Information
                        VStack(alignment: .leading, spacing: 16) {
                            Text("CATEGORY DETAILS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color("appTextPrimary"))
                                .kerning(1.5)
                            
                            VStack(spacing: 12) {
                                CustomTextField(
                                    title: "Category Name",
                                    text: $name,
                                    placeholder: "e.g., Academic"
                                )
                            }
                        }
                        .padding()
                        .background(Color("appCardBG"))
                        .cornerRadius(16)
                        
                        // Color Selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("COLOR")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color("appTextPrimary"))
                                .kerning(1.5)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
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
                        .padding()
                        .background(Color("appCardBG"))
                        .cornerRadius(16)
                        
                        // Icon Selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("ICON")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color("appTextPrimary"))
                                .kerning(1.5)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
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
                        .padding()
                        .background(Color("appCardBG"))
                        .cornerRadius(16)
                    }
                    .padding()
                }
            }
            .navigationTitle(category == nil ? "Add Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.large)
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
                    .fontWeight(.semibold)
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
    TaskCategoryManagementView()
        .environmentObject(TaskCategoryManager())
} 