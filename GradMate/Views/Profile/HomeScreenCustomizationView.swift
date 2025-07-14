//
//  HomeScreenCustomizationView.swift
//  GradMate
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI

struct HomeScreenCustomizationView: View {
    @EnvironmentObject private var preferencesManager: HomeScreenPreferencesManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 32) {
                        headerSection
                        sectionsCustomization
                        careerFeaturesCustomization
                        progressDashboardCustomization
                        statsCustomization
                        quickActionsCustomization
                        resetSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Customize Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("PERSONALIZE YOUR DASHBOARD")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .kerning(1.5)
            
            Text("Choose what you want to see on your home screen. You can always change these settings later.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 24)
        .background(Color(.systemGray6))
        .cornerRadius(20)
    }
    
    // MARK: - Sections Customization
    private var sectionsCustomization: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("MAIN SECTIONS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .kerning(1.5)
                
                Spacer()
                
                Rectangle()
                    .fill(Color.primary)
                    .frame(height: 2)
                    .frame(width: 80)
            }
            .padding(.leading, 4)
            
            VStack(spacing: 0) {
                CustomizationRow(
                    title: "Welcome Section",
                    subtitle: "Personalized greeting with your name",
                    icon: "person.circle",
                    isEnabled: $preferencesManager.preferences.showWelcomeSection
                )
                
                Divider()
                    .padding(.leading, 56)
                
                CustomizationRow(
                    title: "Today's Focus",
                    subtitle: "Today's task progress and focus",
                    icon: "target",
                    isEnabled: $preferencesManager.preferences.showTodayFocus
                )
                
                Divider()
                    .padding(.leading, 56)
                
                CustomizationRow(
                    title: "Motivational Quote",
                    subtitle: "Daily motivational message",
                    icon: "quote.bubble",
                    isEnabled: $preferencesManager.preferences.showMotivationalQuote
                )
            }
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Career Features Customization
    private var careerFeaturesCustomization: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("CAREER FEATURES")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .kerning(1.5)
                
                Spacer()
                
                Rectangle()
                    .fill(Color.primary)
                    .frame(height: 2)
                    .frame(width: 100)
            }
            .padding(.leading, 4)
            
            VStack(spacing: 0) {
                CustomizationRow(
                    title: "Career Overview",
                    subtitle: "Summary of your career progress",
                    icon: "briefcase",
                    isEnabled: $preferencesManager.preferences.showCareerOverview
                )
                
                Divider()
                    .padding(.leading, 56)
                
                CustomizationRow(
                    title: "Recent Projects",
                    subtitle: "Your latest projects",
                    icon: "folder",
                    isEnabled: $preferencesManager.preferences.showRecentProjects
                )
                
                Divider()
                    .padding(.leading, 56)
                
                CustomizationRow(
                    title: "Recent Internships",
                    subtitle: "Your recent internships",
                    icon: "graduationcap",
                    isEnabled: $preferencesManager.preferences.showRecentInternships
                )
                
                Divider()
                    .padding(.leading, 56)
                
                CustomizationRow(
                    title: "Recent Certifications",
                    subtitle: "Your latest certifications",
                    icon: "trophy",
                    isEnabled: $preferencesManager.preferences.showRecentCertifications
                )
                
                Divider()
                    .padding(.leading, 56)
                
                CustomizationRow(
                    title: "Recent Work Experience",
                    subtitle: "Your recent work experience",
                    icon: "building.2",
                    isEnabled: $preferencesManager.preferences.showRecentWorkExperience
                )
            }
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Progress Dashboard Customization
    private var progressDashboardCustomization: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("PROGRESS DASHBOARD")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .kerning(1.5)
                
                Spacer()
                
                Rectangle()
                    .fill(Color.primary)
                    .frame(height: 2)
                    .frame(width: 100)
            }
            .padding(.leading, 4)
            
            VStack(spacing: 0) {
                CustomizationRow(
                    title: "Progress Overview",
                    subtitle: "Overall progress overview",
                    icon: "chart.bar.fill",
                    isEnabled: $preferencesManager.preferences.showProgressOverview
                )
                
                Divider()
                    .padding(.leading, 56)
                
                CustomizationRow(
                    title: "Productivity Trends",
                    subtitle: "Your productivity trends",
                    icon: "flame.fill",
                    isEnabled: $preferencesManager.preferences.showProductivityTrends
                )
                
                Divider()
                    .padding(.leading, 56)
                
                CustomizationRow(
                    title: "Career Progress",
                    subtitle: "Your career development progress",
                    icon: "briefcase.fill",
                    isEnabled: $preferencesManager.preferences.showCareerProgress
                )
                
                Divider()
                    .padding(.leading, 56)
                
                CustomizationRow(
                    title: "Skills Development",
                    subtitle: "Your skills development progress",
                    icon: "star.circle",
                    isEnabled: $preferencesManager.preferences.showSkillsDevelopment
                )
                
                Divider()
                    .padding(.leading, 56)
                
                CustomizationRow(
                    title: "Recent Achievements",
                    subtitle: "Your recent achievements",
                    icon: "medal.fill",
                    isEnabled: $preferencesManager.preferences.showRecentAchievements
                )
            }
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Stats Customization
    private var statsCustomization: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("PRODUCTIVITY STATS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .kerning(1.5)
                
                Spacer()
                
                Rectangle()
                    .fill(Color.primary)
                    .frame(height: 2)
                    .frame(width: 100)
            }
            .padding(.leading, 4)
            
            VStack(spacing: 0) {
                CustomizationRow(
                    title: "Tasks Completed",
                    subtitle: "Number of completed tasks",
                    icon: "checkmark.seal",
                    isEnabled: $preferencesManager.preferences.showTasksCompleted
                )
                
                Divider()
                    .padding(.leading, 56)
                
                CustomizationRow(
                    title: "Streak",
                    subtitle: "Current productivity streak",
                    icon: "flame",
                    isEnabled: $preferencesManager.preferences.showStreak
                )
                
                Divider()
                    .padding(.leading, 56)
                
                CustomizationRow(
                    title: "Focus Hours",
                    subtitle: "Total focus time today",
                    icon: "clock",
                    isEnabled: $preferencesManager.preferences.showFocusHours
                )
                
                Divider()
                    .padding(.leading, 56)
                
                CustomizationRow(
                    title: "Skills Count",
                    subtitle: "Number of skills mastered",
                    icon: "star",
                    isEnabled: $preferencesManager.preferences.showSkillsCount
                )
            }
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Quick Actions Customization
    private var quickActionsCustomization: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("QUICK ACTIONS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .kerning(1.5)
                
                Spacer()
                
                Rectangle()
                    .fill(Color.primary)
                    .frame(height: 2)
                    .frame(width: 70)
            }
            .padding(.leading, 4)
            
            VStack(spacing: 0) {
                CustomizationRow(
                    title: "Add Task",
                    subtitle: "Create a new task",
                    icon: "plus",
                    isEnabled: $preferencesManager.preferences.showAddTaskAction
                )
                
                Divider()
                    .padding(.leading, 56)
                
                CustomizationRow(
                    title: "Ask AI",
                    subtitle: "Get AI assistance",
                    icon: "brain.head.profile",
                    isEnabled: $preferencesManager.preferences.showAskAIAction
                )
                
                Divider()
                    .padding(.leading, 56)
                
                CustomizationRow(
                    title: "Focus",
                    subtitle: "Start focus session",
                    icon: "timer",
                    isEnabled: $preferencesManager.preferences.showFocusAction
                )
                
                Divider()
                    .padding(.leading, 56)
                
                CustomizationRow(
                    title: "Notes",
                    subtitle: "View your notes",
                    icon: "note.text",
                    isEnabled: $preferencesManager.preferences.showNotesAction
                )
            }
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Reset Section
    private var resetSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                preferencesManager.resetToDefaults()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                    Text("RESET TO DEFAULTS")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("This will restore all sections to their default visibility")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Supporting Views

struct CustomizationRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
    }
} 