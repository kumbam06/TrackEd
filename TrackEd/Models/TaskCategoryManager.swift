import Foundation
import SwiftUI
import Combine
import CoreData

class TaskCategoryManager: ObservableObject {
    @Published var categories: [TaskCategoryEntity] = []
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        loadCategories()
        if categories.isEmpty {
            setupDefaultCategories()
        }
    }
    
    func loadCategories() {
        let request: NSFetchRequest<TaskCategoryEntity> = TaskCategoryEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskCategoryEntity.createdAt, ascending: true)]
        
        do {
            categories = try context.fetch(request)
        } catch {
            print("Error loading task categories: \(error)")
        }
    }
    
    func addCategory(_ category: TaskCategory) {
        let entity = TaskCategoryEntity(context: context)
        entity.id = category.id
        entity.name = category.name
        entity.color = category.color
        entity.icon = category.icon
        entity.isDefault = false
        entity.createdAt = Date()
        entity.updatedAt = Date()
        
        save()
        loadCategories()
    }
    
    func updateCategory(_ category: TaskCategory) {
        let request: NSFetchRequest<TaskCategoryEntity> = TaskCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", category.id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                entity.name = category.name
                entity.color = category.color
                entity.icon = category.icon
                entity.updatedAt = Date()
                
                save()
                loadCategories()
            }
        } catch {
            print("Error updating task category: \(error)")
        }
    }
    
    func deleteCategory(_ category: TaskCategory) {
        let request: NSFetchRequest<TaskCategoryEntity> = TaskCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", category.id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                context.delete(entity)
                save()
                loadCategories()
            }
        } catch {
            print("Error deleting task category: \(error)")
        }
    }
    
    func getCategory(by id: UUID) -> TaskCategoryEntity? {
        let request: NSFetchRequest<TaskCategoryEntity> = TaskCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("Error fetching task category: \(error)")
            return nil
        }
    }
    
    func getCategory(by name: String) -> TaskCategoryEntity? {
        let request: NSFetchRequest<TaskCategoryEntity> = TaskCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("Error fetching task category by name: \(error)")
            return nil
        }
    }
    
    private func setupDefaultCategories() {
        let defaultCategories = TaskCategory.defaultCategories
        
        for category in defaultCategories {
            let entity = TaskCategoryEntity(context: context)
            entity.id = category.id
            entity.name = category.name
            entity.color = category.color
            entity.icon = category.icon
            entity.isDefault = true
            entity.createdAt = Date()
            entity.updatedAt = Date()
        }
        
        save()
        loadCategories()
    }
    
    func resetToDefaults() {
        // Delete all non-default categories
        let request: NSFetchRequest<TaskCategoryEntity> = TaskCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isDefault == NO")
        
        do {
            let results = try context.fetch(request)
            for entity in results {
                context.delete(entity)
            }
            save()
            loadCategories()
        } catch {
            print("Error resetting to defaults: \(error)")
        }
    }
    
    private func save() {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
} 