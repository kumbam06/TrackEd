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
    @State private var selectedDate: Date = Date()
    @State private var showCalendar = false
    @State private var scrollOffset: CGFloat = 0
    @State private var isScrolled = false
    
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
    
    private var tasksForSelectedDate: [PlannerTask] {
        return taskManager.tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return Calendar.current.isDate(dueDate, inSameDayAs: selectedDate)
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
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    // Calendar Section
                    VStack(spacing: showCalendar ? 8 : 16) {
                        HStack {
                            Text("CALENDAR")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color("appTextPrimary"))
                                .kerning(1.5)
                            
                            Spacer()
                            
                            Button(action: { showCalendar.toggle() }) {
                                HStack(spacing: 4) {
                                    Text(showCalendar ? "Hide" : "Show")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Image(systemName: showCalendar ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                }
                                .foregroundColor(Color("appPrimaryAccent"))
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        if showCalendar {
                            CalendarView(
                                selectedDate: $selectedDate,
                                tasks: taskManager.tasks
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, showCalendar ? 12 : 16)
                    .background(Color("appCardBG"))
                    .id("calendar")
                    
                    // Search and Filter Bar
                    VStack(spacing: showCalendar ? 12 : 16) {
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Color("appTextSecondary"))
                            
                            TextField("Search tasks...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .foregroundColor(Color("appTextPrimary"))
                            
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Color("appTextSecondary"))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color("appStrokeGray"))
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
                    .padding(.top, showCalendar ? 12 : 16)
                    .padding(.bottom, 8)
                    .background(Color("appCardBG"))
                    .id("search")
                    
                    // Cloud Sync Section
                    if #available(iOS 16.0, *) {
                        CloudSyncView(taskManager: taskManager)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                    }
                    
                    // Selected Date Tasks (if calendar is shown)
                    if showCalendar && !tasksForSelectedDate.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("TASKS FOR \(formatSelectedDate())")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("appTextPrimary"))
                                    .kerning(1.5)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(tasksForSelectedDate, id: \.id) { task in
                                        SelectedDateTaskCard(
                                            task: task,
                                            onToggle: { taskManager.toggleTaskCompletion(task) },
                                            onDelete: { taskManager.deleteTask(task) }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 12)
                        .background(Color("appCardBG"))
                        .id("selectedTasks")
                    }
                    
                    // Tasks List
                    if filteredTasks.isEmpty {
                        emptyStateView
                            .id("empty")
                    } else {
                        LazyVStack(spacing: showCalendar ? 16 : 20) {
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
                        .padding(.top, showCalendar ? 12 : 16)
                        .padding(.bottom, 100) // Padding for tab bar
                        .id("tasks")
                    }
                }
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
                isScrolled = value < -100
            }
        }
        .background(Color("appScreenBG"))
        .navigationTitle("Planner")
        .navigationBarTitleDisplayMode(shouldShowLargeTitle ? .large : .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddTask = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color("appPrimaryAccent"))
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
    
    private var shouldShowLargeTitle: Bool {
        // Show large title when not scrolled or when calendar is hidden
        return !isScrolled || !showCalendar
    }
    
    private func formatSelectedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: selectedDate).uppercased()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: emptyStateIcon)
                .font(.system(size: 60))
                .foregroundColor(Color("appTextSecondary"))
            
            Text(emptyStateTitle)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color("appTextPrimary"))
            
            Text(emptyStateMessage)
                .font(.body)
                .foregroundColor(Color("appTextSecondary"))
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
                .background(Color("appPrimaryAccent"))
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
                .foregroundColor(Color("appTextPrimary"))
            
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
        case 1: return Color("appSuccess")
        case 2: return Color("appWarning")
        case 3: return Color("appError")
        default: return Color("appTextSecondary")
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
                    .foregroundColor(task.completed ? Color("appSuccess") : Color("appTextSecondary"))
            }
            
            // Task Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(task.title ?? "Untitled Task")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color("appTextPrimary"))
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
                        .foregroundColor(Color("appTextSecondary"))
                        .lineLimit(2)
                }
                
                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                            .foregroundColor(Color("appTextSecondary"))
                        
                        Text(formatDueDate(dueDate))
                            .font(.caption)
                            .foregroundColor(Color("appTextSecondary"))
                    }
                }
            }
            
            // Delete Button
            Button(action: { showingDeleteAlert = true }) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(Color("appError"))
            }
        }
        .padding(16)
        .background(Color("appCardBG"))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
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
                        .background(isSelected ? Color.white.opacity(0.2) : Color("appTextSecondary").opacity(0.15))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color("appPrimaryAccent") : Color("appStrokeGray"))
            .foregroundColor(isSelected ? .white : Color("appTextPrimary"))
            .cornerRadius(20)
            .shadow(color: isSelected ? Color("appPrimaryAccent").opacity(0.2) : Color.black.opacity(0.04), radius: isSelected ? 6 : 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color("appPrimaryAccent") : Color("appStrokeGray"), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Calendar Components
struct CalendarView: View {
    @Binding var selectedDate: Date
    let tasks: [PlannerTask]
    
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    private let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 12) {
            // Month Navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(Color("appPrimaryAccent"))
                }
                
                Spacer()
                
                Text(dateFormatter.string(from: currentMonth))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("appTextPrimary"))
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(Color("appPrimaryAccent"))
                }
            }
            .padding(.horizontal, 4)
            
            // Weekday Headers
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    Text(weekdaySymbol(for: index))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(Color("appTextSecondary"))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasTasks: hasTasksForDate(date),
                            onTap: { selectedDate = date }
                        )
                    } else {
                        Color.clear
                            .frame(height: 32)
                    }
                }
            }
        }
        .padding(12)
        .background(Color("appStrokeGray"))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    
    private func weekdaySymbol(for index: Int) -> String {
        let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
        return weekdays[index]
    }
    
    private func daysInMonth() -> [Date?] {
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 30
        
        var days: [Date?] = []
        
        // Add empty cells for days before the first day of the month
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // Add all days in the month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func hasTasksForDate(_ date: Date) -> Bool {
        return tasks.contains { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: date)
        }
    }
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newDate
        }
    }
}

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasTasks: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 28, height: 28)
                
                VStack(spacing: 1) {
                    Text(dayFormatter.string(from: date))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(textColor)
                    
                    if hasTasks {
                        Circle()
                            .fill(taskIndicatorColor)
                            .frame(width: 3, height: 3)
                    } else {
                        Color.clear
                            .frame(width: 3, height: 3)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color("appPrimaryAccent")
        } else if isToday {
            return Color("appPrimaryAccent").opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return Color("appPrimaryAccent")
        } else {
            return Color("appTextPrimary")
        }
    }
    
    private var taskIndicatorColor: Color {
        if isSelected {
            return .white
        } else {
            return Color("appPrimaryAccent")
        }
    }
}

struct SelectedDateTaskCard: View {
    let task: PlannerTask
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    private var priorityColor: Color {
        switch task.priority {
        case 1: return Color("appSuccess")
        case 2: return Color("appWarning")
        case 3: return Color("appError")
        default: return Color("appTextSecondary")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Button(action: onToggle) {
                    Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(task.completed ? Color("appSuccess") : Color("appTextSecondary"))
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(task.title ?? "Untitled Task")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color("appTextPrimary"))
                        .strikethrough(task.completed)
                        .opacity(task.completed ? 0.6 : 1.0)
                        .lineLimit(2)
                    
                    if let dueDate = task.dueDate {
                        Text(formatTime(dueDate))
                            .font(.caption2)
                            .foregroundColor(Color("appTextSecondary"))
                    }
                }
                
                Spacer()
                
                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(Color("appError"))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if task.priority > 1 {
                HStack {
                    Circle()
                        .fill(priorityColor)
                        .frame(width: 6, height: 6)
                    
                    Text(priorityText)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(priorityColor)
                    
                    Spacer()
                }
            }
        }
        .padding(10)
        .frame(width: 180)
        .background(Color("appStrokeGray"))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        .alert("Delete Task", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("Are you sure you want to delete this task?")
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
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
} 