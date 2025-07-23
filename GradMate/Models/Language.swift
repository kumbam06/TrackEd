import Foundation

struct Language: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var proficiency: ProficiencyLevel
    
    enum ProficiencyLevel: String, Codable, CaseIterable, Equatable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case fluent = "Fluent"
        case native = "Native"
    }
    
    init(id: UUID = UUID(), name: String = "", proficiency: ProficiencyLevel = .beginner) {
        self.id = id
        self.name = name
        self.proficiency = proficiency
    }
} 