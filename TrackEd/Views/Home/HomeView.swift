//
//  HomeView.swift
//  TrackEd
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI
import Combine

struct HomeView: View {
    @EnvironmentObject private var profileManager: ProfileManager
    @EnvironmentObject private var taskManager: TaskManager
    @EnvironmentObject private var skillManager: SkillManager
    @EnvironmentObject private var preferencesManager: HomeScreenPreferencesManager
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var todayTasks: [PlannerTask] = []
    @State private var showAddTask = false
    
    private var timeOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<22: return "evening"
        default: return "night"
        }
    }
    
    private var todayCompletedCount: Int {
        todayTasks.filter { $0.completed }.count
    }
    
    private var todayProgress: Double {
        guard !todayTasks.isEmpty else { return 0.0 }
        return Double(todayCompletedCount) / Double(todayTasks.count)
    }
    
    private var streak: String {
        let calendar = Calendar.current
        var streakCount = 0
        var date = Date()
        while true {
            let completed = taskManager.tasks.contains { task in
                (task.completed) && (task.dueDate != nil ? calendar.isDate(task.dueDate!, inSameDayAs: date) : false)
            }
            if completed {
                streakCount += 1
                date = calendar.date(byAdding: .day, value: -1, to: date) ?? date
            } else {
                break
            }
        }
        return "\(streakCount)d"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Welcome Section
                    if preferencesManager.preferences.showWelcomeSection {
                        welcomeSection
                    }
                    
                    // Today's Progress
                    if preferencesManager.preferences.showTodayFocus {
                        todayProgressSection
                    }
                    
                    // Quick Stats
                    if preferencesManager.preferences.showProductivityStats {
                        quickStatsSection
                    }
                    
                    // Today's Tasks
                    todayTasksSection
                    
                    // Skills Overview
                    if preferencesManager.preferences.showSkillsOverview {
                        skillsOverviewSection
                    }
                    
                    // Career Overview
                    if preferencesManager.preferences.showCareerOverview {
                        careerOverviewSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("TrackEd")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddTask = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .onAppear {
                loadTodayTasks()
            }
            .sheet(isPresented: $showAddTask) {
                AddTaskView { title, notes, dueDate, isAllDay, priority in
                    taskManager.createTask(
                        title: title.isEmpty ? "Untitled Task" : title,
                        dueDate: dueDate,
                        isAllDay: isAllDay,
                        notes: notes,
                        priority: priority
                    )
                    loadTodayTasks()
                }
                .environmentObject(taskManager)
            }
        }
    }
    
    // MARK: - Welcome Section
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greetingText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text(firstName(profileManager.currentProfile?.name ?? "Student"))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                Spacer()
                
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.accentColor.opacity(0.2), lineWidth: 8)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: todayProgress)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 60, height: 60)
                    
                    Text("\(Int(todayProgress * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                }
            }
            
            if preferencesManager.preferences.showMotivationalQuote {
                Text(motivationalQuote)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Today's Progress Section
    private var todayProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                StatCard(
                    title: "Tasks",
                    value: "\(todayCompletedCount)/\(todayTasks.count)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Streak",
                    value: streak,
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Skills",
                    value: "\(skillManager.skills.count)",
                    icon: "star.fill",
                    color: .blue
                )
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Stats")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickStatCard(
                    title: "Total Tasks",
                    value: "\(taskManager.tasks.count)",
                    icon: "list.bullet",
                    color: .blue
                )
                
                QuickStatCard(
                    title: "Completed",
                    value: "\(taskManager.tasks.filter { $0.completed }.count)",
                    icon: "checkmark.circle",
                    color: .green
                )
                
                QuickStatCard(
                    title: "Due Today",
                    value: "\(todayTasks.count)",
                    icon: "calendar",
                    color: .orange
                )
                
                QuickStatCard(
                    title: "High Priority",
                    value: "\(taskManager.tasks.filter { $0.priority == 3 }.count)",
                    icon: "exclamationmark.triangle",
                    color: .red
                )
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Today's Tasks Section
    private var todayTasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Tasks")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to Planner
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }
            
            if todayTasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    
                    Text("No tasks for today!")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text("Great job! All tasks are completed.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(todayTasks.prefix(5), id: \.id) { task in
                        TaskRowView(task: task) {
                            taskManager.toggleTaskCompletion(task)
                            loadTodayTasks()
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Skills Overview Section
    private var skillsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Career Skills")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Manage") {
                    // Navigate to Profile
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }
            
            if skillManager.skills.isEmpty {
                VStack(spacing: 8) {
                    Text("No skills added yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Add skills to build your career profile")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(skillManager.skills.prefix(3)), id: \.id) { skill in
                        SkillRowView(skill: skill)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Career Overview Section
    private var careerOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Career Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ProgressRow(title: "Resume", progress: 0.8, color: .blue)
                ProgressRow(title: "Portfolio", progress: 0.6, color: .green)
                ProgressRow(title: "Certifications", progress: 0.4, color: .orange)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    private func loadTodayTasks() {
        todayTasks = taskManager.getTodayTasks()
    }
    
    private func firstName(_ fullName: String) -> String {
        fullName.split(separator: " ").first.map(String.init) ?? fullName
    }
    
    private var greetingText: String {
        switch timeOfDay.lowercased() {
        case "morning": return "Good Morning"
        case "afternoon": return "Good Afternoon"
        case "evening": return "Good Evening"
        default: return "Good Night"
        }
    }
    
    private var motivationalQuote: String {
        [
            "Every day is a new opportunity to grow.",
            "Small steps lead to big achievements.",
            "Stay curious. Stay productive.",
            "Your future is created by what you do today."
        ].randomElement() ?? "Stay motivated!"
    }
}

// MARK: - Supporting Views
struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SkillRowView: View {
    let skill: SkillEntity
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(skill.name ?? "Unknown Skill")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(skill.category ?? "General")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: index < Int(skill.proficiency) ? "star.fill" : "star")
                        .font(.caption)
                        .foregroundColor(index < Int(skill.proficiency) ? .yellow : .gray)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct ProgressRow: View {
    let title: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
        }
    }
} 

