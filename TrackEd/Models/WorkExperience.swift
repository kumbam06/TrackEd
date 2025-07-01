import Foundation

struct WorkExperience: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var company: String
    var location: String
    var startDate: Date
    var endDate: Date?
    var isCurrent: Bool
    var description: String
    var technologies: [String]?
    
    init(
        id: UUID = UUID(),
        title: String = "",
        company: String = "",
        location: String = "",
        startDate: Date = Date(),
        endDate: Date? = nil,
        isCurrent: Bool = false,
        description: String = "",
        technologies: [String]? = nil
    ) {
        self.id = id
        self.title = title
        self.company = company
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
        self.isCurrent = isCurrent
        self.description = description
        self.technologies = technologies
    }
} 