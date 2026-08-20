import Foundation
import FirebaseAuth
import FirebaseFirestore

struct SkillRecord: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var category: String
    var skillDescription: String
    var proficiency: Int
}

struct UserPortfolio: Equatable {
    var name: String = ""
    var role: String = ""
    var email: String = ""
    var phone: String = ""
    var bio: String = ""
    var linkedin: String = ""
    var website: String = ""
    var username: String = ""
    var address: String = ""
    var currentCompany: String = ""
    var photoURL: String? = nil
    var skills: [SkillRecord] = []
    var workExperiences: [WorkExperience] = []
    var projects: [Project] = []
    var internships: [Internship] = []
    var certifications: [Certification] = []
    var languages: [Language] = []
}

final class FirestoreUserDataService {
    static let shared = FirestoreUserDataService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func savePortfolio(_ portfolio: UserPortfolio, completion: ((Error?) -> Void)? = nil) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion?(nil)
            return
        }
        var data: [String: Any] = [
            "name": portfolio.name,
            "role": portfolio.role,
            "email": portfolio.email,
            "phone": portfolio.phone,
            "bio": portfolio.bio,
            "linkedin": portfolio.linkedin,
            "website": portfolio.website,
            "username": portfolio.username,
            "address": portfolio.address,
            "currentCompany": portfolio.currentCompany,
            "updatedAt": FieldValue.serverTimestamp(),
            "skills": portfolio.skills.map { skillDict($0) },
            "workExperiences": portfolio.workExperiences.map { workDict($0) },
            "projects": portfolio.projects.map { projectDict($0) },
            "internships": portfolio.internships.map { internshipDict($0) },
            "certifications": portfolio.certifications.map { certDict($0) },
            "languages": portfolio.languages.map { languageDict($0) }
        ]
        db.collection("users").document(uid).setData(data, merge: true) { error in
            if let error {
                print("[Portfolio] Failed to save: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                completion?(error)
            }
        }
    }
    
    func fetchPortfolio(uid: String, completion: @escaping (UserPortfolio?) -> Void) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error {
                print("[Portfolio] Failed to fetch: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            guard let data = snapshot?.data() else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            let portfolio = self.decodePortfolio(data)
            DispatchQueue.main.async { completion(portfolio) }
        }
    }
    
    private func decodePortfolio(_ data: [String: Any]) -> UserPortfolio {
        UserPortfolio(
            name: data["name"] as? String ?? "",
            role: data["role"] as? String ?? "",
            email: data["email"] as? String ?? "",
            phone: data["phone"] as? String ?? "",
            bio: data["bio"] as? String ?? "",
            linkedin: data["linkedin"] as? String ?? "",
            website: data["website"] as? String ?? "",
            username: data["username"] as? String ?? "",
            address: data["address"] as? String ?? "",
            currentCompany: data["currentCompany"] as? String ?? "",
            photoURL: data["photoURL"] as? String,
            skills: (data["skills"] as? [[String: Any]] ?? []).compactMap(decodeSkill),
            workExperiences: (data["workExperiences"] as? [[String: Any]] ?? []).compactMap(decodeWork),
            projects: (data["projects"] as? [[String: Any]] ?? []).compactMap(decodeProject),
            internships: (data["internships"] as? [[String: Any]] ?? []).compactMap(decodeInternship),
            certifications: (data["certifications"] as? [[String: Any]] ?? []).compactMap(decodeCert),
            languages: (data["languages"] as? [[String: Any]] ?? []).compactMap(decodeLanguage)
        )
    }
    
    private func skillDict(_ skill: SkillRecord) -> [String: Any] {
        [
            "id": skill.id.uuidString,
            "name": skill.name,
            "category": skill.category,
            "skillDescription": skill.skillDescription,
            "proficiency": skill.proficiency
        ]
    }
    
    private func workDict(_ item: WorkExperience) -> [String: Any] {
        var data: [String: Any] = [
            "id": item.id.uuidString,
            "title": item.title,
            "company": item.company,
            "location": item.location,
            "startDate": Timestamp(date: item.startDate),
            "isCurrent": item.isCurrent,
            "description": item.description,
            "technologies": item.technologies ?? []
        ]
        if let end = item.endDate { data["endDate"] = Timestamp(date: end) }
        return data
    }
    
    private func projectDict(_ item: Project) -> [String: Any] {
        var data: [String: Any] = [
            "id": item.id.uuidString,
            "title": item.title,
            "role": item.role,
            "company": item.company,
            "location": item.location,
            "startDate": Timestamp(date: item.startDate),
            "isCurrent": item.isCurrent,
            "description": item.description,
            "technologies": item.technologies ?? []
        ]
        if let end = item.endDate { data["endDate"] = Timestamp(date: end) }
        return data
    }
    
    private func internshipDict(_ item: Internship) -> [String: Any] {
        var data: [String: Any] = [
            "id": item.id.uuidString,
            "title": item.title,
            "role": item.role,
            "company": item.company,
            "location": item.location,
            "startDate": Timestamp(date: item.startDate),
            "isCurrent": item.isCurrent,
            "description": item.description,
            "technologies": item.technologies ?? []
        ]
        if let end = item.endDate { data["endDate"] = Timestamp(date: end) }
        return data
    }
    
    private func certDict(_ item: Certification) -> [String: Any] {
        var data: [String: Any] = [
            "id": item.id.uuidString,
            "title": item.title,
            "organization": item.organization,
            "location": item.location,
            "dateReceived": Timestamp(date: item.dateReceived),
            "description": item.description
        ]
        if let expiry = item.dateExpiry { data["dateExpiry"] = Timestamp(date: expiry) }
        if let credential = item.credentialID { data["credentialID"] = credential }
        return data
    }
    
    private func languageDict(_ item: Language) -> [String: Any] {
        [
            "id": item.id.uuidString,
            "name": item.name,
            "proficiency": item.proficiency.rawValue
        ]
    }
    
    private func decodeSkill(_ data: [String: Any]) -> SkillRecord? {
        guard let name = data["name"] as? String, !name.isEmpty else { return nil }
        return SkillRecord(
            id: UUID(uuidString: data["id"] as? String ?? "") ?? UUID(),
            name: name,
            category: data["category"] as? String ?? "General",
            skillDescription: data["skillDescription"] as? String ?? "",
            proficiency: data["proficiency"] as? Int ?? 3
        )
    }
    
    private func decodeWork(_ data: [String: Any]) -> WorkExperience? {
        guard let title = data["title"] as? String else { return nil }
        return WorkExperience(
            id: UUID(uuidString: data["id"] as? String ?? "") ?? UUID(),
            title: title,
            company: data["company"] as? String ?? "",
            location: data["location"] as? String ?? "",
            startDate: (data["startDate"] as? Timestamp)?.dateValue() ?? Date(),
            endDate: (data["endDate"] as? Timestamp)?.dateValue(),
            isCurrent: data["isCurrent"] as? Bool ?? false,
            description: data["description"] as? String ?? "",
            technologies: data["technologies"] as? [String]
        )
    }
    
    private func decodeProject(_ data: [String: Any]) -> Project? {
        guard let title = data["title"] as? String else { return nil }
        return Project(
            id: UUID(uuidString: data["id"] as? String ?? "") ?? UUID(),
            title: title,
            role: data["role"] as? String ?? "",
            company: data["company"] as? String ?? "",
            location: data["location"] as? String ?? "",
            startDate: (data["startDate"] as? Timestamp)?.dateValue() ?? Date(),
            endDate: (data["endDate"] as? Timestamp)?.dateValue(),
            isCurrent: data["isCurrent"] as? Bool ?? false,
            description: data["description"] as? String ?? "",
            technologies: data["technologies"] as? [String]
        )
    }
    
    private func decodeInternship(_ data: [String: Any]) -> Internship? {
        guard let title = data["title"] as? String else { return nil }
        return Internship(
            id: UUID(uuidString: data["id"] as? String ?? "") ?? UUID(),
            title: title,
            role: data["role"] as? String ?? "",
            company: data["company"] as? String ?? "",
            location: data["location"] as? String ?? "",
            startDate: (data["startDate"] as? Timestamp)?.dateValue() ?? Date(),
            endDate: (data["endDate"] as? Timestamp)?.dateValue(),
            isCurrent: data["isCurrent"] as? Bool ?? false,
            description: data["description"] as? String ?? "",
            technologies: data["technologies"] as? [String]
        )
    }
    
    private func decodeCert(_ data: [String: Any]) -> Certification? {
        guard let title = data["title"] as? String else { return nil }
        return Certification(
            id: UUID(uuidString: data["id"] as? String ?? "") ?? UUID(),
            title: title,
            organization: data["organization"] as? String ?? "",
            location: data["location"] as? String ?? "",
            dateReceived: (data["dateReceived"] as? Timestamp)?.dateValue() ?? Date(),
            dateExpiry: (data["dateExpiry"] as? Timestamp)?.dateValue(),
            description: data["description"] as? String ?? "",
            credentialID: data["credentialID"] as? String
        )
    }
    
    private func decodeLanguage(_ data: [String: Any]) -> Language? {
        guard let name = data["name"] as? String, !name.isEmpty else { return nil }
        let level = Language.ProficiencyLevel(rawValue: data["proficiency"] as? String ?? "") ?? .beginner
        return Language(
            id: UUID(uuidString: data["id"] as? String ?? "") ?? UUID(),
            name: name,
            proficiency: level
        )
    }
}
