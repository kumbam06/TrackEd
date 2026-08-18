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
    @StateObject private var careerDataService = CareerDataService()
    @StateObject private var focusSessionService = FocusSessionService()
    @StateObject private var progressDataService = ProgressDataService()
    @StateObject private var languageManager = LanguageManager()
    @State private var didSeeOnboarding = UserDefaults.standard.bool(forKey: "didSeeOnboarding")
    @State private var showProfileCompletion = false
    
    init() {
        logToFile("[DEBUG] GradMateApp.init() - Configuring Firebase")
    }
    
    private func logToFile(_ message: String) {
        print(message)
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
                    OnboardingView {
                        UserDefaults.standard.set(true, forKey: "didSeeOnboarding")
                        didSeeOnboarding = true
                    }
                    .environmentObject(authViewModel)
                } else if authViewModel.user == nil {
                    AuthView()
                        .environmentObject(authViewModel)
                } else if showProfileCompletion {
                    ProfileCompletionView()
                        .environmentObject(authViewModel)
                        .environmentObject(profileManager)
                        .onDisappear {
                            showProfileCompletion = false
                        }
                } else {
                    ContentView()
                        .modifier(AppEnvironment(
                            authViewModel: authViewModel,
                            profileManager: profileManager,
                            taskManager: taskManager,
                            skillManager: skillManager,
                            chatService: chatService,
                            homeScreenPreferencesManager: homeScreenPreferencesManager,
                            taskCategoryManager: taskCategoryManager,
                            careerDataService: careerDataService,
                            focusSessionService: focusSessionService,
                            progressDataService: progressDataService,
                            languageManager: languageManager
                        ))
                }
                if authViewModel.isCheckingAuth || authViewModel.isLoading {
                    CustomLoaderOverlay()
                }
            }
            .onAppear {
                let settings = FirestoreSettings()
                settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: FirestoreCacheSizeUnlimited))
                settings.isSSLEnabled = true
                settings.host = "firestore.googleapis.com"
                Firestore.firestore().settings = settings
                logToFile("[DEBUG] GradMateApp - Firestore configured successfully with offline support and timeout settings")
            }
            .onChange(of: authViewModel.user) { user in
                if let user = user {
                    profileManager.loadProfileFromFirestore(uid: user.uid) { profile in
                        if profile == nil || (profile?.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            showProfileCompletion = true
                        }
                    }
                } else {
                    profileManager.clearLocalProfile()
                    showProfileCompletion = false
                }
            }
        }
    }
}

private struct AppEnvironment: ViewModifier {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var profileManager: ProfileManager
    @ObservedObject var taskManager: TaskManager
    @ObservedObject var skillManager: SkillManager
    @ObservedObject var chatService: FirestoreChatService
    @ObservedObject var homeScreenPreferencesManager: HomeScreenPreferencesManager
    @ObservedObject var taskCategoryManager: TaskCategoryManager
    @ObservedObject var careerDataService: CareerDataService
    @ObservedObject var focusSessionService: FocusSessionService
    @ObservedObject var progressDataService: ProgressDataService
    @ObservedObject var languageManager: LanguageManager
    
    func body(content: Content) -> some View {
        content
            .environmentObject(authViewModel)
            .environmentObject(profileManager)
            .environmentObject(taskManager)
            .environmentObject(skillManager)
            .environmentObject(chatService)
            .environmentObject(homeScreenPreferencesManager)
            .environmentObject(taskCategoryManager)
            .environmentObject(careerDataService)
            .environmentObject(focusSessionService)
            .environmentObject(progressDataService)
            .environmentObject(languageManager)
    }
}
