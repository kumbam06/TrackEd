//
//  OnboardingView.swift
//  TrackEd
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let image: String
    let title: String
    let description: String
}

let onboardingPages = [
    OnboardingPage(image: "sparkles", title: "Welcome to TrackEd!", description: "Your all-in-one productivity, planning, and learning companion."),
    OnboardingPage(image: "note.text", title: "Take Smart Notes", description: "Capture ideas, organize thoughts, and never lose track of important info."),
    OnboardingPage(image: "timer", title: "Focus Sessions", description: "Boost productivity with Pomodoro-style focus sessions and analytics."),
    OnboardingPage(image: "calendar", title: "Plan & Schedule", description: "Organize tasks, set priorities, and manage your time effectively."),
    OnboardingPage(image: "bubble.left.and.bubble.right", title: "Chat & Collaborate", description: "Real-time chat for study groups, project teams, and more."),
    OnboardingPage(image: "chart.bar.xaxis", title: "Track Progress", description: "Visualize your productivity, streaks, and learning journey.")
]

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showAuth = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack {
                Spacer(minLength: 32)
                TabView(selection: $currentPage) {
                    ForEach(Array(onboardingPages.enumerated()), id: \.offset) { index, page in
                        VStack(spacing: 28) {
                            Spacer(minLength: 16)
                            ZStack {
                                Circle()
                                    .fill(Color(.secondarySystemBackground))
                                    .frame(width: 140, height: 140)
                                    .shadow(color: Color.primary.opacity(0.08), radius: 8, x: 0, y: 4)
                                Image(systemName: page.image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.accentColor)
                                    .accessibilityLabel(Text(page.title))
                            }
                            Text(page.title)
                                .font(.largeTitle).fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 8)
                            Text(page.description)
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                            Spacer(minLength: 16)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 380)
                Spacer(minLength: 8)
                HStack(spacing: 8) {
                    ForEach(0..<onboardingPages.count, id: \.self) { i in
                        Circle()
                            .fill(i == currentPage ? Color.accentColor : Color(.systemGray4))
                            .frame(width: i == currentPage ? 12 : 8, height: i == currentPage ? 12 : 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.bottom, 8)
                Button(action: {
                    UserDefaults.standard.set(true, forKey: "didSeeOnboarding")
                    withAnimation { showAuth = true }
                }) {
                    Text(currentPage == onboardingPages.count - 1 ? "Get Started" : "Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(color: Color.accentColor.opacity(0.15), radius: 6, x: 0, y: 3)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 8)
                .accessibilityLabel(Text(currentPage == onboardingPages.count - 1 ? "Get Started" : "Continue"))
                Button(action: {
                    UserDefaults.standard.set(true, forKey: "didSeeOnboarding")
                    withAnimation { showAuth = true }
                }) {
                    Text("Skip")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                        .padding(.vertical, 8)
                }
                .accessibilityLabel(Text("Skip Onboarding"))
                .padding(.bottom, 24)
            }
            .padding(.top, 24)
            .padding(.bottom, 0)
            .padding(.horizontal, 0)
        }
        .transition(.opacity)
        .fullScreenCover(isPresented: $showAuth) {
            AuthView()
        }
    }
} 