import SwiftUI

struct AchievementDetailsView: View {
    @EnvironmentObject private var progressDataService: ProgressDataService
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: AchievementCategory = .all
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("appScreenBG")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search and Filter Bar
                    searchAndFilterBar
                    
                    // Achievements List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredAchievements, id: \.id) { achievement in
                                AchievementCard(achievement: achievement)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Search and Filter Bar
    private var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search achievements...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding()
            .background(Color("appCardBG"))
            .cornerRadius(12)
            
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AchievementCategory.allCases, id: \.self) { category in
                        CategoryFilterButton(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color("appCardBG"))
    }
    
    // MARK: - Filtered Achievements
    private var filteredAchievements: [AchievementEntity] {
        var achievements = progressDataService.achievements
        
        // Filter by category
        if selectedCategory != .all {
            achievements = achievements.filter { $0.category == selectedCategory.rawValue }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            achievements = achievements.filter { achievement in
                achievement.title?.localizedCaseInsensitiveContains(searchText) == true ||
                achievement.achievementDescription?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        return achievements
    }
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievement: AchievementEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(achievement.color ?? "blue").opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: achievement.icon ?? "star.fill")
                        .font(.title2)
                        .foregroundColor(Color(achievement.color ?? "blue"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(achievement.title ?? "Achievement")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("appTextPrimary"))
                    
                    Text(achievement.achievementDescription ?? "")
                        .font(.subheadline)
                        .foregroundColor(Color("appTextSecondary"))
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Completion Status
                if achievement.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color("appTextSecondary"))
                    
                    Spacer()
                    
                    Text("\(Int(achievement.progress * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("appTextPrimary"))
                }
                
                ProgressView(value: achievement.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(achievement.color ?? "blue")))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            
            // Progress Details
            HStack {
                Text("\(achievement.current) / \(achievement.target)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color("appTextSecondary"))
                
                Spacer()
                
                if let completedAt = achievement.completedAt {
                    Text("Completed \(completedAt, style: .date)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color("appCardBG"))
        .cornerRadius(16)
    }
}

// MARK: - Category Filter Button
struct CategoryFilterButton: View {
    let category: AchievementCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color("appPrimaryAccent") : Color.clear)
                .foregroundColor(isSelected ? .white : Color("appTextPrimary"))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color("appPrimaryAccent"), lineWidth: isSelected ? 0 : 1)
                )
        }
    }
}

// MARK: - Supporting Types

enum AchievementCategory: String, CaseIterable {
    case all = "All"
    case productivity = "Productivity"
    case focus = "Focus"
    case skills = "Skills"
    case career = "Career"
    case learning = "Learning"
    
    var icon: String {
        switch self {
        case .all: return "trophy.fill"
        case .productivity: return "checkmark.circle.fill"
        case .focus: return "clock.fill"
        case .skills: return "star.fill"
        case .career: return "briefcase.fill"
        case .learning: return "book.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .orange
        case .productivity: return .green
        case .focus: return .blue
        case .skills: return .orange
        case .career: return .purple
        case .learning: return .indigo
        }
    }
    
    var displayName: String {
        self.rawValue
    }
}

#Preview {
    AchievementDetailsView()
} 