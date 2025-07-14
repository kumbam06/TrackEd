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
    @StateObject private var progressDataService = ProgressDataService()
    @StateObject private var careerDataService = CareerDataService()
    
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
        
        // Simple scoring algorithm
        let taskScore = min(completedTasks * 5, 40)
        let skillScore = min(skillsCount * 2, 30)
        
        return taskScore + skillScore
    }
    
    private func calculateCareerProgress() -> Int {
        let resumeProgress = 85
        let portfolioProgress = 60
        let certificationProgress = 40
        let networkingProgress = 30
        
        return (resumeProgress + portfolioProgress + certificationProgress + networkingProgress) / 4
    }
    
    private func getCompletedTasksCount() -> Int {
        // TODO: Implement based on selected timeframe
        return 24
    }
    
    private func getMasteredSkillsCount() -> Int {
        return skillManager.skills.filter { $0.proficiency >= 4 }.count
    }
    
    private func getProjectsCount() -> Int {
        // TODO: Get from projects data
        return 3
    }
    
    private func getCertificationsCount() -> Int {
        // TODO: Implement based on selected timeframe
        return 1
    }
    
    private func generateProductivityData() -> [ProductivityDataPoint] {
        // TODO: Generate real data based on selected timeframe
        return [
            ProductivityDataPoint(date: Date().addingTimeInterval(-6*24*60*60), tasks: 4),
            ProductivityDataPoint(date: Date().addingTimeInterval(-5*24*60*60), tasks: 6),
            ProductivityDataPoint(date: Date().addingTimeInterval(-4*24*60*60), tasks: 3),
            ProductivityDataPoint(date: Date().addingTimeInterval(-3*24*60*60), tasks: 8),
            ProductivityDataPoint(date: Date().addingTimeInterval(-2*24*60*60), tasks: 5),
            ProductivityDataPoint(date: Date().addingTimeInterval(-1*24*60*60), tasks: 7),
            ProductivityDataPoint(date: Date(), tasks: 6)
        ]
    }
    
    private func getRecentAchievements() -> [Achievement] {
        return [
            Achievement(
                id: UUID(),
                title: "Task Master",
                description: "Completed 20 tasks this week",
                icon: "checkmark.circle.fill",
                color: .green,
                date: Date()
            ),
            Achievement(
                id: UUID(),
                title: "Skill Builder",
                description: "Mastered 3 new skills",
                icon: "star.fill",
                color: .orange,
                date: Date().addingTimeInterval(-24*60*60)
            ),
            Achievement(
                id: UUID(),
                title: "Project Champion",
                description: "Completed 2 major projects",
                icon: "folder.fill",
                color: .purple,
                date: Date().addingTimeInterval(-2*24*60*60)
            )
        ]
    }
    
    private func getCategoryBreakdown() -> [CategoryBreakdown] {
        return [
            CategoryBreakdown(category: "Academic", count: 12, percentage: 40, color: .blue),
            CategoryBreakdown(category: "Career", count: 8, percentage: 27, color: .green),
            CategoryBreakdown(category: "Personal", count: 6, percentage: 20, color: .orange),
            CategoryBreakdown(category: "Health", count: 4, percentage: 13, color: .red)
        ]
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
    }
}

struct ProductivityChart: View {
    let data: [ProductivityDataPoint]
    
    var body: some View {
        VStack {
            // Placeholder for chart - in a real app, use Charts framework
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    Text("Productivity Chart")
                        .font(.caption)
                        .foregroundColor(Color("appTextSecondary"))
                )
        }
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
} 
