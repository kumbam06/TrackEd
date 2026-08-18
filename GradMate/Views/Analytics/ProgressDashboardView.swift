//
//  ProgressDashboardView.swift
//  GradMate
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI

struct ProgressDashboardView: View {
    @EnvironmentObject private var profileManager: ProfileManager
    @EnvironmentObject private var taskManager: TaskManager
    @EnvironmentObject private var skillManager: SkillManager
    @EnvironmentObject private var taskCategoryManager: TaskCategoryManager
    @EnvironmentObject private var progressDataService: ProgressDataService
    @EnvironmentObject private var careerDataService: CareerDataService
    
    @State private var selectedTimeframe: Timeframe = .week
    @State private var showingAchievementDetails = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("appScreenBG")
                    .ignoresSafeArea()
                if isLoading {
                    // Loader is now shown globally
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header with timeframe selector
                            headerSection
                            
                            // Key Metrics Overview
                            keyMetricsSection
                            
                            // Productivity Trends
                            productivityTrendsSection
                            
                            // Career Progress
                            careerProgressSection
                            
                            // Skills Development
                            skillsDevelopmentSection
                            
                            // Recent Achievements
                            recentAchievementsSection
                            
                            // Category Breakdown
                            categoryBreakdownSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Progress Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAchievementDetails = true
                    }) {
                        Image(systemName: "trophy")
                            .foregroundColor(Color("appPrimaryAccent"))
                    }
                }
            }
            .sheet(isPresented: $showingAchievementDetails) {
                AchievementDetailsView()
                    .environmentObject(progressDataService)
            }
            .onAppear {
                refreshAchievementProgress()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("YOUR PROGRESS")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color("appTextPrimary"))
                    
                    Text("Track your journey to success")
                        .font(.subheadline)
                        .foregroundColor(Color("appTextSecondary"))
                }
                
                Spacer()
                
                // Timeframe Selector
                Picker("Timeframe", selection: $selectedTimeframe) {
                    ForEach(Timeframe.allCases, id: \.self) { timeframe in
                        Text(timeframe.displayName).tag(timeframe)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            // Progress Summary Card
            HStack(spacing: 20) {
                ProgressSummaryCard(
                    title: "Productivity Score",
                    value: "\(calculateProductivityScore())",
                    subtitle: "out of 100",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                )
                
                ProgressSummaryCard(
                    title: "Career Progress",
                    value: "\(calculateCareerProgress())",
                    subtitle: "% complete",
                    icon: "briefcase.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color("appCardBG"))
        .cornerRadius(16)
    }
    
    // MARK: - Key Metrics Section
    private var keyMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("KEY METRICS")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color("appTextPrimary"))
                .kerning(1.5)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                MetricCard(
                    title: "Tasks Completed",
                    value: "\(getCompletedTasksCount())",
                    change: "+12%",
                    isPositive: true,
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                MetricCard(
                    title: "Skills Mastered",
                    value: "\(getMasteredSkillsCount())",
                    change: "+2",
                    isPositive: true,
                    icon: "star.fill",
                    color: .orange
                )
                
                MetricCard(
                    title: "Projects",
                    value: "\(getProjectsCount())",
                    change: "+1",
                    isPositive: true,
                    icon: "folder.fill",
                    color: .purple
                )
                
                MetricCard(
                    title: "Certifications",
                    value: "\(getCertificationsCount())",
                    change: "+1",
                    isPositive: true,
                    icon: "certificate.fill",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color("appCardBG"))
        .cornerRadius(16)
    }
    
    // MARK: - Productivity Trends Section
    private var productivityTrendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PRODUCTIVITY TRENDS")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color("appTextPrimary"))
                .kerning(1.5)
            
            VStack(spacing: 12) {
                // Chart placeholder - in a real app, you'd use Charts framework
                ProductivityChart(data: generateProductivityData())
                    .frame(height: 200)
                
                HStack {
                    LegendItem(color: .blue, label: "Tasks Completed")
                    Spacer()
                    LegendItem(color: .green, label: "Skills Progress")
                }
            }
        }
        .padding()
        .background(Color("appCardBG"))
        .cornerRadius(16)
    }
    
    // MARK: - Career Progress Section
    private var careerProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CAREER PROGRESS")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color("appTextPrimary"))
                .kerning(1.5)
            
            VStack(spacing: 16) {
                ProgressBar(
                    title: "Resume Completion",
                    progress: 0.85,
                    color: .blue
                )
                
                ProgressBar(
                    title: "Portfolio Projects",
                    progress: 0.60,
                    color: .green
                )
                
                ProgressBar(
                    title: "Certifications",
                    progress: 0.40,
                    color: .orange
                )
                
                ProgressBar(
                    title: "Networking",
                    progress: 0.30,
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color("appCardBG"))
        .cornerRadius(16)
    }
    
    // MARK: - Skills Development Section
    private var skillsDevelopmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SKILLS DEVELOPMENT")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color("appTextPrimary"))
                .kerning(1.5)
            
            VStack(spacing: 12) {
                ForEach(Array(skillManager.skills.prefix(5)), id: \.id) { skill in
                    SkillProgressRow(
                        skill: skill,
                        progress: Double(skill.proficiency) / 5.0
                    )
                }
            }
        }
        .padding()
        .background(Color("appCardBG"))
        .cornerRadius(16)
    }
    
    // MARK: - Recent Achievements Section
    private var recentAchievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("RECENT ACHIEVEMENTS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color("appTextPrimary"))
                    .kerning(1.5)
                
                Spacer()
                
                if #available(iOS 16.0, *) {
                    Button("View All") {
                        showingAchievementDetails = true
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("appPrimaryAccent"))
                } else {
                    // Fallback on earlier versions
                }
            }
            
            VStack(spacing: 12) {
                ForEach(getRecentAchievements(), id: \.id) { achievement in
                    DashboardAchievementCard(achievement: achievement)
                }
            }
        }
        .padding()
        .background(Color("appCardBG"))
        .cornerRadius(16)
    }
    
    // MARK: - Category Breakdown Section
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TASK CATEGORY BREAKDOWN")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color("appTextPrimary"))
                .kerning(1.5)
            
            VStack(spacing: 12) {
                ForEach(getCategoryBreakdown(), id: \.category) { breakdown in
                    CategoryBreakdownRow(breakdown: breakdown)
                }
            }
        }
        .padding()
        .background(Color("appCardBG"))
        .cornerRadius(16)
    }
    
    // MARK: - Helper Methods
    private func calculateProductivityScore() -> Int {
        let completedTasks = getCompletedTasksCount()
        let skillsCount = skillManager.skills.count
        let taskScore = min(completedTasks * 5, 40)
        let skillScore = min(skillsCount * 2, 30)
        let careerScore = min(Int(careerDataService.careerCompletionRatio * 30), 30)
        return min(taskScore + skillScore + careerScore, 100)
    }
    
    private func calculateCareerProgress() -> Int {
        Int((careerDataService.careerCompletionRatio * 100).rounded())
    }
    
    private var timeframeStart: Date {
        let calendar = Calendar.current
        let now = Date()
        switch selectedTimeframe {
        case .week:
            return calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .quarter:
            return calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
    }
    
    private func getCompletedTasksCount() -> Int {
        taskManager.tasks.filter { task in
            guard task.completed else { return false }
            let date = task.dueDate ?? task.createdAt ?? Date.distantPast
            return date >= timeframeStart
        }.count
    }
    
    private func getMasteredSkillsCount() -> Int {
        return skillManager.skills.filter { $0.proficiency >= 4 }.count
    }
    
    private func getProjectsCount() -> Int {
        careerDataService.projects.count
    }
    
    private func getCertificationsCount() -> Int {
        careerDataService.certifications.count
    }
    
    private func generateProductivityData() -> [ProductivityDataPoint] {
        let calendar = Calendar.current
        let days: Int
        switch selectedTimeframe {
        case .week: days = 7
        case .month: days = 14
        case .quarter: days = 12
        case .year: days = 12
        }
        
        return (0..<days).reversed().map { offset in
            let date: Date
            if selectedTimeframe == .year || selectedTimeframe == .quarter {
                date = calendar.date(byAdding: .month, value: -offset, to: Date()) ?? Date()
                let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
                let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? date
                let count = taskManager.tasks.filter { task in
                    guard task.completed, let due = task.dueDate ?? task.createdAt else { return false }
                    return due >= monthStart && due < monthEnd
                }.count
                return ProductivityDataPoint(date: monthStart, tasks: count)
            } else {
                date = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: Date())) ?? Date()
                let count = taskManager.tasks.filter { task in
                    guard task.completed else { return false }
                    let due = task.dueDate ?? task.createdAt
                    return due.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                }.count
                return ProductivityDataPoint(date: date, tasks: count)
            }
        }
    }
    
    private func getRecentAchievements() -> [Achievement] {
        let completed = progressDataService.achievements
            .filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
            .prefix(5)
        
        let mapped = completed.map { entity in
            Achievement(
                id: entity.id ?? UUID(),
                title: entity.title ?? "Achievement",
                description: entity.achievementDescription ?? "",
                icon: entity.icon ?? "star.fill",
                color: Color(hex: entity.color ?? "#34C759") ?? .green,
                date: entity.completedAt ?? entity.updatedAt ?? Date()
            )
        }
        return Array(mapped)
    }
    
    private func getCategoryBreakdown() -> [CategoryBreakdown] {
        let categories = taskCategoryManager.categories
        let grouped = Dictionary(grouping: taskManager.tasks) { task -> String in
            if let id = task.categoryId, let match = categories.first(where: { $0.id == id }) {
                return match.name ?? "Uncategorized"
            }
            return "Uncategorized"
        }
        let total = max(taskManager.tasks.count, 1)
        let palette: [Color] = [.blue, .green, .orange, .purple, .red, .teal]
        return grouped.keys.sorted().enumerated().map { index, name in
            let count = grouped[name]?.count ?? 0
            return CategoryBreakdown(
                category: name,
                count: count,
                percentage: Double(count) / Double(total) * 100,
                color: palette[index % palette.count]
            )
        }
    }
    
    private func refreshAchievementProgress() {
        let snapshot = progressDataService.achievements
        let completedThisWeek = taskManager.tasks.filter { $0.completed }.count
        let masteredSkills = getMasteredSkillsCount()
        for achievement in snapshot {
            switch achievement.title {
            case "Task Master":
                progressDataService.updateAchievementProgress(achievement, current: Int32(completedThisWeek))
            case "Skill Builder":
                progressDataService.updateAchievementProgress(achievement, current: Int32(masteredSkills))
            case "Project Pioneer":
                progressDataService.updateAchievementProgress(achievement, current: Int32(careerDataService.projects.count))
            case "Certification Collector":
                progressDataService.updateAchievementProgress(achievement, current: Int32(careerDataService.certifications.count))
            default:
                break
            }
        }
    }
}

// MARK: - Supporting Types and Views

enum Timeframe: String, CaseIterable {
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    case year = "year"
    
    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .quarter: return "Quarter"
        case .year: return "Year"
        }
    }
}

struct ProductivityDataPoint {
    let date: Date
    let tasks: Int
}

struct Achievement: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let color: Color
    let date: Date
}

struct CategoryBreakdown {
    let category: String
    let count: Int
    let percentage: Double
    let color: Color
}

// MARK: - Supporting Views

struct ProgressSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color("appTextPrimary"))
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color("appTextSecondary"))
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(Color("appTextSecondary"))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color("appScreenBG"))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                
                Spacer()
                
                Text(change)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isPositive ? .green : .red)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color("appTextPrimary"))
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color("appTextSecondary"))
        }
        .padding()
        .background(Color("appScreenBG"))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

struct ProductivityChart: View {
    let data: [ProductivityDataPoint]
    
    var body: some View {
        let maxValue = max(data.map(\.tasks).max() ?? 1, 1)
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(data.enumerated()), id: \.offset) { _, point in
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.75))
                        .frame(height: max(4, CGFloat(point.tasks) / CGFloat(maxValue) * 140))
                    Text(shortLabel(for: point.date))
                        .font(.caption2)
                        .foregroundColor(Color("appTextSecondary"))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.top, 8)
    }
    
    private func shortLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.caption)
                .foregroundColor(Color("appTextSecondary"))
        }
    }
}

struct ProgressBar: View {
    let title: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color("appTextPrimary"))
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("appStrokeGray"))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

struct SkillProgressRow: View {
    let skill: SkillEntity
    let progress: Double
    
    var body: some View {
        HStack {
            Text(skill.name ?? "Unknown")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color("appTextPrimary"))
            
            Spacer()
            
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { level in
                    Image(systemName: level <= skill.proficiency ? "star.fill" : "star")
                        .font(.caption2)
                        .foregroundColor(level <= skill.proficiency ? .orange : .gray)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct DashboardAchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(achievement.color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(achievement.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("appTextPrimary"))
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(Color("appTextSecondary"))
            }
            
            Spacer()
            
            Text(achievement.date, style: .date)
                .font(.caption2)
                .foregroundColor(Color("appTextSecondary"))
        }
        .padding()
        .background(Color("appScreenBG"))
        .cornerRadius(12)
    }
}

struct CategoryBreakdownRow: View {
    let breakdown: CategoryBreakdown
    
    var body: some View {
        HStack {
            Circle()
                .fill(breakdown.color)
                .frame(width: 12, height: 12)
            
            Text(breakdown.category)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color("appTextPrimary"))
            
            Spacer()
            
            Text("\(breakdown.count) tasks")
                .font(.caption)
                .foregroundColor(Color("appTextSecondary"))
            
            Text("\(Int(breakdown.percentage))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(breakdown.color)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ProgressDashboardView()
        .environmentObject(ProfileManager())
        .environmentObject(TaskManager())
        .environmentObject(SkillManager())
        .environmentObject(TaskCategoryManager())
        .environmentObject(ProgressDataService())
        .environmentObject(CareerDataService())
} 
