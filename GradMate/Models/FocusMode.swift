import Foundation

public enum FocusMode: String, CaseIterable {
    case pomodoro = "Pomodoro"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
    
    public var emoji: String {
        switch self {
        case .pomodoro: return "🍅"
        case .shortBreak: return "☕️"
        case .longBreak: return "��"
        }
    }
} 