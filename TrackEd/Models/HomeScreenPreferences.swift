//
//  HomeScreenPreferences.swift
//  TrackEd
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import Foundation
import SwiftUI
import Combine

struct HomeScreenPreferences: Codable {
    var showWelcomeSection: Bool = true
    var showProductivityStats: Bool = true
    var showSkillsOverview: Bool = true
    var showQuickActions: Bool = true
    var showTodayFocus: Bool = true
    var showMotivationalQuote: Bool = true
    
    // Career features
    var showCareerOverview: Bool = true
    var showRecentProjects: Bool = true
    var showRecentInternships: Bool = true
    var showRecentCertifications: Bool = true
    var showRecentWorkExperience: Bool = true
    
    // Progress dashboard
    var showProgressOverview: Bool = true
    var showProductivityTrends: Bool = true
    var showCareerProgress: Bool = true
    var showSkillsDevelopment: Bool = true
    var showRecentAchievements: Bool = true
    
    // Customizable stats
    var showTasksCompleted: Bool = true
    var showStreak: Bool = true
    var showFocusHours: Bool = true
    var showSkillsCount: Bool = true
    
    // Quick actions customization
    var showAddTaskAction: Bool = true
    var showAskAIAction: Bool = true
    var showFocusAction: Bool = true
    var showNotesAction: Bool = true
}

class HomeScreenPreferencesManager: ObservableObject {
    @Published var preferences: HomeScreenPreferences {
        didSet {
            savePreferences()
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private let preferencesKey = "HomeScreenPreferences"
    
    init() {
        if let data = userDefaults.data(forKey: preferencesKey),
           let savedPreferences = try? JSONDecoder().decode(HomeScreenPreferences.self, from: data) {
            self.preferences = savedPreferences
        } else {
            self.preferences = HomeScreenPreferences()
        }
    }
    
    private func savePreferences() {
        if let encoded = try? JSONEncoder().encode(preferences) {
            userDefaults.set(encoded, forKey: preferencesKey)
        }
    }
    
    func resetToDefaults() {
        preferences = HomeScreenPreferences()
    }
}

// MARK: - Home Screen Section Identifiers
enum HomeScreenSection: String, CaseIterable {
    case welcome = "Welcome Section"
    case productivityStats = "Productivity Stats"
    case skillsOverview = "Skills Overview"
    case quickActions = "Quick Actions"
    case todayFocus = "Today's Focus"
    case motivationalQuote = "Motivational Quote"
    case careerOverview = "Career Overview"
    case recentProjects = "Recent Projects"
    case recentInternships = "Recent Internships"
    case recentCertifications = "Recent Certifications"
    case recentWorkExperience = "Recent Work Experience"
    case progressOverview = "Progress Overview"
    case productivityTrends = "Productivity Trends"
    case careerProgress = "Career Progress"
    case skillsDevelopment = "Skills Development"
    case recentAchievements = "Recent Achievements"
    
    var icon: String {
        switch self {
        case .welcome: return "person.circle"
        case .productivityStats: return "chart.bar"
        case .skillsOverview: return "star"
        case .quickActions: return "bolt"
        case .todayFocus: return "target"
        case .motivationalQuote: return "quote.bubble"
        case .careerOverview: return "briefcase"
        case .recentProjects: return "folder"
        case .recentInternships: return "graduationcap"
        case .recentCertifications: return "trophy"
        case .recentWorkExperience: return "building.2"
        case .progressOverview: return "chart.bar.fill"
        case .productivityTrends: return "flame.fill"
        case .careerProgress: return "briefcase.fill"
        case .skillsDevelopment: return "star.circle"
        case .recentAchievements: return "medal.fill"
        }
    }
    
    var description: String {
        switch self {
        case .welcome: return "Personalized greeting with your name"
        case .productivityStats: return "Your daily productivity metrics"
        case .skillsOverview: return "Your skills and achievements"
        case .quickActions: return "Quick access to main features"
        case .todayFocus: return "Today's task progress and focus"
        case .motivationalQuote: return "Daily motivational message"
        case .careerOverview: return "Summary of your career progress"
        case .recentProjects: return "Your latest projects"
        case .recentInternships: return "Your recent internships"
        case .recentCertifications: return "Your latest certifications"
        case .recentWorkExperience: return "Your recent work experience"
        case .progressOverview: return "Progress Overview"
        case .productivityTrends: return "Productivity Trends"
        case .careerProgress: return "Career Progress"
        case .skillsDevelopment: return "Skills Development"
        case .recentAchievements: return "Recent Achievements"
        }
    }
}

// MARK: - Stat Item Identifiers
enum StatItem: String, CaseIterable {
    case tasksCompleted = "Tasks Completed"
    case streak = "Streak"
    case focusHours = "Focus Hours"
    case skillsCount = "Skills Count"
    
    var icon: String {
        switch self {
        case .tasksCompleted: return "checkmark.seal"
        case .streak: return "flame"
        case .focusHours: return "clock"
        case .skillsCount: return "star"
        }
    }
    
    var description: String {
        switch self {
        case .tasksCompleted: return "Number of completed tasks"
        case .streak: return "Current productivity streak"
        case .focusHours: return "Total focus time today"
        case .skillsCount: return "Number of skills mastered"
        }
    }
}

// MARK: - Quick Action Identifiers
enum HomeQuickAction: String, CaseIterable {
    case addTask = "Add Task"
    case askAI = "Ask AI"
    case focus = "Focus"
    case notes = "Notes"
    
    var icon: String {
        switch self {
        case .addTask: return "plus"
        case .askAI: return "brain.head.profile"
        case .focus: return "timer"
        case .notes: return "note.text"
        }
    }
    
    var description: String {
        switch self {
        case .addTask: return "Create a new task"
        case .askAI: return "Get AI assistance"
        case .focus: return "Start focus session"
        case .notes: return "View your notes"
        }
    }
} 