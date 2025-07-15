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
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabContent(selectedTab: selectedTab)
            AdvancedFloatingTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 16)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct TabContent: View {
    @EnvironmentObject private var taskManager: TaskManager
    let selectedTab: Int
    
    var body: some View {
        if selectedTab == 0 {
            NavigationStack {
                HomeView()
            }
        } else if selectedTab == 1 {
            NavigationStack {
                PlannerView()
                    .environmentObject(taskManager)
            }
        } else if selectedTab == 2 {
            NavigationStack {
                ChatListView()
            }
        } else if selectedTab == 3 {
            NavigationStack {
                ProfileView()
            }
        } else {
            NavigationStack {
                HomeView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ProfileManager())
        .environmentObject(TaskManager())
        .environmentObject(SkillManager())
}
