//
//  ContentView.swift
//  GradMate
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var profileManager: ProfileManager
    @EnvironmentObject private var taskManager: TaskManager
    @EnvironmentObject private var skillManager: SkillManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            PlannerView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Planner")
                }
            
            ChatListView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Chats")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .accentColor(.accentColor)
    }
}

#Preview {
    ContentView()
        .environmentObject(ProfileManager())
        .environmentObject(TaskManager())
        .environmentObject(SkillManager())
}
