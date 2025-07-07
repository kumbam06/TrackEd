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
            LinearGradient(gradient: Gradient(colors: [Color.accentColor.opacity(0.12), Color(.systemBackground)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack {
                Spacer(minLength: 32)
                TabView(selection: $currentPage) {
                    ForEach(Array(onboardingPages.enumerated()), id: \.offset) { index, page in
                        VStack(spacing: 32) {
                            Spacer(minLength: 16)
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(gradient: Gradient(colors: [Color.accentColor.opacity(0.18), Color(.secondarySystemBackground)]), startPoint: .top, endPoint: .bottom))
                                    .frame(width: 160, height: 160)
                                    .shadow(color: Color.primary.opacity(0.10), radius: 12, x: 0, y: 6)
                                Image(systemName: page.image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 90, height: 90)
                                    .foregroundColor(.accentColor)
                                    .accessibilityLabel(Text(page.title))
                            }
                            Text(page.title)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            Text(page.description)
                                .font(.title2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            Spacer(minLength: 16)
                        }
                        .tag(index)
                        .padding(.horizontal, 8)
                        .animation(.easeInOut, value: currentPage)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 420)
                Spacer(minLength: 8)
                HStack(spacing: 8) {
                    ForEach(0..<onboardingPages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? Color.accentColor : Color(.systemGray4))
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, 8)
                HStack {
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation { currentPage -= 1 }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.headline)
                                .foregroundColor(.accentColor)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel(Text("Back"))
                    } else {
                        Spacer().frame(width: 44)
                    }
                    Button(action: {
                        if currentPage == onboardingPages.count - 1 {
                            UserDefaults.standard.set(true, forKey: "didSeeOnboarding")
                            withAnimation { showAuth = true }
                        } else {
                            withAnimation { currentPage += 1 }
                        }
                    }) {
                        Text(currentPage == onboardingPages.count - 1 ? "Get Started" : "Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: Color.accentColor.opacity(0.18), radius: 8, x: 0, y: 4)
                    }
                    .accessibilityLabel(Text(currentPage == onboardingPages.count - 1 ? "Get Started" : "Continue"))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 8)
                Button(action: {
                    UserDefaults.standard.set(true, forKey: "didSeeOnboarding")
                    withAnimation { showAuth = true }
                }) {
                    Text("Skip")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                        .padding(.vertical, 8)
                        .opacity(0.7)
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