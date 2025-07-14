//
//  TaskView.swift
//  GradMate
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI

struct TaskView: View {
    let task: PlannerTask
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var priorityColor: Color {
        switch task.priority {
        case 3: return .red
        case 2: return .orange
        default: return .blue
        }
    }
    
    private var priorityText: String {
        switch task.priority {
        case 3: return "High"
        case 2: return "Medium"
        default: return "Low"
        }
    }
    
    var body: some View {
        CardView {
            HStack(spacing: 12) {
                Button(action: onToggle) {
                    Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(task.completed ? .accentColor : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title ?? "Untitled Task")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .strikethrough(task.completed)
                        .opacity(task.completed ? 0.6 : 1.0)
                    
                    if let dueDate = task.dueDate {
                        HStack(spacing: 8) {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(formatDate(dueDate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if task.isAllDay {
                                Text("All Day")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(Color.accentColor.opacity(0.1))
                                    )
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    
                    if let notes = task.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(priorityText)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(priorityColor.opacity(0.1))
                        )
                        .foregroundColor(priorityColor)
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: task.completed)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = task.isAllDay ? .none : .short
        return formatter.string(from: date)
    }
}

struct TaskRowView: View {
    let task: PlannerTask
    let onToggle: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(task.completed ? .accentColor : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title ?? "Untitled Task")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .strikethrough(task.completed)
                    .opacity(task.completed ? 0.6 : 1.0)
                
                if let dueDate = task.dueDate {
                    Text(formatTime(dueDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if task.priority > 1 {
                Circle()
                    .fill(priorityColor)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.2), value: task.completed)
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case 3: return .red
        case 2: return .orange
        default: return .clear
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
} 