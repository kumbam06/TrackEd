//
//  AIService.swift
//  TrackEd
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import Foundation
import Combine

// MARK: - AI Service Protocol
protocol AIServiceProtocol {
    func sendMessage(_ message: String, context: AIContext) async throws -> AIResponse
    func generateStudyPlan(for courses: [String]) async throws -> StudyPlan
    func analyzeCode(_ code: String, language: String) async throws -> CodeAnalysis
    func generateCareerAdvice(for skills: [String], goal: String) async throws -> CareerAdvice
}

// MARK: - AI Context
struct AIContext {
    let userProfile: UserProfile
    let currentTasks: [PlannerTask]
    let skills: [SkillEntity]
    let recentMessages: [AIMessage]
    let currentDate: Date
    
    struct UserProfile {
        let name: String
        let major: String?
        let year: String?
        let goals: [String]
    }
}

// MARK: - AI Response
struct AIResponse {
    let content: String
    let suggestions: [String]
    let actions: [AIAction]
    let confidence: Double
}

// MARK: - AI Action
struct AIAction {
    let type: AIActionType
    let title: String
    let description: String
    let data: [String: Any]
}

enum AIActionType {
    case createTask
    case addSkill
    case scheduleStudy
    case setReminder
    case generateReport
}

// MARK: - Study Plan
struct StudyPlan {
    let title: String
    let description: String
    let schedule: [StudySession]
    let recommendations: [String]
    let estimatedHours: Int
}

struct StudySession {
    let day: String
    let time: String
    let duration: Int // minutes
    let topic: String
    let method: String
}

// MARK: - Code Analysis
struct CodeAnalysis {
    let score: Int // 1-100
    let feedback: [String]
    let suggestions: [String]
    let bestPractices: [String]
    let improvements: [String]
}

// MARK: - Career Advice
struct CareerAdvice {
    let recommendations: [String]
    let skillGaps: [String]
    let learningPath: [String]
    let resources: [String]
    let timeline: String
}

// MARK: - OpenAI Service Implementation
class OpenAIService: AIServiceProtocol {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func sendMessage(_ message: String, context: AIContext) async throws -> AIResponse {
        let prompt = buildPrompt(message: message, context: context)
        
        let requestBody = OpenAIRequest(
            model: "gpt-4",
            messages: [
                OpenAIMessage(role: "system", content: systemPrompt),
                OpenAIMessage(role: "user", content: prompt)
            ],
            temperature: 0.7,
            max_tokens: 1000
        )
        
        let response = try await makeAPIRequest(requestBody)
        return parseAIResponse(response)
    }
    
    func generateStudyPlan(for courses: [String]) async throws -> StudyPlan {
        let prompt = """
        Create a comprehensive study plan for the following courses: \(courses.joined(separator: ", "))
        
        Please provide:
        1. A weekly schedule
        2. Study methods for each course
        3. Time allocation recommendations
        4. Tips for effective learning
        """
        
        let requestBody = OpenAIRequest(
            model: "gpt-4",
            messages: [
                OpenAIMessage(role: "system", content: "You are an expert academic advisor and study coach."),
                OpenAIMessage(role: "user", content: prompt)
            ],
            temperature: 0.7,
            max_tokens: 1500
        )
        
        let response = try await makeAPIRequest(requestBody)
        return parseStudyPlan(response)
    }
    
    func analyzeCode(_ code: String, language: String) async throws -> CodeAnalysis {
        let prompt = """
        Analyze this \(language) code and provide detailed feedback:
        
        ```\(language)
        \(code)
        ```
        
        Please provide:
        1. Code quality score (1-100)
        2. Specific feedback and suggestions
        3. Best practices recommendations
        4. Potential improvements
        """
        
        let requestBody = OpenAIRequest(
            model: "gpt-4",
            messages: [
                OpenAIMessage(role: "system", content: "You are an expert software engineer and code reviewer."),
                OpenAIMessage(role: "user", content: prompt)
            ],
            temperature: 0.3,
            max_tokens: 1000
        )
        
        let response = try await makeAPIRequest(requestBody)
        return parseCodeAnalysis(response)
    }
    
    func generateCareerAdvice(for skills: [String], goal: String) async throws -> CareerAdvice {
        let prompt = """
        Provide career advice for someone with skills: \(skills.joined(separator: ", "))
        Career goal: \(goal)
        
        Please provide:
        1. Skill gap analysis
        2. Learning path recommendations
        3. Resource suggestions
        4. Timeline for achieving the goal
        """
        
        let requestBody = OpenAIRequest(
            model: "gpt-4",
            messages: [
                OpenAIMessage(role: "system", content: "You are an expert career counselor and professional development coach."),
                OpenAIMessage(role: "user", content: prompt)
            ],
            temperature: 0.7,
            max_tokens: 1200
        )
        
        let response = try await makeAPIRequest(requestBody)
        return parseCareerAdvice(response)
    }
    
    // MARK: - Private Methods
    
    private var systemPrompt: String {
        """
        You are TrackEd AI, a personalized study assistant for students. You help with:
        - Study planning and time management
        - Code review and programming help
        - Career guidance and skill development
        - Academic advice and learning strategies
        
        Always be encouraging, practical, and specific. Provide actionable advice and suggestions.
        When appropriate, suggest creating tasks, adding skills, or scheduling study sessions.
        """
    }
    
    private func buildPrompt(message: String, context: AIContext) -> String {
        """
        User: \(context.userProfile.name)
        Major: \(context.userProfile.major ?? "Not specified")
        Year: \(context.userProfile.year ?? "Not specified")
        Goals: \(context.userProfile.goals.joined(separator: ", "))
        
        Current Tasks: \(context.currentTasks.map { "- \($0.title ?? "")" }.joined(separator: "\n"))
        Skills: \(context.skills.map { "- \($0.name ?? "")" }.joined(separator: "\n"))
        
        User Message: \(message)
        
        Please provide a helpful response considering the user's context, current tasks, and skills.
        """
    }
    
    private func makeAPIRequest(_ requestBody: OpenAIRequest) async throws -> OpenAIResponse {
        guard let url = URL(string: baseURL) else {
            throw AIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIError.apiError("Invalid response")
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(OpenAIResponse.self, from: data)
    }
    
    private func parseAIResponse(_ response: OpenAIResponse) -> AIResponse {
        let content = response.choices.first?.message.content ?? "I'm sorry, I couldn't process your request."
        
        // Parse suggestions and actions from the response
        let suggestions = extractSuggestions(from: content)
        let actions = extractActions(from: content)
        
        return AIResponse(
            content: content,
            suggestions: suggestions,
            actions: actions,
            confidence: 0.9
        )
    }
    
    private func parseStudyPlan(_ response: OpenAIResponse) -> StudyPlan {
        // Parse the study plan from the response
        // This is a simplified implementation
        let sessions = [
            StudySession(day: "Monday", time: "9:00 AM", duration: 60, topic: "Course 1", method: "Active reading"),
            StudySession(day: "Tuesday", time: "2:00 PM", duration: 90, topic: "Course 2", method: "Practice problems")
        ]
        
        return StudyPlan(
            title: "Personalized Study Plan",
            description: response.choices.first?.message.content ?? "",
            schedule: sessions,
            recommendations: ["Use Pomodoro technique", "Review notes daily"],
            estimatedHours: 15
        )
    }
    
    private func parseCodeAnalysis(_ response: OpenAIResponse) -> CodeAnalysis {
        return CodeAnalysis(
            score: 85,
            feedback: ["Good variable naming", "Consider adding comments"],
            suggestions: ["Add error handling", "Optimize the algorithm"],
            bestPractices: ["Follow naming conventions", "Use meaningful variable names"],
            improvements: ["Add input validation", "Consider using guard statements"]
        )
    }
    
    private func parseCareerAdvice(_ response: OpenAIResponse) -> CareerAdvice {
        return CareerAdvice(
            recommendations: ["Focus on practical projects", "Build a portfolio"],
            skillGaps: ["Advanced algorithms", "System design"],
            learningPath: ["Complete online courses", "Build real projects", "Network with professionals"],
            resources: ["Coursera", "LeetCode", "GitHub"],
            timeline: "6-12 months"
        )
    }
    
    private func extractSuggestions(from content: String) -> [String] {
        // Extract suggestions from AI response
        // This is a simplified implementation
        return ["Review your notes daily", "Practice coding regularly", "Set specific goals"]
    }
    
    private func extractActions(from content: String) -> [AIAction] {
        // Extract actionable items from AI response
        // This is a simplified implementation
        return [
            AIAction(
                type: .createTask,
                title: "Create Study Session",
                description: "Schedule a focused study session",
                data: ["duration": 60, "topic": "Current course"]
            )
        ]
    }
}

// MARK: - OpenAI Models
struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double
    let max_tokens: Int
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

// MARK: - AI Error
enum AIError: Error {
    case invalidURL
    case apiError(String)
    case decodingError
    case noAPIKey
}

// MARK: - Mock AI Service (for development)
class MockAIService: AIServiceProtocol {
    func sendMessage(_ message: String, context: AIContext) async throws -> AIResponse {
        // Simulate API delay
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        let response = generateMockResponse(for: message)
        return response
    }
    
    func generateStudyPlan(for courses: [String]) async throws -> StudyPlan {
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        return StudyPlan(
            title: "Personalized Study Plan",
            description: "A comprehensive study plan tailored to your courses and learning style.",
            schedule: [
                StudySession(day: "Monday", time: "9:00 AM", duration: 60, topic: courses.first ?? "Study", method: "Active reading"),
                StudySession(day: "Wednesday", time: "2:00 PM", duration: 90, topic: courses.last ?? "Practice", method: "Problem solving")
            ],
            recommendations: ["Use Pomodoro technique", "Review notes daily", "Practice regularly"],
            estimatedHours: 15
        )
    }
    
    func analyzeCode(_ code: String, language: String) async throws -> CodeAnalysis {
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        return CodeAnalysis(
            score: 85,
            feedback: ["Good variable naming", "Consider adding comments", "Well-structured code"],
            suggestions: ["Add error handling", "Optimize the algorithm", "Consider edge cases"],
            bestPractices: ["Follow naming conventions", "Use meaningful variable names", "Add documentation"],
            improvements: ["Add input validation", "Consider using guard statements", "Implement unit tests"]
        )
    }
    
    func generateCareerAdvice(for skills: [String], goal: String) async throws -> CareerAdvice {
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        return CareerAdvice(
            recommendations: ["Focus on practical projects", "Build a portfolio", "Network with professionals"],
            skillGaps: ["Advanced algorithms", "System design", "Cloud platforms"],
            learningPath: ["Complete online courses", "Build real projects", "Contribute to open source"],
            resources: ["Coursera", "LeetCode", "GitHub", "LinkedIn Learning"],
            timeline: "6-12 months"
        )
    }
    
    private func generateMockResponse(for message: String) -> AIResponse {
        let lowercased = message.lowercased()
        
        if lowercased.contains("study") || lowercased.contains("learn") {
            return AIResponse(
                content: "For effective studying, I recommend using the Pomodoro Technique (25-minute focused sessions with 5-minute breaks), creating mind maps for complex topics, and practicing active recall. Would you like me to create a personalized study schedule for you?",
                suggestions: ["Use Pomodoro technique", "Create mind maps", "Practice active recall"],
                actions: [
                    AIAction(type: .createTask, title: "Create Study Session", description: "Schedule a focused study session", data: ["duration": 25, "method": "Pomodoro"])
                ],
                confidence: 0.9
            )
        } else if lowercased.contains("code") || lowercased.contains("programming") {
            return AIResponse(
                content: "Great question about coding! I suggest starting with small projects, practicing daily, and reviewing your code regularly. Would you like me to analyze any specific code you're working on or suggest some practice exercises?",
                suggestions: ["Start small projects", "Practice daily", "Code review"],
                actions: [
                    AIAction(type: .createTask, title: "Code Practice", description: "Schedule daily coding practice", data: ["duration": 30, "type": "practice"])
                ],
                confidence: 0.9
            )
        } else if lowercased.contains("career") || lowercased.contains("job") {
            return AIResponse(
                content: "For career development, focus on building a strong portfolio, networking, and staying updated with industry trends. I can help you identify the most valuable skills for your target role. What specific area are you interested in?",
                suggestions: ["Build portfolio", "Network", "Stay updated"],
                actions: [
                    AIAction(type: .addSkill, title: "Add Career Skill", description: "Add a new skill to your profile", data: ["category": "Career"])
                ],
                confidence: 0.9
            )
        }
        
        return AIResponse(
            content: "I'd be happy to help you with that! Based on your question, here's what I recommend...",
            suggestions: ["Set specific goals", "Track your progress", "Stay consistent"],
            actions: [],
            confidence: 0.8
        )
    }
} 