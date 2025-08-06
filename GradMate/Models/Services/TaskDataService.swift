//
//  TaskDataService.swift
//  GradMate
//
//  Created by Pradeep Reddy Kumbam on 23/06/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

// MARK: - Task Model for Cloud Storage
struct CloudTask: Codable, Identifiable {
    let id: String
    let userId: String
    var title: String
    var dueDate: Date?
    var isAllDay: Bool
    var notes: String
    var priority: Int
    var categoryId: String?
    var completed: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        title: String,
        dueDate: Date? = nil,
        isAllDay: Bool = false,
        notes: String = "",
        priority: Int = 1,
        categoryId: String? = nil,
        completed: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.dueDate = dueDate
        self.isAllDay = isAllDay
        self.notes = notes
        self.priority = priority
        self.categoryId = categoryId
        self.completed = completed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Task Data Service
class TaskDataService: ObservableObject {
    private let db = Firestore.firestore()
    @Published var tasks: [CloudTask] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var listenerRegistration: ListenerRegistration?
    
    init() {
        // Don't start listening immediately to avoid Firestore initialization conflicts
        // startListening() will be called manually when needed
    }
    
    deinit {
        stopListening()
    }
    
    // MARK: - Real-time Listener
    func startListening() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("[DEBUG] TaskDataService - No authenticated user")
            return
        }
        
        print("[DEBUG] TaskDataService - Starting listener for userId: \(userId)")
        
        listenerRegistration = db.collection("tasks")
            .whereField("userId", isEqualTo: userId)
            .order(by: "dueDate", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("[DEBUG] TaskDataService - Error listening for tasks: \(error.localizedDescription)")
                        self?.error = error.localizedDescription
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("[DEBUG] TaskDataService - No documents found")
                        self?.tasks = []
                        return
                    }
                    
                    print("[DEBUG] TaskDataService - Received \(documents.count) documents from Firestore")
                    
                    self?.tasks = documents.compactMap { document in
                        do {
                            let data = document.data()
                            let task = try self?.convertDocumentToTask(document: document, data: data)
                            print("[DEBUG] TaskDataService - Loaded task: \(task?.title ?? "nil")")
                            return task
                        } catch {
                            print("[DEBUG] TaskDataService - Error converting document: \(error)")
                            return nil
                        }
                    }
                    
                    self?.error = nil
                }
            }
    }
    
    func stopListening() {
        listenerRegistration?.remove()
        listenerRegistration = nil
        print("[DEBUG] TaskDataService - Stopped listening")
    }
    
    // MARK: - CRUD Operations
    func createTask(_ task: CloudTask, completion: @escaping (Bool) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("[DEBUG] TaskDataService - No authenticated user for task creation")
            completion(false)
            return
        }
        
        print("[DEBUG] TaskDataService - Creating task: \(task.title)")
        
        let taskData: [String: Any] = [
            "userId": userId,
            "title": task.title,
            "dueDate": task.dueDate as Any,
            "isAllDay": task.isAllDay,
            "notes": task.notes,
            "priority": task.priority,
            "categoryId": task.categoryId as Any,
            "completed": task.completed,
            "createdAt": task.createdAt,
            "updatedAt": task.updatedAt
        ]
        
        db.collection("tasks").document(task.id).setData(taskData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[DEBUG] TaskDataService - Error creating task: \(error.localizedDescription)")
                    self?.error = error.localizedDescription
                    completion(false)
                } else {
                    print("[DEBUG] TaskDataService - Task created successfully")
                    completion(true)
                }
            }
        }
    }
    
    func updateTask(_ task: CloudTask, completion: @escaping (Bool) -> Void) {
        print("[DEBUG] TaskDataService - Updating task: \(task.title)")
        
        let taskData: [String: Any] = [
            "title": task.title,
            "dueDate": task.dueDate as Any,
            "isAllDay": task.isAllDay,
            "notes": task.notes,
            "priority": task.priority,
            "categoryId": task.categoryId as Any,
            "completed": task.completed,
            "updatedAt": Date()
        ]
        
        db.collection("tasks").document(task.id).updateData(taskData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[DEBUG] TaskDataService - Error updating task: \(error.localizedDescription)")
                    self?.error = error.localizedDescription
                    completion(false)
                } else {
                    print("[DEBUG] TaskDataService - Task updated successfully")
                    completion(true)
                }
            }
        }
    }
    
    func deleteTask(_ taskId: String, completion: @escaping (Bool) -> Void) {
        print("[DEBUG] TaskDataService - Deleting task: \(taskId)")
        
        db.collection("tasks").document(taskId).delete { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[DEBUG] TaskDataService - Error deleting task: \(error.localizedDescription)")
                    self?.error = error.localizedDescription
                    completion(false)
                } else {
                    print("[DEBUG] TaskDataService - Task deleted successfully")
                    completion(true)
                }
            }
        }
    }
    
    func toggleTaskCompletion(_ task: CloudTask, completion: @escaping (Bool) -> Void) {
        var updatedTask = task
        updatedTask.completed.toggle()
        updatedTask.updatedAt = Date()
        
        updateTask(updatedTask, completion: completion)
    }
    
    // MARK: - Query Methods
    func getTasksForDate(_ date: Date) -> [CloudTask] {
        let calendar = Calendar.current
        return tasks.filter { task in
            guard let taskDate = task.dueDate else { return false }
            return calendar.isDate(taskDate, inSameDayAs: date)
        }
    }
    
    func getTasksForCategory(_ categoryId: String) -> [CloudTask] {
        return tasks.filter { task in
            task.categoryId == categoryId
        }
    }
    
    func getTodayTasks() -> [CloudTask] {
        return getTasksForDate(Date())
    }
    
    func getTasksByCategory() -> [String: [CloudTask]] {
        var groupedTasks: [String: [CloudTask]] = [:]
        
        for task in tasks {
            let categoryId = task.categoryId ?? "uncategorized"
            if groupedTasks[categoryId] == nil {
                groupedTasks[categoryId] = []
            }
            groupedTasks[categoryId]?.append(task)
        }
        
        return groupedTasks
    }
    
    // MARK: - Helper Methods
    private func convertDocumentToTask(document: DocumentSnapshot, data: [String: Any]) throws -> CloudTask? {
        guard let id = document.documentID as String?,
              let userId = data["userId"] as? String,
              let title = data["title"] as? String else {
            print("[DEBUG] TaskDataService - Missing required fields in document")
            return nil
        }
        
        let dueDate = data["dueDate"] as? Timestamp
        let isAllDay = data["isAllDay"] as? Bool ?? false
        let notes = data["notes"] as? String ?? ""
        let priority = data["priority"] as? Int ?? 1
        let categoryId = data["categoryId"] as? String
        let completed = data["completed"] as? Bool ?? false
        let createdAt = data["createdAt"] as? Timestamp
        let updatedAt = data["updatedAt"] as? Timestamp
        
        return CloudTask(
            id: id,
            userId: userId,
            title: title,
            dueDate: dueDate?.dateValue(),
            isAllDay: isAllDay,
            notes: notes,
            priority: priority,
            categoryId: categoryId,
            completed: completed,
            createdAt: createdAt?.dateValue() ?? Date(),
            updatedAt: updatedAt?.dateValue() ?? Date()
        )
    }
    
    // MARK: - Sync with Core Data
    func syncWithCoreData(_ coreDataTasks: [PlannerTask]) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        print("[DEBUG] TaskDataService - Syncing \(coreDataTasks.count) tasks with cloud")
        
        for coreDataTask in coreDataTasks {
            let cloudTask = CloudTask(
                id: coreDataTask.id?.uuidString ?? UUID().uuidString,
                userId: userId,
                title: coreDataTask.title ?? "",
                dueDate: coreDataTask.dueDate,
                isAllDay: coreDataTask.isAllDay,
                notes: coreDataTask.notes ?? "",
                priority: Int(coreDataTask.priority),
                categoryId: coreDataTask.categoryId?.uuidString,
                completed: coreDataTask.completed,
                createdAt: coreDataTask.createdAt ?? Date(),
                updatedAt: Date()
            )
            
            createTask(cloudTask) { success in
                if success {
                    print("[DEBUG] TaskDataService - Synced task: \(cloudTask.title)")
                } else {
                    print("[DEBUG] TaskDataService - Failed to sync task: \(cloudTask.title)")
                }
            }
        }
    }
} 