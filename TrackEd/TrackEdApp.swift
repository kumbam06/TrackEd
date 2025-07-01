//
//  TrackEdApp.swift
//  TrackEd
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI
import CoreData
import Firebase

@main
struct TrackEdApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var profileManager = ProfileManager()
    @StateObject private var taskManager = TaskManager()
    @StateObject private var skillManager = SkillManager()
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var chatService = FirestoreChatService()
    @StateObject private var homeScreenPreferencesManager = HomeScreenPreferencesManager()
    @StateObject private var taskCategoryManager = TaskCategoryManager()
    @State private var didSeeOnboarding = UserDefaults.standard.bool(forKey: "didSeeOnboarding")
    
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            if authViewModel.isCheckingAuth {
                SplashView()
            } else if !didSeeOnboarding {
                OnboardingView()
                    .environmentObject(authViewModel)
                    .onDisappear {
                        didSeeOnboarding = true
                    }
            } else if authViewModel.user == nil {
                AuthView()
                    .environmentObject(authViewModel)
            } else {
                ContentView()
                    .environmentObject(authViewModel)
                    .environmentObject(profileManager)
                    .environmentObject(taskManager)
                    .environmentObject(skillManager)
                    .environmentObject(chatService)
                    .environmentObject(homeScreenPreferencesManager)
                    .environmentObject(taskCategoryManager)
            }
        }
    }
}
