import Foundation

struct Certification: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var organization: String
    var location: String
    var dateReceived: Date
    var dateExpiry: Date?
    var description: String
    var credentialID: String?
    
    init(
        id: UUID = UUID(),
        title: String = "",
        organization: String = "",
        location: String = "",
        dateReceived: Date = Date(),
        dateExpiry: Date? = nil,
        description: String = "",
        credentialID: String? = nil
    ) {
        self.id = id
        self.title = title
        self.organization = organization
        self.location = location
        self.dateReceived = dateReceived
        self.dateExpiry = dateExpiry
        self.description = description
        self.credentialID = credentialID
    }
} 