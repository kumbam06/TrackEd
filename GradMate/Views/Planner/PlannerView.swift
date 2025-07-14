//
//  PlannerView.swift
//  GradMate
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI

struct PlannerView: View {
    @EnvironmentObject private var taskManager: TaskManager
    @EnvironmentObject private var taskCategoryManager: TaskCategoryManager
    @State private var showAddTask = false
    @State private var selectedFilter: TaskFilter = .all
    @State private var searchText = ""
    
    private var filteredTasks: [PlannerTask] {
        let tasks = taskManager.tasks
        
        let filteredBySearch = searchText.isEmpty ? tasks : tasks.filter { task in
            task.title?.localizedCaseInsensitiveContains(searchText) == true ||
            task.notes?.localizedCaseInsensitiveContains(searchText) == true
        }
        
        switch selectedFilter {
        case .all:
            return filteredBySearch
        case .today:
            return filteredBySearch.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return Calendar.current.isDateInToday(dueDate)
            }
        case .upcoming:
            return filteredBySearch.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return dueDate > Date()
            }
        case .completed:
            return filteredBySearch.filter { $0.completed }
        case .pending:
            return filteredBySearch.filter { !$0.completed }
        }
    }
    
    private var groupedTasks: [(String, [PlannerTask])] {
        let grouped = Dictionary(grouping: filteredTasks) { task in
            if let dueDate = task.dueDate {
                if Calendar.current.isDateInToday(dueDate) {
                    return "Today"
                } else if Calendar.current.isDateInTomorrow(dueDate) {
                    return "Tomorrow"
                } else {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "EEEE, MMM d"
                    return formatter.string(from: dueDate)
                }
            } else {
                return "No Due Date"
            }
        }
        
        return grouped.sorted { first, second in
            let dateOrder = ["Today", "Tomorrow", "No Due Date"]
            let firstIndex = dateOrder.firstIndex(of: first.key) ?? Int.max
            let secondIndex = dateOrder.firstIndex(of: second.key) ?? Int.max
            
            if firstIndex != secondIndex {
                return firstIndex < secondIndex
            }
            
            return first.key < second.key
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                VStack(spacing: 16) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search tasks...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(TaskFilter.allCases, id: \.self) { filter in
                                FilterPill(
                                    title: filter.displayName,
                                    isSelected: selectedFilter == filter,
                                    count: getCount(for: filter)
                                ) {
                                    selectedFilter = filter
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .background(Color(.systemBackground))
                
                // Tasks List
                if filteredTasks.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(groupedTasks, id: \.0) { section, tasks in
                                TaskSectionView(
                                    title: section,
                                    tasks: tasks,
                                    onToggleTask: { task in
                                        taskManager.toggleTaskCompletion(task)
                                    },
                                    onDeleteTask: { task in
                                        taskManager.deleteTask(task)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Planner")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddTask = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showAddTask) {
                AddTaskView { title, notes, dueDate, isAllDay, priority in
                    taskManager.createTask(
                        title: title.isEmpty ? "Untitled Task" : title,
                        dueDate: dueDate,
                        isAllDay: isAllDay,
                        notes: notes,
                        priority: priority
                    )
                }
                .environmentObject(taskManager)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: emptyStateIcon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(emptyStateTitle)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(emptyStateMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: { showAddTask = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Add Your First Task")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    private func getCount(for filter: TaskFilter) -> Int {
        switch filter {
        case .all:
            return taskManager.tasks.count
        case .today:
            return taskManager.tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return Calendar.current.isDateInToday(dueDate)
            }.count
        case .upcoming:
            return taskManager.tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return dueDate > Date()
            }.count
        case .completed:
            return taskManager.tasks.filter { $0.completed }.count
        case .pending:
            return taskManager.tasks.filter { !$0.completed }.count
        }
    }
    
    private var emptyStateIcon: String {
        switch selectedFilter {
        case .all: return "list.bullet"
        case .today: return "calendar"
        case .upcoming: return "clock"
        case .completed: return "checkmark.circle"
        case .pending: return "circle"
        }
    }
    
    private var emptyStateTitle: String {
        switch selectedFilter {
        case .all: return "No Tasks Yet"
        case .today: return "No Tasks for Today"
        case .upcoming: return "No Upcoming Tasks"
        case .completed: return "No Completed Tasks"
        case .pending: return "No Pending Tasks"
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedFilter {
        case .all: return "Start organizing your day by adding your first task."
        case .today: return "You have no tasks scheduled for today. Add some to stay productive!"
        case .upcoming: return "No upcoming tasks found. Plan ahead to stay on track."
        case .completed: return "Complete some tasks to see them here."
        case .pending: return "All your tasks are completed! Great job!"
        }
    }
}

// MARK: - Supporting Views
struct TaskSectionView: View {
    let title: String
    let tasks: [PlannerTask]
    let onToggleTask: (PlannerTask) -> Void
    let onDeleteTask: (PlannerTask) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 8) {
                ForEach(tasks, id: \.id) { task in
                    TaskCardView(
                        task: task,
                        onToggle: { onToggleTask(task) },
                        onDelete: { onDeleteTask(task) }
                    )
                }
            }
        }
    }
}

struct TaskCardView: View {
    let task: PlannerTask
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    private var priorityColor: Color {
        switch task.priority {
        case 1: return .green
        case 2: return .orange
        case 3: return .red
        default: return .gray
        }
    }
    
    private var priorityText: String {
        switch task.priority {
        case 1: return "Low"
        case 2: return "Medium"
        case 3: return "High"
        default: return "None"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(task.completed ? .green : .secondary)
            }
            
            // Task Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(task.title ?? "Untitled Task")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .strikethrough(task.completed)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    // Priority Badge
                    if task.priority > 1 {
                        Text(priorityText)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(priorityColor)
                            .cornerRadius(4)
                    }
                }
                
                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(formatDueDate(dueDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Delete Button
            Button(action: { showingDeleteAlert = true }) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .alert("Delete Task", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("Are you sure you want to delete this task? This action cannot be undone.")
        }
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "Today at h:mm a"
        } else if Calendar.current.isDateInTomorrow(date) {
            formatter.dateFormat = "Tomorrow at h:mm a"
        } else {
            formatter.dateFormat = "MMM d at h:mm a"
        }
        return formatter.string(from: date)
    }
}

// MARK: - Task Filter Enum
enum TaskFilter: CaseIterable {
    case all, today, upcoming, completed, pending
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .today: return "Today"
        case .upcoming: return "Upcoming"
        case .completed: return "Completed"
        case .pending: return "Pending"
        }
    }
}

// MARK: - Filter Pill Button
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.2) : Color.gray.opacity(0.15))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.accentColor : Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
} 