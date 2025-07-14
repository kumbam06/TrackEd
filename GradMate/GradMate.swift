//
//  GradMateApp.swift
//  GradMate
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI
import CoreData
import Firebase
import FirebaseAuth

@main
struct GradMateApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
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
        logToFile("[DEBUG] GradMateApp.init() - Configuring Firebase")
        // FirebaseApp.configure() // Removed to avoid double configuration
        
        // Configure Firestore with better offline support
        // let settings = FirestoreSettings()
        // settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: FirestoreCacheSizeUnlimited))
        // Firestore.firestore().settings = settings
        // logToFile("[DEBUG] GradMateApp.init() - Firebase configured successfully with offline support")
    }
    
    private func logToFile(_ message: String) {
        print(message)
        // Also write to a file for debugging when running directly
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let logFile = documentsPath.appendingPathComponent("debug.log")
            let timestamp = DateFormatter().string(from: Date())
            let logMessage = "[\(timestamp)] \(message)\n"
            
            if let data = logMessage.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: logFile.path) {
                    if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                        fileHandle.closeFile()
                    }
                } else {
                    try? data.write(to: logFile)
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if !didSeeOnboarding {
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
                // Custom loader overlay
                if authViewModel.isCheckingAuth || authViewModel.isLoading {
                    CustomLoaderOverlay()
                }
            }
            .onAppear {
                // Setup auth listener after Firebase is configured
                authViewModel.setupAuthListener()
                
                // Configure Firestore with better offline support
                let settings = FirestoreSettings()
                settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: FirestoreCacheSizeUnlimited))
                Firestore.firestore().settings = settings
                logToFile("[DEBUG] GradMateApp - Firestore configured successfully with offline support")
            }
            .onChange(of: authViewModel.user) { oldValue, user in
                if let user = user {
                    profileManager.loadProfileFromFirestore(uid: user.uid)
                } else {
                    profileManager.clearLocalProfile()
                }
            }
        }
    }
}
