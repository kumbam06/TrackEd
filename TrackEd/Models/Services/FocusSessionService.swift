import Foundation
import CoreData
import Combine

class FocusSessionService: FocusSessionServiceProtocol, ObservableObject {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }
    
    func fetchSessions(completion: @escaping ([FocusSessionEntity]) -> Void) {
        let request: NSFetchRequest<FocusSessionEntity> = FocusSessionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FocusSessionEntity.startTime, ascending: false)]
        do {
            let sessions = try context.fetch(request)
            completion(sessions)
        } catch {
            print("Error loading focus sessions: \(error)")
            completion([])
        }
    }
    
    func addSession(taskId: UUID?, startTime: Date, endTime: Date, completion: (() -> Void)?) {
        let session = FocusSessionEntity(context: context)
        session.id = UUID()
        session.taskId = taskId
        session.startTime = startTime
        session.endTime = endTime
        session.duration = endTime.timeIntervalSince(startTime)
        save()
        completion?()
    }
    
    func getSessions(for date: Date, completion: @escaping ([FocusSessionEntity]) -> Void) {
        fetchSessions { sessions in
            let calendar = Calendar.current
            let filtered = sessions.filter { session in
                if let startTime = session.startTime {
                    return calendar.isDate(startTime, inSameDayAs: date)
                }
                return false
            }
            completion(filtered)
        }
    }
    
    func getTotalFocusMinutes(for date: Date, completion: @escaping (Int) -> Void) {
        getSessions(for: date) { sessions in
            let total = sessions.reduce(0) { $0 + Int($1.duration / 60) }
            completion(total)
        }
    }
    
    func getTotalFocusMinutes(forDays days: Int, upTo endDate: Date = Date(), completion: @escaping ([Int]) -> Void) {
        fetchSessions { sessions in
            let calendar = Calendar.current
            let result = (0..<days).map { offset in
                let date = calendar.date(byAdding: .day, value: -offset, to: endDate) ?? endDate
                let total = sessions.filter { session in
                    if let startTime = session.startTime {
                        return calendar.isDate(startTime, inSameDayAs: date)
                    }
                    return false
                }.reduce(0) { $0 + Int($1.duration / 60) }
                return total
            }.reversed()
            completion(Array(result))
        }
    }
    
    private func save() {
        do {
            try context.save()
        } catch {
            print("Error saving focus session: \(error)")
        }
    }
} 