//
//  CustomTabBarView.swift
//  TrackEd
//
//  Created by Pradeep Reddy Kumbam on 10/06/2025.
//

import SwiftUI

public struct CustomTabBarView:View {
    @State var selectedTab: Int = 1
    
    let tabItems = [
        (icon: "house", label: "Home", index: 0),
        (icon: "calendar", label: "Planner", index: 1),
        (icon: "bubble.left", label: "Chats", index: 2),
        (icon: "bubble.left.and.bubble.right", label: "Ask AI", index: 3),
        (icon: "person", label: "Profile", index: 4)
    ]
    
    public var body: some View {
        
        VStack(spacing: 0) {
            ZStack {
                // Conditional views
                if selectedTab == 0 { HomeView() }
                else if selectedTab == 1 { PlannerView() }
                else if selectedTab == 2 { ChatsView() }
                else if selectedTab == 3 { AskAIView() }
                else if selectedTab == 4 { ProfileView() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Tab bar
            HStack {
                ForEach(tabItems, id: \.index) { item in
                    TabBarItemView(
                        icon: item.icon,
                        label: item.label,
                        isSelected: selectedTab == item.index,
                        action: {
                            selectedTab = item.index
                        }
                    )
                }
            }
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .ignoresSafeArea(.keyboard)
    }
}
