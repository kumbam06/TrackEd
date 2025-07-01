//
//  AskAIView.swift
//  TrackEd
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI
import Combine

struct AskAIView: View {
    @EnvironmentObject private var taskManager: TaskManager
    @EnvironmentObject private var skillManager: SkillManager
    @EnvironmentObject private var profileManager: ProfileManager
    
    @StateObject private var aiManager: AIManager
    @State private var messageText = ""
    @State private var showingQuickActions = false
    @FocusState private var isTextFieldFocused: Bool
    
    init() {
        let tempTaskManager = TaskManager()
        let tempSkillManager = SkillManager()
        let tempProfileManager = ProfileManager()
        
        _aiManager = StateObject(wrappedValue: AIManager(
            taskManager: tempTaskManager,
            skillManager: tempSkillManager,
            profileManager: tempProfileManager
        ))
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            NavigationView {
                VStack(spacing: 0) {
                    aiHeader5D
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                if aiManager.messages.isEmpty {
                                    welcomeMessage5D
                                }
                                ForEach(aiManager.messages, id: \.id) { message in
                                    AIMessageBubble5D(message: message)
                                        .id(message.id)
                                }
                                if aiManager.isTyping {
                                    TypingIndicator5D()
                                        .id("typing")
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .onChange(of: aiManager.messages.count) {
                            if let lastMessage = aiManager.messages.last {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: aiManager.isTyping) { isTyping in
                            if isTyping {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo("typing", anchor: .bottom)
                                }
                            }
                        }
                    }
                    if aiManager.messages.isEmpty {
                        quickActionsSection5D
                    }
                    messageInputArea5D
                }
                .navigationBarHidden(true)
                .onAppear {
                    updateAIManager()
                }
            }
        }
        .background(.ultraThinMaterial)
    }
    
    private func updateAIManager() {
        aiManager.updateManagers(taskManager: taskManager, skillManager: skillManager, profileManager: profileManager)
    }
    
    private var aiHeader5D: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color(.systemFill).opacity(0.2), radius: 12, x: 0, y: 4)
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(.white)
                        .shadow(color: Color(.systemFill).opacity(0.2), radius: 16, x: 0, y: 0)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("TRACKED AI")
                        .font(.headline)
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                        .kerning(1)
                        .shadow(color: Color(.systemFill).opacity(0.2), radius: 16, x: 0, y: 0)
                    Text("YOUR PERSONAL STUDY ASSISTANT")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.7))
                        .kerning(0.5)
                        .shadow(color: Color(.systemFill).opacity(0.2), radius: 8, x: 0, y: 0)
                }
                Spacer()
                Button(action: { showingQuickActions.toggle() }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color.accentColor)
                        .shadow(color: Color.accentColor.opacity(0.18), radius: 8, x: 0, y: 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            Divider()
                .background(Color(.systemFill).opacity(0.15))
        }
        .background(.ultraThinMaterial)
    }
    
    private var welcomeMessage5D: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color(.systemFill).opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(Color.accentColor)
                    .shadow(color: Color(.systemFill).opacity(0.2), radius: 12, x: 0, y: 0)
            }
            VStack(spacing: 12) {
                Text("HELLO! I'M YOUR AI STUDY ASSISTANT")
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .kerning(1)
                    .multilineTextAlignment(.center)
                Text("I can help you with study planning, code review, career advice, and much more. What would you like to work on today?")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 40)
    }
    
    private var quickActionsSection5D: some View {
        VStack(spacing: 20) {
            Text("QUICK ACTIONS")
                .font(.headline)
                .fontWeight(.heavy)
                .foregroundColor(.white)
                .kerning(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                QuickActionCard5D(
                    icon: "graduationcap.fill",
                    title: "Study Plan",
                    subtitle: "Create a personalized study schedule",
                    color: Color.accentColor
                ) {
                    aiManager.sendMessage("Create a study plan for my current courses and help me organize my learning schedule.")
                }
                
                QuickActionCard5D(
                    icon: "code",
                    title: "Code Review",
                    subtitle: "Get feedback on your code",
                    color: .blue
                ) {
                    aiManager.sendMessage("Can you review my code and suggest improvements?")
                }
                
                QuickActionCard5D(
                    icon: "briefcase.fill",
                    title: "Career Advice",
                    subtitle: "Get guidance on your career path",
                    color: .green
                ) {
                    aiManager.sendMessage("I need career advice for someone in my field. Can you help?")
                }
                
                QuickActionCard5D(
                    icon: "brain.head.profile",
                    title: "Learning Tips",
                    subtitle: "Improve your study techniques",
                    color: .mint
                ) {
                    aiManager.sendMessage("What are some effective study techniques I can use?")
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private var messageInputArea5D: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color(.systemFill).opacity(0.15))
            HStack(spacing: 12) {
                TextField("Ask me anything...", text: $messageText, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($isTextFieldFocused)
                    .lineLimit(1...4)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground).opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .strokeBorder(Color(.systemFill).opacity(0.2), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.white)
                    .onSubmit {
                        sendMessage()
                    }
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(
                                    messageText.isEmpty ? LinearGradient(colors: [Color(.systemBackground).opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing) : LinearGradient(colors: [Color.accentColor, Color(.systemFill)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .shadow(color: Color(.systemFill).opacity(0.2), radius: 4, x: 0, y: 2)
                        )
                }
                .disabled(messageText.isEmpty)
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground).opacity(0.2))
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        aiManager.sendMessage(messageText)
        messageText = ""
    }
}

struct QuickActionCard5D: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                        .shadow(color: Color(.systemFill).opacity(0.2), radius: 8, x: 0, y: 0)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .shadow(color: Color(.systemFill).opacity(0.2), radius: 8, x: 0, y: 0)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .shadow(color: color.opacity(0.18), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AIMessageBubble5D: View {
    let message: AIMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromUser {
                Spacer(minLength: 80)
                VStack(alignment: .trailing, spacing: 6) {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(colors: [Color.accentColor, Color(.systemFill)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .shadow(color: Color(.systemFill).opacity(0.2), radius: 4, x: 0, y: 2)
                        )
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground).opacity(0.3))
                                .shadow(color: Color(.systemFill).opacity(0.08), radius: 4, x: 0, y: 2)
                        )
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer(minLength: 80)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct TypingIndicator5D: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)
                            .scaleEffect(1.0 + 0.3 * sin(animationOffset + Double(index) * 0.5))
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: animationOffset
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground).opacity(0.3))
                        .shadow(color: Color(.systemFill).opacity(0.08), radius: 4, x: 0, y: 2)
                )
            }
            Spacer(minLength: 80)
        }
        .onAppear {
            animationOffset = 1.0
        }
    }
}

// AI Manager for handling AI interactions
class AIManager: ObservableObject {
    @Published var messages: [AIMessage] = []
    @Published var isTyping = false
    
    private var taskManager: TaskManager
    private var skillManager: SkillManager
    private var profileManager: ProfileManager
    
    private let aiService: AIServiceProtocol
    
    init(taskManager: TaskManager, skillManager: SkillManager, profileManager: ProfileManager) {
        // Use MockAIService for development, replace with OpenAIService for production
        self.aiService = MockAIService()
        self.taskManager = taskManager
        self.skillManager = skillManager
        self.profileManager = profileManager
    }
    
    func sendMessage(_ content: String) {
        let userMessage = AIMessage(content: content, isFromUser: true)
        messages.append(userMessage)
        
        isTyping = true
        
        Task {
            do {
                let context = buildAIContext()
                let response = try await aiService.sendMessage(content, context: context)
                
                await MainActor.run {
                    self.isTyping = false
                    let aiMessage = AIMessage(content: response.content, isFromUser: false)
                    self.messages.append(aiMessage)
                    
                    // Handle AI actions
                    self.handleAIActions(response.actions)
                }
            } catch {
                await MainActor.run {
                    self.isTyping = false
                    let errorMessage = AIMessage(content: "I'm sorry, I encountered an error. Please try again.", isFromUser: false)
                    self.messages.append(errorMessage)
                }
            }
        }
    }
    
    private func buildAIContext() -> AIContext {
        let userProfile = AIContext.UserProfile(
            name: profileManager.currentProfile?.name ?? "Student",
            major: nil, // No major in Core Data
            year: nil, // No year in Core Data
            goals: [] // No goals in Core Data
        )
        
        return AIContext(
            userProfile: userProfile,
            currentTasks: taskManager.getTasksForDate(Date()),
            skills: skillManager.skills,
            recentMessages: messages.suffix(5).map { AIMessage(content: $0.content, isFromUser: $0.isFromUser) },
            currentDate: Date()
        )
    }
    
    private func handleAIActions(_ actions: [AIAction]) {
        for action in actions {
            switch action.type {
            case .createTask:
                if let _ = action.data["duration"] as? Int,
                   let _ = action.data["topic"] as? String {
                    // Use TaskManager's public create method
                    taskManager.createTask(title: action.title, dueDate: Date(), isAllDay: false, notes: action.description, priority: 1)
                }
                
            case .addSkill:
                if let category = action.data["category"] as? String {
                    // Use SkillManager's public add method
                    skillManager.addSkill(name: action.title, category: category, description: action.description, proficiency: 1)
                }
                
            case .scheduleStudy:
                // Handle study scheduling
                break
                
            case .setReminder:
                // Handle reminder setting
                break
                
            case .generateReport:
                // Handle report generation
                break
            }
        }
    }
    
    // MARK: - Advanced AI Features
    
    func generateStudyPlan(for courses: [String]) async throws -> StudyPlan {
        return try await aiService.generateStudyPlan(for: courses)
    }
    
    func analyzeCode(_ code: String, language: String) async throws -> CodeAnalysis {
        return try await aiService.analyzeCode(code, language: language)
    }
    
    func generateCareerAdvice(for skills: [String], goal: String) async throws -> CareerAdvice {
        return try await aiService.generateCareerAdvice(for: skills, goal: goal)
    }
    
    func updateManagers(taskManager: TaskManager, skillManager: SkillManager, profileManager: ProfileManager) {
        self.taskManager = taskManager
        self.skillManager = skillManager
        self.profileManager = profileManager
    }
}

// AI Message Model
struct AIMessage: Identifiable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp = Date()
} 