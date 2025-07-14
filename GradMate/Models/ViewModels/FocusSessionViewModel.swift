import Foundation
import Combine
import SwiftUI
import AVFoundation

class FocusSessionViewModel: ObservableObject {
    // Session data
    @Published var todaySessions: [FocusSessionEntity] = []
    @Published var todayTotalMinutes: Int = 0
    @Published var isLoading = false
    @Published var error: String?
    
    // Timer and focus mode state
    @Published var isActive = false
    @Published var isPaused = false
    @Published var currentMode: FocusMode = .pomodoro
    @Published var timeRemaining: TimeInterval = 25 * 60 // 25 minutes default
    private var totalTime: TimeInterval { // depends on mode
        switch currentMode {
        case .pomodoro: return 25 * 60
        case .shortBreak: return 5 * 60
        case .longBreak: return 15 * 60
        }
    }
    private var timerCancellable: AnyCancellable?
    
    private let focusSessionService: FocusSessionServiceProtocol
    private var sessionStartTime: Date?
    private var selectedTaskId: UUID?
    
    init(focusSessionService: FocusSessionServiceProtocol) {
        self.focusSessionService = focusSessionService
        loadTodaySessions()
    }
    
    // MARK: - Timer/Mode Logic
    func setMode(_ mode: FocusMode) {
        currentMode = mode
        timeRemaining = totalTime
    }
    
    func startTimer() {
        isActive = true
        isPaused = false
        timeRemaining = totalTime
        sessionStartTime = Date()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }
    
    func pauseTimer() {
        isPaused.toggle()
    }
    
    func stopTimer() {
        isActive = false
        isPaused = false
        timerCancellable?.cancel()
        timerCancellable = nil
        timeRemaining = totalTime
        sessionStartTime = nil
    }
    
    private func tick() {
        guard isActive, !isPaused else { return }
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            completeSession()
        }
    }
    
    private func completeSession() {
        isActive = false
        isPaused = false
        timerCancellable?.cancel()
        timerCancellable = nil
        let endTime = Date()
        if let start = sessionStartTime {
            focusSessionService.addSession(taskId: selectedTaskId, startTime: start, endTime: endTime) { [weak self] in
                self?.loadTodaySessions()
            }
        }
        sessionStartTime = nil
        timeRemaining = totalTime
    }
    
    // MARK: - Session Data
    func startSession(taskId: UUID?) {
        selectedTaskId = taskId
        setMode(.pomodoro)
        startTimer()
    }
    
    func stopSession() {
        stopTimer()
    }
    
    func loadTodaySessions() {
        isLoading = true
        focusSessionService.getSessions(for: Date()) { [weak self] sessions in
            DispatchQueue.main.async {
                self?.todaySessions = sessions
                self?.todayTotalMinutes = sessions.reduce(0) { $0 + Int($1.duration / 60) }
                self?.isLoading = false
            }
        }
    }
    
    // MARK: - Computed Properties
    var progress: Double {
        1 - (timeRemaining / totalTime)
    }
    var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
} 