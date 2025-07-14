import Foundation

protocol FocusSessionServiceProtocol {
    func fetchSessions(completion: @escaping ([FocusSessionEntity]) -> Void)
    func addSession(taskId: UUID?, startTime: Date, endTime: Date, completion: (() -> Void)?)
    func getSessions(for date: Date, completion: @escaping ([FocusSessionEntity]) -> Void)
    func getTotalFocusMinutes(for date: Date, completion: @escaping (Int) -> Void)
    func getTotalFocusMinutes(forDays days: Int, upTo endDate: Date, completion: @escaping ([Int]) -> Void)
} 