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
    @State private var isChatDetailActive = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabContent(selectedTab: selectedTab, isChatDetailActive: $isChatDetailActive)
            if !isChatDetailActive {
                AdvancedFloatingTabBar(selectedTab: $selectedTab)
                    .padding(.horizontal, 16)
                    .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity),
                                             removal: .move(edge: .bottom).combined(with: .opacity)))
                    .animation(.easeInOut(duration: 0.28), value: isChatDetailActive)
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct TabContent: View {
    @EnvironmentObject private var taskManager: TaskManager
    let selectedTab: Int
    @Binding var isChatDetailActive: Bool
    
    var body: some View {
        if selectedTab == 0 {
            NavigationView {
                HomeView()
            }
        } else if selectedTab == 1 {
            NavigationView {
                PlannerView()
                    .environmentObject(taskManager)
            }
        } else if selectedTab == 2 {
            NavigationView {
                ChatListView(isChatDetailActive: $isChatDetailActive)
            }
        } else if selectedTab == 3 {
            NavigationView {
                ProfileView()
            }
        } else {
            NavigationView {
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
