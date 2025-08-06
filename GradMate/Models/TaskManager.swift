//
//  TaskManager.swift
//  GradMate
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import SwiftUI
import CoreData
import Combine
import Foundation
import FirebaseAuth

class TaskManager: ObservableObject {
    @Published var tasks: [PlannerTask] = []
    @Published var isLoading = false
    @Published var cloudTasks: [CloudTask] = []
    @Published var useCloudStorage = false
    
    private let context: NSManagedObjectContext
    private let taskDataService = TaskDataService()
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        setupCloudService()
        Task {
            await loadTasksAsync()
        }
    }
    
    private func setupCloudService() {
        // Check if user is authenticated to enable cloud storage
        if Auth.auth().currentUser != nil {
            useCloudStorage = true
            // Start listening after a short delay to ensure Firestore is properly initialized
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.taskDataService.startListening()
            }
            
            // Observe cloud tasks changes
            taskDataService.$tasks
                .receive(on: DispatchQueue.main)
                .assign(to: &$cloudTasks)
        }
    }
    
    @MainActor
    func loadTasksAsync() async {
        isLoading = true
        let request: NSFetchRequest<PlannerTask> = PlannerTask.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PlannerTask.dueDate, ascending: true)]
        do {
            let fetchedTasks = try await context.perform {
                try request.execute()
            }
            tasks = fetchedTasks
        } catch {
            print("Error loading tasks: \(error)")
        }
        isLoading = false
    }
    
    func loadTasks() {
        Task { await loadTasksAsync() }
    }
    
    func createTask(title: String, dueDate: Date?, isAllDay: Bool = false, notes: String = "", priority: Int16 = 1, categoryId: UUID? = nil) {
        // Create local task
        let task = PlannerTask(context: context)
        task.id = UUID()
        task.title = title
        task.dueDate = dueDate
        task.isAllDay = isAllDay
        task.notes = notes
        task.priority = priority
        task.categoryId = categoryId
        task.completed = false
        task.createdAt = Date()
        save()
        loadTasks()
        
        // Create cloud task if user is authenticated
        if useCloudStorage, let userId = Auth.auth().currentUser?.uid {
            let cloudTask = CloudTask(
                userId: userId,
                title: title,
                dueDate: dueDate,
                isAllDay: isAllDay,
                notes: notes,
                priority: Int(priority),
                categoryId: categoryId?.uuidString,
                completed: false
            )
            
            taskDataService.createTask(cloudTask) { success in
                if success {
                    print("[DEBUG] TaskManager - Task created in cloud successfully")
                } else {
                    print("[DEBUG] TaskManager - Failed to create task in cloud")
                }
            }
        }
    }
    
    func createTaskFromNaturalLanguage(_ text: String, categoryId: UUID? = nil) {
        let parser = NaturalLanguageParser()
        let parsedTask = parser.parseTask(text)
        createTask(
            title: parsedTask.title,
            dueDate: parsedTask.dueDate,
            isAllDay: parsedTask.isAllDay,
            notes: parsedTask.notes,
            priority: parsedTask.priority,
            categoryId: categoryId
        )
    }
    
    func toggleTaskCompletion(_ task: PlannerTask) {
        task.completed.toggle()
        save()
        loadTasks()
        
        // Update cloud task if user is authenticated
        if useCloudStorage, let userId = Auth.auth().currentUser?.uid {
            let cloudTask = CloudTask(
                id: task.id?.uuidString ?? UUID().uuidString,
                userId: userId,
                title: task.title ?? "",
                dueDate: task.dueDate,
                isAllDay: task.isAllDay,
                notes: task.notes ?? "",
                priority: Int(task.priority),
                categoryId: task.categoryId?.uuidString,
                completed: task.completed,
                createdAt: task.createdAt ?? Date(),
                updatedAt: Date()
            )
            
            taskDataService.updateTask(cloudTask) { success in
                if success {
                    print("[DEBUG] TaskManager - Task completion updated in cloud successfully")
                } else {
                    print("[DEBUG] TaskManager - Failed to update task completion in cloud")
                }
            }
        }
    }
    
    func deleteTask(_ task: PlannerTask) {
        let taskId = task.id?.uuidString ?? UUID().uuidString
        context.delete(task)
        save()
        loadTasks()
        
        // Delete cloud task if user is authenticated
        if useCloudStorage {
            taskDataService.deleteTask(taskId) { success in
                if success {
                    print("[DEBUG] TaskManager - Task deleted from cloud successfully")
                } else {
                    print("[DEBUG] TaskManager - Failed to delete task from cloud")
                }
            }
        }
    }
    
    func updateTask(_ task: PlannerTask, title: String, dueDate: Date?, isAllDay: Bool, notes: String, priority: Int16, categoryId: UUID? = nil) {
        task.title = title
        task.dueDate = dueDate
        task.isAllDay = isAllDay
        task.notes = notes
        task.priority = priority
        task.categoryId = categoryId
        save()
        loadTasks()
        
        // Update cloud task if user is authenticated
        if useCloudStorage, let userId = Auth.auth().currentUser?.uid {
            let cloudTask = CloudTask(
                id: task.id?.uuidString ?? UUID().uuidString,
                userId: userId,
                title: title,
                dueDate: dueDate,
                isAllDay: isAllDay,
                notes: notes,
                priority: Int(priority),
                categoryId: categoryId?.uuidString,
                completed: task.completed,
                createdAt: task.createdAt ?? Date(),
                updatedAt: Date()
            )
            
            taskDataService.updateTask(cloudTask) { success in
                if success {
                    print("[DEBUG] TaskManager - Task updated in cloud successfully")
                } else {
                    print("[DEBUG] TaskManager - Failed to update task in cloud")
                }
            }
        }
    }
    
    func getTasksForDate(_ date: Date) -> [PlannerTask] {
        let calendar = Calendar.current
        return tasks.filter { task in
            guard let taskDate = task.dueDate else { return false }
            return calendar.isDate(taskDate, inSameDayAs: date)
        }
    }
    
    func getTasksForCategory(_ categoryId: UUID) -> [PlannerTask] {
        return tasks.filter { task in
            task.categoryId == categoryId
        }
    }
    
    func getTodayTasks() -> [PlannerTask] {
        getTasksForDate(Date())
    }
    
    func getTasksByCategory() -> [UUID: [PlannerTask]] {
        var groupedTasks: [UUID: [PlannerTask]] = [:]
        
        for task in tasks {
            let categoryId = task.categoryId ?? UUID() // Use a default UUID for uncategorized tasks
            if groupedTasks[categoryId] == nil {
                groupedTasks[categoryId] = []
            }
            groupedTasks[categoryId]?.append(task)
        }
        
        return groupedTasks
    }
    
    private func save() {
        do {
            try context.save()
        } catch {
            print("Error saving task: \(error)")
        }
    }
    
    // MARK: - Cloud Sync Methods
    func syncTasksToCloud() {
        guard useCloudStorage else {
            print("[DEBUG] TaskManager - Cloud storage not enabled")
            return
        }
        
        print("[DEBUG] TaskManager - Syncing \(tasks.count) tasks to cloud")
        taskDataService.syncWithCoreData(tasks)
    }
    
    func enableCloudStorage() {
        if Auth.auth().currentUser != nil {
            useCloudStorage = true
            taskDataService.startListening()
            syncTasksToCloud()
            print("[DEBUG] TaskManager - Cloud storage enabled")
        } else {
            print("[DEBUG] TaskManager - No authenticated user, cannot enable cloud storage")
        }
    }
    
    func disableCloudStorage() {
        useCloudStorage = false
        taskDataService.stopListening()
        print("[DEBUG] TaskManager - Cloud storage disabled")
    }
    
    func startCloudService() {
        if Auth.auth().currentUser != nil && !useCloudStorage {
            useCloudStorage = true
            taskDataService.startListening()
            print("[DEBUG] TaskManager - Cloud storage started")
        }
    }
}

// Natural Language Parser for task creation
struct NaturalLanguageParser {
    struct ParsedTask {
        let title: String
        let dueDate: Date?
        let isAllDay: Bool
        let notes: String
        let priority: Int16
    }
    
    func parseTask(_ text: String) -> ParsedTask {
        let lowercasedText = text.lowercased()
        var title = text
        var dueDate: Date? = nil
        var isAllDay = false
        let notes = ""
        var priority: Int16 = 1
        
        // Extract time patterns
        if let timeMatch = lowercasedText.range(of: "at (\\d{1,2})(?::(\\d{2}))?\\s*(am|pm)?", options: .regularExpression) {
            let timeString = String(lowercasedText[timeMatch])
            dueDate = parseTimeString(timeString)
        }
        
        // Extract date patterns
        if lowercasedText.contains("tomorrow") {
            dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        } else if lowercasedText.contains("next week") {
            dueDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())
        }
        
        // Extract priority
        if lowercasedText.contains("urgent") || lowercasedText.contains("high priority") {
            priority = 3
        } else if lowercasedText.contains("important") || lowercasedText.contains("medium priority") {
            priority = 2
        }
        
        // Extract all-day indicator
        if lowercasedText.contains("all day") || lowercasedText.contains("allday") {
            isAllDay = true
        }
        
        // Clean up title by removing time indicators
        title = title.replacingOccurrences(of: "at \\d{1,2}(?::\\d{2})?\\s*(am|pm)?", with: "", options: .regularExpression)
        title = title.replacingOccurrences(of: "urgent", with: "", options: .caseInsensitive)
        title = title.replacingOccurrences(of: "high priority", with: "", options: .caseInsensitive)
        title = title.replacingOccurrences(of: "important", with: "", options: .caseInsensitive)
        title = title.replacingOccurrences(of: "medium priority", with: "", options: .caseInsensitive)
        title = title.replacingOccurrences(of: "all day", with: "", options: .caseInsensitive)
        title = title.replacingOccurrences(of: "allday", with: "", options: .caseInsensitive)
        title = title.replacingOccurrences(of: "tomorrow", with: "", options: .caseInsensitive)
        title = title.replacingOccurrences(of: "next week", with: "", options: .caseInsensitive)
        title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return ParsedTask(
            title: title.isEmpty ? "New Task" : title,
            dueDate: dueDate,
            isAllDay: isAllDay,
            notes: notes,
            priority: priority
        )
    }
    
    private func parseTimeString(_ timeString: String) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        
        // Simple time parsing - in a real app, you'd use a more robust parser
        if let hourMatch = timeString.range(of: "\\d{1,2}", options: .regularExpression) {
            let hourString = String(timeString[hourMatch])
            if let hour = Int(hourString) {
                components.hour = hour
                components.minute = 0
                return calendar.date(from: components)
            }
        }
        
        return nil
    }
} 