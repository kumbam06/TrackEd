import Foundation
import CoreData
import Combine

class ProgressDataService: ObservableObject {
    @Published var achievements: [AchievementEntity] = []
    @Published var progressData: [ProgressDataEntity] = []
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        loadAllData()
        setupDefaultAchievements()
    }
    
    // MARK: - Achievements
    func loadAchievements() {
        let request: NSFetchRequest<AchievementEntity> = AchievementEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AchievementEntity.createdAt, ascending: false)]
        
        do {
            achievements = try context.fetch(request)
        } catch {
            print("Error loading achievements: \(error)")
        }
    }
    
    func createAchievement(title: String, description: String, category: String, icon: String, color: String, target: Int32) {
        let entity = AchievementEntity(context: context)
        entity.id = UUID()
        entity.title = title
        entity.achievementDescription = description
        entity.category = category
        entity.icon = icon
        entity.color = color
        entity.isCompleted = false
        entity.progress = 0.0
        entity.target = target
        entity.current = 0
        entity.completedAt = nil
        entity.createdAt = Date()
        entity.updatedAt = Date()
        
        save()
        loadAchievements()
    }
    
    func updateAchievement(_ achievement: AchievementEntity) {
        achievement.updatedAt = Date()
        save()
        loadAchievements()
    }
    
    func deleteAchievement(_ achievement: AchievementEntity) {
        context.delete(achievement)
        save()
        loadAchievements()
    }
    
    func updateAchievementProgress(_ achievement: AchievementEntity, current: Int32) {
        achievement.current = current
        achievement.progress = Double(current) / Double(achievement.target)
        
        if achievement.progress >= 1.0 && !achievement.isCompleted {
            achievement.isCompleted = true
            achievement.completedAt = Date()
        }
        
        achievement.updatedAt = Date()
        save()
        loadAchievements()
    }
    
    // MARK: - Progress Data
    func loadProgressData() {
        let request: NSFetchRequest<ProgressDataEntity> = ProgressDataEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ProgressDataEntity.date, ascending: false)]
        
        do {
            progressData = try context.fetch(request)
        } catch {
            print("Error loading progress data: \(error)")
        }
    }
    
    func createProgressData(_ data: ProgressDataPoint) {
        let entity = ProgressDataEntity(context: context)
        entity.id = UUID()
        entity.date = data.date
        entity.tasksCompleted = Int32(data.tasks)
        entity.focusHours = data.focusHours
        entity.productivityScore = Int32(calculateProductivityScore(tasks: data.tasks, focusHours: data.focusHours))
        entity.careerProgress = calculateCareerProgress()
        entity.createdAt = Date()
        
        save()
        loadProgressData()
    }
    
    func updateProgressData(_ data: ProgressDataPoint) {
        let request: NSFetchRequest<ProgressDataEntity> = ProgressDataEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", data.date as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                entity.tasksCompleted = Int32(data.tasks)
                entity.focusHours = data.focusHours
                entity.productivityScore = Int32(calculateProductivityScore(tasks: data.tasks, focusHours: data.focusHours))
                entity.careerProgress = calculateCareerProgress()
            } else {
                createProgressData(data)
            }
        } catch {
            print("Error updating progress data: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    private func loadAllData() {
        loadAchievements()
        loadProgressData()
    }
    
    private func setupDefaultAchievements() {
        if achievements.isEmpty {
            let defaultAchievements = [
                (title: "Task Master", description: "Complete 20 tasks in a single week", category: "Productivity", icon: "checkmark.circle.fill", color: "#34C759", target: Int32(20)),
                (title: "Focus Champion", description: "Achieve 10 focus hours in a week", category: "Focus", icon: "clock.fill", color: "#007AFF", target: Int32(10)),
                (title: "Skill Builder", description: "Master 5 different skills", category: "Skills", icon: "star.fill", color: "#FF9500", target: Int32(5)),
                (title: "Project Pioneer", description: "Complete 3 portfolio projects", category: "Career", icon: "folder.fill", color: "#AF52DE", target: Int32(3)),
                (title: "Certification Collector", description: "Earn 3 professional certifications", category: "Career", icon: "certificate.fill", color: "#5856D6", target: Int32(3)),
                (title: "Streak Master", description: "Maintain a 30-day productivity streak", category: "Productivity", icon: "flame.fill", color: "#FF3B30", target: Int32(30))
            ]
            
            for achievement in defaultAchievements {
                createAchievement(
                    title: achievement.title,
                    description: achievement.description,
                    category: achievement.category,
                    icon: achievement.icon,
                    color: achievement.color,
                    target: achievement.target
                )
            }
        }
    }
    
    private func calculateProductivityScore(tasks: Int, focusHours: Double) -> Int {
        let taskScore = min(tasks * 5, 40)
        let focusScore = min(Int(focusHours) * 3, 30)
        return taskScore + focusScore + 30 // Base score
    }
    
    private func calculateCareerProgress() -> Double {
        let service = CareerDataService(context: context)
        return service.careerCompletionRatio
    }
    
    private func save() {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    // MARK: - Public Helper Methods
    func getAchievementsByCategory(_ category: AchievementCategory) -> [AchievementEntity] {
        return achievements.filter { $0.category == category.rawValue }
    }
    
    func getProgressDataForDateRange(from startDate: Date, to endDate: Date) -> [ProgressDataEntity] {
        let request: NSFetchRequest<ProgressDataEntity> = ProgressDataEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as CVarArg, endDate as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ProgressDataEntity.date, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching progress data for date range: \(error)")
            return []
        }
    }
    
    func getTodayProgressData() -> ProgressDataEntity? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let request: NSFetchRequest<ProgressDataEntity> = ProgressDataEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", today as CVarArg, tomorrow as CVarArg)
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("Error fetching today's progress data: \(error)")
            return nil
        }
    }
}

// MARK: - Supporting Types
struct ProgressDataPoint {
    let date: Date
    let tasks: Int
    let focusHours: Double
} 