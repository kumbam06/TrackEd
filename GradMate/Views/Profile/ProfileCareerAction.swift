import SwiftUI

/// Actions shown on the Profile tab under Career & Skills.
/// Upload Resume is intentionally not included.
enum ProfileCareerAction: String, CaseIterable, Identifiable {
    case addSkill = "ADD SKILL"
    case projects = "PROJECTS"
    case internships = "INTERNSHIPS"
    case certifications = "CERTIFICATIONS"
    case workExperience = "WORK EXPERIENCE"
    case languages = "LANGUAGES"
    case coverLetters = "COVER LETTERS"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .addSkill: return "plus.circle.fill"
        case .projects: return "folder.fill"
        case .internships: return "building.2.fill"
        case .certifications: return "trophy.fill"
        case .workExperience: return "briefcase.fill"
        case .languages: return "globe"
        case .coverLetters: return "envelope.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .addSkill, .projects, .languages, .coverLetters:
            return Color("appPrimaryAccent")
        case .internships, .certifications:
            return Color("appWarning")
        case .workExperience:
            return Color("appSuccess")
        }
    }
}
