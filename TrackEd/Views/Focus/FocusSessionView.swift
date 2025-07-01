//
//  FocusSessionView.swift
//  TrackEd
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI
import AVFoundation
import Combine

struct FocusSessionView: View {
    @EnvironmentObject private var taskManager: TaskManager
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var focusSessionService: FocusSessionService
    @StateObject private var viewModel: FocusSessionViewModel
    @State private var selectedTask: PlannerTask?
    @State private var showingTaskPicker = false
    @State private var showTaskRequiredAlert = false
    
    init() {
        _viewModel = StateObject(wrappedValue: FocusSessionViewModel(focusSessionService: FocusSessionService()))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 32) {
                    focusHeader5D
                    timerDisplay5D
                    taskInfoSection5D
                    controlButtons
                    progressStats
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingTaskPicker) {
                TaskPickerView(selectedTask: $selectedTask)
            }
        }
    }
    
    private var focusHeader5D: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            VStack(spacing: 4) {
                Text(viewModel.isActive ? "FOCUS MODE" : "READY TO FOCUS")
                    .font(.headline)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .kerning(1)
                Text(viewModel.currentMode.rawValue.uppercased())
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.7))
                    .kerning(0.5)
            }
            Spacer()
            Button(action: { showingTaskPicker = true }) {
                Image(systemName: "list.bullet.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
        }
    }
    
    private var timerDisplay5D: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color(.secondarySystemBackground).opacity(0.3), lineWidth: 12)
                    .frame(width: 280, height: 280)
                Circle()
                    .trim(from: 0, to: viewModel.progress)
                    .stroke(
                        LinearGradient(
                            colors: [.accentColor, .primary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 280, height: 280)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: viewModel.progress)
                    .shadow(color: .accentColor.opacity(0.3), radius: 12, x: 0, y: 0)
                VStack(spacing: 8) {
                    Text(viewModel.timeString)
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                    Text(viewModel.isActive ? "FOCUSING..." : "READY")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.7))
                        .kerning(1)
                }
            }
            if !viewModel.isActive {
                sessionTypeSelector5D
            }
        }
    }
    
    private var sessionTypeSelector5D: some View {
        HStack(spacing: 16) {
            ForEach(FocusMode.allCases, id: \.self) { mode in
                Button(action: { viewModel.setMode(mode) }) {
                    VStack(spacing: 8) {
                        Text(mode.emoji)
                            .font(.title2)
                        Text(mode.rawValue.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(viewModel.currentMode == mode ? .white : .white.opacity(0.7))
                            .kerning(0.5)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(sessionTypeButtonBackground(isSelected: (viewModel.currentMode == mode)))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func sessionTypeButtonBackground(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                isSelected ?
                LinearGradient(colors: [.accentColor, .primary], startPoint: .topLeading, endPoint: .bottomTrailing) :
                LinearGradient(colors: [Color(.secondarySystemBackground), Color(.secondarySystemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
            )
    }
    
    private var taskInfoSection5D: some View {
        VStack(spacing: 16) {
            if let task = selectedTask {
                VStack(spacing: 8) {
                    Text("CURRENT TASK")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.7))
                        .kerning(0.5)
                    Text(task.title ?? "UNTITLED TASK")
                        .font(.headline)
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.separator), lineWidth: 1))
            } else {
                Button(action: { showingTaskPicker = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.accentColor)
                            .shadow(color: .accentColor.opacity(0.18), radius: 8, x: 0, y: 4)
                        Text("SELECT TASK")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var controlButtons: some View {
        HStack(spacing: 32) {
            Button(action: {
                if selectedTask != nil {
                    viewModel.startSession(taskId: selectedTask?.id)
                } else {
                    showTaskRequiredAlert = true
                }
            }) {
                Image(systemName: viewModel.isActive ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)
            }
            .disabled(selectedTask == nil)
            .alert(isPresented: $showTaskRequiredAlert) {
                Alert(title: Text("Select a Task"), message: Text("Please select a task before starting a focus session."), dismissButton: .default(Text("OK")))
            }
            Button(action: {
                viewModel.stopSession()
            }) {
                Image(systemName: "stop.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.red)
            }
        }
    }
    
    private var progressStats: some View {
        HStack(spacing: 24) {
            StatCard5D(
                title: "SESSIONS",
                value: "\(viewModel.todaySessions.count)",
                icon: "timer",
                color: .accentColor
            )
            StatCard5D(
                title: "TOTAL TIME",
                value: String(format: "%02d:%02d", viewModel.todayTotalMinutes / 60, viewModel.todayTotalMinutes % 60),
                icon: "clock",
                color: .accentColor
            )
        }
    }
}

struct StatCard5D: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.7))
                    .kerning(0.5)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.separator), lineWidth: 1))
    }
}

struct TaskPickerView: View {
    @Binding var selectedTask: PlannerTask?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var taskManager: TaskManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("SELECT TASK")
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                        .kerning(1)
                        .padding(.top, 20)
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(taskManager.tasks, id: \.id) { task in
                                TaskRow5D(task: task, isSelected: selectedTask?.id == task.id) {
                                    selectedTask = task
                                    dismiss()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct TaskRow5D: View {
    let task: PlannerTask
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.accentColor : Color.accentColor.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: isSelected ? "checkmark" : "circle")
                        .font(.title3)
                        .foregroundColor(isSelected ? .white : Color.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title ?? "UNTITLED TASK")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .kerning(0.5)
                    
                    if let notes = task.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.separator), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Focus Manager

class FocusManager: ObservableObject {
    @Published var isActive = false
    @Published var isPaused = false
    @Published var currentMode: FocusMode = .pomodoro
    @Published var timeRemaining: TimeInterval = 25 * 60 // 25 minutes
    @Published var todayFocusMinutes: Int = 0
    @Published var currentStreak: Int = 0
    @Published var dailyGoal: Int = 120 // 2 hours
    
    @Published var isBreakPaused = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var totalTime: TimeInterval = 25 * 60
    private var audioPlayer: AVAudioPlayer?
    
    var progress: Double {
        1 - (timeRemaining / totalTime)
    }
    
    var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func setMode(_ mode: FocusMode) {
        currentMode = mode
        switch mode {
        case .pomodoro:
            totalTime = 25 * 60
        case .shortBreak:
            totalTime = 5 * 60
        case .longBreak:
            totalTime = 15 * 60
        }
        timeRemaining = totalTime
    }
    
    func startSession() {
        isActive = true
        isPaused = false
        playStartSound()
    }
    
    func stopSession() {
        isActive = false
        isPaused = false
        timeRemaining = totalTime
        playStopSound()
    }
    
    func togglePause() {
        isPaused.toggle()
        if isPaused {
            playPauseSound()
        } else {
            playResumeSound()
        }
    }
    
    func updateTimer() {
        guard isActive && !isPaused else { return }
        
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            sessionCompleted()
        }
    }
    
    func togglePauseBreak() {
        isBreakPaused.toggle()
        // add sound or behavior if needed
    }
    
    func skipBreak() {
        // Logic to skip break and resume or stop session
        isBreakPaused = false
        // Add any additional logic needed
    }
    
    private func sessionCompleted() {
        isActive = false
        isPaused = false
        timeRemaining = totalTime
        
        // Update stats
        let minutesCompleted = Int(totalTime - timeRemaining) / 60
        todayFocusMinutes += minutesCompleted
        
        playCompletionSound()
    }
    
    private func playStartSound() {
        // Play start sound
    }
    
    private func playStopSound() {
        // Play stop sound
    }
    
    private func playPauseSound() {
        // Play pause sound
    }
    
    private func playResumeSound() {
        // Play resume sound
    }
    
    private func playCompletionSound() {
        // Play completion sound
    }
    
    // MARK: - Computed properties (placeholders)
    
    var completedSessions: Int {
        0 // TODO: Implement logic
    }
    
    var totalTimeString: String {
        "00:00" // TODO: Implement logic
    }
    
    var breakProgress: Double {
        0.5 // TODO: Implement logic
    }
    
    var breakTimeString: String {
        "05:00" // TODO: Implement logic
    }
}

