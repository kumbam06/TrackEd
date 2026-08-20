import Foundation
import FirebaseAuth
import Combine

extension Notification.Name {
    static let userPortfolioNeedsCloudSync = Notification.Name("userPortfolioNeedsCloudSync")
}

/// Bridges local MVVM stores (Core Data / UserDefaults) with the Firestore user document.
enum UserPortfolioSync {
    private static var pendingPush: DispatchWorkItem?
    
    static func snapshot(
        profileManager: ProfileManager,
        skillManager: SkillManager,
        career: CareerDataService,
        languages: LanguageManager
    ) -> UserPortfolio {
        let profile = profileManager.currentProfile
        return UserPortfolio(
            name: profile?.name ?? "",
            role: profile?.role ?? "",
            email: profile?.email ?? "",
            phone: profile?.phone ?? "",
            bio: profile?.bio ?? "",
            linkedin: profile?.linkedin ?? "",
            website: profile?.website ?? "",
            username: profile?.username ?? "",
            address: profile?.address ?? "",
            currentCompany: profile?.currentCompany ?? "",
            photoURL: nil,
            skills: skillManager.skillRecords,
            workExperiences: career.workExperienceModels,
            projects: career.projectModels,
            internships: career.internshipModels,
            certifications: career.certificationModels,
            languages: languages.languages
        )
    }
    
    static func schedulePush(
        profileManager: ProfileManager,
        skillManager: SkillManager,
        career: CareerDataService,
        languages: LanguageManager
    ) {
        pendingPush?.cancel()
        let work = DispatchWorkItem {
            push(
                profileManager: profileManager,
                skillManager: skillManager,
                career: career,
                languages: languages
            )
        }
        pendingPush = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }
    
    static func push(
        profileManager: ProfileManager,
        skillManager: SkillManager,
        career: CareerDataService,
        languages: LanguageManager,
        completion: ((Error?) -> Void)? = nil
    ) {
        guard Auth.auth().currentUser?.uid != nil else {
            completion?(nil)
            return
        }
        let portfolio = snapshot(
            profileManager: profileManager,
            skillManager: skillManager,
            career: career,
            languages: languages
        )
        FirestoreUserDataService.shared.savePortfolio(portfolio, completion: completion)
    }
    
    static func pullAndMerge(
        uid: String,
        profileManager: ProfileManager,
        skillManager: SkillManager,
        career: CareerDataService,
        languages: LanguageManager,
        completion: ((UserPortfolio?) -> Void)? = nil
    ) {
        FirestoreUserDataService.shared.fetchPortfolio(uid: uid) { portfolio in
            DispatchQueue.main.async {
                guard let portfolio else {
                    push(profileManager: profileManager, skillManager: skillManager, career: career, languages: languages)
                    completion?(nil)
                    return
                }
                profileManager.applyCloudProfile(portfolio)
                let local = snapshot(
                    profileManager: profileManager,
                    skillManager: skillManager,
                    career: career,
                    languages: languages
                )
                let merged = merge(local: local, remote: portfolio)
                skillManager.replaceAll(merged.skills)
                career.replaceAll(
                    workExperiences: merged.workExperiences,
                    projects: merged.projects,
                    internships: merged.internships,
                    certifications: merged.certifications
                )
                languages.replaceAll(merged.languages)
                push(profileManager: profileManager, skillManager: skillManager, career: career, languages: languages)
                completion?(merged)
            }
        }
    }
    
    /// Keep local lists when the device already has data so a partial cloud document cannot wipe work, projects, or internships.
    static func merge(local: UserPortfolio, remote: UserPortfolio) -> UserPortfolio {
        UserPortfolio(
            name: pick(local.name, remote.name),
            role: pick(local.role, remote.role),
            email: pick(local.email, remote.email),
            phone: pick(local.phone, remote.phone),
            bio: pick(local.bio, remote.bio),
            linkedin: pick(local.linkedin, remote.linkedin),
            website: pick(local.website, remote.website),
            username: pick(local.username, remote.username),
            address: pick(local.address, remote.address),
            currentCompany: pick(local.currentCompany, remote.currentCompany),
            photoURL: local.photoURL ?? remote.photoURL,
            skills: local.skills.isEmpty ? remote.skills : local.skills,
            workExperiences: local.workExperiences.isEmpty ? remote.workExperiences : local.workExperiences,
            projects: local.projects.isEmpty ? remote.projects : local.projects,
            internships: local.internships.isEmpty ? remote.internships : local.internships,
            certifications: local.certifications.isEmpty ? remote.certifications : local.certifications,
            languages: local.languages.isEmpty ? remote.languages : local.languages
        )
    }
    
    private static func pick(_ local: String, _ remote: String) -> String {
        local.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? remote : local
    }
}
